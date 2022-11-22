local composer = require( "composer" )
local scene = composer.newScene()
 
 --Active challenge E
 --Identify which direction a given PlusCode is in from you. 8-way change.
 --ISSUES:
-- May still be too difficult for new players. May want to have level 1-2 difficulty only do 4-way directions, and add in the diagonals at higher difficulties

--UI
local jumpE1 = ''
local jumpE2 = ''
local jumpE3 = ''
local jumpECancel = ''
local dumpInfoE = '' --dumping debug info onscreen in dev
--local dumpInfoE2 = ''

--table is in y,x order, but upside down because of how I generate the shift. lower left is 1,1 . 3,3 is upper right.
local results = {
    {0, 0, 0},
    {0, 0, 0},
    {0, 0, 0}
}

local dirNW = {}
local dirN = {}
local dirNE = {}
local dirE = {}
local dirSE = {}
local dirS = {}
local dirSW = {}
local dirW = {}

--vars
local creature = ''
local baseCreature = {}
local seconds = 0
local destPlusCode = ''

--common and config stuff
local countdownTimerE = {}
local creatureEarned = {}
local currentDifficulty = {}
local difficulties = {}
difficulties[1] = {seconds = 15, pairs = 1}
difficulties[2] = {seconds = 15, pairs = 2}

local function TimerCallbackE() 
    seconds = seconds - 1
    jumpE2.text = "Time Left: " .. seconds
    if seconds <= 0 then
        jumpE2.text = "Missed!"
        timer.performWithDelay(2000, HideOverlayCrossfade, 1)
        timer.cancel(countdownTimerE)
    end
 end

 local function PickAnswer()
    local xShift = 2 --middle of the results grid
    local yShift = 2

    while xShift == 2 and yShift == 2 do
        xShift = math.random(3) 
        yShift = math.random(3) 
    end
    results[yShift][xShift] = 1
    --so, to get SW, these results are 1, 1. 
    --or to get just E the results are 2, 3.

    --now shift these down to the actual change in distance.
    xShift = xShift- 2
    yShift = yShift- 2

    local digitPair = math.random(currentDifficulty.pairs)
    destPlusCode = RemovePlus(currentPlusCode)
    destPlusCode = ShiftCellNoPlus(destPlusCode, yShift, digitPair * 2 - 1)
    destPlusCode = ShiftCellNoPlus(destPlusCode, xShift, digitPair * 2)

    destPlusCode = destPlusCode:sub(1,8) .. '+' .. destPlusCode:sub(9,10)
 end

 local function CheckAnswer(x, y)
    timer.cancel(countdownTimerE)
    timer.performWithDelay(2000, HideOverlayCrossfade, 1)
    if results[y][x] == 1 then
        --correct
        jumpE2.text = "Correct!"
        ActiveChallengeSuccess(baseCreature)
        creatureEarned.isVisible = true
    else
        --wrong
        jumpE2.text = "Missed!"
    end
 end

local function DirNWTap(event)
    CheckAnswer(1,3)
end

local function DirNTap(event)
    CheckAnswer(2,3)
end

local function DirNETap(event)
    CheckAnswer(3,3)
end

local function DirETap(event)
    CheckAnswer(3,2)
end

local function DirSETap(event)
    CheckAnswer(3,1)
end

local function DirSTap(event)
    CheckAnswer(2,1)
end

local function DirSWTap(event)
    CheckAnswer(1,1)
end

local function DirWTap(event)
    CheckAnswer(1,2)
end

function scene:create( event )
    local sceneGroup = self.view
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 980, 1400)    
    bg.fill = bgFill

    jumpE1 = display.newText({ parent = sceneGroup, text = "Which Way to ", x = display.contentCenterX, y = 400})
    jumpE1.anchorX = 0.5

    jumpE2 = display.newText({ parent = sceneGroup, text = "Time left:", x = display.contentCenterX, y = 470})

    jumpE3 = display.newText({ parent = sceneGroup, text = "", x = 100, y = 600})
    jumpE3.anchorX = 0

    jumpECancel = display.newText({ parent = sceneGroup, text = "Cancel", x = display.contentCenterX, y = 1600})
    jumpECancel:addEventListener("tap", HideOverlayCrossfade)

    dirNW = display.newImageRect(sceneGroup, 'themables/ArrowNW.png', system.ResourceDirectory, 128, 128)
    dirNW.x = 350
    dirNW.y = 600
    dirNW:addEventListener('tap', DirNWTap)

    dirN = display.newImageRect(sceneGroup, 'themables/ArrowN.png', system.ResourceDirectory, 128, 128)
    dirN.x = 500
    dirN.y = 600
    dirN:addEventListener('tap', DirNTap)

    dirNE = display.newImageRect(sceneGroup, 'themables/ArrowNE.png', system.ResourceDirectory, 128, 128)
    dirNE.x = 650
    dirNE.y = 600
    dirNE:addEventListener('tap', DirNETap)

    dirW = display.newImageRect(sceneGroup, 'themables/ArrowW.png', system.ResourceDirectory, 128, 128)
    dirW.x = 350
    dirW.y = 750
    dirW:addEventListener('tap', DirWTap)

    dirE = display.newImageRect(sceneGroup, 'themables/ArrowE.png', system.ResourceDirectory, 128, 128)
    dirE.x = 650
    dirE.y = 750
    dirE:addEventListener('tap', DirETap)

    dirSW = display.newImageRect(sceneGroup, 'themables/ArrowSW.png', system.ResourceDirectory, 128, 128)
    dirSW.x = 350
    dirSW.y = 900
    dirSW:addEventListener('tap', DirSWTap)

    dirS = display.newImageRect(sceneGroup, 'themables/ArrowS.png', system.ResourceDirectory, 128, 128)
    dirS.x = 500
    dirS.y = 900
    dirS:addEventListener('tap', DirSTap)

    dirSE = display.newImageRect(sceneGroup, 'themables/ArrowSE.png', system.ResourceDirectory, 128, 128)
    dirSE.x = 650
    dirSE.y = 900
    dirSE:addEventListener('tap', DirSETap)

    dumpInfoE = display.newText({ parent = sceneGroup, text = "", x = display.contentCenterX, y = 1100  , width = 900})
    --dumpInfoE2 = display.newText({ parent = sceneGroup, text = "", x = 500, y = 1400, width = 900})
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        creature = composer.getVariable("creatureCaught")
        
        currentDifficulty = difficulties[creature.difficulty]
        seconds = currentDifficulty.seconds
        jumpE2.text = "Time Left: " .. seconds
    elseif ( phase == "did" ) then
        results = {
            {0, 0, 0},
            {0, 0, 0},
            {0, 0, 0}
        }

        countdownTimerE = timer.performWithDelay(1000, TimerCallbackE, currentDifficulty.seconds)
        PickAnswer()
        jumpE1.text = "Which Way to " .. destPlusCode .. "?"

        --dumpInfoE.text = dump(results)
        baseCreature = FindCreatureById(creature.creatureIdCaught)
        creatureEarned = MakeCreatureDisplay(baseCreature.eliteId)
        creatureEarned.pic.height = 512
        creatureEarned.pic.width = 512
        creatureEarned.text.y = creatureEarned.text.y + 256
        creatureEarned.x = display.contentCenterX
        creatureEarned.y = 1200
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