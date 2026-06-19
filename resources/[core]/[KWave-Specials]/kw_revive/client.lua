--[[
    Standalone Revive System - Client
    Handles death detection and revive
]]

local isDead = false
local isSearched = false

-- Wait for KW to be ready
CreateThread(function()
    while not KW.PlayerLoaded do
        Wait(500)
    end
    
    -- Check death status on spawn
    local isDeadStatus = lib.callback.await('revive_system:getDeathStatus', false)
    if isDeadStatus then
        -- Player was dead when they disconnected, revive them
        TriggerEvent('revive_system:revive')
    end
end)

-- Main revive function (same logic as kw_ambulancejob)
RegisterNetEvent('revive_system:revive')
AddEventHandler('revive_system:revive', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    -- Update death status on server
    TriggerServerEvent('revive_system:setDeathStatus', false)
    
    -- Fade out
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do
        Wait(50)
    end
    
    -- Resurrect player at current location (same as kw_ambulancejob)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(playerPed), true, false)
    
    -- Clear death effects
    SetPlayerInvincible(playerPed, false)
    ClearPedBloodDamage(playerPed)
    ClearTimecycleModifier()
    SetPedMotionBlur(playerPed, false)
    ClearExtraTimecycleModifier()
    
    -- Reset health and armour
    SetEntityHealth(playerPed, 200)
    SetPedArmour(playerPed, 0)
    
    -- Clear any damage
    ResetPedVisibleDamage(playerPed)
    
    -- Reset death state
    isDead = false
    isSearched = false
    
    -- Trigger spawn events
    TriggerServerEvent('kw:onPlayerSpawn')
    TriggerEvent('kw:onPlayerSpawn')
    TriggerEvent('playerSpawned') -- compatibility
    
    -- Fade in
    DoScreenFadeIn(800)
    
    -- Notification
    lib.notify({ description = 'You have been revived!', type = 'success' })
end)

-- Death detection (triggers when player dies)
CreateThread(function()
    while true do
        Wait(500)
        
        local playerPed = PlayerPedId()
        
        -- Check if player died
        if not isDead and IsPedDeadOrDying(playerPed, true) then
            isDead = true
            
            -- Notify server
            TriggerServerEvent('kw:onPlayerDeath', {})
            
            -- Death effects (red screen, etc)
            SetTimecycleModifier("REDMIST_blend")
            SetTimecycleModifierStrength(0.7)
            SetExtraTimecycleModifier("fp_vig_red")
            SetExtraTimecycleModifierStrength(1.0)
            SetPedMotionBlur(playerPed, true)
            
            -- Start death loop (disable controls)
            StartDeathLoop()
        end
    end
end)

-- Death loop - disable controls while dead
function StartDeathLoop()
    CreateThread(function()
        while isDead do
            Wait(0)
            
            local playerPed = PlayerPedId()
            
            -- Disable most controls
            DisableAllControlActions(0)
            
            -- Keep some controls enabled
            EnableControlAction(0, 1, true)    -- Look left/right
            EnableControlAction(0, 2, true)    -- Look up/down
            EnableControlAction(0, 245, true)  -- T (chat)
            EnableControlAction(0, 38, true)   -- E (use)
            
            -- Force death animation if not playing
            if not IsEntityPlayingAnim(playerPed, 'dead', 'dead_a', 3) then
                if not HasAnimDictLoaded('dead') then
                    RequestAnimDict('dead')
                    while not HasAnimDictLoaded('dead') do
                        Wait(0)
                    end
                end
                TaskPlayAnim(playerPed, 'dead', 'dead_a', 8.0, 8.0, -1, 33, 0, false, false, false)
            end
        end
        
        -- Clear animation when revived
        ClearPedTasks(PlayerPedId())
        RemoveAnimDict('dead')
    end)
end

-- Reset on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ClearTimecycleModifier()
        SetPedMotionBlur(PlayerPedId(), false)
        ClearExtraTimecycleModifier()
    end
end)

-- Keybind for self-revive (for testing - can be removed)
-- RegisterCommand('selfrevive', function()
--     TriggerServerEvent('revive_system:setDeathStatus', false)
--     TriggerEvent('revive_system:revive')
-- end, false)

print('[^2Revive System^7] Client loaded')
