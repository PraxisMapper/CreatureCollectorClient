local composer = require( "composer" )
local scene = composer.newScene()

 --Active challenge B
 --Load image from composer variable on catch
 -- this one is 'shake device Y times in under X seconds'

local creature = ''
local baseCreature = {}
local seconds = 0
local shakes = 0
local jumpB1 = ''
local jumpB2 = ''
local jumpB3 = ''
local jumpBCancel = ''
local dumpInfoB = ''
local dumpInfoB2 = ''
local countdownTimerB = {}
local creatureEarned = {}
local currentDifficulty = {}
local difficulties = {}
difficulties[1] = {seconds = 5, shakes = 1}
difficulties[2] = {seconds = 5, shakes = 3}

 function AccelBCallback(event)
    if event.isShake then
        shakes = shakes - 1
        if (shakes == 0) then
            jumpB2.text = "Done!"        
            Runtime:removeEventListener("accelerometer", AccelBCallback)
            ActiveChallengeSuccess(baseCreature)
            creatureEarned.isVisible = true

            timer.performWithDelay(2000, HideOverlayCrossfade, 1)
            timer.cancel(countdownTimerB)
        else
            jumpB1.text = "Shake it more!"
        end
    end    
 end

 function TimerCallbackB() 
    seconds = seconds - 1
    jumpB2.text = "Time Left: " .. seconds
    if seconds <= 0 then
        jumpB2.text = "Missed!"
        timer.performWithDelay(2000, HideOverlayCrossfade, 1)
        Runtime:removeEventListener("accelerometer", AccelBCallback)
        timer.cancel(countdownTimerB)
    end
 end

function scene:create( event )
    local sceneGroup = self.view
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 980, 1400)    
    bg.fill = bgFill

    jumpB1 = display.newText({ parent = sceneGroup, text = "Shake your phone!", x = display.contentCenterX, y = 400})
    jumpB1.anchorX = 0.5

    jumpB2 = display.newText({ parent = sceneGroup, text = "Time left:", x = display.contentCenterX, y = 470})

    jumpB3 = display.newText({ parent = sceneGroup, text = "", x = 100, y = 600})
    jumpB3.anchorX = 0

    jumpBCancel = display.newText({ parent = sceneGroup, text = "Cancel", x = display.contentCenterX, y = 1600})
    jumpBCancel:addEventListener("tap", HideOverlayCrossfade)

    dumpInfoB = display.newText({ parent = sceneGroup, text = "", x = 500, y = 1000, width = 900}) --gps
    dumpInfoB2 = display.newText({ parent = sceneGroup, text = "", x = 500, y = 1400, width = 900}) --accel
end
 
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
         creature = composer.getVariable("creatureCaught")
        currentDifficulty = difficulties[creature.difficulty]
        seconds = currentDifficulty.seconds
        shakes = currentDifficulty.shakes
        jumpB2.text = "Time Left: " .. seconds
    elseif ( phase == "did" ) then
         Runtime:addEventListener( "accelerometer", AccelBCallback)
        countdownTimerB = timer.performWithDelay(1000, TimerCallbackB, currentDifficulty.seconds)

        baseCreature = FindCreatureById(creature.creatureIdCaught)
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

    elseif ( phase == "did" ) then
        creatureEarned = {}
        Runtime:removeEventListener("accelerometer", AccelBCallback)
    end
end
 
function scene:destroy( event )
    local sceneGroup = self.view
end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene