local composer = require( "composer" )
require('common')
local scene = composer.newScene()

local scoresText = {}

local function LeaderboardsListener(event)
    if NetCallCheck(event.status) == false then
        local text = "Control Mode Scores\n\n"
        local response = json.decode(event.response)
        for k,v in pairs(response) do
            local teamName = ''
            if k == 'team1Score' then teamName = team1Name end
            if k == 'team2Score' then teamName = team2Name end
            if k == 'team3Score' then teamName = team3Name end
            if k == 'team4Score' then teamName = team4Name end

            text = text .. teamName .. ': ' .. v .. '\n'
        end
        scoresText.text = text
    end
end

local function GetLeaderboardData()
    local url = serverURL .. 'Control/Leaderboards'
    network.request(url, "GET", LeaderboardsListener, normalParams)
end

function scene:create( event )
    local sceneGroup = self.view

    local bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 980, 1800)    
    bg.fill = bgFill

    local exitButton = display.newText({ parent = sceneGroup, text = "Close", x = display.contentCenterX, y = 1700})
    exitButton:addEventListener("tap", HideOverlay)

    scoresText = display.newText({ parent = sceneGroup, text = "Control Mode Scores", x = display.contentCenterX, y = 100})
    scoresText.anchorY = 0
end

function scene:show( event ) 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        GetLeaderboardData()
    elseif ( phase == "did" ) then
 
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