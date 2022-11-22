local composer = require( "composer" )
local scene = composer.newScene()

local image = {}
   
function spinIcon(event)
    image.rotation = image.rotation + 1
    if image.rotation == 360 then
        image.rotation = 0
    end
end

function scene:create( event )
    local sceneGroup = self.view

    local bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 500, 500)
    bg.fill = bgFill

    image = display.newImageRect(sceneGroup, "themables/LoadingOverlay.png", 170, 170)
    image.x = display.contentCenterX
    image.y = display.contentCenterY + 50

    local loadingLabel = display.newText({parent = sceneGroup, text = "Loading...", x = display.contentCenterX, y = display.contentCenterY - 150})
end
 
 function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
 
    elseif ( phase == "did" ) then
        Runtime:addEventListener("enterFrame", spinIcon)
    end
end

function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
 
    elseif ( phase == "did" ) then
        Runtime:removeEventListener("enterFrame", spinIcon)
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