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
