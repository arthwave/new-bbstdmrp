----------------------------------------------------
-- TDMRP Damage Threshold (DT) System - Server
-- Handles flat damage reduction, warnings, and sounds
-- NOTE: Main DT damage reduction is in sh_tdmrp_job_stats.lua
-- This file handles audio/visual feedback only
----------------------------------------------------

if CLIENT then return end

TDMRP = TDMRP or {}
TDMRP.DT = TDMRP.DT or {}

----------------------------------------------------
-- State tracking for cooldowns
----------------------------------------------------

local lastWarningTime = {}  -- [attackerSteamID][victimSteamID] = lastTime
local lastSoundTime = {}    -- [victimSteamID] = lastTime

----------------------------------------------------
-- Play impact sounds and warnings for high DT targets
-- NOTE: Actual damage reduction is handled in sh_tdmrp_job_stats.lua
----------------------------------------------------

hook.Add("EntityTakeDamage", "TDMRP_DT_Feedback", function(target, dmginfo)
    -- Only apply to players
    if not IsValid(target) or not target:IsPlayer() then return end
    
    local attacker = dmginfo:GetAttacker()
    
    -- Get victim's DT
    local dt = TDMRP.DT.GetTotalDT(target)
    
    -- Only proceed with warnings/sounds if attacker is a valid player and DT >= threshold
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if dt < TDMRP.DT.Config.soundThreshold then return end
    
    local attackerID = attacker:SteamID64() or "BOT"
    local victimID = target:SteamID64() or "BOT"
    local curTime = CurTime()
    
    -- Play metal deflection sound (0.25s cooldown)
    lastSoundTime[victimID] = lastSoundTime[victimID] or 0
    if curTime - lastSoundTime[victimID] >= TDMRP.DT.Config.impactSoundCooldown then
        lastSoundTime[victimID] = curTime
        
        -- Play sound at victim's position with random pitch
        local pitch = math.random(90, 110)
        sound.Play(TDMRP.DT.Config.impactSound, target:GetPos(), 75, pitch, 1)
    end
    
    -- Send chat warning to attacker (1s cooldown per target)
    lastWarningTime[attackerID] = lastWarningTime[attackerID] or {}
    lastWarningTime[attackerID][victimID] = lastWarningTime[attackerID][victimID] or 0
    
    if curTime - lastWarningTime[attackerID][victimID] >= TDMRP.DT.Config.warningCooldown then
        lastWarningTime[attackerID][victimID] = curTime
        
        local dtName = TDMRP.DT.GetDTName(target)
        
        -- Send warning message to attacker
        attacker:ChatPrint("[TDMRP] Target is heavily armored! " .. 
            string.format("%d DT (%s) - %d damage absorbed per hit", dt, dtName, dt))
    end
end)

----------------------------------------------------
-- Cleanup old cooldown entries periodically
----------------------------------------------------

timer.Create("TDMRP_DT_Cleanup", 60, 0, function()
    local curTime = CurTime()
    
    -- Clean up old warning entries
    for attackerID, victims in pairs(lastWarningTime) do
        for victimID, time in pairs(victims) do
            if curTime - time > 10 then
                victims[victimID] = nil
            end
        end
        if table.Count(victims) == 0 then
            lastWarningTime[attackerID] = nil
        end
    end
    
    -- Clean up old sound entries
    for victimID, time in pairs(lastSoundTime) do
        if curTime - time > 10 then
            lastSoundTime[victimID] = nil
        end
    end
end)

print("[TDMRP] sv_tdmrp_dr.lua loaded (now using DT system)")
