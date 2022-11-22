local composer = require( "composer" )
local scene = composer.newScene()
require('common')
local json = require('json')

local thisSceneView = {}
local loadingBox = {}
local coinCount = {}

--tweaked version for shop display
local function MakeCreatureDisplayShop(creatureId) --this is pretty big with default font sizes.
    local c = FindCreatureById(creatureId)
    local creatureGroup = display.newGroup()
    local creaturePic = display.newImageRect(creatureGroup, c.imageName, system.DocumentsDirectory, 256, 256)
    local creatureText = display.newText({parent = creatureGroup, text = c.name, x = 0, y = 170})
    return creatureGroup
end

local function BuyListener(event)
    -- remove coins, update 
    if NetCallCheck(event.status) == false then
        return
    end

    local response = json.decode(event.response)
    BoostCreatureById(response.creatureId)
    playerData.currencies.baseCurrency = playerData.currencies.baseCurrency - response.creatureCost
    coinCount.text = "Coins: " ..playerData.currencies.baseCurrency
end

local function BuyThisCreature(self, event)
    local url = serverURL .. 'CoinShop/Buy/' .. self.creatureId
    network.request(url, "GET", BuyListener, normalParams)
end

local function GetShopListener(event)
    if NetCallCheck(event.status) == false then
        GetShopEntries()
        return
    end

    loadingBox.isVisible = false
    --Make 3 boxes, show creature name, image, and cost.
    local entries = json.decode(event.response)
    local thisShopGroup = display.newGroup()
    for k,v in pairs(entries) do
        local creatureEntryBox = MakeCreatureDisplayShop(v.creatureId)
        creatureEntryBox.y = k * 450
        creatureEntryBox.x = display.contentCenterX
        creatureEntryBox.tap = BuyThisCreature
        creatureEntryBox.creatureId = v.creatureId
        creatureEntryBox:addEventListener('tap', creatureEntryBox)
        thisShopGroup:insert(creatureEntryBox)
        local costText = display.newText({parent = thisShopGroup, text = "Cost: " .. v.creatureCost .. " Coins", x = display.contentCenterX, y = 200 + (k * 450)})
        costText.anchorY = 0
    end

    thisSceneView:insert(thisShopGroup)
end

local function GetShopEntries()
    local url = serverURL .. 'CoinShop/Entries'
    network.request(url, "GET", GetShopListener, normalParams)
end

function scene:create( event ) 
    local sceneGroup = self.view
    thisSceneView = sceneGroup

    local bg = display.newRect(sceneGroup, display.contentCenterX, display.contentCenterY, 980, 1800)    
    bg.fill = bgFill

    local header = display.newText({ parent = sceneGroup, text = "Coin Shop", x = display.contentCenterX, y = 150, fontSize = 64})
    coinCount = display.newText({ parent = sceneGroup, text = "Coins:" .. playerData.currencies.baseCurrency, x = display.contentCenterX, y = 200})

    local exitButton = display.newText({ parent = sceneGroup, text = "Close", x = display.contentCenterX, y = 1800})
    exitButton:addEventListener("tap", HideOverlay)

    loadingBox = display.newImageRect(sceneGroup, "themables/LoadingOverlay.png", 260, 260)
    loadingBox.x = display.contentCenterX
    loadingBox.y = display.contentCenterY
end
 
function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        GetShopEntries()
        loadingBox.isVisible = true 
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