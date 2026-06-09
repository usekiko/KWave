Database = {}
Database.connected = false
Database.found = false
Database.tables = { users = "identifier" }

function Database:GetConnection()
    local connectionString = GetConvar("pgsql_connection_string", "")

    if connectionString == "" then
        error(connectionString .. "\n^1Unable to start Multicharacter - unable to determine database from pgsql_connection_string^0", 0)
    elseif connectionString:find("postgresql://") or connectionString:find("postgres://") then
        local dbName = connectionString:match("/([^/%?]+)[%?]?[^/]*$")
        if dbName then
            self.name = dbName
            self.found = true
        end
    else
        local confPairs = { string.strsplit(";", connectionString) }
        for i = 1, #confPairs do
            local confPair = confPairs[i]
            local key, value = confPair:match("^%s*(.-)%s*=%s*(.-)%s*$")
            if key == "database" then
                self.name = value
                self.found = true
                break
            end
        end
    end
end

PostgreSQL.ready(function()
    local length = 42 + #Server.prefix
    local DB_COLUMNS = PostgreSQL.query.await(('SELECT table_name, column_name, character_maximum_length FROM information_schema.columns WHERE table_catalog = current_database() AND data_type = $1 AND column_name IN ($2, $3)'), {
        "character varying", "identifier", "owner",
    })

    if DB_COLUMNS then
        local columns = {}
        local count = 0

        for i = 1, #DB_COLUMNS do
            local column = DB_COLUMNS[i]
            Database.tables[column.table_name] = column.column_name

            if column?.character_maximum_length and column.character_maximum_length < length then
                count = count + 1
                columns[column.table_name] = column.column_name
            end
        end

        if next(columns) then
            local query = "ALTER TABLE %s ALTER COLUMN %s TYPE VARCHAR(%s)"
            local queries = table.create(count, 0)

            for k, v in pairs(columns) do
                queries[#queries + 1] = { query = query:format(k, v, length) }
            end

            if PostgreSQL.transaction.await(queries) then
                print(("[^2INFO^7] Updated ^5%s^7 columns to use ^5VARCHAR(%s)^7"):format(count, length))
            else
                print(("[^2INFO^7] Unable to update ^5%s^7 columns to use ^5VARCHAR(%s)^7"):format(count, length))
            end
        end

        Database.connected = true

        KW.Jobs = KW.GetJobs()
        while not next(KW.Jobs) do
            Wait(500)
            KW.Jobs = KW.GetJobs()
        end
    end
end)

function Database:DeleteCharacter(source, charid)
    local identifier = ("%s%s:%s"):format(Server.prefix, charid, KW.GetIdentifier(source))
    local query = "DELETE FROM %s WHERE %s = ?"
    local queries = {}
    local count = 0

    for table, column in pairs(self.tables) do
        count = count + 1
        queries[count] = { query = query:format(table, column), values = { identifier } }
    end

    PostgreSQL.transaction(queries, function(result)
        if result then
            local name = GetPlayerName(source)
            print(("[^2INFO^7] Player ^5%s %s^7 has deleted a character ^5(%s)^7"):format(name, source, identifier))
            Wait(50)
            Multicharacter:SetupCharacters(source)
        else
            error("\n^1Transaction failed while trying to delete " .. identifier .. "^0")
        end
    end)
end

function Database:GetPlayerSlots(identifier)
    return PostgreSQL.scalar.await("SELECT slots FROM multicharacter_slots WHERE identifier = ?", { identifier }) or
        Server.slots
end

function Database:GetPlayerInfo(identifier, slots)
    return PostgreSQL.query.await(
        "SELECT identifier, accounts, job, job_grade, firstname, lastname, dateofbirth, sex, skin, disabled FROM users WHERE identifier LIKE ? LIMIT ?",
        { identifier, slots })
end

function Database:SetSlots(identifier, slots)
    PostgreSQL.insert("INSERT INTO multicharacter_slots (identifier, slots) VALUES (?, ?) ON CONFLICT (identifier) DO UPDATE SET slots = EXCLUDED.slots", {
        identifier,
        slots,
    })
end

function Database:RemoveSlots(identifier)
    local slots = PostgreSQL.scalar.await("SELECT slots FROM multicharacter_slots WHERE identifier = ?", {
        identifier,
    })

    if slots then
        PostgreSQL.update("DELETE FROM multicharacter_slots WHERE identifier = ?", {
            identifier,
        })
        return true
    end
    return false
end

function Database:EnableSlot(identifier, slot)
    local selectedCharacter = ("char%s:%s"):format(slot, identifier)

    local updated = PostgreSQL.update.await("UPDATE users SET disabled = 0 WHERE identifier = ?", {selectedCharacter})
    return updated > 0
end

function Database:DisableSlot(identifier, slot)
    local selectedCharacter = ("char%s:%s"):format(slot, identifier)

    local updated = PostgreSQL.update.await("UPDATE users SET disabled = 1 WHERE identifier = ?", {selectedCharacter})
    return updated > 0
end

Database:GetConnection()
