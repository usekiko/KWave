local pickups = {}

RegisterNetEvent("kw:requestModel", function(model)
    KW.Streaming.RequestModel(model)
end)

RegisterNetEvent("kw:playerLoaded", function(xPlayer, _, skin)
    KW.PlayerData = xPlayer

    if not Config.Multichar then
        KW.SpawnPlayer(skin, KW.PlayerData.coords, function()
            TriggerEvent("kw:onPlayerSpawn")
            TriggerEvent("kw:restoreLoadout")
            TriggerServerEvent("kw:onPlayerSpawn")
            TriggerEvent("kw:loadingScreenOff")
            ShutdownLoadingScreen()
            ShutdownLoadingScreenNui()
        end)
    end

    while not DoesEntityExist(KW.PlayerData.ped) do
        Wait(20)
    end

    KW.PlayerLoaded = true

    local timer = GetGameTimer()
    while not HaveAllStreamingRequestsCompleted(KW.PlayerData.ped) and (GetGameTimer() - timer) < 2000 do
        Wait(0)
    end

    Adjustments:Load()

    ClearPedTasksImmediately(KW.PlayerData.ped)

    if not Config.Multichar then
        Core.FreezePlayer(false)
    end

    if IsScreenFadedOut() then
        DoScreenFadeIn(500)
    end

    Actions:Init()
    StartPointsLoop()
    StartServerSyncLoops()
    NetworkSetLocalPlayerSyncLookAt(true)
end)

local isFirstSpawn = true
KW.SecureNetEvent("kw:onPlayerLogout", function()
    KW.PlayerLoaded = false
    isFirstSpawn = true
end)

KW.SecureNetEvent("kw:setMaxWeight", function(newMaxWeight)
    KW.SetPlayerData("maxWeight", newMaxWeight)
end)

KW.SecureNetEvent("kw:setInventory", function(newInventory)
    KW.SetPlayerData("inventory", newInventory)
end)

local function onPlayerSpawn()
    KW.SetPlayerData("ped", PlayerPedId())
    KW.SetPlayerData("dead", false)
end

AddEventHandler("playerSpawned", onPlayerSpawn)
AddEventHandler("kw:onPlayerSpawn", function()
    onPlayerSpawn()

    if isFirstSpawn then
        isFirstSpawn = false

        if KW.PlayerData.metadata.health and (KW.PlayerData.metadata.health > 0 or Config.SaveDeathStatus) then
            SetEntityHealth(KW.PlayerData.ped, KW.PlayerData.metadata.health)
        end

        if KW.PlayerData.metadata.armor and KW.PlayerData.metadata.armor > 0 then
            SetPedArmour(KW.PlayerData.ped, KW.PlayerData.metadata.armor)
        end
    end
end)

AddEventHandler("kw:onPlayerDeath", function()
    KW.SetPlayerData("ped", PlayerPedId())
    KW.SetPlayerData("dead", true)
end)

AddEventHandler("skinchanger:modelLoaded", function()
    while not KW.PlayerLoaded do
        Wait(100)
    end
    TriggerEvent("kw:restoreLoadout")
end)

AddEventHandler("kw:restoreLoadout", function()
    KW.SetPlayerData("ped", PlayerPedId())

    if not Config.CustomInventory then
        local ammoTypes = {}
        RemoveAllPedWeapons(KW.PlayerData.ped, true)

        for _, v in ipairs(KW.PlayerData.loadout) do
            local weaponName = v.name
            local weaponHash = joaat(weaponName)

            GiveWeaponToPed(KW.PlayerData.ped, weaponHash, 0, false, false)
            SetPedWeaponTintIndex(KW.PlayerData.ped, weaponHash, v.tintIndex)

            local ammoType = GetPedAmmoTypeFromWeapon(KW.PlayerData.ped, weaponHash)

            for _, v2 in ipairs(v.components) do
                local componentHash = KW.GetWeaponComponent(weaponName, v2).hash
                GiveWeaponComponentToPed(KW.PlayerData.ped, weaponHash, componentHash)
            end

            if not ammoTypes[ammoType] then
                AddAmmoToPed(KW.PlayerData.ped, weaponHash, v.ammo)
                ammoTypes[ammoType] = true
            end
        end
    end
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler("VehicleProperties", nil, function(bagName, _, value)
    if not value then
        return
    end

    bagName = bagName:gsub("entity:", "")
    local netId = tonumber(bagName)
    if not netId then
        error("Tried to set vehicle properties with invalid netId")
        return
    end

    local tries = 0
    
    while not NetworkDoesEntityExistWithNetworkId(netId) do
        Wait(200)
        tries = tries + 1
        if tries > 20 then
            return error(("Invalid entity - ^5%s^7!"):format(netId))
        end
    end

    local vehicle = NetToVeh(netId)

    if NetworkGetEntityOwner(vehicle) ~= KW.playerId then
        return
    end

    KW.Game.SetVehicleProperties(vehicle, value)
end)

AddStateBagChangeHandler("accounts", "", function(bagName, _, value, _, _)
    local ply = PlayerId()
    if bagName ~= ("player:%s"):format(GetPlayerServerId(ply)) then return end
    if not value then return end
    KW.SetPlayerData("accounts", value)
end)

if not Config.CustomInventory then
    KW.SecureNetEvent("kw:addInventoryItem", function(item, count, showNotification)
        for k, v in ipairs(KW.PlayerData.inventory) do
            if v.name == item then
                KW.UI.ShowInventoryItemNotification(true, v.label, count - v.count)
                KW.PlayerData.inventory[k].count = count
                break
            end
        end

        if showNotification then
            KW.UI.ShowInventoryItemNotification(true, item, count)
        end
    end)

    KW.SecureNetEvent("kw:removeInventoryItem", function(item, count, showNotification)
        for i = 1, #KW.PlayerData.inventory do
            if KW.PlayerData.inventory[i].name == item then
                KW.UI.ShowInventoryItemNotification(false, KW.PlayerData.inventory[i].label, KW.PlayerData.inventory[i].count - count)
                KW.PlayerData.inventory[i].count = count
                break
            end
        end

        if showNotification then
            KW.UI.ShowInventoryItemNotification(false, item, count)
        end
    end)

    KW.SecureNetEvent("kw:addLoadoutItem", function(weaponName, weaponLabel, ammo)
        table.insert(KW.PlayerData.loadout, {
            name = weaponName,
            ammo = ammo,
            label = weaponLabel,
            components = {},
            tintIndex = 0,
        })
    end)

    KW.SecureNetEvent("kw:removeLoadoutItem", function(weaponName, weaponLabel)
        for i = 1, #KW.PlayerData.loadout do
            if KW.PlayerData.loadout[i].name == weaponName then
                table.remove(KW.PlayerData.loadout, i)
                break
            end
        end
    end)

    RegisterNetEvent("kw:addWeapon", function()
        error("event ^5'kw:addWeapon'^1 Has Been Removed. Please use ^5xPlayer.addWeapon^1 Instead!")
    end)


    RegisterNetEvent("kw:addWeaponComponent", function()
        error("event ^5'kw:addWeaponComponent'^1 Has Been Removed. Please use ^5xPlayer.addWeaponComponent^1 Instead!")
    end)

    RegisterNetEvent("kw:setWeaponAmmo", function()
        error("event ^5'kw:setWeaponAmmo'^1 Has Been Removed. Please use ^5xPlayer.addWeaponAmmo^1 Instead!")
    end)

    KW.SecureNetEvent("kw:setWeaponTint", function(weapon, weaponTintIndex)
        SetPedWeaponTintIndex(KW.PlayerData.ped, joaat(weapon), weaponTintIndex)
    end)

    RegisterNetEvent("kw:removeWeapon", function()
        error("event ^5'kw:removeWeapon'^1 Has Been Removed. Please use ^5xPlayer.removeWeapon^1 Instead!")
    end)

    KW.SecureNetEvent("kw:removeWeaponComponent", function(weapon, weaponComponent)
        local componentHash = KW.GetWeaponComponent(weapon, weaponComponent).hash
        RemoveWeaponComponentFromPed(KW.PlayerData.ped, joaat(weapon), componentHash)
    end)
end

AddStateBagChangeHandler("job", "", function(bagName, _, value, _, _)
    local ply = PlayerId()
    if bagName ~= ("player:%s"):format(GetPlayerServerId(ply)) then return end
    if not value then return end
    KW.SetPlayerData("job", value)
end)

AddStateBagChangeHandler("group", "", function(bagName, _, value, _, _)
    local ply = PlayerId()
    if bagName ~= ("player:%s"):format(GetPlayerServerId(ply)) then return end
    if not value then return end
    KW.SetPlayerData("group", value)
end)



KW.SecureNetEvent("kw:registerSuggestions", function(registeredCommands)
    for name, command in pairs(registeredCommands) do
        if command.suggestion then
            TriggerEvent("chat:addSuggestion", ("/%s"):format(name), command.suggestion.help, command.suggestion.arguments)
        end
    end
end)



function StartServerSyncLoops()
    if Config.CustomInventory then return end

    local currentWeapon = {
        ---@type number
        ---@diagnostic disable-next-line: assign-type-mismatch
        hash = `WEAPON_UNARMED`,
        ammo = 0,
    }

    local function updateCurrentWeaponAmmo(weaponName)
        local newAmmo = GetAmmoInPedWeapon(KW.PlayerData.ped, currentWeapon.hash)

        if newAmmo ~= currentWeapon.ammo then
            currentWeapon.ammo = newAmmo
            TriggerServerEvent("kw:updateWeaponAmmo", weaponName, newAmmo)
        end
    end

    CreateThread(function()
        while KW.PlayerLoaded do
            currentWeapon.hash = GetSelectedPedWeapon(KW.PlayerData.ped)

            if currentWeapon.hash ~= `WEAPON_UNARMED` then
                local weaponConfig = KW.GetWeaponFromHash(currentWeapon.hash)

                if weaponConfig then
                    currentWeapon.ammo = GetAmmoInPedWeapon(KW.PlayerData.ped, currentWeapon.hash)

                    while GetSelectedPedWeapon(KW.PlayerData.ped) == currentWeapon.hash do
                        updateCurrentWeaponAmmo(weaponConfig.name)
                        Wait(1000)
                    end

                    updateCurrentWeaponAmmo(weaponConfig.name)
                end
            end
            Wait(250)
        end
    end)

    CreateThread(function()
        local PARACHUTE_OPENING <const> = 1
        local PARACHUTE_OPEN <const> = 2

        while KW.PlayerLoaded do
            local parachuteState = GetPedParachuteState(KW.PlayerData.ped)

            if parachuteState == PARACHUTE_OPENING or parachuteState == PARACHUTE_OPEN then
                TriggerServerEvent("kw:updateWeaponAmmo", "GADGET_PARACHUTE", 0)

                while GetPedParachuteState(KW.PlayerData.ped) ~= -1 do Wait(1000) end
            end
            Wait(500)
        end
    end)
end



----- Admin commands from kw_adminplus
RegisterNetEvent("kw:tpm", function()
    local GetEntityCoords = GetEntityCoords
    local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
    local GetFirstBlipInfoId = GetFirstBlipInfoId
    local DoesBlipExist = DoesBlipExist
    local DoScreenFadeOut = DoScreenFadeOut
    local GetBlipInfoIdCoord = GetBlipInfoIdCoord
    local GetVehiclePedIsIn = GetVehiclePedIsIn

    local admin = lib.callback.await("kw:isUserAdmin", false)
    if not admin then
        return
    end
        local blipMarker = GetFirstBlipInfoId(8)
        if not DoesBlipExist(blipMarker) then
            KW.ShowNotification(TranslateCap("tpm_nowaypoint"), "error")
            return "marker"
        end

        -- Fade screen to hide how clients get teleported.
        DoScreenFadeOut(650)
        while not IsScreenFadedOut() do
            Wait(0)
        end

        local ped, coords = KW.PlayerData.ped, GetBlipInfoIdCoord(blipMarker)
        local vehicle = GetVehiclePedIsIn(ped, false)
        local oldCoords = GetEntityCoords(ped)

        -- Unpack coords instead of having to unpack them while iterating.
        -- 825.0 seems to be the max a player can reach while 0.0 being the lowest.
        local x, y, groundZ, Z_START = coords["x"], coords["y"], 850.0, 950.0
        local found = false
        FreezeEntityPosition(vehicle > 0 and vehicle or ped, true)

        for i = Z_START, 0, -25.0 do
            local z = i
            if (i % 2) ~= 0 then
                z = Z_START - i
            end

            NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
            local curTime = GetGameTimer()
            while IsNetworkLoadingScene() do
                if GetGameTimer() - curTime > 1000 then
                    break
                end
                Wait(0)
            end
            NewLoadSceneStop()
            SetPedCoordsKeepVehicle(ped, x, y, z)

            while not HasCollisionLoadedAroundEntity(ped) do
                RequestCollisionAtCoord(x, y, z)
                if GetGameTimer() - curTime > 1000 then
                    break
                end
                Wait(0)
            end

            -- Get ground coord. As mentioned in the natives, this only works if the client is in render distance.
            found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
            if found then
                Wait(0)
                SetPedCoordsKeepVehicle(ped, x, y, groundZ)
                break
            end
            Wait(0)
        end

        -- Remove black screen once the loop has ended.
        DoScreenFadeIn(650)
        FreezeEntityPosition(vehicle > 0 and vehicle or ped, false)

        if not found then
            -- If we can't find the coords, set the coords to the old ones.
            -- We don't unpack them before since they aren't in a loop and only called once.
            SetPedCoordsKeepVehicle(ped, oldCoords["x"], oldCoords["y"], oldCoords["z"] - 1.0)
            KW.ShowNotification(TranslateCap("tpm_success"), "success")
        end

        -- If Z coord was found, set coords in found coords.
        SetPedCoordsKeepVehicle(ped, x, y, groundZ)
        KW.ShowNotification(TranslateCap("tpm_success"), "success")
    end)

local noclip = false
local noclip_pos = vector3(0, 0, 70)
local heading = 0

local function noclipThread()
    while noclip do
        SetEntityCoordsNoOffset(KW.PlayerData.ped, noclip_pos.x, noclip_pos.y, noclip_pos.z, false, false, true)

        if IsControlPressed(1, 34) then
            heading = heading + 1.5
            if heading > 360 then
                heading = 0
            end

            SetEntityHeading(KW.PlayerData.ped, heading)
        end

        if IsControlPressed(1, 9) then
            heading = heading - 1.5
            if heading < 0 then
                heading = 360
            end

            SetEntityHeading(KW.PlayerData.ped, heading)
        end

        if IsControlPressed(1, 8) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(KW.PlayerData.ped, 0.0, 1.0, 0.0)
        end

        if IsControlPressed(1, 32) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(KW.PlayerData.ped, 0.0, -1.0, 0.0)
        end

        if IsControlPressed(1, 27) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(KW.PlayerData.ped, 0.0, 0.0, 1.0)
        end

        if IsControlPressed(1, 173) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(KW.PlayerData.ped, 0.0, 0.0, -1.0)
        end
        Wait(0)
    end
end

RegisterNetEvent("kw:noclip", function()
    local admin = lib.callback.await("kw:isUserAdmin", false)
    if not admin then
        return
    end

        if not noclip then
            noclip_pos = GetEntityCoords(KW.PlayerData.ped, false)
            heading = GetEntityHeading(KW.PlayerData.ped)
        end

        noclip = not noclip
        if noclip then
            CreateThread(noclipThread)
        end

        if noclip then
            KW.ShowNotification(TranslateCap("noclip_message", Translate("enabled")), "success")
        else
            KW.ShowNotification(TranslateCap("noclip_message", Translate("disabled")), "error")
        end
end)

RegisterNetEvent("kw:killPlayer", function()
    SetEntityHealth(KW.PlayerData.ped, 0)
end)

RegisterNetEvent("kw:repairPedVehicle", function()
    local ped = KW.PlayerData.ped
    local vehicle = GetVehiclePedIsIn(ped, false)
    SetVehicleEngineHealth(vehicle, 1000)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleFixed(vehicle)
    SetVehicleDirtLevel(vehicle, 0)
end)

RegisterNetEvent("kw:freezePlayer", function(input)
    if input == "freeze" then
        SetEntityCollision(KW.PlayerData.ped, false, false)
        FreezeEntityPosition(KW.PlayerData.ped, true)
        SetPlayerInvincible(KW.playerId, true)
    elseif input == "unfreeze" then
        SetEntityCollision(KW.PlayerData.ped, true, true)
        FreezeEntityPosition(KW.PlayerData.ped, false)
        SetPlayerInvincible(KW.playerId, false)
    end
end)

KW.RegisterClientCallback("kw:GetVehicleType", function(cb, model)
    cb(KW.GetVehicleTypeClient(model))
end)

KW.SecureNetEvent('kw:updatePlayerData', function(key, val)
	KW.SetPlayerData(key, val)
end)

AddStateBagChangeHandler(nil, nil, function(bagName, key, value)
    local playerId = PlayerId()
    if playerId == -1 then return end
    
    if bagName == ("player:%s"):format(GetPlayerServerId(playerId)) then
        local validKeys = {
            ["job"] = true,
            ["accounts"] = true,
            ["maxWeight"] = true,
            ["group"] = true,
            ["name"] = true,
            ["metadata"] = true,
            ["variables"] = true
        }
        
        if validKeys[key] then
            KW.SetPlayerData(key, value)
        end
    end
end)

---@param command string
KW.SecureNetEvent("kw:executeCommand", function(command)
    ExecuteCommand(command)
end)

AddEventHandler("onResourceStop", function(resource)
    if Core.Events[resource] then
        for i = 1, #Core.Events[resource] do
            RemoveEventHandler(Core.Events[resource][i])
        end
    end
end)
