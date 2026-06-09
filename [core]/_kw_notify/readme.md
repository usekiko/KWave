`<h1 align='center'>`[KW] Notify`</a>``</h1>``<p align='center'>``<b>``<a href='https://discord.kwave.org/'>`Discord`</a>` - `<a href='https://kwave.org/'>`Website`</a>` - `<a href='https://docs.kwave.org/legacy/installation'>`Documentation`</a>``</b>``</h5>`

A beautiful and simple NUI notification system for KW

# Example Code

`<h3>`Change style and time`</h3>`

```lua
---usage: message/type/length
KW.ShowNotification("message here", "error", 3000)
KW.ShowNotification("message here", "success", 3000)
KW.ShowNotification("message here", "info", 3000)
KW.ShowNotification("message here", "warning", 3000)

KW.ShowNotification("text here") -- Default will time and type will be info/3000

-- With title (optional 4th parameter)
KW.ShowNotification("message here", "success", 3000, "Achievement")

--[[
With position (optional 5th parameter)
Possible positions:
    "top-right"
    "top-left"
    "top-middle"
    "bottom-right"
    "bottom-left"
    "bottom-middle"
    "middle-left"
    "middle-right"
]]
KW.ShowNotification("Your message here", "info", 3000, "Info Title", "top-right")
```

`<h3>`Export Usage`</h3>`

```lua
-- Basic usage
exports["kw_notify"]:Notify("info", 3000, "message here")

-- With title
exports["kw_notify"]:Notify("success", 3000, "Item purchased!", "Shop")

-- With position
exports["kw_notify"]:Notify("warning", 4000, "Inventory full!", "Warning", "bottom-left")

-- With line break
exports["kw_notify"]:Notify("warning", 4000, "Inventory full!~br~Some items were dropped.", "Warning")
```

`<h3>`Event Usage`</h3>`

```lua
-- Basic usage
TriggerEvent("KW:Notify", "info", 3000, "message here")

-- With title
TriggerEvent("KW:Notify", "error", 5000, "You don't have enough money!", "Transaction Failed")

-- With position
TriggerEvent("KW:Notify", "success", 4000, "Welcome!", "Greetings", "top-middle")
```

`<h3>`Color Code Usage`</h3>`

```lua
~r~ = Red
~b~ = Blue
~g~ = Green
~y~ = Yellow
~p~ = Purple
~c~ = Grey
~m~ = Dark Grey
~u~ = Black
~o~ = Orange

KW.ShowNotification("I i ~r~love~s~ donuts", "success", 3000)

-- Line break example
KW.ShowNotification("You received ~br~1x ~g~ball~s~!", "success", 3000, "Item Received")
```

# Previews

![Preview 1](https://r2.fivemanage.com/gWoWHGuKZdsK8PFzaVuGC/image_2025-05-05_194204916.png)

## Legal

kw_notify- Notify!

Copyright (C) 2022-2024 KW-Framework

This program Is free software: you can redistribute it And/Or modify it under the terms Of the GNU General Public License As published by the Free Software Foundation, either version 3 Of the License, Or (at your option) any later version.

This program Is distributed In the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty Of MERCHANTABILITY Or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License For more details.

You should have received a copy Of the GNU General Public License along with this program. If Not, see `<http://www.gnu.org/licenses/>`.
