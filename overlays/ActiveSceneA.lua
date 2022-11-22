local composer = require( "composer" )
local scene = composer.newScene()
require("plusCodes")

 --Active challenge A
 --Load image from composer variable on catch
 -- this one is 'jog X cells'
--cell10s are ~14m, so giving 30 seconds to be in 3 unique ones should be OK and work around accuracy values on rougher days.
local creature = ''
local baseCreature = {}
local secondsLeft = 0
local jumpA1 = ''
local jumpA2 = ''
local jumpA3 = ''
local jumpA4 = ''
local dumpInfoA = ''
local dumpInfoA2 = ''
local cells = {}
local cellCount = 0
local bg = ''
local countdownTimerA = {}
local creatureEarned = {}
local currentDifficulty = {}
local difficulties = { }
difficulties[1] = {cells = 2, seconds = 20} 
difficulties[2] = {cells = 5, seconds = 45}

function TimerCallbackA()
    secondsLeft = secondsLeft - 1
    jumpA3.text = "Time Left: " .. secondsLeft
    if secondsLeft <= 0 then
        jumpA3.text = "Missed!"
        timer.performWithDelay(2000, HideOverlayCrossfade, 1)
        timer.cancel(countdownTimerA)
        Runtime:removeEventListener("location", ActiveSceneACallback)
    end
 end

 function ActiveSceneACallback(event)
    --This looks dumb, BUT it's because FakeScroll fires off this call with timer data rather than location data, so this stops it from crashing on the simulator.
    if (event.latitude == nil) then
        return
    end

    local thisPlusCode = EncodeLatLon(event.latitude, event.longitude, 10)
    if cells[thisPlusCode] == nil then
        cells[thisPlusCode] = 1
        cellCount = cellCount + 1
    end
    
    jumpA2.text = "Current Count: " .. (cellCount - 1)
    jumpA3.text = "Time Left: " .. secondsLeft
    if (cellCount >= currentDifficulty.cells + 1) then
        jumpA3.text = "Complete!"
        Runtime:removeEventListener("location", ActiveSceneACallback)
        timer.cancel(countdownTimerA)
        ActiveChallengeSuccess(baseCreature)
        timer.performWithDelay(2000, HideOverlayCrossfade, 1)
        creatureEarned.isVisible = true
    end   
 end

function scene:create( event ) 
    local sceneGroup = self.view

    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 980, 1400)    
    bg.fill = bgFill

    jumpA1 = display.newText({ parent = sceneGroup, text = "Jog through X cells!", x = display.contentCenterX, y = 400})
    jumpA1.anchorX = 0.5

    jumpA2 = display.newText({ parent = sceneGroup, text = "Current Count: 0", x = display.contentCenterX, y = 600})
    jumpA3 = display.newText({ parent = sceneGroup, text = "Time Left:", x = display.contentCenterX, y = 470})

    jumpA4 = display.newText({ parent = sceneGroup, text = "Cancel", x = display.contentCenterX, y = 1600})
    jumpA4:addEventListener("tap", HideOverlayCrossfade)

    dumpInfoA = display.newText({ parent = sceneGroup, text = "", x = 500, y = 1000, width = 900}) --gps
    dumpInfoA2 = display.newText({ parent = sceneGroup, text = "", x = 500, y = 1400, width = 900}) --accel   
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        creature = composer.getVariable("creatureCaught")
        currentDifficulty = difficulties[creature.difficulty]
        print(dump(currentDifficulty))
        cells = {}
        cellCount = 0
    elseif ( phase == "did" ) then
        jumpA1.text = "Jog through " .. currentDifficulty.cells .. " cells!"
        secondsLeft = currentDifficulty.seconds
        Runtime:addEventListener( "location", ActiveSceneACallback)
        countdownTimerA = timer.performWithDelay(1000, TimerCallbackA, currentDifficulty.seconds, "cdA")

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