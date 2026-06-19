Framework = {}

function Framework.ESX()
    return GetResourceState("kw_core") ~= "missing"
end

function Framework.QBCore()
    return GetResourceState("qb-core") ~= "missing"
end

function Framework.Ox()
    return GetResourceState("ox_core") ~= "missing"
end
