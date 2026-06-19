---@meta

---@class KWJob
---@field id number
---@field name string
---@field label string
---@field type string
---@field grade number
---@field grade_name string
---@field grade_label string
---@field grade_salary number
---@field onDuty boolean

---@class KWAccount
---@field name string
---@field money number
---@field label string
---@field round boolean

---@class xPlayer
---@field identifier string
---@field license string
---@field source number
---@field playerId number
---@field name string
---@field job KWJob
---@field group string
---@field accounts KWAccount[]
---@field maxWeight number
---@field weight number
---@field loadout table
---@field inventory table
---@field metadata table

---@class KWShared
---@field PlayerData xPlayer
---@field Jobs table<string, KWJob>
---@field Items table<string, any>
---@field Config table<string, any>
