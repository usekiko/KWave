-- DTF Kits - Server-side daily kit system
-- Handles database operations and item distribution

local kitCooldown = 86400 -- 24 hours in seconds

-- Initialize database table on resource start
CreateThread(function()
    Wait(2000)
    
    PostgreSQL.query([[CREATE TABLE IF NOT EXISTS kw_kits (
        id SERIAL PRIMARY KEY,
        identifier varchar(60) NOT NULL,
        kit_name varchar(50) NOT NULL,
        last_claimed timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT identifier_kit UNIQUE (identifier, kit_name)
    );]], {}, function(result)
        print('[^6DTF Kits^7] Database table initialized')
    end)
end)

-- Get player identifier
local function GetPlayerIdentifier(src)
    local xPlayer = KW.GetPlayerFromId(src)
    if xPlayer then
        return xPlayer.identifier
    end
    
    -- Fallback to license identifier
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.find(id, 'license:') then
            return id
        end
    end
    
    return nil
end

-- Get KW object
KW = exports['kw_core']:getSharedObject()

-- Claim kit handler
RegisterNetEvent('kw_kits:claimKit')
AddEventHandler('kw_kits:claimKit', function(kitName)
    local src = source
    local identifier = GetPlayerIdentifier(src)
    
    if not identifier then
        TriggerClientEvent('kw_notify:client:Notify', src, {
            type = 'error',
            title = 'Error',
            description = 'Unable to identify player',
            duration = 5000
        })
        return
    end
    
    -- Only 'pvp' kit available for now
    if kitName ~= 'pvp' then
        TriggerClientEvent('kw_notify:client:Notify', src, {
            type = 'error',
            title = 'Error',
            description = 'Invalid kit name',
            duration = 5000
        })
        return
    end
    
    -- Check when kit was last claimed
    PostgreSQL.query('SELECT last_claimed FROM kw_kits WHERE identifier = ? AND kit_name = ?', {
        identifier, kitName
    }, function(result)
        if result and #result > 0 then
            local lastClaimed = result[1].last_claimed
            local lastTime = os.time(lastClaimed)
            local currentTime = os.time()
            local timeDiff = currentTime - lastTime
            
            if timeDiff < kitCooldown then
                -- Still on cooldown
                local remaining = kitCooldown - timeDiff
                local hours = math.floor(remaining / 3600)
                local minutes = math.floor((remaining % 3600) / 60)
                
                local timeString = ''
                if hours > 0 then
                    timeString = hours .. 'h ' .. minutes .. 'm'
                else
                    timeString = minutes .. ' minutes'
                end
                
                TriggerClientEvent('kw_notify:client:Notify', src, {
                    type = 'warning',
                    title = 'Kit Cooldown',
                    description = 'Wait ' .. timeString .. ' to claim again',
                    duration = 5000
                })
                return
            end
        end
        
        -- Give items to player
        local canGivePistol = exports.ox_inventory:CanCarryItem(src, 'weapon_pistol', 1)
        local canGiveAmmo = exports.ox_inventory:CanCarryItem(src, 'ammo-9', 100)
        
        if not canGivePistol or not canGiveAmmo then
            TriggerClientEvent('kw_notify:client:Notify', src, {
                type = 'error',
                title = 'Inventory Full',
                description = 'You do not have enough space in your inventory!',
                duration = 5000
            })
            return
        end
        
        -- Add items
        local pistolAdded = exports.ox_inventory:AddItem(src, 'weapon_pistol', 1)
        local ammoAdded = exports.ox_inventory:AddItem(src, 'ammo-9', 100)
        
        if pistolAdded and ammoAdded then
            -- Update database
            PostgreSQL.query('INSERT INTO kw_kits (identifier, kit_name, last_claimed) VALUES (?, ?, CURRENT_TIMESTAMP) ON CONFLICT (identifier, kit_name) DO UPDATE SET last_claimed = CURRENT_TIMESTAMP', {
                identifier, kitName
            }, function()
                TriggerClientEvent('kw_notify:client:Notify', src, {
                    type = 'success',
                    title = 'Claimed daily kit',
                    description = "You've claimed your daily kit, enjoy!",
                    duration = 5000
                })
                print('[^6DTF Kits^7] Player ' .. GetPlayerName(src) .. ' claimed PvP kit')
            end)
        else
            TriggerClientEvent('kw_notify:client:Notify', src, {
                type = 'error',
                title = 'Error',
                description = 'Failed to add items to inventory!',
                duration = 5000
            })
        end
    end)
end)

-- Admin command to reset someone's kit cooldown
RegisterCommand('resetkit', function(source, args, rawCommand)
    local src = source
    
    -- Check if player is admin (console or has permission)
    if src ~= 0 then
        local xPlayer = KW.GetPlayerFromId(src)
        if not xPlayer or (xPlayer.getGroup() ~= 'admin' and xPlayer.getGroup() ~= 'superadmin') then
            TriggerClientEvent('kw_notify:client:Notify', src, {
                type = 'error',
                title = 'No Permission',
                description = 'You do not have permission to use this command!',
                duration = 5000
            })
            return
        end
    end
    
    local targetId = tonumber(args[1])
    local kitName = args[2] or 'pvp'
    
    if not targetId then
        print('[^6DTF Kits^7] Usage: /resetkit [playerId] [kitName]')
        if src ~= 0 then
            TriggerClientEvent('kw_notify:client:Notify', src, {
                type = 'warning',
                title = 'Invalid Usage',
                description = 'Usage: /resetkit [playerId] [kitName]',
                duration = 5000
            })
        end
        return
    end
    
    local targetPlayer = KW.GetPlayerFromId(targetId)
    if not targetPlayer then
        print('[^6DTF Kits^7] Player not found: ' .. targetId)
        if src ~= 0 then
            TriggerClientEvent('kw_notify:client:Notify', src, {
                type = 'error',
                title = 'Player Not Found',
                description = 'Player with ID ' .. targetId .. ' not found!',
                duration = 5000
            })
        end
        return
    end
    
    -- Delete entry from database
    PostgreSQL.query('DELETE FROM kw_kits WHERE identifier = ? AND kit_name = ?', {
        targetPlayer.identifier, kitName
    }, function()
        print('[^6DTF Kits^7] Reset ' .. kitName .. ' kit for ' .. targetPlayer.name)
        if src ~= 0 then
            TriggerClientEvent('kw_notify:client:Notify', src, {
                type = 'success',
                title = 'Kit Reset',
                description = 'Reset ' .. kitName .. ' kit for ' .. targetPlayer.name,
                duration = 5000
            })
        end
        TriggerClientEvent('kw_notify:client:Notify', targetId, {
            type = 'success',
            title = 'Kit Available',
            description = 'Your ' .. kitName .. ' kit cooldown has been reset!',
            duration = 5000
        })
    end)
end, true)

print('[^6DTF Kits^7] Server loaded')
