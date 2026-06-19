---@module 'guard'
--- Server-side event validation and rate limiting for KWave.
--- Wrap any RegisterNetEvent handler with Guard.Check() to validate
--- inputs and prevent event spam.

local Guard = {}

-- Rate limit state: { [source] = { [event] = { count, reset_time } } }
local rateLimits = {}

--- Check rate limit for a player on a specific event.
--- Returns false if the player has exceeded the limit.
---@param source number
---@param event string
---@param maxPerSecond number  max calls allowed per second
---@return boolean allowed
function Guard.RateLimit(source, event, maxPerSecond)
    local now = GetGameTimer()
    rateLimits[source] = rateLimits[source] or {}
    local state = rateLimits[source][event] or { count = 0, reset = now + 1000 }

    if now > state.reset then
        state.count = 0
        state.reset = now + 1000
    end

    state.count = state.count + 1
    rateLimits[source][event] = state

    if state.count > maxPerSecond then
        local name = GetPlayerName(source) or tostring(source)
        print(("[^3GUARD^7] Rate limit exceeded: ^5%s^7 (id:%d) on event ^5%s^7 (%d/s)"):format(
            name, source, event, state.count
        ))
        return false
    end
    return true
end

--- Clean up rate limit state when a player disconnects.
---@param source number
function Guard.ClearPlayer(source)
    rateLimits[source] = nil
end

--- Validate a set of values against a schema.
--- Schema example:
--- {
---   { type = "integer", min = 1, max = 500 },      -- positional: validates values[1]
---   { type = "string",  maxlen = 64, notempty = true },
---   { type = "string",  enum = {"item_standard","item_account"} },
---   { type = "number",  min = 0 },
--- }
---@param source number   player source (for logging)
---@param schema table    array of field descriptors
---@param values table    array of values to check (matching schema order)
---@return boolean valid
function Guard.Validate(source, schema, values)
    for i, rule in ipairs(schema) do
        local val = values[i]
        local t = rule.type

        if t == "integer" then
            if type(val) ~= "number" or math.type(val) ~= "integer" then
                return Guard._fail(source, i, "expected integer, got " .. type(val))
            end
            if rule.min and val < rule.min then
                return Guard._fail(source, i, ("value %d < min %d"):format(val, rule.min))
            end
            if rule.max and val > rule.max then
                return Guard._fail(source, i, ("value %d > max %d"):format(val, rule.max))
            end

        elseif t == "number" then
            if type(val) ~= "number" or val ~= val or val == math.huge then
                return Guard._fail(source, i, "expected number, got " .. type(val))
            end
            if rule.min and val < rule.min then
                return Guard._fail(source, i, ("value %g < min %g"):format(val, rule.min))
            end
            if rule.max and val > rule.max then
                return Guard._fail(source, i, ("value %g > max %g"):format(val, rule.max))
            end

        elseif t == "string" then
            if type(val) ~= "string" then
                return Guard._fail(source, i, "expected string, got " .. type(val))
            end
            if rule.notempty and val == "" then
                return Guard._fail(source, i, "empty string not allowed")
            end
            if rule.maxlen and #val > rule.maxlen then
                return Guard._fail(source, i, ("string length %d > maxlen %d"):format(#val, rule.maxlen))
            end
            if rule.enum then
                local found = false
                for _, allowed in ipairs(rule.enum) do
                    if val == allowed then found = true; break end
                end
                if not found then
                    return Guard._fail(source, i, ("invalid enum value '%s'"):format(val))
                end
            end

        elseif t == "boolean" then
            if type(val) ~= "boolean" then
                return Guard._fail(source, i, "expected boolean, got " .. type(val))
            end
        end
    end
    return true
end

function Guard._fail(source, field, reason)
    local name = GetPlayerName(source) or tostring(source)
    print(("[^3GUARD^7] Validation failed for ^5%s^7 (id:%d) field[%d]: %s"):format(
        name, source, field, reason
    ))
    return false
end

-- Auto-cleanup rate limit state on disconnect
AddEventHandler("playerDropped", function()
    Guard.ClearPlayer(source)
end)

return Guard
