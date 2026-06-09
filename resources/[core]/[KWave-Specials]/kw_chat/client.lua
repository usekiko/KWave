-- DTF Chat Client - Enhanced Edition
-- Improved reliability and error handling

local chatInputActive = false
local chatInputActivating = false
local chatLoaded = false
local chatVisible = false

-- Register chat events
RegisterNetEvent('chatMessage')
RegisterNetEvent('chat:addMessage')
RegisterNetEvent('chat:addSuggestion')
RegisterNetEvent('chat:addSuggestions')
RegisterNetEvent('chat:removeSuggestion')
RegisterNetEvent('chat:clear')

-- Handle incoming messages
AddEventHandler('chat:addMessage', function(message)
    SendNUIMessage({
        type = 'ON_MESSAGE',
        message = message
    })
    SendNUIMessage({ type = 'ON_SHOW' })
end)

-- Handle single suggestion add
AddEventHandler('chat:addSuggestion', function(name, help, params)
    SendNUIMessage({
        type = 'ON_SUGGESTION_ADD',
        suggestion = {
            name = name,
            help = help or '',
            params = params or nil
        }
    })
end)

-- Handle multiple suggestions add
AddEventHandler('chat:addSuggestions', function(suggestions)
    for _, suggestion in ipairs(suggestions) do
        SendNUIMessage({
            type = 'ON_SUGGESTION_ADD',
            suggestion = suggestion
        })
    end
end)

-- Handle suggestion remove
AddEventHandler('chat:removeSuggestion', function(name)
    SendNUIMessage({
        type = 'ON_SUGGESTION_REMOVE',
        name = name
    })
end)

-- Handle chat clear
AddEventHandler('chat:clear', function()
    SendNUIMessage({ type = 'ON_CLEAR' })
end)

-- Legacy chatMessage support
AddEventHandler('chatMessage', function(author, color, text)
    local args = { text }
    if author ~= "" then
        table.insert(args, 1, author)
    end
    SendNUIMessage({
        type = 'ON_MESSAGE',
        message = {
            color = color,
            multiline = true,
            args = args
        }
    })
    SendNUIMessage({ type = 'ON_SHOW' })
end)

-- Blocked command prefixes (internal commands)
local blockedPrefixes = {
    'txAdmin-check', 'txAdmin-hide', 'txAdmin-show', 
    'txAdmin-set', 'txAdmin-get', 'txAdmin-toggle', 'txAdmin-',
    '_', '__'
}

local function isBlockedCommand(cmdName)
    for _, prefix in ipairs(blockedPrefixes) do
        if string.sub(cmdName, 1, string.len(prefix)) == prefix then
            return true
        end
    end
    return string.len(cmdName) > 40
end

-- Get all registered commands and send as suggestions
local function refreshCommands()
    if not GetRegisteredCommands then return end
    
    local registeredCommands = GetRegisteredCommands()
    local suggestions = {}
    
    for _, command in ipairs(registeredCommands) do
        local cmdName = command.name
        if not isBlockedCommand(cmdName) and IsAceAllowed(('command.%s'):format(cmdName)) then
            table.insert(suggestions, {
                name = cmdName,
                help = command.description or ''
            })
        end
    end
    
    table.insert(suggestions, { name = 'help', help = 'Show available commands' })
    table.insert(suggestions, { name = 'clear', help = 'Clear chat history' })
    
    TriggerEvent('chat:addSuggestions', suggestions)
end

-- Open chat
local function openChat()
    chatInputActive = true
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'ON_OPEN' })
end

-- Close chat
local function closeChat()
    chatInputActive = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'ON_CLOSE' })
end

-- Handle chat result from NUI
RegisterNUICallback('chatResult', function(data, cb)
    closeChat()
    
    if not data.canceled and data.message then
        local id = PlayerId()
        if data.message:sub(1, 1) == '/' then
            ExecuteCommand(data.message:sub(2))
        else
            TriggerServerEvent('_chat:messageEntered', GetPlayerName(id), { 255, 255, 255 }, data.message)
        end
    end
    
    cb('ok')
end)

-- NUI loaded callback
RegisterNUICallback('loaded', function(data, cb)
    TriggerServerEvent('chat:init')
    refreshCommands()
    chatLoaded = true
    cb('ok')
end)

-- Player spawned - trigger join message
local hasJoined = false
CreateThread(function()
    while true do
        Wait(3000)
        if not hasJoined then
            local playerPed = PlayerPedId()
            if DoesEntityExist(playerPed) then
                hasJoined = true
                TriggerServerEvent('kw_chat:playerJoined')
                break
            end
        end
    end
end)

-- Refresh commands on resource start
AddEventHandler('onClientResourceStart', function(resName)
    Wait(500)
    if chatLoaded then
        refreshCommands()
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    Wait(500)
    if chatLoaded then
        refreshCommands()
    end
end)

-- Main thread - Input handling
CreateThread(function()
    SetTextChatEnabled(false)
    SetNuiFocus(false, false)
    
    while true do
        Wait(0)
        
        -- Open chat with T key
        if not chatInputActive then
            if IsControlJustPressed(0, 245) then -- INPUT_MP_TEXT_CHAT_ALL
                openChat()
            end
        end
    end
end)

print('[^6DTF Chat^7] Client loaded. Press T to open chat.')
