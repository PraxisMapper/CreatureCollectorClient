local composer = require( "composer" )
local scene = composer.newScene()
local widget = require("widget")
local json = require("json")
local lfs = require('lfs')
require('helpers')
require("common")
require("plusCodes")
require("PraxisMapper")
local thisScenesView = '' 

--Compete mode: Teams place creatures anywhere and work to have more of the map under circles of their color.
--TODO:

local menu = {}
local updateLoopTimer = nil
local PVPTileTimer = nil
local gameMapDisplayPVP = {} -- scrollview 
local gameMapTilesPVP = {} -- background map tiles
local competeMapTiles = {} -- overlay compete pvp maptiles.
local pvpTileTimer = {}
local playerHeading = {}

local header = {}
local muniTimer = {}

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
local placeFragLabel = {}
local attackerName = {}
local attackerLevel = {}
local attackerLevelLabel = {}
local attackResults = {}

local pickScreen = nil
local placeIcon = {}

local leaderboardOverlay = {}
local leaderboardText = {}

local placeFragments = {}
local lastTappedAreaInfo = {}
local lastStepperValue = 0

local netStatusTimer = {}
--TODO:

function CheckTileGenerationPVP(plusCode)
    if (plusCode == '') then return end

    local url = serverURL .. "MapTile/Generation/" .. plusCode .. "/Compete"
    QueueCall(url, "GET", TileGenHandlerPVP, normalParams)
end

function TileGenHandlerPVP(event)
    NetUp()

    if NetCallCheck(event.status) == false then
        return
    end

    local piece = string.gsub(event.url, serverURL .. "MapTile/Generation/", "")
    local pieces = Split(piece, '/') -- 1 = plusCode, 2 = styleSet (Compete)
    local answer = event.response

    if (answer == 'Timed out') then
        --abort this logic!
        return
    end
    local imageExists = false
    imageExists = DoesFileExist(pieces[1] .. "-PVP.png", system.TemporaryDirectory)

    local hasData = false
    local redownload = false
    local tileGen = 0
    local tileInfoOnPlusCode = tileGenInfo[pieces[1]]
    if tileInfoOnPlusCode ~= nil then
        if tileInfoOnPlusCode.Compete ~= nil then
            hasData = true
            tileGen = tileInfoOnPlusCode.Compete
        end
    end
    

    --loop, but should be 1 result.
        if hasdData == true and tonumber(tileGen) < tonumber(answer)then
            tileGenInfo[pieces[1]].Compete = answer
            redownload = true
        end

    if hasData == false then
        tileGenInfo[pieces[1]] = { Compete = answer }
        redownload = true
    end
    
    redownload = (imageExists == false) or redownload or answer == '-1'
    if redownload then
        GetCompeteTile(pieces[1])
    end
end

local function ClosePickWindowPVP()
    pickScreen:removeSelf()
    pickScreen = nil
end

local function SetAttacker(self, event) 
    pickedCreatureId = self.creatureId
    local creature = FindCreatureById(pickedCreatureId)
    placeAttackerIcon.fill = {
        type = "image",
        filename = creature.imageName,
        baseDir = system.DocumentsDirectory
    }
    attackerName.text = creature.name
    local attackerLevelVal = GetLevelByFragments(creature.name, myCreatures[tostring(creature.id)].currentAvailableCompete)
    attackerLevel.text = attackerLevelVal
    placeAttackButton.isVisible = true
    ClosePickWindowPVP()
end

local function FillPickWindowPVP(tapHandler)
    if (placeData.teamId ~= 0 or tapHandler.numTaps > 1 or pickScreen ~= nil) then --Don't change established points, and don't run this twice.
        return
    end
    if (pickScreen == nil) then
        pickScreen = FillPickWindow(SetPickedE, FilterCreaturesHasCompeteFragments, ClosePickWindowPVP) 
    else
        print("FillPickWindowPVP already ran once, why did it fire off again?")
    end
    return true
end

local function FillPickWindowAttack(tapHandler)
    placeAttackButton.isVisible = false
    pickScreen = FillPickWindow(SetAttacker, FilterCreaturesHasCompeteFragments, ClosePickWindowPVP) 
end

local function RedrawEntireMapPVP()
    gameMapDisplayPVP:removeSelf()
    CreateFullMapDisplayPVP(scene.view, zoomData[currentZoom])
    UpdateScrollViewPVP(0)
end

--NOTE: CompetePVP tap tester doesn't work on Cell11 logic.
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
    tapPlusCode = tapPlusCode:sub(1,8)

    lastTappedCode = tapPlusCode:sub(1,8)
    GetTappedElementRequestPVP(tapPlusCode)
    return true
end

function GetTappedElementRequestPVP(plusCode)
    local url = serverURL .. 'Compete/Placed/' .. plusCode 
    network.request(url, "GET", TappedElementListenerPVP, normalParams)
    composer.showOverlay("overlays.LoadingOverlay")
end

function TappedElementListenerPVP(event)
    --expected results in JSON:
    --creatureId 
    --teamId
    -- creatureFragmentCount --array of user IDs and counts. Look up ours here.
    --locationCell8
    --totalFragments
    --scouting

    if NetCallCheck(event.status) == false then
        composer.hideOverlay()
        return 
    end

    placeName.text = lastTappedCode
    placeData = json.decode(event.response)

    print(dump(placeData))

    if placeData == nil or placeData.totalFragments == 0 or placeData.teamId == playerData.team then
        --Same team or empty place, use contribution logic
        print("using contribution logic ")
       
        pickedCreatureId = 0
        lastTappedAreaInfo = nil
        if(placeData == nil) then
            pcall(RemoveStepper)
            placeFragmentCountText.text = '0'
            placeCreatureLevel.text = '0'
            composer.hideOverlay()
            showPlaceOverlayPVP()
            return
        end

        if (placeData.creatureId == 0) then
            placeFragmentCountText.text = '0'
            placeCreatureLevel.text = '0'
            pcall(RemoveStepper)
            placeIcon.isVisible = true
            placeIcon2.isVisible = false
            placePlaceButton.isVisible = false
            placeAttackButton.isVisible = false
            composer.hideOverlay()
            showPlaceOverlayPVP()
            return
        end

        local creatureData = FindCreatureById(placeData.creatureId)
        local myCreatureData = myCreatures[tostring(creatureData.id)]

        local myContribution = placeData.creatureFragmentCounts[playerData.name] 
        local creatureMinLevel = GetLevelByFragments(creatureData.name, placeData.totalFragments - myContribution)
        local creatureCurrentLevel = GetLevelByFragments(creatureData.name, placeData.totalFragments)

        placeName.text = placeData.locationCell8
        lastTappedCode = placeData.locationCell8
        MakeStepper(myCreatureData.currentAvailableCompete + myContribution)

        local thisCreatureLevel = GetLevelByFragments(creatureData.name, placeData.totalFragments)
        placeCreatureLevel.text = thisCreatureLevel
        placeFragments:setValue(myContribution)
        pickedCreatureId = placeData.creatureId
        
        placeIcon.fill = {
            type = "image",
            filename = creatureData.imageName,
            baseDir = system.DocumentsDirectory
        }
        placeIcon2.isVisible = false

        placeFragLabel.isVisible = true
        placeFragmentCountText.isVisible = true
        placeFragmentCountText.text = myContribution .. ' / ' .. (myCreatureData.currentAvailableCompete + myContribution) --placeData.creatureFragmentCounts[playerData.name]
        placeCreature.text = creatureData.name

        lastTappedAreaInfo = placeData
        placePlaceButton.isVisible = true
        placeAttackButton.isVisible = false
        placeAttackerIcon.isVisible = false
        placeIcon:addEventListener("tap", FillPickWindowPVP)

        attackerLevel.isVisible = false
        attackerLevelLabel.isVisible = false
        attackerName.isVisible = false

    else
        --different team, use combat logic
        --show creature and its level.
        --and give me a choice of which creature, by level descending, to attack it with.
        print("using combat logic")

        --TODO: could reuse lines marked 'same' across all sets, but ones marked 'different' still need to be in this else.
        local creatureData = FindCreatureById(placeData.creatureId) --same
        local thisCreatureLevel = GetLevelByFragments(creatureData.name, placeData.totalFragments) --same
        placeCreatureLevel.text = thisCreatureLevel --same

        placeCreature.text = creatureData.name --same
        
        --different
        placeIcon2.fill = {
            type = "image",
            filename = creatureData.imageName,
            baseDir = system.DocumentsDirectory
        }
        placeIcon2.isVisible = true
        placeIcon.isVisible = false

        placePlaceButton.isVisible = false -- different
        placeAttackerIcon.isVisible = true --different
        
        placeFragments.isVisible = false --different
        pcall(RemoveStepper)
        placeFragmentCountText.isVisible = false --different
        placeFragLabel.isVisible = false --different

        attackerLevel.isVisible = true --different
        attackerLevelLabel.isVisible = true --different
        attackerName.isVisible = true --different
        
        --same
        lastTappedAreaInfo = placeData
    end

    composer.hideOverlay()
    showPlaceOverlayPVP()
end

function GetCompeteTile(plusCode)
    local params = GetImageDownloadParams(plusCode .. '-PVP.png', system.TemporaryDirectory)
    local url = serverURL .. 'MapTile/CompeteOverlay/' .. plusCode
    QueueCall(url, 'GET', CompeteTileListener, params)
end

function CompeteTileListener(event)
    NetUp()
    local pieces = Split(event.url, '/')
    local plusCode = pieces[#pieces]
    if NetCallCheck(event.status) == false then
        print("get compete tile failed!")
        return
    end
    --save file, draw file.
    for tile = 1, #competeMapTiles do
        if competeMapTiles[tile].pluscode == plusCode then
            if PaintOneTile(competeMapTiles[tile], plusCode .. '-PVP.png', system.TemporaryDirectory) == false then 
            end
            return
        end
    end
end

function WalkaroundGpsCallbackPVP(event)
    ScrollToPlayerLocation(gameMapDisplayPVP, playerPoint, currentMapValues, 0, playerHeading)
    playerHeading.rotation = currentHeading
    header.locText.text = "Loc: " .. currentPlusCode
    header.muniDisplay.text = currentMuni

    if (event.accuracy ~= nil) then --doesnt work in simulator.
        header.accuracyLabel.text = math.round(event.accuracy) .. 'm'
    end
end

function ZoomInPVP(event)
    currentZoom = currentZoom - 1
    if (currentZoom == 0) then
        currentZoom = 1
        return true
    end

    RedrawEntireMapPVP()
    return true
end

function ZoomOutPVP(event)
    currentZoom = currentZoom + 1
    if (currentZoom > #zoomData) then
        currentZoom = #zoomData
        return true
    end

    RedrawEntireMapPVP()
    return true
end

function PauseUpdateTimerPVP()
    if updateLoopTimer ~= nil then        
        timer.pause(updateLoopTimer)
    end
end

function ScrollCallbackPVP()
    if (updateLoopTimer ~= nil) then
        timer.resume(updateLoopTimer)
    end
end

function CreateFullMapDisplayPVP(gridGroup, sizeProps) 
    PauseUpdateTimerPVP()
    currentMapValues = sizeProps
    gameMapTilesPVP = {}
    competeMapTiles = {}

    playerPoint.width = currentMapValues.playerPointWidth
    playerPoint.height = currentMapValues.playerPointHeight

    playerHeading.width = currentMapValues.playerPointHeight --correct, this image is square and we want the larger value.
    playerHeading.height = currentMapValues.playerPointHeight

    gameMapDisplayPVP = CreateBaseMapDisplay(TapTester)
    CreateInnerGrid(gridGroup, gameMapTilesPVP, gameMapDisplayPVP)
    CreateInnerGrid(gridGroup, competeMapTiles, gameMapDisplayPVP)

    gameMapDisplayPVP:insert(playerPoint)
    playerPoint:toFront()
    
    gameMapDisplayPVP:insert(playerHeading)
    playerHeading:toFront()

    gameMapDisplayPVP:toBack()
    ScrollToPlayerLocation(gameMapDisplayPVP, playerPoint, currentMapValues, 0, playerHeading)
    ScrollCallbackPVP()
end

local function GetTileListener(event)
    --update the appropriate map tile.
    NetUp()
    if NetCallCheck(event.status) == true then
        local plusCode = string.gsub(event.url, serverURL .. "MapTile/Area/", "")

        for tile = 1, #gameMapTilesPVP do
            if gameMapTilesPVP[tile].pluscode == plusCode then
                if PaintOneTile(gameMapTilesPVP[tile], plusCode .. '.png', system.CachesDirectory, true) == false then GetNewTile(plusCode, GetTileListener) end
                return
            end
        end
    end
end

function UpdateScrollViewPVP(speed)
    --call this when current and previous plus code are different.
    for tile = 1, #gameMapTilesPVP do
        local thisTilesPlusCode = currentPlusCode
        thisTilesPlusCode = ShiftCell(thisTilesPlusCode, gameMapTilesPVP[tile].gridX, 8)
        thisTilesPlusCode = ShiftCell(thisTilesPlusCode, gameMapTilesPVP[tile].gridY, 7)
        thisTilesPlusCode = thisTilesPlusCode:sub(1,8)    

        --Check if this imageRect has a different plusCode (meaning the player walked into a new Cell8)
        --and if so we have some extra processing to do.
        if gameMapTilesPVP[tile].pluscode ~= thisTilesPlusCode then
            gameMapTilesPVP[tile].pluscode = thisTilesPlusCode
            competeMapTiles[tile].pluscode = thisTilesPlusCode
            if PaintOneTile(gameMapTilesPVP[tile], thisTilesPlusCode .. '.png', system.CachesDirectory, true) == false then GetNewTile(thisTilesPlusCode, GetTileListener) end
            if PaintOneTile(competeMapTiles[tile], thisTilesPlusCode .. '-PVP.png', system.TemporaryDirectory) == false then GetCompeteTile(thisTilesPlusCode) end
        end   
    end
    ScrollToPlayerLocation(gameMapDisplayPVP, playerPoint, currentMapValues, speed, playerHeading)
end

function CheckForPVPTiles()
    for i = 1, #competeMapTiles do
        CheckTileGenerationPVP(competeMapTiles[i].pluscode)
    end
end

function UpdateLoopPVP()
    local cell8 = currentPlusCode:sub(1,8)
    local cell10 = RemovePlus(currentPlusCode)
    if cell8 ~= lastDrawnPlusCode then
        UpdateScrollViewPVP(0) -- resets all the tiles drawn, if necessary.
        lastDrawnPlusCode = cell8
    else
        
    end
end

function hidePlaceOverlayPVP(event)
    pickedCreatureId = 0
    placeScreen.x = -2500
    placeName.text = ''
    placeScore.text = ''
    placeCreature.text = ''
    placeIcon.fill = {
        type = "image",
        filename = 'themables/PickCreature.png'
    }
    placeAttackerIcon.fill = {
        type = "image",
        filename = 'themables/PickCreature.png'
    }
    attackerLevel.text = ''
    attackerName.text = ''
    attackResults.text = ''

    placeAttackerIcon.isVisible = false
    attackerLevelLabel.isVisible = false
    placeAttackButton.isVisible = false
    pcall(RemoveStepper)
    return true
end

function showPlaceOverlayPVP(event)
    placeScreen.x = 0
    return true
end

local function PlacePickedCreaturePVP()
    local url = serverURL .. "Compete/Placed/"  .. lastTappedCode:sub(1,8) .. '/' .. pickedCreatureId ..  '/' .. Split(placeFragmentCountText.text, '/')[1]
    network.request(url, "PUT", PlaceCreatureListenerPVP, normalParams)
    hidePlaceOverlayPVP()   
end

function PlaceCreatureListenerPVP(event)
    if NetCallCheck(event.status) == false then
        return
    end    

    --1: plusCode, 2: creature, 3: frag total to apply
    local URLfrags = Split(string.gsub(event.url, serverURL .. "Compete/Placed/", ""), '/')

    local fragsSpent = tonumber(event.response)
    local creatureID = URLfrags[2]
    local placedCreature = myCreatures[creatureID]

    placedCreature.currentAvailableCompete = placedCreature.currentAvailableCompete - fragsSpent
end

function placeThisPlacePVP(event)
    PlacePickedCreaturePVP() 
    return true
end



function SetPickedE(self, event) 
    pickedCreatureId = self.creatureId
    local creature = FindCreatureById(pickedCreatureId)
    local myCreatureData = myCreatures[tostring(creature.id)]
    placeIcon.fill = {
        type = "image",
        filename = creature.imageName,
        baseDir = system.DocumentsDirectory
    }
    MakeStepper(myCreatureData.currentAvailableCompete  + placeData.totalFragments)
    placeCreature.text = creature.name
    placePlaceButton.isVisible = true
    placeFragLabel.isVisible = true
    placeFragmentCountText.isVisible = true
    placeFragmentCountText.text = '0 / ' .. myCreatures[tostring(creature.id)].currentAvailableCompete
    ClosePickWindowPVP()
end

function stepperOnPress(event)
    local currentLevel = tonumber(placeCreatureLevel.text)
    local thisBaseCreature = FindCreatureById(pickedCreatureId)
    local thisCreature = myCreatures[tostring(pickedCreatureId)]
    local myContrib = placeData.creatureFragmentCounts[playerData.name]
    if (myContrib == nil) then
        myContrib = 0
    end
    local otherFrags = placeData.totalFragments --probably unnecessary, pending confirmation.

    placeFragmentCountText.text = event.value .. ' / ' .. event.maximumValue
    local creatureLevel = GetLevelByFragments(thisBaseCreature.name, placeData.totalFragments - myContrib + event.value) -- Remove original contribution, display current value.
    placeCreatureLevel.text = creatureLevel
end

local function LeaderboardListener(event)
    if NetCallCheck(event.status) == false then
        leaderboardText.text = 'Network error'    
    end

    local v = json.decode(event.response)
    local text = ''

    text = text .. "Red: " ..  v.team1Score .. '\n'
    text = text .. "Green: " ..  v.team2Score .. '\n'
    text = text .. "Purple: " ..  v.team3Score .. '\n'
    text = text .. "Grey: " ..  v.team4Score .. '\n'

    leaderboardText.text = text
end

local function GetLeaderboard(event)
    leaderboardOverlay.x = 0
    local url = serverURL .. 'Compete/Leaderboards'
    network.request(url,'GET', LeaderboardListener, normalParams)
    return true
end

local function HideLBoverlay(event)
    leaderboardOverlay.x = -2500
    leaderboardText.text = ''
    return true
end

local function ShowMenuCompete(event)
    menu.name.text = playerData.name
    ShowMenu(menu)
    return true
end

 local function HideMenu()
    transition.moveTo(menu, {x = -1080, time = menuSlideSpeed})
    return true
 end

 local function AttackListener(event)
    if NetCallCheck(event.status) == false then
        attackResults.text = "Network error."
        return
    end
    if (event.response == 'false') then
        attackResults.text = "Failed! Try another creature."
    else
        attackResults.text = "Success!"
        timer.performWithDelay(2000, hidePlaceOverlayPVP, 1)
    end
 end

 local function Attack(event)
    attackResults.text = "Attacking...."
    local url = 'Compete/Attack/' .. lastTappedCode:sub(1,8) .. '/' .. pickedCreatureId
    MakeUnqueuedRequest(url, AttackListener)
 end

 function MakeStepper(maxVal)
    placeFragments = widget.newStepper({ x = display.contentCenterX, y = 1300, sheet = stepperSkin, onPress = stepperOnPress, timerIncrementSpeed = 125, maximumValue = maxVal })
    placeScreen:insert(placeFragments)
 end

 function RemoveStepper(source)
    if source == nil then
        source = 'unnamed'
    end
    if (placeFragments == nil) then
        return
    end
    if (placeFragments.removeSelf == nil) then
        return
    end
    placeFragments:removeSelf()
 end

function UpdateNetStatusIconCompete()
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

    CreateFullMapDisplayPVP(sceneGroup, defaultSizes)
    gameMapDisplayPVP:insert(sceneGroup)

    local ZoomOut = display.newImageRect(sceneGroup, "themables/ZoomOut.png",300, 100)
    ZoomOut.x = 200
    ZoomOut.y = 1850
    ZoomOut:addEventListener("tap", ZoomOutPVP)

    local ZoomIn = display.newImageRect(sceneGroup, "themables/ZoomIn.png",300, 100)
    ZoomIn.x = 860
    ZoomIn.y = 1850
    ZoomIn:addEventListener("tap", ZoomInPVP)

    local leaderboard = display.newImageRect(sceneGroup, "themables/LeaderboardButton.png",300, 100)
    leaderboard.x = 530
    leaderboard.y = 1700
    leaderboard:addEventListener("tap", GetLeaderboard)

    header = MakeHeaderBar(false)
    sceneGroup:insert(header)
    netStatusTimer = timer.performWithDelay(50, UpdateNetStatusIconCompete, -1)

    --Show point tapped and its info
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
    placeIcon:addEventListener("tap", FillPickWindowPVP)

    --2 is used to display when attacking.
    placeIcon2 = display.newImageRect(placeScreen, "themables/PickCreature.png", 256, 256)
    placeIcon2.x = display.contentCenterX
    placeIcon2.y = 600
    placeIcon2.isVisible = false

    placeAttackerIcon = display.newImageRect(placeScreen, "themables/PickCreature.png", 256, 256)
    placeAttackerIcon.x = display.contentCenterX
    placeAttackerIcon.y = 1000
    placeAttackerIcon:addEventListener("tap", FillPickWindowAttack)
    placeAttackerIcon.isVisible = false
    
    placeCreature = display.newText({parent = placeScreen, text = "", x = display.contentCenterX, y = 400})
    placeCreature.anchorY = 0  

    placeFragLabel = display.newText({parent = placeScreen, text = "Fragments:", x = 200, y = 900})
    placeFragLabel.anchorX = 0

    placeFragmentCountText = display.newText({parent = placeScreen, text = "", x = display.contentCenterX + 100, y = 900})
    placeFragmentCountText.text = '1' -- placeFragments.value

    placeCreatureLevelLabel = display.newText({parent = placeScreen, text = "Level:", x = 200, y = 800})
    placeCreatureLevelLabel.anchorX = 0
    placeCreatureLevel = display.newText({parent = placeScreen, text = "1", x = display.contentCenterX, y = 800})

    attackerName = display.newText({parent = placeScreen, text = "", x = display.contentCenterX, y = 1150})
    attackerLevel = display.newText({parent = placeScreen, text = "", x = display.contentCenterX, y = 1200})
    attackerLevel.anchorX = 0
    attackerLevelLabel = display.newText({parent = placeScreen, text = "Level:", x = 200, y = 1200})
    attackerLevelLabel.anchorX = 0
    attackerLevelLabel.isVisible = false
    attackResults = display.newText({parent = placeScreen, text = "", x = display.contentCenterX, y = 1400})

    placeAttackButton = display.newImageRect(placeScreen, "themables/AttackButton.png", 300, 100)
    placeAttackButton.x = display.contentCenterX - 200
    placeAttackButton.y = display.contentCenterY + 600
    placeAttackButton:addEventListener("tap", Attack)
    placeAttackButton.isVisible = false

    placePlaceButton = display.newImageRect(placeScreen, "themables/PlaceButton.png", 300, 100)
    placePlaceButton.x = display.contentCenterX - 200
    placePlaceButton.y = display.contentCenterY + 600
    placePlaceButton.isVisible = false
    placePlaceButton:addEventListener("tap", placeThisPlacePVP)
    placeCancelButton = MakeCancelButton(display.contentCenterX + 200, display.contentCenterY + 600, placeScreen, hidePlaceOverlayPVP)
    placeScreen.x = -2500 --way offscreen.

    leaderboardOverlay = display.newGroup()
    lbTouchLock = display.newRect(leaderboardOverlay, display.contentCenterX, display.contentCenterY, 1080, 1920)     --blocks touches for the background
    lbTouchLock.fill = {0, 0, 0, .01}
    lbTouchLock:addEventListener("tap", blockTouch)
    lbBg = display.newRect(leaderboardOverlay, display.contentCenterX, display.contentCenterY, 700, 1400)
    lbBg.fill = {.6, .6, .5, 1}

    lbHeader = display.newText({parent = leaderboardOverlay, text = "Compete High Scores", x = display.contentCenterX, y = 300})
    leaderboardText = display.newText({parent = leaderboardOverlay, text = "", x = 250, y = 400})
    leaderboardText.anchorY = 0
    leaderboardText.anchorX = 0

    lbCancel = MakeCancelButton(display.contentCenterX, display.contentCenterY + 600, leaderboardOverlay, HideLBoverlay)
    leaderboardOverlay.x = -2500

    menu = MakeMenu("Compete")
    menu.cancelListener:addEventListener("tap", HideMenu)
    menu.x = -1080

    local menuButton = display.newImageRect(sceneGroup, "themables/MenuButton.png",300, 100)
    menuButton.x = 530
    menuButton.y = 1850
    menuButton:addEventListener("tap", ShowMenuCompete)
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        gameMapDisplayPVP.isVisible = true
    elseif ( phase == "did" ) then
        UpdateScrollViewPVP(0)
        updateLoopTimer = timer.performWithDelay(updateLoopDelay, UpdateLoopPVP, -1)
        pvpTileTimer = timer.performWithDelay(modeTileDelay, CheckForPVPTiles, -1)
        CheckForPVPTiles()
        currentGpsCallback = WalkaroundGpsCallbackPVP
        onPlusCodeChangeCallback = nil
        RedrawEntireMapPVP()
        RequestTutorial("competeIntro")
        muniTimer = timer.performWithDelay(15000, GetMuniTimed, -1)
    end
end
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        gameMapDisplayPVP.isVisible = false
        timer.cancel(updateLoopTimer)
        timer.cancel(pvpTileTimer)
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