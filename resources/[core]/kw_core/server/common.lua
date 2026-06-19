KW.Players = {}
KW.Jobs = {}
KW.Items = {}

RegisterNetEvent("kw:onPlayerSpawn", function()
    KW.Players[source].spawned = true
end)

if Config.CustomInventory then
    SetConvarReplicated("inventory:framework", "kw")
    SetConvarReplicated("inventory:weight", tostring(Config.MaxWeight * 1000))
end

local function StartDBSync()
    CreateThread(function()
        local interval <const> = 10 * 60 * 1000
        while true do
            Wait(interval)
            Core.SavePlayers()
        end
    end)
end

PostgreSQL.ready(function()
    -- Run schema migrations before anything else
    local Migrations = require 'server.modules.migrations'
    Migrations.Run()

    Core.DatabaseConnected = true

    if not Config.CustomInventory then
        KW.RefreshItems()
    end

    KW.RefreshJobs()

    print(("[^2INFO^7] KW ^5Legacy %s^0 initialized!"):format(GetResourceMetadata(GetCurrentResourceName(), "version", 0)))

    StartDBSync()
    if Config.EnablePaycheck then
        StartPayCheck()
    end
end)

RegisterNetEvent("kw:clientLog", function(msg)
    if Config.EnableDebug then
        print(("[^2TRACE^7] %s^7"):format(msg))
    end
end)

RegisterNetEvent("kw:ReturnVehicleType", function(Type, Request)
    if Core.ClientCallbacks[Request] then
        Core.ClientCallbacks[Request](Type)
        Core.ClientCallbacks[Request] = nil
    end
end)

GlobalState.playerCount = 0
