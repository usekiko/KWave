--[[
    Standalone Revive System
    Works like kw_ambulancejob revive
    Uses same database queries: UPDATE users SET is_dead = ? WHERE identifier = ?
]]

local KW = exports['kw_core']:getSharedObject()
local deadPlayers = {}

-- Helper function to set player state
local function setDeadState(src, bool)
    if not src or bool == nil then return end
    Player(src).state:set('isDead', bool, true)
end

-- Event when player dies (same as kw_ambulancejob)
RegisterNetEvent('kw:onPlayerDeath')
AddEventHandler('kw:onPlayerDeath', function(data)
    local source = source
    deadPlayers[source] = 'dead'
    setDeadState(source, true)
    
    -- Update database (same query as kw_ambulancejob)
    local xPlayer = KW.GetPlayerFromId(source)
    if xPlayer then
        xPlayer.setMeta('isDead', 1)
        -- The core will automatically save this into the JSONB metadata column on player drop
    end
end)

-- Event when player spawns (remove from dead list)
RegisterNetEvent('kw:onPlayerSpawn')
AddEventHandler('kw:onPlayerSpawn', function()
    local source = source
    if deadPlayers[source] then
        deadPlayers[source] = nil
        setDeadState(source, false)
    end
end)

-- Main revive function
RegisterNetEvent('revive_system:revive')
AddEventHandler('revive_system:revive', function(playerId)
    playerId = tonumber(playerId)
    if not playerId then return end
    
    local xTarget = KW.GetPlayerFromId(playerId)
    if not xTarget then
        -- Player offline, notify admin
        local xPlayer = KW.GetPlayerFromId(source)
        if xPlayer then
            TriggerClientEvent('ox_lib:notify', xPlayer.source, { description = '^1Player is offline', type = 'error' })
        end
        return
    end
    
    -- Remove from dead players
    deadPlayers[playerId] = nil
    setDeadState(playerId, false)
    
    -- Update metadata
    xTarget.setMeta('isDead', 0)
    
    -- Trigger client revive
    TriggerClientEvent('revive_system:revive', playerId)
end)

-- /revive command (admin only)
KW.RegisterCommand('revive', 'admin', function(xPlayer, args, showError)
    if args.playerId then
        local targetId = tonumber(args.playerId)
        if targetId then
            -- Revive specific player
            TriggerEvent('revive_system:revive', targetId)
            TriggerClientEvent('ox_lib:notify', xPlayer.source, { description = '^2Revived player ' .. targetId, type = 'success' })
        end
    else
        -- Revive self
        local playerId = xPlayer.source
        TriggerEvent('revive_system:revive', playerId)
        TriggerClientEvent('ox_lib:notify', xPlayer.source, { description = '^2You revived yourself', type = 'success' })
    end
end, true, { 
    help = 'Revive a player (or yourself if no ID provided)', 
    validate = false, 
    arguments = {
        { name = 'playerId', help = 'Player ID (optional)', type = 'number', optional = true }
    }
})

-- /reviveall command (admin only) - Revive all dead players
KW.RegisterCommand('reviveall', 'admin', function(xPlayer, args, showError)
    -- Get all extended players
    local allPlayers = KW.GetExtendedPlayers()
    local revivedCount = 0
    
    for _, player in pairs(allPlayers) do
        local playerId = player.source
        -- Check if player was dead (optional check, or just revive everyone)
        if deadPlayers[playerId] then
            deadPlayers[playerId] = nil
            setDeadState(playerId, false)
            
            -- Update database
            player.setMeta('isDead', 0)
            
            -- Trigger client revive
            TriggerClientEvent('revive_system:revive', playerId)
            revivedCount = revivedCount + 1
        end
    end
    
    -- Also revive any player who requests it (safety net)
    TriggerClientEvent('revive_system:revive', -1)
    
    TriggerClientEvent('ox_lib:notify', xPlayer.source, { description = '^2Revived ' .. revivedCount .. ' dead players', type = 'success' })
end, false, { help = 'Revive all dead players' })

-- Get death status callback (same as kw_ambulancejob)
lib.callback.register('revive_system:getDeathStatus', function(source)
    local xPlayer = KW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return PostgreSQL.scalar.await('SELECT is_dead FROM users WHERE identifier = ?', { xPlayer.identifier })
end)

-- Set death status manually
RegisterNetEvent('revive_system:setDeathStatus')
AddEventHandler('revive_system:setDeathStatus', function(isDead)
    local xPlayer = KW.GetPlayerFromId(source)
    if type(isDead) == 'boolean' and xPlayer then
        xPlayer.setMeta('isDead', isDead and 1 or 0)
        setDeadState(source, isDead)
    end
end)

-- Player dropped - clean up
AddEventHandler('kw:playerDropped', function(playerId, reason)
    if deadPlayers[playerId] then
        deadPlayers[playerId] = nil
        setDeadState(playerId, false)
    end
end)

-- txAdmin heal support
AddEventHandler('txAdmin:events:healedPlayer', function(eventData)
    if GetInvokingResource() ~= "monitor" or type(eventData) ~= "table" or type(eventData.id) ~= "number" then
        return
    end
    
    local playerId = eventData.id
    if deadPlayers[playerId] then
        deadPlayers[playerId] = nil
        setDeadState(playerId, false)
        
        local xPlayer = KW.GetPlayerFromId(playerId)
        if xPlayer then
            xPlayer.setMeta('isDead', 0)
        end
        
        TriggerClientEvent('revive_system:revive', playerId)
    end
end)

print('[^2Revive System^7] Loaded successfully')
