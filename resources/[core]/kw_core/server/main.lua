SetMapName("San Andreas")
SetGameType("KW Legacy")

local oneSyncState = GetConvar("onesync", "off")
local Guard = require 'server.modules.guard'
local newPlayer = "INSERT INTO users (accounts, identifier, ssn, \"group\") VALUES (?, ?, ?, ?)"
local loadPlayer = "SELECT accounts, ssn, job, job_grade, \"group\", position, inventory, skin, loadout, metadata"

if Config.Multichar and Config.StartingInventoryItems then
    newPlayer = "INSERT INTO users (accounts, identifier, ssn, \"group\", firstname, lastname, dateofbirth, sex, height, inventory) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
elseif Config.Multichar then
    newPlayer = "INSERT INTO users (accounts, identifier, ssn, \"group\", firstname, lastname, dateofbirth, sex, height) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
elseif Config.StartingInventoryItems then
    newPlayer = "INSERT INTO users (accounts, identifier, ssn, \"group\", inventory) VALUES (?, ?, ?, ?, ?)"
end

if Config.Multichar or Config.Identity then
    loadPlayer = loadPlayer .. ", firstname, lastname, dateofbirth, sex, height"
end

loadPlayer = loadPlayer .. " FROM users WHERE identifier = ?"

local function createKWPlayer(identifier, playerId, data)
    local accounts = {}

    for account, money in pairs(Config.StartingAccountMoney) do
        accounts[account] = money
    end

    local defaultGroup = "user"
    if Core.IsPlayerAdmin(playerId) then
        print(("[^2INFO^0] Player ^5%s^0 Has been granted admin permissions via ^5Ace Perms^7."):format(playerId))
        defaultGroup = "admin"
    end
    local parameters = Config.Multichar and
        { json.encode(accounts), identifier, Core.generateSSN(), defaultGroup, data.firstname, data.lastname, data.dateofbirth, data.sex, data.height }
        or { json.encode(accounts), identifier, Core.generateSSN(), defaultGroup }

    if Config.StartingInventoryItems then
        table.insert(parameters, json.encode(Config.StartingInventoryItems))
    end

    PostgreSQL.prepare(newPlayer, parameters, function()
        loadKWPlayer(identifier, playerId, true)
    end)
end


local function onPlayerJoined(playerId)
    local identifier = KW.GetIdentifier(playerId)
    if not identifier then
        return DropPlayer(playerId, "there was an error loading your character!\nError code: identifier-missing-ingame\n\nThe cause of this error is not known, your identifier could not be found. Please come back later or report this problem to the server administration team.")
    end

    if KW.GetPlayerFromIdentifier(identifier) then
        DropPlayer(
            playerId,
            ("there was an error loading your character!\nError code: identifier-active-ingame\n\nThis error is caused by a player on this server who has the same identifier as you have. Make sure you are not playing on the same Rockstar account.\n\nYour Rockstar identifier: %s"):format(
                identifier
            )
        )
    else
        local result = PostgreSQL.scalar.await("SELECT 1 FROM users WHERE identifier = ?", { identifier })
        if result then
            loadKWPlayer(identifier, playerId, false)
        else
            createKWPlayer(identifier, playerId)
        end
    end
end

---@param playerId number
---@param reason string
---@param cb function?
local function onPlayerDropped(playerId, reason, cb)
    local p = not cb and promise:new()
    local function resolve()
        if cb then
            return cb()
        elseif(p) then
            return p:resolve()
        end
    end

    local xPlayer = KW.GetPlayerFromId(playerId)
    if not xPlayer then
        return resolve()
    end

    TriggerEvent("kw:playerDropped", playerId, reason)
    local job = xPlayer.getJob().name
    local currentJob = Core.JobsPlayerCount[job]
    Core.JobsPlayerCount[job] = ((currentJob and currentJob > 0) and currentJob or 1) - 1

    GlobalState[("%s:count"):format(job)] = Core.JobsPlayerCount[job]

    Core.SavePlayer(xPlayer, function()
        GlobalState["playerCount"] = GlobalState["playerCount"] - 1
        KW.Players[playerId] = nil
        Core.playersByIdentifier[xPlayer.identifier] = nil

        resolve()
    end)

    if p then
        return Citizen.Await(p)
    end
end
AddEventHandler("kw:onPlayerDropped", onPlayerDropped)


if Config.Multichar then
    AddEventHandler("kw:onPlayerJoined", function(src, char, data)
        require('server.modules.ready').OnJobsReady(function()
            if not KW.Players[src] then
                local identifier = char .. ":" .. KW.GetIdentifier(src)
                if data then
                    createKWPlayer(identifier, src, data)
                else
                    loadKWPlayer(identifier, src, false)
                end
            end
        end)
    end)
else
    RegisterNetEvent("kw:onPlayerJoined", function()
        local _source = source
        if not Guard.RateLimit(_source, "onPlayerJoined", 1) then return end
        require('server.modules.ready').OnJobsReady(function()
            if not KW.Players[_source] then
                onPlayerJoined(_source)
            end
        end)
    end)
end

if not Config.Multichar then
    AddEventHandler("playerConnecting", function(_, _, deferrals)
        local playerId = source
        deferrals.defer()
        Wait(0) -- Required
        local identifier
        local correctLicense, _ = pcall(function ()
            identifier = KW.GetIdentifier(playerId)
        end)

        -- luacheck: ignore
        if not SetEntityOrphanMode then
            return deferrals.done(("[KW] KW Requires a minimum Artifact version of 10188, Please update your server."))
        end

        if oneSyncState == "off" or oneSyncState == "legacy" then
            return deferrals.done(("[KW] KW Requires Onesync Infinity to work. This server currently has Onesync set to: %s"):format(oneSyncState))
        end

        if not Core.DatabaseConnected then
            return deferrals.done("[KW] PostgreSQL Was Unable To Connect to your database. Please make sure it is turned on and correctly configured in your server.cfg")
        end

        if not identifier or not correctLicense then
            if GetResourceState("kw_identity") ~= "started" then
                return deferrals.done("[KW] There was an error loading your character!\nError code: identifier-missing\n\nThe cause of this error is not known, your identifier could not be found. Please come back later or report this problem to the server administration team.")
            end
        end

        local xPlayer = KW.GetPlayerFromIdentifier(identifier)

        if not xPlayer then
            return deferrals.done()
        end

        if GetPlayerPing(xPlayer.source --[[@as string]]) > 0 then
            return deferrals.done(
                ("[KW] There was an error loading your character!\nError code: identifier-active\n\nThis error is caused by a player on this server who has the same identifier as you have. Make sure you are not playing on the same account.\n\nYour identifier: %s"):format(identifier)
            )
        end

        deferrals.update(("[KW] Cleaning stale player entry..."):format(identifier))
        onPlayerDropped(xPlayer.source, "kw_stale_player_obj")
        deferrals.done()
    end)
end

function loadKWPlayer(identifier, playerId, isNew)
    local userData = {
        accounts = {},
        inventory = {},
        loadout = {},
        weight = 0,
        name = GetPlayerName(playerId),
        identifier = identifier,
        firstName = "John",
        lastName = "Doe",
        dateofbirth = "01/01/2000",
        height = 120,
        dead = false,
    }

    local result = PostgreSQL.prepare.await(loadPlayer, { identifier })

    -- Accounts
    local accounts = result.accounts
    accounts = type(accounts) == "string" and json.decode(accounts) or accounts or {}

    for account, data in pairs(Config.Accounts) do
        data.round = data.round or data.round == nil

        local index = #userData.accounts + 1
        userData.accounts[index] = {
            name = account,
            money = accounts[account] or Config.StartingAccountMoney[account] or 0,
            label = data.label,
            round = data.round,
            index = index,
        }
    end

    -- SSN
    userData.ssn = result.ssn

    -- Job
    local job, grade = result.job, tostring(result.job_grade)

    if not KW.DoesJobExist(job, grade) then
        print(("[^3WARNING^7] Ignoring invalid job for ^5%s^7 [job: ^5%s^7, grade: ^5%s^7]"):format(identifier, job, grade))
        job, grade = "unemployed", "0"
    end

    local jobObject, gradeObject = KW.Jobs[job], KW.Jobs[job].grades[grade]

    userData.job = {
        id = jobObject.id,
        name = jobObject.name,
        label = jobObject.label,
        type = jobObject.type,

        grade = tonumber(grade),
        grade_name = gradeObject.name,
        grade_label = gradeObject.label,
        grade_salary = gradeObject.salary,

        skin_male = type(gradeObject.skin_male) == "string" and json.decode(gradeObject.skin_male) or gradeObject.skin_male or {},
        skin_female = type(gradeObject.skin_female) == "string" and json.decode(gradeObject.skin_female) or gradeObject.skin_female or {},
    }

    -- Inventory
    if not Config.CustomInventory then
        local inventory = type(result.inventory) == "string" and json.decode(result.inventory) or result.inventory or {}

        for name, item in pairs(KW.Items) do
            local count = inventory[name] or 0
            userData.weight += (count * item.weight)

            userData.inventory[#userData.inventory + 1] = {
                name = name,
                count = count,
                label = item.label,
                weight = item.weight,
                usable = Core.UsableItemsCallbacks[name] ~= nil,
                rare = item.rare,
                canRemove = item.canRemove,
            }
        end
        table.sort(userData.inventory, function(a, b)
            return a.label < b.label
        end)
    elseif result.inventory and result.inventory ~= "" then
        userData.inventory = type(result.inventory) == "string" and json.decode(result.inventory) or result.inventory or {}
    end

    -- Group
    if result.group then
        if result.group == "superadmin" then
            userData.group = "admin"
            print("[^3WARNING^7] ^5Superadmin^7 detected, setting group to ^5admin^7")
        else
            userData.group = result.group
        end
    else
        userData.group = "user"
    end

    -- Loadout
    if not Config.CustomInventory then
        if result.loadout and result.loadout ~= "" then

            local loadout = type(result.loadout) == "string" and json.decode(result.loadout) or result.loadout or {}
            for name, weapon in pairs(loadout) do
                local label = KW.GetWeaponLabel(name)

                if label then
                    userData.loadout[#userData.loadout + 1] = {
                        name = name,
                        ammo = weapon.ammo,
                        label = label,
                        components = weapon.components or {},
                        tintIndex = weapon.tintIndex or 0,
                    }
                end
            end
        end
    end

    -- Position
    userData.coords = (type(result.position) == "string" and json.decode(result.position) or result.position) or Config.DefaultSpawns[KW.Math.Random(1,#Config.DefaultSpawns)]

    -- Skin
    userData.skin = (type(result.skin) == "string" and json.decode(result.skin) or result.skin) or { sex = userData.sex == "f" and 1 or 0 }

    -- Metadata
    userData.metadata = type(result.metadata) == "string" and json.decode(result.metadata) or result.metadata or {}

    -- xPlayer Creation
    local xPlayer = CreateExtendedPlayer(playerId, identifier, userData.ssn, userData.group, userData.accounts, userData.inventory, userData.weight, userData.job, userData.loadout, GetPlayerName(playerId), userData.coords, userData.metadata)

    GlobalState["playerCount"] = GlobalState["playerCount"] + 1
    KW.Players[playerId] = xPlayer
    Core.playersByIdentifier[identifier] = xPlayer

    -- Identity
    if result.firstname and result.firstname ~= "" then
        userData.firstName = result.firstname
        userData.lastName = result.lastname

        local name = ("%s %s"):format(result.firstname, result.lastname)
        userData.name = name

        xPlayer.set("firstName", result.firstname)
        xPlayer.set("lastName", result.lastname)
        xPlayer.setName(name)

        if result.dateofbirth then
            userData.dateofbirth = result.dateofbirth
            xPlayer.set("dateofbirth", result.dateofbirth)
        end
        if result.sex then
            userData.sex = result.sex
            xPlayer.set("sex", result.sex)
        end
        if result.height then
            userData.height = result.height
            xPlayer.set("height", result.height)
        end
    end

    TriggerEvent("kw:playerLoaded", playerId, xPlayer, isNew)
    userData.money = xPlayer.getMoney()
    userData.maxWeight = xPlayer.getMaxWeight()
    userData.variables = xPlayer.variables or {}
    xPlayer.triggerEvent("kw:playerLoaded", userData, isNew, userData.skin)

    if not Config.CustomInventory then
        xPlayer.triggerEvent("kw:createMissingPickups", Core.Pickups)
    elseif setPlayerInventory then
        setPlayerInventory(playerId, xPlayer, userData.inventory, isNew)
    end

    xPlayer.triggerEvent("kw:registerSuggestions", Core.RegisteredCommands)
    print(('[^2INFO^0] Player ^5"%s"^0 has connected to the server. ID: ^5%s^7'):format(xPlayer.getName(), playerId))
end

AddEventHandler("chatMessage", function(playerId, _, message)
    local xPlayer = KW.GetPlayerFromId(playerId)
    if xPlayer and message:sub(1, 1) == "/" and playerId > 0 then
        CancelEvent()
        local commandName = message:sub(1):gmatch("%w+")()
        xPlayer.showNotification(TranslateCap("commanderror_invalidcommand", commandName))
    end
end)

---@param reason string
AddEventHandler("playerDropped", function(reason)
    onPlayerDropped(source --[[@as number]], reason)
end)

AddEventHandler("kw:playerLoaded", function(_, xPlayer, isNew)
    local job = xPlayer.getJob().name
    local jobKey = ("%s:count"):format(job)

    Core.JobsPlayerCount[job] = (Core.JobsPlayerCount[job] or 0) + 1
    GlobalState[jobKey] = Core.JobsPlayerCount[job]
    if isNew then
        Player(xPlayer.source).state:set('isNew', true, false)
    end
end)

AddEventHandler("kw:setJob", function(_, job, lastJob)
    local lastJobKey = ("%s:count"):format(lastJob.name)
    local jobKey = ("%s:count"):format(job.name)
    local currentLastJob = Core.JobsPlayerCount[lastJob.name]

    Core.JobsPlayerCount[lastJob.name] = ((currentLastJob and currentLastJob > 0) and currentLastJob or 1) - 1
    Core.JobsPlayerCount[job.name] = (Core.JobsPlayerCount[job.name] or 0) + 1

    GlobalState[lastJobKey] = Core.JobsPlayerCount[lastJob.name]
    GlobalState[jobKey] = Core.JobsPlayerCount[job.name]
end)

AddEventHandler("kw:playerLogout", function(playerId, cb)
    onPlayerDropped(playerId, "kw_player_logout", cb)
    TriggerClientEvent("kw:onPlayerLogout", playerId)
end)

if not Config.CustomInventory then
    RegisterNetEvent("kw:updateWeaponAmmo", function(weaponName, ammoCount)
        local playerId = source
        if not Guard.RateLimit(playerId, "updateWeaponAmmo", 10) then return end
        if not Guard.Validate(playerId, {
            { type = "string", maxlen = 64, notempty = true },
            { type = "integer", min = 0, max = 9999 }
        }, { weaponName, ammoCount }) then return end

        local xPlayer = KW.GetPlayerFromId(playerId)

        if xPlayer then
            xPlayer.updateWeaponAmmo(weaponName, ammoCount)
        end
    end)

    RegisterNetEvent("kw:giveInventoryItem", function(target, itemType, itemName, itemCount)
        local playerId = source
        if not Guard.RateLimit(playerId, "giveInventoryItem", 5) then return end
        if not Guard.Validate(playerId, {
            { type = "integer", min = 1 },
            { type = "string", enum = {"item_standard", "item_account", "item_weapon", "item_ammo"} },
            { type = "string", maxlen = 64, notempty = true },
            { type = "integer", min = 1, max = 1000000 }
        }, { target, itemType, itemName, itemCount }) then return end

        if type(target) ~= "number" or math.type(target) ~= "integer" then
            print(("[^3WARNING^7] Player Detected Cheating (Invalid Target): ^5%s^7"):format(GetPlayerName(playerId)))
            return
        end
        local sourceXPlayer = KW.GetPlayerFromId(playerId)
        local targetXPlayer = KW.GetPlayerFromId(target)
        local distance = #(GetEntityCoords(GetPlayerPed(playerId)) - GetEntityCoords(GetPlayerPed(target)))
        if not sourceXPlayer or not targetXPlayer or distance > Config.DistanceGive then
            print(("[^3WARNING^7] Player Detected Cheating: ^5%s^7"):format(GetPlayerName(playerId)))
            return
        end

        if type(itemCount) ~= "number" or math.type(itemCount) ~= "integer" or itemCount < 1 then
            return sourceXPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
        end

        if itemType == "item_standard" then
            local sourceItem = sourceXPlayer.getInventoryItem(itemName)

            if not sourceItem then
                return
            end

            if itemCount < 1 or sourceItem.count < itemCount then
                return sourceXPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
            end

            if not targetXPlayer.canCarryItem(itemName, itemCount) then
                return sourceXPlayer.showNotification(TranslateCap("ex_inv_lim", targetXPlayer.name))
            end

            sourceXPlayer.removeInventoryItem(itemName, itemCount)
            targetXPlayer.addInventoryItem(itemName, itemCount)

            sourceXPlayer.showNotification(TranslateCap("gave_item", itemCount, sourceItem.label, targetXPlayer.name))
            targetXPlayer.showNotification(TranslateCap("received_item", itemCount, sourceItem.label, sourceXPlayer.name))
        elseif itemType == "item_account" then
            if itemCount < 1 or sourceXPlayer.getAccount(itemName).money < itemCount then
                return sourceXPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            sourceXPlayer.removeAccountMoney(itemName, itemCount, "Gave to " .. targetXPlayer.name)
            targetXPlayer.addAccountMoney(itemName, itemCount, "Received from " .. sourceXPlayer.name)

            sourceXPlayer.showNotification(TranslateCap("gave_account_money", KW.Math.GroupDigits(itemCount), Config.Accounts[itemName].label, targetXPlayer.name))
            targetXPlayer.showNotification(TranslateCap("received_account_money", KW.Math.GroupDigits(itemCount), Config.Accounts[itemName].label, sourceXPlayer.name))
        elseif itemType == "item_weapon" then
            if not sourceXPlayer.hasWeapon(itemName) then
                return
            end

            local weaponLabel = KW.GetWeaponLabel(itemName)
            if targetXPlayer.hasWeapon(itemName) then
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_hasalready", targetXPlayer.name, weaponLabel))
                targetXPlayer.showNotification(TranslateCap("received_weapon_hasalready", sourceXPlayer.name, weaponLabel))
                return
            end

            local _, weapon = sourceXPlayer.getWeapon(itemName)
            if not weapon then
                return
            end

            local _, weaponObject = KW.GetWeapon(itemName)
            itemCount = weapon.ammo
            local weaponComponents = KW.Table.Clone(weapon.components)
            local weaponTint = weapon.tintIndex

            if weaponTint then
                targetXPlayer.setWeaponTint(itemName, weaponTint)
            end

            if weaponComponents then
                for _, v in pairs(weaponComponents) do
                    targetXPlayer.addWeaponComponent(itemName, v)
                end
            end

            sourceXPlayer.removeWeapon(itemName)
            targetXPlayer.addWeapon(itemName, itemCount)

            if weaponObject.ammo and itemCount > 0 then
                local ammoLabel = weaponObject.ammo.label
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_withammo", weaponLabel, itemCount, ammoLabel, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_withammo", weaponLabel, itemCount, ammoLabel, sourceXPlayer.name))
            else
                sourceXPlayer.showNotification(TranslateCap("gave_weapon", weaponLabel, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon", weaponLabel, sourceXPlayer.name))
            end
        elseif itemType == "item_ammo" then
            if not sourceXPlayer.hasWeapon(itemName) then
                return
            end

            local _, weapon = sourceXPlayer.getWeapon(itemName)
            if not weapon then
                return
            end

            if not targetXPlayer.hasWeapon(itemName) then
                sourceXPlayer.showNotification(TranslateCap("gave_weapon_noweapon", targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_noweapon", sourceXPlayer.name, weapon.label))
                return
            end

            local _, weaponObject = KW.GetWeapon(itemName)

            if not weaponObject.ammo then return end

            local ammoLabel = weaponObject.ammo.label
            if weapon.ammo >= itemCount then
                sourceXPlayer.removeWeaponAmmo(itemName, itemCount)
                targetXPlayer.addWeaponAmmo(itemName, itemCount)

                sourceXPlayer.showNotification(TranslateCap("gave_weapon_ammo", itemCount, ammoLabel, weapon.label, targetXPlayer.name))
                targetXPlayer.showNotification(TranslateCap("received_weapon_ammo", itemCount, ammoLabel, weapon.label, sourceXPlayer.name))
            end
        end
    end)

    RegisterNetEvent("kw:removeInventoryItem", function(itemType, itemName, itemCount)
        local playerId = source
        if not Guard.RateLimit(playerId, "removeInventoryItem", 5) then return end
        if not Guard.Validate(playerId, {
            { type = "string", enum = {"item_standard", "item_account", "item_weapon", "item_ammo"} },
            { type = "string", maxlen = 64, notempty = true },
            { type = "integer", min = 1, max = 1000000 }
        }, { itemType, itemName, itemCount }) then return end

        local xPlayer = KW.GetPlayerFromId(playerId)

        if not xPlayer then
            return
        end

        if type(itemCount) ~= "number" or math.type(itemCount) ~= "integer" or itemCount < 1 then
            return xPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
        end

        if itemType == "item_standard" then
            if not itemCount or itemCount < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
            end

            local xItem = xPlayer.getInventoryItem(itemName)
            if not xItem then
                return
            end

            if itemCount > xItem.count or xItem.count < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_quantity"))
            end

            xPlayer.removeInventoryItem(itemName, itemCount)
            local pickupLabel = ("%s [%s]"):format(xItem.label, itemCount)
            KW.CreatePickup("item_standard", itemName, itemCount, pickupLabel, playerId)
            xPlayer.showNotification(TranslateCap("threw_standard", itemCount, xItem.label))
        elseif itemType == "item_account" then
            if itemCount == nil or itemCount < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            local account = xPlayer.getAccount(itemName)
            if not account then
                return
            end

            if itemCount > account.money or account.money < 1 then
                return xPlayer.showNotification(TranslateCap("imp_invalid_amount"))
            end

            xPlayer.removeAccountMoney(itemName, itemCount, "Threw away")
            local pickupLabel = ("%s [%s]"):format(account.label, TranslateCap("locale_currency", KW.Math.GroupDigits(itemCount)))
            KW.CreatePickup("item_account", itemName, itemCount, pickupLabel, playerId)
            xPlayer.showNotification(TranslateCap("threw_account", KW.Math.GroupDigits(itemCount), string.lower(account.label)))
        elseif itemType == "item_weapon" then
            itemName = string.upper(itemName)

            if not xPlayer.hasWeapon(itemName) then return end

            local _, weapon = xPlayer.getWeapon(itemName)
            if not weapon then
                return
            end

            local _, weaponObject = KW.GetWeapon(itemName)
            -- luacheck: ignore weaponPickupLabel
            local weaponPickupLabel = ""
            local components = KW.Table.Clone(weapon.components)
            xPlayer.removeWeapon(itemName)

            if weaponObject.ammo and weapon.ammo > 0 then
                local ammoLabel = weaponObject.ammo.label
                weaponPickupLabel = ("%s [%s %s]"):format(weapon.label, weapon.ammo, ammoLabel)
                xPlayer.showNotification(TranslateCap("threw_weapon_ammo", weapon.label, weapon.ammo, ammoLabel))
            else
                weaponPickupLabel = ("%s"):format(weapon.label)
                xPlayer.showNotification(TranslateCap("threw_weapon", weapon.label))
            end

            KW.CreatePickup("item_weapon", itemName, weapon.ammo, weaponPickupLabel, playerId, components, weapon.tintIndex)
        end
    end)

    RegisterNetEvent("kw:useItem", function(itemName)
        local source = source
        local xPlayer = KW.GetPlayerFromId(source)

        if not xPlayer then
            return
        end

        local item = xPlayer.getInventoryItem(itemName)
        if not item then return end
        local count = item.count

        if count < 1 then
            return xPlayer.showNotification(TranslateCap("act_imp"))
        end

        KW.UseItem(source, itemName)
    end)

    RegisterNetEvent("kw:onPickup", function(pickupId)
        local pickup, xPlayer, success = Core.Pickups[pickupId], KW.GetPlayerFromId(source)

        if not xPlayer or not pickup or pickup.inCollection then
            return
        end
        pickup.inCollection = true

        local playerPickupDistance = #(pickup.coords - xPlayer.getCoords(true))
        if playerPickupDistance > 5.0 then
            pickup.inCollection = false
            print(("[^3WARNING^7] Player Detected Cheating (Out of range pickup): ^5%s^7"):format(xPlayer.getIdentifier()))
            return
        end

        if pickup.type == "item_standard" then
            if not xPlayer.canCarryItem(pickup.name, pickup.count) then
                pickup.inCollection = false
                return xPlayer.showNotification(TranslateCap("threw_cannot_pickup"))
            end

            xPlayer.addInventoryItem(pickup.name, pickup.count)
            success = true
        elseif pickup.type == "item_account" then
            success = true
            xPlayer.addAccountMoney(pickup.name, pickup.count, "Picked up")
        elseif pickup.type == "item_weapon" then
            if xPlayer.hasWeapon(pickup.name) then
                pickup.inCollection = false
                return xPlayer.showNotification(TranslateCap("threw_weapon_already"))
            end

            success = true
            xPlayer.addWeapon(pickup.name, pickup.count)
            xPlayer.setWeaponTint(pickup.name, pickup.tintIndex)

            for _, v in ipairs(pickup.components) do
                xPlayer.addWeaponComponent(pickup.name, v)
            end
        end

        if success then
            Core.Pickups[pickupId] = nil
            TriggerClientEvent("kw:removePickup", -1, pickupId)
        end
    end)
end

lib.callback.register("kw:getPlayerData", function(source)
    local xPlayer = KW.GetPlayerFromId(source)

    if not xPlayer then
        return nil
    end

    return {
        identifier = xPlayer.identifier,
        accounts = xPlayer.getAccounts(),
        inventory = xPlayer.getInventory(),
        job = xPlayer.getJob(),
        loadout = xPlayer.getLoadout(),
        money = xPlayer.getMoney(),
        position = xPlayer.getCoords(true),
        metadata = xPlayer.getMeta(),
    }
end)

lib.callback.register("kw:isUserAdmin", function(source)
    return Core.IsPlayerAdmin(source)
end)

lib.callback.register("kw:getGameBuild", function(source)
    return tonumber(GetConvar("sv_enforceGameBuild", "1604"))
end)

lib.callback.register("kw:getOtherPlayerData", function(source, target)
    if not Core.IsPlayerAdmin(source) then
        return false
    end
    local xPlayer = KW.GetPlayerFromId(target)

    if not xPlayer then
        return nil
    end

    return {
        identifier = xPlayer.identifier,
        accounts = xPlayer.getAccounts(),
        inventory = xPlayer.getInventory(),
        job = xPlayer.getJob(),
        loadout = xPlayer.getLoadout(),
        money = xPlayer.getMoney(),
        position = xPlayer.getCoords(true),
        metadata = xPlayer.getMeta(),
    }
end)

lib.callback.register("kw:getPlayerNames", function(source, players)
    players[source] = nil

    for playerId, _ in pairs(players) do
        local xPlayer = KW.GetPlayerFromId(playerId)

        if xPlayer then
            players[playerId] = xPlayer.getName()
        else
            players[playerId] = nil
        end
    end

    return players
end)



AddEventHandler("txAdmin:events:scheduledRestart", function(eventData)
    if eventData.secondsRemaining == 60 then
        CreateThread(function()
            Wait(50000)
            Core.SavePlayers()
        end)
    end
end)

AddEventHandler("txAdmin:events:serverShuttingDown", function()
    Core.SavePlayers()
end)

local DoNotUse = {
    ["essentialmode"] = true,
    ["es_admin2"] = true,
    ["basic-gamemode"] = true,
    ["mapmanager"] = true,
    ["fivem-map-skater"] = true,
    ["fivem-map-hipster"] = true,
    ["qb-core"] = true,
    ["default_spawnpoint"] = true,
}

AddEventHandler("onResourceStart", function(key)
    if DoNotUse[string.lower(key)] then
        while GetResourceState(key) ~= "started" do
            Wait(0)
        end

        StopResource(key)
        error(("WE STOPPED A RESOURCE THAT WILL BREAK ^1KW^1, PLEASE REMOVE ^5%s^1"):format(key))
    end
    -- luacheck: ignore
    if not SetEntityOrphanMode then
        CreateThread(function()
            while true do
                error("KW Requires a minimum Artifact version of 10188, Please update your server.")
                Wait(60 * 1000)
            end
        end)
    end
    
    -- The client automatically triggers kw:onPlayerJoined if they are already active during a resource restart.
    -- We don't need a server loop here to load players, as it would cause a race condition with the client's trigger.
end)

AddEventHandler("onResourceStop", function(key)
    if key == GetCurrentResourceName() then
        print("[DTF HMR] kw_core stopping! Synchronously saving all player sessions...")
        Core.SavePlayers()
        print("[DTF HMR] All sessions saved.")
    end
end)

for key in pairs(DoNotUse) do
    if GetResourceState(key) == "started" or GetResourceState(key) == "starting" then
        StopResource(key)
        error(("WE STOPPED A RESOURCE THAT WILL BREAK ^1KW^1, PLEASE REMOVE ^5%s^1"):format(key))
    end
end
