-- === DTF Admin - Server ===
-- Clean server-side admin handling
local KW = exports['kw_core']:getSharedObject()

-- === UTILS ===
local function IsAdmin(src)
    local xPlayer = KW.GetPlayerFromId(src)
    if not xPlayer then return false end
    local group = xPlayer.getGroup()
    return group == 'admin' or group == 'superadmin' or group == 'mod'
end

local function GetAdminName(src)
    local xPlayer = KW.GetPlayerFromId(src)
    if xPlayer then
        return xPlayer.getName() .. ' [' .. src .. ']'
    end
    return 'Unknown [' .. src .. ']'
end

local function LogAction(action, admin, target, details)
    print(string.format('[^1DTF Admin^7] %s | Admin: %s | Target: %s | %s', 
        action, admin, target or 'N/A', details or ''))
end

-- === SPECTATE ===
RegisterNetEvent('kw_admin:requestSpectate')
AddEventHandler('kw_admin:requestSpectate', function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    
    TriggerClientEvent('kw_admin:startSpectate', src, targetId)
end)

RegisterNetEvent('kw_admin:stopSpectate')
AddEventHandler('kw_admin:stopSpectate', function()
    local src = source
    TriggerClientEvent('kw_admin:stopSpectate', src)
end)

-- === TELEPORT ===
lib.callback.register('kw_admin:getPlayerCoords', function(source, targetId)
    if not IsAdmin(source) then return nil end
    
    local targetPed = GetPlayerPed(targetId)
    if targetPed and targetPed ~= 0 then
        local coords = GetEntityCoords(targetPed)
        return { x = coords.x, y = coords.y, z = coords.z }
    else
        return nil
    end
end)

RegisterNetEvent('kw_admin:bringPlayer')
AddEventHandler('kw_admin:bringPlayer', function(targetId, coords)
    local src = source
    if not IsAdmin(src) then return end
    
    local xTarget = KW.GetPlayerFromId(targetId)
    if xTarget then
        TriggerClientEvent('kw_admin:teleportToCoords', targetId, coords)
        
        local adminName = GetAdminName(src)
        LogAction('BRING', adminName, xTarget.getName() .. ' [' .. targetId .. ']')
    end
end)

-- === FREEZE ===
RegisterNetEvent('kw_admin:freezePlayer')
AddEventHandler('kw_admin:freezePlayer', function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    
    local xTarget = KW.GetPlayerFromId(targetId)
    if not xTarget then return end
    
    -- Toggle freeze state
    local state = not (xTarget.get('freeze') or false)
    xTarget.set('freeze', state)
    
    TriggerClientEvent('kw_admin:setFreeze', targetId, state)
    
    local adminName = GetAdminName(src)
    LogAction(state and 'FREEZE' or 'UNFREEZE', adminName, xTarget.getName() .. ' [' .. targetId .. ']')
end)

-- === KICK ===
RegisterNetEvent('kw_admin:kickPlayer')
AddEventHandler('kw_admin:kickPlayer', function(targetId, reason)
    local src = source
    if not IsAdmin(src) then return end
    
    local xTarget = KW.GetPlayerFromId(targetId)
    if not xTarget then return end
    
    reason = reason or 'Kicked by admin'
    
    local adminName = GetAdminName(src)
    LogAction('KICK', adminName, xTarget.getName() .. ' [' .. targetId .. ']', 'Reason: ' .. reason)
    
    DropPlayer(targetId, 'Kicked: ' .. reason .. ' | By: ' .. adminName)
end)

-- === BAN ===
RegisterNetEvent('kw_admin:banPlayer')
AddEventHandler('kw_admin:banPlayer', function(targetId, reason, duration)
    local src = source
    if not IsAdmin(src) then return end
    
    local xTarget = KW.GetPlayerFromId(targetId)
    if not xTarget then return end
    
    reason = reason or 'Banned by admin'
    duration = duration or 0
    
    local adminName = GetAdminName(src)
    local targetIdentifier = xTarget.getIdentifier()
    local targetName = xTarget.getName()
    
    -- Simple ban using KW datastore or just log it
    -- For now, just kick with ban message (implement actual ban in database as needed)
    local banMessage = string.format('Banned: %s | By: %s', reason, adminName)
    if duration > 0 then
        banMessage = banMessage .. string.format(' | Duration: %d hours', duration)
    else
        banMessage = banMessage .. ' | Permanent'
    end
    
    LogAction('BAN', adminName, targetName .. ' [' .. targetId .. ']', banMessage)
    DropPlayer(targetId, banMessage)
end)

-- === GIVE ITEMS ===
RegisterNetEvent('kw_admin:giveItem')
AddEventHandler('kw_admin:giveItem', function(targetId, item, count)
    local src = source
    if not IsAdmin(src) then return end
    
    local xTarget = KW.GetPlayerFromId(targetId)
    if not xTarget then return end
    
    count = count or 1
    
    if xTarget.canCarryItem(item, count) then
        xTarget.addInventoryItem(item, count)
        
        local adminName = GetAdminName(src)
        LogAction('GIVE ITEM', adminName, xTarget.getName() .. ' [' .. targetId .. ']', 
            string.format('%s x%d', item, count))
        
        TriggerClientEvent('ox_lib:notify', src, { description = string.format('^2Gave %s x%d', type = item, count }), 'success')
    else
        TriggerClientEvent('ox_lib:notify', src, { description = '^1Player can\'t carry that', type = 'error' })
    end
end)

RegisterNetEvent('kw_admin:giveWeapon')
AddEventHandler('kw_admin:giveWeapon', function(targetId, weapon)
    local src = source
    if not IsAdmin(src) then return end
    
    local xTarget = KW.GetPlayerFromId(targetId)
    if not xTarget then return end
    
    -- Add weapon_ prefix if missing
    if not string.find(weapon, 'weapon_') then
        weapon = 'weapon_' .. weapon
    end
    
    xTarget.addWeapon(weapon, 250)
    
    local adminName = GetAdminName(src)
    LogAction('GIVE WEAPON', adminName, xTarget.getName() .. ' [' .. targetId .. ']', weapon)
    
    TriggerClientEvent('ox_lib:notify', src, { description = '^2Gave ' .. weapon, type = 'success' })
end)

RegisterNetEvent('kw_admin:giveMoney')
AddEventHandler('kw_admin:giveMoney', function(targetId, amount)
    local src = source
    if not IsAdmin(src) then return end
    
    local xTarget = KW.GetPlayerFromId(targetId)
    if not xTarget then return end
    
    amount = tonumber(amount) or 0
    if amount <= 0 then return end
    
    xTarget.addMoney(amount)
    
    local adminName = GetAdminName(src)
    LogAction('GIVE MONEY', adminName, xTarget.getName() .. ' [' .. targetId .. ']', '$' .. amount)
    
    TriggerClientEvent('ox_lib:notify', src, { description = string.format('^2Gave $%d', type = amount }), 'success')
end)

-- === SLAY ===
RegisterNetEvent('kw_admin:slayPlayer')
AddEventHandler('kw_admin:slayPlayer', function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    
    local xTarget = KW.GetPlayerFromId(targetId)
    if not xTarget then return end
    
    TriggerClientEvent('kw_admin:getSlain', targetId)
    
    local adminName = GetAdminName(src)
    LogAction('SLAY', adminName, xTarget.getName() .. ' [' .. targetId .. ']')
end)

-- === PLAYER LIST CALLBACK ===
-- Register the callback for getting player list
lib.callback.register('kw_admin:getPlayers', function(source)
    local src = source
    if not IsAdmin(src) then return {} end
    
    local players = {}
    local xPlayers = KW.GetExtendedPlayers()
    
    for _, xPlayer in pairs(xPlayers) do
        table.insert(players, {
            id = xPlayer.source,
            name = xPlayer.getName()
        })
    end
    
    -- Sort by ID
    table.sort(players, function(a, b) return a.id < b.id end)
    
    return players
end)



print('[^1DTF Admin^7] Server loaded')
