local esxVersion = "v1.13.3"

Core.Migrations = Core.Migrations or {}
Core.Migrations[esxVersion] = Core.Migrations[esxVersion] or {}

if GetResourceKvpInt(("kw_migration:%s"):format(esxVersion)) == 1 then
  return
end

---@return boolean restartRequired
Core.Migrations[esxVersion].ssn = function()
  print("^4[kw_migration:v.1.13.3:ssn]^7 Adding SSN column to users table.")
  local col = PostgreSQL.scalar.await([[
    SELECT COUNT(*)
    FROM information_schema.columns
    WHERE table_catalog = current_database()
      AND table_name = 'users'
      AND column_name = 'ssn'
]])

  local idx = PostgreSQL.scalar.await([[
    SELECT COUNT(*)
    FROM pg_indexes
    WHERE tablename = 'users'
      AND indexname = 'unique_ssn'
]])

  if col == 0 and idx == 0 then
    PostgreSQL.update.await([[
        ALTER TABLE users
            ADD COLUMN ssn VARCHAR(11) NULL DEFAULT NULL
    ]])
    PostgreSQL.update.await([[
        ALTER TABLE users
            ADD CONSTRAINT unique_ssn UNIQUE (ssn)
    ]])
  elseif col == 0 then
    PostgreSQL.update.await("ALTER TABLE users ADD COLUMN ssn VARCHAR(11) NULL DEFAULT NULL")
  elseif idx == 0 then
    PostgreSQL.update.await("ALTER TABLE users ADD CONSTRAINT unique_ssn UNIQUE (ssn)")
  end


  local Result = PostgreSQL.query.await("SELECT identifier FROM users WHERE ssn IS NULL")
  if #Result == 0 then
    print("^4[kw_migration:v.1.13.3:ssn]^7 No users found without SSN, migration not needed.")
    return false
  end

  print("^4[kw_migration:v.1.13.3:ssn]^7 Generating SSN for existing users.")
  local GeneratedSSNs = {}
  local Parameters = {}
  for i = 1, #Result do
    local ssn
    repeat
      ssn = Core.generateSSN(true)
    until not GeneratedSSNs[ssn]

    GeneratedSSNs[ssn] = true
    Parameters[i] = { ssn, Result[i].identifier }
  end

  print("^4[kw_migration:v.1.13.3:ssn]^7 Updating users with generated SSN. This may take a minute...")
  PostgreSQL.prepare.await("UPDATE users SET ssn = ? WHERE identifier = ?", Parameters)

  print("^4[kw_migration:v.1.13.3:ssn]^7 Removing SSN default value.")
  PostgreSQL.update.await("ALTER TABLE users ALTER COLUMN ssn SET NOT NULL")

  print(("^4[kw_migration:v.1.13.3:ssn]^7 Successfully migrated %d users."):format(#Parameters))

  return true
end
