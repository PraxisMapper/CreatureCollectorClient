local composer = require( "composer" )
local scene = composer.newScene()
 --Active challenge C
 --Stand perfectly still

local jumpC1 = ''
local jumpC2 = ''
local jumpC3 = ''
local jumpCCancel = ''
--local dumpInfoC = '' --dumping debug info onscreen in dev
--local dumpInfoC2 = ''

local creature = ''
local baseCreature = {}
local seconds = 0
local ticks = 0

local countdownTimerC = {}
local creatureEarned = {}
local currentDifficulty = {}
local difficulties = {}
difficulties[1] = {seconds = 8, ticks = 10}
difficulties[2] = {seconds = 5, ticks = 20}

local function AccelCCallback(event)
    --sum up the values. This takes a few seconds to wind down to 0.
    local totalAccel = math.abs(event.xInstant) + math.abs(event.yInstant) + math.abs(event.zInstant) -- this has a curve and averaging applied to it vs the previous check
    local altTotalAccel = math.abs(event.xRaw) + math.abs(event.yRaw) + math.abs(event.zRaw) - 1 --this does not.
    --We check both: totalAccel takes a few seconds to realize we're sitting still, and altTotalAccel never hits under 0.1 if a human is holding the phone.
    --jumpC3.text = "Total motion: " .. totalAccel .. ' \n' .. altTotalAccel

    if altTotalAccel < 0.05 or totalAccel < 0.05 then
        ticks = ticks - 1
        if (ticks == 0) then
            jumpC2.text = "Done!"        
            Runtime:removeEventListener("accelerometer", AccelCCallback)
            ActiveChallengeSuccess(baseCreature)
            creatureEarned.isVisible = true

            timer.performWithDelay(2000, HideOverlayCrossfade, 1)
            timer.cancel(countdownTimerC)
        end
    end    
 end

local function TimerCallbackC() 
    seconds = seconds - 1
    jumpC2.text = "Time Left: " .. seconds
    if seconds <= 0 then
        jumpC2.text = "Missed!"
        timer.performWithDelay(2000, HideOverlayCrossfade, 1)
        timer.cancel(countdownTimerC)
    end
 end

function scene:create( event ) 
    local sceneGroup = self.view
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 980, 1400)    
    bg.fill = bgFill

    jumpC1 = display.newText({ parent = sceneGroup, text = "Hold Perfectly Still!", x = display.contentCenterX, y = 400})
    jumpC1.anchorX = 0.5

    jumpC2 = display.newText({ parent = sceneGroup, text = "Time left:", x = display.contentCenterX, y = 470})

    jumpC3 = display.newText({ parent = sceneGroup, text = "", x = 100, y = 600})
    jumpC3.anchorX = 0

    jumpCCancel = display.newText({ parent = sceneGroup, text = "Cancel", x = display.contentCenterX, y = 1600})
    jumpCCancel:addEventListener("tap", HideOverlayCrossfade)

    --dumpInfoX = display.newText({ parent = sceneGroup, text = "", x = 500, y = 1000, width = 900})
    --dumpInfoX2 = display.newText({ parent = sceneGroup, text = "", x = 500, y = 1400, width = 900})
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        creature = composer.getVariable("creatureCaught")
        currentDifficulty = difficulties[creature.difficulty]
        seconds = currentDifficulty.seconds
        ticks = currentDifficulty.ticks
        jumpC2.text = "Time Left: " .. seconds
    elseif ( phase == "did" ) then
        countdownTimerC = timer.performWithDelay(1000, TimerCallbackC, currentDifficulty.seconds)
        Runtime:addEventListener( "accelerometer", AccelCCallback)

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
        Runtime:removeEventListener("accelerometer", AccelCCallback)
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