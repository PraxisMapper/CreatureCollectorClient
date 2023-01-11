
-- oh right, the 11th character level is a 5x4 ordered grid. so...
--'23456789CFGHJMPQRVWX'
-- R V W X
-- J M P Q 
-- C F G H 
-- 6 7 8 9 
-- 2 3 4 5 
--alter the last digit of the current cell to check neighbors, or 2nd to last cell if it overflows
--that only matters if I use 11-digit or more codes. At the 10 digit level its still 20x20. So, same idea, but one is X and one is Y

-- 14x14 meter precision
--CODE_PRECISION_NORMAL = 10

-- 2x3 meter precision
--CODE_PRECISION_EXTRA = 11

-- A separator used to break the code into two parts to aid memorability.
local SEPARATOR_ = '+'

-- The number of characters to place before the separator.
--local SEPARATOR_POSITION_ = 8

-- The character set used to encode the values.
CODE_ALPHABET_ = '23456789CFGHJMPQRVWX' --no longer local, so we can use it in other files

-- The resolution values in degrees for each position in the lat/lng pair
-- encoding. These give the place value of each position, and therefore the
-- dimensions of the resulting area. reference values, not actually used
--local PAIR_RESOLUTIONS_ = {20.0, 1.0, .05, .0025, .000125}

-- Number of columns in the grid refinement method.
local GRID_COLUMNS_ = 4;

-- Number of rows in the grid refinement method.
local GRID_ROWS_ = 5;

--for decoding the 11th digit
local GRID_ROW_MULTIPLIER = 3125
local GRID_COL_MULTIPLIER = 1024

function GetCell11Shift(letter)
    --Lazy way to work out how far to move the indicator based on the 11th digit.
    local xShift = 0 -- left
    local yShift = 0 -- bottom

    if string.find("6789", letter) then
        yShift = 1
    elseif string.find("CFGH", letter) then
        yShift = 2
    elseif string.find("JMPQ", letter) then
        yShift = 3
    elseif string.find("RVWX", letter) then
        yShift = 4
    end

    if string.find("37FMV", letter) then
        xShift = 1
    elseif string.find("48GPW", letter) then
        xShift = 2
    elseif string.find("59HQX", letter) then
        xShift = 3
    end

    return xShift, yShift
end

--my own pass at the algorithm. shorter, less thorough.
function EncodeLatLon(latitude, longitude, codeLength)
    local code = ''
    local lat =  0
    local long = 0
    local digit11 = ''
    local nextLongChar = ''
    local nextLatChar = ''
    if (codeLength == 11) then
        lat =  math.floor((latitude + 90) * 40000)
        long = math.floor((longitude + 180) * 32000)
        local nextLonIndex = (long % 4) 
        local nextLatIndex = (lat % 5)
        local indexDigit = (nextLatIndex * GRID_COLUMNS_ + nextLonIndex) + 1
        digit11 = CODE_ALPHABET_:sub(indexDigit, indexDigit)

        lat = math.floor(lat / 5)
        long = math.floor(long / 4)
    end

    -- 10 most significant digits
    for i= 1, 5, 1 do
        nextLongChar = (long % 20) + 1 
        nextLatChar = (lat % 20) + 1

        code = CODE_ALPHABET_:sub(nextLatChar, nextLatChar) .. CODE_ALPHABET_:sub(nextLongChar, nextLongChar) .. code
        lat = math.floor(lat / 20)
        long = math.floor(long / 20)
    end

    --11th digit is from a 4x5 grid, starting with 2 in the lower-left corner and ending with X in the upper-right, increasing left-to-right and then bottom-to-top
    if (codeLength == 11) then
        code = code .. digit11
    end 

    return code:sub(1,8) .. SEPARATOR_ .. code:sub(9, 11);
end
function ShiftCell(pluscode, Shift, position)
    --take the current cell, move it some number of cells at some position. (Call this twice to do X and Y)
    --Shift should be under 20
    --position is which cell we're looking to shift, from 1 to 10. This function handles the plus sign by skipping it.

    local charPos = position
    if (position > 8) then --shift this over 1, to avoid the + in the plus code
        charPos = position + 1
    end

    local newCode = pluscode
    local currentDigit = ""
    local digitIndex = 0
    --do the shift
    if (Shift ~= 0) then
        currentDigit = pluscode:sub(charPos, charPos)
        digitIndex = CODE_ALPHABET_:find(currentDigit)
        digitIndex = digitIndex + Shift
        while (digitIndex <= 0) do
            digitIndex = 20 + digitIndex
            newCode = ShiftCell(newCode, -1, position - 2) 
        end
        while (digitIndex > 20) do
            digitIndex = digitIndex - 20
            newCode = ShiftCell(newCode, 1, position - 2) 
        end
        currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
        newCode = newCode:sub(1, charPos - 1) .. currentDigit .. newCode:sub(charPos + 1, 11)
    end
    return newCode
end

function ShiftCellNoPlus(pluscode, Shift, position)
    --take the current cell, move it some number of cells at some position. (Call this twice to do X and Y)
    --Shift should be under 20
    --position is which cell we're looking to shift, from 1 to 10. This function handles the plus sign by skipping it.

    local charPos = position
    local newCode = pluscode
    local currentDigit = ""
    local digitIndex = 0
    --do the shift
    if (Shift ~= 0) then
        currentDigit = pluscode:sub(charPos, charPos)
        digitIndex = CODE_ALPHABET_:find(currentDigit)
        digitIndex = digitIndex + Shift
        while (digitIndex <= 0) do
            digitIndex = 20 + digitIndex
            newCode = ShiftCellNoPlus(newCode, -1, position - 2) 
        end
        while (digitIndex > 20) do
            digitIndex = digitIndex - 20
            newCode = ShiftCellNoPlus(newCode, 1, position - 2) 
        end
        currentDigit = CODE_ALPHABET_:sub(digitIndex, digitIndex)
        newCode = newCode:sub(1, charPos - 1) .. currentDigit .. newCode:sub(charPos + 1, 11)
    end
    return newCode
end

function RemovePlus(pluscode)
    return string.gsub(pluscode, "+", "")
end

function CountDistanceInCells(startCode, endCode)
    -- figure out X cell distance, capping distance at a cell8 (even)
    local xDigitS = startCode:sub(10, 10)
    local xDigitE = endCode:sub(10, 10)
    local xDistance = math.abs(CODE_ALPHABET_:find(xDigitS) - CODE_ALPHABET_:find(xDigitE))
    --figure out Y cell distance, capping at a cell 8 (odd)
    local yDigitS = startCode:sub(9, 9)
    local yDigitE = endCode:sub(9, 9)
    local yDistance = math.abs(CODE_ALPHABET_:find(yDigitS) - CODE_ALPHABET_:find(yDigitE))
    --triangulate straight line distance.
    --local fullDist = math.sqrt((xDistance * xDistance) + (yDistance * yDistance))
    return xDistance, yDistance
end