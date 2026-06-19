RegisterNetEvent("kw_skin:save", function(skin)
    if not skin or type(skin) ~= "table" then
        return
    end
    local xPlayer = KW.Player(source)

    if not KW.GetConfig().CustomInventory then
        local defaultMaxWeight = KW.GetConfig().MaxWeight
        local backpackModifier = Config.BackpackWeight[skin.bags_1]

        if backpackModifier then
            xPlayer.setMaxWeight(defaultMaxWeight + backpackModifier)
        else
            xPlayer.setMaxWeight(defaultMaxWeight)
        end
    end

    PostgreSQL.update("UPDATE users SET skin = ? WHERE identifier = ?", {
        json.encode(skin),
        xPlayer.getIdentifier(),
    })
end)

RegisterNetEvent("kw_skin:setWeight", function(skin)
    local xPlayer = KW.Player(source)

    if not KW.GetConfig().CustomInventory then
        local defaultMaxWeight = KW.GetConfig().MaxWeight
        local backpackModifier = Config.BackpackWeight[skin.bags_1]

        if backpackModifier then
            xPlayer.setMaxWeight(defaultMaxWeight + backpackModifier)
        else
            xPlayer.setMaxWeight(defaultMaxWeight)
        end
    end
end)

lib.callback.register("kw_skin:getPlayerSkin", function(source)
    local xPlayer = KW.Player(source)

    local users = PostgreSQL.query.await("SELECT skin FROM users WHERE identifier = ?", {
        xPlayer.getIdentifier(),
    })

    local user, skin = users[1], nil

    local jobSkin = {
        skin_male = xPlayer.getJob().skin_male,
        skin_female = xPlayer.getJob().skin_female,
    }

    if user and user.skin then
        skin = type(user.skin) == "string" and json.decode(user.skin) or user.skin
    end

    return skin, jobSkin
end)

KW.RegisterCommand("skin", "admin", function(xPlayer, args)
    if not args.playerId then
        args.playerId = xPlayer
    end
    args.playerId.triggerEvent("kw_skin:openSaveableMenu")
end, false, { help = TranslateCap("skin"), arguments = { { name = "playerId", help = TranslateCap("skin"), type = "player" }} })
