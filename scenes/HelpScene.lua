local composer = require( "composer" )
local scene = composer.newScene()

function scene:create( event )
    local sceneGroup = self.view

    helpText = display.newText({ parent = sceneGroup, text = "", x = 25, y = 25, width = 1030, height = 1780})
    helpText.anchorX = 0
    helpText.anchorY = 0
    helpText.text = "* 'Walk' means 'walk around in real life' \n\n*COLLECT MODE: walk near the crystal icons to collect creature fragments. Tap 'ACTIVE' to have the next creature  " 
    .. "prompt a mini-game. Succeed at the active game and collect a rarer, stronger creature. Different areas on the map will spawn different creatures to collect."
    .. "\n\n*CONTROL MODE: walk around to view areas on the map. Tap interesting areas to place a creature and claim it for your team."
    .. "\n\n*Interesting areas generally means 'public places people are likely to visit'. Parks, nature reserves, tourist sites, retail shopping areas, and "
    .. "named buildings are among the list of things you can claim in this mode."
    .. "\n\n*COVER MODE: Spend fragments to place a creature anywhere on the map and cover it in a circle. More fragments make bigger circles. See how much of the state you can cover."
    .. " Or draw pictures with different colors by using different creatures."
 
    closeButton = display.newText({ parent = sceneGroup, text = "Tap here to close this screen", x = display.contentCenterX, y = 1800})
    closeButton:addEventListener("tap", CloseThis)
end

function scene:show( event ) 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
 
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