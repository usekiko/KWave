-- === DTF Admin - Enhanced Black & White Admin Menu ===
-- Complete rewrite with searchable items, animations, and toggle support

-- Get KW object (modern approach)
KW = exports['kw_core']:getSharedObject()

local adminOpen = false
local noclipEnabled = false
local invisibleEnabled = false
local godmodeEnabled = false
local vehicleGodmode = false
local spectating = false
local lastCoords = nil
local lastVehicle = nil

-- Noclip vars
local noclipSpeed = 1.0
local noclipCam = nil

-- === ADMIN CHECK ===
local function IsAdmin()
    if not KW or not KW.PlayerData or not KW.PlayerData.group then return false end
    local group = KW.PlayerData.group
    return group == 'admin' or group == 'superadmin' or group == 'mod'
end

-- === MENU FUNCTIONS ===
function ToggleAdminMenu()
    if adminOpen then
        CloseAdminMenu()
    else
        OpenAdminMenu()
    end
end

function OpenAdminMenu()
    if not KW or not KW.PlayerData then
        exports['kw_notify']:ShowNotification('^1Loading... please wait', 'warning')
        return
    end
    
    if not IsAdmin() then
        exports['kw_notify']:ShowNotification('^1You don\'t have permission', 'error')
        return
    end
    
    adminOpen = true
    SetNuiFocus(true, true)
    
    -- Send admin group to UI
    SendNUIMessage({ 
        type = 'openMenu',
        group = KW.PlayerData.group
    })
    
    -- Send current toggle states
    SendNUIMessage({ type = 'toggleState', action = 'noclip', enabled = noclipEnabled })
    SendNUIMessage({ type = 'toggleState', action = 'invisible', enabled = invisibleEnabled })
    SendNUIMessage({ type = 'toggleState', action = 'godmode', enabled = godmodeEnabled })
    SendNUIMessage({ type = 'toggleState', action = 'vehiclegod', enabled = vehicleGodmode })
    SendNUIMessage({ type = 'toggleState', action = 'spectate', enabled = spectating })
    
    RefreshPlayerList()
end

function CloseAdminMenu()
    adminOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeMenu' })
end

-- === PLAYER LIST ===
function RefreshPlayerList()
    if not KW then return end
    local players = lib.callback.await('kw_admin:getPlayers', false)
    if players then
        SendNUIMessage({ type = 'updatePlayers', players = players })
    end
end

-- === SELF ACTIONS ===
function ToggleNoclip()
    noclipEnabled = not noclipEnabled
    local ped = PlayerPedId()
    
    if noclipEnabled then
        SetEntityInvincible(ped, true)
        SetEntityCollision(ped, false, false)
        SetEntityVisible(ped, false, false)
        SetEveryoneIgnorePlayer(PlayerId(), true)
        SetPoliceIgnorePlayer(PlayerId(), true)
        FreezeEntityPosition(ped, false)
        
        -- Create camera for smooth movement
        local coords = GetEntityCoords(ped)
        noclipCam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', coords.x, coords.y, coords.z, 0.0, 0.0, GetEntityHeading(ped), 50.0, false, 0)
        SetCamActive(noclipCam, true)
        RenderScriptCams(true, false, 0, true, true)
        
        Citizen.CreateThread(function()
            while noclipEnabled do
                local ped = PlayerPedId()
                
                -- Disable controls
                DisableControlAction(0, 30, true) -- Movement
                DisableControlAction(0, 31, true)
                DisableControlAction(0, 21, true) -- Sprint
                DisableControlAction(0, 44, true) -- Cover
                DisableControlAction(0, 37, true) -- Weapon select
                
                local camCoords = GetCamCoord(noclipCam)
                local heading = GetCamRot(noclipCam, 2).z
                local rot = GetCamRot(noclipCam, 2)
                
                -- Mouse look
                local mouseX = GetDisabledControlNormal(0, 1) * 5.0
                local mouseY = GetDisabledControlNormal(0, 2) * 5.0
                
                if math.abs(mouseX) > 0.1 or math.abs(mouseY) > 0.1 then
                    rot = vector3(math.max(-89, math.min(89, rot.x - mouseY)), 0.0, rot.z - mouseX)
                    SetCamRot(noclipCam, rot.x, rot.y, rot.z, 2)
                end
                
                -- Movement
                local dx, dy = 0.0, 0.0
                if IsDisabledControlPressed(0, 32) then dy = 1.0 end -- W
                if IsDisabledControlPressed(0, 33) then dy = -1.0 end -- S
                if IsDisabledControlPressed(0, 34) then dx = -1.0 end -- A
                if IsDisabledControlPressed(0, 35) then dx = 1.0 end -- D
                
                -- Up/Down
                local dz = 0.0
                if IsDisabledControlPressed(0, 22) then dz = 1.0 end -- Space
                if IsDisabledControlPressed(0, 36) then dz = -1.0 end -- Ctrl
                
                -- Speed modifier
                local speed = noclipSpeed
                if IsDisabledControlPressed(0, 21) then -- Shift
                    speed = speed * 3.0
                end
                
                -- Normalize movement
                if dx ~= 0 or dy ~= 0 then
                    local len = math.sqrt(dx * dx + dy * dy)
                    dx, dy = dx / len, dy / len
                end
                
                local newX = camCoords.x + (dx * math.cos(math.rad(heading)) - dy * math.sin(math.rad(heading))) * speed
                local newY = camCoords.y + (dx * math.sin(math.rad(heading)) + dy * math.cos(math.rad(heading))) * speed
                local newZ = camCoords.z + dz * speed
                
                SetCamCoord(noclipCam, newX, newY, newZ)
                SetEntityCoordsNoOffset(ped, newX, newY, newZ, false, false, false)
                SetEntityHeading(ped, heading)
                
                Citizen.Wait(0)
            end
            
            -- Cleanup
            RenderScriptCams(false, false, 0, true, true)
            DestroyCam(noclipCam, false)
            noclipCam = nil
        end)
        
        SendToast('success', 'Noclip Enabled', 'Use WASD to move, Space/Ctrl for up/down, Shift to speed up, Mouse to look around')
    else
        SetEntityInvincible(ped, false)
        SetEntityCollision(ped, true, true)
        SetEntityVisible(ped, true, false)
        SetEveryoneIgnorePlayer(PlayerId(), false)
        SetPoliceIgnorePlayer(PlayerId(), false)
        FreezeEntityPosition(ped, false)
        SendToast('info', 'Noclip Disabled', 'Normal movement restored')
    end
    
    return noclipEnabled
end

function ToggleInvisible()
    invisibleEnabled = not invisibleEnabled
    SetEntityVisible(PlayerPedId(), not invisibleEnabled, false)
    SendToast(invisibleEnabled and 'success' or 'info', 
        invisibleEnabled and 'Invisible' or 'Visible', 
        invisibleEnabled and 'You are now invisible' or 'You are now visible')
    return invisibleEnabled
end

function ToggleGodmode()
    godmodeEnabled = not godmodeEnabled
    SetEntityInvincible(PlayerPedId(), godmodeEnabled)
    SendToast(godmodeEnabled and 'success' or 'warning',
        godmodeEnabled and 'Godmode On' or 'Godmode Off',
        godmodeEnabled and 'You are now invincible' or 'You can take damage again')
    return godmodeEnabled
end

function ToggleVehicleGodmode()
    vehicleGodmode = not vehicleGodmode
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle and vehicle ~= 0 then
        SetEntityInvincible(vehicle, vehicleGodmode)
        SetVehicleCanBreak(vehicle, not vehicleGodmode)
        SetVehicleCanDeformWheels(vehicle, not vehicleGodmode)
        SetVehicleCanLeakOil(vehicle, not vehicleGodmode)
        SetVehicleCanLeakPetrol(vehicle, not vehicleGodmode)
        SetVehicleEngineCanDegrade(vehicle, not vehicleGodmode)
        SetVehicleWheelsCanBreak(vehicle, not vehicleGodmode)
        SendToast(vehicleGodmode and 'success' or 'warning',
            vehicleGodmode and 'Vehicle God On' or 'Vehicle God Off',
            vehicleGodmode and 'Vehicle is now invincible' or 'Vehicle can take damage again')
    else
        SendToast('error', 'Not in Vehicle', 'You must be in a vehicle to use this')
        vehicleGodmode = false
    end
    return vehicleGodmode
end

function SelfHeal()
    SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
    SendToast('success', 'Healed', 'Health restored to maximum')
end

function SelfArmor()
    AddArmourToPed(PlayerPedId(), 100)
    SetPedArmour(PlayerPedId(), 100)
    SendToast('success', 'Armored', 'Armor added')
end

function SelfRevive()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    StopScreenEffect('DeathFailOut')
    SendToast('success', 'Revived', 'You have been revived')
end

function RepairVehicle()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle and vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehicleDirtLevel(vehicle, 0.0)
        SendToast('success', 'Repaired', 'Vehicle fully repaired and cleaned')
    else
        SendToast('error', 'Not in Vehicle', 'You must be in a vehicle to repair')
    end
end

function CleanPed()
    local ped = PlayerPedId()
    ClearPedBloodDamage(ped)
    ClearPedEnvDirt(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastWeaponDamage(ped)
    SendToast('success', 'Cleaned', 'Ped cleaned of all damage and dirt')
end

function ClearLoadout()
    RemoveAllPedWeapons(PlayerPedId(), true)
    SendToast('success', 'Cleared', 'All weapons removed')
end

function TPMarker()
    local ped = PlayerPedId()
    local blip = GetFirstBlipInfoId(8) -- Waypoint blip
    
    if DoesBlipExist(blip) then
        local coords = GetBlipInfoIdCoord(blip)
        
        -- Find ground Z
        local found, groundZ = false, 0.0
        for i = 800.0, 0.0, -50.0 do
            local ret, z = GetGroundZFor_3dCoord(coords.x, coords.y, i, false)
            if ret then
                groundZ = z
                found = true
                break
            end
        end
        
        if found then
            SetEntityCoords(ped, coords.x, coords.y, groundZ, false, false, false, false)
            SendToast('success', 'Teleported', 'Teleported to waypoint')
        else
            -- Fallback to sky teleport
            SetEntityCoords(ped, coords.x, coords.y, 800.0, false, false, false, false)
            SendToast('warning', 'Teleported', 'Teleported to waypoint (high altitude)')
        end
    else
        SendToast('error', 'No Waypoint', 'Set a waypoint on the map first')
    end
end

-- === SPECTATE ===
function ToggleSpectate(targetId)
    if spectating then
        -- Stop spectating
        spectating = false
        TriggerServerEvent('kw_admin:stopSpectate')
        return false
    end
    
    if not targetId or targetId == 0 then
        SendToast('warning', 'No Target', 'Select a player to spectate')
        return false
    end
    
    spectating = true
    TriggerServerEvent('kw_admin:requestSpectate', targetId)
    return true
end

RegisterNetEvent('kw_admin:startSpectate')
AddEventHandler('kw_admin:startSpectate', function(targetId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if targetPed and targetPed ~= 0 then
        lastCoords = GetEntityCoords(PlayerPedId())
        NetworkSetInSpectatorMode(true, targetPed)
        SendToast('success', 'Spectating', 'Press Spectate again to stop')
    else
        SendToast('error', 'Not Found', 'Player not found')
        spectating = false
        SendNUIMessage({ type = 'toggleState', action = 'spectate', enabled = false })
    end
end)

RegisterNetEvent('kw_admin:stopSpectate')
AddEventHandler('kw_admin:stopSpectate', function()
    NetworkSetInSpectatorMode(false, nil)
    if lastCoords then
        SetEntityCoords(PlayerPedId(), lastCoords)
        lastCoords = nil
    end
    spectating = false
    SendNUIMessage({ type = 'toggleState', action = 'spectate', enabled = false })
end)

-- === PLAYER ACTIONS ===
function GotoPlayer(targetId)
    if not targetId or targetId == 0 then
        SendToast('warning', 'No Target', 'Select a player first')
        return
    end
    
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
    if targetPed and targetPed ~= 0 then
        local coords = GetEntityCoords(targetPed)
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z + 1.0, false, false, false, false)
        SendToast('success', 'Teleported', 'Teleported to player')
    else
        SendToast('error', 'Not Found', 'Player not found')
    end
end

function BringPlayer(targetId)
    if not targetId or targetId == 0 then
        SendToast('warning', 'No Target', 'Select a player first')
        return
    end
    
    local myCoords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('kw_admin:bringPlayer', targetId, {x = myCoords.x, y = myCoords.y, z = myCoords.z})
end

RegisterNetEvent('kw_admin:teleportToCoords')
AddEventHandler('kw_admin:teleportToCoords', function(coords)
    if coords then
        SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
        SendToast('success', 'Teleported', 'You were teleported by an admin')
    end
end)

function FreezePlayer(targetId)
    if not targetId or targetId == 0 then
        SendToast('warning', 'No Target', 'Select a player first')
        return
    end
    
    TriggerServerEvent('kw_admin:freezePlayer', targetId)
end

RegisterNetEvent('kw_admin:setFreeze')
AddEventHandler('kw_admin:setFreeze', function(freeze)
    FreezeEntityPosition(PlayerPedId(), freeze)
    if freeze then
        SendToast('warning', 'Frozen', 'You have been frozen by an admin')
    else
        SendToast('success', 'Unfrozen', 'You have been unfrozen')
    end
end)

function SlayPlayer(targetId)
    if not targetId or targetId == 0 then
        SendToast('warning', 'No Target', 'Select a player first')
        return
    end
    
    TriggerServerEvent('kw_admin:slayPlayer', targetId)
end

RegisterNetEvent('kw_admin:getSlain')
AddEventHandler('kw_admin:getSlain', function()
    SetEntityHealth(PlayerPedId(), 0)
    SendToast('error', 'Slain', 'You were slain by an admin')
end)

-- === VEHICLE SPAWNING ===
function SpawnVehicle(model)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    
    -- Load model
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        SendToast('error', 'Invalid Model', 'Vehicle model does not exist')
        return
    end
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(10)
    end
    
    -- Delete old vehicle if exists
    if lastVehicle and DoesEntityExist(lastVehicle) then
        DeleteEntity(lastVehicle)
    end
    
    -- Spawn vehicle
    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetPedIntoVehicle(ped, vehicle, -1)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleEngineOn(vehicle, true, true, false)
    
    lastVehicle = vehicle
    SendToast('success', 'Vehicle Spawned', 'Spawned ' .. model)
    
    SetModelAsNoLongerNeeded(hash)
end

-- === NUI CALLBACKS ===
RegisterNUICallback('closeMenu', function(data, cb)
    CloseAdminMenu()
    cb({})
end)

RegisterNUICallback('setFocus', function(data, cb)
    SetNuiFocus(data.hasFocus, data.hasCursor)
    cb({})
end)

RegisterNUICallback('refreshPlayers', function(data, cb)
    RefreshPlayerList()
    cb({})
end)

-- Self actions
RegisterNUICallback('noclip', function(data, cb)
    cb({ enabled = ToggleNoclip() })
end)

RegisterNUICallback('invisible', function(data, cb)
    cb({ enabled = ToggleInvisible() })
end)

RegisterNUICallback('godmode', function(data, cb)
    cb({ enabled = ToggleGodmode() })
end)

RegisterNUICallback('heal', function(data, cb)
    SelfHeal()
    cb({})
end)

RegisterNUICallback('armor', function(data, cb)
    SelfArmor()
    cb({})
end)

RegisterNUICallback('revive', function(data, cb)
    SelfRevive()
    cb({})
end)

RegisterNUICallback('vehiclegod', function(data, cb)
    cb({ enabled = ToggleVehicleGodmode() })
end)

RegisterNUICallback('repair', function(data, cb)
    RepairVehicle()
    cb({})
end)

RegisterNUICallback('clean', function(data, cb)
    CleanPed()
    cb({})
end)

RegisterNUICallback('clearloadout', function(data, cb)
    ClearLoadout()
    cb({})
end)

RegisterNUICallback('tpm', function(data, cb)
    TPMarker()
    cb({})
end)

RegisterNUICallback('spectate', function(data, cb)
    local targetId = tonumber(data.targetId) or 0
    cb({ enabled = ToggleSpectate(targetId) })
end)

-- Player actions
RegisterNUICallback('goto', function(data, cb)
    GotoPlayer(tonumber(data.targetId))
    cb({})
end)

RegisterNUICallback('bring', function(data, cb)
    BringPlayer(tonumber(data.targetId))
    cb({})
end)

RegisterNUICallback('freeze', function(data, cb)
    FreezePlayer(tonumber(data.targetId))
    cb({})
end)

RegisterNUICallback('slay', function(data, cb)
    SlayPlayer(tonumber(data.targetId))
    cb({})
end)

RegisterNUICallback('kick', function(data, cb)
    TriggerServerEvent('kw_admin:kickPlayer', tonumber(data.targetId), data.reason)
    cb({})
end)

RegisterNUICallback('ban', function(data, cb)
    TriggerServerEvent('kw_admin:banPlayer', tonumber(data.targetId), data.reason, data.duration)
    cb({})
end)

-- Give actions
RegisterNUICallback('giveItem', function(data, cb)
    local targetId = tonumber(data.targetId)
    if targetId == -1 then targetId = GetPlayerServerId(PlayerId()) end
    TriggerServerEvent('kw_admin:giveItem', targetId, data.item, data.count)
    cb({})
end)

RegisterNUICallback('giveWeapon', function(data, cb)
    local targetId = tonumber(data.targetId)
    if targetId == -1 then targetId = GetPlayerServerId(PlayerId()) end
    TriggerServerEvent('kw_admin:giveWeapon', targetId, data.item)
    cb({})
end)

RegisterNUICallback('giveMoney', function(data, cb)
    local targetId = tonumber(data.targetId)
    if targetId == -1 then targetId = GetPlayerServerId(PlayerId()) end
    TriggerServerEvent('kw_admin:giveMoney', targetId, data.count)
    cb({})
end)

-- Vehicle
RegisterNUICallback('spawnVehicle', function(data, cb)
    SpawnVehicle(data.model)
    cb({})
end)

-- === TOAST HELPER ===
function SendToast(toastType, title, message)
    SendNUIMessage({
        type = 'showToast',
        toastType = toastType,
        title = title,
        message = message
    })
end

-- === COMMANDS ===
RegisterCommand('admin', function()
    ToggleAdminMenu()
end, false)

RegisterKeyMapping('admin', 'Open Admin Menu', 'keyboard', 'F9')

-- Close on ESC (backup)
Citizen.CreateThread(function()
    while true do
        if adminOpen and IsControlJustReleased(0, 200) then -- ESC
            CloseAdminMenu()
        end
        Citizen.Wait(0)
    end
end)

-- === INIT ===
print('[^1DTF Admin^7] Client loaded - Enhanced version with searchable items')
