Adjustments = {}

function Adjustments:RemoveHudComponents()
    for i = 1, #Config.RemoveHudComponents do
        if Config.RemoveHudComponents[i] then
            SetHudComponentSize(i, 0.0, 0.0)
            SetHudComponentPosition(i, 900.0, 900.0)
        end
    end
end

function Adjustments:DisableAimAssist()
    if Config.DisableAimAssist then
        SetPlayerTargetingMode(3)
    end
end

function Adjustments:DisableNPCDrops()
    if Config.DisableNPCDrops then
        local weaponPickups = { `PICKUP_WEAPON_CARBINERIFLE`, `PICKUP_WEAPON_PISTOL`, `PICKUP_WEAPON_PUMPSHOTGUN` }
        for i = 1, #weaponPickups do
            ToggleUsePickupsForPlayer(KW.playerId, weaponPickups[i], false)
        end
    end
end

function Adjustments:SeatShuffle()
    if Config.DisableVehicleSeatShuff then
        AddEventHandler("kw:enteredVehicle", function(vehicle, _, seat)
            if seat > -1 then
                SetPedIntoVehicle(KW.PlayerData.ped, vehicle, seat)
                SetPedConfigFlag(KW.PlayerData.ped, 184, true)
            end
        end)
    end
end

function Adjustments:HealthRegeneration()
    if Config.DisableHealthRegeneration then
        SetPlayerHealthRechargeMultiplier(KW.playerId, 0.0)
    end
end

function Adjustments:AmmoAndVehicleRewards()
    -- Ammo and Vehicle Rewards are now handled in the master tick below
end

function Adjustments:Multipliers()
    -- Multipliers are now handled in the master tick below
end

-- === MASTER ADJUSTMENTS THREAD ===
CreateThread(function()
    -- Check if we even need a Wait(0) thread at all
    local needsTick = false
    if Config.DisableDisplayAmmo or Config.DisableVehicleRewards then
        needsTick = true
    end
    if Config.Multipliers and (Config.Multipliers.pedDensity ~= 1.0 or Config.Multipliers.vehicleDensity ~= 1.0) then
        needsTick = true
    end
    
    -- If default settings, just terminate the thread immediately
    if not needsTick then return end
    
    while true do
        Wait(0)
        
        -- Ammo & Rewards
        if Config.DisableDisplayAmmo then
            DisplayAmmoThisFrame(false)
        end

        if Config.DisableVehicleRewards then
            DisablePlayerVehicleRewards(KW.playerId)
        end
        
        -- Multipliers
        if Config.Multipliers then
            SetPedDensityMultiplierThisFrame(Config.Multipliers.pedDensity or 1.0)
            SetScenarioPedDensityMultiplierThisFrame(Config.Multipliers.scenarioPedDensityInterior or 1.0, Config.Multipliers.scenarioPedDensityExterior or 1.0)
            SetAmbientVehicleRangeMultiplierThisFrame(Config.Multipliers.ambientVehicleRange or 1.0)
            SetParkedVehicleDensityMultiplierThisFrame(Config.Multipliers.parkedVehicleDensity or 1.0)
            SetRandomVehicleDensityMultiplierThisFrame(Config.Multipliers.randomVehicleDensity or 1.0)
            SetVehicleDensityMultiplierThisFrame(Config.Multipliers.vehicleDensity or 1.0)
        end
    end
end)

function Adjustments:Load()
    self:RemoveHudComponents()
    self:DisableAimAssist()
    self:DisableNPCDrops()
    self:SeatShuffle()
    self:HealthRegeneration()
    self:AmmoAndVehicleRewards()
    -- Legacy methods removed to improve performance
    self:Multipliers()
end
