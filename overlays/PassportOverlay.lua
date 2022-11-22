local composer = require( "composer" )
local scene = composer.newScene()

--Passport mode:
--List all valid terrain types for this mode, and 3 checkboxes under each with space for a name.
--display a Stamp! button to mark the current (or nearest in the cell8, if not standing directly on it) location [leeway being provided to handle point locations]
--when 3 unique (by name) locations are stamped in a category, grant +1 to a creature granted by Passport mode and clear that terrain type's entries.
--(Most of this is done server-side)
local creatureEarned = {}
local uiElements = {}
local checkboxChecked = {
    type = "image",
    filename = 'themables/checkFilled.png',
    baseDir = system.ResourceDirectory
}
local checkboxEmpty = {
    type = "image",
    filename = 'themables/checkEmpty.png',
    baseDir = system.ResourceDirectory
}

local function HideEarnedCreature()
    --TODO: add and test fade. Make sure that existing .isVisible logic applies to it or change that to only work with alpha channel.
    --transition.fadeOut(creatureEarned, {time = 275} )
    creatureEarned.isVisible = false
end

local function StampListener(event)
    PostQueueCall(event)
    if (event.response ~= "") then
        --cool, update our stuff now.
        local response = Split(event.response, '|') --terrain|name|guid
        if #response == 3 then
            -- added an entry to the list if its new
            local entries = passportData[response[1]].currentEntries
            local addEntry = true
            for i = 1, #entries do
                if StartsWith(entries[i], response[1] .. "|" .. response[2]) then
                    addEntry = false
                end
            end
            if (addEntry) then
                table.insert(entries, event.response)
                local nextSlot = #entries
                uiElements[response[1]].checkboxes[nextSlot].fill = checkboxChecked
                uiElements[response[1]].textLines[nextSlot].text = response[2]
            end
        else
            -- got a creature, clear a terrain.
            passportData[response[1]] = { currentEntries = {}}
            for i = 1, 3 do
                uiElements[response[1]].checkboxes[i].fill = checkboxEmpty
                uiElements[response[1]].textLines[i].text = ''
            end
            
            local creatureData = FindCreatureByName(response[2])
            BoostCreatureById(creatureData.id)
            creatureEarned.pic.fill = {
                type = "image",
                filename = 'creatureImages/' .. creatureData.name .. '.png',
                baseDir = system.DocumentsDirectory
            }
            creatureEarned.text.text = creatureData.name
            creatureEarned.isVisible = true
            timer.performWithDelay(2000, HideEarnedCreature, 1)
        end
    else
        --TODO show we didn't stamp anything.
    end
end

local function StampMyPlace(self, event)
    local url = serverURL .. "Passport/Stamp/" .. RemovePlus(currentPlusCode) -- .. "/" .. self.areaType
    network.request(url, "PUT", StampListener, normalParams)
    return true
end
 
function MakePassportUIEntry(key, entry)
    --key is the string matching the 'terrain' type.
    --entry is a list of strings, in "terrain|name|GUID" format
    local thisGroup = display.newGroup()
    thisGroup.areaType = entry.type
    thisGroup.anchorX = 0
    thisGroup.anchorY = 0  

    --todo: new BG entry.
    local bg = display.newRect(thisGroup, 0, 0, 400, 200)
    bg.anchorX = 0
    bg.anchorY = 0
    bg.fill = {.1, .1, .1}

    thisGroup.checkboxes = {}
    thisGroup.textLines = {}
    local terrainType = display.newText({parent = thisGroup, text = key, x = 200, y = 10, fontSize = 40})
    terrainType.anchorX = 0.5
    terrainType.anchorY = 0
    for i = 1, 3 do 
        local thisCheckBox = display.newImageRect(thisGroup, "themables/checkEmpty.png", 24, 24)
        thisCheckBox.x = 15
        thisCheckBox.y = 50 + (40 * i)
        local thisName = display.newText({ parent = thisGroup, text = "", x = 50, y = 50  + (40 * i), fontSize = 30})
        thisName.anchorX = 0
        if (#entry.currentEntries >= i) then
            thisName.text = Split(entry.currentEntries[i], "|")[2]
            thisCheckBox.fill = checkboxChecked
        end
        thisGroup.checkboxes[i] = thisCheckBox
        thisGroup.textLines[i] = thisName
    end
    
    uiElements[key] = thisGroup
    return thisGroup
end

function scene:create( event )
    local sceneGroup = self.view
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 980, 1700)    
    bg.fill = bgFill

    display.newText({ parent = sceneGroup, text = "Passport", x = display.contentCenterX, y = 175, fontSize = 75})

    local stamp = display.newImageRect(sceneGroup, "themables/StampButton.png",300, 100)
    stamp.x = 350
    stamp.y = 1600
    stamp.tap = StampMyPlace
    stamp:addEventListener("tap", stamp) 

    local cancel = display.newImageRect(sceneGroup, "themables/CancelButton.png",300, 100)
    cancel.x = 750
    cancel.y = 1600
    cancel:addEventListener("tap", HideOverlay) 

    creatureEarned = MakeCreatureDisplay(1)
    creatureEarned.pic.height = 512
    creatureEarned.pic.width = 512
    creatureEarned.text.y = creatureEarned.text.y + 256
    creatureEarned.x = display.contentCenterX
    creatureEarned.y = 1000
    creatureEarned.isVisible = false
    sceneGroup:insert(creatureEarned)
end

function scene:show( event ) 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
 
    elseif ( phase == "did" ) then
        local i = 1
        for k,v in pairs(passportData) do
            local group = MakePassportUIEntry(k, v)
            group.y = 245 + ((i % 5) * 260)
            group.x = 120 + ((i % 2) * 450)
            sceneGroup:insert(group)
            i = i + 1
        end
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
    for i = 1, #uiElements do
        uiElements[i]:removeSelf()
    end
end
 
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
 
return scene