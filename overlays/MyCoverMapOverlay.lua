local composer = require( "composer" )
local scene = composer.newScene()
require('common')

local loadingDisplay = {}
local fullMapImage = {}

local function HideThis()
    composer.hideOverlay(true, "crossFade", menuSlideSpeed)
end

local function FullMapHandler(event)
    loadingDisplay.isVisible = false
    if NetCallCheck(event.status) == false then
        HideThis()
        return
    end
    
    --pop up a window/etc with box.
    fullMapImage.fill = {
        type = "image",
        filename = 'fullCoverMap.png',
        baseDir = system.TemporaryDirectory
    }
end

local function FullCoverMap()
    local params = GetImageDownloadParams('fullCoverMap.png', system.TemporaryDirectory)
    local url = serverURL .. 'Cover/PlacedFull/'
    network.request(url, 'GET', FullMapHandler, params)
    return true
end

function scene:create( event )
    local sceneGroup = self.view
    loadingDisplay = display.newImageRect(sceneGroup, "themables/LoadingOverlay.png", 260, 260)
    loadingDisplay.x = display.contentCenterX
    loadingDisplay.y = display.contentCenterY

    fullMapImage = display.newImageRect(sceneGroup, "themables/LoadingOverlay.png", 1080, 1920)
    fullMapImage.x = display.contentCenterX
    fullMapImage.y = display.contentCenterY
    fullMapImage:addEventListener("tap", HideThis)
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        loadingDisplay.isVisible = true
        fullMapImage.fill = paintClear
        FullCoverMap()
    elseif ( phase == "did" ) then

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