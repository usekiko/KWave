-- DTF Death Messages - Client-side death detection
-- Tracks local player deaths and sends data to server
-- Includes NPC kill detection for localhost testing

local lastDeathTime = 0
local deathCooldown = 500 -- Reduced to 500ms to prevent duplicates but allow fast kills
local lastKilledPeds = {} -- Track recently killed peds (for NPC mode)
local pendingKills = {} -- Buffer for kills to process

-- Weapon hash to name mapping
local weaponNames = {
    -- Melee
    [-1569615261] = { name = 'Fist' },
    [-1716189206] = { name = 'Knife' },
    [1737195953] = { name = 'Nightstick' },
    [1317494643] = { name = 'Hammer' },
    [-1024456158] = { name = 'Bat' },
    [1141786504] = { name = 'Golf Club' },
    [-2067956739] = { name = 'Crowbar' },
    [-102973651] = { name = 'Hatchet' },
    [-656458692] = { name = 'Knuckle Duster' },
    [-1786099057] = { name = 'Machete' },
    [-2066285827] = { name = 'Flashlight' },
    [-1951375401] = { name = 'Battle Axe' },
    [-1834847097] = { name = 'Dagger' },
    [-1386199700] = { name = 'Bottle' },
    [539292904] = { name = 'Broken Bottle' },
    [-1810792071] = { name = 'Pool Cue' },
    [-2000187721] = { name = 'Switchblade' },
    [940833800] = { name = 'Stone Hatchet' },
    
    -- Pistols
    [453432689] = { name = 'Pistol' },
    [-1075685676] = { name = 'Pistol Mk2' },
    [1593441988] = { name = 'Combat Pistol' },
    [584646201] = { name = 'AP Pistol' },
    [-1716589765] = { name = 'Pistol .50' },
    [-1076751822] = { name = 'SNS Pistol' },
    [-2009644972] = { name = 'SNS Pistol Mk2' },
    [-771403250] = { name = 'Heavy Pistol' },
    [137902532] = { name = 'Vintage Pistol' },
    [-598887786] = { name = 'Marksman Pistol' },
    [-1045183535] = { name = 'Revolver' },
    [-879347409] = { name = 'Revolver Mk2' },
    [911657153] = { name = 'Taser' },
    [1198879012] = { name = 'Flare Gun' },
    [1470379660] = { name = 'Ceramic Pistol' },
    [-1853920116] = { name = 'Navy Revolver' },
    
    -- SMGs
    [736523883] = { name = 'SMG' },
    [2024373456] = { name = 'SMG Mk2' },
    [-270015777] = { name = 'Assault SMG' },
    [171789620] = { name = 'Combat PDW' },
    [-619010992] = { name = 'Machine Pistol' },
    [-1121678507] = { name = 'Mini SMG' },
    [-1660422300] = { name = 'Micro SMG' },
    
    -- Shotguns
    [487013001] = { name = 'Pump Shotgun' },
    [1432025498] = { name = 'Pump Shotgun Mk2' },
    [2017895192] = { name = 'Sawed-Off Shotgun' },
    [-1654528753] = { name = 'Bullpup Shotgun' },
    [-494615257] = { name = 'Assault Shotgun' },
    [-1466123874] = { name = 'Musket' },
    [984333226] = { name = 'Heavy Shotgun' },
    [-275439685] = { name = 'Double Barrel Shotgun' },
    [317205821] = { name = 'Sweeper Shotgun' },
    [94989220] = { name = 'Combat Shotgun' },
    
    -- Assault Rifles
    [-1074790547] = { name = 'Assault Rifle' },
    [961495388] = { name = 'Assault Rifle Mk2' },
    [-2084633992] = { name = 'Carbine Rifle' },
    [-86904375] = { name = 'Carbine Rifle Mk2' },
    [-1357824103] = { name = 'Advanced Rifle' },
    [-1063057011] = { name = 'Special Carbine' },
    [-1768145561] = { name = 'Special Carbine Mk2' },
    [2132975508] = { name = 'Bullpup Rifle' },
    [-2066285827] = { name = 'Bullpup Rifle Mk2' },
    [1649403952] = { name = 'Compact Rifle' },
    [-1658906650] = { name = 'Military Rifle' },
    [-774507221] = { name = 'Tactical Rifle' },
    
    -- LMGs
    [-1660422300] = { name = 'MG' },
    [2144741730] = { name = 'Combat MG' },
    [-608341376] = { name = 'Combat MG Mk2' },
    [1627465347] = { name = 'Gusenberg' },
    
    -- Sniper Rifles
    [100416529] = { name = 'Sniper Rifle' },
    [205991906] = { name = 'Heavy Sniper' },
    [177293209] = { name = 'Heavy Sniper Mk2' },
    [-952879014] = { name = 'Marksman Rifle' },
    [1785463520] = { name = 'Marksman Rifle Mk2' },
    
    -- Heavy Weapons
    [-1312131151] = { name = 'RPG' },
    [-1568386805] = { name = 'Grenade Launcher' },
    [1305664598] = { name = 'Grenade Launcher Smoke' },
    [1119849093] = { name = 'Minigun' },
    [2138347493] = { name = 'Firework' },
    [1834241177] = { name = 'Railgun' },
    [1672152130] = { name = 'Homing Launcher' },
    [125959754] = { name = 'Compact Launcher' },
    [-1238556825] = { name = 'Ray Minigun' },
    
    -- Throwables
    [-1813897027] = { name = 'Grenade' },
    [741814745] = { name = 'Sticky Bomb' },
    [-1420407917] = { name = 'Proximity Mine' },
    [-1600701090] = { name = 'BZ Gas' },
    [615608432] = { name = 'Molotov' },
    [101631238] = { name = 'Fire Extinguisher' },
    [883325847] = { name = 'Petrol Can' },
    [-37975472] = { name = 'Snowball' },
    [600439132] = { name = 'Ball' },
    [126349499] = { name = 'Snowball' },
    [-1169823560] = { name = 'Pipe Bomb' },
    
    -- Miscellaneous
    [-72657034] = { name = 'Parachute' },
    [-1569615261] = { name = 'Unarmed' },
    [1223143800] = { name = 'Barbed Wire' },
    [-1553120962] = { name = 'Drowning' },
    [310817095] = { name = 'Drowning in Vehicle' },
    [-10959621] = { name = 'Bleeding' },
    [419712736] = { name = 'Electric Fence' },
    [-1603817716] = { name = 'Exhaustion' },
    [539292904] = { name = 'Hit by Water Cannon' },
    [-842959696] = { name = 'Run Over by Car' },
    [-544306709] = { name = 'Heli Crash' },
    [148160082] = { name = 'Vehicle' },
    [-1200737721] = { name = 'Vehicle' },
    [160266735] = { name = 'Tank' },
    [69063493] = { name = 'Tank' },
    [-1561147194] = { name = 'Plane' },
}

-- Get weapon info from hash
local function GetWeaponInfo(weaponHash)
    if not weaponHash then return { name = 'Unknown' } end
    return weaponNames[weaponHash] or { name = 'Unknown' }
end

-- Calculate distance between two coordinates
local function CalculateDistance(coords1, coords2)
    if not coords1 or not coords2 then return 0 end
    return math.floor(#(coords1 - coords2))
end

-- Check if entity is an NPC (not a player)
local function IsNPC(entity)
    if not DoesEntityExist(entity) then return false end
    if not IsPedAPlayer(entity) then return true end
    return false
end

-- Get NPC display name
local function GetNPCName(ped)
    if not DoesEntityExist(ped) then return 'NPC' end
    local model = GetEntityModel(ped)
    local modelName = 'NPC'
    
    local commonModels = {
        [-1686014385] = 'Cop',
        [-1323286274] = 'Swat',
        [1581098148] = 'Cop',
        [-1275859404] = 'Gangster',
        [-1620232223] = 'Gangster',
        [588969535] = 'Vagos',
        [-1872961334] = 'Vagos',
        [-198252413] = 'Ballas',
        [-1492432238] = 'Ballas',
        [-1410400252] = 'Families',
        [599294057] = 'Families',
        [768005095] = 'Security',
        [-1422914553] = 'Military',
        [1702441027] = 'Military',
        [1925237458] = 'Firefighter',
        [-1920006714] = 'Paramedic',
    }
    
    if commonModels[model] then
        modelName = commonModels[model]
    end
    
    return modelName .. ' #' .. math.random(100, 999)
end

-- Send kill notification to server (with deduplication)
local lastKillTime = 0
local lastKillTarget = nil
local function SendKillNotification(data)
    local currentTime = GetGameTimer()
    
    -- Prevent duplicate kills within 300ms (same target)
    if lastKillTarget == data.npcName and (currentTime - lastKillTime) < 300 then
        return
    end
    
    lastKillTime = currentTime
    lastKillTarget = data.npcName
    
    TriggerServerEvent('kw_deathmessages:npckilled', data)
end

-- Handle player death
AddEventHandler('baseevents:onPlayerDied', function(killerType, deathCoords)
    local currentTime = GetGameTimer()
    if currentTime - lastDeathTime < deathCooldown then return end
    lastDeathTime = currentTime
    
    TriggerServerEvent('kw_deathmessages:playerDied', {
        killer = nil,
        weapon = nil,
        headshot = false,
        distance = 0,
        suicide = false,
        environmental = true
    })
end)

-- Handle player killed by another player
AddEventHandler('baseevents:onPlayerKilled', function(killerServerId, deathData)
    local currentTime = GetGameTimer()
    if currentTime - lastDeathTime < deathCooldown then return end
    lastDeathTime = currentTime
    
    local killerPlayer = GetPlayerFromServerId(killerServerId)
    local killerPed = nil
    local killerCoords = nil
    local victimCoords = GetEntityCoords(PlayerPedId())
    
    if killerPlayer and killerPlayer ~= -1 then
        killerPed = GetPlayerPed(killerPlayer)
        killerCoords = GetEntityCoords(killerPed)
    end
    
    local distance = CalculateDistance(killerCoords, victimCoords)
    local weaponHash = deathData.weaponhash
    local headshot = deathData.wasHeadshot or false
    local weaponInfo = GetWeaponInfo(weaponHash)
    
    TriggerServerEvent('kw_deathmessages:playerKilled', {
        killer = killerServerId,
        weapon = weaponInfo,
        headshot = headshot,
        distance = distance
    })
end)

-- NPC Death Detection (optimized to 0.00ms via CEventNetworkEntityDamage)
AddEventHandler('gameEventTriggered', function(eventName, args)
    if not Config.EnableNPCDeaths then return end
    if eventName == 'CEventNetworkEntityDamage' then
        local victim = args[1]
        local culprit = args[2]
        local isFatal = args[6] == 1
        local weaponHash = args[7]
        
        if isFatal and victim and culprit then
            local playerPed = PlayerPedId()
            
            -- Check if victim is an NPC and culprit is us
            if victim ~= playerPed and not IsPedAPlayer(victim) and culprit == playerPed then
                -- Dedup Check (since game events can sometimes double-fire)
                local pedId = victim
                if not lastKilledPeds[pedId] then
                    lastKilledPeds[pedId] = true
                    
                    local pedCoords = GetEntityCoords(victim)
                    local playerCoords = GetEntityCoords(playerPed)
                    local distance = CalculateDistance(playerCoords, pedCoords)
                    
                    local bone = GetPedLastDamageBone(victim)
                    local headshot = (bone == 31086) -- SKEL_Head
                    
                    local weaponInfo = GetWeaponInfo(weaponHash)
                    local npcName = GetNPCName(victim)
                    
                    SendKillNotification({
                        weapon = weaponInfo,
                        headshot = headshot,
                        distance = distance,
                        npcName = npcName
                    })
                    
                    if Config.Debug then
                        print('[^7DTF Death Messages^7] NPC Kill: ' .. npcName .. ' with ' .. weaponInfo.name)
                    end
                end
            end
        end
    end
end)

-- Cleanup old ped IDs periodically
CreateThread(function()
    while true do
        Wait(10000)
        for ped, _ in pairs(lastKilledPeds) do
            if not DoesEntityExist(ped) then
                lastKilledPeds[ped] = nil
            end
        end
    end
end)

-- Start message
CreateThread(function()
    Wait(2000)
    if Config.EnableNPCDeaths then
        print('[^7DTF Death Messages^7] NPC kill tracking ENABLED (Optimized 0.00ms mode)')
    else
        print('[^7DTF Death Messages^7] NPC kill tracking DISABLED')
    end
end)

-- Update NPC setting from server
RegisterNetEvent('kw_deathmessages:updateNPCSetting')
AddEventHandler('kw_deathmessages:updateNPCSetting', function(enabled)
    Config.EnableNPCDeaths = enabled
    print('[^7DTF Death Messages^7] NPC tracking updated: ' .. tostring(enabled))
end)

-- Receive death message from server
RegisterNetEvent('kw_deathmessages:showKillFeed')
AddEventHandler('kw_deathmessages:showKillFeed', function(data)
    -- Use kw_notify to display the death message (silent - no sound)
    local message = data.title .. ' - ' .. data.message
    exports['kw_notify']:ShowNotification(message, 'error', true)
end)

print('[^7DTF Death Messages^7] Client loaded - Improved detection active')
