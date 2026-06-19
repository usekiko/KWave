-- DTF Chat Server - Enhanced Edition
-- Improved reliability and error handling

-- Register server events
RegisterServerEvent('chat:init')
RegisterServerEvent('chat:addMessage')
RegisterServerEvent('chat:addSuggestion')
RegisterServerEvent('chat:removeSuggestion')
RegisterServerEvent('_chat:messageEntered')
RegisterServerEvent('chat:clear')
RegisterServerEvent('__cfx_internal:commandFallback')
RegisterServerEvent('kw_chat:playerJoined')

-- Handle chat messages from clients
AddEventHandler('_chat:messageEntered', function(author, color, message)
    if not message or not author then return end
    
    local src = source
    if not src or src <= 0 then return end
    
    -- Trigger the chatMessage event for other resources
    TriggerEvent('chatMessage', src, author, message)
    
    -- Broadcast if not canceled
    if not WasEventCanceled() then
        TriggerClientEvent('chat:addMessage', -1, {
            color = { 255, 255, 255 },
            multiline = true,
            args = { author, message }
        })
    end
    
    print(author .. '^7: ' .. message)
end)

-- Handle unknown commands fallback
AddEventHandler('__cfx_internal:commandFallback', function(command)
    local src = source
    if not src or src <= 0 then 
        CancelEvent()
        return 
    end
    
    -- Show invalid command notification using kw_notify
    TriggerClientEvent('kw_notify:client:Notify', src, {
        type = 'error',
        title = 'Invalid Command',
        description = 'Unknown command: /' .. tostring(command),
        duration = 4000
    })
    
    CancelEvent()
end)

-- Player actually spawned/loaded (join messages disabled)
AddEventHandler('kw_chat:playerJoined', function()
    -- Join messages disabled - no notifications
end)

-- Chat init - refresh commands for player
AddEventHandler('chat:init', function()
    local src = source
    if not src or src <= 0 then return end
    refreshCommands(src)
end)

-- Player left
AddEventHandler('playerDropped', function(reason)
    local src = source
    if not src or src <= 0 then return end
    
    local playerName = GetPlayerName(src)
    if not playerName then return end
    
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 0, 255, 0 },
        multiline = true,
        args = { '', '^2* ' .. playerName .. ' left (' .. reason .. ')' }
    })
end)

-- Refresh command suggestions for a player
function refreshCommands(player)
    if not player or player <= 0 then return end
    if not GetRegisteredCommands then return end
    
    local registeredCommands = GetRegisteredCommands()
    local suggestions = {}
    
    for _, command in ipairs(registeredCommands) do
        if IsPlayerAceAllowed(player, ('command.%s'):format(command.name)) then
            table.insert(suggestions, {
                name = command.name,
                help = command.description or ''
            })
        end
    end
    
    TriggerClientEvent('chat:addSuggestions', player, suggestions)
end

-- Admin broadcast command
RegisterCommand('announce', function(source, args, rawCommand)
    local msg = table.concat(args, ' ')
    if msg:len() > 0 then
        TriggerClientEvent('chat:addMessage', -1, {
            color = { 255, 0, 0 },
            multiline = true,
            args = { 'ADMIN', msg }
        })
    end
end, true)

-- Refresh commands when resources start/stop
AddEventHandler('onServerResourceStart', function(resName)
    Wait(500)
    for _, player in ipairs(GetPlayers()) do
        local pid = tonumber(player)
        if pid and pid > 0 then
            refreshCommands(pid)
        end
    end
end)

AddEventHandler('onServerResourceStop', function(resName)
    Wait(500)
    for _, player in ipairs(GetPlayers()) do
        local pid = tonumber(player)
        if pid and pid > 0 then
            refreshCommands(pid)
        end
    end
end)

print('[^6DTF Chat^7] Server loaded - Enhanced Edition')
