-- DTF Red Bull - Speed boost effect
-- Gives 1.5x walking speed for 2 minutes when consuming Red Bull
-- Energy crash after effect ends

local speedBoostActive = false
local speedBoostThread = nil
local boostEndTime = 0
local CRASH_CHANCE_RAGDOLL = 40 -- 40%
local CRASH_CHANCE_DRUNK = 30 -- 30%

-- Function to apply drunk effect
local function ApplyDrunkEffect()
    local playerPed = PlayerPedId()
    local startTime = GetGameTimer()
    local duration = 10000 -- 10 seconds
    
    print('[^3DTF Red Bull^7] Applying drunk effect')
    
    -- Apply drunk movement
    SetPedIsDrunk(playerPed, true)
    
    -- Apply strong camera shake
    CreateThread(function()
        local shakeDuration = 0
        while shakeDuration < duration do
            ShakeGameplayCam('DRUNK_SHAKE', 2.0)
            Wait(100)
            shakeDuration = shakeDuration + 100
        end
        StopGameplayCamShaking(false)
        SetPedIsDrunk(playerPed, false)
        print('[^3DTF Red Bull^7] Drunk effect ended')
    end)
end

-- Function to apply ragdoll effect
local function ApplyRagdollEffect()
    local playerPed = PlayerPedId()
    
    print('[^3DTF Red Bull^7] Applying ragdoll effect')
    
    -- Clear any current tasks and force ragdoll
    ClearPedTasksImmediately(playerPed)
    SetPedToRagdoll(playerPed, 2000, 2000, 0, true, true, false)
    
    -- Ensure player can get up quickly
    CreateThread(function()
        Wait(1500)
        if IsPedRagdoll(playerPed) then
            ClearPedTasks(playerPed)
        end
    end)
end

-- Function to apply energy crash
local function ApplyEnergyCrash()
    -- Roll first to see if there's an effect
    local roll = math.random(1, 100)
    print('[^3DTF Red Bull^7] Energy crash roll: ' .. roll .. ' (Ragdoll: 1-' .. CRASH_CHANCE_RAGDOLL .. ', Drunk: ' .. (CRASH_CHANCE_RAGDOLL + 1) .. '-' .. (CRASH_CHANCE_RAGDOLL + CRASH_CHANCE_DRUNK) .. ')')
    
    if roll <= CRASH_CHANCE_RAGDOLL then
        -- 40% chance - ragdoll
        print('[^3DTF Red Bull^7] Triggering ragdoll effect')
        exports['kw_notify']:ShowNotification("Energy crash! You'll feel worse for a moment, drink another one to feel better!", 'warning')
        Wait(1000)
        ApplyRagdollEffect()
    elseif roll <= CRASH_CHANCE_RAGDOLL + CRASH_CHANCE_DRUNK then
        -- 30% chance - drunk effect
        print('[^3DTF Red Bull^7] Triggering drunk effect')
        exports['kw_notify']:ShowNotification("Energy crash! You'll feel worse for a moment, drink another one to feel better!", 'warning')
        Wait(1000)
        ApplyDrunkEffect()
    else
        -- 30% chance - no effect
        print('[^3DTF Red Bull^7] No effect this time')
        exports['kw_notify']:ShowNotification("The crash wasn't too bad this time...", 'info')
    end
end

-- Main speed boost function
local function StartSpeedBoost()
    if speedBoostActive then
        return false
    end
    
    speedBoostActive = true
    boostEndTime = GetGameTimer() + 120000 -- 2 minutes
    
    exports['kw_notify']:ShowNotification('You drank a redbull! You got an energy boost.', 'success')
    
    -- Create thread for speed boost
    speedBoostThread = CreateThread(function()
        while speedBoostActive do
            local currentTime = GetGameTimer()
            
            if currentTime >= boostEndTime then
                break
            end
            
            -- Apply speed boost (1.5x)
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.5)
            SetPedMoveRateOverride(PlayerPedId(), 1.5)
            
            -- Infinite stamina
            RestorePlayerStamina(PlayerId(), 1.0)
            
            Wait(0)
        end
        
        -- Reset
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        SetPedMoveRateOverride(PlayerPedId(), 1.0)
        speedBoostActive = false
        boostEndTime = 0
        speedBoostThread = nil
        
        ApplyEnergyCrash()
    end)
    
    return true
end

-- Export for ox_inventory (this MUST be at the end after all functions are defined)
exports('UseRedBull', function(data, slot)
    if speedBoostActive then
        exports['kw_notify']:ShowNotification('You already drank one, wait till it finishes!', 'warning')
        return false
    end
    
    -- Remove item
    TriggerServerEvent('kw_redbull:removeItem', slot.slot)
    
    -- Start the boost
    StartSpeedBoost()
    return true
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        speedBoostActive = false
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        SetPedMoveRateOverride(PlayerPedId(), 1.0)
    end
end)

print('[^3DTF Red Bull^7] Loaded - Speed boost system active (1.5x, Infinite Stamina, Energy Crash)')
