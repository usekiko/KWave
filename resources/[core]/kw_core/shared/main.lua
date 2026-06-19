KW = {}

exports("getSharedObject", function()
    return KW
end)

AddEventHandler("kw:getSharedObject", function(cb)
    if KW.IsFunctionReference(cb) then
        cb(KW)
    end
end)

-- backwards compatibility (DO NOT TOUCH !)
Config.OxInventory = Config.CustomInventory == "ox"

-- Expose Config on KW so external resources (e.g. ox_inventory bridge) can read KW.Config
KW.Config = Config
