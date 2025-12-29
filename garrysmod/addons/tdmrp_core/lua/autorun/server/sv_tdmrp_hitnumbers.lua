-- sv_tdmrp_hitnumbers.lua
-- Hit number system - Intercepts damage at the weapon level

if not SERVER then return end

util.AddNetworkString("TDMRP_HitNumber")
util.AddNetworkString("TDMRP_ChainDamage")

-- Track recent hits to avoid duplicates (penetration can cause multiple hits)
local lastHitTime = {}

-- Helper to send hit number to attacker
function TDMRP_SendHitNumber(attacker, target, dmg, pos, isHeadshot, willKill)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not IsValid(target) then return end
    
    -- Debounce: prevent duplicate numbers from penetration hits (0.1s cooldown per attacker-target combo)
    local key = attacker:SteamID64() .. "_" .. target:EntIndex()
    if lastHitTime[key] and CurTime() - lastHitTime[key] < 0.1 then
        return
    end
    lastHitTime[key] = CurTime()
    
    dmg = math.Round(dmg or 0)
    if dmg <= 0 then return end
    
    -- Validate position
    if not pos or pos == vector_origin then
        if IsValid(target) then
            pos = target:LocalToWorld(target:OBBCenter())
        else
            return
        end
    end
    
    -- Send to attacker only
    net.Start("TDMRP_HitNumber")
        net.WriteVector(pos)
        net.WriteUInt(math.min(dmg, 65535), 16)
        net.WriteBool(isHeadshot or false)
        net.WriteBool(willKill or false)
    net.Send(attacker)

    -- Play headshot kill sound for both players if this is a headshot kill
    if isHeadshot and willKill then
        local playGlobal = GetConVar("tdmrp_play_headshot_sound")
        if not playGlobal or playGlobal:GetInt() == 1 then
            if IsValid(attacker) and attacker.EmitSound then
                attacker:EmitSound("tdmrp/headshot.wav", 90, 100)
            end
            if IsValid(target) and target.EmitSound then
                target:EmitSound("tdmrp/headshot.wav", 90, 100)
            end
        end
    end
end

-- Helper to send chain damage hit number (pale light blue, smaller)
function TDMRP_SendChainDamageNumber(attacker, target, dmg, pos)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not IsValid(target) then return end
    
    dmg = math.Round(dmg or 0)
    if dmg <= 0 then return end
    
    -- Validate position
    if not pos or pos == vector_origin then
        if IsValid(target) then
            pos = target:LocalToWorld(target:OBBCenter())
        else
            return
        end
    end
    
    -- Send chain damage indicator to attacker
    net.Start("TDMRP_ChainDamage")
        net.WriteVector(pos)
        net.WriteUInt(math.min(dmg, 65535), 16)
    net.Send(attacker)
end

-- PRIMARY HOOK: Intercept damage through the weapon mixin system
-- This catches M9K bullets at the source before damage is applied
-- NOTE: DISABLED - The weapon mixin now handles all hit numbers via RicochetCallback
-- hook.Add("OnBulletImpact", "TDMRP_HitNumber", function(attacker, traceResult, dmginfo)
--     if not IsValid(attacker) or not attacker:IsPlayer() then return end
--     
--     local target = traceResult.Entity
--     if not IsValid(target) or (not target:IsPlayer() and not target:IsNPC()) then return end
--     if target == attacker then return end
--     
--     -- Get damage amount
--     local dmg = dmginfo:GetDamage()
--     if dmg <= 0 then return end
--     
--     -- Get impact position
--     local pos = traceResult.HitPos or dmginfo:GetDamagePosition() or target:GetPos()
--     
--     -- Check if headshot (was target hit in head area?)
--     local isHeadshot = false
--     if target:IsPlayer() or target:IsNPC() then
--         local headPos = target:GetBonePosition(target:LookupBone("ValveBiped.Bip01_Head1") or 0)
--         if headPos and pos then
--             isHeadshot = (headPos:Distance(pos) < 8.5)
--         end
--     end
--     
--     -- Check if this will kill them
--     local willKill = (target:Health() - dmg) <= 0
--     
--     SendHitNumber(attacker, target, dmg, pos, isHeadshot, willKill)
-- end)

-- FALLBACK: Also hook EntityTakeDamage in case OnBulletImpact doesn't fire
-- This ensures we catch ANY damage even from non-M9K sources
-- NOTE: DISABLED - The weapon mixin now handles all hit numbers via RicochetCallback
-- hook.Add("EntityTakeDamage", "TDMRP_HitNumber_TakeDamage", function(target, dmginfo)
--     if not IsValid(target) or (not target:IsPlayer() and not target:IsNPC()) then return end
--     
--     local attacker = dmginfo:GetAttacker()
--     if not IsValid(attacker) or not attacker:IsPlayer() then return end
--     if target == attacker then return end
--     
--     local dmg = dmginfo:GetDamage()
--     if dmg <= 0 then return end
--     
--     local pos = dmginfo:GetDamagePosition() or target:GetPos()
--     
--     local isHeadshot = false
--     if dmginfo:GetDamagePosition() then
--         local headPos = target:GetBonePosition(target:LookupBone("ValveBiped.Bip01_Head1") or 0)
--         if headPos then
--             isHeadshot = (headPos:Distance(dmginfo:GetDamagePosition()) < 8.5)
--         end
--     end
--     
--     local willKill = (target:Health() - dmg) <= 0
--     
--     SendHitNumber(attacker, target, dmg, pos, isHeadshot, willKill)
-- end, 200)  -- High priority to run before damage modifiers

-- Clean up debounce table periodically to prevent memory leaks
timer.Create("TDMRP_HitNumber_Cleanup", 30, 0, function()
    table.Empty(lastHitTime)
end)

-- ConVar to toggle headshot kill sound playback
CreateConVar("tdmrp_play_headshot_sound", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Play headshot.wav on headshot kills (1=enabled)")

print("[TDMRP] sv_tdmrp_hitnumbers.lua loaded - Using OnBulletImpact + EntityTakeDamage fallback")
