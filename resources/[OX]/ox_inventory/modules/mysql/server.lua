if not lib then return end

-- =========================================================================
-- Query Definitions — strict PostgreSQL $N positional placeholders
-- Template tokens {user_table}, {vehicle_table}, etc. are resolved at boot
-- =========================================================================
local Query = {
    -- ox_inventory stash table
    SELECT_STASH   = 'SELECT data FROM ox_inventory WHERE owner = ? AND name = ?',
    UPSERT_STASH   = 'INSERT INTO ox_inventory (data, owner, name) VALUES (?, ?, ?) ON CONFLICT (owner, name) DO UPDATE SET data = EXCLUDED.data, lastupdated = CURRENT_TIMESTAMP',
    INSERT_STASH   = 'INSERT INTO ox_inventory (owner, name) VALUES (?, ?) ON CONFLICT DO NOTHING',

    -- Vehicle columns
    SELECT_GLOVEBOX = 'SELECT plate, glovebox FROM {vehicle_table} WHERE {vehicle_column} = ?',
    SELECT_TRUNK    = 'SELECT plate, trunk    FROM {vehicle_table} WHERE {vehicle_column} = ?',
    UPDATE_GLOVEBOX = 'UPDATE {vehicle_table} SET glovebox = ? WHERE {vehicle_column} = ?',
    UPDATE_TRUNK    = 'UPDATE {vehicle_table} SET trunk    = ? WHERE {vehicle_column} = ?',

    -- Player inventory column
    SELECT_PLAYER = 'SELECT inventory FROM {user_table} WHERE {user_column} = ?',
    UPDATE_PLAYER = 'UPDATE {user_table} SET inventory = ? WHERE {user_column} = ?',
}

-- =========================================================================
-- Boot initialisation thread
-- =========================================================================
Citizen.CreateThreadNow(function()
    local playerTable, playerColumn, vehicleTable, vehicleColumn

    if shared.framework == 'ox' then
        playerTable  = 'character_inventory'
        playerColumn = 'charid'
        vehicleTable  = 'vehicles'
        vehicleColumn = 'id'
    elseif shared.framework == 'kw' then
        playerTable  = 'users'
        playerColumn = 'identifier'
        vehicleTable  = 'owned_vehicles'
        vehicleColumn = 'plate'
    elseif shared.framework == 'nd' then
        playerTable  = 'nd_characters'
        playerColumn = 'charid'
        vehicleTable  = 'nd_vehicles'
        vehicleColumn = 'id'
    elseif shared.framework == 'qbx' then
        playerTable  = 'players'
        playerColumn = 'citizenid'
        vehicleTable  = 'player_vehicles'
        vehicleColumn = 'id'
    else
        return
    end

    -- Resolve template tokens in every query string
    for k, v in pairs(Query) do
        Query[k] = v
            :gsub('{user_table}',    playerTable)
            :gsub('{user_column}',   playerColumn)
            :gsub('{vehicle_table}', vehicleTable)
            :gsub('{vehicle_column}', vehicleColumn)
    end

    Wait(0)

    -- -----------------------------------------------------------------------
    -- Ensure ox_inventory table exists with JSONB data column for performance
    -- -----------------------------------------------------------------------
    local success = pcall(PostgreSQL.scalar.await, 'SELECT 1 FROM ox_inventory LIMIT 1')

    if not success then
        PostgreSQL.query.await([[
            CREATE TABLE IF NOT EXISTS ox_inventory (
                owner       VARCHAR(60)  DEFAULT NULL,
                name        VARCHAR(100) NOT NULL,
                data        JSONB        DEFAULT NULL,
                lastupdated TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP,
                UNIQUE (owner, name)
            )
        ]])

        -- GIN index for fast JSONB key lookups
        PostgreSQL.query.await('CREATE INDEX IF NOT EXISTS idx_ox_inventory_data ON ox_inventory USING GIN (data)')
        -- Composite index for the most common WHERE owner = AND name = queries
        PostgreSQL.query.await('CREATE INDEX IF NOT EXISTS idx_ox_inventory_owner_name ON ox_inventory (owner, name)')
        shared.info('Created ox_inventory table with JSONB column and GIN index.')
    end

    -- -----------------------------------------------------------------------
    -- Ensure vehicle table has glovebox / trunk columns (JSONB)
    -- -----------------------------------------------------------------------
    local columnCheck = pcall(PostgreSQL.query.await, ('SELECT glovebox FROM %s LIMIT 1'):format(vehicleTable))
    if not columnCheck then
        PostgreSQL.query.await(('ALTER TABLE %s ADD COLUMN IF NOT EXISTS glovebox JSONB DEFAULT NULL'):format(vehicleTable))
        PostgreSQL.query.await(('ALTER TABLE %s ADD COLUMN IF NOT EXISTS trunk    JSONB DEFAULT NULL'):format(vehicleTable))
        shared.info(('Added glovebox/trunk JSONB columns to %s.'):format(vehicleTable))
    end

    -- -----------------------------------------------------------------------
    -- Ensure player table has inventory column (JSONB)
    -- -----------------------------------------------------------------------
    local playerColumnCheck = pcall(PostgreSQL.scalar.await, ('SELECT inventory FROM %s LIMIT 1'):format(playerTable))
    if not playerColumnCheck then
        PostgreSQL.query.await(('ALTER TABLE %s ADD COLUMN IF NOT EXISTS inventory JSONB DEFAULT NULL'):format(playerTable))
        shared.info(('Added inventory JSONB column to %s.'):format(playerTable))
    end

    -- -----------------------------------------------------------------------
    -- Purge stale stash entries older than the configured interval
    -- -----------------------------------------------------------------------
    local clearStashes = GetConvar('inventory:clearstashes', '6 months')

    if clearStashes ~= '' then
        -- PostgreSQL interval syntax: '6 months', '30 days', etc.
        local ok, err = pcall(PostgreSQL.query.await,
            ("DELETE FROM ox_inventory WHERE lastupdated < (NOW() - INTERVAL '%s')"):format(clearStashes))
        if not ok then
            warn(('[ox_inventory] Stash purge failed (check inventory:clearstashes format): %s'):format(err))
        end
    end
end)

-- =========================================================================
-- db interface — all public functions used by the rest of ox_inventory
-- =========================================================================
db = {}

-- JSONB safe decode helper: oxpsql returns JSONB as native Lua tables.
-- Calling json.decode on a table crashes the thread, so we guard with type().
local function safeDecode(value)
    if type(value) == 'string' then
        return json.decode(value) or nil
    end
    return value  -- already a table (native JSONB)
end

---@param identifier string
---@return table?
function db.loadPlayer(identifier)
    local result = PostgreSQL.prepare.await(Query.SELECT_PLAYER, { identifier })
    if not result then return end
    -- result may be a row table from oxpsql (single-column SELECT returns scalar OR row)
    local raw = type(result) == 'table' and result.inventory or result
    return safeDecode(raw)
end

---@param owner string
---@param inventory string JSON-encoded inventory blob
function db.savePlayer(owner, inventory)
    return PostgreSQL.prepare(Query.UPDATE_PLAYER, { inventory, owner })
end

---@param owner string | number | nil
---@param dbId string
---@param inventory string JSON-encoded inventory blob
function db.saveStash(owner, dbId, inventory)
    return PostgreSQL.prepare(Query.UPSERT_STASH, { inventory, owner and tostring(owner) or '', dbId })
end

---@param owner string | number | nil
---@param name string
---@return table?
function db.loadStash(owner, name)
    local result = PostgreSQL.prepare.await(Query.SELECT_STASH, { owner and tostring(owner) or '', name })
    return safeDecode(result)
end

---@param id string | number plate or vehicle id
---@param inventory string
function db.saveGlovebox(id, inventory)
    return PostgreSQL.prepare(Query.UPDATE_GLOVEBOX, { inventory, id })
end

---@param id string | number
---@return table?
function db.loadGlovebox(id)
    local result = PostgreSQL.prepare.await(Query.SELECT_GLOVEBOX, { id })
    if not result then return end
    local raw = type(result) == 'table' and result.glovebox or result
    return safeDecode(raw)
end

---@param id string | number
---@param inventory string
function db.saveTrunk(id, inventory)
    return PostgreSQL.prepare(Query.UPDATE_TRUNK, { inventory, id })
end

---@param id string | number
---@return table?
function db.loadTrunk(id)
    local result = PostgreSQL.prepare.await(Query.SELECT_TRUNK, { id })
    if not result then return end
    local raw = type(result) == 'table' and result.trunk or result
    return safeDecode(raw)
end

-- =========================================================================
-- Batch save — runs concurrently for each inventory type
-- =========================================================================

---Count the number of successfully updated rows from a pg driver response.
---@param rows number | table
---@return number
local function countRows(rows)
    if type(rows) == 'number' then return rows end

    local n = 0
    for i = 1, #rows do
        if rows[i] == 1 then n += 1 end
    end

    return n
end

---pcall wrapper that surfaces errors as warnings instead of crashing the thread.
local function safeQuery(fn, ...)
    local ok, resp = pcall(fn, ...)

    if not ok then
        return warn(('[ox_inventory] DB error: %s'):format(resp))
    end

    return resp
end

-- Build a multi-row UPSERT for bulk stash saving.
-- PostgreSQL uses ?..$N positional params, so we dynamically expand them.
local function buildBulkUpsert(rowCount)
    -- Each row contributes 3 params: (data, owner, name)
    local rows  = {}
    local param = 0

    for i = 1, rowCount do
        param += 1; local p1 = param
        param += 1; local p2 = param
        param += 1; local p3 = param
        rows[i] = ('($%d, $%d, $%d)'):format(p1, p2, p3)
    end

    return ('INSERT INTO ox_inventory (data, owner, name) VALUES %s ON CONFLICT (owner, name) DO UPDATE SET data = EXCLUDED.data, lastupdated = CURRENT_TIMESTAMP'):format(table.concat(rows, ', '))
end

---@param players InventorySaveData[]
---@param trunks InventorySaveData[]
---@param gloveboxes InventorySaveData[]
---@param stashes (InventorySaveData | string | number)[]
---@param total number[]
function db.saveInventories(players, trunks, gloveboxes, stashes, total)
    local start   = os.nanotime()
    local saveStr = 'Saved %d/%d %s (%.4f ms)'
    local pending = 0

    shared.info(('Saving %s inventories to PostgreSQL'):format(total[5]))

    -- Player inventories
    if total[1] > 0 then
        pending += 1
        Citizen.CreateThreadNow(function()
            local resp = safeQuery(PostgreSQL.prepare.await, Query.UPDATE_PLAYER, players)
            pending -= 1
            if resp then
                shared.info(saveStr:format(countRows(resp), total[1], 'players', (os.nanotime() - start) / 1e6))
            end
        end)
    end

    -- Trunk inventories
    if total[2] > 0 then
        pending += 1
        Citizen.CreateThreadNow(function()
            local resp = safeQuery(PostgreSQL.prepare.await, Query.UPDATE_TRUNK, trunks)
            pending -= 1
            if resp then
                shared.info(saveStr:format(countRows(resp), total[2], 'trunks', (os.nanotime() - start) / 1e6))
            end
        end)
    end

    -- Glovebox inventories
    if total[3] > 0 then
        pending += 1
        Citizen.CreateThreadNow(function()
            local resp = safeQuery(PostgreSQL.prepare.await, Query.UPDATE_GLOVEBOX, gloveboxes)
            pending -= 1
            if resp then
                shared.info(saveStr:format(countRows(resp), total[3], 'gloveboxes', (os.nanotime() - start) / 1e6))
            end
        end)
    end

    -- Stash inventories
    if total[4] > 0 then
        pending += 1

        if server.bulkstashsave then
            -- total[4] is already the param count (3 params per row), compute row count
            local rowCount = math.floor(total[4] / 3)

            Citizen.CreateThreadNow(function()
                local query = buildBulkUpsert(rowCount)
                local resp  = safeQuery(PostgreSQL.query.await, query, stashes)
                pending -= 1

                if resp then
                    -- pg returns rowCount for INSERT … ON CONFLICT
                    local affected = type(resp) == 'number' and resp or (resp.rowCount or 0)
                    shared.info(saveStr:format(affected, rowCount, 'stashes', (os.nanotime() - start) / 1e6))
                end
            end)
        else
            Citizen.CreateThreadNow(function()
                local resp = safeQuery(PostgreSQL.rawExecute.await, Query.UPSERT_STASH, stashes)
                pending -= 1

                if resp then
                    local affectedRows = 0

                    if table.type(resp) == 'hash' then
                        if resp.affectedRows > 0 then affectedRows = 1 end
                    else
                        for i = 1, #resp do
                            if resp[i].affectedRows > 0 then affectedRows += 1 end
                        end
                    end

                    shared.info(saveStr:format(affectedRows, total[4], 'stashes', (os.nanotime() - start) / 1e6))
                end
            end)
        end
    end

    repeat Wait(0) until pending == 0
end

return db
