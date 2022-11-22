local composer = require("composer" )
local scene = composer.newScene()
local widget = require("widget")
local json = require("json")
require("plusCodes")
require("PraxisMapper")
require("common")
local thisScenesView = '' 

local menu = {}
local updateLoopTimer = nil
local TCTileTimer = nil
local gameMapDisplayTC = {} -- scrollview 
local gameMapTilesTC = {} -- background map tiles
local controlMapTiles = {} -- overlay team control maptiles.
local playerHeading = {}
local header = {}
local netStatusTimer = {}

local attackResultText = {}
local lastSentCreature = {}

--claim modal
local claimScreen = {}
local claimName = ''
local claimScore = ''
local claimCreature = ''
local claimClaimButton = ''
local claimCancelButton = ''
local claimAttackButton = ''
local placeData = {}
local lastTappedCode = ''

local pyramidIcons = {}
local playerPoint = {}

function CheckTileGeneration(plusCode, styleSet)
    if (plusCode == '') then return end

    if (styleSet == 'mapTiles') and (requestedMapTileCells[plusCode] == 1) then
        return --only check baseline tiles once per run. Check for updates on next run.
    end

    local url = serverURL .. "MapTile/Generation/" .. plusCode .. "/" ..styleSet
    QueueCall(url, "GET", TileGenHandlerTC, normalParams)    
end

local function GetTileListener(event)
    NetUp()
    if NetCallCheck(event.status) == true then
        local plusCode = string.gsub(event.url, serverURL .. "MapTile/Area/", "")
        for tile = 1, #gameMapTilesTC do
            if gameMapTilesTC[tile].pluscode == plusCode then
                if (PaintOneTile(gameMapTilesTC[tile], plusCode .. '.png', system.CachesDirectory, true)) == false then GetNewTile(plusCode, GetTileListener) end
                return
            end
        end
    end
end

function TileGenHandlerTC(event)
    NetUp()

    if NetCallCheck(event.status) == false then
        return
    end

    local piece = string.gsub(event.url, serverURL .. "MapTile/Generation/", "")
    local pieces = Split(piece, '/') -- 1 = plusCode, 2 = styleSet
    local answer = event.response

    if (answer == 'Timed out') then
        --abort this logic!
        return
    end

    local imageExists = false
    if pieces[2] == "mapTiles" then
        imageExists = DoesFileExist(pieces[1] .. ".png", system.CachesDirectory)
    elseif pieces[2] == "TC" then
        imageExists = DoesFileExist(pieces[1] .. "-TC.png", system.TemporaryDirectory)
    end

    local hasData = false
    local redownload = false
    local tileGen = 0
    local tileInfoOnPlusCode = tileGenInfo[pieces[1]]
    if tileInfoOnPlusCode ~= nil then
        if tileInfoOnPlusCode[pieces[2]] ~= nil then
            hasData = true
            tileGen = tileInfoOnPlusCode[pieces[2]]
        end
    end

    --loop, but should be 1 result.
    if hasData == true and tonumber(tileGen) < tonumber(answer)then
        tileGenInfo[pieces[1]][pieces[2]] = answer
        redownload = true
    end

    if hasData == false then
        tileGenInfo[pieces[1]] = {}
        tileGenInfo[pieces[1]][pieces[2]] = answer
        redownload = true
    end

    redownload = (imageExists == false) or redownload or answer == '-1'
    if redownload then
        if pieces[2] == "mapTiles" then
            GetNewTile(pieces[1], GetTileListener)
        elseif pieces[2] == "TC" then
            GetNewControlTile(pieces[1])
        end
    end

    if pieces[2] == 'mapTiles' then
        requestedMapTileCells[pieces[1]] = 1
    end
end

local function TapTester(self, event)
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

function GetTappedElementRequest(plusCode)
    local url = serverURL .. 'Control/Info/' .. plusCode
    network.request(url, "GET", TappedElementListener, normalParams)
    composer.showOverlay("overlays.LoadingOverlay")
end

function TappedElementListener(event)
    --expected results in JSON:
    --placeId (privacy ID, guid) - the elemenet in question
    --score - current score logic value
    --terrain - probably not, that doesn't seem to be relevant to the client right now
    --pyramid data: layers, creature data in each slot (PLAYER data does't need revealed here.)
    --i want to see which creature, team, and power is in each slot of the pyramid, so that's probably the minimum
    --cost: the price to open up a new slot or layer.
    if NetCallCheck(event.status) == false then
        composer.hideOverlay()
        return 
    end

    if (event.response == '') then
        claimName.text = "No place detected"
        claimAttackButton.isVisible = false
        claimClaimButton.isVisible = false
        composer.hideOverlay()
        showClaimOverlay()
        for i = 1, #pyramidIcons do
            pyramidIcons[i].bg.fill = paintClear
            pyramidIcons[i].image.fill = paintClear
            pyramidIcons[i].levelText.text = ''
        end
        return
    end

    placeData = json.decode(event.response)
    composer.hideOverlay()
    showClaimOverlay()
    claimName.text = placeData.name
    claimScore.text = "Points: " .. placeData.score

    local allowAttack = true
    local allowClaim = true

    --clear out all the icons every time.
    for i = 1, #pyramidIcons do
        pyramidIcons[i].bg.fill = paintClear
        pyramidIcons[i].image.fill = paintClear
        pyramidIcons[i].levelText.text = ''
    end

    if placeData.creatures ~= nil and #placeData.creatures > 0 then
        local creatureCount = #placeData.creatures
        if  creatureCount >= 15 then
            allowClaim = false
        end

        for i = 1, creatureCount do
            local thisCreature = FindCreatureById(placeData.creatures[i].creatureId)
            pyramidIcons[i].bg.fill = paintTeam[placeData.creatures[i].team]
            pyramidIcons[i].image.fill = {
                type = "image",
                filename = thisCreature.imageName,
                baseDir = system.DocumentsDirectory
            }
            pyramidIcons[i].levelText.text = placeData.creatures[i].level
            if placeData.creatures[i].owner == playerData.name then
                allowAttack = false
                allowClaim = false
            end
        end
    else
        allowAttack = false
    end

    claimAttackButton.isVisible = allowAttack
    claimClaimButton.isVisible = allowClaim
end

function WalkaroundGpsCallbackTC(event)
    ScrollToPlayerLocation(gameMapDisplayTC, playerPoint, currentMapValues, 125, playerHeading)
    playerHeading.rotation = currentHeading
    headerLoc.text = "Loc: " .. currentPlusCode
    muniDisplay.text = currentMuni
    if (event.accuracy ~= nil) then --doesnt work in simulator.
        header.accuracyLabel.text = math.round(event.accuracy) .. 'm'
    end
end

local function RedrawEntireMap()
    gameMapDisplayTC:removeSelf()
    CreateFullMapDisplayTC(scene.view, zoomData[currentZoom])
    UpdateScrollViewTC(0)
end

local function ZoomInTC(event)
    currentZoom = currentZoom - 1
    if (currentZoom == 0) then
        currentZoom = 1
        return true
    end

    RedrawEntireMap()
    return true
end

local function ZoomOutTC(event)
    currentZoom = currentZoom + 1
    if (currentZoom > #zoomData) then
        currentZoom = #zoomData
        return true
    end

    RedrawEntireMap()
    return true
end

local function PauseUpdateTimer()
    if updateLoopTimer ~= nil then
        timer.pause(updateLoopTimer)
    end
end

local function ScrollCallback()
    if (updateLoopTimer ~= nil) then
        timer.resume(updateLoopTimer)
    end
end

--should be local, but ordering locals is hard.
function CreateFullMapDisplayTC(gridGroup, sizeProps) --was 640 width, 800 height
    PauseUpdateTimer()
    currentMapValues = sizeProps
    gameMapTilesTC = {}
    controlMapTiles = {}

    playerPoint.width = currentMapValues.playerPointWidth
    playerPoint.height = currentMapValues.playerPointHeight

    playerHeading.width = currentMapValues.playerPointHeight --correct, this image is square and we want the larger value.
    playerHeading.height = currentMapValues.playerPointHeight

    gameMapDisplayTC = CreateBaseMapDisplay(TapTester)
    CreateInnerGrid(gridGroup, gameMapTilesTC, gameMapDisplayTC)
    CreateInnerGrid(gridGroup, controlMapTiles, gameMapDisplayTC)

    gameMapDisplayTC:insert(playerPoint)
    playerPoint:toFront()

    gameMapDisplayTC:insert(playerHeading)
    playerHeading:toFront()

    gameMapDisplayTC:toBack()
    ScrollToPlayerLocation(gameMapDisplayTC, playerPoint, currentMapValues, 0, playerHeading)
    ScrollCallback()
end

function UpdateScrollViewTC(speed)
    --call this when current and previous plus code are different.
    for tile = 1, #gameMapTilesTC do
        local thisTilesPlusCode = currentPlusCode
        thisTilesPlusCode = ShiftCell(thisTilesPlusCode, gameMapTilesTC[tile].gridX, 8)
        thisTilesPlusCode = ShiftCell(thisTilesPlusCode, gameMapTilesTC[tile].gridY, 7)
        thisTilesPlusCode = thisTilesPlusCode:sub(1,8)    

        --Check if this imageRect has a different plusCode (meaning the player walked into a new Cell8)
        --and if so we have some extra processing to do.
        if gameMapTilesTC[tile].pluscode ~= thisTilesPlusCode then
            gameMapTilesTC[tile].pluscode = thisTilesPlusCode
            controlMapTiles[tile].pluscode = thisTilesPlusCode
            if (PaintOneTile(gameMapTilesTC[tile], thisTilesPlusCode .. '.png', system.CachesDirectory, true)) == false then GetNewTile(thisTilesPlusCode, GetTileListener) end
            if (PaintOneTile(controlMapTiles[tile], thisTilesPlusCode .. '-TC.png', system.TemporaryDirectory)) == false then GetNewControlTile(thisTilesPlusCode) end
        end   
    end
    ScrollToPlayerLocation(gameMapDisplayTC, playerPoint, currentMapValues, speed, playerHeading)
end

function GetNewControlTile(plusCode8)
    local params = GetImageDownloadParams(plusCode8 .. '-TC.png', system.TemporaryDirectory)
    local url = serverURL .. "MapTile/AreaPlaceData/" .. plusCode8 .. "/TC/teamOwner"
    QueueCall(url, "GET", GetControlTileListener, params)
end

function GetControlTileListener(event)
    NetUp()
    if NetCallCheck(event.status) == true then
        local plusCode = string.gsub(string.gsub(event.url, serverURL .. "MapTile/AreaPlaceData/", ""), "/TC/teamOwner", "")
        for tile = 1, #controlMapTiles do
            if controlMapTiles[tile].pluscode == plusCode then
                if (PaintOneTile(controlMapTiles[tile], plusCode .. '-TC.png', system.TemporaryDirectory)) == false then GetNewControlTile(plusCode) end
                return
            end
        end
    end
end

function CheckForTCTiles()
    for i = 1, #controlMapTiles do
        CheckTileGeneration(controlMapTiles[i].pluscode, "TC")
    end
end

function UpdateLoopTC()
    local cell8 = currentPlusCode:sub(1,8)
    local cell10 = RemovePlus(currentPlusCode)
    if cell8 ~= lastDrawnPlusCode then --TODO: make this a callback for when you move Cells.
        UpdateScrollViewTC(0) -- resets all the tiles drawn, if necessary.
        lastDrawnPlusCode = cell8        
    end
end

function attackThisPlace(event)
    FillPickWindowTC(AttackPickedCreature) -- and attack when done.
    return true
end

function claimThisPlace(event)
    FillPickWindowTC(SendPickedCreature) -- and claim when done
    return true
end

function hideClaimOverlay(event)
    claimScreen.x = -2500
    claimName.text = ''
    claimScore.text = ''
    return true
end

function showClaimOverlay(event)
    claimScreen.x = 0
    return true
end

function AttackPickedCreature(self, event)
    local url = serverURL .. "Control/Combat/" .. lastTappedCode
    local claimData = {}
    claimData.team = playerData.team
    claimData.owner = playerData.name
    local creatureData = myCreatures[tostring(self.creatureId)]
    claimData.strength = creatureData.strength
    local thisCreature = FindCreatureById(self.creatureId)
    claimData.creatureId = thisCreature.id

    local headers = {}
    headers["PraxisAuthKey"] = "testingKey"
    headers = AddAuthHeaders(headers)
    local params = {
        headers = headers,
        body = json.encode(claimData)
    }
    network.request(url, "GET", AttackListener, params)
end

function AttackListener(event)
    if NetCallCheck(event.status) == false then
        attackResultsText.text = 'Network error'
    elseif (event.response == "true") then
        attackResultText.text = "Victory!"
    else
        attackResultText.text = "Could not win!"
    end 
    attackResultText.x = display.contentCenterX
    timer.performWithDelay(3000, HideAttackResultText, 1)

    pickScreen:removeSelf()
    hideClaimOverlay()
end

function HideAttackResultText()
    attackResultText.x = -display.contentCenterX    
end

function SendPickedCreature(self, event)
    local url = serverURL .. "Control/Claim/" .. lastTappedCode
    local claimData = {}
    claimData.team = playerData.team
    claimData.owner = playerData.name
    local creatureData = myCreatures[tostring(self.creatureId)]
    claimData.strength = creatureData.strength
    local thisCreature = FindCreatureById(self.creatureId)
    claimData.creatureId = thisCreature.id

    local headers = {}
    headers["PraxisAuthKey"] = "testingKey"
    headers = AddAuthHeaders(headers)
    local params = {
        headers = headers,
        body = json.encode(claimData)
    }
    myCreatures[tostring(self.creatureId)].available = false
    myCreatures[tostring(self.creatureId)].assignedTo = lastTappedCode
    lastSentCreature = tostring(self.creatureId)
    network.request(url, "PUT", SendCreatureListener, params)
    pickScreen:removeSelf()
    hideClaimOverlay()
end

function SendCreatureListener(event)
    --on failure, return the locked creature if possible.
    if NetCallCheck(event.status) == false then
        myCreatures[lastSentCreature].available = true
        myCreatures[lastSentCreature].assignedTo = ''
        --TODO: alert player to network error.
    end
end

local function CancelPickTC(event)
    pickScreen:removeSelf()
end

function FillPickWindowTC(tapHandler)
    pickScreen = FillPickWindow(tapHandler, FilterCreaturesAvailableAndLeveled, CancelPickTC)
end

local function ShowMenuControl(event)
    menu.name.text = playerData.name
    ShowMenu(menu)
    return true
end

 local function HideMenu()
    transition.moveTo(menu, {x = -1080, time = menuSlideSpeed})
    return true
 end

 local function MakeCreaturePyramidIcon(parent, creature, x, y, level)
    local iconGroup = display.newGroup()
    parent:insert(iconGroup)
    local thisBg = display.newRect(iconGroup, 0, 0, 128, 128)
    thisBg.anchorY = 0
    local thisIcon = display.newImageRect(iconGroup, "themables/placeholder.png", 128, 128) --64, 64)
    if creature ~= nil then
        thisIcon.fill = {
            type = "image",
            filename = creature.imageName,
            baseDir = system.DocumentsDirectory
        }
    else
        thisIcon.fill = paintClear
    end
    local thisText = display.newText({parent = iconGroup, x = 64, y = 96, fontSize = 32, text = level})
    thisText.anchorX = 1
    thisText.anchorY = 0
    thisIcon.anchorY = 0
    iconGroup.x = x
    iconGroup.y = y
    iconGroup.bg = thisBg
    iconGroup.image = thisIcon
    iconGroup.levelText = thisText

    return iconGroup
 end

 function UpdateNetStatusIconControl()
    UpdateNetStatusIcon(header)
end

function scene:create( event )
    local sceneGroup = self.view

    playerPoint = display.newImageRect(sceneGroup, "themables/PlayerTemplate.png", 48, 60) 
    playerPoint.anchorX = 0.5
    playerPoint.anchorY = 0.5

    playerHeading = display.newImageRect(sceneGroup, "themables/headingIndicator.png", 60, 60)
    playerHeading.anchorX = 0.5
    playerHeading.anchorY = 0.5

    CreateFullMapDisplayTC(sceneGroup, defaultSizes)
    gameMapDisplayTC:insert(sceneGroup)

    local ZoomOut = display.newImageRect(sceneGroup, "themables/ZoomOut.png",300, 100)
    ZoomOut.x = 200
    ZoomOut.y = 1850
    ZoomOut:addEventListener("tap", ZoomOutTC)

    local ZoomIn = display.newImageRect(sceneGroup, "themables/ZoomIn.png",300, 100)
    ZoomIn.x = 860
    ZoomIn.y = 1850
    ZoomIn:addEventListener("tap", ZoomInTC)

    menu = MakeMenu("Control")
    menu.cancelListener:addEventListener("tap", HideMenu)
    menu.x = -1080

    local menuButton = display.newImageRect(sceneGroup, "themables/MenuButton.png",300, 100)
    menuButton.x = 530
    menuButton.y = 1850
    menuButton:addEventListener("tap", ShowMenuControl)

    header = MakeHeaderBar(false)
    sceneGroup:insert(header)
    netStatusTimer = timer.performWithDelay(50, UpdateNetStatusIconControl, -1)

    --Adding some pop-up overlays that aren't actually overlays.
    claimScreen = display.newGroup()
    claimTouchLock = display.newRect(claimScreen, display.contentCenterX, display.contentCenterY, 1080, 1920)     --blocks touches for the background
    claimTouchLock.fill = {0, 0, 0, .01}
    claimTouchLock:addEventListener("tap", blockTouch)
    claimBg = display.newRect(claimScreen, display.contentCenterX, display.contentCenterY, 900, 1700)
    claimBg.fill = {.6, .6, .5, 1}
    claimName = display.newText({parent = claimScreen, text = "", x = 300, y = 900, width = 500})
    claimName.anchorX = 0
    claimName.anchorY = 0
    claimScore = display.newText({parent = claimScreen, text = "", x = 300, y = 1100})
    claimScore.anchorX = 0
    claimClaimButton = display.newImageRect(claimScreen, "themables/ClaimButton.png", 300, 100)
    claimClaimButton.x = display.contentCenterX - 200
    claimClaimButton.y = display.contentCenterY + 500
    claimClaimButton:addEventListener("tap", claimThisPlace)
    claimAttackButton = display.newImageRect(claimScreen, "themables/AttackButton.png", 300, 100)
    claimAttackButton.x = display.contentCenterX - 200
    claimAttackButton.y = display.contentCenterY + 700
    claimAttackButton:addEventListener("tap", attackThisPlace)
    claimCancelButton = MakeCancelButton(display.contentCenterX + 200, display.contentCenterY + 700, claimScreen, hideClaimOverlay)

    --Make the pyramid icons.
    local coreX = display.contentCenterX
    local coreY = display.contentCenterY
    local pyramidXvals = {coreX,       coreX - 64, coreX + 64,    coreX - 128, coreX, coreX + 128,   coreX - 192, coreX - 64, coreX + 64, coreX  + 192,     coreX - 256, coreX - 128, coreX, coreX + 128, coreX + 256}
    local pyramidYvals = {200,         328, 328,                  456, 456, 456,                     584, 584, 584, 584,                                    712, 712, 712, 712, 712}

    for i = 1, 15, 1 do
        local pyramidIcon = MakeCreaturePyramidIcon(claimScreen, nil, pyramidXvals[i], pyramidYvals[i], 16 -1)
        table.insert(pyramidIcons, pyramidIcon) --for later tracking and updating.
    end
    claimScreen.x = -2500 --way offscreen.

    attackResultText = display.newText({parent = sceneGroup, text = "Victory!", x = -display.contentCenterX, y = display.contentCenterY})
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        gameMapDisplayTC.isVisible = true
    elseif ( phase == "did" ) then
        UpdateScrollViewTC(0)
        updateLoopTimer = timer.performWithDelay(updateLoopDelay, UpdateLoopTC, -1)
        TCTileTimer = timer.performWithDelay(modeTileDelay, CheckForTCTiles, -1)
        CheckForTCTiles()
        currentGpsCallback = WalkaroundGpsCallbackTC
        onPlusCodeChangeCallback = nil
        RedrawEntireMap() --Allows zoom to stay consistent between mode swaps.
        RequestTutorial("controlIntro")
        muniTimer = timer.performWithDelay(15000, GetMuniTimed, -1)
    end
end

function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        gameMapDisplayTC.isVisible = false
        timer.cancel(updateLoopTimer)
        timer.cancel(TCTileTimer)
        timer.cancel(muniTimer)
        timer.cancel(netStatusTimer)
        currentGpsCallback = nil
        onPlusCodeChangeCallback = nil
    elseif ( phase == "did" ) then
 
    end
end

function scene:destroy( event )
    local sceneGroup = self.view
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
 
return scene