---@module 'migrations'
--- Runs versioned SQL migrations from the migrations/ directory on startup.
--- Each migration runs exactly once; completed migrations are tracked in kw_migrations.

local Migrations = {}

-- Create the tracking table if it doesn't exist
local CREATE_TABLE = [[
    CREATE TABLE IF NOT EXISTS kw_migrations (
        id         SERIAL       PRIMARY KEY,
        name       VARCHAR(255) UNIQUE NOT NULL,
        applied_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
    );
]]

-- List of migrations in order — filenames must match files in migrations/
local MIGRATIONS = {
    "001_fresh_schema.sql",
    "002_ox_inventory.sql",
}

---@param name string migration filename
---@return boolean already applied
local function isApplied(name)
    local result = PostgreSQL.scalar.await(
        "SELECT 1 FROM kw_migrations WHERE name = $1",
        { name }
    )
    return result == 1
end

---@param name string migration filename
---@param sql string raw SQL content
local function applyMigration(name, sql)
    -- Split on semicolons, run each statement individually
    -- PostgreSQL.query.await can handle multi-statement but splitting is safer
    local ok, err = pcall(function()
        PostgreSQL.query.await(sql)
    end)

    if not ok then
        print(("[^1ERROR^7] Migration ^5%s^7 FAILED:\n%s"):format(name, err))
        -- Fatal — stop the resource
        StopResource(GetCurrentResourceName())
        return
    end

    PostgreSQL.query.await(
        "INSERT INTO kw_migrations (name) VALUES ($1) ON CONFLICT DO NOTHING",
        { name }
    )
    print(("[^2INFO^7] Migration applied: ^5%s^7"):format(name))
end

---Run all pending migrations. Blocks until complete.
function Migrations.Run()
    -- Ensure tracking table exists first
    PostgreSQL.query.await(CREATE_TABLE)

    local resourceName = GetCurrentResourceName()
    local applied = 0

    for _, name in ipairs(MIGRATIONS) do
        if not isApplied(name) then
            -- Read the SQL file from the resource
            local path = ("migrations/%s"):format(name)
            local rawSql = LoadResourceFile(resourceName, path)

            if not rawSql then
                print(("[^1ERROR^7] Could not read migration file: ^5%s^7"):format(path))
                StopResource(resourceName)
                return
            end

            applyMigration(name, rawSql)
            applied = applied + 1
        end
    end

    if applied > 0 then
        print(("[^2INFO^7] ^5%d^7 migration(s) applied successfully."):format(applied))
    else
        print(("[^2INFO^7] Database schema is up to date (^5%d^7 migrations)."):format(#MIGRATIONS))
    end
end

return Migrations
