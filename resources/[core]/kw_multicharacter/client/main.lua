local nuiReady = false

CreateThread(function()
    while not KW.PlayerLoaded do
        Wait(100)

        if NetworkIsPlayerActive(KW.playerId) then
            KW.DisableSpawnManager()
            DoScreenFadeOut(0)
            Multicharacter:SetupCharacters()
            break
        end
    end
end)

-- Events

KW.SecureNetEvent("kw_multicharacter:SetupUI", function(data, slots)
    if not nuiReady then
        print('[WARNING]', 'NUI not ready yet, awaiting...')
        KW.Await(function()
            return nuiReady == true
        end, 'NUI Failed to load after 10000ms', 10000)
    end
    Multicharacter:SetupUI(data, slots)
end)

RegisterNetEvent('kw:playerLoaded', function(playerData, isNew, skin)
    Multicharacter:PlayerLoaded(playerData, isNew, skin)
end)

KW.SecureNetEvent('kw:onPlayerLogout', function()
    DoScreenFadeOut(500)
    Wait(5000)

    Multicharacter.spawned = false

    Multicharacter:SetupCharacters()
    TriggerEvent("kw_skin:resetFirstSpawn")
end)

-- Relog

if Config.Relog then
    RegisterCommand("relog", function()
        if Multicharacter.canRelog then
            Multicharacter.canRelog = false
            TriggerServerEvent("kw_multicharacter:relog")

            KW.SetTimeout(10000, function()
                Multicharacter.canRelog = true
            end)
        end
    end, false)
end

RegisterNuiCallback('nuiReady', function(_, cb)
    nuiReady = true
    cb(1)
end)