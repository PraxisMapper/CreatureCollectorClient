local composer = require( "composer" )
local scene = composer.newScene()
local widget = require("widget")
require("transitionFunctions")

local pickScroll = {}
local pickScreen = {}
local dataPage = {}
local name = {}
local picture = {}
local descText = {}
local statsText = {}
--To list off stats, pictures, hints, and info on creatures.
 
local function ShowCreatureInfo(self, event)
    local c = FindCreatureById(self.creatureId)
    local myStats = myCreatures[tostring(self.creatureId)]
    name.text = c.name
    picture.fill = {
        type = "image",
        filename =  c.imageName,
        baseDir = system.DocumentsDirectory
    }
    if (myStats.hintUnlocked == true and myStats.totalCaught == 0) then
        SilhouetteImage(picture)
        statsText.text = "Found At: " .. c.hintText
        descText.text = ""
    else
        descText.text = c.flavorText
        statsText.text = "Level: " .. myStats.level .. "\nStrength: " .. math.floor(c.stats.strengthPerLevel * myStats.level) 
        .. "\nDefense: " .. math.floor(c.stats.defensePerLevel * myStats.level) .. "\nScouting: " .. math.floor(c.stats.scoutingPerLevel * myStats.level) 
        .. "\nTo Next Level: " .. myStats.toNextLevel .. "\nTotal Collected: " ..myStats.totalCaught .. "\nFound At: " .. c.hintText
    end
    dataPage.x = 0
    return true
end

local function HideCreatureInfo()
    dataPage.x = -3000
    return true
end

--special, different, screen-specific version of this function in common.lua
local function MakeCreatureDisplayI(c) 
    local shouldShow = myCreatures[tostring(c.id)]
    local creatureGroup = display.newGroup()
    creatureText = display.newText({parent = creatureGroup, text = c.name, x = 0, y = 80})
    if shouldShow == nil then
        creaturePic = display.newImageRect(creatureGroup, "themables/PickCreature.png", 96, 96)
        creatureText.text = "?????"
    elseif shouldShow.level > 0 then
        creaturePic = display.newImageRect(creatureGroup, c.imageName, system.DocumentsDirectory, 96, 96)
    elseif shouldShow.hintUnlocked == true then
        creaturePic = display.newImageRect(creatureGroup, c.imageName, system.DocumentsDirectory, 96, 96)
        SilhouetteImage(creaturePic)
        creatureText.text = "Hint" --Show actual hint when creature is tapped. They're long and don't fit here.
    end
    
    return creatureGroup
end

local function FillPickWindowI(tapHandler)
    --NOTE: this one works differently from the shared version, and shouldn't be shoved into it.
    pickScreen = display.newGroup()
    pickScroll = widget.newScrollView({left = 0, top = 0, width = 1080, height = 1720, backgroundColor = bgFill, horizontalScrollDisabled = true }) --{0, 0, 0, 1}
    pickScreen:insert(pickScroll)

    local xCounter = 0
    local yCounter = 0

    for k, v in pairs(creatureInfo) do
        if (v.isHidden == true and myCreatures[tostring(v.id)] == nil) then
            --skip this one. It's unobtainable
        else
            local icon = MakeCreatureDisplayI(v)
            icon.creatureName = k
            icon.creatureId = v.id
            pickScroll:insert(icon) 
            icon.x = 150 + (xCounter % 3) * 350
            icon.y = 100 + math.floor(yCounter / 3) * 200
            icon.anchorX = 0
            icon.anchorY = 0
            icon.creatureId = v.id
            icon.creatureIcon = thisIcon
            if myCreatures[tostring(v.id)] ~= nil then
                icon.tap = tapHandler 
                icon:addEventListener("tap", icon)
            end
            xCounter = xCounter + 1
            yCounter = yCounter + 1
        end
    end
end

function ClosePickWindowI()
    pickScreen:removeSelf()
    return true
end 

function scene:create( event )
    local sceneGroup = self.view
end

function scene:show( event ) 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
 
    elseif ( phase == "did" ) then
        --Make baseline list
        FillPickWindowI(ShowCreatureInfo)

        --Make offscreen info page.
        dataPage = display.newGroup()
        local bg = display.newRect(dataPage, display.contentCenterX, display.contentCenterY, 980, 1850)    
        bg.fill = {.5, .5, .5, 1} --bgFill
        name = display.newText({ x = 100, y = 200, parent = dataPage, text = ''  })
        name.anchorX = 0
        name.anchorY = 0
        picture = display.newImageRect(dataPage, "themables/PickCreature.png", 512, 512)
        picture.anchorX = 0
        picture.anchorY = 0
        picture.x = 500
        picture.y = 150
        descText = display.newText({ x = 140, y = 700, parent = dataPage, text = '', width = 900  })
        descText.anchorX = 0
        descText.anchorY = 0
        statsText = display.newText({ x = 140, y = 1100, parent = dataPage, text = '', width = 900  })
        statsText.anchorX = 0
        statsText.anchorY = 0

        local ICancelButton = MakeCancelButton(display.contentCenterX, 1700, dataPage, HideCreatureInfo)
        dataPage.x = -3000
        dataPage.y = 0

        local CancelButton = MakeCancelButton(display.contentCenterX, 1800, sceneGroup, CloseThis)
    end
end
  
function scene:hide( event ) 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then

    elseif ( phase == "did" ) then
        if pickScroll.removeSelf ~= nil then pickScroll:removeSelf() end
        if pickScreen.removeSelf ~= nil then pickScreen:removeSelf() end 
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