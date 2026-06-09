-- === DTF Core - Basic Notifications & Utilities ===
-- Engine toggle, quick leave, and essential notifications

KW = exports['kw_core']:getSharedObject()

-- Load config
local function LoadConfig()
    -- Config is loaded from shared_scripts in fxmanifest
    return Config or {}
end

local cfg = LoadConfig()

-- === ENGINE BREAKDOWN NOTIFICATIONS ===
if cfg.Notifications and cfg.Notifications.EngineBroken then
    local lastEngineHealth = 1000
    local engineNotified = false

    CreateThread(function()
        while true do
            Wait(1000)
            
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                local engineHealth = GetVehicleEngineHealth(vehicle)
                
                -- Engine broken (completely dead)
                if engineHealth <= 0 and lastEngineHealth > 0 then
                    exports['kw_notify']:ShowNotification('^1Engine broken down!', 'error')
                    engineNotified = true
                -- Engine heavily damaged (smoking, about to break)
                elseif cfg.Notifications.EngineDamaged and engineHealth <= 300 and lastEngineHealth > 300 and not engineNotified then
                    exports['kw_notify']:ShowNotification('^3Engine critically damaged! Find a mechanic!', 'warning')
                    engineNotified = true
                -- Engine reset (vehicle repaired)
                elseif engineHealth > 500 and engineNotified then
                    engineNotified = false
                end
                
                lastEngineHealth = engineHealth
            else
                -- Reset when not in vehicle
                lastEngineHealth = 1000
                engineNotified = false
            end
        end
    end)
end

-- === LOW HEALTH NOTIFICATION ===
if cfg.Notifications and cfg.Notifications.LowHealth then
    local lowHealthNotified = false

    CreateThread(function()
        while true do
            Wait(500)
            
            local ped = PlayerPedId()
            local health = GetEntityHealth(ped)
            local maxHealth = GetEntityMaxHealth(ped)
            local healthPercent = (health / maxHealth) * 100
            
            -- Critical health (below 25%)
            if healthPercent <= 25 and health > 0 and not lowHealthNotified then
                exports['kw_notify']:ShowNotification('^1Critical health! Find cover!', 'error')
                lowHealthNotified = true
            -- Reset notification when health recovers
            elseif healthPercent > 50 and lowHealthNotified then
                lowHealthNotified = false
            end
        end
    end)
end

-- === DEATH NOTIFICATION ===
if cfg.Notifications and cfg.Notifications.Death then
    local wasDead = false
    local playerId = PlayerId()

    CreateThread(function()
        while true do
            Wait(500)
            
            local ped = PlayerPedId()
            local isDead = IsEntityDead(ped) or IsPedDeadOrDying(ped, true)
            
            if isDead and not wasDead then
                -- Player just died
                local killer = GetPedSourceOfDeath(ped)
                local killerName = nil
                local killedBySelf = false
                
                if killer and killer ~= 0 then
                    -- Check if killer is a player
                    if IsPedAPlayer(killer) then
                        local killerId = NetworkGetPlayerIndexFromPed(killer)
                        if killerId and killerId >= 0 then
                            -- Don't show if killed yourself
                            if killerId == playerId then
                                killedBySelf = true
                            else
                                killerName = GetPlayerName(killerId)
                            end
                        end
                    end
                end
                
                -- Only show killer name if not self and not environment
                if killerName and not killedBySelf then
                    exports['kw_notify']:ShowNotification('^1You were killed by ' .. killerName, 'error')
                elseif not killedBySelf then
                    exports['kw_notify']:ShowNotification('^1You died!', 'error')
                end
                
                wasDead = true
            elseif not isDead and wasDead then
                -- Player respawned
                wasDead = false
                playerId = PlayerId() -- Refresh player ID
            end
        end
    end)
end

-- === VEHICLE DAMAGE NOTIFICATIONS ===
if cfg.Notifications and (cfg.Notifications.FuelLeak or cfg.Notifications.BodyDamage) then
    local lastBodyHealth = 1000
    local lastTankHealth = 1000

    CreateThread(function()
        while true do
            Wait(2000)
            
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                local bodyHealth = GetVehicleBodyHealth(vehicle)
                local tankHealth = GetVehiclePetrolTankHealth(vehicle)
                
                -- Fuel tank leak
                if cfg.Notifications.FuelLeak and tankHealth <= 400 and lastTankHealth > 400 then
                    exports['kw_notify']:ShowNotification('^3Fuel tank leaking!', 'warning')
                end
                
                -- Vehicle heavily damaged
                if cfg.Notifications.BodyDamage and bodyHealth <= 300 and lastBodyHealth > 300 then
                    exports['kw_notify']:ShowNotification('^3Vehicle heavily damaged!', 'warning')
                end
                
                lastBodyHealth = bodyHealth
                lastTankHealth = tankHealth
            else
                lastBodyHealth = 1000
                lastTankHealth = 1000
            end
        end
    end)
end

-- === WEAPON RELOAD NOTIFICATION ===
if cfg.Notifications and (cfg.Notifications.OutOfAmmo or cfg.Notifications.LowAmmo) then
    local lastAmmo = -1
    local lastWeapon = nil
    local notifiedEmpty = false
    local notifiedLow = false

    CreateThread(function()
        while true do
            Wait(200)
            
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            
            -- Skip if no weapon or unarmed (hash -1569615261)
            if not weapon or weapon == 0 or weapon == -1569615261 then
                lastWeapon = nil
                lastAmmo = -1
                notifiedEmpty = false
                notifiedLow = false
                goto continue
            end
            
            -- Get current ammo in clip
            local hasAmmo, currentAmmo = GetAmmoInClip(ped, weapon)
            
            -- Weapon switched - reset tracking
            if weapon ~= lastWeapon then
                lastWeapon = weapon
                lastAmmo = currentAmmo or 0
                notifiedEmpty = false
                notifiedLow = false
                goto continue
            end
            
            -- Only check if we got valid ammo count
            if hasAmmo and currentAmmo ~= nil then
                -- Out of ammo (just fired last bullet)
                if cfg.Notifications.OutOfAmmo and currentAmmo == 0 and lastAmmo > 0 and not notifiedEmpty then
                    exports['kw_notify']:ShowNotification('^1Out of ammo!', 'warning')
                    notifiedEmpty = true
                    notifiedLow = false
                end
                
                -- Low ammo (5 or less, and was above 5 before)
                if cfg.Notifications.LowAmmo and currentAmmo <= 5 and currentAmmo > 0 and lastAmmo > 5 and not notifiedLow then
                    exports['kw_notify']:ShowNotification('^3Low ammo! (' .. currentAmmo .. ' left)', 'warning')
                    notifiedLow = true
                end
                
                -- Reset notifications when reloaded
                if currentAmmo > 5 then
                    notifiedEmpty = false
                    notifiedLow = false
                end
                
                lastAmmo = currentAmmo
            end
            
            ::continue::
        end
    end)
end

-- === ENGINE TOGGLE (Y key) ===
-- Only Y can control engine - disable auto-start on W
if cfg.EngineToggle and cfg.EngineToggle.Enabled then
    local engineOn = true
    local keyCode = 246 -- Y key default
    local lastVehicle = nil
    
    -- Convert key name to control index if string
    if cfg.EngineToggle.Key then
        local keyMap = {
            ['Y'] = 246,
            ['y'] = 246,
            ['E'] = 38,
            ['e'] = 38,
            ['G'] = 47,
            ['g'] = 47
        }
        keyCode = keyMap[cfg.EngineToggle.Key] or 246
    end

    -- Thread for Y key toggle
    CreateThread(function()
        while true do
            Wait(0)
            
            -- Check if player pressed key and is in driver seat
            if IsControlJustPressed(0, keyCode) then
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)
                
                if vehicle and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                    engineOn = not engineOn
                    SetVehicleEngineOn(vehicle, engineOn, false, true)
                    
                    -- Store vehicle reference
                    lastVehicle = vehicle
                    
                    if engineOn then
                        exports['kw_notify']:ShowNotification('^2Engine started', 'success')
                    else
                        exports['kw_notify']:ShowNotification('^1Engine stopped', 'info')
                    end
                end
            end
        end
    end)
    
    -- Thread to prevent auto-start when pressing W
    CreateThread(function()
        while true do
            Wait(0)
            
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            
            if vehicle and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                -- If this is a new vehicle, assume engine is on initially
                if lastVehicle ~= vehicle then
                    lastVehicle = vehicle
                    engineOn = GetIsVehicleEngineRunning(vehicle)
                end
                
                -- If engine should be off, force it off even if player presses W
                if not engineOn then
                    SetVehicleEngineOn(vehicle, false, true, true)
                    -- Also disable throttle
                    DisableControlAction(0, 71, true) -- INPUT_VEH_ACCELERATE
                    DisableControlAction(0, 72, true) -- INPUT_VEH_BRAKE
                end
            else
                lastVehicle = nil
            end
        end
    end)
end

-- === QUICK VEHICLE LEAVE & ENTER ===
-- Instant exit/enter without animation
if cfg.QuickLeave and cfg.QuickLeave.Enabled then
    -- Quick Leave
    CreateThread(function()
        while true do
            Wait(0)
            
            -- Check if player pressed exit key (F)
            if IsControlJustPressed(0, 75) then -- INPUT_VEH_EXIT = 75
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)
                
                if vehicle and vehicle ~= 0 then
                    -- Flag 16 = teleport out (instant, no animation)
                    TaskLeaveVehicle(ped, vehicle, 16)
                end
            end
        end
    end)
    
    -- Quick Enter
    CreateThread(function()
        while true do
            Wait(0)
            
            -- Check if player pressed enter key (F) when outside vehicle
            if IsControlJustPressed(0, 23) then -- INPUT_ENTER = 23 (F key)
                local ped = PlayerPedId()
                
                -- Only if not already in vehicle
                if not IsPedInAnyVehicle(ped, false) then
                    local vehicle = GetVehiclePedIsTryingToEnter(ped)
                    
                    -- If no vehicle being entered naturally, check nearby
                    if not vehicle or vehicle == 0 then
                        local coords = GetEntityCoords(ped)
                        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
                    end
                    
                    if vehicle and vehicle ~= 0 then
                        -- Find best seat
                        local seat = -1 -- Driver
                        
                        -- Check if driver seat is free
                        if not IsVehicleSeatFree(vehicle, -1) then
                            -- Try passenger seats
                            for i = 0, GetVehicleModelNumberOfSeats(GetEntityModel(vehicle)) - 2 do
                                if IsVehicleSeatFree(vehicle, i) then
                                    seat = i
                                    break
                                end
                            end
                        end
                        
                        -- Warp into vehicle instantly
                        SetPedIntoVehicle(ped, vehicle, seat)
                    end
                end
            end
        end
    end)
end

-- === RESOURCE START ===
print('[^3DTF Core^7] Client loaded - Configurable features active')
