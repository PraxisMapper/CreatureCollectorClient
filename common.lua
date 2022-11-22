local widget = require('widget')

--adjustable values that get reused around the app. Could put these in Options screen.
updateLoopDelay = 50
modeTileDelay = 5000
menuSlideSpeed = 225
creatureCheckDelay = 10000
mapTileStyle = 'mapTiles'

activeOn = false
lastDrawnPlusCode = ''
currentMapValues = {}
requestedMapTileCells = {} --tracks which cells we've called for a mapTiles style update already this run. background mapTiles should almost never change, so only check the first time we look at it.
currentHeading = 0

--built-in colors and fills
bgFill = {.6, .6, .6, 1}
paintClear = {0, 0, 0, 0.01}

--background colors for icons in Control mode
--indexes match to team ids.
paintTeam = {
    {.5, .05, .05}, --red
    {.05, .5, .05}, --green
    {.3, .05, .3}, -- purple
    {.2, .2, .2} -- grey
}

paintStatic = {
    type = "image",
    filename = "themables/staticTile.png",
    baseDir = system.resourceDirectory
}

team1Name = 'Red Team'
team2Name = 'Green Team'
team3Name = 'Purple Team'
team4Name = 'Grey Team'

--Generic listener to stop UI elements pretending to be overlays from passing touch events through.
function blockTouch(event)
    return true
end

function ScrollToPlayerLocation(scrollView, playerPoint, currentMapValues, speed, playerHeading)
    --do the math to figure out the player's current location on the scroll view, then move there
    --should use a speed of 0 when redrawing all the map tiles, and something fast but gentle otherwise.
    local xPos = 0
    local yPos = 0

    local shift = CODE_ALPHABET_:find(currentPlusCode:sub(11, 11)) - 10 -- X 
    local shift2 = CODE_ALPHABET_:find(currentPlusCode:sub(10, 10)) - 10 -- Y

    local shiftX11, shiftY11
    if (#currentPlusCode == 12) then
        shiftX11, shiftY11 = GetCell11Shift(currentPlusCode:sub(12,12))
    end
    
    --upper left is 0, 0
    --need to figure out the center of the center map tile, then the pixels needed to move center map tile to center of view area, then the offset amount to keep the player centered.
    --center of map tile is (cellSizeX * gridSize) * .5 (3 * .5 = 1.5 for simplicity)
    local mapMid = currentPlusCode:sub(1,8) .. "+FF" -- map center.
    local mapMidX = currentMapValues.cellSizeX * currentMapValues.gridSize * .5
    local mapMidY = currentMapValues.cellSizeY * currentMapValues.gridSize * .5
    
    local ViewMidX = currentMapValues.viewWidth * .5
    local ViewMidY = currentMapValues.viewHeight * .5

    --pixel difference is midPoint - (viewSize * .5)
    local scaleShiftX = (mapMidX - (currentMapValues.viewWidth * .5))
    local scaleShiftY = (mapMidY - (currentMapValues.viewHeight * .5))   

    --existing xPos and yPos values are correct for my needs
    local playerShiftX = (shift * currentMapValues.cell10SizeX)
    local playerShiftY = (shift2 * currentMapValues.cell10SizeY)

    if (#currentPlusCode == 12) then
        playerShiftX = playerShiftX + (shiftX11 * (currentMapValues.cell10SizeX / 4))
        playerShiftY = playerShiftY + (shiftY11 * (currentMapValues.cell10SizeY / 5))
    end
    
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

    if (playerHeading ~= nil) then
        playerHeading.x = playerPoint.x
        playerHeading.y = playerPoint.y
    else
        print('playerHeading nil')
    end

    --scrolling is backwards from positioning
    local options = {x = -xPos, y = -yPos, time = speed}
    scrollView:scrollToPosition(options)
end

--TODO: apply this where appropriate.
function MakeUnqueuedRequest(url, listener)
    local desturl = serverURL .. url
    network.request(desturl, 'GET', listener, normalParams)
end

function CreateBaseMapDisplay(tapListener)
    local MapDisplay = widget.newScrollView({x = 0, y = 0, width = currentMapValues.viewWidth, height = currentMapValues.viewHeight, hideScrollBar = true, isLocked = true, backgroundColor = {0, 0, 0, 1}})
    MapDisplay.anchorX = 0
    MapDisplay.anchorY = 0
    MapDisplay.tap = tapListener
    MapDisplay:addEventListener("tap", MapDisplay)
    return MapDisplay
end

function CreateInnerGrid(gridGroup, mapTiles,  mapDisplay)
    local cellSizeX = currentMapValues.cellSizeX
    local cellSizeY = currentMapValues.cellSizeY
    
    local padding = currentMapValues.padding --space between cells.
    local range = math.floor(currentMapValues.gridSize / 2) -- 7 becomes 3, which is right. 6 also becomes 3.

    local fullRange = range * 2

    for x = 0, fullRange, 1 do
        for y = 0, fullRange, 1 do
            --create cell, tag it with x and y values.
            newSquare = display.newRect(gridGroup,  (cellSizeX * x) + (padding * x), (cellSizeY * y)  + (padding * y), cellSizeX, cellSizeY) --x y w h
            newSquare.gridX = x - range
            newSquare.gridY = -y + range --invert this so cells get identified top-to-bottom, rather than bottom-to-top
            newSquare.pluscode = "" --to potentially be filled in by the game mode
            newSquare.fill = paintStatic  -- {0, 0, 0, .1} --default to transparent, but using 0, 0 means they don't register at all?
            --newSquare.fill = {math.random(), .5} --Uncomment this to make the grid visible for debug/layout purposes
            newSquare.anchorX = 0
            newSquare.anchorY = 0

            table.insert(mapTiles, newSquare)
            mapDisplay:insert(newSquare)
        end
    end
end

function BgMapTileGenHandler(event)
    if NetCallCheck(event.status) == false then
        return
    end

    local piece = string.gsub(event.url, serverURL .. "MapTile/Generation/", "")
    local pieces = Split(piece, '/') -- 1 = plusCode, 2 = styleSet (mapTiles, biomes)

    local tileGen = 0
    local tileInfoOnPlusCode = tileGenInfo[pieces[1]]
    if tileInfoOnPlusCode ~= nil then
        if tileInfoOnPlusCode[pieces[2]] ~= nil then
            if tileInfoOnPlusCode[pieces[2]] ~= event.response then
                --redownload tile.
            end
        end
    end

end

function CheckTileGeneration(plusCode, styleSet, handler)
    if (plusCode == '') then return end

    local url = serverURL .. "MapTile/Generation/" .. plusCode .. "/Compete"
    QueueCall(url, "GET", handler, normalParams)
end

function GetNewTile(plusCode8, callback)
    local params = GetImageDownloadParams(plusCode8 .. '.png', system.CachesDirectory)
    local url = serverURL .. "MapTile/Area/" .. plusCode8 .. '/' .. configInfo.mapTileStyle
    QueueCall(url, "GET", callback, params)
end

function PaintOneTile(mapTile, filename, folder, useStatic)
    local imageExists = DoesFileExist(filename, folder)
    if (imageExists == true) then
        mapTile.fill = paintClear
        local paint = {
            type = "image",
            filename = filename,
            baseDir = folder
        }
        mapTile.fill = paint
        return true
    else
        --file doesn't exist, queue up a request for it
        if (useStatic) then
            mapTile.fill = paintStatic
        else
            mapTile.fill = paintClear
        end
        return false
    end
end

function MakeCancelButton(x, y, parent, listener)
    local CancelButton = display.newImageRect(parent, "themables/CancelButton.png", 300, 100)
    CancelButton.x = x
    CancelButton.y = y
    CancelButton:addEventListener("tap", listener)
    return CancelButton
end

function MakeCreatureDisplay(creatureId, level) --this is pretty big with default font sizes.
    local c = FindCreatureById(creatureId)
    if (c == ni) then
        return display.newGroup()
    end
    local creatureGroup = display.newGroup()
    local creaturePic = display.newImageRect(creatureGroup, c.imageName, system.DocumentsDirectory, 96, 96)
    local creatureText = display.newText({parent = creatureGroup, text = c.name, x = 0, y = 80})
    --testing to make levels show up more often on creature displays.
    if level ~= nil then
        local creatureLevel = display.newText({parent = creatureGroup, text = "0", x = 0, y = 96})
        creatureLevel.anchorY = 1
    end
    creatureGroup.pic = creaturePic
    creatureGroup.text = creatureText
    return creatureGroup
end

function FillPickWindow(tapHandler, creatureFilter, cancelFunction)
    local pickScreen = display.newGroup()
    local pickTouchLock = display.newRect(pickScreen, display.contentCenterX, display.contentCenterY, 1080, 1920)     --blocks touches for the background
    pickTouchLock.fill = {0, 0, 0, .01}
    pickTouchLock:addEventListener("tap", blockTouch)
    local pickBg = display.newRect(pickScreen, display.contentCenterX, display.contentCenterY, 700, 1400)
    pickBg.fill = {.6, .6, .5, 1}
    local pickScroll = widget.newScrollView({left = 100, top = 100, width = 880, height = 1720, backgroundColor = {0, 0, 0, 1} })
    pickScreen:insert(pickScroll)
    local pickCancel = display.newImageRect(pickScreen, "themables/CancelButton.png", 300, 100)
    pickCancel.y = 1870
    pickCancel.x = display.contentCenterX
    pickCancel:addEventListener("tap", cancelFunction)

    local xCounter = 0
    local yCounter = 0

    for k, v in pairs(myCreatures) do
        if creatureFilter(v) == true then
            local icon = MakeCreatureDisplay(v.id)
            icon.creatureName = k
            icon.creatureId = v.id
            pickScroll:insert(icon) 
            icon.x = 200 + (xCounter % 3) * 250
            icon.y = 100 + math.floor(yCounter / 3) * 200
            icon.anchorX = 0
            icon.anchorY = 0
            icon.tap = tapHandler
            icon:addEventListener("tap", icon)
            xCounter = xCounter + 1
            yCounter = yCounter + 1
        end
    end

    return pickScreen
end

function FilterCreaturesShowAllCaught(c)
    return true
end

function FilterCreaturesAvailable(c)
    return c.available
end

function FilterCreaturesAvailableAndLeveled(c) --This one removes creatures that are only hinted. Hints mark a creature as available because thats the default.
    return c.available and c.level > 0
end

function FilterCreaturesWildSpawn(c)
    local creatureSource = FindCreatureById(c.id)
    return c.totalCaught > 1 and creatureSource.isWild
end

function FilterCreaturesHasFragments(c)
    return c.currentAvailable > 0
end

function FilterCreaturesHasCompeteFragments(c)
    return c.currentAvailableCompete > 0
end

-- function CheckTileGenerationMapTiles(plusCode, handler)
--     if (plusCode == '') then return end

--     if (styleSet == 'mapTiles') and (requestedMapTileCells[plusCode] == 1) then
--         return --only check baseline tiles once per run. Check for updates on next run.
--     end

--     local url = serverURL .. "MapTile/Generation/" .. plusCode .. "/" .. mapTileStyle
--     QueueCall(url, "GET", handler, normalParams)    
-- end

function GetTileListenerWithTable(event, mapTiles)
    --update the appropriate map tile.
    --networkQueueBusy = false
    NetUp()
    if NetCallCheck(event.status) == true then
        local plusCode = string.gsub(event.url, serverURL .. "MapTile/Area/", "")

        for tile = 1, #mapTiles do
            if mapTiles[tile].pluscode == plusCode then
                return PaintOneTile(mapTiles[tile], plusCode .. '.png', system.CachesDirectory)
            end
        end
    end
end

function GetImageDownloadParams(filename, folder)
    local params = {}
    local headers = {}
    headers = AddAuthHeaders(headers)
    params.headers = headers
    params["response"] = {}
    params["PraxisAuthKey"] = "testingKey" --the proper way to authenticate
    params.response["filename"] = filename
    params.response["baseDirectory"] = folder

    return params
end

function SilhouetteImage(image)
    if image ~= nil then
        image:setFillColor(0, 0, 0, 1) -- pure black tint.
    end
end
   
function ShowMenu(menu)
    menu.coinText.text = "Coins:" .. playerData.currencies.baseCurrency
    transition.moveTo(menu, {x = 0, time = menuSlideSpeed})
    return true
 end

 function ToggleActiveChallenge(event)
    activeOn = not activeOn
    if (activeOn) then
        activeChallengeInfo.text = "Active Challenge: ON"
    else
        activeChallengeInfo.text = "Active Challenge: off"
    end
    return true
 end

function GetMuniListener(event)
    NetUp()
    if NetCallCheck(event.status) == true then
        currentMuni = event.response
    end
end

function GetMuni(plusCode)
    local url = serverURL .. 'Municipality/Muni/' .. plusCode
    QueueCall(url, 'GET', GetMuniListener, normalParams)
end

function GetMuniTimed()
    local url = serverURL .. 'Municipality/Muni/' .. RemovePlus(currentPlusCode)
    QueueCall(url, 'GET', GetMuniListener, normalParams)
end


function MakeMenu(currentScene)
    --TODO: Scene-specific buttons (Cover map, Leaderboards) might need to be added here.
    --Probably change colors of the current mode.
    local menu = display.newGroup()
    menuTouchCancel = display.newRect(menu, 0, 0, 1080, 1920)     --blocks touches for the background
    menuTouchCancel.fill = {0, 0, 0, .01}
    menuTouchCancel.anchorX = 0
    menuTouchCancel.anchorY = 0
    menu.cancelListener = menuTouchCancel -- to be assigned per scene.
    menuBg = display.newRect(menu, 0, 0, 500, 1920)
    menuBg.fill = bgFill
    menuBg.anchorX = 0
    menuBg.anchorY = 0

    local yPos = 50

    --Quick Info
    local info1 = display.newText({ parent = menu, text = playerData.name, x = 50, y = yPos})
    info1.anchorX = 0
    info1.anchorY = 0
    menu.name = info1
    yPos = yPos + 50
    local info2 = display.newText({ parent = menu, text = "Coins: " .. playerData.currencies.baseCurrency, x = 50, y = yPos})
    info2.anchorX = 0
    info2.anchorY = 0
    menu.coinText = info2

    yPos = yPos + 100
    --Text links to modes.
    local jump1 = display.newText({ parent = menu, text = "Collect", x = 50, y = yPos})
    jump1.anchorX = 0
    jump1.anchorY = 0
    jump1:addEventListener("tap", GoToCollect)
    yPos = yPos + 50    
    activeChallengeInfo = display.newText({ parent = menu, text = "Active Challenge: off", fontSize = 40, x = 100, y = yPos})
    activeChallengeInfo.anchorX = 0
    activeChallengeInfo.anchorY = 0
    if (activeOn) then
        activeChallengeInfo.text = "Active Challenge: ON"
    else
        activeChallengeInfo.text = "Active Challenge: off"
    end
    activeChallengeInfo:addEventListener("tap", ToggleActiveChallenge)
    yPos = yPos + 100

    local jump2 = display.newText({ parent = menu, text = "Control", x = 50, y = yPos})
    jump2.anchorX = 0
    jump2.anchorY = 0
    jump2:addEventListener("tap", GoToControl)
    yPos = yPos + 50

    local jump2a = display.newText({ parent = menu, text = "Control Leaderboard", fontSize = 40, x = 100, y = yPos})
    jump2a.anchorX = 0
    jump2a.anchorY = 0
    jump2a:addEventListener("tap", ShowLeaderboardOverlay)
    yPos = yPos + 100

    local jump3 = display.newText({ parent = menu, text = "Cover", x = 50, y = yPos})
    jump3.anchorX = 0
    jump3.anchorY = 0
    jump3:addEventListener("tap", GoToCover)
    yPos = yPos + 50

    local jump3a = display.newText({ parent = menu, text = "My Cover Map", fontSize = 40, x = 100, y = yPos})
    jump3a.anchorX = 0
    jump3a.anchorY = 0
    jump3a:addEventListener("tap", ShowCoverMapOverlay)
    yPos = yPos + 100

    local jump9 = display.newText({ parent = menu, text = "Compete", x = 50, y = yPos})
    jump9.anchorX = 0
    jump9.anchorY = 0
    jump9:addEventListener("tap", GoToCompete)
    yPos = yPos + 50

    local jump9a = display.newText({ parent = menu, text = "Compete State Map", fontSize = 40, x = 100, y = yPos})
    jump9a.anchorX = 0
    jump9a.anchorY = 0
    jump9a:addEventListener("tap", ShowCompeteMapOverlay)
    yPos = yPos + 100

    local jump4 = display.newText({ parent = menu, text = "Upgrades", x = 50, y = yPos})
    jump4.anchorX = 0
    jump4.anchorY = 0
    jump4:addEventListener("tap", GoToUpgrades)
    yPos = yPos + 100

    local jump5 = display.newText({ parent = menu, text = "Creature List", x = 50, y = yPos})
    jump5.anchorX = 0
    jump5.anchorY = 0
    jump5:addEventListener("tap", JumpToCreatureInfo)
    yPos = yPos + 100

    local jump6 = display.newText({ parent = menu, text = "Passport", x = 50, y = yPos})
    jump6.anchorX = 0
    jump6.anchorY = 0
    jump6:addEventListener("tap", ShowPassportOverlay)
    yPos = yPos + 100

    local jump9 = display.newText({ parent = menu, text = "Coin Shop", x = 50, y = yPos})
    jump9.anchorX = 0
    jump9.anchorY = 0
    jump9:addEventListener("tap", ShowCoinShopOverlay)
    yPos = yPos + 100

    local jump7 = display.newText({ parent = menu, text = "Options", x = 50, y = yPos})
    jump7.anchorX = 0
    jump7.anchorY = 0
    jump7:addEventListener("tap", GoToOptions)
    yPos = yPos + 100

    local jump8 = display.newText({ parent = menu, text = "Help", x = 50, y = yPos})
    jump8.anchorX = 0
    jump8.anchorY = 0
    jump8:addEventListener("tap", JumpToHelp)
    yPos = yPos + 100

    return menu
end

function MakeHeaderBar(showPossible)
    local header = display.newGroup()
    local headerBG = display.newRect(header, 0, 0, 1080, 100)
    headerBG.anchorX = 0
    headerBG.anchorY =0
    headerBG.fill = bgFill

    headerLoc = display.newText({ parent = header, text = "Loc: " .. currentPlusCode, x = 15, y = 10})
    headerLoc.anchorX = 0
    headerLoc.anchorY = 0

    muniDisplay = display.newText({ parent = header, text = "", x = 15, y = 60, fontSize = 30})
    muniDisplay.anchorX = 0
    muniDisplay.anchorY = 0

    netStatusLight = display.newImageRect(header, "themables/networkDown.png", 25, 25)
    netStatusLight.x = display.contentCenterX + 25
    netStatusLight.y = 25

    accuracyInfo = display.newText({ parent = header, text = "", x = display.contentCenterX + 25, y = 60, fontSize = 35})
    accuracyInfo.anchorX = 0.5
    accuracyInfo.anchorY = 0.5

    local availableImages = {}
    if showPossible then
        print('making available entries')
        local headerPossibleLabel = display.newText({ parent = header, text = "Possible:", x = 700, y = 50, fontSize = 40})
        for i=1, 3 do
            availableImages[i] = display.newImageRect(header, "themables/placeholder.png", 64, 64)
            availableImages[i].fill = paintClear
            availableImages[i].x = 720 + (i * 85)
            availableImages[i].y = 20
            availableImages[i].anchorX = 0
            availableImages[i].anchorY = 0
        end
    else
        print('showPossible says dont make entries for images')
    end

    header.locText = headerLoc
    header.possibleLabel = headerPossibleLabel
    header.muniDisplay = muniDisplay
    header.netStatusLight = netStatusLight
    header.accuracyLabel = accuracyInfo
    header.availableImages = availableImages
    
    return header
end

function UpdateNetStatusIcon(header)
    local lightPaint = {
        type = "image",
        filename = '',
        baseDir =  system.ResourceDirectory
    }
    if currentNetStatus == 'up' then
        lightPaint.filename = 'themables/networkUp.png'
    elseif currentNetStatus == 'open' then
        lightPaint.filename = 'themables/networkTransfer.png'
    else
        lightPaint.filename = 'themables/networkDown.png'
    end
    header.netStatusLight.fill = lightPaint
end