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

    -- === MASTER OPTIMIZED THREAD ===
    -- Consolidates Engine Toggle, Engine Force Off, Quick Leave, and Quick Enter
    CreateThread(function()
        while true do
            local sleep = 500
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            local inVehicle = vehicle ~= 0
            
            -- Quick Leave & Enter Check
            if cfg.QuickLeave and cfg.QuickLeave.Enabled then
                sleep = 0
                if inVehicle then
                    if IsControlJustPressed(0, 75) then -- F key
                        TaskLeaveVehicle(ped, vehicle, 16)
                    end
                else
                    if IsControlJustPressed(0, 23) then -- F key
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
                end
            end
            
            -- Engine Toggle Check
            if cfg.EngineToggle and cfg.EngineToggle.Enabled then
                if inVehicle and GetPedInVehicleSeat(vehicle, -1) == ped then
                    sleep = 0
                    
                    -- Start/Stop logic
                    if IsControlJustPressed(0, keyCode) then
                        engineOn = not engineOn
                        SetVehicleEngineOn(vehicle, engineOn, false, true)
                        lastVehicle = vehicle
                        
                        if engineOn then
                            exports['kw_notify']:ShowNotification('^2Engine started', 'success')
                        else
                            exports['kw_notify']:ShowNotification('^1Engine stopped', 'info')
                        end
                    end
                    
                    -- Force off logic
                    if lastVehicle ~= vehicle then
                        lastVehicle = vehicle
                        engineOn = GetIsVehicleEngineRunning(vehicle)
                    end
                    
                    if not engineOn then
                        SetVehicleEngineOn(vehicle, false, true, true)
                        DisableControlAction(0, 71, true) -- Throttle
                        DisableControlAction(0, 72, true) -- Brake
                    end
                else
                    lastVehicle = nil
                end
            end
            
            Wait(sleep)
        end
    end)

-- === RESOURCE START ===
print('[^3DTF Core^7] Client loaded - Configurable features active')
