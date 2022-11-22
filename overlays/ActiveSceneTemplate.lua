local composer = require( "composer" )
local scene = composer.newScene()
 
 --Active challenge X
 --description of task
 --ISSUES:

 --UI
local jumpX1 = ''
local jumpX2 = ''
local jumpX3 = ''
local jumpXCancel = ''
--local dumpInfoX = '' --dumping debug info onscreen in dev
--local dumpInfoX2 = ''

--vars
local creature = ''
local baseCreature = {}
local seconds = 0

--common and config stuff
local countdownTimerX = {}
local creatureEarned = {}
local currentDifficulty = {}
local difficulties = {}
difficulties[1] = {seconds = 5}
difficulties[2] = {seconds = 3}

local function TimerCallbackX() 
    seconds = seconds - 1
    jumpX2.text = "Time Left: " .. seconds
    if seconds <= 0 then
        jumpX2.text = "Missed!"
        timer.performWithDelay(2000, HideOverlayCrossfade, 1)
        timer.cancel(countdownTimerX)
    end
 end

function scene:create( event )
    local sceneGroup = self.view
    -- Code here runs when the scene is first created but has not yet appeared on screen
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 980, 1400)    
    bg.fill = bgFill

    jumpX1 = display.newText({ parent = sceneGroup, text = "Description Here!", x = display.contentCenterX, y = 400})
    jumpX1.anchorX = 0.5

    jumpX2 = display.newText({ parent = sceneGroup, text = "Time left:", x = display.contentCenterX, y = 470})

    jumpX3 = display.newText({ parent = sceneGroup, text = "", x = 100, y = 600})
    jumpX3.anchorX = 0

    jumpXCancel = display.newText({ parent = sceneGroup, text = "Cancel", x = display.contentCenterX, y = 1600})
    jumpXCancel:addEventListener("tap", HideOverlayCrossfade)

    --dumpInfoX = display.newText({ parent = sceneGroup, text = "", x = 500, y = 1000, width = 900})
    --dumpInfoX2 = display.newText({ parent = sceneGroup, text = "", x = 500, y = 1400, width = 900})
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
        creature = composer.getVariable("creatureCaught")
        currentDifficulty = difficulties[creature.difficulty]
        seconds = currentDifficulty.seconds
        jumpX2.text = "Time Left: " .. seconds
    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen
        countdownTimerX = timer.performWithDelay(1000, TimerCallbackX, currentDifficulty.seconds)

        baseCreature = FindCreatureById(creature.id)
        creatureEarned = MakeCreatureDisplay(baseCreature.eliteId)
        creatureEarned.pic.height = 512
        creatureEarned.pic.width = 512
        creatureEarned.text.y = creatureEarned.text.y + 256
        creatureEarned.x = display.contentCenterX
        creatureEarned.y = 1000
        creatureEarned.isVisible = false
        sceneGroup:insert(creatureEarned)
    end
end
 
function scene:hide( event ) 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        creatureEarned = {}
        --Remove any callbacks attached to Runtime
    end
end

function scene:destroy( event )
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
end
 
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
 
return scene