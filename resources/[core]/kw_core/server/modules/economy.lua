---@module 'economy'
--- Atomic PostgreSQL economy operations for KWave.
--- All money mutations go through this module to ensure the DB
--- is always the source of truth — no race conditions, no duplication bugs.

local Economy = {}

--- Internal: write a transaction to the audit log
---@param identifier string
---@param playerName string
---@param action string
---@param data table
local function auditLog(identifier, playerName, action, data)
    PostgreSQL.query(
        "INSERT INTO kw_audit_log (identifier, player_name, action, data) VALUES (?, ?, ?, ?)",
        { identifier, playerName, action, json.encode(data) }
    )
end

---Atomically add money to a player's account.
--- Returns the new balance, or nil on failure.
---@param identifier string
---@param playerName string
---@param account string  e.g. "bank", "money"
---@param amount number   must be > 0
---@param reason string
---@return number? newBalance
function Economy.AddAccountMoney(identifier, playerName, account, amount, reason)
    if type(amount) ~= "number" or amount <= 0 or amount ~= amount or amount == math.huge then
        print(("[^1ECONOMY^7] Invalid add amount for ^5%s^7: ^5%s^7"):format(identifier, tostring(amount)))
        return nil
    end

    amount = math.floor(amount + 0.5) -- round

    local result = PostgreSQL.rawQuery.await(([[
        UPDATE users
        SET accounts = jsonb_set(
            accounts,
            '{%s}',
            to_jsonb(COALESCE((accounts->>'%s')::numeric, 0) + ?)
        )
        WHERE identifier = ?
        RETURNING (accounts->>'%s')::numeric AS new_balance
    ]]):format(account, account, account), { amount, identifier })

    if not result or not result[1] then
        print(("[^1ECONOMY^7] AddAccountMoney DB error for ^5%s^7"):format(identifier))
        return nil
    end

    local newBalance = tonumber(result[1].new_balance)
    auditLog(identifier, playerName, "add_money", { account = account, amount = amount, reason = reason, new_balance = newBalance })
    return newBalance
end

---Atomically remove money from a player's account.
--- Returns the new balance, or nil if insufficient funds or DB error.
---@param identifier string
---@param playerName string
---@param account string
---@param amount number  must be > 0
---@param reason string
---@return number? newBalance  nil = insufficient funds or error
function Economy.RemoveAccountMoney(identifier, playerName, account, amount, reason)
    if type(amount) ~= "number" or amount <= 0 or amount ~= amount or amount == math.huge then
        print(("[^1ECONOMY^7] Invalid remove amount for ^5%s^7: ^5%s^7"):format(identifier, tostring(amount)))
        return nil
    end

    amount = math.floor(amount + 0.5) -- round

    -- Atomic: only subtract if balance >= amount (prevents going negative)
    local result = PostgreSQL.rawQuery.await(([[
        UPDATE users
        SET accounts = jsonb_set(
            accounts,
            '{%s}',
            to_jsonb((accounts->>'%s')::numeric - ?)
        )
        WHERE identifier = ?
          AND (accounts->>'%s')::numeric >= ?
        RETURNING (accounts->>'%s')::numeric AS new_balance
    ]]):format(account, account, account, account), { amount, identifier, amount })

    if not result or not result[1] then
        -- No row updated = insufficient funds
        return nil
    end

    local newBalance = tonumber(result[1].new_balance)
    auditLog(identifier, playerName, "remove_money", { account = account, amount = amount, reason = reason, new_balance = newBalance })
    return newBalance
end

---Atomically set a player's account to an exact value.
---@param identifier string
---@param playerName string
---@param account string
---@param amount number  must be >= 0
---@param reason string
---@return number? newBalance
function Economy.SetAccountMoney(identifier, playerName, account, amount, reason)
    if type(amount) ~= "number" or amount < 0 or amount ~= amount or amount == math.huge then
        print(("[^1ECONOMY^7] Invalid set amount for ^5%s^7: ^5%s^7"):format(identifier, tostring(amount)))
        return nil
    end

    amount = math.floor(amount + 0.5)

    local result = PostgreSQL.rawQuery.await(([[
        UPDATE users
        SET accounts = jsonb_set(accounts, '{%s}', to_jsonb(?::numeric))
        WHERE identifier = ?
        RETURNING (accounts->>'%s')::numeric AS new_balance
    ]]):format(account, account), { amount, identifier })

    if not result or not result[1] then
        return nil
    end

    local newBalance = tonumber(result[1].new_balance)
    auditLog(identifier, playerName, "set_money", { account = account, amount = amount, reason = reason, new_balance = newBalance })
    return newBalance
end

---Atomically transfer money between two online players.
---@param fromIdentifier string
---@param fromName string
---@param toIdentifier string
---@param toName string
---@param account string
---@param amount number
---@param reason string
---@return boolean success
function Economy.TransferMoney(fromIdentifier, fromName, toIdentifier, toName, account, amount, reason)
    local newFrom = Economy.RemoveAccountMoney(fromIdentifier, fromName, account, amount, reason .. " -> " .. toName)
    if not newFrom then
        return false
    end
    local newTo = Economy.AddAccountMoney(toIdentifier, toName, account, amount, reason .. " <- " .. fromName)
    if not newTo then
        -- Rollback: give money back to sender
        Economy.AddAccountMoney(fromIdentifier, fromName, account, amount, "rollback: transfer failed")
        return false
    end
    return true
end

return Economy
