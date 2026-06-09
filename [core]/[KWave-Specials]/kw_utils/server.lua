-- === DTF Core - Server Side ===
-- Basic server notifications and utilities

-- === PLAYER CONNECTION/DISCONNECTION (optional, disabled by default) ===
-- These are commented out since kw_chat handles join/leave messages
-- Uncomment if you want notifications in kw_notify style instead

--[[
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    -- Connection notification (optional)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local playerName = GetPlayerName(src)
    if playerName then
        -- Notify all players someone left
        TriggerClientEvent('kw_notify:client:Notify', -1, {
            type = 'info',
            title = 'Player Left',
            description = playerName .. ' disconnected',
            duration = 3000
        })
    end
end)
--]]

-- === ADMIN ALERTS ===
-- Notify admins when certain events happen

RegisterNetEvent('kw_core:adminAlert')
AddEventHandler('kw_core:adminAlert', function(message)
    local src = source
    if not src or src <= 0 then return end
    
    -- Get all online admins
    local xPlayers = KW.GetExtendedPlayers()
    for _, xPlayer in pairs(xPlayers) do
        if xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin' or xPlayer.getGroup() == 'mod' then
            TriggerClientEvent('kw_notify:client:Notify', xPlayer.source, {
                type = 'warning',
                title = 'Admin Alert',
                description = message,
                duration = 5000
            })
        end
    end
end)

-- === SERVER ANNOUNCEMENTS ===
RegisterCommand('svannounce', function(source, args, rawCommand)
    local src = source
    
    -- Check if console or admin
    if src ~= 0 then
        local xPlayer = KW.GetPlayerFromId(src)
        if not xPlayer or (xPlayer.getGroup() ~= 'admin' and xPlayer.getGroup() ~= 'superadmin') then
            return
        end
    end
    
    local message = table.concat(args, ' ')
    if message:len() > 0 then
        TriggerClientEvent('kw_notify:client:Notify', -1, {
            type = 'info',
            title = 'Server announcement!',
            description = message,
            duration = 8000,
            sound = 'announcement'
        })
    end
end, true)

print('[^3DTF Core^7] Server loaded')
