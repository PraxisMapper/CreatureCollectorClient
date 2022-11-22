local composer = require( "composer" )
local scene = composer.newScene()
local widget = require("widget")
local json = require("json")
require("plusCodes")
require("PraxisMapper")
require("common")
local thisScenesView = '' 

--This is more or less the minimum code to draw a scene into the scrollview reasonably well.
--make sure to keep this up to date with the actual gameplay scenes.
--TODO: new pass to ensure this is legitly up to date.

local updateLoopTimer = nil
local gameMapDisplay = {} -- scrollview 
local gameMapTiles = {} -- background map tiles
local controlMapTiles = {} -- overlay team control maptiles.

local currentMapValues = {}
playerPoint = {}

--remember, current map tiles are 320 x 400, zooming in more will make them look worse.
--Gridsize can't really be smaller than 3 for the scroll thing to work, but the cells can get bigger..
--I could reduce the grid sizes some if I letterboxed the window a little bit.

--A better zoom set might be 3/7/11/19 for visible tiles? They'd feel more distinct, since the first 3-4 in this working set are very similar.


function WalkaroundGpsCallback()
    ScrollToPlayerLocation(125)
end

function ZoomIn(event)
    currentZoom = currentZoom - 1
    if (currentZoom == 0) then
        currentZoom = 1
        return
    end

    gameMapDisplay:removeSelf()
    local sizeData = zoomData[currentZoom]
    CreateFullMapDisplay(scene.view, sizeData)
    UpdateScrollView(0)
end

function ZoomOut(event)
    currentZoom = currentZoom + 1
    if (currentZoom > #zoomData) then
        currentZoom = #zoomData
        return
    end

    gameMapDisplay:removeSelf()
    local sizeData = zoomData[currentZoom]
    CreateFullMapDisplay(scene.view, sizeData)
    UpdateScrollView(0)
end

function PauseUpdateTimer()
    -- if updateLoopTimer ~= nil then
    --     print("pausing timer")
    --     timer.pause(updateLoopTimer)
    -- end
end

function ScrollCallback()
    -- if (updateLoopTimer ~= nil) then
    --     print("resuming timer")
    --     timer.resume(updateLoopTimer)
    -- end
end

function CreateFullMapDisplay(gridGroup, sizeProps) --was 640 width, 800 height
    PauseUpdateTimer()
    currentMapValues = sizeProps
    gameMapTiles = {}

    playerPoint.width = currentMapValues.playerPointWidth
    playerPoint.height = currentMapValues.playerPointHeight

    gameMapDisplay = widget.newScrollView({x = 0, y = 0, width = currentMapValues.viewWidth, height = currentMapValues.viewHeight, hideScrollBar = true, isLocked = true, backgroundColor = {0, 0, 0, 1}})
    gameMapDisplay.anchorX = 0
    gameMapDisplay.anchorY = 0
    --grid size is rectangular, X by Y size. Must be odd so that i can have a center square. Even values get treated as the next largest odd number.
    --Might want a couple dictionaries of values so I can look at an object where I calculated everything for various image sizes.
    cellSizeX = currentMapValues.cellSizeX
    cellSizeY = currentMapValues.cellSizeY
    
    local padding = currentMapValues.padding --space between cells.
    local range = math.floor(currentMapValues.gridSize / 2) -- 7 becomes 3, which is right. 6 also becomes 3.

    local fullRange = range * 2

    for x = 0, fullRange, 1 do
        for y = 0, fullRange, 1 do
            --create cell, tag it with x and y values.
            local newSquare = display.newRect(gridGroup,  (cellSizeX * x) + (padding * x), (cellSizeY * y)  + (padding * y), cellSizeX, cellSizeY) --x y w h
            newSquare.gridX = x - range
            newSquare.gridY = -y + range --invert this so cells get identified top-to-bottom, rather than bottom-to-top
            newSquare.pluscode = "" --to potentially be filled in by the game mode
            newSquare.fill = paintStatic  -- {0, 0, 0, .1} --default to transparent, but using 0, 0 means they don't register at all?
            --newSquare.fill = {math.random(), .5} --Uncomment this to make the grid visible for debug/layout purposes
            newSquare.anchorX = 0
            newSquare.anchorY = 0

            table.insert(gameMapTiles, newSquare)
            gameMapDisplay:insert(newSquare)
        end
    end

    gameMapDisplay:insert(playerPoint)
    playerPoint:toFront()

    --need to recreate creatureIconGroup and icons.
    creatureIconGroup = display.newGroup()
    gameMapDisplay:insert(creatureIconGroup)
    gameMapDisplay:toBack()
    ScrollToPlayerLocation(0)
    
end

function ScrollToPlayerLocation(speed)
    --do the math to figure out the player's current location on the scroll view, then move there
    --should use a speed of 0 when redrawing all the map tiles, and something fast but gentle otherwise.
    local xPos = 0
    local yPos = 0

    local shift = CODE_ALPHABET_:find(currentPlusCode:sub(11, 11)) - 10 -- X 
    local shift2 = CODE_ALPHABET_:find(currentPlusCode:sub(10, 10)) - 10 -- Y
    

    --upper left is 0, 0
    --need to figure out the center of the center map tile, then the pixels needed to move center map tile to center of view area, then the offset amount to keep the player centered.
    --center of map tile is (cellSizeX * gridSize) * .5 (3 * .5 = 1.5 for simplicity)
    local mapMid = currentPlusCode:sub(1,8) .. "+FF" -- map center.
    local mapMidX = currentMapValues.cellSizeX * currentMapValues.gridSize * .5
    local mapMidY = currentMapValues.cellSizeY * currentMapValues.gridSize * .5
    
    --480, 600

    local ViewMidX = currentMapValues.viewWidth * .5
    local ViewMidY = currentMapValues.viewHeight * .5
    
    --320, 400 on defaults, and everything else really.
    --This is where I want playerPoint to be after scrolling, basically.

    --pixel difference is midPoint - (viewSize * .5)
    local scaleShiftX = (mapMidX - (currentMapValues.viewWidth * .5))
    local scaleShiftY = (mapMidY - (currentMapValues.viewHeight * .5))   

    --existing xPos and yPos values are correct for my needs
    local playerShiftX = (shift * currentMapValues.cell10SizeX)
    local playerShiftY = (shift2 * currentMapValues.cell10SizeY)
    
    xPos = scaleShiftX + playerShiftX
    yPos = scaleShiftY - playerShiftY

    local printData = false
    if printData == true then
        print("Code Shift values are " .. shift .. ", " .. shift2)
        print("Map Mid is " .. mapMidX .. ", " .. mapMidY)
        print("View Mid is " .. ViewMidX .. ", " .. ViewMidY)
        print("scale shift is " .. scaleShiftX .. ", " .. scaleShiftY)
        print("player shift is " .. playerShiftX .. ", " .. playerShiftY)
        print("scrolling to " .. xPos .. ", " .. yPos)
    end

    local pad = currentMapValues.padding * math.floor(currentMapValues.gridSize / 2)

    playerPoint.x = mapMidX + playerShiftX - currentMapValues.playerPointOffsetX + pad
    playerPoint.y = mapMidY - playerShiftY + currentMapValues.playerPointOffsetY + pad

    --scrolling is backwards from positioning
    local options = {x = -xPos, y = -yPos, time = speed}
    if (speed == 0) then
        options.onComplete = ScrollCallback
    end
    gameMapDisplay:scrollToPosition(options)
end

function ClearAllCreatureIcons()
    creatureIconGroup:removeSelf()
    creatureIconGroup = display.newGroup()
    gameMapDisplay:insert(creatureIconGroup)
end

-- function PaintOneTile(mapTile, plusCode)
--     local imageExists = DoesFileExist(plusCode .. ".png", system.CachesDirectory)
--     if (imageExists == true) then
--         local paint = {
--             type = "image",
--             filename = plusCode .. ".png",
--             baseDir = system.CachesDirectory
--         }
--         mapTile.fill = paint
--     else
--         --file doesn't exist, queue up a request for it
--         mapTile.fill = paintStatic
--         GetNewTile(plusCode)
--     end
-- end

function UpdateScrollView(speed)
    --call this when current and previous plus code are different.
    for tile = 1, #gameMapTiles do
        local thisTilesPlusCode = currentPlusCode
        thisTilesPlusCode = ShiftCell(thisTilesPlusCode, gameMapTiles[tile].gridX, 8)
        thisTilesPlusCode = ShiftCell(thisTilesPlusCode, gameMapTiles[tile].gridY, 7)
        thisTilesPlusCode = thisTilesPlusCode:sub(1,8)    

        --Check if this imageRect has a different plusCode (meaning the player walked into a new Cell8)
        --and if so we have some extra processing to do.
        if gameMapTiles[tile].pluscode ~= thisTilesPlusCode then
            gameMapTiles[tile].pluscode = thisTilesPlusCode
            PaintOneTile(gameMapTiles[tile], thisTilesPlusCode + ".png", system.CachesDirectory)
        end   
        --DrawOneTileCreatureIcons(thisTilesPlusCode)
    end
    ScrollToPlayerLocation(speed)
end

local function GetTileListener(event)
    --update the appropriate map tile.
    --networkQueueBusy = false
    NetUp()
    if NetCallCheck(event.status) then
        local plusCode = Split(string.gsub(event.url, serverURL .. "MapTile/Area/", ""), '?')[1] --TODO: wont need this check once i fix the server to not need the query string.

        for tile = 1, #gameMapTiles do
            if gameMapTiles[tile].pluscode == plusCode then
                PaintOneTile(gameMapTiles[tile], plusCode + ".png", system.CachesDirectory)
                return
            end
        end
    end
end

function GetNewTileBaseline(plusCode8)
    local params = GetImageDownloadParams(plusCode8 .. '.png', system.CachesDirectory) {}
    local url = serverURL .. "MapTile/Area/" .. plusCode8 .. '/' .. mapTileStyle
    QueueCall(url, "GET", GetTileListener, params)
end

function UpdateLoop()
    local cell8 = currentPlusCode:sub(1,8)
    local cell10 = RemovePlus(currentPlusCode)
    if cell8 ~= lastDrawnPlusCode then
        UpdateScrollView(0) -- resets all the tiles drawn, if necessary.
        lastDrawnPlusCode = cell8
    end
end

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view

    -- Code here runs when the scene is first created but has not yet appeared on screen
    playerPoint = display.newImageRect(sceneGroup, "themables/PlayerTemplate.png", 48, 60) 
    playerPoint.anchorX = 0.5
    playerPoint.anchorY = 0.5

    CreateFullMapDisplay(sceneGroup, defaultSizes)
    gameMapDisplay:insert(sceneGroup)

    local zoomOut = display.newImageRect(sceneGroup, "themables/ZoomOut.png",300, 100)
    zoomOut.x = 200
    zoomOut.y = 1400
    zoomOut:addEventListener("tap", ZoomOut)

    local zoomIn = display.newImageRect(sceneGroup, "themables/ZoomIn.png",300, 100)
    zoomIn.x = 860
    zoomIn.y = 1400
    zoomIn:addEventListener("tap", ZoomIn)

    local improveMode = display.newImageRect(sceneGroup, "themables/ImproveMode.png",300, 100)
    improveMode.x = 860
    improveMode.y = 1550

    local controlMode = display.newImageRect(sceneGroup, "themables/ControlMode.png",300, 100)
    controlMode.x = 200
    controlMode.y = 1700
    --controlMode:addEventListener("tap", TestAccountCreate)

    local help = display.newImageRect(sceneGroup, "themables/HelpLong.png",300, 100)
    help.x = 860
    help.y = 1700
    --help:addEventListener("tap", TestAccountSave)

    local store = display.newImageRect(sceneGroup, "themables/StoreLong.png",300, 100)
    store.x = 200
    store.y = 1850
    --store:addEventListener("tap", ClearAllCreatureIcons)
end
 
-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        gameMapDisplay.isVisible = true

 
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        UpdateScrollView(0)
        updateLoopTimer = timer.performWithDelay(updateLoopDelay, UpdateLoop, -1)
        currentGpsCallback = WalkaroundGpsCallback
    end
end
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
        gameMapDisplay.isVisible = false
        currentGpsCallback = nil
 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
 
    end
end
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
 
end
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene