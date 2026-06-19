Actions = {}
Actions._index = Actions

Actions.inVehicle = false
Actions.enteringVehicle = false
Actions.inPauseMenu = false
Actions.currentWeapon = false

function Actions:GetSeatPedIsIn()
    for i = -1, 16 do
        if GetPedInVehicleSeat(self.vehicle, i) == KW.PlayerData.ped then
            return i
        end
    end
    return -1
end

function Actions:GetVehicleData()
    if not DoesEntityExist(self.vehicle) then
        return
    end

    local vehicleModel = GetEntityModel(self.vehicle)
    local displayName = GetDisplayNameFromVehicleModel(vehicleModel)
    local netId = NetworkGetEntityIsNetworked(self.vehicle) and VehToNet(self.vehicle) or self.vehicle
    local plate = GetVehicleNumberPlateText(self.vehicle)

    return displayName, netId, plate
end

function Actions:SetVehicleStatus()
    KW.SetPlayerData("vehicle", self.vehicle)
    KW.SetPlayerData("seat", self.seat)
end

function Actions:TrackPedCoordsOnce()
    CreateThread(function()
        while not KW.IsPlayerLoaded() do
            Wait(250)
        end

        KW.PlayerData.coords = nil

        setmetatable(KW.PlayerData, {
            __index = function(_, key)
                if key ~= "coords" then
                    return
                end

                local coords = GetEntityCoords(KW.PlayerData.ped)

                return coords
            end
        })
    end)
end

function Actions:TrackPed()
    local playerPed = KW.PlayerData.ped
    local newPed = PlayerPedId()

    if playerPed ~= newPed then
        KW.SetPlayerData("ped", newPed)

        TriggerEvent("kw:playerPedChanged", newPed)

        if Config.EnableDebug then
            print("[DEBUG] Player ped changed:", newPed)
        end
    end
end

function Actions:TrackPauseMenu()
    local isActive = IsPauseMenuActive()

    if isActive ~= self.inPauseMenu then
        self.inPauseMenu = isActive
        TriggerEvent("kw:pauseMenuActive", isActive)

        if Config.EnableDebug then
            print("[DEBUG] Pause menu active:", isActive)
        end
    end
end

function Actions:EnterVehicle()
    self.seat = GetSeatPedIsTryingToEnter(KW.PlayerData.ped)

    local _, netId, plate = self:GetVehicleData()

    self.enteringVehicle = true
    TriggerEvent("kw:enteringVehicle", self.vehicle, plate, self.seat, netId)
    TriggerServerEvent("kw:enteringVehicle", plate, self.seat, netId)

    self:SetVehicleStatus()

    if Config.EnableDebug then
        print("[DEBUG] Entering vehicle:", self.vehicle, plate, self.seat, netId)
    end
end

function Actions:ResetVehicleData()
    self.enteringVehicle = false
    self.vehicle = false
    self.seat = false
    self.inVehicle = false

    self:SetVehicleStatus()
end

function Actions:EnterAborted()
    self:ResetVehicleData()

    TriggerEvent("kw:enteringVehicleAborted")
    TriggerServerEvent("kw:enteringVehicleAborted")

    if Config.EnableDebug then
        print("[DEBUG] Entering vehicle aborted")
    end
end

function Actions:WarpEnter()
    self.enteringVehicle = false
    self.inVehicle = true

    self.seat = self:GetSeatPedIsIn()

    local displayName, netId, plate = self:GetVehicleData()

    self:SetVehicleStatus()
    TriggerEvent("kw:enteredVehicle", self.vehicle, plate, self.seat, displayName, netId)
    TriggerServerEvent("kw:enteredVehicle", plate, self.seat, displayName, netId)

    if Config.EnableDebug then
        print("[DEBUG] Entered vehicle:", self.vehicle, plate, self.seat, displayName, netId)
    end
end

function Actions:ExitVehicle()
    local currentVehicle = GetVehiclePedIsIn(KW.PlayerData.ped, false)

    if currentVehicle ~= self.vehicle or KW.PlayerData.dead then
        local displayName, netId, plate = self:GetVehicleData()

        TriggerEvent("kw:exitedVehicle", self.vehicle, plate, self.seat, displayName, netId)
        TriggerServerEvent("kw:exitedVehicle", plate, self.seat, displayName, netId)

        if Config.EnableDebug then
            print("[DEBUG] Exited vehicle:", self.vehicle, plate, self.seat, displayName, netId)
        end

        self:ResetVehicleData()
    end
end

function Actions:TrackVehicle()
    if not self.inVehicle and not KW.PlayerData.dead then
        local tempVehicle = GetVehiclePedIsTryingToEnter(KW.PlayerData.ped)

        if DoesEntityExist(tempVehicle) and not self.enteringVehicle then
            self.vehicle = tempVehicle
            self:EnterVehicle()
        elseif not DoesEntityExist(tempVehicle) and not IsPedInAnyVehicle(KW.PlayerData.ped, true) and self.enteringVehicle then
            self:EnterAborted()
        elseif IsPedInAnyVehicle(KW.PlayerData.ped, false) then
            self.vehicle = GetVehiclePedIsIn(KW.PlayerData.ped, false)
            self:WarpEnter()
        end
    elseif self.inVehicle then
        self:ExitVehicle()
        self:TrackSeat()
    end
end

function Actions:TrackSeat()
    if not self.inVehicle then
        return
    end

    local newSeat = self:GetSeatPedIsIn()
    if newSeat ~= self.seat then
        self.seat = newSeat
        KW.SetPlayerData("seat", self.seat)
        TriggerEvent("kw:vehicleSeatChanged", self.seat)

        if Config.EnableDebug then
            print("[DEBUG] Vehicle seat changed:", self.seat)
        end
    end
end

function Actions:TrackWeapon()
    ---@type number|false
    local newWeapon = GetSelectedPedWeapon(KW.PlayerData.ped)
    newWeapon = newWeapon ~= `WEAPON_UNARMED` and newWeapon or false

    if newWeapon ~= self.currentWeapon then
        self.currentWeapon = newWeapon
        KW.SetPlayerData("weapon", self.currentWeapon)
        TriggerEvent("kw:weaponChanged", self.currentWeapon)

        if Config.EnableDebug then
            print("[DEBUG] Weapon changed:", self.currentWeapon)
        end
    end
end

function Actions:SlowLoop()
    CreateThread(function()
        while KW.PlayerLoaded do
            self:TrackPauseMenu()
            self:TrackVehicle()
            self:TrackWeapon()
            Wait(500)
        end
    end)
end

function Actions:PedLoop()
    CreateThread(function()
        while KW.PlayerLoaded do
            self:TrackPed()
            Wait(0)
        end
    end)
end

function Actions:Init()
    self:SlowLoop()
    self:PedLoop()
    self:TrackPedCoordsOnce()
end

Actions:Init()
