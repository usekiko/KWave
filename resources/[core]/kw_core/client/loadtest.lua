RegisterCommand('kw_loadtest', function(source, args, rawCommand)
    local testType = args[1]
    
    if testType == "spam" then
        print("[DTF LoadTest] Simulating 50 rapid event payloads...")
        CreateThread(function()
            for i = 1, 50 do
                TriggerServerEvent('kw:updateWeaponAmmo', 'WEAPON_PISTOL', 100)
            end
            print("[DTF LoadTest] 50 events fired. Check server console for Guard block messages.")
        end)
        
    elseif testType == "economy" then
        print("[DTF LoadTest] Simulating 50 simultaneous $100 withdrawals (Atomic Test)...")
        CreateThread(function()
            for i = 1, 50 do
                -- We use a raw callback to simulate 50 async requests at the exact same millisecond
                TriggerServerEvent('kw:testAtomicWithdraw')
            end
            print("[DTF LoadTest] 50 withdrawal requests sent simultaneously.")
        end)
    else
        print("Usage: /kw_loadtest [spam | economy]")
    end
end, false)
