local composer = require( "composer" )
local scene = composer.newScene()
require("tutorialEntries") -- contains TutorialDataSets info
 
local imagebox = {}
local textBox = {}

local dataSet = "first"
local currentStep = 0;

--specialFunc should be a function that runs when its not nil, to allow for code to run like switching to display another overlay scene, or
--set values. EX1: if you're not in bounds, show an overlay to pick your first ProxyPlay point for free.

function testSpecial()
    print("Ran special code!")
end

function variableSub()
    local orig = textBox.text

    orig = orig:gsub("|name", playerData.name)
    orig = orig:gsub("|location", locationName)

    textBox.text = orig
end

function AdvanceDisplay()
    currentStep = currentStep + 1
    if currentStep == #tutorialDataSets[dataSet] then
        --save completion of this tutorial to the database on display of the last step.
        local url = serverURL .. 'Tibo/Tutorial/' .. dataSet
        network.request(url, 'PUT', DefaultNetCallHandler, normalParams)
        table.insert(tutorialsViewed, dataSet)
    end

    --Close the window if we're past the last step.
    if currentStep > #tutorialDataSets[dataSet] then
        composer.hideOverlay()
        return
    end
    
    local paint = {
        type = "image",
        filename = tutorialDataSets[dataSet][currentStep].image,
        baseDir = system.ResourceDirectory
    }
    imagebox.fill = paint
    textBox.text = tutorialDataSets[dataSet][currentStep].text
    variableSub()

    if (tutorialDataSets[dataSet][currentStep].specialFunc ~= nil) then
        tutorialDataSets[dataSet][currentStep].specialFunc()
    end
end

function TapListener(self, event)
    AdvanceDisplay()
end

function scene:create(event) 
    local sceneGroup = self.view    
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 8080, 1920)
    bg.fill = {.2, .2, .2, .7}

    imagebox = display.newImageRect(sceneGroup, "themables/placeholder.png", 512, 512)
    imagebox.x = 256
    imagebox.y = 799
    imagebox.anchorY = 1

    textBox = display.newText(sceneGroup, "", display.contentCenterX, display.contentCenterY, 800, 900, native.systemFont, 50)
    textBox.anchorY = 0

    sceneGroup:addEventListener("tap", TapListener)
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
    
    if ( phase == "will" ) then
        
    elseif ( phase == "did" ) then
        dataSet = composer.getVariable("tutorialData")
        currentStep = 0
        AdvanceDisplay() 
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