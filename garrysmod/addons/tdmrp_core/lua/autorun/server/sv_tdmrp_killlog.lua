----------------------------------------------------
-- TDMRP Kill Log System
-- Server-side kill tracking and global broadcast
-- Displays custom weapon names in kill logs
----------------------------------------------------

if CLIENT then return end

TDMRP = TDMRP or {}
TDMRP.KillLog = TDMRP.KillLog or {}

----------------------------------------------------
-- Network String
----------------------------------------------------

util.AddNetworkString("TDMRP_KillLog")

----------------------------------------------------
-- Kill Tracking
----------------------------------------------------

local killStreaks = {}  -- { [ply] = { count, lastKillTime, victim } }
local lastKillTime = {}  -- { [ply] = CurTime() }

local MULTI_KILL_WINDOW = 5  -- Seconds between kills to count as streak

----------------------------------------------------
-- Helper: Get weapon display name
----------------------------------------------------

local function GetWeaponDisplayName(wep)
    if not IsValid(wep) then return "Unknown" end
    
    local customName = wep:GetNWString("TDMRP_CustomName", "")
    if customName ~= "" then
        return customName  -- Return custom name if it exists
    end
    
    -- Otherwise return base gun name without prefix/suffix
    local baseName = wep:GetPrintName() or wep:GetClass()
    baseName = baseName:gsub("^weapon_", ""):gsub("^tdmrp_m9k_", "")
    
    -- Convert to title case
    local function TitleCase(str)
        return str:gsub("([^_])([A-Z])", "%1 %2"):gsub("_", " "):gsub("(%w)([%w']*)", function(a,b) return string.upper(a)..b end)
    end
    baseName = TitleCase(baseName)
    
    return "Custom *" .. baseName .. "*"
end

----------------------------------------------------
-- Broadcast Kill to All Players
----------------------------------------------------

local function BroadcastKill(attacker, victim, weaponName, isHeadshot, killStreak, streakCount, isNPC)
    net.Start("TDMRP_KillLog")
    net.WriteEntity(attacker)
    net.WriteEntity(victim)
    net.WriteString(weaponName)
    net.WriteBool(isHeadshot)
    net.WriteUInt(killStreak, 8)  -- 0=normal, 1=double, 2=triple, 3=quad+
    net.WriteUInt(streakCount, 8)  -- Actual streak count
    net.WriteBool(isNPC or false)  -- Flag: is attacker an NPC?
    net.Broadcast()
    
    local attackerName = isNPC and (attacker:GetNWString("DarkRPDisplayName") or attacker:GetClass() or "NPC") or attacker:Nick()
    print(string.format("[TDMRP Kill] %s killed %s with %s%s%s", 
        attackerName, victim:Nick(), weaponName,
        isHeadshot and " (HEADSHOT)" or "",
        killStreak > 0 and string.format(" (%d-KILL STREAK)" , streakCount) or ""))
end

----------------------------------------------------
-- Hook: On Player Injured
----------------------------------------------------

hook.Add("ScalePlayerDamage", "TDMRP_KillLogTracking", function(ply, hitGroup, dmgInfo)
    -- We'll use PlayerDeath instead for cleaner logic
    return dmgInfo
end)

----------------------------------------------------
-- Hook: On Player Death
----------------------------------------------------

hook.Add("PlayerDeath", "TDMRP_KillLogTracking", function(victim, inflictor, attacker)
    if not IsValid(attacker) then return end
    if attacker == victim then return end  -- Suicide, don't count
    
    local isNPC = attacker:IsNPC()
    local weaponName = "Unknown"
    
    if isNPC then
        -- NPC kill - use NPC name or type
        weaponName = attacker:GetNWString("DarkRPDisplayName") or attacker:GetClass() or "NPC"
        if weaponName:find("npc_") then
            weaponName = weaponName:gsub("npc_", ""):gsub("_", " ")
            weaponName = weaponName:gsub("(%w)([%w']*)", function(a,b) return string.upper(a)..b end)
        end
    else
        -- Player kill - require valid weapon
        local wep = attacker:GetActiveWeapon()
        if not IsValid(wep) then return end
        weaponName = GetWeaponDisplayName(wep)
    end
    
    -- Detect headshot (only for player kills)
    local isHeadshot = false
    if not isNPC then
        isHeadshot = false  -- Would need DamageInfo hook for proper detection
    end
    
    -- Update kill streak (only for player-vs-player)
    local currentTime = CurTime()
    local lastKill = lastKillTime[attacker] or 0
    local streakCount = 1
    local killStreak = 0
    
    if not isNPC then
        if currentTime - lastKill > MULTI_KILL_WINDOW then
            -- Kill streak expired, reset
            killStreaks[attacker] = { count = 1, lastKillTime = currentTime, victim = victim }
        else
            -- Add to streak
            killStreaks[attacker] = killStreaks[attacker] or { count = 0, lastKillTime = currentTime }
            killStreaks[attacker].count = killStreaks[attacker].count + 1
            killStreaks[attacker].lastKillTime = currentTime
            killStreaks[attacker].victim = victim
        end
        
        lastKillTime[attacker] = currentTime
        
        -- Determine kill streak type
        streakCount = killStreaks[attacker].count
        if streakCount >= 4 then
            killStreak = 3  -- Quad+
        elseif streakCount >= 3 then
            killStreak = 2  -- Triple
        elseif streakCount >= 2 then
            killStreak = 1  -- Double
        end
    end
    
    -- Broadcast kill to all players
    BroadcastKill(attacker, victim, weaponName, isHeadshot, killStreak, streakCount, isNPC)
    
    -- Clean up old streaks
    for ply, data in pairs(killStreaks) do
        if not IsValid(ply) or (currentTime - data.lastKillTime) > MULTI_KILL_WINDOW then
            killStreaks[ply] = nil
        end
    end
end)

----------------------------------------------------
-- Hook: On Player Spawn (Reset Kill Streak)
----------------------------------------------------

hook.Add("PlayerSpawn", "TDMRP_KillLogReset", function(ply)
    killStreaks[ply] = nil
    lastKillTime[ply] = nil
end)

----------------------------------------------------
-- Hook: On NPC Death (via Entity Take Damage)
----------------------------------------------------

local npcDeathTracking = {}  -- Track recent NPC health to detect deaths

hook.Add("EntityTakeDamage", "TDMRP_NPCKillTracking", function(npc, dmginfo)
    -- Only track NPCs
    if not npc:IsNPC() then return end
    if not IsValid(npc) then return end
    
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) then return end
    
    -- Store NPC's health before damage
    local healthBeforeDamage = npc:Health()
    local maxHealth = npc:GetMaxHealth()
    local healthAfterDamage = healthBeforeDamage - dmginfo:GetDamage()
    
    -- Check if this damage will kill the NPC
    if healthAfterDamage <= 0 then
        -- NPC will die from this damage - check if attacker is player or NPC
        if not attacker:IsPlayer() and not attacker:IsNPC() then return end
        
        -- Get weapon display name
        local weaponName = "Melee"
        if attacker:IsPlayer() then
            local wep = attacker:GetActiveWeapon()
            if IsValid(wep) then
                weaponName = GetWeaponDisplayName(wep)
            end
        else
            -- Attacker is also an NPC - get its name
            weaponName = attacker:GetNWString("DarkRPDisplayName") or attacker:GetClass() or "NPC"
        end
        
        -- Broadcast NPC kill
        local isNPC = attacker:IsNPC()
        BroadcastKill(attacker, npc, weaponName, false, 0, 1, isNPC)
        
        print(string.format("[TDMRP Kill] NPC %s killed %s", 
            isNPC and (attacker:GetClass()) or attacker:Nick(),
            npc:GetClass()))
    end
end)

print("[TDMRP] Kill log tracking system loaded")
