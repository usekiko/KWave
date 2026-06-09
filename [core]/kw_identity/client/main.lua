local loadingScreenFinished = false
local ready = false
local guiEnabled = false
local timecycleModifier = "hud_def_blur"

KW.SecureNetEvent("kw_identity:alreadyRegistered", function()
    while not loadingScreenFinished do
        Wait(100)
    end
    TriggerEvent("kw_skin:playerRegistered")
end)

KW.SecureNetEvent("kw_identity:setPlayerData", function(data)
    SetTimeout(1, function()
        KW.SetPlayerData("name", ("%s %s"):format(data.firstName, data.lastName))
        KW.SetPlayerData("firstName", data.firstName)
        KW.SetPlayerData("lastName", data.lastName)
        KW.SetPlayerData("dateofbirth", data.dateOfBirth)
        KW.SetPlayerData("sex", data.sex)
        KW.SetPlayerData("height", data.height)
    end)
end)

AddEventHandler("kw:loadingScreenOff", function()
    loadingScreenFinished = true
end)

RegisterNUICallback("ready", function(_, cb)
    ready = true
    cb(1)
end)

function setGuiState(state)
        SetNuiFocus(state, state)
        guiEnabled = state

        if state then
            SetTimecycleModifier(timecycleModifier)
        else
            ClearTimecycleModifier()
        end

        SendNUIMessage({ type = "enableui", enable = state })
end

RegisterNetEvent("kw_identity:showRegisterIdentity", function()
        TriggerEvent("kw_skin:resetFirstSpawn")
        while not (ready and loadingScreenFinished) do
            print("Waiting for kw_identity NUI..")
            Wait(100)
        end
        if not KW.PlayerData.dead then
            setGuiState(true)
        end
end)

RegisterNUICallback("register", function(data, cb)
        if not guiEnabled then
            return
        end

        KW.TriggerServerCallback("kw_identity:registerIdentity", function(callback)
            if not callback then
                return
            end

            KW.ShowNotification(TranslateCap("thank_you_for_registering"))
            setGuiState(false)

            if not KW.GetConfig().Multichar then
                TriggerEvent("kw_skin:playerRegistered")
            end
        end, data)
        cb(1)
end)
