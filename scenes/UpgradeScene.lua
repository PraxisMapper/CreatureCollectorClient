local composer = require("composer")
local scene = composer.newScene()
local json = require("json")
local widget = require("widget")
require('common')

local sceneView = ''
local pickScreen = {}
local tasks = {}

local function OpenPickWindow(self, event)
    FillPickWindowU(self.task, self)
end

function AssignCreatureListener(self, event)
    --this sends the assignment request to the server.
    local url = serverURL .. 'Improve/Assign/' .. self.creatureId .. '/' .. self.task.id
    network.request(url, "PUT", AssignCreatureNetListener, normalParams)
    local baseCreature = FindCreatureById(self.creatureId)
    self.creatureIcon.fill = {
        type = "image",
        filename = baseCreature.imageName,
        baseDir =  system.DocumentsDirectory
    }

    local creatureSent = FindCreatureById(self.creatureId)
    myCreatures[tostring(creatureSent.id)].available = false
    myCreatures[tostring(creatureSent.id)].assignedTo = self.task.id
    self.task.assigned = self.creatureId

    CancelPickU()
end

function AssignCreatureNetListener(event)
    --mark stuff locally, or un-mark stuff locally on failure?
    if NetCallCheck(event.status) == false then
    end
    
    CancelPickU()
end

local function CancelTask(self, event)
    if (self.task.assigned ~= 0) then
        local creatureFree = FindCreatureById(self.task.assigned)
        myCreatures[tostring(creatureFree.id)].available = true
        myCreatures[tostring(creatureFree.id)].assignedTo = ''
    end

    local url = serverURL .. 'Improve/CancelTask/' .. self.task.id
    network.request(url, "PUT", CancelTaskListener, normalParams)
    --update UI to be cleared out.
    self.creatureIcon.fill = {
        type = "image",
        filename = 'themables/PickCreature.png'
    }
end

function CancelTaskListener(event)
    --remove entries or re-add entries on failure?
    if NetCallCheck(event.status) == false then
    end
end


function MakeImprovementWidget(task)
    local thisGroup = display.newGroup()
    local bg = display.newRect(thisGroup, 0, 0, 1030, 200)    
    bg.anchorX = 0
    bg.anchorY = 0
    bg.fill = bgFill
    local mainText = display.newText({ parent = thisGroup, text = task.name, x = 10, y = 30})
    mainText.anchorX = 0
    local creatureIcon = display.newImageRect(thisGroup, "themables/PickCreature.png", 128, 128)
    if (task.assigned ~= nil) then
        local baseCreature = FindCreatureById(task.assigned)
        local imageFill = {
            type = "image",
            filename = baseCreature.imageName,
            baseDir =  system.DocumentsDirectory
        }
        creatureIcon.fill = imageFill
    end
    creatureIcon.x = 10
    creatureIcon.y = 60
    creatureIcon.anchorX = 0
    creatureIcon.anchorY = 0
    creatureIcon.assigned = task.assigned
    creatureIcon.task = task
    creatureIcon.tap = OpenPickWindow
    creatureIcon:addEventListener("tap", creatureIcon)

    --My standard cancel button function cannot take in itself as the listener.
    local cancelButtonI = display.newImageRect(thisGroup, "themables/CancelButton.png", 300, 100)
    cancelButtonI.x = 700
    cancelButtonI.anchorX = 0
    cancelButtonI.y = 90
    cancelButtonI.task = task
    cancelButtonI.creatureIcon = creatureIcon
    cancelButtonI.tap = CancelTask
    cancelButtonI:addEventListener("tap", cancelButtonI)

    local progressMeter = display.newRect(thisGroup, 80, 90, 500, 50)
    progressMeter.x = 150
    progressMeter.anchorX = 0
    local filledMeter = display.newRect(thisGroup, 80, 90, 500, 50)
    filledMeter.fill = {1, 0, 0}
    filledMeter.x = 150
    filledMeter.anchorX = 0
    local percent = (task.accrued /  task.timePerResult)
    filledMeter.width = filledMeter.width * percent

    local amountText = display.newText({ parent = thisGroup, text = '' .. task.accrued .. ' / ' .. task.timePerResult .. ' (' .. math.floor(percent * 100) .. '%)' , x = 400, y = 100, fontSize = 30})
    amountText.fill = {0, 0, 0}

    local descText = display.newText({ parent = thisGroup, text = task.desc, x = 150, y = 160, fontSize = 30})
    descText.anchorX = 0

    thisGroup.task = task
    thisGroup.creatureIcon = creatureIcon
    return thisGroup
end

function CancelPickU(event)
    pickScreen:removeSelf()
end

--This version is also unique in that it attaches tasks to each entry here., so its hard to recycle.
function FillPickWindowU(task, thisIcon)
    pickScreen = display.newGroup() 
    local pickTouchLock = display.newRect(pickScreen, display.contentCenterX, display.contentCenterY, 1080, 1920)     --blocks touches for the background
    pickTouchLock.fill = {0, 0, 0, .01}
    pickTouchLock:addEventListener("tap", blockTouch)
    local pickBg = display.newRect(pickScreen, display.contentCenterX, display.contentCenterY, 700, 1400)
    pickBg.fill = {.6, .6, .5, 1}
    local pickScroll = widget.newScrollView({left = 100, top = 100, width = 880, height = 1720, backgroundColor = {0, 0, 0, 1} })
    pickScreen:insert(pickScroll)
    local pickCancel = MakeCancelButton(display.contentCenterX, 1870, pickScreen, CancelPickU)

    local xCounter = 0
    local yCounter = 0

    for k, v in pairs(myCreatures) do
        if v.available == true and v.level > 0 then --we might have a hint property set, which means we have 0 of that creature, don't display it here.
            local icon = MakeCreatureDisplay(v.id)
            icon.creatureName = k
            icon.creatureId = v.id
            pickScroll:insert(icon) --make sure this can be done before and not after x/y values are set.
            icon.x = 200 + (xCounter % 3) * 250
            icon.y = 100 + math.floor(yCounter / 3) * 200
            icon.anchorX = 0
            icon.anchorY = 0
            icon.creatureId = v.id
            icon.creatureIcon = thisIcon
            xCounter = xCounter + 1
            yCounter = yCounter + 1
            icon.task = task
            icon.tap = AssignCreatureListener
            icon:addEventListener("tap", icon)
        end
    end
end

function TaskProgressListener(event)
    if NetCallCheck(event.status) == false then
        --TODO: display some info about a network failure.
        return
    end

    local i = 1
    tasks = json.decode(event.response)
    for k, v in pairs(tasks) do
        local taskUi = MakeImprovementWidget(v)
        taskUi.x = 25
        taskUi.y = 50 + (i-1) * 250
        sceneView:insert(taskUi)
        i = i + 1
    end
end

function scene:create( event )
    local sceneGroup = self.view
    sceneView = sceneGroup

    local backLink = display.newText({ parent = sceneGroup, text = "Return to Previous Screen", x = 10, y = 1850})
    backLink.x = display.contentCenterX
    backLink:addEventListener("tap", CloseThis)
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
 
    elseif ( phase == "did" ) then
        local url = serverURL .. 'Improve/TaskProgress/'
        network.request(url, "GET", TaskProgressListener, normalParams)
        RequestTutorial("upgradesIntro")
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