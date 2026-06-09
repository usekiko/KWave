local Items = require 'modules.items.server'
local started

local function Print(arg)
	print(('^3=================================================================\n^0%s\n^3=================================================================^0'):format(arg))
end

-- =========================================================================
-- Upgrade: move trunk-/glovebox- rows from ox_inventory → owned_vehicles
-- =========================================================================
local function Upgrade()
	if started then
		return warn('Data is already being converted, please wait..')
	end

	started = true

    -- PostgreSQL uses ? positional params + LIKE
	local trunk    = PostgreSQL.query.await('SELECT owner, name, data FROM ox_inventory WHERE name LIKE ?', { 'trunk-%' })
	local glovebox = PostgreSQL.query.await('SELECT owner, name, data FROM ox_inventory WHERE name LIKE ?', { 'glovebox-%' })

	if trunk and glovebox then
		local vehicles = {}

		for _, v in pairs(trunk) do
			vehicles[v.owner] = vehicles[v.owner] or {}
			local subbedName = v.name:sub(7, #v.name)
            -- oxpsql returns JSONB as table; fall back to raw if needed
            local data = type(v.data) == 'string' and v.data or json.encode(v.data or {})
			vehicles[v.owner][subbedName] = vehicles[v.owner][subbedName] or { trunk = data, glovebox = '[]' }
		end

		for _, v in pairs(glovebox) do
			vehicles[v.owner] = vehicles[v.owner] or {}
			local subbedName = v.name:sub(10, #v.name)
            local data = type(v.data) == 'string' and v.data or json.encode(v.data or {})
			local existing = vehicles[v.owner][subbedName] or { trunk = '[]', glovebox = '[]' }
			vehicles[v.owner][subbedName] = {
				trunk    = existing.trunk ~= '[]' and existing.trunk or '[]',
				glovebox = data ~= '[]' and data or existing.glovebox,
			}
		end

		Print(('Moving ^3%s^0 trunks and ^3%s^0 gloveboxes to owned_vehicles table'):format(#trunk, #glovebox))

		local parameters = {}
		local count = 0

		for owner, v in pairs(vehicles) do
			for plate, v2 in pairs(v) do
				count += 1
				parameters[count] = { v2.trunk, v2.glovebox, plate, owner }
			end
		end

        -- PostgreSQL uses $N positional params; no ? placeholders
		PostgreSQL.prepare.await(
            'UPDATE owned_vehicles SET trunk = ?, glovebox = ? WHERE plate = ? AND owner = ?',
            parameters
        )

        -- Delete both patterns in one query using OR + $N params
		PostgreSQL.query.await(
            'DELETE FROM ox_inventory WHERE name LIKE ? OR name LIKE ?',
            { 'trunk-%', 'glovebox-%' }
        )

		Print('Successfully converted trunks and gloveboxes')
	else
		Print('No inventories need to be converted')
	end

	started = false
end

-- =========================================================================
-- Helpers for serial generation (unchanged)
-- =========================================================================
local function GenerateText(num)
	local str
	repeat str = {}
		for i = 1, num do str[i] = string.char(math.random(65, 90)) end
		str = table.concat(str)
	until str ~= 'POL' and str ~= 'EMS'
	return str
end

local function GenerateSerial(text)
	if text and text:len() > 3 then
		return text
	end
	return ('%s%s%s'):format(math.random(100000,999999), text == nil and GenerateText(3) or text, math.random(100000,999999))
end

-- =========================================================================
-- ConvertESX: migrate legacy ESX user inventories/loadouts to ox format
-- =========================================================================
local function ConvertESX()
	if started then
		return warn('Data is already being converted, please wait..')
	end

    -- No parameters needed for this bulk fetch
	local users = PostgreSQL.query.await('SELECT identifier, inventory, loadout, accounts FROM users')

	if not users then return end

	started = true
	local total      = #users
	local count      = 0
	local parameters = {}

	Print(('Converting %s user inventories to new data format'):format(total))

	for i = 1, total do
		count += 1
		local inventory, slot = {}, 0

        -- JSONB safe-decode: oxpsql may return native tables for JSONB columns
        local function safeDecode(val)
            if type(val) == 'string' then return json.decode(val) or {} end
            return type(val) == 'table' and val or {}
        end

		local items    = safeDecode(users[i].inventory)
		local accounts = safeDecode(users[i].accounts)
		local loadout  = safeDecode(users[i].loadout)

		for k, v in pairs(accounts) do
			if type(v) == 'table' then break end
			if server.accounts[k] and Items(k) and v > 0 then
				slot += 1
				inventory[slot] = { slot = slot, name = k, count = v }
			end
		end

		for k in pairs(loadout) do
			local item = Items(k)
			if item then
				slot += 1
				inventory[slot] = { slot = slot, name = k, count = 1, metadata = { durability = 100 } }
				if item.ammoname then
					inventory[slot].metadata.ammo       = 0
					inventory[slot].metadata.components = {}
					inventory[slot].metadata.serial     = GenerateSerial()
				end
			end
		end

		for k, v in pairs(items) do
			if type(v) == 'table' then break end
			if Items(k) and v > 0 then
				slot += 1
				inventory[slot] = { slot = slot, name = k, count = v }
			end
		end

        -- ? = inventory JSON, ? = identifier
		parameters[count] = { json.encode(inventory), users[i].identifier }
	end

	PostgreSQL.prepare.await('UPDATE users SET inventory = ? WHERE identifier = ?', parameters)
	Print('Successfully converted user inventories')
	started = false
end

-- =========================================================================
-- Convert_Old_ESX_Property: merge property stashes into ox_inventory
-- =========================================================================
local function Convert_Old_ESX_Property()
	if started then
		return warn('Data is already being converted, please wait..')
	end

    -- PostgreSQL uses UNION ALL (same as MySQL) — valid standard SQL
	local inventories = PostgreSQL.query.await([[
        SELECT DISTINCT owner FROM (
            SELECT owner FROM addon_inventory_items WHERE inventory_name = 'property'
            UNION ALL
            SELECT owner FROM datastore_data WHERE name = 'property'
            UNION ALL
            SELECT owner FROM addon_account_data WHERE account_name = 'property_black_money'
        ) a
    ]])

	if not inventories then return end

	started = true
	local total      = #inventories
	local count      = 0
	local parameters = {}

	Print(('Converting %s user property inventories to new data format'):format(total))

	for i = 1, #inventories do
		count += 1
		local inventory, slot = {}, 0

        -- ? positional param for owner
		local addoninventory = PostgreSQL.query.await(
            "SELECT name, count FROM addon_inventory_items WHERE owner = ? AND inventory_name = 'property'",
            { inventories[i].owner }
        )

		for _, v in pairs(addoninventory) do
			if Items(v.name) and v.count > 0 then
				slot += 1
				inventory[slot] = { slot = slot, name = v.name, count = v.count }
			end
		end

		local addonaccount = PostgreSQL.query.await(
            "SELECT money FROM addon_account_data WHERE owner = ? AND account_name = 'property_black_money'",
            { inventories[i].owner }
        )

		for _, v in pairs(addonaccount) do
			if v.money > 0 then
				slot += 1
				inventory[slot] = { slot = slot, name = 'black_money', count = v.money }
			end
		end

		local datastore = PostgreSQL.query.await(
            "SELECT data FROM datastore_data WHERE owner = ? AND name = 'property'",
            { inventories[i].owner }
        )

		for _, v in pairs(datastore) do
            -- JSONB safe-decode
            local obj = type(v.data) == 'string' and json.decode(v.data) or v.data
			if obj and obj.weapons then
				for b = 1, #obj.weapons do
					local item = Items(obj.weapons[b].name)
					if item then
						slot += 1
						inventory[slot] = {
                            slot     = slot,
                            name     = obj.weapons[b].name,
                            count    = 1,
                            metadata = { durability = 100 },
                        }
						if item.ammoname then
							inventory[slot].metadata.ammo       = obj.weapons[b].ammo
							inventory[slot].metadata.components = {}
							inventory[slot].metadata.serial     = GenerateSerial()
						end
					end
				end
			end
		end

        -- ? = owner, ? = name (stash id), ? = data JSON
		parameters[count] = {
            inventories[i].owner,
            'property' .. inventories[i].owner,
            json.encode(inventory, { indent = false }),
        }
	end

    -- PostgreSQL ON CONFLICT instead of INSERT IGNORE
	PostgreSQL.prepare.await(
        'INSERT INTO ox_inventory (owner, name, data) VALUES (?, ?, ?) ON CONFLICT (owner, name) DO UPDATE SET data = EXCLUDED.data',
        parameters
    )
	Print('Successfully converted user property inventories')
	started = false
end

return {
	linden      = Upgrade,
	esx         = ConvertESX,
	esxproperty = Convert_Old_ESX_Property,
}
