local composer = require( "composer" )
local scene = composer.newScene()
local widget = require("widget")
local json = require("json")
local lfs = require('lfs')
require("plusCodes")
require("PraxisMapper")
require('helpers')
require("common")
local thisScenesView = '' 

local menu = {}
local updateLoopTimer = nil
local PVETileTimer = nil
local gameMapDisplayPVE = {} -- scrollview 
local gameMapTilesPVE = {} -- background map tiles
local coverMapTiles = {} -- overlay cover pve maptiles.
local playerHeading = {}
local muniTimer = {}
local header = {}
local netStatusTimer = {}

local attackResultText = {}
local lastSentCreature = {}

--claim modal
local placeScreen = {}
local placeName = ''
local placeScore = ''
local placeCreature = ''
local placePlaceButton = ''
local placeCancelButton = ''
local placeAttackButton = ''
local placeData = {}
local lastTappedCode = ''
local fragments ={} --placeholder for stepper control.
local pickedCreatureId = 0
local placeFragmentCountText = {} -- the text to update on tap
local placeCreatureLevel = {}

local pickScreen = {}
local placeIcon = {}

local fullMapOverlay = {}
local fullMapImage = {}

local leaderboardOverlay = {}
local leaderboardText = {}

local placeFragments = {}
local lastTappedAreaInfo = {}
local lastStepperValue = 0

--TODO:

function CheckTileGenerationPVE(plusCode)
    if (plusCode == '') then return end

    if (DoesFileExist(plusCode .. "-PVE.png", system.TemporaryDirectory) == false) then
        GetCoverTile(plusCode)
    end 
end

local function GetTileListener(event)
    NetUp()
    if NetCallCheck(event.status) == true then
        local plusCode = string.gsub(event.url, serverURL .. "MapTile/Area/", "")

        for tile = 1, #gameMapTilesPVE do
            if gameMapTilesPVE[tile].pluscode == plusCode then
                if PaintOneTile(gameMapTilesPVE[tile], plusCode .. '.png', system.CachesDirectory, true) == false then GetNewTile(plusCode, GetTileListener) end
                return
            end
        end
    end
end

local function RedrawEntireMapPVE()
    gameMapDisplayPVE:removeSelf()
    CreateFullMapDisplayPVE(scene.view, zoomData[currentZoom])
    UpdateScrollViewPVE(0)
    ScrollCallbackPvE()
end

--NOTE: CoverPVE tap tester doesn't work on Cell11 logic.
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

    lastTappedCode = tapPlusCode
    GetTappedElementRequestPVE(tapPlusCode)
    return true
end

function GetTappedElementRequestPVE(plusCode)
    local url = serverURL .. 'Cover/Placed/' .. plusCode 
    network.request(url, "GET", TappedElementListenerPVE, normalParams)
    composer.showOverlay("overlays.LoadingOverlay")
end

function TappedElementListenerPVE(event)
    --expected results in JSON:
    --creatureId 
      -- creatureFragmentCount 
        --locationCell10 
        --strength

    if NetCallCheck(event.status) == false then
        composer.hideOverlay()
        return 
    end

    placeName.text = lastTappedCode
    placeData = json.decode(event.response)
    
    pickedCreatureId = 0
    lastTappedAreaInfo = nil
    if(placeData == nil) then
        placeFragments.isVisible = false
        placeFragmentCountText.text = '0'
        placeCreatureLevel.text = '0'
        placeFragments:setValue(0)
        composer.hideOverlay()
        showPlaceOverlay()
        return
    end

    if (placeData.creatureId == 0) then
        placeFragmentCountText.text = '0'
        placeCreatureLevel.text = '0'
        placeFragments.isVisible = false
        placeFragments:setValue(0)
        composer.hideOverlay()
        showPlaceOverlay()
        return
    end

    placeName.text = placeData.locationCell10
    lastTappedCode = placeData.locationCell10
    placeFragments.isVisible = true
    local creatureData = FindCreatureById(placeData.creatureId)
    local myCreatureData = myCreatures[tostring(creatureData.id)]

    placeFragments.maximumValue = myCreatureData.currentAvailable
    local thisCreatureLevel = GetLevelByFragments(creatureData.name, placeData.creatureFragmentCount)
    placeCreatureLevel.text = thisCreatureLevel
    placeFragments:setValue(thisCreatureLevel)
    pickedCreatureId = placeData.creatureId
    
    placeIcon.fill = {
        type = "image",
        filename = creatureData.imageName,
        baseDir = system.DocumentsDirectory
    }

    local maxFrags = myCreatureData.currentAvailable + placeData.creatureFragmentCount
    local maxLevel = GetLevelByFragments(creatureData.name, maxFrags)
    placeFragments.maximumValue = maxLevel

    placeFragmentCountText.text = placeData.creatureFragmentCount
    placeCreature.text = creatureData.name

    lastTappedAreaInfo = placeData
    placePlaceButton.isVisible = true

    composer.hideOverlay()
    showPlaceOverlay()
end

function GetCoverTile(plusCode)
    local params = GetImageDownloadParams(plusCode .. '-PVE.png', system.TemporaryDirectory)
    local url = serverURL .. 'MapTile/PlacedOverlay/' .. plusCode
    QueueCall(url, 'GET', CoverTileListener, params)
end

function CoverTileListener(event)
    NetUp()
    local pieces = Split(event.url, '/')
    local plusCode = pieces[#pieces]
    if NetCallCheck(event.status) == false then
        return
    end
    --save file, draw file.
    for tile = 1, #coverMapTiles do
        if coverMapTiles[tile].pluscode == plusCode then
            if PaintOneTile(coverMapTiles[tile], plusCode .. '-PVE.png', system.TemporaryDirectory) == false then 
            end
            return
        end
    end
end

function WalkaroundGpsCallbackPVE(event)
    ScrollToPlayerLocation(gameMapDisplayPVE, playerPoint, currentMapValues, 0, playerHeading)
    playerHeading.rotation = currentHeading
    header.locText.text = "Loc: " .. currentPlusCode
    header.muniDisplay.text = currentMuni
    if (event.accuracy ~= nil) then --doesnt work in simulator.
        header.accuracyLabel.text = math.round(event.accuracy) .. 'm'
    end
end

function ZoomInPVE(event)
    currentZoom = currentZoom - 1
    if (currentZoom == 0) then
        currentZoom = 1
        return true
    end

    RedrawEntireMapPVE()
    return true
end

function ZoomOutPVE(event)
    currentZoom = currentZoom + 1
    if (currentZoom > #zoomData) then
        currentZoom = #zoomData
        return true
    end

    RedrawEntireMapPVE()
    return true
end

function PauseUpdateTimer()
    if updateLoopTimer ~= nil then        
        timer.pause(updateLoopTimer)
    end
end

function ScrollCallbackPvE()
    if (updateLoopTimer ~= nil) then
        timer.resume(updateLoopTimer)
    end
end

function CreateFullMapDisplayPVE(gridGroup, sizeProps) 
    PauseUpdateTimer()
    currentMapValues = sizeProps
    gameMapTilesPVE = {}
    coverMapTiles = {}

    playerPoint.width = currentMapValues.playerPointWidth
    playerPoint.height = currentMapValues.playerPointHeight

    playerHeading.width = currentMapValues.playerPointHeight --correct, this image is square and we want the larger value.
    playerHeading.height = currentMapValues.playerPointHeight

    gameMapDisplayPVE = CreateBaseMapDisplay(TapTester)
    CreateInnerGrid(gridGroup, gameMapTilesPVE, gameMapDisplayPVE)
    CreateInnerGrid(gridGroup, coverMapTiles, gameMapDisplayPVE)

    gameMapDisplayPVE:insert(playerPoint)
    playerPoint:toFront()
    
    gameMapDisplayPVE:insert(playerHeading)
    playerHeading:toFront()

    gameMapDisplayPVE:toBack()
    ScrollToPlayerLocation(gameMapDisplayPVE, playerPoint, currentMapValues, 0, playerHeading)
end

function UpdateScrollViewPVE(speed)
    --call this when current and previous plus code are different.
    for tile = 1, #gameMapTilesPVE do
        local thisTilesPlusCode = currentPlusCode
        thisTilesPlusCode = ShiftCell(thisTilesPlusCode, gameMapTilesPVE[tile].gridX, 8)
        thisTilesPlusCode = ShiftCell(thisTilesPlusCode, gameMapTilesPVE[tile].gridY, 7)
        thisTilesPlusCode = thisTilesPlusCode:sub(1,8)    

        --Check if this imageRect has a different plusCode (meaning the player walked into a new Cell8)
        --and if so we have some extra processing to do.
        if gameMapTilesPVE[tile].pluscode ~= thisTilesPlusCode then
            gameMapTilesPVE[tile].pluscode = thisTilesPlusCode
            coverMapTiles[tile].pluscode = thisTilesPlusCode
            if PaintOneTile(gameMapTilesPVE[tile], thisTilesPlusCode .. '.png', system.CachesDirectory, true) == false then GetNewTile(thisTilesPlusCode, GetTileListener) end
            if PaintOneTile(coverMapTiles[tile], thisTilesPlusCode .. '-PVE.png', system.TemporaryDirectory) == false then GetCoverTile(thisTilesPlusCode) end
        end   
    end
    ScrollToPlayerLocation(gameMapDisplayPVE, playerPoint, currentMapValues, speed)    
end

function CheckForPVETiles()
    for i = 1, #coverMapTiles do
        CheckTileGenerationPVE(coverMapTiles[i].pluscode)
    end
end

function UpdateLoopPVE()
    local cell8 = currentPlusCode:sub(1,8)
    local cell10 = RemovePlus(currentPlusCode)
    if cell8 ~= lastDrawnPlusCode then
        UpdateScrollViewPVE(0) -- resets all the tiles drawn, if necessary.
        lastDrawnPlusCode = cell8        
    end
end

function hidePlaceOverlay(event)
    placeScreen.x = -2500
    placeName.text = ''
    placeScore.text = ''
    placeCreature.text = ''
    placeIcon.fill = {
        type = "image",
        filename = 'themables/PickCreature.png'
    }
    return true
end

function showPlaceOverlay(event)
    placeScreen.x = 0
    return true
end

local function PlacePickedCreature()
    local url = serverURL .. "Cover/Placed/"  .. lastTappedCode .. '/' .. pickedCreatureId ..  '/' .. placeFragmentCountText.text
    network.request(url, "PUT", PlaceCreatureListenerPVE, normalParams)
    hidePlaceOverlay()   
end

function PlaceCreatureListenerPVE(event)
    --TODO: on failure, restore locally the fragment count used on the given creature. Both parameter are in the URl
    if NetCallCheck(event.status) == false then
    end    

    local fragsSpent = tonumber(event.response)
    local placedCreature = myCreatures[tostring(pickedCreatureId)]
    placedCreature.currentAvailable = placedCreature.currentAvailable - fragsSpent

    --Remove all PVE maptiles now.
    local temp_path = system.pathForFile("", system.TemporaryDirectory)
    for file in lfs.dir(temp_path) do
        -- "file" is the current file or directory name
        if EndsWith(file, "-PVE.png") then
            os.remove(system.pathForFile(file, system.TemporaryDirectory))
        end
        for tile = 1, #coverMapTiles do
            if coverMapTiles[tile].pluscode == plusCode then
                if PaintOneTile(coverMapTiles[tile], plusCode .. '.png', system.TemporaryDirectory) == false then GetCoverTile(thisTilesPlusCode) end
                return
            end
        end
    end
    
    CheckForPVETiles()
end

function placeThisPlace(event)
    PlacePickedCreature()
    return true
end

local function ClosePickWindowE()
    pickScreen:removeSelf()
end

local function SetPickedE(self, event) 
    pickedCreatureId = self.creatureId
    local creature = FindCreatureById(pickedCreatureId)
    placeIcon.fill = {
        type = "image",
        filename = creature.imageName,
        baseDir = system.DocumentsDirectory
    }
    placeFragments.isVisible = true
    placeCreature.text = creature.name
    placeFragments.minimumValue = 0
    placeFragments.maximumValue = creature.currentAvailable
    placePlaceButton.isVisible = true
    ClosePickWindowE()
end

local function FillPickWindowE(tapHandler)
    pickScreen = FillPickWindow(SetPickedE, FilterCreaturesHasFragments, ClosePickWindowE) 
end

local function stepperOnPress(event)
    local currentLevel = tonumber(placeCreatureLevel.text)
    local thisBaseCreature = FindCreatureById(pickedCreatureId)
    local thisCreature = myCreatures[tostring(pickedCreatureId)]

    local fragTotal = 0
    if event.value > currentLevel then
        --count up to the next level if possible
        local newFragTotal = TotalFragmentsToLevel(thisBaseCreature.name, currentLevel + 1)
        local addition = 0
        if placeData ~= nil then addition = placeData.creatureFragmentCount end
        if newFragTotal <= (thisCreature.currentAvailable + addition) then
            placeCreatureLevel.text = currentLevel + 1
            fragTotal = newFragTotal
        else
            fragTotal = TotalFragmentsToLevel(thisBaseCreature.name, currentLevel)
            placeFragments:setValue(currentLevel)
        end
    else
        --count down to the previous level if possible.
        if (currentLevel == 0) then return end
        fragTotal = TotalFragmentsToLevel(thisBaseCreature.name, currentLevel - 1)
        if fragTotal > 0 then
            placeCreatureLevel.text = tonumber(placeCreatureLevel.text) - 1
        else
            fragTotal = 0
            placeCreatureLevel.text = '0'
            placeFragments:setValue(0)
        end
    end
    placeFragmentCountText.text =  fragTotal
end

local function LeaderboardListener(event)
    if NetCallCheck(event.status) == false then
        leaderboardText.text = 'Network error'
        return
    end

    local results = json.decode(event.response)
    local text = ''

    for k,v in pairs(results) do
        text = text .. k .. ': ' ..  v.DeviceID .. ' (' .. v.score .. ')\n'
    end
    leaderboardText.text = text
end

local function GetLeaderboard(event)
    leaderboardOverlay.x = 0
    local url = serverURL .. 'Cover/Leaderboards'
    network.request(url,'GET', LeaderboardListener, normalParams)
    return true
end

local function HideLBoverlay(event)
    leaderboardOverlay.x = -2500
    leaderboardText.text = ''
    return true
end

local function ShowMenuCover(event)
    menu.name.text = playerData.name
    ShowMenu(menu)
    return true
end

 local function HideMenu()
    transition.moveTo(menu, {x = -1080, time = menuSlideSpeed})
    return true
 end

function UpdateNetStatusIconCover()
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

    CreateFullMapDisplayPVE(sceneGroup, defaultSizes)
    gameMapDisplayPVE:insert(sceneGroup)

    local ZoomOut = display.newImageRect(sceneGroup, "themables/ZoomOut.png",300, 100)
    ZoomOut.x = 200
    ZoomOut.y = 1850
    ZoomOut:addEventListener("tap", ZoomOutPVE)

    local ZoomIn = display.newImageRect(sceneGroup, "themables/ZoomIn.png",300, 100)
    ZoomIn.x = 860
    ZoomIn.y = 1850
    ZoomIn:addEventListener("tap", ZoomInPVE)

    local leaderboard = display.newImageRect(sceneGroup, "themables/LeaderboardButton.png",300, 100)
    leaderboard.x = 530
    leaderboard.y = 1850
    leaderboard:addEventListener("tap", GetLeaderboard)

    placeScreen = display.newGroup()
    placeTouchLock = display.newRect(placeScreen, display.contentCenterX, display.contentCenterY, 1080, 1920)     --blocks touches for the background
    placeTouchLock.fill = {0, 0, 0, .01}
    placeTouchLock:addEventListener("tap", blockTouch)
    placeBg = display.newRect(placeScreen, display.contentCenterX, display.contentCenterY, 700, 1400)
    placeBg.fill = {.6, .6, .5, 1}
    
    placeName = display.newText({parent = placeScreen, text = "", x = 300, y = 300}) --the plus code tapped
    placeName.anchorX = 0
    placeName.anchorY = 0
    placeScore = display.newText({parent = placeScreen, text = "", x = 300, y = 400}) --Unused right now.

    placeIcon = display.newImageRect(placeScreen, "themables/PickCreature.png", 256, 256)
    placeIcon.x = display.contentCenterX
    placeIcon.y = 600
    placeIcon:addEventListener("tap", FillPickWindowE)
    
    placeCreature = display.newText({parent = placeScreen, text = "", x = display.contentCenterX, y = 800})
    placeCreature.anchorY = 0  

    --stepper widget to handle setting amount. Requires stepper texture, 5 frames.
    placeFragments = widget.newStepper({ x = display.contentCenterX, y = 1300, sheet = stepperSkin, onPress = stepperOnPress, timerIncrementSpeed = 125 })
    placeScreen:insert(placeFragments)

    placeFragLabel = display.newText({parent = placeScreen, text = "Fragments:", x = 200, y = 900})
    placeFragLabel.anchorX = 0

    placeFragmentCountText = display.newText({parent = placeScreen, text = "", x = display.contentCenterX, y = 900})
    placeFragmentCountText.text = '1'

    placeCreatureLevelLabel = display.newText({parent = placeScreen, text = "Level:", x = 200, y = 1000})
    placeCreatureLevelLabel.anchorX = 0
    placeCreatureLevel = display.newText({parent = placeScreen, text = "1", x = display.contentCenterX, y = 1000})

    placePlaceButton = display.newImageRect(placeScreen, "themables/PlaceButton.png", 300, 100)
    placePlaceButton.x = display.contentCenterX - 200
    placePlaceButton.y = display.contentCenterY + 600
    placePlaceButton.isVisible = false
    placePlaceButton:addEventListener("tap", placeThisPlace)
    placeCancelButton = MakeCancelButton(display.contentCenterX + 200, display.contentCenterY + 600, placeScreen, hidePlaceOverlay)
    placeScreen.x = -2500 --way offscreen.

    header = MakeHeaderBar(false)
    sceneGroup:insert(header)
    netStatusTimer = timer.performWithDelay(50, UpdateNetStatusIconCover, -1)

    leaderboardOverlay = display.newGroup()
    lbTouchLock = display.newRect(leaderboardOverlay, display.contentCenterX, display.contentCenterY, 1080, 1920)     --blocks touches for the background
    lbTouchLock.fill = {0, 0, 0, .01}
    lbTouchLock:addEventListener("tap", blockTouch)
    lbBg = display.newRect(leaderboardOverlay, display.contentCenterX, display.contentCenterY, 700, 1400)
    lbBg.fill = {.6, .6, .5, 1}

    lbHeader = display.newText({parent = leaderboardOverlay, text = "Cover High Scores", x = display.contentCenterX, y = 300})
    leaderboardText = display.newText({parent = leaderboardOverlay, text = "", x = 250, y = 400})
    leaderboardText.anchorY = 0
    leaderboardText.anchorX = 0

    lbCancel = MakeCancelButton(display.contentCenterX, display.contentCenterY + 600, leaderboardOverlay, HideLBoverlay)
    leaderboardOverlay.x = -2500

    menu = MakeMenu("Cover")
    menu.cancelListener:addEventListener("tap", HideMenu)
    menu.x = -1080

    local menuButton = display.newImageRect(sceneGroup, "themables/MenuButton.png",300, 100)
    menuButton.x = 530
    menuButton.y = 1850
    menuButton:addEventListener("tap", ShowMenuCover)
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
         gameMapDisplayPVE.isVisible = true
    elseif ( phase == "did" ) then
         UpdateScrollViewPVE(0)
        updateLoopTimer = timer.performWithDelay(updateLoopDelay, UpdateLoopPVE, -1)
        CheckForPVETiles()
        currentGpsCallback = WalkaroundGpsCallbackPVE
        onPlusCodeChangeCallback = nil
        RedrawEntireMapPVE()
        RequestTutorial("coverIntro")
        muniTimer = timer.performWithDelay(15000, GetMuniTimed, -1)
    end
end
 
function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        gameMapDisplayPVE.isVisible = false
        timer.cancel(updateLoopTimer)
        timer.cancel(muniTimer)
        timer.cancel(netStatusTimer) 
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