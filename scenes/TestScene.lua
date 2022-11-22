local composer = require( "composer" )
local scene = composer.newScene()
 
function JumpToStore()
    composer.gotoScene("scenes.StoreScene")
end 

function JumpToActiveA()
    composer.setVariable("creatureCaught", {creatureIdCaught = 1, uid = "asdf", name = "Reel", activeGame = "A", difficulty = 1})
    composer.showOverlay("overlays.ActiveSceneA", {isModal = true})
end 

function JumpToActiveB()
    composer.setVariable("creatureCaught", {creatureIdCaught = 1, uid = "asdf", name = "Reel", activeGame = "B", difficulty = 1})
    composer.showOverlay("overlays.ActiveSceneB", {isModal = true})
end 

function JumpToActiveC()
    composer.setVariable("creatureCaught", {creatureIdCaught = 1, uid = "asdf", name = "Reel", activeGame = "C", difficulty = 1})
    composer.showOverlay("overlays.ActiveSceneC", {isModal = true})
end 

function JumpToActiveD()
    composer.setVariable("creatureCaught", {creatureIdCaught = 1, uid = "asdf", name = "Reel", activeGame = "D", difficulty = 1})
    composer.showOverlay("overlays.ActiveSceneD", {isModal = true})
end

function JumpToActiveE()
    composer.setVariable("creatureCaught", {creatureIdCaught = 1, uid = "asdf", name = "Reel", activeGame = "E", difficulty = 1})
    composer.showOverlay("overlays.ActiveSceneE", {isModal = true})
end

function JumpToActiveTemplate()
    composer.setVariable("creatureCaught", {id = 1, uid = "asdf", name = "Reel", activeGame = "B", difficulty = 1})
    composer.showOverlay("overlays.ActiveSceneTemplate", {isModal = true})
end 

function TestTutorial()
    ForceTutorial("story1")
end

function TestPossible()
    local url = serverURL .. 'Creature/Possible/86HWCMMP'
    network.request(url, 'GET', PossibleListener, normalParams)
end

function PossibleListener(event)
    print(dump(event))
end

function TestListener(event)
    print(dump(event))
end

function TestVortex()
    local url = serverURL .. 'Creature/Vortex/' .. currentPlusCode:sub(1,8)
    network.request(url, 'PUT', TestListener, normalParams)
end

function scene:create( event ) 
    local sceneGroup = self.view
    local jump1 = display.newText({ parent = sceneGroup, text = "Full Screen Main Scene", x = 100, y = 100})
    jump1.anchorX = 0
    jump1:addEventListener("tap", GoToCollect)

    local jump2 = display.newText({ parent = sceneGroup, text = "ProxyPlay overlay", x = 100, y =200})
    jump2.anchorX = 0
    jump2:addEventListener("tap", JumpToProxy)

    local jump3 = display.newText({ parent = sceneGroup, text = "Upgrade Scene", x = 100, y = 300})
    jump3.anchorX = 0
    jump3:addEventListener("tap", GoToUpgrades)

    --local jump4a = display.newText({ parent = sceneGroup, text = "Test readonly db issue", x = 100, y = 500})
    --jump4a.anchorX = 0
    --jump4a:addEventListener("tap", TestDbSaves)

    --local jump4 = display.newText({ parent = sceneGroup, text = "Store Scene", x = 100, y = 400})
    --jump4.anchorX = 0
    --jump4:addEventListener("tap", JumpToStore)

    --local jump5 = display.newText({ parent = sceneGroup, text = "Status Scene", x = 100, y = 500})
    --jump5.anchorX = 0
    --jump5:addEventListener("tap", JumpToStatus)

    local jump6 = display.newText({ parent = sceneGroup, text = "Territory Control Scene", x = 100, y = 600})
    jump6.anchorX = 0
    jump6:addEventListener("tap", GoToControl)

    local jump7 = display.newText({ parent = sceneGroup, text = "Options Scene", x = 100, y = 700})
    jump7.anchorX = 0
    jump7:addEventListener("tap", GoToOptions)

    local jump8 = display.newText({ parent = sceneGroup, text = "Account Login Scene", x = 100, y = 800})
    jump8.anchorX = 0
    jump8:addEventListener("tap", JumpToAccount)

    local jump9 = display.newText({ parent = sceneGroup, text = "Active Catch Scene D", x = 100, y = 900})
    jump9.anchorX = 0
    jump9:addEventListener("tap", JumpToActiveD)

    local jump10 = display.newText({ parent = sceneGroup, text = "Pick Team Scene", x = 100, y = 1000})
    jump10.anchorX = 0
    jump10:addEventListener("tap", JumpToTeam)

    local jump11 = display.newText({ parent = sceneGroup, text = "Passport Overlay", x = 100, y = 1100})
    jump11.anchorX = 0
    jump11:addEventListener("tap", ShowPassportOverlay)

    local jump12 = display.newText({ parent = sceneGroup, text = "Help Scene", x = 100, y = 1200})
    jump12.anchorX = 0
    jump12:addEventListener("tap", JumpToHelp)

    local jump13 = display.newText({ parent = sceneGroup, text = "Creature Info Scene", x = 100, y = 1300})
    jump13.anchorX = 0
    jump13:addEventListener("tap", JumpToCreatureInfo)

    local jump14 = display.newText({ parent = sceneGroup, text = "Leaderboards Overlay", x = 100, y = 1400})
    jump14.anchorX = 0
    jump14:addEventListener("tap", ShowLeaderboardOverlay)

    local jump15 = display.newText({ parent = sceneGroup, text = "Test Tutorial Popup", x = 100, y = 1500})
    jump15.anchorX = 0
    jump15:addEventListener("tap", TestTutorial)

    -- local jump16 = display.newText({ parent = sceneGroup, text = "Test catching 2 at once", x = 100, y = 1600})
    -- jump16.anchorX = 0
    -- jump16:addEventListener("tap", TestTutorial)

    -- local jump17 = display.newText({ parent = sceneGroup, text = "Cover PVE Scene", x = 100, y = 1600})
    -- jump17.anchorX = 0
    -- jump17:addEventListener("tap", JumpToCover)

     local jump18 = display.newText({ parent = sceneGroup, text = "Possible Spanws ", x = 100, y = 1600})
     jump18.anchorX = 0
     jump18:addEventListener("tap", TestPossible)

     local jump20 = display.newText({ parent = sceneGroup, text = "test vortex ", x = 100, y = 1800})
     jump20.anchorX = 0
     jump20:addEventListener("tap", TestVortex)
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