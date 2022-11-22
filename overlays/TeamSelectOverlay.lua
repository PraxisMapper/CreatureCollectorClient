local composer = require( "composer" )
local scene = composer.newScene()

local teamNum = 0
local teamDesc = {}
 
local teamDescriptions = {
    "Red is the best team, because red is the color of fast cars and the most delicious apples.", 
    "Green is the color of grass, which grows everywhere all the time, so it's like green already won. Also, the best apples are green and everyone knows it.", 
    "Purple, being a combination of two primary colors, is twice as good as the other teams. Purple apples are very rare, but are real, which makes them the best apples.", 
    "Grey is the color of bad apples, the renegades, loners, and... wait no, they're still a team. Disregard that 'loner' bit. Still the coolest team to join."
}
 
function setTeam(num)
    teamNum = num
    teamDesc.text = teamDescriptions[num]
end

function selectTeam(num)
    playerData.team = teamNum
    local url = serverURL .. 'Tibo/Team/' .. teamNum
    network.request(url, 'PUT', DefaultNetCallHandler, normalParams)
    HideOverlay()
    RequestTutorial("story2")
end

function setTeam1()
    setTeam(1)
end

function setTeam2()
    setTeam(2)
end

function setTeam3()
    setTeam(3)
end

function setTeam4()
    setTeam(4)
end

function scene:create( event ) 
    local sceneGroup = self.view
    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 980, 1400)
    bg.fill = bgFill

    local text1 = display.newText({ parent = sceneGroup, text = "Select Your Team!", x = display.contentCenterX, y = 350})
    teamDesc = display.newText({ parent = sceneGroup, text = "", x = display.contentCenterX, y = 1050, width = 800})
    teamDesc.anchorY = 0
    local confirmButton = display.newText({ parent = sceneGroup, text = "Confirm", x = display.contentCenterX, y = 1550})
    confirmButton.anchorX = .5
    confirmButton:addEventListener("tap", selectTeam)

    local team1 = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 200, 200)
    local team2 = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 200, 200)
    local team3 = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 200, 200)
    local team4 = display.newRect(sceneGroup,display.contentCenterX, display.contentCenterY, 200, 200)

    team1:addEventListener("tap", setTeam1)
    team2:addEventListener("tap", setTeam2)
    team3:addEventListener("tap", setTeam3)
    team4:addEventListener("tap", setTeam4)

    local team1Fill = {.8, .1, .1, 1} --red
    local team2Fill = {.1, .8, .1, 1} --green
    local team3Fill = {.21, .09, .51, 1} -- purple
    local team4Fill = {.3, .3, .3, 1} -- grey

    team1.fill = team1Fill
    team2.fill = team2Fill
    team3.fill = team3Fill
    team4.fill = team4Fill

    local teamSet = {}
    table.insert(teamSet, team1)
    table.insert(teamSet, team2)
    table.insert(teamSet, team3)
    table.insert(teamSet, team4)

    local posSet = {}
    table.insert(posSet, {x = 300, y = 500})
    table.insert(posSet, {x = 300, y = 900})
    table.insert(posSet, {x = 800, y = 500})
    table.insert(posSet, {x = 800, y = 900})

    for i = 1, 4 do --We randomize the order teams are displayed so that there's no positional bias (EX: more people pick the first team more often)
        local rng = math.random(#posSet)
        local pos = posSet[rng]
        teamSet[i].x = pos.x
        teamSet[i].y = pos.y
        table.remove(posSet, rng)
    end 
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
 
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