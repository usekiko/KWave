---@diagnostic disable: duplicate-set-field

Multicharacter = {}
Multicharacter._index = Multicharacter
Multicharacter.awaitingRegistration = {}
Multicharacter.playerSlots = {}

function Multicharacter:SetupCharacters(source)
    SetPlayerRoutingBucket(source, source)
    while not Database.connected do
        Wait(100)
    end

    local identifier = KW.GetIdentifier(source)
    KW.Players[identifier] = source

    local slots = Database:GetPlayerSlots(identifier)
    self.playerSlots[source] = slots
    identifier = Server.prefix .. "%:" .. identifier

    local rawCharacters = Database:GetPlayerInfo(identifier, slots)
    local characters

    if rawCharacters then
        local characterCount = #rawCharacters
        characters = table.create(0, characterCount)

        for i = 1, characterCount, 1 do
            local v = rawCharacters[i]
            local job, grade = v.job or "unemployed", tostring(v.job_grade)

            if KW.Jobs[job] and KW.Jobs[job].grades[grade] then
                if job ~= "unemployed" then
                    grade = KW.Jobs[job].grades[grade].label
                else
                    grade = ""
                end
                job = KW.Jobs[job].label
            end

            local accounts = type(v.accounts) == "string" and json.decode(v.accounts) or v.accounts or {}
            local idString = string.sub(v.identifier, #Server.prefix + 1, string.find(v.identifier, ":") - 1)
            local id = tonumber(idString)
            if id then
                characters[id] = {
                    id = id,
                    bank = accounts.bank,
                    money = accounts.money,
                    job = job,
                    job_grade = grade,
                    firstname = v.firstname,
                    lastname = v.lastname,
                    dateofbirth = v.dateofbirth,
                    skin = type(v.skin) == "string" and json.decode(v.skin) or v.skin or {},
                    disabled = v.disabled,
                    sex = v.sex == "m" and TranslateCap("male") or TranslateCap("female"),
                }
            end
        end
    end

    TriggerClientEvent("kw_multicharacter:SetupUI", source, characters, slots)
end

function Multicharacter:CharacterChosen(source, charid, isNew)
    if type(charid) ~= "number" or math.type(charid) ~= "integer" or charid < 1 or type(isNew) ~= "boolean" then
        return
    end

    local allowedSlots = self.playerSlots[source] or Server.slots
    if charid > allowedSlots then
        print(("[KW Multicharacter] Player %s tried to bypass char slots!"):format(source))
        return
    end

    if isNew then
        self.awaitingRegistration[source] = charid
    else
        SetPlayerRoutingBucket(source, 0)
        if not KW.GetConfig().EnableDebug then
            local identifier = ("%s%s:%s"):format(Server.prefix, charid, KW.GetIdentifier(source))

            if KW.GetPlayerFromIdentifier(identifier) then
                DropPlayer(source, "[KW Multicharacter] Your identifier " .. identifier .. " is already on the server!")
                return
            end
        end

        local charIdentifier = ("%s%s"):format(Server.prefix, charid)
        TriggerEvent("kw:onPlayerJoined", source, charIdentifier)
        KW.Players[KW.GetIdentifier(source)] = charIdentifier
    end
end

function Multicharacter:RegistrationComplete(source, data)
    local charId = self.awaitingRegistration[source]
    local charIdentifier = ("%s%s"):format(Server.prefix, charId)
    self.awaitingRegistration[source] = nil
    KW.Players[KW.GetIdentifier(source)] = charIdentifier

    SetPlayerRoutingBucket(source, 0)
    TriggerEvent("kw:onPlayerJoined", source, charIdentifier, data)
end

function Multicharacter:PlayerDropped(player)
    self.awaitingRegistration[player] = nil
    self.playerSlots[player] = nil
    KW.Players[KW.GetIdentifier(player)] = nil
end
