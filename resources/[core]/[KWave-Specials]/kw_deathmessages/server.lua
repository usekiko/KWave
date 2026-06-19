-- DTF Death Messages - Server-side kill feed manager
-- Handles multi-kill tracking and broadcasts death messages via kw_notify
-- Includes NPC kill support for localhost testing

-- Track player kill streaks
local playerKillStreaks = {}
local killStreakTimeouts = {}

-- Format distance
local function FormatDistance(distance)
    if distance < 10 then
        return distance .. 'm'
    elseif distance < 100 then
        return distance .. 'm'
    else
        return distance .. 'm'
    end
end

-- Get multi-kill text
local function GetMultiKillText(streak)
    local multiKillMessages = {
        [2] = { text = 'DOUBLE KILL!', color = '^3' },
        [3] = { text = 'TRIPLE KILL!', color = '^4' },
        [4] = { text = 'QUADRA KILL!', color = '^6' },
        [5] = { text = 'PENTA KILL!', color = '^1' },
        [6] = { text = 'RAMPAGE!', color = '^5' },
        [7] = { text = 'UNSTOPPABLE!', color = '^2' },
        [8] = { text = 'GODLIKE!', color = '^8' },
    }
    
    if streak >= 8 then
        return multiKillMessages[8]
    end
    return multiKillMessages[streak] or nil
end

-- Reset player kill streak
local function ResetKillStreak(playerId)
    playerKillStreaks[playerId] = 0
    if killStreakTimeouts[playerId] then
        killStreakTimeouts[playerId] = nil
    end
end

-- Update player kill streak
local function UpdateKillStreak(playerId)
    if not playerKillStreaks[playerId] then
        playerKillStreaks[playerId] = 0
    end
    
    playerKillStreaks[playerId] = playerKillStreaks[playerId] + 1
    
    -- Reset streak after time window
    killStreakTimeouts[playerId] = os.time() + (Config.MultiKillWindow / 1000)
    
    CreateThread(function()
        Wait(Config.MultiKillWindow)
        if killStreakTimeouts[playerId] and os.time() >= killStreakTimeouts[playerId] then
            playerKillStreaks[playerId] = 0
            killStreakTimeouts[playerId] = nil
        end
    end)
    
    return playerKillStreaks[playerId]
end

-- Handle player killed event
RegisterNetEvent('kw_deathmessages:playerKilled')
AddEventHandler('kw_deathmessages:playerKilled', function(data)
    local src = source
    local killerId = data.killer
    
    -- Validate killer exists
    if not killerId then return end
    
    local killerName = GetPlayerName(killerId) or 'Unknown'
    local victimName = GetPlayerName(src) or 'Unknown'
    local weaponName = data.weapon and data.weapon.name or 'Unknown'
    local headshot = data.headshot
    local distance = data.distance or 0
    
    -- Update killer streak
    local streak = UpdateKillStreak(killerId)
    local multiKillData = GetMultiKillText(streak)
    
    -- Build notification description
    local description = killerName .. ' killed ' .. victimName .. ' with ' .. weaponName
    
    -- Add headshot indicator
    if headshot then
        description = description .. ' [HEADSHOT]'
    end
    
    -- Add distance
    if distance > 0 then
        description = description .. ' (' .. FormatDistance(distance) .. ')'
    end
    
    -- Determine title and type based on multi-kill
    local title = 'Kill'
    local notifyType = 'info'
    local duration = Config.DefaultDuration
    
    if multiKillData then
        title = multiKillData.text
        notifyType = 'success'
        duration = Config.MultiKillDuration
    end
    
    -- Broadcast to all clients via kw_notify
    TriggerClientEvent('ox_lib:notify', -1, {
        type = notifyType,
        title = title,
        description = description,
        duration = duration,
        icon = 'skull'
    })
    
    -- Console log
    print('[^7DTF Death Messages^7] ' .. killerName .. ' killed ' .. victimName .. 
          (headshot and ' [HEADSHOT]' or '') .. 
          ' (' .. FormatDistance(distance) .. ')' ..
          (multiKillData and ' - ' .. multiKillData.text or ''))
end)

-- Handle NPC killed event (for localhost testing)
RegisterNetEvent('kw_deathmessages:npckilled')
AddEventHandler('kw_deathmessages:npckilled', function(data)
    local src = source
    
    if not Config.EnableNPCDeaths then return end
    
    local killerName = GetPlayerName(src) or 'Unknown'
    local npcName = data.npcName or 'NPC'
    local weaponName = data.weapon and data.weapon.name or 'Unknown'
    local headshot = data.headshot
    local distance = data.distance or 0
    
    -- Update killer streak (NPC kills count towards streak too)
    local streak = UpdateKillStreak(src)
    local multiKillData = GetMultiKillText(streak)
    
    -- Build notification description
    local description = killerName .. ' killed ' .. npcName .. ' [NPC] with ' .. weaponName
    
    -- Add headshot indicator
    if headshot then
        description = description .. ' [HEADSHOT]'
    end
    
    -- Add distance
    if distance > 0 then
        description = description .. ' (' .. FormatDistance(distance) .. ')'
    end
    
    -- Determine title and type based on multi-kill
    local title = 'NPC Kill'
    local notifyType = 'info'
    local duration = Config.DefaultDuration
    
    if multiKillData then
        title = multiKillData.text
        notifyType = 'success'
        duration = Config.MultiKillDuration
    end
    
    -- Broadcast to all clients via kw_notify
    TriggerClientEvent('ox_lib:notify', -1, {
        type = notifyType,
        title = title,
        description = description,
        duration = duration,
        icon = 'skull'
    })
    
    if Config.Debug then
        print('[^7DTF Death Messages^7] ' .. killerName .. ' killed NPC ' .. npcName .. 
              (headshot and ' [HEADSHOT]' or '') .. 
              ' (' .. FormatDistance(distance) .. ')' ..
              (multiKillData and ' - ' .. multiKillData.text or ''))
    end
end)

-- Handle player died (suicide/environmental)
RegisterNetEvent('kw_deathmessages:playerDied')
AddEventHandler('kw_deathmessages:playerDied', function(data)
    local src = source
    local victimName = GetPlayerName(src) or 'Unknown'
    
    -- Reset victim's kill streak
    ResetKillStreak(src)
    
    -- Broadcast to all clients via kw_notify
    TriggerClientEvent('ox_lib:notify', -1, {
        type = 'error',
        title = 'Death',
        description = victimName .. ' died',
        duration = Config.DeathDuration,
        icon = 'cross'
    })
    
    print('[^7DTF Death Messages^7] ' .. victimName .. ' died')
end)

-- Reset streak on player disconnect
AddEventHandler('playerDropped', function(reason)
    local src = source
    ResetKillStreak(src)
end)

-- Admin command to reset all streaks (for testing)
RegisterCommand('resetstreaks', function(source, args, rawCommand)
    if source == 0 or IsPlayerAceAllowed(source, 'command.resetstreaks') then
        playerKillStreaks = {}
        killStreakTimeouts = {}
        print('[^7DTF Death Messages^7] All kill streaks reset')
        if source ~= 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'success',
                title = 'Streaks Reset',
                description = 'All kill streaks have been reset',
                duration = 3000
            })
        end
    end
end, true)

-- Toggle NPC kills command (for testing)
RegisterCommand('togglenpckills', function(source, args, rawCommand)
    if source == 0 or IsPlayerAceAllowed(source, 'command.togglenpckills') then
        Config.EnableNPCDeaths = not Config.EnableNPCDeaths
        local status = Config.EnableNPCDeaths and 'ENABLED' or 'DISABLED'
        print('[^7DTF Death Messages^7] NPC kills ' .. status)
        if source ~= 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'info',
                title = 'NPC Kills ' .. status,
                description = 'NPC kill tracking is now ' .. status:lower(),
                duration = 3000
            })
        end
        -- Broadcast to all clients to update their tracking
        TriggerClientEvent('kw_deathmessages:updateNPCSetting', -1, Config.EnableNPCDeaths)
    end
end, true)

print('[^7DTF Death Messages^7] Server loaded - using kw_notify')
