Core = {}
Core.Input = {}
Core.Events = {}

KW.PlayerData = {}
KW.PlayerLoaded = false
KW.playerId = PlayerId()
KW.serverId = GetPlayerServerId(KW.playerId)

KW.UI = {}
KW.UI.Menu = {}
KW.UI.Menu.RegisteredTypes = {}
KW.UI.Menu.Opened = {}

KW.Game = {}
KW.Game.Utils = {}

CreateThread(function()
    while not Config.Multichar do
        Wait(100)

        if NetworkIsPlayerActive(KW.playerId) then
            KW.DisableSpawnManager()
            DoScreenFadeOut(0)
            Wait(500)
            TriggerServerEvent("kw:onPlayerJoined")
            break
        end
    end
end)
