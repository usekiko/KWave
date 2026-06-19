Death = {}
Death._index = Death

function Death:ResetValues()
    self.killerEntity = nil
    self.deathCause = nil
    self.killerId = nil
    self.killerServerId = nil
end

function Death:ByPlayer()
    local victimCoords = GetEntityCoords(KW.PlayerData.ped)
    local killerCoords = GetEntityCoords(self.killerEntity)
    local distance = #(victimCoords - killerCoords)

    local data = {
        victimCoords = { x = KW.Math.Round(victimCoords.x, 1), y = KW.Math.Round(victimCoords.y, 1), z = KW.Math.Round(victimCoords.z, 1) },
        killerCoords = { x = KW.Math.Round(killerCoords.x, 1), y = KW.Math.Round(killerCoords.y, 1), z = KW.Math.Round(killerCoords.z, 1) },

        killedByPlayer = true,
        deathCause = self.deathCause,
        distance = KW.Math.Round(distance, 1),

        killerServerId = self.killerServerId,
        killerClientId = self.killerId,
    }

    TriggerEvent("kw:onPlayerDeath", data)
    TriggerServerEvent("kw:onPlayerDeath", data)
end

function Death:Natural()
    local coords = GetEntityCoords(KW.PlayerData.ped)

    local data = {
        victimCoords = { x = KW.Math.Round(coords.x, 1), y = KW.Math.Round(coords.y, 1), z = KW.Math.Round(coords.z, 1) },

        killedByPlayer = false,
        deathCause = self.deathCause,
    }

    TriggerEvent("kw:onPlayerDeath", data)
    TriggerServerEvent("kw:onPlayerDeath", data)
end

function Death:Died()
    self.killerEntity = GetPedSourceOfDeath(KW.PlayerData.ped)
    self.deathCause = GetPedCauseOfDeath(KW.PlayerData.ped)
    self.killerId = NetworkGetPlayerIndexFromPed(self.killerEntity)
    self.killerServerId = GetPlayerServerId(self.killerId)

    local isActive = NetworkIsPlayerActive(self.killerId)

    if self.killerEntity ~= KW.PlayerData.ped and self.killerId and isActive then
        self:ByPlayer()
    else
        self:Natural()
    end

    self:ResetValues()
end

AddEventHandler("kw:onPlayerSpawn", function()
    Citizen.CreateThreadNow(function()
        while not KW.PlayerLoaded do Wait(0) end

        while KW.PlayerLoaded and not KW.PlayerData.dead do
            if DoesEntityExist(KW.PlayerData.ped) and (IsPedDeadOrDying(KW.PlayerData.ped, true) or IsPedFatallyInjured(KW.PlayerData.ped)) then
                Death:Died()
                break
            end
            Citizen.Wait(250)
        end
    end)
end)
