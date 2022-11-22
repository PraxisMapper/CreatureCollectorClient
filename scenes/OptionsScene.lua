local composer = require( "composer" )
local scene = composer.newScene()
local widget = require("widget")
widget.setTheme("widget_theme_android_holo_dark")
local lfs = require("lfs")
require('common')

local queueUpdateTimer = nil
local queueSize = {}
local label2b = ''
local prevScene = ""
local proxyPlayDrawTimer = {}
local deleteDialog ={}
local graduateDialog ={}
local graduateLink = {}
local enterArea = {}
local enterTerrain = {} 
local gradCreatureId = -1
local pickScreen = {}
local creatureIcon = {}
local creatureName = {}

local proxyPlayText = {}
local changeTeamText = {}
local mapTileStyleLabel = {}

local function dumpQueue(event)
    for i = 1, #networkQueue do
        print(dump(networkQueue[i]))
    end
end

local function ShowProxyOverlay()
    composer.showOverlay("overlays.ProxyPlayOverlay", {isModal = true})
end

local function LogOut(event)
    credentials.username = ''
    credentials.password = ''

    local temp_path = system.pathForFile("", system.TemporaryDirectory)
    for file in lfs.dir(temp_path) do
        os.remove(system.pathForFile(file, system.TemporaryDirectory))
    end

    ClearAuthHeaders()
    playerData = {}
    JumpToAccount()
end

function scene:UpdateProxyText()
    proxyPlayText.text = "Change ProxyPlay Location (" .. playerData.currencies.proxyPlayTokens .. " left)"
    if playerData.proxyPlayPoint == nil or playerData.proxyPlayPoint.lat == nil then
        label2b.text = "ProxyPlay Location: None"
    else
        label2b.text = "ProxyPlay Location: " ..playerData.proxyPlayPoint.lat .. ", " .. playerData.proxyPlayPoint.lon
    end
end

function ShowDeleteDialog()
    deleteDialog.x = 0
end

function HideDeleteDialog()
    deleteDialog.x = -3000
end

function DeleteAccount()
    local url = serverURL .. 'Tibo/Account/'
    network.request(url, "DELETE", DeleteCallListenerA, normalParams)
end

function DeleteCallListenerA(event)
    if NetCallCheck(event.status) == false then
        --handle network issue
        native.showAlert('', print(dump(event)))
        return
    end

    local url = serverURL .. 'Server/Account/'
    network.request(url, "DELETE", DeleteCallListenerB, normalParams)
end

function DeleteCallListenerB(event)
    if NetCallCheck(event.status) == false then
        --handle network issue
        native.showAlert('', print(dump(event)))
        return
    end

    native.requestExit()
end

local function ShowGraudateDialog()
    graduateDialog.x = 0
end

local function PickArea()
    enterArea.isVisible = true
    enterTerrain.isVisible = false
end

local function PickTerrain()
    enterArea.isVisible = false
    enterTerrain.isVisible = true
end

local function Graduate()
    local value = ''
    if (enterArea.isVisible == true) then
        value = enterArea.text
    elseif enterTerrain.isVisible == true then
        value = enterTerrain:getValues()[1].value
    end

    if (value == '' or gradCreatureId == -1) then
        --didn't pick a thing, don't upload.
        return
    end

    local url = serverURL .. 'Creature/Graduate/' .. gradCreatureId .. '/' .. value
    network.request(url, 'PUT', GraduateListener, normalParams)
end

function GraduateListener(event)
    if NetCallCheck(event.status) == false then
        -- graduation request failed, TODO try again or tell user it failed.
    end

    --we succeeded here, thank the user.
    enterArea.isVisible = false
    enterTerrain.isVisible = false
    graduateDialog.x = -3000
    postGraduateDialog.x = 0
end

local function ClosePickWindowO()
    pickScreen:removeSelf()
end

local function SetPicked(self, event) 
    gradCreatureId = self.creatureId
    local creature = FindCreatureById(gradCreatureId)
    creatureIcon.fill = {
        type = "image",
        filename = creature.imageName,
        baseDir =  system.DocumentsDirectory
    }
    creatureName.text = creature.name
    ClosePickWindowO()
end

local function FillPickWindowO(tapHandler)
    pickScreen = FillPickWindow(tapHandler, FilterCreaturesWildSpawn, ClosePickWindowO)
end

local function ReportQueueSize()
    queueSize.text = "Queued Calls:" .. #networkQueue
end

local function ChangeMapTileStyle(event)
    local tile_path = system.pathForFile("", system.CachesDirectory)
    for file in lfs.dir(tile_path) do
        os.remove(system.pathForFile(file, system.CachesDirectory))
    end

    if (mapTileStyle == 'mapTiles') then
        mapTileStyle = 'biomes'
        mapTileStyleLabel.text = "Map Tile Style: Biomes" 
    else
        mapTileStyle = 'mapTiles'
        mapTileStyleLabel.text = "Map Tile Style: OpenCarto" 
    end
    
    configInfo.mapTileStyle = mapTileStyle
    SaveToFile('configInfo.json', configInfo)
end

function scene:create( event ) 
    local sceneGroup = self.view

    queueSize = display.newText({ parent = sceneGroup, text = "Queued Calls:", x = 100, y = 200})
    queueSize.anchorX = 0
    queueSize:addEventListener("tap", dumpQueue)

    mapTileStyleLabel = display.newText({ parent = sceneGroup, text = "Map Tile Style: ", x = 100, y = 250})
    mapTileStyleLabel.anchorX = 0
    if (mapTileStyle == 'mapTiles') then
        mapTileStyleLabel.text = mapTileStyleLabel.text .. 'OpenCarto'
    else
        mapTileStyleLabel.text = mapTileStyleLabel.text .. 'Biomes'
    end
    mapTileStyleLabel:addEventListener("tap", ChangeMapTileStyle)

    local label1 = display.newText({ parent = sceneGroup, text = "Sound:", x = 100, y = 300})
    label1.anchorX = 0
    label1.isVisible = false
    
    proxyPlayText = display.newText({ parent = sceneGroup, text = "Change ProxyPlay Location (" .. playerData.currencies.proxyPlayTokens .. " left)", x = 100, y = 400})
    proxyPlayText.anchorX = 0
    proxyPlayText:addEventListener("tap", ShowProxyOverlay)

    label2b = display.newText({ parent = sceneGroup, text = "Current ProxyPlay Location:", x = 100, y = 450, fontSize = 40})
    label2b.anchorX = 0
    
    local label3 = display.newText({ parent = sceneGroup, text = "Active Net Calls:", x = 100, y = 600})
    label3.anchorX = 0
    label3.isVisible = false
    local label4 = display.newText({ parent = sceneGroup, text = "(Higher = faster, Lower = more stable)", x = 100, y = 650})
    label4.anchorX = 0
    label4.isVisible = false
    
    changeTeamText = display.newText({ parent = sceneGroup, text = "Change Team (" .. playerData.currencies.teamSwapTokens ..  " tokens left)", x = 100, y = 600})
    changeTeamText.anchorX = 0
    changeTeamText:addEventListener("tap", JumpToTeam)
    label6a = display.newText({ parent = sceneGroup, text = "Current Team: " , x = 100, y = 650, fontSize = 40})
    label6a.anchorX = 0
    local teamName = "none"
    if playerData.team == 1 then
        teamName = "Red"
    elseif playerData.team == 2 then
        teamName = "Green"
    elseif playerData.team == 3 then
        teamName = "Purple"
    elseif playerData.team == 4 then
        teamName = "Grey"
    end
    label6a.text = label6a.text .. teamName

    label7 = display.newText({ parent = sceneGroup, text = "Delete Account and All Server-Side Data", x = 100, y = 1200})
    label7.anchorX = 0
    label7:addEventListener("tap", ShowDeleteDialog)

    local label9 = display.newText({ parent = sceneGroup, text = "Log Out", x = 100, y = 1600})
    label9.anchorX = 0
    label9:addEventListener("tap", LogOut)
 
    local label5 = display.newText({ parent = sceneGroup, text = "Close Options Menu", x = 100, y = 1800})
    label5.anchorX = 0
    label5:addEventListener("tap", CloseThis)

    local label8 = display.newText({ parent = sceneGroup, text = "Map Data © OpenStreetMap", x = 100, y = 100})
    label8.anchorX = 0
    label8:setFillColor(.2, .2, 1)
    label8:addEventListener("tap", OpenOSMLicenseInBrowser)

    deleteDialog = display.newGroup()
    deleteDialog.anchorX = 0
    deleteDialog.anchorY = 0
    sceneGroup:insert(deleteDialog)
    local bg = display.newRect(deleteDialog, display.contentCenterX, display.contentCenterY, 1080, 1920)
    bg.fill = bgFill
    bg:addEventListener("tap", blockTouch)
    local warningText = display.newText({ parent = deleteDialog, text = "NOTICE: by tapping 'Delete My Account', the server will permanently remove ALL data you created or edited from the server. This includes your account name and password, any creatures placed in Control mode, and other data. \n\nAfter the server data is successfully deleted, the app will close itself. You may clear data locally or uninstall the app to remove any remaining traces of activity on your device.", x = 100, y = 100, width = 800})
    warningText.anchorX = 0
    warningText.anchorY = 0

    local deleteLink = display.newText({ parent = deleteDialog, text = "I said 'Delete My Account' and I meant it ", x = 50, y = 1200})
    deleteLink.anchorX = 0
    deleteLink.anchorY = 0
    deleteLink:addEventListener("tap", DeleteAccount)

    local cancelDeleteLink = display.newText({ parent = deleteDialog, text = "Cancel", x = 100, y = 1400})
    cancelDeleteLink.anchorX = 0
    cancelDeleteLink.anchorY = 0
    cancelDeleteLink:addEventListener("tap", HideDeleteDialog)
    deleteDialog.x = -3000

    graduateLink = display.newText({ parent = sceneGroup, text = "Graduate!", x = 100, y = 1250})
    graduateLink.anchorX = 0
    graduateLink.anchorY = 0
    graduateLink:addEventListener("tap", ShowGraudateDialog)
    graduateLink.fill = {.9, .2, .2}

    graduateDialog = display.newGroup()
    graduateDialog.anchorX = 0
    graduateDialog.anchorY = 0
    sceneGroup:insert(graduateDialog)
    local bg2 = display.newRect(graduateDialog, display.contentCenterX, display.contentCenterY, 1080, 1920)
    bg2.fill = bgFill
    bg2:addEventListener("tap", blockTouch)

    local gradText1 = display.newText({ parent = graduateDialog, text = "Pick a creature you want to boost spawn rates for:", x = 100, y = 100, width = 800})
    gradText1.anchorX = 0
    gradText1.anchorY = 0

    creatureIcon = display.newImageRect(graduateDialog, "themables/PickCreature.png", 512, 512)
    creatureIcon.x = display.contentCenterX
    creatureIcon.y =  500
    creatureIcon:addEventListener("tap", FillPickWindowO)
    creatureName = display.newText({ parent = graduateDialog, text = "name here", x = display.contentCenterX, y = 800})
    creatureName.anchorY = 0

    --TODO: only boost an Area. Leave Terrains alone.
    local gradText2 = display.newText({ parent = graduateDialog, text = "Do you want to boost an Area or a Terrain?", x = 100, y = 1000, width = 800})
    gradText2.anchorX = 0
    gradText2.anchorY = 0

    local areaButtonLabel = display.newText({ parent = graduateDialog, text = "Area", x = 200, y = 1200})
    areaButtonLabel:addEventListener("tap", PickArea)

    local terrainButtonLabel = display.newText({ parent = graduateDialog, text = "Terrain", x = 800, y = 1200})
    terrainButtonLabel:addEventListener("tap", PickTerrain)

    local gradText3 = display.newText({ parent = graduateDialog, text = "Pick the entry you want to boost", x = 100, y = 1300, width = 800})
    gradText3.anchorX = 0
    gradText3.anchorY = 0

    enterArea = native.newTextField(display.contentCenterX, 1580, 800, 100)
    enterArea.text = currentPlusCode:sub(1,8)
    enterArea.isVisible = false

    local columnData = { labels = {"water", "wetland", "park", "beach", "university", "nature_reserve", "cemetery", "retail", "tourism", "historical", "trail"}, startIndex = 1}
    enterTerrain = widget.newPickerWheel({x = display.contentCenterX, y = 1500, width=800, fontColor = {0, 0, 0}, style = "resizable", columns = columnData, rowHeight = 70 })
    enterTerrain.isVisible = false

    local commitButton = display.newImageRect(graduateDialog, "themables/GraduateButton.png", 300, 100)
    commitButton.x = display.contentCenterX
    commitButton.y =  1800
    commitButton:addEventListener("tap", Graduate)

    graduateDialog.x = -3000

    postGraduateDialog = display.newGroup()
    postGraduateDialog.anchorX = 0
    postGraduateDialog.anchorY = 0
    sceneGroup:insert(postGraduateDialog)
    local bg3 = display.newRect(postGraduateDialog, display.contentCenterX, display.contentCenterY, 1080, 1920)
    bg3.fill = bgFill
    bg3:addEventListener("tap", blockTouch)

    local postGradText1 = display.newText({ parent = postGraduateDialog, text = "Done! You've left a permanent impact on the game. Thanks for playing!", x = 100, y = 100, width = 800})
    postGradText1.anchorX = 0
    postGradText1.anchorY = 0

    postGraduateDialog.x = -3000

    self.UpdateProxyText()
end

function scene:show( event ) 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
 
    elseif ( phase == "did" ) then
        prevScene = composer.getSceneName("previous")
        queueUpdateTimer = timer.performWithDelay(1000, ReportQueueSize, -1)

        proxyPlayText.text = "Change ProxyPlay Location (" .. playerData.currencies.proxyPlayTokens .. " left)"
        changeTeamText.text = "Change Team (" .. playerData.currencies.teamSwapTokens ..  " tokens left)"

        graduateLink.isVisible = playerData.graduationEligible
    end
end

function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        queueUpdateTimer = timer.cancel(queueUpdateTimer) 
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