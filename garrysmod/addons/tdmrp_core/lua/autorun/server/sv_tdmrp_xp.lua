----------------------------------------------------
-- TDMRP XP System - Server Logic
-- Track XP per player, handle kill/assist/capture events
-- Apply level rewards (regen, damage boost)
----------------------------------------------------

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.XP = TDMRP.XP or {}

----------------------------------------------------
-- Network Strings
----------------------------------------------------

util.AddNetworkString("TDMRP_XP_Sync")
util.AddNetworkString("TDMRP_XP_Gain")
util.AddNetworkString("TDMRP_XP_LevelUp")

----------------------------------------------------
-- XP Storage (session-based, resets on disconnect)
----------------------------------------------------

TDMRP.XP.PlayerXP = TDMRP.XP.PlayerXP or {}

----------------------------------------------------
-- Get/Set Player XP
----------------------------------------------------

function TDMRP.XP.GetPlayerXP(ply)
    if not IsValid(ply) or not ply.SteamID64 then return 0 end
    
    local sid = ply:SteamID64()
    return TDMRP.XP.PlayerXP[sid] or 0
end

function TDMRP.XP.SetPlayerXP(ply, xp)
    if not IsValid(ply) or not ply.SteamID64 then return end
    
    local sid = ply:SteamID64()
    TDMRP.XP.PlayerXP[sid] = math.max(0, xp)
    
    -- Sync to client
    TDMRP.XP.SyncToClient(ply)
end

----------------------------------------------------
-- Add XP to player
----------------------------------------------------

function TDMRP.XP.AddXP(ply, amount, reason)
    if not IsValid(ply) then return end
    if amount <= 0 then return end
    
    local oldXP = TDMRP.XP.GetPlayerXP(ply)
    local oldLevel = TDMRP.XP.GetLevelFromXP(oldXP)
    
    local newXP = oldXP + amount
    TDMRP.XP.SetPlayerXP(ply, newXP)
    
    local newLevel = TDMRP.XP.GetLevelFromXP(newXP)
    
    -- Notify client of XP gain
    net.Start("TDMRP_XP_Gain")
        net.WriteUInt(amount, 16)
        net.WriteString(reason or "")
    net.Send(ply)
    
    print(string.format("[TDMRP XP] %s gained %d XP (%s) - Total: %d", ply:Nick(), amount, reason or "unknown", newXP))
    
    -- Check for level up
    if newLevel > oldLevel then
        TDMRP.XP.OnLevelUp(ply, oldLevel, newLevel)
    end
    
    -- Reapply buffs in case rewards changed
    TDMRP.XP.ApplyLevelBuffs(ply)
end

----------------------------------------------------
-- Level Up Handler
----------------------------------------------------

function TDMRP.XP.OnLevelUp(ply, oldLevel, newLevel)
    if not IsValid(ply) then return end
    
    -- Notify client
    net.Start("TDMRP_XP_LevelUp")
        net.WriteUInt(newLevel, 8)
    net.Send(ply)
    
    -- Chat message
    local msg = string.format("[TDMRP] %s reached Level %d!", ply:Nick(), newLevel)
    
    -- Add reward info
    if newLevel == TDMRP.XP.Config.REGEN_LEVEL then
        msg = msg .. " (Unlocked: +5 HP/s Regeneration)"
    elseif newLevel == TDMRP.XP.Config.DAMAGE_LEVEL then
        msg = msg .. " (Unlocked: +10% Damage Boost)"
    end
    
    PrintMessage(HUD_PRINTTALK, msg)
    print(string.format("[TDMRP XP] %s leveled up: %d -> %d", ply:Nick(), oldLevel, newLevel))
end

----------------------------------------------------
-- Apply Level Buffs (called on spawn, level up, etc.)
----------------------------------------------------

function TDMRP.XP.ApplyLevelBuffs(ply)
    if not IsValid(ply) then return end
    
    local xp = TDMRP.XP.GetPlayerXP(ply)
    
    -- Store buff status on player (for damage hook to read)
    ply.TDMRP_HasRegenBuff = TDMRP.XP.HasRegenReward(xp)
    ply.TDMRP_HasDamageBuff = TDMRP.XP.HasDamageReward(xp)
    
    print(string.format("[TDMRP XP] Applied buffs for %s - Regen: %s, Damage: %s", 
        ply:Nick(), 
        tostring(ply.TDMRP_HasRegenBuff), 
        tostring(ply.TDMRP_HasDamageBuff)
    ))
end

----------------------------------------------------
-- HP Regeneration (Level 5+)
----------------------------------------------------

timer.Create("TDMRP_XP_Regen", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() and ply.TDMRP_HasRegenBuff then
            local maxHP = ply:GetMaxHealth()
            local currentHP = ply:Health()
            
            if currentHP < maxHP then
                local newHP = math.min(maxHP, currentHP + TDMRP.XP.Config.REGEN_AMOUNT)
                ply:SetHealth(newHP)
            end
        end
    end
end)

----------------------------------------------------
-- Damage Boost Hook (Level 10+)
----------------------------------------------------

hook.Add("EntityTakeDamage", "TDMRP_XP_DamageBoost", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not attacker.TDMRP_HasDamageBuff then return end
    
    -- Apply 10% damage bonus
    local originalDamage = dmginfo:GetDamage()
    local boostedDamage = originalDamage * (1 + TDMRP.XP.Config.DAMAGE_BONUS)
    dmginfo:SetDamage(boostedDamage)
end)

----------------------------------------------------
-- Kill/Assist Tracking
----------------------------------------------------

hook.Add("PlayerDeath", "TDMRP_XP_OnKill", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not IsValid(victim) or not victim:IsPlayer() then return end
    if attacker == victim then return end -- No XP for suicide
    
    -- Give kill XP
    TDMRP.XP.AddXP(attacker, TDMRP.XP.Config.KILL_XP, "Kill")
    
    -- TODO: Assist tracking (need damage tracking system)
end)

-- NPC Kill Tracking
hook.Add("OnNPCKilled", "TDMRP_XP_OnNPCKilled", function(npc, attacker, inflictor)
    if not IsValid(npc) then return end
    if not IsValid(attacker) then return end

    local ply = nil

    -- Direct player attacker
    if attacker:IsPlayer() then
        ply = attacker
    else
        -- Check for owner (turrets, props, sentries, etc.) safely
        if attacker.GetOwner then
            local owner = attacker:GetOwner()
            if IsValid(owner) and owner:IsPlayer() then
                ply = owner
            end
        end
        -- Fallback: sometimes inflictor may be the player (thrown weapon/projectile)
        if not ply and IsValid(inflictor) and inflictor:IsPlayer() then
            ply = inflictor
        end
    end

    if not IsValid(ply) or not ply:IsPlayer() then return end

    -- Award NPC kill XP (configurable)
    local amt = TDMRP.XP.Config.NPC_KILL_XP or 5
    TDMRP.XP.AddXP(ply, amt, "NPC Kill")
end)

----------------------------------------------------
-- Control Point Capture Handler
-- Called by control point system when player captures a point
----------------------------------------------------

function TDMRP.XP.OnControlPointCapture(ply)
    if not IsValid(ply) then return end
    
    TDMRP.XP.AddXP(ply, TDMRP.XP.Config.CAPTURE_XP, "Control Point Capture")
end

----------------------------------------------------
-- Network Sync to Client
----------------------------------------------------

function TDMRP.XP.SyncToClient(ply)
    if not IsValid(ply) then return end
    
    local xp = TDMRP.XP.GetPlayerXP(ply)
    
    net.Start("TDMRP_XP_Sync")
        net.WriteUInt(xp, 32)
    net.Send(ply)
end

----------------------------------------------------
-- Initialize Player XP on Spawn
----------------------------------------------------

hook.Add("PlayerInitialSpawn", "TDMRP_XP_Init", function(ply)
    local sid = ply:SteamID64()
    if not sid then return end
    
    -- Initialize to 0 if not exists
    if not TDMRP.XP.PlayerXP[sid] then
        TDMRP.XP.PlayerXP[sid] = 0
    end
    
    -- Sync to client
    timer.Simple(1, function()
        if IsValid(ply) then
            TDMRP.XP.SyncToClient(ply)
        end
    end)
end)

----------------------------------------------------
-- Cleanup on Disconnect
----------------------------------------------------

hook.Add("PlayerDisconnected", "TDMRP_XP_Cleanup", function(ply)
    if not IsValid(ply) or not ply.SteamID64 then return end
    
    local sid = ply:SteamID64()
    
    -- Reset XP (session-based)
    TDMRP.XP.PlayerXP[sid] = nil
    
    print("[TDMRP XP] Reset XP for " .. ply:Nick() .. " (disconnected)")
end)

----------------------------------------------------
-- Admin Commands
----------------------------------------------------

concommand.Add("tdmrp_xp_set", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    
    local target = args[1] and player.GetByID(tonumber(args[1]))
    local amount = tonumber(args[2])
    
    if not IsValid(target) or not amount then
        print("[TDMRP XP] Usage: tdmrp_xp_set <player_id> <xp>")
        return
    end
    
    TDMRP.XP.SetPlayerXP(target, amount)
    print(string.format("[TDMRP XP] Set %s XP to %d", target:Nick(), amount))
end)

concommand.Add("tdmrp_xp_add", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    
    local target = args[1] and player.GetByID(tonumber(args[1]))
    local amount = tonumber(args[2])
    
    if not IsValid(target) or not amount then
        print("[TDMRP XP] Usage: tdmrp_xp_add <player_id> <xp>")
        return
    end
    
    TDMRP.XP.AddXP(target, amount, "Admin Command")
end)

concommand.Add("tdmrp_xp_reset", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    
    local target = args[1] and player.GetByID(tonumber(args[1]))
    
    if not IsValid(target) then
        print("[TDMRP XP] Usage: tdmrp_xp_reset <player_id>")
        return
    end
    
    TDMRP.XP.SetPlayerXP(target, 0)
    print(string.format("[TDMRP XP] Reset %s XP to 0", target:Nick()))
end)

print("[TDMRP] sv_tdmrp_xp.lua loaded (XP tracking & rewards)")
