local KW = exports['kw_core']:getSharedObject()

local isInVehicle = false
local myVehicle = nil
local hudVisible = false
local vehHudVisible = false

local hunger = 100
local thirst = 100
local talking = false

-- Minimap Styling
CreateThread(function()
    RequestStreamedTextureDict("squaremap", false)
    if not HasStreamedTextureDictLoaded("squaremap") then Wait(200) end
    Wait(50)
    SetMinimapClipType(0)
    AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
    AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
    
    local ratio = GetScreenAspectRatio()
    
    local scaleX = 1.05 -- Reduced width
    local scaleY = 1.2  -- Kept height scale
    local offsetX = 0.025
    local offsetY = 0.025
    local extraHeight = 0.03 -- Increased height

    if tonumber(string.format("%.2f", ratio)) >= 2.3 then
        offsetX = -0.050
    end

    SetMinimapComponentPosition('minimap', 'L', 'B', -0.0045 + offsetX, 0.002 + offsetY, 0.150 * scaleX, (0.188888 * scaleY) + extraHeight)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', 0.020 + offsetX, 0.032 + offsetY, 0.111 * scaleX, (0.159 * scaleY) + extraHeight)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.03 + offsetX, 0.022 + offsetY, 0.266 * scaleX, (0.237 * scaleY) + extraHeight)
    
    SetBlipAlpha(GetNorthRadarBlip(), 0)
    SetRadarBigmapEnabled(true, false)
    Wait(50)
    SetRadarBigmapEnabled(false, false)
end)

-- Scaleform & Radar Zoom maintenance loop (Prevents map glitching/disappearing)
CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    while not HasScaleformMovieLoaded(minimap) do
        Wait(100)
    end
    while true do
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
        SetRadarZoom(1100)
        Wait(2500)
    end
end)

-- Status Update Loop
CreateThread(function()
    while true do
        local status = KW.GetPlayerData()
        if status and status.metadata then
            hunger = 100
            thirst = 100
        end
        Wait(Config.LoopTimeoutStatus or 2500)
    end
end)

-- Voice talking state via NetworkIsPlayerTalking
CreateThread(function()
    while true do
        Wait(200)
        local ped = PlayerId()
        local isTalking = NetworkIsPlayerTalking(ped)
        if isTalking ~= talking then
            talking = isTalking
            SendNUIMessage({
                action = "updateStatus",
                data = {
                    isTalking = talking
                }
            })
        end
    end
end)

-- Main HUD Loop
CreateThread(function()
    while true do
        Wait(Config.LoopTimeoutHud or 200)
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped) - 100
        if health < 0 then health = 0 end
        local armor = GetPedArmour(ped)

        -- Pause menu hide
        local pause = IsPauseMenuActive()
        if pause and hudVisible then
            hudVisible = false
            SendNUIMessage({ action = "displayHud", data = { display = false } })
        elseif not pause and not hudVisible then
            hudVisible = true
            SendNUIMessage({ action = "displayHud", data = { display = true } })
        end

        SendNUIMessage({
            action = "updateStatus",
            data = {
                health = health,
                armor = armor,
                hunger = hunger,
                thirst = thirst,
                voice = 2 -- Default voice range level
            }
        })

        -- Vehicle logic check
        local inVeh = IsPedSittingInAnyVehicle(ped)
        if inVeh and not vehHudVisible then
            vehHudVisible = true
            isInVehicle = true
            myVehicle = GetVehiclePedIsIn(ped, false)
            SendNUIMessage({ action = "showCarHud" })
        elseif not inVeh and vehHudVisible then
            vehHudVisible = false
            isInVehicle = false
            myVehicle = nil
            SendNUIMessage({ action = "hideCarHud" })
        end
    end
end)

-- Dedicated Vehicle Loop (Runs only when in vehicle)
CreateThread(function()
    local lastSpeed = 0.0
    local lastBodyHealth = 1000.0

    while true do
        if isInVehicle and myVehicle then
            local speed = GetEntitySpeed(myVehicle) * 3.6 -- KMH
            local rpm = GetVehicleCurrentRpm(myVehicle)
            local gear = GetVehicleCurrentGear(myVehicle)
            
            SendNUIMessage({
                action = "updateCarHud",
                data = {
                    speed = speed,
                    rpm = rpm,
                    gear = gear
                }
            })
            
            lastSpeed = speed
            Wait(50)
        else
            Wait(1000)
        end
    end
end)
