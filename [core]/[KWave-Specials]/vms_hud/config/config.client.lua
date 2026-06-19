local isStressUpdated = false
generateStress = function(vehicleSpeed) -- Stress generator when player rides in a vehicle without a seat belt
    Citizen.CreateThread(function()
        if not isStressUpdated then
            isStressUpdated = true
            local mySpeed = Config.UnitOfSpeed == 'kmh' and vehicleSpeed * 3.6 or vehicleSpeed * 2.236936
            local randomizer = math.random(1000)
            if mySpeed > Config.StressGeneratorMinSpeed and randomizer < 300 then
                if Config.Core == "KW" then
                    TriggerServerEvent('vms_hud:addStress', math.random(20, 50) * mySpeed / 10)
                elseif Config.Core == "QB-Core" then
                    TriggerServerEvent('vms_hud:addStress', math.random(2, 5) * mySpeed / 1000)
                end
            end
            Citizen.Wait(2000)
            isStressUpdated = false
        end
    end)
end

--    ___  __ __  ___         _ _  ___  _  ___  ___ 
--   | . \|  \  \| . |  ___  | | || . || ||  _]| __]
--   |  _/|     ||   | |___| | | || | || || [__| _] 
--   |_|  |_|_|_||_|_|       |__/ `___'|_|`___/|___]

RegisterNetEvent('pma-voice:setTalkingMode', function(range)
    if not Config.PMAVoiceRanges[range] then
        return print('PMA Voice ranges are not adjusted to used values.')
    end
    ChangeVoiceRange(Config.PMAVoiceRanges[range])
end)

RegisterNetEvent('SaltyChat_VoiceRangeChanged', function(range)
    if not Config.SaltyChatRanges[range] then
        return print('Salty Chat ranges are not adjusted to used values.')
    end
    ChangeVoiceRange(Config.SaltyChatRanges[range])
end)

RegisterNetEvent('mumble-voip:setHudMode', function(range)
    if not Config.MumbleVoipRanges[range] then
        return print('Mumble-Voip ranges are not adjusted to used values.')
    end
    ChangeVoiceRange(Config.MumbleVoipRanges[range])
end)

--    ___   ___   __  _
--   | __] / __]  \ \/ 
--   | _]  \__ \   \ \ 
--   |___] [___/ /_/\_\

RegisterNetEvent('kw:playerLoaded')
AddEventHandler('kw:playerLoaded', function(xPlayer, isNew, skin)
    local accounts = xPlayer.accounts
    for k, v in pairs(accounts) do
        if v.name == 'money' then
            SendNUIMessage({
                action = 'updateHud',
                cash = tostring(v.money)
            })
        elseif v.name == 'bank' then
            SendNUIMessage({
                action = 'updateHud',
                bank = tostring(v.money)
            })
        elseif v.name == 'black_money' then
            SendNUIMessage({
                action = 'updateHud',
                black_money = tostring(v.money)
            })
        end
    end
    if Config.EnablePlayerJob and xPlayer.job and xPlayer.job.label then
        SendNUIMessage({
            action = 'updateHud',
            job = xPlayer.job.label
        })
        if Config.EnablePlayerJobGrade and xPlayer.job.grade_label then
            SendNUIMessage({
                action = 'updateHud',
                job_grade = xPlayer.job.grade_label
            })
        end
    end
    -- if Config.EnablePlayerGang and xPlayer.job2 and xPlayer.job2.label then
    --     SendNUIMessage({
    --         action = 'updateHud',
    --         gang = xPlayer.job2.label
    --     })
    --     if Config.EnablePlayerGangGrade and xPlayer.job2.grade_label then
    --         SendNUIMessage({
    --             action = 'updateHud',
    --             gang_grade = xPlayer.job2.grade_label
    --         })
    --     end
    -- end
    loadPlayerMinimap()
    loadPlayerSpeedometer()
end)

AddStateBagChangeHandler('accounts', '', function(bagName, _, value, _, _)
    local ply = PlayerId()
    if bagName ~= ('player:%s'):format(GetPlayerServerId(ply)) then return end
    if not value then return end

    for _, account in ipairs(value) do
        if account.name == 'money' then
            SendNUIMessage({ action = 'updateHud', cash = tostring(account.money) })
        elseif account.name == 'bank' then
            SendNUIMessage({ action = 'updateHud', bank = tostring(account.money) })
        elseif account.name == 'black_money' then
            SendNUIMessage({ action = 'updateHud', black_money = tostring(account.money) })
        end
    end
end)

if Config.EnablePlayerJob then
    AddStateBagChangeHandler('job', '', function(bagName, _, value, _, _)
        local ply = PlayerId()
        if bagName ~= ('player:%s'):format(GetPlayerServerId(ply)) then return end
        if not value then return end
        local PlayerJob = value

        if PlayerJob and PlayerJob.label then
            SendNUIMessage({
                action = 'updateHud',
                job = PlayerJob.label
            })
            if Config.EnablePlayerJobGrade and PlayerJob.grade_label then
                SendNUIMessage({
                    action = 'updateHud',
                    job_grade = PlayerJob.grade_label
                })
            end
        end
    end)
end

-- if Config.EnablePlayerGang then -- THIS TRIGGER DOES NOT EXIST IN THE DEFAULT KW
--     RegisterNetEvent('kw:setJob2', function(PlayerGang)
--         if PlayerGang and PlayerGang.label then
--             SendNUIMessage({
--                 action = 'updateHud',
--                 gang = PlayerGang.label
--             })
--             if Config.EnablePlayerGangGrade and PlayerGang.grade_label then
--                 SendNUIMessage({
--                     action = 'updateHud',
--                     gang_grade = PlayerGang.grade_label
--                 })
--             end
--         end
--     end)
-- end

if Config.EnableCompanyBalance then
    RegisterNetEvent('kw_addonaccount:setMoney') -- kw_SOCIETY
    AddEventHandler('kw_addonaccount:setMoney', function(society, money)
        if KW.GetPlayerData().job and KW.GetPlayerData().job.grade_name == 'boss' and 'society_'..KW.GetPlayerData().job.name == society then
            exports['vms_hud']:UpdateCompanyMoney(tostring(money))
        end
    end)
end


--    ___   ___          ___   ___   ___  ___ 
--   / _ \ | _ )   __   / __| / _ \ | _ \| __|
--  | (_) || _ \  |__| | (__ | (_) ||   /| _| 
--   \__\_\|___/        \___| \___/ |_|_\|___|

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if PlayerData then
        SendNUIMessage({
            action = 'updateHud',
            cash = tostring(PlayerData.money['cash']),
            bank = tostring(PlayerData.money['bank']),
        })
        if Config.EnablePlayerJob and PlayerData.job and PlayerData.job.label then
            SendNUIMessage({
                action = 'updateHud',
                job = PlayerData.job.label
            })
            if Config.EnablePlayerJobGrade and PlayerData.job.grade and PlayerData.job.grade.name then
                SendNUIMessage({
                    action = 'updateHud',
                    job_grade = PlayerData.job.grade.name
                })
            end
        end
        if Config.EnablePlayerGang and PlayerData.gang and PlayerData.gang.label then
            SendNUIMessage({
                action = 'updateHud',
                gang = PlayerData.gang.label
            })
            if Config.EnablePlayerGangGrade and PlayerData.gang.grade and PlayerData.gang.grade.name then
                SendNUIMessage({
                    action = 'updateHud',
                    gang_grade = PlayerData.gang.grade.name
                })
            end
        end
    end
    loadPlayerMinimap()
    loadPlayerSpeedometer()
end)

if Config.EnablePlayerJob then
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(PlayerJob)
        if PlayerJob and PlayerJob.label then
            SendNUIMessage({
                action = 'updateHud',
                job = PlayerJob.label
            })
            if Config.EnablePlayerJobGrade and PlayerJob.grade and PlayerJob.grade.name then
                SendNUIMessage({
                    action = 'updateHud',
                    job_grade = PlayerJob.grade.name
                })
            end
        end
    end)
end

if Config.EnablePlayerGang then
    RegisterNetEvent('QBCore:Client:OnGangUpdate', function(PlayerGang)
        if PlayerGang and PlayerGang.label then
            SendNUIMessage({
                action = 'updateHud',
                gang = PlayerGang.label
            })
            if Config.EnablePlayerGangGrade and PlayerGang.grade and PlayerGang.grade.name then
                SendNUIMessage({
                    action = 'updateHud',
                    gang_grade = PlayerGang.grade.name
                })
            end
        end
    end)
end

RegisterNetEvent('hud:client:UpdateNeeds', function(hunger, thirst) -- Triggered in qb-core
    hungerStatus = hunger
    thirstStatus = thirst
end)

RegisterNetEvent('hud:client:OnMoneyChange', function(type, amount, isMinus)
    SendNUIMessage({
        action = 'updateHud',
        cash = tostring(QBCore.Functions.GetPlayerData().money['cash']),
        bank = tostring(QBCore.Functions.GetPlayerData().money['bank']),
    })
end)

if Config.EnableStressStatus then
    RegisterNetEvent('hud:client:UpdateStress', function(stress) -- Add this event with adding stress elsewhere
        stressStatus = stress
    end)
end


Citizen.CreateThread(function()
    while Config.EnableStressShooting do
        local ped = PlayerPedId()
        local status = IsPedShooting(ped)
        local silenced = IsPedCurrentWeaponSilenced(ped)
        if status and not silenced then
            TriggerServerEvent('vms_hud:addStress', math.random(2, 5))
            Citizen.Wait(2000)
        else
            Citizen.Wait(1)
        end
    end
end)

Citizen.CreateThread(function()
    while Config.EnableStressReducer do
        local ped = PlayerPedId()
        local status = IsPedStill(ped)
        local status_w = IsPedArmed(ped, 4)
        local status2 = IsPedWalking(ped)
        local status_v = IsPedInAnyVehicle(ped, false)
        if status and not status_w and not status_v and not GetPedStealthMovement(ped) then
            Citizen.Wait(15000)
            TriggerServerEvent("vms_hud:removeStress", 30)
            Citizen.Wait(15000)
        elseif status2 and not status_w and not GetPedStealthMovement(ped) then
            Citizen.Wait(15000)
            TriggerServerEvent("vms_hud:removeStress", 10)
            Citizen.Wait(15000)
        else
            Citizen.Wait(1)
        end
    end
end)

-- RegisterNetEvent('your_custom_seatbelt', function(toggle)
--     seatbelt = toggle
-- end)