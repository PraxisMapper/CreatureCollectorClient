local composer = require("composer")
local scene = composer.newScene()
local widget = require("widget")
local json = require("json")
require("plusCodes")
require("PraxisMapper")
require("common")
local thisScenesView = '' 

local pauseScrolling = false
local updateLoopTimer = nil
local CreatureCheckTimer = nil
local gameMapDisplay = {}
local gameMapTiles = {}
local caughtSlideover = {}
local slideoverIcon = {}
local slideoverText = {}
local vortexButton = {}
local availableImages = {}

local possibleCreatures = {}
local netStatusTimer = {}

local active = ''
local playerPoint = {}
local playerHeading = {}
local headerLoc = {}

local creatureDict = {} --creature data by cell8
local creatureIconDict = {} --Use this to have a reference to creature icons outside of the scrollview. Should be the guid for the key, and the imageRect for the value upon revision.
local creatureIconGroup = {} -- display group for creature icons.
local menu = {}
local header = {}

function WalkaroundGpsCallback(event)
    --This callback occurs on every GPS event
    if pauseScrolling == false then
        ScrollToPlayerLocation(gameMapDisplay, playerPoint, currentMapValues, 125, playerHeading)
    end
    header.locText.text = "Loc: " .. currentPlusCode
    playerHeading.rotation = currentHeading
    header.muniDisplay.text = currentMuni

    if (event.accuracy ~= nil) then --doesnt work in simulator.
        header.accuracyLabel.text = math.round(event.accuracy) .. 'm'
    end
end

function WalkaroundPlusCodeChangesCallback()
    --This callback only occurs if we're in a different Cell10 plusCode than the previous GPS event.
    --Call the server have it do all the server-side stuff for us.
    local url = serverURL .. 'Creature/Enter/' .. RemovePlus(currentPlusCode)
    network.request(url, 'PUT', EnterCellCallback, normalParams)
    GetMuni(RemovePlus(currentPlusCode))
end

function EnterCellCallback(event)
    if NetCallCheck(event.status) == true then
         --null reponses are 204(no content), don't get processed.
         if event.status == 204 then return end
        local results = json.decode(event.response)
        playerData.currencies.baseCurrency = playerData.currencies.baseCurrency + results.coinsGranted
        if (results ~= nil and results.creatureIdCaught ~= 0) then
            CatchCreature(results)
        end
    end
end

local function RedrawEntireMap()
    gameMapDisplay:removeSelf()
    creatureIconDict = {}
    CreateFullMapDisplay(scene.view, zoomData[currentZoom])
    UpdateScrollView(0)
end

local function ZoomIn(event)
    currentZoom = currentZoom - 1
    if (currentZoom == 0) then
        currentZoom = 1
        return
    end

    RedrawEntireMap()
end

local function ZoomOut(event)
    currentZoom = currentZoom + 1
    if (currentZoom > #zoomData) then
        currentZoom = #zoomData
        return
    end

    RedrawEntireMap()
end

local function PauseUpdateTimer()
    if updateLoopTimer ~= nil then
        timer.pause(updateLoopTimer)
        pauseScrolling = true
    end
end

local function ScrollCallback()
    if (updateLoopTimer ~= nil) then
        timer.resume(updateLoopTimer)
        pauseScrolling = false
    end
end

function CreateFullMapDisplay(gridGroup, sizeProps) 
    PauseUpdateTimer()
    currentMapValues = sizeProps
    gameMapTiles = {}

    playerPoint.width = currentMapValues.playerPointWidth
    playerPoint.height = currentMapValues.playerPointHeight

    playerHeading.width = currentMapValues.playerPointHeight --correct, this image is square and we want the larger value.
    playerHeading.height = currentMapValues.playerPointHeight

    gameMapDisplay = CreateBaseMapDisplay(nil)
    
    CreateInnerGrid(gridGroup, gameMapTiles, gameMapDisplay)

    gameMapDisplay:insert(playerPoint)
    playerPoint:toFront()

    gameMapDisplay:insert(playerHeading)
    playerHeading:toFront()

    --need to recreate creatureIconGroup and icons.
    creatureIconGroup = display.newGroup()
    gameMapDisplay:insert(creatureIconGroup)
    gameMapDisplay:toBack()
    
    ScrollToPlayerLocation(gameMapDisplay, playerPoint, currentMapValues, 0, playerHeading)
    ScrollCallback()
end

function ClearAllCreatureIcons()
    creatureIconGroup:removeSelf()
    creatureIconGroup = display.newGroup()
    gameMapDisplay:insert(creatureIconGroup)
end

local function GetTileListener(event)
    --update the appropriate map tile.
    NetUp()
    if NetCallCheck(event.status) == true then
        local plusCode = Split(string.gsub(event.url, serverURL .. "MapTile/Area/", ""), '/')[1]

        for tile = 1, #gameMapTiles do
            if gameMapTiles[tile].pluscode == plusCode then
                if PaintOneTile(gameMapTiles[tile], plusCode .. '.png', system.CachesDirectory, true) == false then GetNewTile(plusCode, GetTileListener) end
                return
            end
        end
    end
end

function UpdateScrollView(speed)
    --call this when current and previous pluscode8 are different.
    PauseUpdateTimer()
    GetPossibleSpawns()

    for tile = 1, #gameMapTiles do
        local thisTilesPlusCode = currentPlusCode
        thisTilesPlusCode = ShiftCell(thisTilesPlusCode, gameMapTiles[tile].gridX, 8)
        thisTilesPlusCode = ShiftCell(thisTilesPlusCode, gameMapTiles[tile].gridY, 7)
        thisTilesPlusCode = thisTilesPlusCode:sub(1,8)

        --everything already got removed at hte start of this function
         if math.abs(gameMapTiles[tile].gridX) > 1 or math.abs(gameMapTiles[tile].gridY) > 1 then
             if (creatureDict[thisTilesPlusCode] ~= nil) then
                creatureDict[thisTilesPlusCode] = {} --ensure this entry exists later
             end
         end

        --Check if this imageRect has a different plusCode (meaning the player walked into a new Cell8)
        --and if so we have some extra processing to do.
        if gameMapTiles[tile].pluscode ~= thisTilesPlusCode then
            gameMapTiles[tile].pluscode = thisTilesPlusCode
            if PaintOneTile(gameMapTiles[tile], thisTilesPlusCode .. '.png', system.CachesDirectory, true) == false then GetNewTile(thisTilesPlusCode, GetTileListener) end
        end   
        DrawOneTileCreatureIcons(thisTilesPlusCode)
    end

    CreatureCheck() --Normally on a 10sec timer, this force-queues it up immediately.
    ScrollToPlayerLocation(gameMapDisplay, playerPoint, currentMapValues, 0, playerHeading)
    ScrollCallback()
end

function ToggleVortexVisible()
    vortexButton.isVisible = false
    if playerData.currencies.vortexTokens < 1 then
        return
    end

    local count = 0
    for i,v in pairs(creatureDict) do
        for ii, vv in pairs(v) do
            count = count + 1
            if (count >= 20) then
                vortexButton.isVisible = true
                return
            end
        end
    end
end

function DrawOneTileCreatureIcons(plusCode)
    for tile = 1, #gameMapTiles do
        if (gameMapTiles[tile].pluscode == plusCode)then 
            local thisTilesPlusCode =  gameMapTiles[tile].pluscode

            local thingsToDraw = creatureDict[plusCode]
            if (thingsToDraw ~= nil) then
                local baseX = gameMapTiles[tile].x 
                local baseY = gameMapTiles[tile].y  + currentMapValues.cellSizeY

                local padX = currentMapValues.padding * (gameMapTiles[tile].gridX - 1)
                local padY = currentMapValues.padding * (gameMapTiles[tile].gridY - 1)

                for k,v in pairs(thingsToDraw) do
                    --remove all creatures before adding them back.
                    if (creatureIconDict[v.uid] ~= nil and creatureIconDict[v.uid].removeSelf ~= nil) then
                        creatureIconDict[v.uid]:removeSelf()
                        creatureIconDict[v.uid] = nil
                    end

                    MakeCreatureIcon(gameMapTiles[tile], v)
                end 
            else
            end
        end
    end
end

function MakeCreatureIcon(mapTile, creature)
    local baseX = mapTile.x 
    local baseY = mapTile.y  + currentMapValues.cellSizeY

    local shift = CODE_ALPHABET_:find(creature.plusCode:sub(10, 10)) - 1 -- X 
    local shift2 = CODE_ALPHABET_:find(creature.plusCode:sub(9, 9)) - 1 -- Y

    --draw the memory fragment here.
    local thisIcon = display.newImageRect(creatureIconGroup, 'themables/CreatureMarker.png', currentMapValues.cell10SizeX, currentMapValues.cell10SizeY)
    thisIcon.x = baseX + (currentMapValues.cell10SizeX * shift) 
    thisIcon.y = baseY - (currentMapValues.cell10SizeY * shift2)

    thisIcon.anchorX = 0
    thisIcon.anchorY = 1
    creatureIconGroup:insert(thisIcon)
    
    if creatureIconDict[creature.uid] ~= nil and creatureIconDict[creature.uid].removeSelf ~= nil then
        creatureIconDict[creature.uid]:removeSelf()
    end
    creatureIconDict[creature.uid] = thisIcon
end

function DrawAllCreatureIcons()
    for tile = 1, #gameMapTiles do
        DrawOneTileCreatureIcons(gameMapTiles[tile].pluscode)
    end
end

function UpdateLoop()
    local cell8 = currentPlusCode:sub(1,8)
    if cell8 ~= lastDrawnPlusCode then
        --new attempt and making this scene more reliable
        RedrawEntireMap()

        --Original set
        --ClearAllCreatureIcons()
        --UpdateScrollView(0) -- resets all the tiles drawn, if necessary.
        --DrawAllCreatureIcons()
        lastDrawnPlusCode = cell8
    end
end

function CreatureCheck() --updates list of wild creatures from server.
    for tile = 1, #gameMapTiles do
        if math.abs(gameMapTiles[tile].gridX) <= 1 and math.abs(gameMapTiles[tile].gridY) <= 1 then 
            GetCreatures(gameMapTiles[tile].pluscode)
        end
    end
end
 
function GetCreatures(plusCode8)
    local url = serverURL .. 'Creature/Wild/' .. plusCode8
    QueueCall(url, "GET", GetCreaturesListener, normalParams)
end

function GetCreaturesListener(event)
    NetUp()
    if NetCallCheck(event.status) == true then
        local plusCode = Split(string.gsub(string.gsub(event.url, serverURL .. "Creature/Wild/", ""), "/creature", ""), '?')[1]
        plusCode = Split(plusCode, '/')[1]
        local results = json.decode(event.response)
        if (results == nil) then
            return
        end
        local existing = creatureDict[plusCode]
        if (existing == nil) then
            creatureDict[plusCode] = {}
            existing = creatureDict[plusCode]
        end
        --Remove our current icons before adding new ones
        for k, v in pairs(existing) do
            if creatureIconDict[v.uid] ~= nil then
                if creatureIconDict[v.uid].removeSelf == nil then
                    --nothing
                else
                    creatureIconDict[v.uid]:removeSelf()
                    creatureIconDict[v.uid] = nil
                end
            end
            existing[k] = nil
        end

        for k,v in pairs(results) do
            --Server determined which creatures we can see. We dont have to filter them.
            local creature = json.decode(v.value)
            creature.plusCode = v.plusCode
            if existing[creature.plusCode] == nil then
                existing[v.plusCode] = creature
            else
                --this one already exists. Skip this step.
            end
        end
        creatureDict[plusCode] = existing
        DrawOneTileCreatureIcons(plusCode)
    end

    ToggleVortexVisible()
end

function CatchCreature(creatureData) --show the player they caught something
    local creature = FindCreatureById(creatureData.creatureIdCaught)
    composer.setVariable("creatureCaught", creatureData)
    BoostCreatureData(creature.name) 

    local cellCreatures = creatureDict[creatureData.plusCode:sub(1,8)]
    if (cellCreatures ~= nil) then
        for k, v in pairs(cellCreatures) do
            if (v.uid == creatureData.creatureUidCaught) then
                cellCreatures[k] = nil
            end
        end
    end

    if (creatureIconDict[creatureData.creatureUidCaught] ~= nil) then
        creatureIconGroup:remove(creatureIconDict[creatureData.creatureUidCaught])
        creatureIconDict[creatureData.creatureUidCaught]:removeSelf()
        creatureIconDict[creatureData.creatureUidCaught] = nil
    end

    DrawOneTileCreatureIcons(creatureData.plusCode:sub(1,8))

    local paint = {
        type = "image",
        filename = creature.imageName,
        baseDir =  system.DocumentsDirectory
    }
    slideoverIcon.fill = paint
    slideoverText.text = "You Collected " .. creature.name
    transition.cancel(caughtSlideover)
    transition.moveTo(caughtSlideover, {x = 0, time = menuSlideSpeed})
    timer.performWithDelay(2000, CaughtSlideOff, 1)
    RedrawPossibleCreatures()

    if (activeOn == true and composer.getSceneName("overlay") == nil and (creatureData.activeGame ~= nil and creatureData.activeGame ~= '')) then
        composer.showOverlay("overlays.ActiveScene" .. creatureData.activeGame, {isModal = true})
    end
end

function CaughtSlideOff()
    transition.cancel(caughtSlideover)
    transition.moveTo(caughtSlideover, {x = -400, time = menuSlideSpeed})
end

function AskForTeam()
    --Keeping this as a fall-back, in case a player opens the game up after graduation and needs a team but doesn't get the tutorial.
    if (playerData.team == 0) then
        composer.showOverlay("overlays.TeamSelectOverlay")
    end
 end

 local function ShowMenuCollect(event)
    menu.name.text = playerData.name
    ShowMenu(menu)
    return true
 end

 local function HideMenu()
    transition.moveTo(menu, {x = -1080, time = menuSlideSpeed})
    return true
 end

 local function VortexListener(event)
    if NetCallCheck(event.status) == false then
        return
    end

    if (event.response == '') then
        native.showAlert("Vortex Results", "There weren't enough creature fragments to collect, your token was saved.")
        return
    end

    local resultString = "You Obtained:\n"
    --result is a Dict<long, long>, of <creatureId, count>

    local data = json.decode(event.response)
    for i, v in pairs(data) do
        local creature = FindCreatureById(tonumber(i))
        resultString = resultString .. creature.name .. ": " .. v .. '\n'
    end

    playerData.currencies.vortexTokens = playerData.currencies.vortexTokens - 1
    if (playerData.currencies.vortexTokens <= 0) then
        vortexButton.isVisible = false
    end

    local centerCell = currentPlusCode:sub(1,8)
    for x = -1, 1 do
        for y = -1, 1 do
            local mapTileCell8 = ShiftCellNoPlus(centerCell, x, 8)
            mapTileCell8 = ShiftCellNoPlus(mapTileCell8, y, 7)
            creatureDict[mapTileCell8] = nil
        end
    end
    ClearAllCreatureIcons()
    UpdateScrollView(0)

    --set this on a popup window. Could upgrade this to its own actual screen instead of a native popup.
    native.showAlert("Vortex Results", resultString)
 end

 local function Vortex(event)
    local url = serverURL .. 'Creature/Vortex/' .. currentPlusCode:sub(1,8)
    network.request(url, "PUT", VortexListener, normalParams)
 end

local function CompareOnTotalCaught(a, b)
    return a.totalCaught < b.totalCaught
end

 local function GetPossibleSpawnsListener(event)
    if NetCallCheck(event.status) == false then
        return
    end

    --response is a list of ids
    local jsonVal = json.decode(event.response)  
    local displayEntries = {}
    --pull out relevant data
    for k,v in pairs(jsonVal) do
        local myCreatureInfo = myCreatures[tostring(v)]
        if (myCreatureInfo == nil) then
            table.insert(displayEntries, {id = v, totalCaught = 0})
        else
            table.insert(displayEntries, {id = v, totalCaught = myCreatureInfo.totalCaught})
        end
    end
    
    --sort creatures by least-to-most totalCaught
    table.sort(displayEntries, CompareOnTotalCaught)
    possibleCreatures = displayEntries

    --now set 3 imageRects to the appropriate paint from 1 to 3 that we sorted above.
    RedrawPossibleCreatures()
end

function RedrawPossibleCreatures()
    for i = 1, 3 do 
        local thisCreature = FindCreatureById(possibleCreatures[i].id)
        if (thisCreature ~= nil) then --Shouldn't happen, but sometimes it does this very first thing opening the scene. More common if an art update happened?
            local myCreatureInfo = myCreatures[tostring(possibleCreatures[i].id)]
            local imgPaint = {
                type = "image",
                filename = thisCreature.imageName,
                baseDir =  system.DocumentsDirectory
            }
            header.availableImages[i].fill = imgPaint
            if possibleCreatures[i].totalCaught == 0 then
                SilhouetteImage(header.availableImages[i])
            end
        end
    end
end

function GetPossibleSpawns()
    MakeUnqueuedRequest('Creature/Possible/' .. currentPlusCode:sub(1,8), GetPossibleSpawnsListener)
end

function UpdateNetStatusIconCollect()
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

    CreateFullMapDisplay(sceneGroup, defaultSizes)
    gameMapDisplay:insert(sceneGroup)

    local zoomOut = display.newImageRect(sceneGroup, "themables/ZoomOut.png",300, 100)
    zoomOut.x = 200
    zoomOut.y = 1850
    zoomOut:addEventListener("tap", ZoomOut)

    local zoomIn = display.newImageRect(sceneGroup, "themables/ZoomIn.png",300, 100)
    zoomIn.x = 860
    zoomIn.y = 1850
    zoomIn:addEventListener("tap", ZoomIn)

    menu = MakeMenu("Collect")
    menu.cancelListener:addEventListener("tap", HideMenu)
    menu.x = -1080

    local menuButton = display.newImageRect(sceneGroup, "themables/MenuButton.png",300, 100)
    menuButton.x = 530
    menuButton.y = 1850
    menuButton:addEventListener("tap", ShowMenuCollect)

    header = MakeHeaderBar(true)
    sceneGroup:insert(header)
    netStatusTimer = timer.performWithDelay(50, UpdateNetStatusIconCollect, -1)

    vortexButton = display.newImageRect(sceneGroup, "themables/VortexButton.png",300, 100)
    vortexButton.x = 530
    vortexButton.y = 1700
    vortexButton:addEventListener("tap", Vortex)
    vortexButton.isVisible = playerData.currencies.vortexTokens > 0

    --now putting the caught creature 'overlay' here as a UI element.
    caughtSlideover = display.newGroup()
    bg = display.newRect(caughtSlideover, 0, 0, 400, 500)
    bg.anchorX = 0
    bg.anchorY =0
    bg.fill = bgFill
    slideoverText = display.newText(caughtSlideover, "You Collected ", 25, 350, 400, 100, native.systemFont, 30)
    slideoverText.anchorX = 0
    slideoverText.anchorY = 0
    slideoverText.fill = {0, 1} --black text

    slideoverIcon = display.newImageRect(caughtSlideover, "themables/PickCreature.png", 300, 300)
    slideoverIcon.x = 25
    slideoverIcon.y = 25
    slideoverIcon.anchorX = 0
    slideoverIcon.anchorY = 0

    caughtSlideover.x = -400
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        gameMapDisplay.isVisible = true
    elseif ( phase == "did" ) then
        UpdateScrollView(0)
        --if updateLoopTimer == nil then
            updateLoopTimer = timer.performWithDelay(updateLoopDelay, UpdateLoop, -1)
        --end
        --if CreatureCheckTime == nil then
            CreatureCheckTimer = timer.performWithDelay(creatureCheckDelay, CreatureCheck, -1)
        --end
        if netStatusTimer == nil then
            netStatusTimer = timer.performWithDelay(50, UpdateNetStatusIcon, -1)
        end
        
        currentGpsCallback = WalkaroundGpsCallback
        onPlusCodeChangeCallback = WalkaroundPlusCodeChangesCallback
        RedrawEntireMap() --Allows zoom to stay consistent between mode swaps.
            if(RequestTutorial("story1") == false) then
                AskForTeam() --If we aren't doing the intro tutorial to ask for a team, and don't have a team, ask for it explicitly.
            end
        
        WalkaroundPlusCodeChangesCallback() --Fired manually here so that we catch anything we're standing on when starting up or switching modes.
    end
end

function scene:hide( event ) 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        gameMapDisplay.isVisible = false
        currentGpsCallback = nil
        onPlusCodeChangeCallback = nil
        transition.cancel(caughtSlideover)
        if (updateLoopTimer ~= nil) then timer.cancel(updateLoopTimer) end
        if (CreatureCheckTimer ~= nil) then timer.cancel(CreatureCheckTimer) end
        if (netStatusTimer ~= nil) then timer.cancel(netStatusTimer) end
 
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