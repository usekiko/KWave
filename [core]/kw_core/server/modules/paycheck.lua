function StartPayCheck()
    CreateThread(function()
        while true do
            Wait(Config.PaycheckInterval)
            for player, xPlayer in pairs(KW.Players) do
                local jobLabel = xPlayer.job.label
                local job = xPlayer.job.grade_name
                local onDuty = xPlayer.job.onDuty
                local salary = (job == "unemployed" or onDuty) and xPlayer.job.grade_salary or KW.Math.Round(xPlayer.job.grade_salary * Config.OffDutyPaycheckMultiplier)

                if xPlayer.paycheckEnabled then
                    if salary > 0 then
                        if job == "unemployed" then -- unemployed
                            xPlayer.addAccountMoney("bank", salary, "Welfare Check")
                            TriggerClientEvent("kw:showAdvancedNotification", player, TranslateCap("bank"), TranslateCap("received_paycheck"), TranslateCap("received_help", salary), "CHAR_BANK_MAZE", 9)
                            if Config.LogPaycheck then
                                KW.DiscordLogFields("Paycheck", "Paycheck - Unemployment Benefits", "green", {
                                    { name = "Player", value = xPlayer.name, inline = true },
                                    { name = "ID", value = xPlayer.source, inline = true },
                                    { name = "Amount", value = salary, inline = true },
                                })
                            end
                        elseif Config.EnableSocietyPayouts then -- possibly a society
                            TriggerEvent("kw_society:getSociety", xPlayer.job.name, function(society)
                                if society ~= nil then -- verified society
                                    TriggerEvent("kw_addonaccount:getSharedAccount", society.account, function(account)
                                        if account.money >= salary then -- does the society money to pay its employees?
                                            xPlayer.addAccountMoney("bank", salary, "Paycheck")
                                            account.removeMoney(salary)
                                            if Config.LogPaycheck then
                                                KW.DiscordLogFields("Paycheck", "Paycheck - " .. jobLabel, "green", {
                                                    { name = "Player", value = xPlayer.name, inline = true },
                                                    { name = "ID", value = xPlayer.source, inline = true },
                                                    { name = "Amount", value = salary, inline = true },
                                                })
                                            end

                                            TriggerClientEvent("kw:showAdvancedNotification", player, TranslateCap("bank"), TranslateCap("received_paycheck"), TranslateCap("received_salary", salary), "CHAR_BANK_MAZE", 9)
                                        else
                                            TriggerClientEvent("kw:showAdvancedNotification", player, TranslateCap("bank"), "", TranslateCap("company_nomoney"), "CHAR_BANK_MAZE", 1)
                                        end
                                    end)
                                else -- not a society
                                    xPlayer.addAccountMoney("bank", salary, "Paycheck")
                                    if Config.LogPaycheck then
                                        KW.DiscordLogFields("Paycheck", "Paycheck - " .. jobLabel, "green", {
                                            { name = "Player", value = xPlayer.name, inline = true },
                                            { name = "ID", value = xPlayer.source, inline = true },
                                            { name = "Amount", value = salary, inline = true },
                                        })
                                    end
                                    TriggerClientEvent("kw:showAdvancedNotification", player, TranslateCap("bank"), TranslateCap("received_paycheck"), TranslateCap("received_salary", salary), "CHAR_BANK_MAZE", 9)
                                end
                            end)
                        else -- generic job
                            xPlayer.addAccountMoney("bank", salary, "Paycheck")
                            if Config.LogPaycheck then
                                KW.DiscordLogFields("Paycheck", "Paycheck - Generic", "green", {
                                    { name = "Player", value = xPlayer.name, inline = true },
                                    { name = "ID", value = xPlayer.source, inline = true },
                                    { name = "Amount", value = salary, inline = true },
                                })
                            end
                            TriggerClientEvent("kw:showAdvancedNotification", player, TranslateCap("bank"), TranslateCap("received_paycheck"), TranslateCap("received_salary", salary), "CHAR_BANK_MAZE", 9)
                        end
                    end
                end
            end
        end
    end)
end
