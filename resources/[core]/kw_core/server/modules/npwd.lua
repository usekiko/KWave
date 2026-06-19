local npwd = GetResourceState("npwd"):find("start") and exports.npwd or nil

AddEventHandler("onServerResourceStart", function(resource)
    if resource ~= "npwd" then
        return
    end

    npwd = GetResourceState("npwd"):find("start") and exports.npwd or nil

    if not npwd then
        return
    end
    for _, xPlayer in pairs(KW.Players) do
        npwd:newPlayer({
            source = xPlayer.source,
            identifier = xPlayer.identifier,
            firstname = xPlayer.get("firstName"),
            lastname = xPlayer.get("lastName"),
        })
    end
end)

AddEventHandler("onServerResourceStop", function(resource)
    if resource == "npwd" then
        npwd = nil
    end
end)

AddEventHandler("kw:playerLoaded", function(playerId, xPlayer)
    if not npwd then
        return
    end

    if not xPlayer then
        xPlayer = KW.GetPlayerFromId(playerId)
    end

    npwd:newPlayer({
        source = playerId,
        identifier = xPlayer.identifier,
        firstname = xPlayer.get("firstName"),
        lastname = xPlayer.get("lastName"),
    })
end)

AddEventHandler("kw:playerLogout", function(playerId)
    if not npwd then
        return
    end

    npwd:unloadPlayer(playerId)
end)
