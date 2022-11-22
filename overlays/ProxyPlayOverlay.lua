local composer = require( "composer" )
local scene = composer.newScene()

local parentUpdateCallback = nil
local customPlace = {}
local placeE = {}
local placeESub = {}
 
function SetProxyPlayPoint(proxyPoint)
    local url = serverURL .. 'Tibo/ProxyPlay/' .. proxyPoint
    network.request(url, "PUT", ProxyPointListener, normalParams)

    HideOverlay()
end

function ProxyPointListener(event)
    if NetCallCheck(event.status) == false then
        --probably need to reset since network call failed or no proxy token was usable.
        return
    end
    playerData.currencies.proxyPlayTokens = playerData.currencies.proxyPlayTokens - 1
    local response = json.decode(event.response)
    if (event.response == '{}') then
        playerData.proxyPlayPoint = nil
    else
        playerData.proxyPlayPoint = response
    end
    if (parentUpdateCallback ~= nil) then parentUpdateCallback() end

    --for simulator, will be overwritten next GPS event on devices
    if (response ~= nil and event.response ~= "{}") then
        currentPlusCode = EncodeLatLon(response.lat, response.lon, 10)
    end
end
 
function ProxyToPlace1(event)
    SetProxyPlayPoint(proxyPlayPoints[1].location)
end

function ProxyToPlace2(event)
    SetProxyPlayPoint(proxyPlayPoints[1].location)
end

function ProxyToPlace3(event)
    SetProxyPlayPoint(proxyPlayPoints[3].location)
end

function ProxyToPlace4(event)
    SetProxyPlayPoint(proxyPlayPoints[4].location)
end

function ProxyToCustom(event)
    local plusCodeNoPlus = RemovePlus(customPlace.text)
    SetProxyPlayPoint(plusCodeNoPlus)
end

function ProxyClear(event)
    SetProxyPlayPoint('')
end

function scene:create( event ) 
    local sceneGroup = self.view

    bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 980, 1800)    
    bg.fill = bgFill

    local exitButton = display.newText({ parent = sceneGroup, text = "Cancel", x = display.contentCenterX, y = 1800})
    exitButton:addEventListener("tap", HideOverlay)
    local headerText = display.newText({ parent = sceneGroup, text = "Set your ProxyPlay point", x = display.contentCenterX, y = 200, fontSize = 65})

    local placeA = display.newText({ parent = sceneGroup, text = proxyPlayPoints[1].name, x = display.contentCenterX, y = 400})
    placeA:addEventListener("tap", ProxyToPlace1)
    local placeASub = display.newText({ parent = sceneGroup, text = proxyPlayPoints[1].desc, x = display.contentCenterX, y = 460, fontSize = 35})

    local placeB = display.newText({ parent = sceneGroup, text = proxyPlayPoints[2].name, x = display.contentCenterX, y = 600})
    placeB:addEventListener("tap", ProxyToPlace2)
    local placeBSub = display.newText({ parent = sceneGroup, text = proxyPlayPoints[2].desc, x = display.contentCenterX, y = 660, fontSize = 35})

    local placeC = display.newText({ parent = sceneGroup, text = proxyPlayPoints[3].name, x = display.contentCenterX, y = 800})
    placeC:addEventListener("tap", ProxyToPlace3)
    local placeCSub = display.newText({ parent = sceneGroup, text = proxyPlayPoints[3].desc, x = display.contentCenterX, y = 860, fontSize = 35})

    local placeD = display.newText({ parent = sceneGroup, text = proxyPlayPoints[4].name, x = display.contentCenterX, y = 1000})
    placeD:addEventListener("tap", ProxyToPlace4)
    local placeDSub = display.newText({ parent = sceneGroup, text = proxyPlayPoints[4].desc, x = display.contentCenterX, y = 1060, fontSize = 35})

    placeE = display.newText({ parent = sceneGroup, text = "Clear Proxy", x = display.contentCenterX, y = 1200})
    placeE:addEventListener("tap", ProxyClear)
    placeESub = display.newText({ parent = sceneGroup, text = "Use your actual location instead of proxying elsewhere", x = display.contentCenterX, y = 1260, fontSize = 35})

    local placeF = display.newText({ parent = sceneGroup, text = "Custom", x = display.contentCenterX, y = 1400})
    placeF:addEventListener("tap", ProxyToCustom)
    local placeFSub = display.newText({ parent = sceneGroup, text = "Set your own home point here, then tap Custom above.\n86HR-86FX recommended", x = display.contentCenterX, y = 1460, fontSize = 35})
    local placeFSub2 = display.newText({ parent = sceneGroup, text = "Todays Suggestion: " .. suggestedProxyPoint, x = display.contentCenterX, y = 1560, fontSize = 35})
    customPlace = native.newTextField(display.contentCenterX, 1650, 600, 100)
    customPlace.placeholder = "AABBCCDD+EE"
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

    parentUpdateCallback = event.parent.UpdateProxyText
 
    if ( phase == "will" ) then
        if playerInBounds == false then
            placeE.isVisible = false
            placeESub.isVisible = false
        end
 
    elseif ( phase == "did" ) then

    end
end
 
function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        if customPlace.removeSelf ~= nil then customPlace:removeSelf() end
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