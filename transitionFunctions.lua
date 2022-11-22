local composer = require("composer")

function GoToControl()
    composer.gotoScene("scenes.TerritoryControlScene")
    --return true
end

function GoToCover()
    composer.gotoScene("scenes.CoverPvEScene")
    --return true
end

function JumpToStatus()
    composer.gotoScene("scenes.StatusScene")
end 

function GoToOptions()
    composer.gotoScene("scenes.OptionsScene")
 end

function JumpToHelp()
    composer.gotoScene("scenes.HelpScene")
    --return true
end 

function GoToCollect()
    composer.gotoScene("scenes.CollectScene")
    --return true
end 

function GoToCompete()
    composer.gotoScene("scenes.CompetePvPScene")
    --return true
end 

function GoToUpgrades()
    composer.gotoScene("scenes.UpgradeScene")
    --return true
end

function JumpToAccount()
    composer.gotoScene("scenes.AccountLoginScene")
end     

function ShowLeaderboardOverlay()
    composer.showOverlay("overlays.LeaderboardsOverlay", {isModal = true})
end

function ShowPassportOverlay()
    composer.showOverlay("overlays.PassportOverlay", {isModal = true})
end

function ShowCoverMapOverlay()
    composer.showOverlay("overlays.MyCoverMapOverlay", {isModal = true})
end

function ShowCompeteMapOverlay()
    composer.showOverlay("overlays.CompeteMapOverlay", {isModal = true})
end

function ShowCoinShopOverlay()
    composer.showOverlay("overlays.CoinShopOverlay", {isModal = true})
end

function JumpToTeam()
    composer.showOverlay("overlays.TeamSelectOverlay", {isModal = true})
    return true
end 

function JumpToProxy()
    composer.showOverlay("overlays.ProxyPlayOverlay", {isModal = true})
    return true
end 

function JumpToCreatureInfo()
    composer.gotoScene("scenes.CreatureInfoScene")
end 

function JumpToCover()
    composer.gotoScene("scenes.CoverPvEScene")
    return true
end 

function CloseThis(prevScene)
    composer.gotoScene(composer.getSceneName("previous"))
    return true
 end

 function HideOverlay()
    composer.hideOverlay()
 end

 function HideOverlayCrossfade()
    composer.hideOverlay(true, "crossFade", 200)
 end

 function OpenOSMLicenseInBrowser()
    system.openURL('https://www.openstreetmap.org/copyright')
end
