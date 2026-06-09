-- === DTF Core Configuration ===

Config = {}

-- === NOTIFICATION SETTINGS ===
Config.Notifications = {
    -- Engine health warnings
    EngineBroken = true,      -- Notify when engine dies
    EngineDamaged = true,   -- Notify at 30% health
    
    -- Health warnings
    LowHealth = true,       -- Notify at 25% health
    
    -- Death
    Death = true,           -- Show death notification
    
    -- Vehicle damage
    FuelLeak = true,        -- Notify when fuel tank damaged
    BodyDamage = true,      -- Notify at 30% body health
    
    -- Ammo
    OutOfAmmo = true,       -- Notify when clip empty
    LowAmmo = true          -- Notify at 5 or less ammo
}

-- === ENGINE TOGGLE SETTINGS ===
Config.EngineToggle = {
    Enabled = true,         -- Enable/disable engine toggle
    Key = 'Y',              -- Key to toggle engine (when in driver seat)
    -- Key codes: https://docs.fivem.net/docs/game-references/controls/
    -- Y = INPUT_MP_TEXT_CHAT_TEAM (246)
}

-- === QUICK VEHICLE LEAVE SETTINGS ===
Config.QuickLeave = {
    Enabled = true         -- Enable/disable instant vehicle exit (no animation)
}
