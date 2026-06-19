-- DTF Red Bull - Server-side item handling

-- Remove Red Bull item from player inventory
RegisterNetEvent('kw_redbull:removeItem')
AddEventHandler('kw_redbull:removeItem', function(slot)
    local src = source
    
    if slot then
        exports.ox_inventory:RemoveItem(src, 'redbull', 1, nil, slot)
    end
end)

-- Server export for ox_inventory (required for export to work)
exports('UseRedBull', function(event, item, inventory, slot, data)
    -- The actual logic is handled client-side
    -- This export just confirms the item can be used
    return true
end)

print('[^3DTF Red Bull^7] Server loaded')
