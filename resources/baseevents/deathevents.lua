local hasBeenDead = false
local diedAt = nil

AddEventHandler('gameEventTriggered', function(eventName, args)
    if eventName == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local culprit = args[2]
        local isFatal = args[6] == 1
        local weaponHash = args[7]
        
        local ped = PlayerPedId()
        if victim == ped and isFatal then
            if not diedAt then diedAt = GetGameTimer() end
            hasBeenDead = true
            
            local killer = culprit
            local killerweapon = weaponHash
            local killerentitytype = GetEntityType(killer)
            local killertype = -1
            local killerinvehicle = false
            local killervehiclename = ''
            local killervehicleseat = 0
            
            if killerentitytype == 1 then
                killertype = GetPedType(killer)
                if IsPedInAnyVehicle(killer, false) == 1 then
                    killerinvehicle = true
                    local veh = GetVehiclePedIsUsing(killer)
                    if veh > 0 then
                        killervehiclename = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
                        killervehicleseat = GetPedVehicleSeat(killer, veh)
                    end
                else 
                    killerinvehicle = false
                end
            end
            
            local killerid = -1
            if killer ~= ped and killer ~= 0 and killer ~= -1 then
                killerid = GetPlayerByEntityID(killer) or -1
            end
            
            if killer == ped or killer == -1 or killer == 0 then
                TriggerEvent('baseevents:onPlayerDied', killertype, { table.unpack(GetEntityCoords(ped)) })
                TriggerServerEvent('baseevents:onPlayerDied', killertype, { table.unpack(GetEntityCoords(ped)) })
            else
                TriggerEvent('baseevents:onPlayerKilled', killerid, {killertype=killertype, weaponhash = killerweapon, killerinveh=killerinvehicle, killervehseat=killervehicleseat, killervehname=killervehiclename, killerpos={table.unpack(GetEntityCoords(ped))}})
                TriggerServerEvent('baseevents:onPlayerKilled', killerid, {killertype=killertype, weaponhash = killerweapon, killerinveh=killerinvehicle, killervehseat=killervehicleseat, killervehname=killervehiclename, killerpos={table.unpack(GetEntityCoords(ped))}})
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        if hasBeenDead and not IsPedFatallyInjured(ped) then
            hasBeenDead = false
            diedAt = nil
        elseif hasBeenDead and diedAt and (GetGameTimer() - diedAt) > 0 then
            TriggerEvent('baseevents:onPlayerWasted', { table.unpack(GetEntityCoords(ped)) })
            TriggerServerEvent('baseevents:onPlayerWasted', { table.unpack(GetEntityCoords(ped)) })
            diedAt = nil -- Prevent spamming the event
        end
    end
end)

function GetPlayerByEntityID(id)
    for i=0,255 do
        if NetworkIsPlayerActive(i) and GetPlayerPed(i) == id then
            return GetPlayerServerId(i)
        end
    end
    return nil
end

function GetPedVehicleSeat(ped, vehicle)
    for i=-2,GetVehicleMaxNumberOfPassengers(vehicle) do
        if(GetPedInVehicleSeat(vehicle, i) == ped) then return i end
    end
    return -2
end
