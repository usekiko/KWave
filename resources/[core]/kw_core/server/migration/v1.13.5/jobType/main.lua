local esxVersion = "v1.13.5"

Core.Migrations = Core.Migrations or {}
Core.Migrations[esxVersion] = Core.Migrations[esxVersion] or {}

if GetResourceKvpInt(("kw_migration:%s"):format(esxVersion)) == 1 then
  return
end

---@return boolean restartRequired
Core.Migrations[esxVersion].jobTypes = function()
  print("^4[kw_migration:v1.13.5:jobTypes]^7 Adding job type column to jobs table.")

  local col = PostgreSQL.scalar.await([[
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_catalog = current_database()
      AND table_name = 'jobs'
      AND column_name = 'type'
  ]])

  if col == 0 then
    print("^4[kw_migration:v1.13.5:jobTypes]^7 Column not found, altering jobs table.")
    PostgreSQL.update.await([[
      ALTER TABLE jobs
        ADD COLUMN type VARCHAR(50) NOT NULL DEFAULT 'civ'
    ]])
  else
    print("^4[kw_migration:v1.13.5:jobTypes]^7 Column already exists, migration not needed.")
    return false
  end

  print("^4[kw_migration:v1.13.5:jobTypes]^7 Migration complete.")
  return true
end
