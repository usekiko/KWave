-- DTF Notify - Client-side notification system
-- Modern black & white notifications, middle-right position

-- Main export function
Config = Config or {}
Config.Position = 'top-right' -- Options: top-right, top-left, top-middle, bottom-right, bottom-left, bottom-middle, middle-right, middle-left

function Notify(data)
    local notificationData = {
        type = data.type or 'info',
        title = data.title or '',
        description = data.description or data.message or '',
        duration = data.duration or 5000,
        icon = data.icon,
        silent = data.silent or false,
        sound = data.sound
    }
    
    SendNUIMessage({
        action = 'notify',
        data = notificationData,
        position = Config.Position
    })
end

-- Simple text-only notification (for compatibility)
function ShowNotification(message, notifyType)
    notifyType = notifyType or 'info'
    
    -- Parse GTA color codes for title detection
    local title = notifyType:gsub("^%l", string.upper) -- Capitalize first letter
    
    -- If message starts with color code, extract it for the title
    if message:match("^%^[0-9]") then
        local colorCode = message:sub(2, 2)
        if colorCode == '1' or colorCode == '8' then
            notifyType = 'error'
            title = 'Error'
        elseif colorCode == '2' then
            notifyType = 'success'
            title = 'Success'
        elseif colorCode == '3' then
            notifyType = 'warning'
            title = 'Warning'
        end
    end
    
    Notify({
        type = notifyType,
        title = title,
        description = message,
        duration = 4000
    })
end

-- Exports
exports('Notify', Notify)
exports('ShowNotification', ShowNotification)

-- Event handler for server notifications
RegisterNetEvent('kw_notify:client:Notify')
AddEventHandler('kw_notify:client:Notify', function(data)
    Notify(data)
end)

-- Command for testing
RegisterCommand('testnotify', function(source, args, rawCommand)
    local type = args[1] or 'info'
    
    if type == 'success' then
        Notify({
            type = 'success',
            title = 'Success',
            description = 'You completed the action successfully!',
            duration = 5000
        })
    elseif type == 'error' then
        Notify({
            type = 'error',
            title = 'Error',
            description = 'Something went wrong!',
            duration = 5000
        })
    elseif type == 'warning' then
        Notify({
            type = 'warning',
            title = 'Warning',
            description = 'Please be careful!',
            duration = 5000
        })
    else
        Notify({
            type = 'info',
            title = 'Information',
            description = 'You quenched your thirst with cola',
            duration = 5000
        })
    end
end, false)

print('[^7DTF Notify^7] Loaded. Use exports[\'kw_notify\']:Notify() or Event kw_notify:client:Notify')
