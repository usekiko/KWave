KW.RegisterCommand(
    "setslots",
    "admin",
    function(xPlayer, args)
        Database:SetSlots(args.identifier, args.slots)
        xPlayer.triggerEvent("kw:showNotification", TranslateCap("slotsadd", args.slots, args.identifier))
    end,
    true,
    {
        help = TranslateCap("command_setslots"),
        validate = true,
        arguments = {
            { name = "identifier", help = TranslateCap("command_identifier"), type = "string" },
            { name = "slots", help = TranslateCap("command_slots"), type = "number" },
        },
    }
)

KW.RegisterCommand(
    "remslots",
    "admin",
    function(xPlayer, args)
        local removed = Database:RemoveSlots(args.identifier)

        if removed then
            xPlayer.triggerEvent("kw:showNotification", TranslateCap("slotsrem", args.identifier))
        end
    end,
    true,
    {
        help = TranslateCap("command_remslots"),
        validate = true,
        arguments = {
            { name = "identifier", help = TranslateCap("command_identifier"), type = "string" },
        },
    }
)

KW.RegisterCommand(
    "enablechar",
    "admin",
    function(xPlayer, args)
        local enabled = Database:EnableSlot(args.identifier, args.charslot)
        if enabled then
            xPlayer.triggerEvent("kw:showNotification", TranslateCap("charenabled", args.charslot, args.identifier))
        else
            xPlayer.triggerEvent("kw:showNotification", TranslateCap("charnotfound", args.charslot, args.identifier))
        end
    end,
    true,
    {
        help = TranslateCap("command_enablechar"),
        validate = true,
        arguments = {
            { name = "identifier", help = TranslateCap("command_identifier"), type = "string" },
            { name = "charslot", help = TranslateCap("command_charslot"), type = "number" },
        },
    }
)

KW.RegisterCommand(
    "disablechar",
    "admin",
    function(xPlayer, args)
        local disabled = Database:DisableSlot(args.identifier, args.charslot)
        if disabled then
            xPlayer.triggerEvent("kw:showNotification", TranslateCap("chardisabled", args.charslot, args.identifier))
        else
            xPlayer.triggerEvent("kw:showNotification", TranslateCap("charnotfound", args.charslot, args.identifier))
        end
    end,
    true,
    {
        help = TranslateCap("command_disablechar"),
        validate = true,
        arguments = {
            { name = "identifier", help = TranslateCap("command_identifier"), type = "string" },
            { name = "charslot", help = TranslateCap("command_charslot"), type = "number" },
        },
    }
)

RegisterCommand("forcelog", function(source)
    TriggerEvent("kw:playerLogout", source)
end, true)
