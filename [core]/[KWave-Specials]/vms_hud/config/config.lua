Config = {}

Config.Core = "KW" -- "KW" / "QB-Core"
Config.CoreExport = function()
    return exports['kw_core']:getSharedObject() -- KW
    -- return exports['qb-core']:GetCoreObject() -- QB-CORE
end

Config.Notification = function(title, message, type)
    if type == 'success' then
        exports['vms_notify']:Notification(title, message, 4500, '#49eb34', 'fa-solid fa-car')
        -- TriggerEvent('kw:showNotification', message)
        -- TriggerEvent('QBCore:Notify', message, type)
    elseif type == 'error' then
        exports['vms_notify']:Notification(title, message, 4500, '#eb4034', 'fa-solid fa-car')
        -- TriggerEvent('kw:showNotification', message)
        -- TriggerEvent('QBCore:Notify', message, type)
    end
end

Config.Translate = {
    ['notify.title.seat_belts'] = 'SEAT BELTS',
    ['notify.seat_belts_buckled'] = 'The seat belts were fastened.',
    ['notify.seat_belts_unbuckled'] = 'Seat belts were unbuckled.',
}

Config.LoopTimeoutHud = 80
Config.LoopTimeoutStatus = 1000


Config.EnableCustomizationMenu = true
Config.CustomizationMenuCommand = 'hud'
Config.CustomizationMenuKey = 'I'
Config.CustomizationMenuDescription = 'Hud Customization'


Config.DisableHudLogo = false


Config.EnableAmmoCounter = true
Config.EnableShowMaxAmmo = true

Config.EnableSeatBelt = true
Config.SeatBeltCommand = 'seatbelt'
Config.SeatBeltKey = 'B'
Config.SeatBeltDescription = 'Seat belt'

Config.SeatBeltMinimumSpeedToRagdoll = 100 -- The minimum speed at which a player without a seatbelt can fall out of a vehicle
Config.SeatBeltChanceForInstantDeath = 50 -- 50 = 50%

-- @SeatBeltVehiclesClasses: false = seat belts cannot be fastened in the vehicle
-- @SeatBeltVehiclesClasses: true = seat belts can be fastened in the vehicle
Config.SeatBeltVehiclesClasses = { -- Classes of vehicles in which seat belts can be fastened
    [0] = true, -- Compacts
    [1] = true, -- Sedans
    [2] = true, -- SUVs
    [3] = true, -- Coupes
    [4] = true, -- Muscle
    [5] = true, -- Sports Classics
    [6] = true, -- Sports
    [7] = true, -- Super
    [8] = false, -- Motorcycles
    [9] = true, -- Off-road
    [10] = true, -- Industrial
    [11] = true, -- Utility
    [12] = true, -- Vans
    [13] = false, -- Cycles
    [14] = false, -- Boats
    [15] = false, -- Helicopters
    [16] = false, -- Planes
    [17] = true, -- Service
    [18] = true, -- Emergency
    [19] = true, -- Military
    [20] = true, -- Commercial
    [21] = true, -- Trains
    [22] = true, -- Open Wheel
}

-- @SeatBeltAntiRagdollVehicles: false = player may fall out
-- @SeatBeltAntiRagdollVehicles: true = player cannot fall out
Config.SeatBeltAntiRagdollVehicles = { -- Vehicle classes that are not taken into account in case of a hard hit (the player will not fall out of them)
    [0] = false, -- Compacts
    [1] = false, -- Sedans
    [2] = false, -- SUVs
    [3] = false, -- Coupes
    [4] = false, -- Muscle
    [5] = false, -- Sports Classics
    [6] = false, -- Sports
    [7] = false, -- Super
    [8] = true, -- Motorcycles
    [9] = false, -- Off-road
    [10] = false, -- Industrial
    [11] = false, -- Utility
    [12] = false, -- Vans
    [13] = true, -- Cycles
    [14] = true, -- Boats
    [15] = true, -- Helicopters
    [16] = true, -- Planes
    [17] = false, -- Service
    [18] = false, -- Emergency
    [19] = false, -- Military
    [20] = false, -- Commercial
    [21] = false, -- Trains
    [22] = false, -- Open Wheel
}

Config.DebugStreetNames = false -- use only for development purposes so that you can check street names on F8 and set a custom name to them, do not use when there are players
Config.CustomStreetNames = {
    -- ['AIRP'] = 'National Airport',
    -- ['PBOX'] = 'Hospital',
}

Config.EnableFuel = false

Config.EnableStressStatus = true
Config.EnableStressGenerator = true
Config.EnableStressReducer = false
Config.StressGeneratorMinSpeed = 50.0 -- 50 kmh / 50 mph
Config.EnableStressShooting = false

Config.EnableDamageEffect = true

Config.InfoHudIcons = true -- true: icons  |  false: text from translation.js

Config.EnablePlayerId = true
Config.EnableCashBalance = true
Config.EnableBankBalance = true
Config.EnableBlackMoneyBalance = true
Config.EnableCompanyBalance = true

Config.EnablePlayerJob = true
Config.EnablePlayerJobGrade = true

Config.EnablePlayerGang = true
Config.EnablePlayerGangGrade = true


Config.UnitOfSpeed = 'kmh' -- 'kmh' or 'mph'

Config.DisableGTAHudInVehicle = true -- removes the natives gta 5 display of street names, etc.

Config.DisablePositioningOnCenterOfScreen = true -- this will prevent the player from setting the status icon in the middle of the screen and using that as, for example, a shooting dot

Config.UseCustomMinimap = true
Config.FirstMinimap = 'circle' -- 'circle' / 'square'
Config.MinimapZoom = 1100
Config.MinimapOnlyInVehicle = false

Config.FirstSpeedometer = 'circle' -- 'circle' / 'linear'

Config.PMAVoiceRanges = {
    [1] = 25,
    [2] = 60,
    [3] = 100,
}

Config.MumbleVoipRanges = {
    [1] = 25,
    [2] = 60,
    [3] = 100,
}

Config.SaltyChatRanges = {
    [3.0] = 10,
    [8.0] = 30,
    [15.0] = 65,
    [32.0] = 100,
}

Config.GetStatus = function()
    -- FOR QB-Core is in the config.client.lua
    if Config.Core == "KW" then
        local hunger = 0
        local thirst = 0
        local stress = 0
        TriggerEvent("kw_status:getStatus", "hunger", function(hungerStat)
            hunger = hungerStat.getPercent()
        end)
        TriggerEvent("kw_status:getStatus", "thirst", function(thirstStat)
            thirst = thirstStat.getPercent()
        end)
        if Config.EnableStressStatus then
            TriggerEvent("kw_status:getStatus", "stress", function(stressStat)
                stress = stressStat.getPercent()
            end)
            return {
                hunger = hunger, 
                thirst = thirst,
                stress = stress,
            }
        end
        return {
            hunger = hunger, 
            thirst = thirst,
        }
    end
end

Config.GetFuel = function(vehicle)
    return GetVehicleFuelLevel(vehicle)
    -- return exports['LegacyFuel']:GetFuel(vehicle)
end