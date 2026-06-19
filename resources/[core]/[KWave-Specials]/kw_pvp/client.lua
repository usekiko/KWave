-- DTF PvP - FPS Boost Optimizer (SMOOTH ULTRA EDITION) + Weapon Recoil
-- Maximum performance without stutter - batched processing
-- Includes weapon recoil system

local pvpEnabled = false
local pvpThreads = {}

-- ============================================
-- PvP MODE FEATURES
-- ============================================

-- Smaller, most impactful prop list only
local RemoveProps = {
    -- High-impact vegetation only
    `prop_bush_ivy_01`, `prop_bush_ivy_02`, `prop_bush_ivy_03`, `prop_bush_ivy_04`,
    `prop_bush_lrg_01`, `prop_bush_lrg_02`, `prop_bush_lrg_03`, `prop_bush_lrg_04`,
    `prop_bush_med_01`, `prop_bush_med_02`, `prop_bush_med_03`, `prop_bush_med_04`,
    `prop_bush_neat_01`, `prop_bush_neat_02`, `prop_bush_neat_03`, `prop_bush_neat_04`,
    `prop_bush_ornament_01`, `prop_bush_ornament_02`, `prop_bush_ornament_03`,
    
    -- Trees only - most common
    `prop_tree_birch_01`, `prop_tree_birch_02`, `prop_tree_birch_03`, `prop_tree_birch_04`,
    `prop_tree_cedar_01`, `prop_tree_cedar_02`, `prop_tree_cedar_03`, `prop_tree_cedar_04`,
    `prop_tree_cedar_s_01`, `prop_tree_cedar_s_02`, `prop_tree_eng_oak_01`,
    `prop_tree_jacada_01`, `prop_tree_jacada_02`, `prop_tree_lficus_01`,
    `prop_tree_lficus_02`, `prop_tree_pine_01`, `prop_tree_pine_02`,
    
    -- Common street clutter
    `prop_fire_hydrant_1`, `prop_fire_hydrant_2`,
    `prop_traffic_01a`, `prop_traffic_01b`, `prop_traffic_02a`, `prop_traffic_03a`,
    `prop_cone01a`, `prop_cone02a`, `prop_cone02b`,
    `prop_barrier_work01a`, `prop_barrier_work02a`,
    
    -- Trash bins
    `prop_bin_01a`, `prop_bin_02a`, `prop_bin_03a`, `prop_bin_04a`,
    `prop_rub_binbag_01`, `prop_rub_binbag_02`, `prop_rub_binbag_03`, `prop_rub_binbag_04`,
    `prop_rub_boxpile_01`, `prop_rub_boxpile_02`,
    
    -- Benches
    `prop_bench_01a`, `prop_bench_01b`, `prop_bench_02`, `prop_bench_03`,
    `prop_bench_04`, `prop_bench_05`, `prop_bench_06`, `prop_bench_07`, `prop_bench_08`,
}

-- Batch index for prop processing
local currentPropIndex = 1
local propsPerBatch = 5

local function StartPvPMode()
    if pvpEnabled then return end
    
    pvpEnabled = true
    currentPropIndex = 1
    
    -- Send NUI message
    SendNUIMessage({ type = 'toggle', enabled = true })
    
    -- Notification
    lib.notify({ description = 'PvP Mode ENABLED - Maximum FPS Boost active', type = 'success' })
    
    -- ONE-TIME setup
    SetTimecycleModifier("rply_saturation_neg")
    SetTimecycleModifierStrength(0.0)
    SetArtificialLightsState(true)
    SetCloudHatOpacity(0.0)
    SetCloudHeight(0.0)
    SetOverrideWeather("EXTRASUNNY")
    NetworkOverrideClockTime(12, 0, 0)
    PauseClock(true)
    
    -- THREAD 1: Frame optimizations (lightweight)
    table.insert(pvpThreads, CreateThread(function()
        while pvpEnabled do
            -- Densities
            SetScenarioPedDensityMultiplierThisFrame(0.0)
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetPedDensityMultiplierThisFrame(0.0)
            
            -- Shadows/lights
            SetArtificialLightsState(true)
            DisableVehicleDistantlights(true)
            
            -- Fog
            SetFogDensityThisFrame(0.0)
            
            -- Weather override
            SetOverrideWeather("EXTRASUNNY")
            
            Wait(0)
        end
    end))
    
    -- THREAD 2: Vehicle cleanup - every 3 seconds
    table.insert(pvpThreads, CreateThread(function()
        while pvpEnabled do
            local playerPed = PlayerPedId()
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)
            local playerCoords = GetEntityCoords(playerPed)
            
            local vehicles = GetGamePool('CVehicle')
            local count = 0
            for _, vehicle in ipairs(vehicles) do
                if count >= 10 then break end -- Max 10 per cycle
                if DoesEntityExist(vehicle) and vehicle ~= playerVehicle then
                    local driver = GetPedInVehicleSeat(vehicle, -1)
                    if driver == 0 or not IsPedAPlayer(driver) then
                        local vehCoords = GetEntityCoords(vehicle)
                        if #(playerCoords - vehCoords) < 200.0 then
                            SetEntityAsMissionEntity(vehicle, false, false)
                            DeleteVehicle(vehicle)
                            count = count + 1
                        end
                    end
                end
            end
            
            Wait(3000)
        end
    end))
    
    -- THREAD 3: Ped cleanup - every 3 seconds
    table.insert(pvpThreads, CreateThread(function()
        while pvpEnabled do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            local peds = GetGamePool('CPed')
            local count = 0
            for _, ped in ipairs(peds) do
                if count >= 10 then break end -- Max 10 per cycle
                if DoesEntityExist(ped) and ped ~= playerPed and not IsPedAPlayer(ped) then
                    local pedCoords = GetEntityCoords(ped)
                    if #(playerCoords - pedCoords) < 150.0 then
                        SetEntityAsMissionEntity(ped, false, false)
                        DeletePed(ped)
                        count = count + 1
                    end
                end
            end
            
            Wait(3000)
        end
    end))
    
    -- THREAD 4: Prop removal - BATCHED, one per frame
    table.insert(pvpThreads, CreateThread(function()
        while pvpEnabled do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            -- Process small batch
            for i = 1, propsPerBatch do
                if currentPropIndex > #RemoveProps then
                    currentPropIndex = 1
                end
                
                local propHash = RemoveProps[currentPropIndex]
                local object = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 
                    100.0, propHash, false, false, false)
                
                if object ~= 0 then
                    SetEntityAsMissionEntity(object, false, false)
                    DeleteObject(object)
                end
                
                currentPropIndex = currentPropIndex + 1
            end
            
            Wait(100)
        end
    end))
    
    -- THREAD 5: Generic small object cleanup - every 2 seconds
    table.insert(pvpThreads, CreateThread(function()
        while pvpEnabled do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            local objects = GetGamePool('CObject')
            local count = 0
            for _, obj in ipairs(objects) do
                if count >= 5 then break end -- Max 5 per cycle
                if DoesEntityExist(obj) then
                    local objCoords = GetEntityCoords(obj)
                    if #(playerCoords - objCoords) < 50.0 then
                        SetEntityAsMissionEntity(obj, false, false)
                        DeleteObject(obj)
                        count = count + 1
                    end
                end
            end
            
            Wait(2000)
        end
    end))
    
    -- THREAD 6: Decals cleanup - every second
    table.insert(pvpThreads, CreateThread(function()
        while pvpEnabled do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            RemoveDecalsInRange(playerCoords.x, playerCoords.y, playerCoords.z, 50.0)
            Wait(1000)
        end
    end))
    
    -- THREAD 7: Particles cleanup - every 2 seconds
    table.insert(pvpThreads, CreateThread(function()
        while pvpEnabled do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            RemoveParticleFxInRange(playerCoords.x, playerCoords.y, playerCoords.z, 100.0)
            Wait(2000)
        end
    end))
    
    -- ONE-TIME mass cleanup
    CreateThread(function()
        Wait(500)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Mass delete props
        for _, propHash in ipairs(RemoveProps) do
            for i = 1, 3 do -- Try 3 times per prop type
                local object = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 
                    200.0, propHash, false, false, false)
                if object ~= 0 then
                    SetEntityAsMissionEntity(object, false, false)
                    DeleteObject(object)
                else
                    break
                end
            end
        end
        
        -- Delete nearby vehicles
        local vehicles = GetGamePool('CVehicle')
        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) then
                local driver = GetPedInVehicleSeat(vehicle, -1)
                if driver == 0 or not IsPedAPlayer(driver) then
                    SetEntityAsMissionEntity(vehicle, false, false)
                    DeleteVehicle(vehicle)
                end
            end
        end
        
        -- Delete nearby peds
        local peds = GetGamePool('CPed')
        for _, ped in ipairs(peds) do
            if DoesEntityExist(ped) and ped ~= playerPed and not IsPedAPlayer(ped) then
                SetEntityAsMissionEntity(ped, false, false)
                DeletePed(ped)
            end
        end
    end)
end

local function StopPvPMode()
    if not pvpEnabled then return end
    
    pvpEnabled = false
    
    SendNUIMessage({ type = 'toggle', enabled = false })
    
    lib.notify({ description = 'PvP Mode DISABLED - Settings restored', type = 'info' })
    
    -- Restore
    ClearTimecycleModifier()
    SetArtificialLightsState(false)
    SetCloudHatOpacity(1.0)
    SetCloudHeight(1.0)
    ClearOverrideWeather()
    PauseClock(false)
    DisableVehicleDistantlights(false)
end

function TogglePvPMode()
    if pvpEnabled then
        StopPvPMode()
    else
        StartPvPMode()
    end
end

-- NUI
RegisterNUICallback('togglePvP', function(data, cb)
    TogglePvPMode()
    cb({ enabled = pvpEnabled })
end)

RegisterNUICallback('closeMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Commands
RegisterCommand('pvp', function() TogglePvPMode() end, false)
RegisterCommand('fps', function() TogglePvPMode() end, false)

-- Menu key
RegisterCommand('pvp_menu', function()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'openMenu', enabled = pvpEnabled })
end, false)
RegisterKeyMapping('pvp_menu', 'Open PvP Menu', 'keyboard', 'F8')

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName and pvpEnabled then
        StopPvPMode()
    end
end)

print('[^3DTF PvP^7] Smooth Ultra mode loaded. Use /pvp')


-- ============================================
-- WEAPON RECOIL FEATURES (from kw_recoil)
-- ============================================

local weapons = {
    [GetHashKey('WEAPON_PISTOL')] = {recoil = 0.2, shake = 0.1},
    [GetHashKey('WEAPON_PISTOL_MK2')] = {recoil = 0.3, shake = 0.03},
    [GetHashKey('WEAPON_COMBATPISTOL')] = {recoil = 0.2, shake = 0.03},
    [GetHashKey('WEAPON_APPISTOL')] = {recoil = 0.1, shake = 0.05},
    [GetHashKey('WEAPON_PISTOL50')] = {recoil = 0.6, shake = 0.05},
    [GetHashKey('WEAPON_MICROSMG')] = {recoil = 0.2, shake = 0.035},
    [GetHashKey('WEAPON_SMG')] = {recoil = 0.1, shake = 0.045},
    [GetHashKey('WEAPON_SMG_MK2')] = {recoil = 0.1, shake = 0.055},
    [GetHashKey('WEAPON_ASSAULTSMG')] = {recoil = 0.1, shake = 0.050},
    [GetHashKey('WEAPON_ASSAULTRIFLE')] = {recoil = 0.2, shake = 0.07},
    [GetHashKey('WEAPON_ASSAULTRIFLE_MK2')] = {recoil = 0.2, shake = 0.072},
    [GetHashKey('WEAPON_CARBINERIFLE')] = {recoil = 0.1, shake = 0.06},
    [GetHashKey('WEAPON_CARBINERIFLE_MK2')] = {recoil = 0.1, shake = 0.065},
    [GetHashKey('WEAPON_ADVANCED_RIFLE')] = {recoil = 0.1, shake = 0.06},
    [GetHashKey('WEAPON_MG')] = {recoil = 0.1, shake = 0.07},
    [GetHashKey('WEAPON_COMBATMG')] = {recoil = 0.1, shake = 0.08},
    [GetHashKey('WEAPON_COMBATMG_MK2')] = {recoil = 0.1, shake = 0.085},
    [GetHashKey('WEAPON_PUMPSHOTGUN')] = {recoil = 0.4, shake = 0.07},
    [GetHashKey('WEAPON_PUMPSHOTGUN_MK2')] = {recoil = 0.4, shake = 0.085},
    [GetHashKey('WEAPON_SAWNOFFSHOTGUN')] = {recoil = 0.7, shake = 0.06},
    [GetHashKey('WEAPON_ASSAULTSHOTGUN')] = {recoil = 0.4, shake = 0.12},
    [GetHashKey('WEAPON_BULLPUPSHOTGUN')] = {recoil = 0.2, shake = 0.08},
    [GetHashKey('WEAPON_STUNGUN')] = {recoil = 0.1, shake = 0.01},
    [GetHashKey('WEAPON_SNIPERRIFLE')] = {recoil = 0.5, shake = 0.2},
    [GetHashKey('WEAPON_HEAVYSNIPER')] = {recoil = 0.7, shake = 0.3},
    [GetHashKey('WEAPON_HEAVYSNIPER_MK2')] = {recoil = 0.7, shake = 0.35},
    [GetHashKey('WEAPON_REMOTESNIPER')] = {recoil = 1.2, shake = 0.1},
    [GetHashKey('WEAPON_GRENADELAUNCHER')] = {recoil = 1.0, shake = 0.08},
    [GetHashKey('WEAPON_GRENADELAUNCHER_SMOKE')] = {recoil = 1.0, shake = 0.04},
    [GetHashKey('WEAPON_RPG')] = {recoil = 0.0, shake = 0.9},
    [GetHashKey('WEAPON_STINGER')] = {recoil = 0.0, shake = 0.3},
    [GetHashKey('WEAPON_MINIGUN')] = {recoil = 0.01, shake = 0.25},
    [GetHashKey('WEAPON_SNSPISTOL')] = {recoil = 0.2, shake = 0.02},
    [GetHashKey('WEAPON_SNSPISTOL_MK2')] = {recoil = 0.25, shake = 0.025},
    [GetHashKey('WEAPON_GUSENBERG')] = {recoil = 0.1, shake = 0.05},
    [GetHashKey('WEAPON_SPECIALCARBINE')] = {recoil = 0.2, shake = 0.06},
    [GetHashKey('WEAPON_SPECIALCARBINE_MK2')] = {recoil = 0.25, shake = 0.075},
    [GetHashKey('WEAPON_HEAVYPISTOL')] = {recoil = 0.4, shake = 0.04},
    [GetHashKey('WEAPON_BULLPUPRIFLE')] = {recoil = 0.2, shake = 0.05},
    [GetHashKey('WEAPON_BULLPUPRIFLE_MK2')] = {recoil = 0.25, shake = 0.055},
    [GetHashKey('WEAPON_VINTAGEPISTOL')] = {recoil = 0.4, shake = 0.025},
    [GetHashKey('WEAPON_DOUBLEACTION')] = {recoil = 0.4, shake = 0.025},
    [GetHashKey('WEAPON_MUSKET')] = {recoil = 0.7, shake = 0.09},
    [GetHashKey('WEAPON_HEAVYSHOTGUN')] = {recoil = 0.2, shake = 0.13},
    [GetHashKey('WEAPON_MARKSMANRIFLE')] = {recoil = 0.3, shake = 0.05},
    [GetHashKey('WEAPON_MARKSMANRIFLE_MK2')] = {recoil = 0.35, shake = 0.035},
    [GetHashKey('WEAPON_HOMINGLAUNCHER')] = {recoil = 0, shake = 0.04},
    [GetHashKey('WEAPON_FLAREGUN')] = {recoil = 0.9, shake = 0.04},
    [GetHashKey('WEAPON_COMBATPDW')] = {recoil = 0.2, shake = 0.05},
    [GetHashKey('WEAPON_MARKSMANPISTOL')] = {recoil = 0.9, shake = 0.04},
    [GetHashKey('WEAPON_RAILGUN')] = {recoil = 2.4, shake = 0.08},
    [GetHashKey('WEAPON_MACHINEPISTOL')] = {recoil = 0.3, shake = 0.04},
    [GetHashKey('WEAPON_REVOLVER')] = {recoil = 0.6, shake = 0.05},
    [GetHashKey('WEAPON_REVOLVER_MK2')] = {recoil = 0.65, shake = 0.055},
    [GetHashKey('WEAPON_DBSHOTGUN')] = {recoil = 0.7, shake = 0.04},
    [GetHashKey('WEAPON_COMPACTRIFLE')] = {recoil = 0.3, shake = 0.03},
    [GetHashKey('WEAPON_AUTOSHOTGUN')] = {recoil = 0.2, shake = 0.04},
    [GetHashKey('WEAPON_COMPACTLAUNCHER')] = {recoil = 0.5, shake = 0.05},
    [GetHashKey('WEAPON_MINISMG')] = {recoil = 0.1, shake = 0.03},
}

local wasAiming = false
local previousViewMode = nil

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)
        
        if weapon == `WEAPON_UNARMED` then
            Wait(500)
            if wasAiming then
                if previousViewMode and previousViewMode ~= 4 then
                    SetFollowPedCamViewMode(previousViewMode)
                end
                wasAiming = false
                previousViewMode = nil
            end
        else
            Wait(0)
            
            -- ADS First Person Logic
            local isAiming = IsControlPressed(0, 25) -- INPUT_AIM
            if isAiming and not wasAiming then
                previousViewMode = GetFollowPedCamViewMode()
                SetFollowPedCamViewMode(4)
                wasAiming = true
            elseif not isAiming and wasAiming then
                if previousViewMode and previousViewMode ~= 4 then
                    SetFollowPedCamViewMode(previousViewMode)
                end
                wasAiming = false
                previousViewMode = nil
            end
            
            -- Recoil & Camera Shake Logic
            if IsPedShooting(ped) and not IsPedDoingDriveby(ped) then
                local data = weapons[weapon]
                if data then
                    if data.shake and data.shake > 0 then
                        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', data.shake)
                    end
                    
                    if data.recoil and data.recoil > 0 then
                        local tv = 0
                        repeat
                            Wait(0)
                            local p = GetGameplayCamRelativePitch()
                            if GetFollowPedCamViewMode() ~= 4 then
                                SetGameplayCamRelativePitch(p + 0.1, 0.2)
                            end
                            tv = tv + 0.1
                        until tv >= data.recoil
                    end
                end
            end
        end
    end
end)

print('[^3DTF PvP^7] Optimized ADS & Recoil systems loaded')

-- ============================================
-- HITMARKER SYSTEM
-- ============================================

AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local attacker = args[2]
        local isFatal = args[6] == 1

        local playerPed = PlayerPedId()
        
        if attacker == playerPed and victim ~= playerPed and IsEntityAPed(victim) then
            if IsPedAPlayer(victim) then
                SendNUIMessage({ type = 'hitmarker' })
            end
        end
    end
end)
