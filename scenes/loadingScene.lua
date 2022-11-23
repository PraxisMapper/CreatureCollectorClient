local composer = require( "composer" )
local scene = composer.newScene()
local json = require("json")
local lfs = require("lfs")
require("plusCodes")
require("PraxisMapper")
require("networkStatus")
require("common")

local statusText = ""
local bgImage = ""
local loadingTimer = {}

local passportDone = false
local tutorialsDone = false

local tilesRequested = 0

function VersionCheck()
    local url = serverURL .. 'Version'
    network.request(url, 'GET', VersionListener, normalParams)
 end

 function AutoUpdateListener(event)
 end

 function VersionListener(event)
    if NetCallCheck(event.status) == false then
        return
    end

    if (event.response ~= clientVersion) then
        --Safe, lazy version
        native.showAlert('Client Out of Date',  'Please get the latest version of the client. The server has been updated.',  VersionIsOld )
    end
 end

 function VersionIsOld(event)
    native.requestExit()
 end

 function ArtVersion()
    print("getting art version")
    MakeUnqueuedRequest('Tibo/ArtVersion', ArtVersionListener)
 end

 function ArtVersionListener(event)
    print("got art version")
    if NetCallCheck(event.status) == true then
        local version = tonumber(event.response)
        if (version ~= dataVersions.artDataVersion) then
            --delete existing files
            local img_path = system.pathForFile("", system.DocumentsDirectory)
            for file in lfs.dir(img_path) do
                os.remove(system.pathForFile(file, system.DocumentsDirectory))
            end
            GetAllCreatureImages()
            dataVersions.artDataVersion = version
            SaveToFile('dataVersions.json', dataVersions)
        end
    else
        ArtVersion()
    end
 end

timesCalled = 0
function CallsLeftTimer()
    timesCalled = timesCalled + 1
    statusText.text = "Loading calls left: " .. #networkQueue

    if (#networkQueue == 0) then
        statusText.text = "Remote Data Loaded."
        if (startingPoint.lat == nil) then
            statusText.text = statusText.text .. "\nWaiting on accurate location..."
            if (startingPoint.accuracy ~= nil) then
                statusText.text = statusText.text .. '(' .. math.round(startingPoint.accuracy) .. "m, must be under 10m to play)"
            else
                --statusText.text = statusText.text .. 'Waiting on accurate location...'
            end
        else
            statusText.text = statusText.text .. "\nLocation OK. " 
        end
    end

    if (#networkQueue == 0 and passportDone and tutorialsDone and startingPoint.lat ~= nil) then
        statusText.text = 'Opening Game...'
        timer.cancel(loadingTimer)
        GotoMain()
    end
end

function GetAllCreatureImages()
    for k, v in pairs(creatureInfo) do
        if DoesFileExist(v.imageName, system.DocumentsDirectory) == false then
            local params = GetImageDownloadParams(v.imageName, system.DocumentsDirectory)
            local url = serverURL .. "Content/Images/" .. v.imageName
            QueueCall(url, "GET", CreatureImageListener, params)    
        end
    end
end

function CreatureImageListener(event)
    NetUp()
end

gpsEventCount = 0
function loadingGpsListener(event)    
    if (event.errorCode ~= nil) then
        return
    end
    gpsEventCount = gpsEventCount + 1

    startingPoint.accuracy = event.accuracy
    if (event.accuracy <= 10) then
        startingPoint.lat = event.latitude
        startingPoint.lon = event.longitude
        startingPoint.altitude = event.altitude
        Runtime:removeEventListener("location", loadingGpsListener)
    end

    local pluscode = EncodeLatLon(event.latitude, event.longitude, 10); --only goes to 10 right now.
    currentPlusCode = pluscode   
end

function WaitForLocation()
    if system.getInfo("environment") == "simulator" then
        currentPlusCode = "86FRWVFR+HX" -- somewhere in columbus
    end

    if currentPlusCode ~= '' then
        statusText.text = "Contacting server..."
        ServerAlive()
    else
        timer.performWithDelay(25, WaitForLocation, 1)
    end
end

function ServerAlive()
    local url = serverURL .. "Server/Test" 
    QueueCall(url, "GET", ServerAliveListener, normalParams)
end

function ServerAliveListener(event)
    if NetCallCheck(event.status) == true then
        --Queue up all our required calls here, fire off the timer to check to move on.
        statusText.text = "Queueing up data calls...."
        ArtVersion()
        VersionCheck() -- not queued
        GetMOTD()
        LoadMyCreatureInfo()
        LoadPassportData()
        LoadTutorials()
        GetServerBoundsStartup()
        GetCreatureDataVersion()
        GetSuggestedProxyPoint()
        GetTiles()
        loadingTimer = timer.performWithDelay(updateLoopDelay, CallsLeftTimer, -1)
    elseif (event.response ~= "") then
        statusText.text = event.response
    else
        statusText.text = "No response from server. Trying again..."
        ServerAlive()
        --TODO: come back here after Offline Mode is implemented and force-start in Offline mode if the server doesn't answer in 3? tries.
    end
    NetUp()
end

function GetServerBoundsStartup()
    statusText.text = "Getting server boundaries...."
    local url = serverURL .. "Server/ServerBounds" 
    QueueCall(url, "GET", GetServerBoundsListenerStartup, normalParams)
end

function GetServerBoundsListenerStartup(event)
    if NetCallCheck(event.status) == true then
        local boundValues = Split(event.response, "|") --in clockwise order, S/W/N/E
        serverBounds["south"] = tonumber(boundValues[1])
        serverBounds["west"] = tonumber(boundValues[2])
        serverBounds["north"] = tonumber(boundValues[3])
        serverBounds["east"] = tonumber(boundValues[4])       
    else
        statusText.text = "Failed to get server bounds, retrying....."
        GetServerBoundsStartup()
    end
    NetUp()
end

function GetCreatureDataVersion()
    statusText.text = "Getting creature data...."
    url = serverURL .. "Creature/CreatureDataVersion"
    QueueCall(url, "GET", CreatureDataVersionHandler, normalParams)
end

function CreatureDataVersionHandler(event)
    if NetCallCheck(event.status) == true then
        local version = tonumber(event.response)
        if (version == dataVersions.creatureDataVersion and DoesFileExist('creatureInfo.json', system.DocumentsDirectory) ) then
            creatureInfo = LoadFromFile("creatureInfo.json")
            GetAllCreatureImages()
        else
            GetCreatureData()
            dataVersions.creatureDataVersion = version
            SaveToFile('dataVersions.json', dataVersions)
        end
    else
        GetCreatureDataVersion()
    end
    NetUp()
end

function GetCreatureData()
    statusText.text = "Getting creature data...."
    url = serverURL .. "Creature/CreatureData"
    QueueCall(url, "GET", CreatureDataHandler, normalParams)
end

function CreatureDataHandler(event)
    if NetCallCheck(event.status) == true then
        creatureInfo = json.decode(event.response)
        SaveToFile("creatureInfo.json", creatureInfo)
        GetAllCreatureImages()
    else
        GetCreatureData()
    end
    NetUp()
end

function GetTiles()
    statusText.text = "Loading map tiles..."
    for x = -2, 2 do
        for y = -2, 2 do
            local thisPlusCode = ShiftCell(currentPlusCode, x, 8)
            thisPlusCode = ShiftCell(thisPlusCode, y, 7)
            thisPlusCode = thisPlusCode:sub(1,8)
            if DoesFileExist(thisPlusCode .. ".png", system.CachesDirectory) == false then
                local params = GetImageDownloadParams(thisPlusCode .. '.png', system.CachesDirectory)
                local url = serverURL .. "MapTile/Area/" .. thisPlusCode .. '/' .. mapTileStyle
                QueueCall(url, "GET", GetTilesListener, params)
                tilesRequested = tilesRequested + 1
            end
        end
    end
end

function GetTilesListener(event)
    tilesRequested = tilesRequested - 1
    if (event.phase ~= 'ended') then
        return
    end
    NetUp()
end

function LoadTutorials()
    local url = serverURL .. "Tibo/Tutorial/"
    QueueCall(url, "GET", TutorialListener, normalParams)
end

function TutorialListener(event)
    if NetCallCheck(event.status) == true and event.response ~= "" then
        tutorialsViewed = json.decode(event.response)
        tutorialsDone = true
    else
        LoadTutorials()
    end
    NetUp()
end

function LoadPassportData()
    local url = serverURL .. "Passport/"
    QueueCall(url, "GET", PassportListener, normalParams)
end

function PassportListener(event)
    if (NetCallCheck(event.status) == true and event.response ~= "") then
        passportData = json.decode(event.response)
        passportDone = true
    else
        LoadPassportData()
    end
    NetUp()
end

function GotoMain()
    Runtime:removeEventListener("location", loadingGpsListener)
    composer.gotoScene("scenes.CollectScene")
end

function SuggestedProxyPointListener(event)
    if NetCallCheck(event.status) == false then
        return --TODO retry
    end

    suggestedProxyPoint = event.response
    NetUp()
end

function GetSuggestedProxyPoint()
    local url = serverURL .. "Tibo/SuggestProxy" 
    QueueCall(url, "GET", SuggestedProxyPointListener, normalParams)
end

function GetMOTD()
    local url = serverURL .. "Server/MOTD" 
    QueueCall(url, "GET", MOTDListener, normalParams)
end

function MOTDListener(event)
    if NetCallCheck(event.status) == false then
        --call failed
        return
    end

    if (event.response ~= '') then
        native.showAlert('Message of the Day', event.response)
    end
end

function scene:create( event )
    local sceneGroup = self.view
    local loadingBg = display.newImageRect(sceneGroup, "themables/LoadingScreen.png", 1080, 1920)
    loadingBg.anchorX = 0
    loadingBg.anchorY = 0

    mapTileStyle = configInfo.mapTileStyle

    statusText = display.newText({parent =sceneGroup, text = "Waiting for Data....", x = display.contentCenterX, y = 260, font = native.systemFont, fontSize = 30, width = 900})
    statusText:setFillColor(.2, .2, .2)

    if system.getInfo("environment") ~= "simulator" then
        Runtime:addEventListener("location", loadingGpsListener)
    else
        startingPoint.lat = 40
        startingPoint.lon = -80
        startingPoint.altitude = 300
        startingPoint.accuracy = 2
    end
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
 
    elseif ( phase == "did" ) then
        passportDone = false
        tutorialsDone = false
        if system.getInfo("environment") ~= "simulator" then
            startingPoint = {}
        end
        timer.performWithDelay(25, WaitForLocation, 1)
    end
end
 
function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then

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