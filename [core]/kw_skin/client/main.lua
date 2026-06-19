Skin = {}
Skin._index = Skin

Skin.firstSpawn = true
Skin.zoomOffset = 0.0
Skin.camOffset = 0.0
Skin.heading = 90.0
Skin.customPI = math.pi / 180.0

function Skin:CalcualteHeading(angle)
    if angle > 360 then
        angle = angle - 360
    elseif angle < 0 then
        angle = angle + 360
    end
    angle = angle * self.customPI
    return angle
end

function Skin:CalcuatePosition(coords)

    local angle = self.heading * self.customPI
    local theta = {
        x = math.cos(angle),
        y = math.sin(angle),
    }

    local pos = {
        x = coords.x + (self.zoomOffset * theta.x),
        y = coords.y + (self.zoomOffset * theta.y),
    }

    local angleToLook = self:CalcualteHeading(self.heading - 140.0)

    local thetaToLook = {
        x = math.cos(angleToLook),
        y = math.sin(angleToLook),
    }

    local posToLook = {
        x = coords.x + (self.zoomOffset * thetaToLook.x),
        y = coords.y + (self.zoomOffset * thetaToLook.y),
    }
    return pos, posToLook
end

AddEventHandler("kw_skin:resetFirstSpawn", function()
    Skin.firstSpawn = true
    KW.PlayerLoaded = false
end)

AddEventHandler("kw_skin:playerRegistered", function()
    CreateThread(function()
        while not KW.PlayerLoaded do
            Wait(100)
        end

        if Skin.firstSpawn then
            local skin = lib.callback.await("kw_skin:getPlayerSkin", false)
            if skin == nil then
                exports["skinchanger"]:LoadSkin({ sex = 0 })
                Menu:Saveable()
            else
                exports["skinchanger"]:LoadSkin(skin)
            end

            Skin.firstSpawn = false
        end
    end)
end)

RegisterNetEvent("kw:playerLoaded", function(_, _, skin)
    KW.PlayerLoaded = true
    TriggerServerEvent("kw_skin:setWeight", skin)
end)

RegisterNetEvent("kw_skin:openMenu", function(submitCb, cancelCb)
    Menu:Open(submitCb, cancelCb, nil)
end)

RegisterNetEvent("kw_skin:openRestrictedMenu", function(submitCb, cancelCb, restrict)
    Menu:Open(submitCb, cancelCb, restrict)
end)

RegisterNetEvent("kw_skin:openSaveableMenu", function(submitCb, cancelCb)
    Menu:Saveable(submitCb, cancelCb, nil)
end)

RegisterNetEvent("kw_skin:openSaveableRestrictedMenu", function(submitCb, cancelCb, restrict)
    Menu:Saveable(submitCb, cancelCb, restrict)
end)

AddEventHandler("kw_skin:getLastSkin", function(cb)
    cb(Skin.Last)
end)

AddEventHandler("kw_skin:setLastSkin", function(skin)
    Skin.Last = skin
end)
