> **KWave Refactor Notice**
> This resource has been refactored and ported to **KWave Framework** and **PostgreSQL (oxpsql)** for improved performance and native database support. 
> 
> *Credit & Disclaimer: This code is based on original works from the ESX and OX projects. All original copyright, licenses, and mentions of ESX/OX are preserved below for full legal compliance and respect for the original authors.*

---
# Revive System

A lightweight standalone revive system compatible with KW Legacy. Works exactly like kw_ambulancejob's revive functionality.

## Features

- `/revive [playerId]` - Revive a specific player (or yourself if no ID)
- `/reviveall` - Revive all dead players
- Saves death status to database (`is_dead` column in `users` table)
- Automatic death detection
- Compatible with txAdmin heal
- Same database queries as kw_ambulancejob

## Database

Uses the same queries as kw_ambulancejob:
```sql
UPDATE users SET is_dead = ? WHERE identifier = ?
SELECT is_dead FROM users WHERE identifier = ?
```

## Installation

1. Place `revive_system` folder in your resources directory
2. Add to `server.cfg`:
   ```
   ensure revive_system
   ```
   
   Place it AFTER kw_core but before other resources that might depend on death status.

## Commands

| Command | Permission | Description |
|---------|------------|-------------|
| `/revive [id]` | admin | Revive yourself or another player |
| `/reviveall` | admin | Revive all players |

## Events

### Server Events
```lua
-- Revive a player
TriggerEvent('revive_system:revive', playerId)

-- Set death status
TriggerServerEvent('revive_system:setDeathStatus', true/false)
```

### Client Events
```lua
-- Revive yourself
TriggerEvent('revive_system:revive')
```

## Dependencies

- KW Legacy
- oxpsql

## How it works

1. When a player dies, `kw:onPlayerDeath` is triggered
2. Server sets `is_dead = true` in database
3. Player sees death effects and can't move
4. Admin uses `/revive` command
5. Server updates `is_dead = false` in database
6. Client revives player at current location
