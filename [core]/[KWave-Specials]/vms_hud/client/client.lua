if Config.Core == "KW" then
    KW = Config.CoreExport()
elseif Config.Core == "QB-Core" then
    QBCore = Config.CoreExport()
else
    Citizen.CreateThread(function()
        while true do
            print(('^8[WARNING] ^7- You missconfigure Config.Core: ^1"%s"^7, available: ^2"KW"^7 / ^2"QB-Core"^7'):format(Config.Core))
            Citizen.Wait(7500)
        end
    end)
end

hungerStatus = 0
thirstStatus = 0
stressStatus = 0
local hudOnScreen = true
local speedometerOnScreen = false
local customizationMenuOnScreen = false
local street = nil

seatbelt = false
local lastSpeed = 0.0
local currentSpeed = 0.0

local isInVehicle = false
local myVehicle = nil
local mySpeed = nil

Citizen.CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    repeat Wait(100) until HasScaleformMovieLoaded(minimap)
    loadPlayerMinimap()
    while true do
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
        -- BeginScaleformMovieMethod(minimap, 'HIDE_SATNAV')
        -- EndScaleformMovieMethod()
        SetRadarZoom(Config.MinimapZoom)
        Citizen.Wait(2500)
    end
end)

local lastHealth = 0
Citizen.CreateThread(function()
    while Config.Core == "KW" do
        local status = Config.GetStatus()
        hungerStatus = status.hunger
        thirstStatus = status.thirst
        stressStatus = Config.EnableStressStatus and status.stress or nil
        Citizen.Wait(Config.LoopTimeoutStatus)
    end
end)

local hudHasAmmo = false
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.LoopTimeoutHud)
        local myPed = PlayerPedId()
        local myPlayer = PlayerId()
        local myHealth = GetEntityHealth(myPed) - 100
        local myArmor = GetPedArmour(myPed)
        local myStamina, isUnderWater = not IsEntityInWater(myPed) and (100 - GetPlayerSprintStaminaRemaining(myPlayer)) or (GetPlayerUnderwaterTimeRemaining(myPlayer)*10), IsEntityInWater(myPed)
        local pause = IsPauseMenuActive()
        local voice = NetworkIsPlayerTalking(myPlayer)
        isInVehicle = IsPedSittingInAnyVehicle(myPed)
        SendNUIMessage({
            action = "updateHud",
            health = myHealth,
            armor = myArmor,
            stamina = myStamina,
            underwater = isUnderWater,
            hunger = hungerStatus,
            thirst = thirstStatus,
            stress = stressStatus,
            talking = voice
        })
        if Config.EnableDamageEffect then
            if lastHealth > GetEntityHealth(myPed) - 100 then
                SendNUIMessage({
                    action = "updateHud",
                    removedHealth = true
                })
            end
            lastHealth = myHealth
        end
        if Config.EnableAmmoCounter then
            local gotWeapon, weaponHash = GetCurrentPedWeapon(myPed)
            if gotWeapon then
                hudHasAmmo = true
                local myAmmo = GetAmmoInPedWeapon(myPed, weaponHash)
                local _, maxAmmo = GetMaxAmmo(myPed, weaponHash, myAmmo)
                SendNUIMessage({
                    action = "updateHud",
                    ammunation = Config.EnableShowMaxAmmo and myAmmo..'/'..maxAmmo or myAmmo,
                    display = true,
                })
            elseif not gotWeapon and hudHasAmmo then
                hudHasAmmo = false
                SendNUIMessage({
                    action = "updateHud",
                    ammunation = true,
                    display = false,
                })
            end
        end
        if isInVehicle then
            myVehicle = GetVehiclePedIsIn(myPed, false)
            mySpeed = (GetEntitySpeed(myVehicle) * (Config.UnitOfSpeed == 'kmh' and 3.6 or 2.236936))
            local door = false
            local lightsOff, lightsOn, highbeams = GetVehicleLightsState(myVehicle)
            local myRpm = GetVehicleCurrentRpm(myVehicle)
            local myFuel = Config.GetFuel(myVehicle)
            local myCoords = GetEntityCoords(myVehicle)
            local nameOfZone = GetNameOfZone(myCoords)
            local streetName, crossingRoad = GetStreetNameAtCoord(myCoords.x, myCoords.y, myCoords.z)
            local streetNameString = GetStreetNameFromHashKey(streetName)
            local crossingRoadHash = GetStreetNameFromHashKey(crossingRoad)
            if Config.DebugStreetNames then
                print('^4Config.DebugStreetNames:^7', nameOfZone)
            end
            if nameOfZone ~= street then
                if crossingRoadHash ~= '' then
                    nameOfZone = ('%s, %s'):format(crossingRoadHash, Config.CustomStreetNames[nameOfZone] or GetLabelText(nameOfZone))
                else
                    nameOfZone = Config.CustomStreetNames[nameOfZone] or GetLabelText(nameOfZone)
                    street = nameOfZone
                end
            end
            if 
                GetVehicleDoorAngleRatio(myVehicle, 0) ~= 0 or
                GetVehicleDoorAngleRatio(myVehicle, 1) ~= 0 or
                GetVehicleDoorAngleRatio(myVehicle, 2) ~= 0 or
                GetVehicleDoorAngleRatio(myVehicle, 3) ~= 0 or
                GetVehicleDoorAngleRatio(myVehicle, 4) ~= 0 or
                GetVehicleDoorAngleRatio(myVehicle, 5) ~= 0
            then
                door = true
            end
            SendNUIMessage({
                action = "updateCarHud",
                unitofspeed = Config.UnitOfSpeed,
                speed = math.floor(mySpeed),
                lights = {
                    lightsOn = lightsOn,
                    highbeams = highbeams
                },
                seatbelt = seatbelt,
                door = door,
                rpm = myRpm,
                fuel = myFuel,
                street = streetNameString,
                zone = nameOfZone
            })
        end
        if pause and hudOnScreen then
            Display(false)
        elseif not hudOnScreen and not pause then
            Display(true)
        end
        if isInVehicle and not speedometerOnScreen then
            SendNUIMessage({action = "showCarHud"})
            if Config.MinimapOnlyInVehicle then
                DisplayRadar(true)
            end
            speedometerOnScreen = true
        elseif speedometerOnScreen and not isInVehicle then
            SendNUIMessage({action = "hideCarHud"})
            seatbelt = false
            if Config.MinimapOnlyInVehicle then
                DisplayRadar(false)
            end
            speedometerOnScreen = false
        end
    end
end)

loadPlayerMinimap = function()
    SendNUIMessage({action = 'getMinimap'})
end

loadPlayerSpeedometer = function()
    SendNUIMessage({action = 'loadDefaultSpeedometer', default = Config.FirstSpeedometer})
end

Display = function(toggle)
    hudOnScreen = toggle
    SendNUIMessage({action = 'displayHud', display = toggle})
end

RegisterNetEvent('vms_hud:display', function(toggle)
    SendNUIMessage({action = 'displayHud', display = toggle})
    if isInVehicle then
        DisplayRadar(toggle)
    end
end)

exports('Display', function(toggle)
    SendNUIMessage({action = 'displayHud', display = toggle})
    if Config.MinimapOnlyInVehicle and isInVehicle or not Config.MinimapOnlyInVehicle then
        DisplayRadar(toggle)
    end
end)

if Config.EnableCustomizationMenu then
    if Config.CustomizationMenuCommand then
        RegisterCommand(Config.CustomizationMenuCommand, function()
            CustomizationMenu()
        end, false)

        if Config.CustomizationMenuKey then
            RegisterKeyMapping(Config.CustomizationMenuCommand, Config.CustomizationMenuDescription, "keyboard", Config.CustomizationMenuKey)
        end
    end
end

CustomizationMenu = function()
    if customizationMenuOnScreen then
        SendNUIMessage({action = 'closeCustomizationMenu'})
        SetNuiFocus(false, false)
        customizationMenuOnScreen = false
    else
        SendNUIMessage({action = 'openCustomizationMenu'})
        SetNuiFocus(true, true)
        customizationMenuOnScreen = true
    end
end

RegisterNUICallback("closeCustomizationMenu", function(data)
    CustomizationMenu()
end)

if Config.EnableSeatBelt then
    if Config.SeatBeltCommand then
        RegisterCommand(Config.SeatBeltCommand, function()
            SeatBelt()
        end, false)

        if Config.SeatBeltKey then
            RegisterKeyMapping(Config.SeatBeltCommand, Config.SeatBeltDescription, "keyboard", Config.SeatBeltKey)
        end
    end

    SeatBelt = function()
        if not isInVehicle then
            return
        end
        if not Config.SeatBeltVehiclesClasses[GetVehicleClass(myVehicle)] then
            return
        end
        seatbelt = not seatbelt
        Config.Notification(Config.Translate['notify.title.seat_belts'], seatbelt and Config.Translate['notify.seat_belts_buckled'] or Config.Translate['notify.seat_belts_unbuckled'], seatbelt and 'success' or 'error')
        Citizen.CreateThread(function()
            while seatbelt do
                if Config.DisableGTAHudInVehicle then
                    RemoveGTAHud()
                end
                DisableControlAction(0, 75, true)
                Citizen.Wait(1)
            end
        end)
    end

    Citizen.CreateThread(function()
        while true do
            local sleep = true
            if isInVehicle and not Config.SeatBeltAntiRagdollVehicles[GetVehicleClass(myVehicle)] and not seatbelt then
                sleep = false
                lastSpeed = currentSpeed
                currentSpeed = mySpeed
                if Config.DisableGTAHudInVehicle then
                    RemoveGTAHud()
                end
                local myVehVector = GetEntitySpeedVector(myVehicle, true).y > 15.0
                local myVehVelocity = GetEntityVelocity(myVehicle)
                local vhfr = (lastSpeed - mySpeed) / GetFrameTime() > 2000
                if lastSpeed > Config.SeatBeltMinimumSpeedToRagdoll and myVehVector and vhfr then
                    SeatBeltRagdoll(myVehVelocity)
                end
                if Config.EnableStressStatus and Config.EnableStressGenerator then
                    generateStress(currentSpeed)
                end
            end
            Citizen.Wait(sleep and 2000 or 5)
        end
    end)

    SeatBeltRagdoll = function(myVehVelocity)
        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)
        SetEntityCoords(myPed, myCoords.x, myCoords.y, myCoords.z+1.0, true, true, true)
        SetPedToRagdoll(myPed, 1000, 1000, 0, 0, 0, 0)
        SetEntityVelocity(myPed, myVehVelocity.x * 1.5, myVehVelocity.y * 1.5, myVehVelocity.z * 1.5)
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.25)
        Citizen.Wait(800)
        if math.random(1, 100) <= Config.SeatBeltChanceForInstantDeath then
            SetEntityHealth(myPed, 0)
        end
    end
end

RemoveGTAHud = function()
    HideHudComponentThisFrame(6)
    HideHudComponentThisFrame(7)
    HideHudComponentThisFrame(8)
    HideHudComponentThisFrame(9)
end

ChangeVoiceRange = function(range)
    SendNUIMessage({
        action = "updateHud",
        voicerange = range,
    })
end

ChangeMinimap = function(type)
    if not Config.UseCustomMinimap then
        return
    end
    local ratio = GetScreenAspectRatio()
    local posX = 0.015
    local posY = 0.022
    if tonumber(string.format("%.2f", ratio)) >= 2.3 then
        posX = -0.140
        posY = 0.022
    end
    if type == "circle" then
        RequestStreamedTextureDict("circlemap", false)
		if not HasStreamedTextureDictLoaded("circlemap") then
			Wait(200)
		end
        Wait(50)
		SetMinimapClipType(1)
		AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")
		AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "circlemap", "radarmasksm")
		SetMinimapComponentPosition('minimap', 'L', 'B', posX, -0.020, 0.120, 0.2)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', posX + 0.0155, posY + 0.03, 0.085, 0.40)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', posX - 0.0255, posY + 0.02, 0.23, 0.28)
		SetBlipAlpha(GetNorthRadarBlip(), 0)
		SetMinimapClipType(1)
		SetRadarBigmapEnabled(true, false)
		Wait(50)
		SetRadarBigmapEnabled(false, false)
    else
        RequestStreamedTextureDict("squaremap", false)
		if not HasStreamedTextureDictLoaded("squaremap") then
			Wait(200)
		end
		Wait(50)
        SetMinimapClipType(0)
		AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
		AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
		SetMinimapComponentPosition('minimap', 'L', 'B', posX, -0.020, 0.1175, 0.18)
        SetMinimapComponentPosition('minimap_mask', 'L', 'B', posX + 0.0155, posY + 0.03, 0.085, 0.40)
        SetMinimapComponentPosition('minimap_blur', 'L', 'B', posX - 0.0255, posY + 0.02, 0.23, 0.28)
		SetBlipAlpha(GetNorthRadarBlip(), 0)
		SetMinimapClipType(0)
		SetRadarBigmapEnabled(true, false)
		Wait(50)
		SetRadarBigmapEnabled(false, false)
    end
    if isInVehicle then
        if Config.MinimapOnlyInVehicle then
            DisplayRadar(true)
        end
    elseif not isInVehicle then
        if Config.MinimapOnlyInVehicle then
            DisplayRadar(false)
        end
    end
end

RegisterNUICallback("loaded", function(data)
    SendNUIMessage({
        action = "load",
        id = GetPlayerServerId(PlayerId()),
        minimapOnlyInVeh = Config.MinimapOnlyInVehicle,
        unitofspeed = Config.UnitOfSpeed,
        disableCenterIcon = Config.DisablePositioningOnCenterOfScreen,
        enableStress = Config.EnableStressStatus,
        enableFuel = Config.EnableFuel,
        enablePlayerId = Config.EnablePlayerId,
        enableCash = Config.EnableCashBalance,
        enableBank = Config.EnableBankBalance,
        enableBlackMoney = Config.EnableBlackMoneyBalance,
        enableJob = Config.EnablePlayerJob,
        enableGang = Config.EnablePlayerGang,
        infoHudIcons = Config.InfoHudIcons,
        disableLogo = Config.DisableHudLogo,
        enableAmmoCounter = Config.EnableAmmoCounter,
        useCustomMinimap = Config.UseCustomMinimap
    })
    if not Config.MinimapOnlyInVehicle then
        DisplayRadar(true)
    else
        DisplayRadar(false)
    end
end)

RegisterNUICallback("changeMinimap", function(data)
    if data.minimap == 'circle' then
        ChangeMinimap('circle')
    elseif data.minimap == 'square' then
        ChangeMinimap()
    else
        ChangeMinimap(Config.FirstMinimap)
    end
end)

exports('CreateCompanyMoneyHUD', function(balance)
    if not Config.EnableCompanyBalance then
        return
    end
    SendNUIMessage({
        action = 'updateHud',
        type = 'company',
        display = true
    })
end)

exports('RemoveCompanyMoneyHUD', function(balance)
    if not Config.EnableCompanyBalance then
        return
    end
    SendNUIMessage({
        action = 'updateHud',
        type = 'company',
        display = false
    })
end)

exports('UpdateCompanyMoney', function(balance)
    if not Config.EnableCompanyBalance then
        return
    end
    SendNUIMessage({
        action = 'updateHud',
        company_money = balance,
    })
end)