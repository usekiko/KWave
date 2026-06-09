if Config.Core == "KW" then
    KW = Config.CoreExport()

    RegisterNetEvent('vms_hud:addStress', function(amount)
        local src = source
        TriggerClientEvent('kw_status:add', src, 'stress', amount)
    end)

    RegisterNetEvent('vms_hud:removeStress', function(amount)
        local src = source
        TriggerClientEvent('kw_status:remove', src, 'stress', amount)
    end)
    
elseif Config.Core == "QB-Core" then
    QBCore = Config.CoreExport()

    RegisterNetEvent('vms_hud:addStress', function(amount)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local newStress
        if not Player.PlayerData.metadata['stress'] then
            Player.PlayerData.metadata['stress'] = 0
        end
        newStress = Player.PlayerData.metadata['stress'] + amount
        if newStress <= 0 then 
            newStress = 0 
        end
        if newStress > 100 then
            newStress = 100
        end
        Player.Functions.SetMetaData('stress', newStress)
        TriggerClientEvent('hud:client:UpdateStress', src, newStress)
    end)

    RegisterNetEvent('vms_hud:removeStress', function(amount)
        local src = source
        local Player = QBCore.Functions.GetPlayer(src)
        local newStress
        if not Player then return end
        if not Player.PlayerData.metadata['stress'] then
            Player.PlayerData.metadata['stress'] = 0
        end
        newStress = Player.PlayerData.metadata['stress'] - amount
        if newStress <= 0 then newStress = 0 end
        if newStress > 100 then
            newStress = 100
        end
        Player.Functions.SetMetaData('stress', newStress)
    end)
end

AddEventHandler("mumble:SetVoiceData", function(key, value)
    if key == 'mode' and value then
        TriggerClientEvent('mumble-voip:setHudMode', source, tonumber(value))
    end
end)