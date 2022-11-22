local composer = require( "composer" )
local scene = composer.newScene()
local json = require("json")
require('PraxisMapper')
 
 local username = ''
 local password = ''
 local statusText = ''
 local isCreating = false

 function SaveLoginData()
    credentials.username = username.text
    credentials.password = password.text
    SaveToFile('credentials.json', credentials)
 end

 function CreateServerAccount()
    if (username.text == '' or password.text == '') then
        statusText.text = "Enter the username and password you want to use, then tap Create Account again"
        return
    end

    SaveLoginData()
    isCreating = true
    local urlA = serverURL .. "Server/CreateAccount/"  .. username.text .. "/" .. password.text
    network.request(urlA, "PUT", CreateAccountListenerA, normalParams)
    composer.showOverlay("overlays.LoadingOverlay", {isModal = true})
 end

 function CreateAccountListenerA(event)
    if (event.status == 200) then
        if (event.response == "false") then
            composer.hideOverlay()
            statusText.text = "Account already exists"
        else
            LoginForCreate()
        end
    else
        composer.hideOverlay()
        statusText.text = "Could not connect to server."
    end
 end

 function CreatePluginAccount()
    if isCreating then
        isCreating = false
        local urlB = serverURL .. "Tibo/Account/Create"
        network.request(urlB, "PUT", CreateAccountListenerB, normalParams)
    end
 end

 function CreateAccountListenerB(event)
    composer.hideOverlay()

    if (event.status == 200) then
        if (response == "false") then
            statusText.text = "Account already exists"
        else
            --login with our new account.
            GetAccount()
        end
    else
        statusText.text = "Could not connect to server."
    end
 end

 function GetAccount()
    local url = serverURL .. "Tibo/Account/"
    network.request(url, "GET", AccountListener, normalParams)
    composer.showOverlay("overlays.LoadingOverlay", {isModal = true})    
 end

 function AccountListener(event)
    composer.hideOverlay()
    if (event.status == 200) then
        if (event.response == "") then
            statusText.text = "Account call failed."
        else
            playerData = json.decode(event.response)
            composer.gotoScene("scenes.loadingScene")
        end
    else
        statusText.text = "Could not connect to server."
    end
 end
 
 function ChangePassword()
    --NOTE: this will need to call both /Server/ChangePassword and /Tibo/Account/ChangePwd.
    --the first handles auth, the second handles account data. - May not be true anymore.
 end

 function ChangePasswordListener(event)
    --print(dump(event))
 end

 function Login()
    ClearAuthHeaders()
    local url = serverURL .. "Server/Login/"  .. username.text .. "/" .. password.text    
    network.request(url, "GET", LoginListener, normalParams)
    composer.showOverlay("overlays.LoadingOverlay", {isModal = true})
 end

 function LoginForCreate()
    ClearAuthHeaders()
    local url = serverURL .. "Server/Login/"  .. username.text .. "/" .. password.text    
    network.request(url, "GET", LoginForCreateListener, normalParams)
    composer.showOverlay("overlays.LoadingOverlay", {isModal = true})
 end

 function SetAuthInfoOnLogin(event)
    local authData = json.decode(event.response)
    authToken = authData.authToken
    authExpiration = os.time() + authData.expiration
    playerData.Name = username.text --will get reset later, but this is necessary now.

    normalParams.headers = AddAuthHeaders(normalParams.headers)
    binaryParams.headers = AddAuthHeaders(binaryParams.headers)
    reauthTimer = timer.performWithDelay(authData.expiration * 900, ReAuth, -1) --function ReAuth in main.lua. Run it when 90% of the way to expiration.
 end

function CommonLoginBehavior(source, event)
    if (event.status == 204 or event.status == 200) then
        if (event.response == "") then
            statusText.text = "Login failed."
            composer.hideOverlay()
        else
            SaveLoginData()
            SetAuthInfoOnLogin(event)
            if source == "create" then
                CreatePluginAccount()
            elseif source == 'login' then
                GetAccount()
            end
        end
    else
        composer.hideOverlay()
        statusText.text = "Could not connect to server."
    end
end

 function LoginForCreateListener(event)
    CommonLoginBehavior('create', event)
 end

 function LoginListener(event)
    CommonLoginBehavior('login', event)
 end

 function TryLogin()
    if (credentials.username ~= nil) then
        composer.showOverlay("overlays.LoadingOverlay", {isModal = true})
        statusText.text = "Logging in..."

        local url = serverURL .. "Server/Login/"  .. credentials.username .. "/" .. credentials.password
        network.request(url, "GET", LoginListener, normalParams)
    end
 end
 
function scene:create( event )
    local sceneGroup = self.view

    local jump1 = display.newText({ parent = sceneGroup, text = "Create Account", x = 100, y = 1200})
    jump1.anchorX = 0
    jump1:addEventListener("tap", CreateServerAccount)

    local jump2 = display.newText({ parent = sceneGroup, text = "Login to Account", x = 100, y = 800})
    jump2.anchorX = 0
    jump2:addEventListener("tap", Login)
 
    local jump3 = display.newText({ parent = sceneGroup, text = "Change Password", x = 100, y = 1000})
    jump3.anchorX = 0
    jump3.isVisible = false --set to true once i have a server endpoint for this.

    statusText = display.newText({ parent = sceneGroup, text = "", x = 100, y = 300, width = 800})
    statusText.anchorX = 0
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
 
    elseif ( phase == "did" ) then
        username = native.newTextField(400, 500, 600, 100)
        username.placeholder= "account id"

        password = native.newTextField(400, 600, 600, 100)
        password.placeholder= "password"
        password.isSecure = true

        if (credentials == {}) then
            composer.hideOverlay()
            return
        end

        username.text = credentials.username
        password.text = credentials.password

        if (credentials.username ~= '') then
            timer.performWithDelay(2, TryLogin, 1) --This is required because android won't see the text assigned 2 lines up until after the frame is drawn.
        end
    end
end
 
function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        if username.removeSelf  ~= nil then username:removeSelf() end
        if password.removeSelf ~= nil then password:removeSelf() end 
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