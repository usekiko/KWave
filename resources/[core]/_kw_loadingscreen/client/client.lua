local ClientLoadKW = false

AddEventHandler("playerSpawned", function()
    if not ClientLoadKW then
        ShutdownLoadingScreenNui()
        ClientLoadKW = true
        if Config.Fade then
            DoScreenFadeOut(0)
            Wait(3000)
            DoScreenFadeIn(2500)
        end
    end
end)
