local Timeouts, OpenedMenus, MenuType = {}, {}, "dialog"

local function openMenu(namespace, name, data)
    for i = 1, #Timeouts, 1 do
        KW.ClearTimeout(Timeouts[i])
    end

    OpenedMenus[namespace .. "_" .. name] = true

    SendNUIMessage({
        action = "openMenu",
        namespace = namespace,
        name = name,
        data = data,
    })

    local timeoutId = KW.SetTimeout(200, function()
        SetNuiFocus(true, true)
    end)

    table.insert(Timeouts, timeoutId)
end

local function closeMenu(namespace, name)
    OpenedMenus[namespace .. "_" .. name] = nil

    SendNUIMessage({
        action = "closeMenu",
        namespace = namespace,
        name = name,
    })

    if not next(OpenedMenus) then
        SetNuiFocus(false, false)
    end
end

KW.UI.Menu.RegisterType(MenuType, openMenu, closeMenu)

AddEventHandler("kw_menu_dialog:message:menu_submit", function(data)
    local menu = KW.UI.Menu.GetOpened(MenuType, data._namespace, data._name)
    local cancel = false

    if not menu then
        return
    end

    if menu.submit then
        -- is the submitted data a number?
        local value = tonumber(data.value)
        if value then
            data.value = KW.Math.Round(value)

            -- check for negative value
            if tonumber(data.value) <= 0 then
                cancel = true
            end
        end

        data.value = KW.Math.Trim(data.value)

        -- don't submit if the value is negative or if it's 0
        if cancel then
            KW.ShowNotification("That input is not allowed!")
        else
            menu.submit(data, menu)
        end
    end
end)

AddEventHandler("kw_menu_dialog:message:menu_cancel", function(data)
    local menu = KW.UI.Menu.GetOpened(MenuType, data._namespace, data._name)

    if not menu then
        return
    end

    if menu.cancel ~= nil then
        menu.cancel(data, menu)
    end
end)

AddEventHandler("kw_menu_dialog:message:menu_change", function(data)
    local menu = KW.UI.Menu.GetOpened(MenuType, data._namespace, data._name)

    if not menu then
        return
    end

    if menu.change ~= nil then
        menu.change(data, menu)
    end
end)
