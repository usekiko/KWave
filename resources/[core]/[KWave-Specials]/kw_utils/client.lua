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
                    lib.notify({ description = '^1Engine broken down!', type = 'error' })
                    engineNotified = true
                -- Engine heavily damaged (smoking, about to break)
                elseif cfg.Notifications.EngineDamaged and engineHealth <= 300 and lastEngineHealth > 300 and not engineNotified then
                    lib.notify({ description = '^3Engine critically damaged! Find a mechanic!', type = 'warning' })
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
                lib.notify({ description = '^1Critical health! Find cover!', type = 'error' })
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
                    lib.notify({ description = '^1You were killed by ' .. killerName, type = 'error' })
                elseif not killedBySelf then
                    lib.notify({ description = '^1You died!', type = 'error' })
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
                    lib.notify({ description = '^3Fuel tank leaking!', type = 'warning' })
                end
                
                -- Vehicle heavily damaged
                if cfg.Notifications.BodyDamage and bodyHealth <= 300 and lastBodyHealth > 300 then
                    lib.notify({ description = '^3Vehicle heavily damaged!', type = 'warning' })
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
                    lib.notify({ description = '^1Out of ammo!', type = 'warning' })
                    notifiedEmpty = true
                    notifiedLow = false
                end
                
                -- Low ammo (5 or less, and was above 5 before)
                if cfg.Notifications.LowAmmo and currentAmmo <= 5 and currentAmmo > 0 and lastAmmo > 5 and not notifiedLow then
                    lib.notify({ description = '^3Low ammo! (' .. currentAmmo .. ' left)', type = 'warning' })
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

    -- === MASTER OPTIMIZED THREAD (Event Driven) ===
    -- Consolidates Engine Toggle, Engine Force Off, Quick Leave, and Quick Enter
    if cfg.QuickLeave and cfg.QuickLeave.Enabled then
        RegisterCommand('+kw_quickleave', function()
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 then
                if LocalPlayer.state.seatbelt then
                    lib.notify({ description = 'You must unbuckle your seatbelt first!', type = 'error' })
                    return
                end
                TaskLeaveVehicle(ped, vehicle, 16)
            else
                local tryingToEnter = GetVehiclePedIsTryingToEnter(ped)
                if not tryingToEnter or tryingToEnter == 0 then
                    local coords = GetEntityCoords(ped)
                    tryingToEnter = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
                end
                if tryingToEnter and tryingToEnter ~= 0 then
                    local seat = -1
                    if not IsVehicleSeatFree(tryingToEnter, -1) then
                        for i = 0, GetVehicleModelNumberOfSeats(GetEntityModel(tryingToEnter)) - 2 do
                            if IsVehicleSeatFree(tryingToEnter, i) then
                                seat = i
                                break
                            end
                        end
                    end
                    SetPedIntoVehicle(ped, tryingToEnter, seat)
                end
            end
        end, false)
        RegisterCommand('-kw_quickleave', function() end, false)
        RegisterKeyMapping('+kw_quickleave', 'Quick Leave/Enter Vehicle', 'keyboard', 'F')
    end

    if cfg.EngineToggle and cfg.EngineToggle.Enabled then
        RegisterCommand('+kw_enginetoggle', function()
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                engineOn = not engineOn
                SetVehicleEngineOn(vehicle, engineOn, false, true)
                lastVehicle = vehicle
                if engineOn then
                    lib.notify({ description = '^2Engine started', type = 'success' })
                else
                    lib.notify({ description = '^1Engine stopped', type = 'info' })
                end
            end
        end, false)
        RegisterCommand('-kw_enginetoggle', function() end, false)
        RegisterKeyMapping('+kw_enginetoggle', 'Toggle Vehicle Engine', 'keyboard', cfg.EngineToggle.Key or 'Y')

        -- We still need a loop to force the engine off and disable throttle if it's off,
        -- but ONLY when the player is actually driving a vehicle with the engine off.
        CreateThread(function()
            while true do
                local sleep = 500
                local ped = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(ped, false)
                
                if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                    if lastVehicle ~= vehicle then
                        lastVehicle = vehicle
                        engineOn = GetIsVehicleEngineRunning(vehicle)
                    end
                    
                    if not engineOn then
                        sleep = 0
                        SetVehicleEngineOn(vehicle, false, true, true)
                        DisableControlAction(0, 71, true) -- Throttle
                        DisableControlAction(0, 72, true) -- Brake
                    end
                else
                    lastVehicle = nil
                end
                Wait(sleep)
            end
        end)
    end

end

-- === PVP OVERRIDES ===
CreateThread(function()
    while true do
        Wait(500)
        
        -- Weather and Time Lock
        SetWeatherTypePersist("EXTRASUNNY")
        SetWeatherTypeNowPersist("EXTRASUNNY")
        SetWeatherTypeNow("EXTRASUNNY")
        SetOverrideWeather("EXTRASUNNY")
        NetworkOverrideClockTime(12, 0, 0)
        
        -- Disable Cops and Emergency Dispatch
        for i = 1, 15 do
            EnableDispatchService(i, false)
        end
        SetCreateRandomCops(false)
        SetCreateRandomCopsNotOnScenarios(false)
        SetCreateRandomCopsOnScenarios(false)
        SetMaxWantedLevel(0)
    end
end)

CreateThread(function()
    while true do
        Wait(100)
        
        -- Infinite Stamina
        RestorePlayerStamina(PlayerId(), 1.0)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            SetVehicleFuelLevel(vehicle, 100.0)
        end
    end
end)

-- === RESOURCE START ===
print('[^3DTF Core^7] Client loaded - PvP Overrides active')
