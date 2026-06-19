-- DTF Kits - Client-side command handler
-- Handles kit claiming with notifications

-- Main kit command
RegisterCommand('kit', function(source, args, rawCommand)
    local kitName = args[1]
    
    if not kitName then
        exports['kw_notify']:ShowNotification('Usage: /kit [kitname] | Available: pvp', 'warning')
        return
    end
    
    kitName = string.lower(kitName)
    
    -- Only 'pvp' kit available for now
    if kitName ~= 'pvp' then
        exports['kw_notify']:ShowNotification('Available kits: pvp', 'error')
        return
    end
    
    -- Send claim request to server
    TriggerServerEvent('kw_kits:claimKit', kitName)
end, false)

-- Handle server response
RegisterNetEvent('kw_kits:claimResponse')
AddEventHandler('kw_kits:claimResponse', function(data)
    local notifyType = data.notifyType or 'info'
    exports['kw_notify']:ShowNotification(data.message, notifyType)
end)

print('[^6DTF Kits^7] Client loaded - Use /kit pvp to claim your daily kit')
