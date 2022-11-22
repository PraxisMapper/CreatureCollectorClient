local json = require("json")

--debugging helper function
function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

 function listProps(o)
    local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          print(type(v))
          if type(v) ~= 'table' then
            s = s .. '['..k..'] = ' .. v ..','
          else
            s = s .. '['..k..'] = "table",'
          end
       end
       return s .. '} '
 end

 --Split a string, since there's no built in split in lua.
 function Split(s, delimiter)
   result = {};
   for match in (s..delimiter):gmatch("(.-)"..delimiter) do
       table.insert(result, match);
   end
   return result;
end

function DoesFileExist( fname, path )
    local results = false
   -- Path for the file
   local filePath = system.pathForFile( fname, path )
   if ( filePath ) then
       local file, errorString = io.open( filePath, "r" )
       if not file then
           -- doesnt exist or an error locked it out
       else
           -- File exists!
           results = true
           -- Close the file handle
           file:close()
       end
   end
   return results
end

function convertColor(colorString)
   --skiasharp colors used on the server are AARRGGBB. In ImageSharp they become RRGGBBAA, and the server handled that swap.
   local alphaHex = tonumber('0x' .. colorString:sub(1,2))
   local redHex = tonumber('0x' .. colorString:sub(3,4))
   local greenHex = tonumber('0x' .. colorString:sub(5,6))
   local blueHex = tonumber('0x' .. colorString:sub(7,8))
   
   return {redHex / 255, greenHex / 255, blueHex / 255, alphaHex / 255}
end

function copyFile( srcName, srcPath, dstName, dstPath, overwrite )
 
   local results = false

   local fileExists = doesFileExist( srcName, srcPath )
   if ( fileExists == false ) then
       return nil  -- nil = Source file not found
   end

   -- Check to see if destination file already exists
   if not ( overwrite ) then
       if ( fileLib.doesFileExist( dstName, dstPath ) ) then
           return 1  -- 1 = File already exists (don't overwrite)
       end
   end

   -- Copy the source file to the destination file
   local rFilePath = system.pathForFile( srcName, srcPath )
   local wFilePath = system.pathForFile( dstName, dstPath )

   local rfh = io.open( rFilePath, "rb" )
   local wfh, errorString = io.open( wFilePath, "wb" )

   if not ( wfh ) then
       -- Error occurred; output the cause
       --print( "File error: " .. errorString )
       return false
   else
       -- Read the file and write to the destination directory
       local data = rfh:read( "*a" )
       if not ( data ) then
           --print( "Read error!" )
           return false
       else
           if not ( wfh:write( data ) ) then
               --print( "Write error!" )
               return false
           end
       end
   end

   results = 2  -- 2 = File copied successfully!

   -- Close file handles
   rfh:close()
   wfh:close()

   return results
end

function SaveToFile(path, tableA)
    local jsonData = json.encode(tableA)
    local pathOut = system.pathForFile(path, system.DocumentsDirectory)
    local file, error = io.open(pathOut, "w")
    if (file) then
        file:write(jsonData)
        io.close(file)
    end
end

function LoadFromFile(path)
    local pathIn = system.pathForFile(path, system.DocumentsDirectory)
    local file, error = io.open(pathIn, "r")
    local tableA = {}
    if file then
        local contents = file:read("*a")
        tableA = json.decode(contents)
        io.close(file)
    end
    return tableA
end

function StartsWith(str, start)
    return string.sub(str,1,string.len(start))==start
 end

function EndsWith(str, ending)
    return str:sub(-#ending) == ending 
end

--NOTE: this is moved here so I can see the full reference for all of the math I did here and my comments, but I don't need this in each scene.
function TapTester(self, event)
        local baseX, baseY = self:getContentPosition()
    local innerX = event.x - baseX
    local innerY = event.y - baseY
    local xDiff = innerX - playerPoint.x + currentMapValues.playerPointOffsetX --playerPoint is centered, for our calcs we need to use its lower left corner.
    local yDiff = innerY - playerPoint.y + currentMapValues.playerPointOffsetY

    local cell10ShiftX = math.floor(xDiff / currentMapValues.cell10SizeX)
    local cell10ShiftY = -math.floor(yDiff / currentMapValues.cell10SizeY)
    --TODO: work out padding values and adjust appropriately.

    local workingPlusCode = RemovePlus(currentPlusCode)
    local tapPlusCode = ShiftCellNoPlus(workingPlusCode, cell10ShiftX, 10)
    tapPlusCode = ShiftCellNoPlus(tapPlusCode, cell10ShiftY, 9)
    
    --TODO ensure padding tweaks apply here too.
    if (currentMapValues.cell10SizeX >= 32) then -- only runs when zoomed in closer than default, to ensure you don't have to hit single-pixel things.
        --cell11 approximations.
        local modSize = currentMapValues.cell10SizeX / 4 --TODO change name to better explanation of its purpose. No longer mod by this. Its a scale factor.

        local cell11X = math.floor(xDiff % currentMapValues.cell10SizeX  / modSize)
        local cell11Y = math.floor(yDiff % currentMapValues.cell10SizeY / modSize)

        local cell11Digit = (cell11Y * 4 + cell11X) + 1
        local cell11Char = CODE_ALPHABET_:sub(cell11Digit, cell11Digit)

        tapPlusCode = tapPlusCode .. cell11Char
    end

    lastTappedCode = tapPlusCode
    GetTappedElementRequest(tapPlusCode)
end