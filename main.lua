-- main.lua
require('common')
require("helpers")
require("plusCodes")
require("networkStatus")
require("PraxisMapper")
require("transitionFunctions")
require("gameSettings")
local composer = require("composer")
json = require("json")

credentials = {}
dataVersions = {}
configInfo = {}
tileGenInfo = {}

system.setIdleTimer(false) --disables screen auto-off.
reauthTimer = {}

debugGPS = false

simultaneousNetCalls = 7 

if system.getInfo("environment") == "simulator" then
    debugGPS = true
    --serverURL = serverSimulatorURL
end

suggestedProxyPoint = ''
authToken = ''
authExpiration = 0

tutorialsViewed = {}
currentMuni = ''

display.setDefault("magTextureFilter", "nearest")
display.setDefault("minTextureFilter", "nearest")

function AddAuthHeaders(headers)
    headers.AuthKey = authToken
    return headers 
end

function ClearAuthHeaders()
    authToken = ''
    normalParams.headers = AddAuthHeaders(normalParams)
    binaryParams.headers = AddAuthHeaders(binaryParams)
end

function AskForTeam()
    if (playerData.team == 0) then
        composer.showOverlay("overlays.TeamSelectOverlay")
    end
 end

--used for proxyPlay math.
startingPoint = {}
currentAltitude = 0
--speedCap = 11 --how many meters per second locks you out of speed-related challenges. 11 is ~24 MPH.

--The complete list of values a creature entry will have this schema, though some tables may be nil if they're unnecessary:
creatureInfo = {
    sample = {id = 1, name = "test", imageName = "test.png", stats = {
        multiplierPerLevel = 2.1,  addedPerLevel = 0, strengthPerLevel = 1, scoutingPerLevel = 1, defensePerLevel  = 1,
        terrainSpawns = { park = 1 }, areaSpawns = { CC = 2}, placeSpawns = { PlaceName = 2}, specificSpawns = { AABBCCDDEE }, 
        isPermanent = false, activeCatchType = "ABCDE", activeCatchDifficulty = 1, artist = "", rights ="", flavorText = "", hintText = "", isWild =true,
        isHidden = false, eliteId = 2, passportReward = false, spawnTimes = { start = '11:00', _end = '15:00'}, spawnDates = {stats = '3/10/2000', _end = '3/17/2000'},
        tierRating = 1, wanderOdds = 0, wanderSpawnEntries = 0
        },
    }
}

--account specific data. This is where I'll want to check when I look for active creatures. This is PlayerCreatureInfo on the plugin side.
--assignedTo will either be a PlusCode (ping server to see if its still there) or a string to indicate which task its on for the user.
--NOTE: this is indexed by creatureID, but uses a string instead of number because of how C# converts Dictionary<int, T>
myCreatures = {
    asdf = { level = 0, available = true, assignedTo = "", totalCaught = 0, toNextLevel = 1, strength = 1}
}
playerDataDirty = false

function FindCreatureByName(creatureName)
    for i, v in ipairs(creatureInfo) do
        if (v.name == creatureName) then
            return v
        end
    end
end

function FindCreatureById(creatureId)
    for i, v in ipairs(creatureInfo) do
        if (v.id == creatureId) then
            return v
        end
    end
end

function ActiveChallengeSuccess(creature)
    BoostCreatureById(creature.eliteId)
    local url = serverURL .. 'Creature/ChallengeDone/' .. creature.id
    network.request(url, 'PUT', ActiveChallengeHandler, normalParams)
end

function ActiveChallengeHandler(event)
    NetCallCheck(event.status)
end

function BoostCreatureById(creatureId)
    local c = FindCreatureById(creatureId)
    BoostCreatureData(c.name)
end

function BoostCreatureData(creatureName)
    local creatureBaseData = FindCreatureByName(creatureName)
    local creatureData = myCreatures[tostring(creatureBaseData.id)]

    if (creatureData == nil) then
        creatureData = { id= creatureBaseData.id, level = 1, available = true, currentAvailable = 1, assignedTo = "", totalCaught = 1, toNextLevel = math.floor(creatureBaseData.stats.multiplierPerLevel) + creatureBaseData.stats.addedPerLevel, strength = creatureBaseData.stats.strength}
    else
        creatureData.totalCaught = creatureData.totalCaught + 1
        creatureData.toNextLevel = creatureData.toNextLevel - 1
        if creatureData.currentAvailableCompete == nil then
            creatureData.currentAvailableCompete = 1
        else
            creatureData.currentAvailableCompete = creatureData.currentAvailableCompete + 1
        end

        if creatureData.currentAvailable == nil then
            creatureData.currentAvailable = 1
        else
            creatureData.currentAvailable = creatureData.currentAvailable + 1
        end
        
        if creatureData.toNextLevel <= 0 then
            creatureData.level = creatureData.level + 1
            creatureData.toNextLevel = math.floor(creatureData.level * creatureBaseData.stats.multiplierPerLevel) + (creatureData.level * creatureBaseData.stats.addedPerLevel)
            creatureData.strength = creatureBaseData.stats.strengthPerLevel * creatureData.level
            creatureData.defense = creatureBaseData.stats.defensePerLevel * creatureData.level
            creatureData.scouting = creatureBaseData.stats.scoutingPerLevel * creatureData.level
        end
    end
    myCreatures[tostring(creatureBaseData.id)] = creatureData
end

function GetLevelByFragments(creatureName, fragments)  
    if (fragments == 0) then return 0 end
    local creatureBaseData = FindCreatureByName(creatureName)
    local creatureLevel = 1
    fragments = fragments - 1
    local toNextLevel = math.floor(creatureLevel * creatureBaseData.stats.multiplierPerLevel) + (creatureLevel * creatureBaseData.stats.addedPerLevel)
    while(toNextLevel <= fragments) do
        fragments = fragments - toNextLevel
        creatureLevel = creatureLevel + 1
        toNextLevel = math.floor(creatureLevel* creatureBaseData.stats.multiplierPerLevel) + (creatureLevel * creatureBaseData.stats.addedPerLevel)
    end 

    return creatureLevel
end

function TotalFragmentsToLevel(creatureName, level)
    if (level == 0) then return 0 end
    local creatureBaseData = FindCreatureByName(creatureName)
    local totalFragments = 1
    local creatureLevel = 1
    while(creatureLevel < level) do
        totalFragments = totalFragments + math.floor((creatureLevel * creatureBaseData.stats.multiplierPerLevel) + (creatureLevel * creatureBaseData.stats.addedPerLevel))
        creatureLevel = creatureLevel + 1
    end

    return totalFragments
end

playerData = {
    name = '', --account handle
    team = 0,
    proxyPlayPoint = {}, --if nil, use current location instead of proxy-play.
    controlInfo ="",
    currencies = {
        baseCurrency = 0,
        instantWinTokens = 0,
        proxyPlayTokens = 1,
        teamSwapTokens = 0,
        vortexTokens = 0
    },
    totalGrants = 0,
    dateCreated = '1/25/2020',
    graduationEligible = false,
    lastAudit = '1/25/2020'
}

passportData = {
    {
        type = '',
        count = 0,
        currentEntries = { --list of strings
            ""
        }, 
    },
}

maxZoomedInSizes = { gridSize = 3, cellSizeX = 1280, cellSizeY = 1600, padding = 2, cell10SizeX = 64, cell10SizeY = 80,  cell11SizeX = 16, cell11SizeY = 16, playerPointOffsetX = 32, playerPointOffsetY = 40, viewWidth = 1080, viewHeight = 1920, viewX = 370, viewY = 500, playerPointWidth = 192, playerPointHeight = 240} --cell11 is 16x16, probably the point where i want to use cell11s for claiming stuff instead of cell10 if detecting Places instead of Areas.
--veryZoomedInSizes = { gridSize = 3, cellSizeX = 960, cellSizeY = 1200, padding = 2, cell10SizeX = 48, cell10SizeY = 60, playerPointOffsetX = 24, playerPointOffsetY = 30, viewWidth = 1080, viewHeight = 1920, viewX = 370, viewY = 500, playerPointWidth = 144, playerPointHeight = 180} --pretty huge zoom in, cell11 is 12x12
--veryZoomedInSizes is not particularly distinct from maxZoomedInSized in play.
zoomedInSizes = { gridSize = 5, cellSizeX = 640, cellSizeY = 800, padding = 2, cell10SizeX = 32, cell10SizeY = 40, playerPointOffsetX = 16, playerPointOffsetY = 20, viewWidth = 1080, viewHeight = 1920, viewX = 370, viewY = 500, playerPointWidth = 96, playerPointHeight = 120} --means that a Cell11 is 8x8 pixels. probably still too small to reliably click.
defaultSizes = { gridSize = 7, cellSizeX = 320, cellSizeY = 400, padding = 2, cell10SizeX = 16, cell10SizeY = 20, playerPointOffsetX = 8, playerPointOffsetY = 10, viewWidth = 1080, viewHeight = 1920, viewX = 0, viewY = 0, playerPointWidth = 48, playerPointHeight = 60}  --means that a Cell11 is 4x4 pixels. Not yet clickable?
zoomedOutSizes = { gridSize = 13, cellSizeX = 160, cellSizeY = 200, padding = 2, cell10SizeX = 8, cell10SizeY = 10, playerPointOffsetX = 4, playerPointOffsetY = 5, viewWidth = 1080, viewHeight = 1920, viewX = 370, viewY = 500, playerPointWidth = 24, playerPointHeight = 30} --original tile resolution. 2x2 cell11 resolution
--veryZoomedOutSizes = { gridSize = 19, cellSizeX = 80, cellSizeY = 100, padding = 2, cell10SizeX = 4, cell10SizeY = 5, playerPointOffsetX = 2, playerPointOffsetY = 2, viewWidth = 1080, viewHeight = 1920, viewX = 370, viewY = 500, playerPointWidth = 12, playerPointHeight = 15} --original tile resolution. Each pixel is 1 Cell11 in size.
--removed VeryZoomedOut because its very likely to kill the server while generating tiles. That's almost 800 calls for tiles in non-collect modes per player. Too much work if someone's in a car.

currentZoom = 3
zoomData = {}
table.insert(zoomData, maxZoomedInSizes)
--table.insert(zoomData, veryZoomedInSizes)
table.insert(zoomData, zoomedInSizes)
table.insert(zoomData, defaultSizes)
table.insert(zoomData, zoomedOutSizes)
--table.insert(zoomData, veryZoomedOutSizes)

creatureSaveTimer = {}
updateCheckTimer = {}

    if DoesFileExist('credentials.json', system.DocumentsDirectory) == false then
        print('credentials file exists')
        credentials = {username = '', password = ''}
        SaveToFile('credentials.json', credentials)
    else
        credentials = LoadFromFile('credentials.json')
        if (credentials. username == nil or credentials.username == '') then
            print('Credentials file exist, but is empty.')
        end
    end

    if DoesFileExist('dataVersions.json', system.DocumentsDirectory) == false then
        dataVersions = { creatureDataVersion = 1, artDataVersion = 1 }
        SaveToFile('dataVersions.json', dataVersions)
    else
        dataVersions = LoadFromFile('dataVersions.json')
    end

    if DoesFileExist('configInfo.json', system.DocumentsDirectory) == false then
        print('creating config info.')
        configInfo = { mapTileStyle = 'mapTiles'}
        SaveToFile('configInfo.json', configInfo)
    else
        configInfo = LoadFromFile('configInfo.json')
        print('loaded config info')
    end
    
    if DoesFileExist('tileGenInfo.json', system.DocumentsDirectory) == false then
        tileGenInfo = { } -- {plusCode = {stylesetA = "", styleSetB = "", ...}}
        SaveToFile('tileGenInfo.json', tileGenInfo)
    else
        tileGenInfo = LoadFromFile('tileGenInfo.json')
    end


function SaveTileGenInfoTimed()
    print('saving tile gen info.')
    SaveToFile('tileGenInfo.json', tileGenInfo)
end
timer.performWithDelay(15000, SaveTileGenInfoTimed, -1)

local isPendingReauth = false
function ReAuth()
    print("Reauth occurring!")
    if isPendingReauth == true then
        return
    end

    if (credentials.password == nil) then
        credentials = LoadFromFile('credentials.json')
    end

    local url = serverURL .. "Server/Login/"  .. credentials.username .. "/" .. credentials.password
    network.request(url, "GET", ReauthListener, normalParams)
 end

 function ReauthListener(event)
    isPendingReauth = false
    if (event.status == 204 or event.status == 200) then
        if (event.response == "") then
            --We failed to reauth, retry again in 20 seconds.
            print('delaying reauth')
            timer.performWithDelay(20000, ReAuth, 1)
        else
            local authData = json.decode(event.response)
            authToken = authData.authToken

            authExpiration = os.time() + authData.expiration
            normalParams.headers = AddAuthHeaders(normalParams.headers)
            binaryParams.headers = AddAuthHeaders(binaryParams.headers)
        end
    end
 end

function SpecialHandlingCheck() --Find things that have happened on the server that the client needs to update. Area changes, creatures returned, etc.
    local url = serverURL .. 'Tibo/Updates/'
    network.request(url, "GET", SpecialHandlingHandler, normalParams)
end

function SpecialHandlingHandler(event)
    if (event.status ~= 200) then
        SpecialHandlingCheck()
    end

    local commandList = json.decode(event.response)
    if commandList == nil or #commandList == 0 then
        return
    end

    for k,v in pairs(commandList) do
        if v.verb == "RETURN" then
            myCreatures[v.target].available = true
            myCreatures[v.target].assignedTo = ""
        elseif v.verb == "GRADUATE" then
            RequestTutorial("graduation")
        elseif v.verb == "RETURNCOMPETE" then
            print('returning compete fragments')
            local values = Split(v.target, '|')
            myCreatures[values[1]].currentAvailableCompete = myCreatures[values[1]].currentAvailableCompete + tonumber(values[2])
            print("returned " .. values[2] .. ' fragments to ' .. myCreatures[values[1]].name .. ', now has ' .. myCreatures[values[1]].currentAvailableCompete 'of ' .. myCreatures[values[1]].totalCaught)
        end
    end

    --check each entry, do whatever it says to our data.
    --schema: 
    --{verb: "asdf", target: "asdf"}
    --verb - RETURN target - creatureName: set this creature's available to true, assignedTo = ""
    --verb - ADDSCORE target - "": add a bunch of credits to the acccount
end

function LoadMyCreatureInfo()
    local url = serverURL .. 'Creature/CreatureInfo/'
    network.request(url, "GET", LoadCreatureInfoHandler, normalParams)
end

function LoadCreatureInfoHandler(event)
    if (event.status == 200) then
        local parsedData = json.decode(event.response)
        if (parsedData ~= nil) then
            myCreatures = parsedData
        end
        updateCheckTimer = timer.performWithDelay(4000, SpecialHandlingCheck, -1)
    else
        LoadMyCreatureInfo()
    end
end

currentPlusCode = ''
lastPlusCode = ''

currentGpsCallback = nil
onPlusCodeChangeCallback = nil
previousGpsCallback = nil

--store server bounds in memory on startup.
serverBounds = {
    south = -90,
    west = -180,
    north = 90,
    east = 180
}
playerInBounds = false

function InBounds(lat, lon)
    if (lat >= serverBounds["south"] and lat <= serverBounds["north"]) then
        if (lon >= serverBounds["west"] and lon <= serverBounds["east"]) then
            return true
        end
    end
    return false
end

function FakeScroll()
        lastPlusCode = currentPlusCode
        --currentPlusCode = ShiftCell(currentPlusCode, 1, 9) -- move north
        currentPlusCode = ShiftCell(currentPlusCode, 1, 10) -- move east
        --currentPlusCode = ShiftCell(currentPlusCode, -1, 10) -- move west
        --currentPlusCode = ShiftCell(currentPlusCode, 1, 9) -- move north
        if onPlusCodeChangeCallback ~= nil then
            onPlusCodeChangeCallback()
        end

    currentHeading = currentHeading + 5
    if (currentHeading > 360) then
        currentHeading = 0
    end

    if (currentGpsCallback ~= nil) then
        timer.performWithDelay(1, currentGpsCallback, 1)
    end
end

totalGpsCalls = 0
function GpsListener(event)
    if (event.errorCode ~= nil) then
        return
    end
    totalGpsCalls = totalGpsCalls + 1

    if (event.direction ~= 0) then
         currentHeading = event.direction
    end

    local lat = event.latitude
    local lon = event.longitude
    currentAltitude = event.altitude

    playerInBounds = InBounds(lat, lon)
    if (playerInBounds == false) then
        RequestTutorial('proxyPlayOOB')
    end

    if playerData.proxyPlayPoint ~= nil and startingPoint.lat ~= nil then 
        --get shift from starting point, then use that data against proxy play point.
        lat = playerData.proxyPlayPoint.lat + (lat - startingPoint.lat)  --lat is bigger going north. moving north should make this value positive.
        lon = playerData.proxyPlayPoint.lon + (lon - startingPoint.lon)  --lon is bigger going east. moving east should make this value positive.
    end

    local NewPluscode = EncodeLatLon(lat, lon, 11); --May allow this to go to 11 eventually. Seems to current have issues with that now.
    if (currentPlusCode ~= NewPluscode) then
        lastPlusCode = currentPlusCode
        currentPlusCode = NewPluscode
        if (onPlusCodeChangeCallback ~= nil) then
            onPlusCodeChangeCallback()
        end
    end

    --TODO: this may be replaced with using multiple callbacks directly on the location event.
    if (currentGpsCallback ~= nil) then
        currentGpsCallback(event)
    end
end

function BackListener(event) --TODO: remove this from release builds.
    if (event.keyName == "back" and event.phase == "up") then
        if (currentScene == "TestScene") then
            return false
        end
        local options = {effect = "flip", time = 125}
        composer.gotoScene("scenes.TestScene", options)
        return true
    end
end

if debugGPS == true then
    timer.performWithDelay(1000, FakeScroll,  -1)
end

Runtime:addEventListener("location", GpsListener)
--Runtime:addEventListener("key", BackListener)
timer.performWithDelay(5, NetQueueCheck,  -1) -- in networkStatus.lua

function HasFinishedTutorial(dialog)
    for i = 1, #tutorialsViewed, 1 do
        if tutorialsViewed[i] == dialog then
            return true
        end
    end
    return false
end

function RequestTutorial(dialog) --ask to show this tutorial if it hasn't been shown before.
    local currentOverlay = composer.getSceneName("overlay")
    if (currentOverlay ~= nil) then
        print('returning false because overlay already exists:' .. currentOverlay)
        return false
    end

    for i = 1, #tutorialsViewed, 1 do
        if tutorialsViewed[i] == dialog then
            print('returning false because this tutorial has already been shown')
            return false
        end
    end
    composer.setVariable("tutorialData", dialog)
    composer.showOverlay("overlays.tutorialOverlay", {isModal = true})
    print('returning true because tutorial is being shown')
    return true
end

function ForceTutorial(dialog) --show the tutorial regardless if it's been shown before.
    composer.setVariable("tutorialData", dialog)
    composer.showOverlay("overlays.tutorialOverlay", {isModal = true})
end

--create imagesheets here
stepperSkin = graphics.newImageSheet('themables/StepperSkin.png', {width = 500, height = 250, numFrames = 5})

composer.gotoScene("scenes.AccountLoginScene")