-- DTF Kits - Client-side command handler
-- Handles kit claiming with notifications

-- Main kit command
RegisterCommand('kit', function(source, args, rawCommand)
    local kitName = args[1]
    
    if not kitName then
        lib.notify({ description = 'Usage: /kit [kitname] | Available: pvp', type = 'warning' })
        return
    end
    
    kitName = string.lower(kitName)
    
    -- Only 'pvp' kit available for now
    if kitName ~= 'pvp' then
        lib.notify({ description = 'Available kits: pvp', type = 'error' })
        return
    end
    
    -- Send claim request to server
    TriggerServerEvent('kw_kits:claimKit', kitName)
end, false)

-- Handle server response
RegisterNetEvent('kw_kits:claimResponse')
AddEventHandler('kw_kits:claimResponse', function(data)
    local notifyType = data.notifyType or 'info'
    lib.notify({ description = data.message, type = notifyType })
end)

print('[^6DTF Kits^7] Client loaded - Use /kit pvp to claim your daily kit')
