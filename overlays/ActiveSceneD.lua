local composer = require( "composer" )
local scene = composer.newScene()

 --Active challenge D
 --Total Altitude change from start. No active task in-game here.
 --ISSUES:

--UI
local jumpD1 = ''
local jumpD2 = ''
local jumpD3 = ''
local jumpDCancel = ''
local dumpInfoD = '' --dumping debug info onscreen in dev
--local dumpInfoX2 = ''

--vars
local creature = ''
local baseCreature = {}
local seconds = 0

--common and config stuff
local creatureEarned = {}
local currentDifficulty = {}
local difficulties = {}
difficulties[1] = {seconds = 3, meters = 10}
difficulties[2] = {seconds = 3, meters = 30}

function scene:create( event )
    local sceneGroup = self.view
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 980, 1400)    
    bg.fill = bgFill

    jumpD1 = display.newText({ parent = sceneGroup, text = "Walk X Meters Uphill!", x = display.contentCenterX, y = 400})
    jumpD1.anchorX = 0.5

    jumpD2 = display.newText({ parent = sceneGroup, text = "", x = display.contentCenterX, y = 470})

    jumpD3 = display.newText({ parent = sceneGroup, text = "", x = 100, y = 600})
    jumpD3.anchorX = 0

    jumpDCancel = display.newText({ parent = sceneGroup, text = "Cancel", x = display.contentCenterX, y = 1600})
    jumpDCancel:addEventListener("tap", HideOverlayCrossfade)

    dumpInfoD = display.newText({ parent = sceneGroup, text = "", x = 500, y = 1000, width = 900})
    --dumpInfoX2 = display.newText({ parent = sceneGroup, text = "", x = 500, y = 1400, width = 900})
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        creature = composer.getVariable("creatureCaught")
        currentDifficulty = difficulties[creature.difficulty]
        seconds = currentDifficulty.seconds
        jumpD2.text = ""
    elseif ( phase == "did" ) then
        --dumpInfoD.text = currentAltitude .. ' ' .. dump(startingPoint)
        --dumpInfoD.isVisible = false

        if (currentAltitude == nil or startingPoint.altitude == nil) then
           --bail on this logic. Possibly on the simulator.
           jumpD2.text = "No altitude data available."
           timer.performWithDelay(3000, HideOverlayCrossfade, 1)
           return
        end

        local change = math.abs(currentAltitude - startingPoint.altitude)
        jumpD1.text = "Move Up or Down " .. currentDifficulty.meters .. " Meters From Start"
        jumpD3.text = "Current Altitude Change: " .. math.round(change, 3) .. " meters"

        baseCreature = FindCreatureById(creature.creatureIdCaught)
        creatureEarned = MakeCreatureDisplay(baseCreature.eliteId)
        creatureEarned.pic.height = 512
        creatureEarned.pic.width = 512
        creatureEarned.text.y = creatureEarned.text.y + 256
        creatureEarned.x = display.contentCenterX
        creatureEarned.y = 1000
        creatureEarned.isVisible = false
        sceneGroup:insert(creatureEarned)

        if change >= currentDifficulty.meters then
            jumpD2.text = "Done!"
            ActiveChallengeSuccess(baseCreature)
            creatureEarned.isVisible = true
        else
            jumpD2.text = "Missed!"
        end
        timer.performWithDelay(3000, HideOverlayCrossfade, 1)
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