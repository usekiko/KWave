local points = {}

function KW.CreatePointInternal(coords, distance, hidden, enter, leave)
    if type(coords) == 'table' and coords.x then
        coords = vec3(coords.x, coords.y, coords.z)
    end
    
    local handle = #points + 1
    
    local point = lib.points.new({
        coords = coords,
        distance = distance,
        kw_handle = handle,
        kw_hidden = hidden,
        kw_resource = GetInvokingResource(),
        onEnter = function(self)
            if not self.kw_hidden and enter then
                enter()
            end
        end,
        onExit = function(self)
            if leave then
                leave()
            end
        end
    })
    
    points[handle] = point
    return handle
end

function KW.RemovePointInternal(handle)
    if points[handle] then
        points[handle]:remove()
        points[handle] = nil
    end
end

function KW.HidePointInternal(handle, hidden)
    if points[handle] then
        points[handle].kw_hidden = hidden
    end
end

function StartPointsLoop()
    -- Deprecated: ox_lib handles all distance calculations at the engine level now.
end

AddEventHandler('onResourceStop', function(resource)
    for handle, point in pairs(points) do
        if point.kw_resource == resource then
            point:remove()
            points[handle] = nil
        end
    end
end)