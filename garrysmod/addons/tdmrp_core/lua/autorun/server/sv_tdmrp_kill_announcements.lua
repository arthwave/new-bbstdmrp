----------------------------------------------------
-- TDMRP Quake Kill Announcements
-- Plays Quake-style voice lines for kill streaks and special kills
----------------------------------------------------

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.KillAnnouncements = TDMRP.KillAnnouncements or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

local CONFIG = {
    ENABLED = true,                    -- Enable/disable announcements
    BURST_WINDOW = 10,                 -- Seconds for burst kills (multi-kills in quick succession)
    CONSECUTIVE_RESET_TIME = 15,       -- Seconds without kill to reset consecutive streak
    REVENGE_WINDOW = 1,                -- Seconds for Impressive (revenge kill)
    VOLUME = 90,                       -- Sound volume
    PITCH = 100,                       -- Sound pitch
}

----------------------------------------------------
-- Sound Mappings
----------------------------------------------------

local ANNOUNCEMENTS = {
    [1] = { name = "Double Kill", sound = "tdmrp/quake/doublekill.mp3", condition = "burst", threshold = 2 },
    [2] = { name = "Triple Kill", sound = "tdmrp/quake/triplekill.mp3", condition = "burst", threshold = 3 },
    [4] = { name = "Killing Spree", sound = "tdmrp/quake/killingspree.mp3", condition = "consecutive", threshold = 4 },
    [5] = { name = "Impressive", sound = "tdmrp/quake/impressive.mp3", condition = "revenge" },
    [7] = { name = "Monster Kill", sound = "tdmrp/quake/monsterkill.mp3", condition = "burst", threshold = 5 },
    [8] = { name = "Ultra Kill", sound = "tdmrp/quake/ultrakill.mp3", condition = "burst", threshold = 4 },
    [9] = { name = "Dominating", sound = "tdmrp/quake/dominating.mp3", condition = "consecutive", threshold = 5 },
    [10] = { name = "Holy Shit", sound = "tdmrp/quake/holyshit.mp3", condition = "burst", threshold = 6 },
    [11] = { name = "Godlike", sound = "tdmrp/quake/godlike.mp3", condition = "consecutive", threshold = 8 },
}

----------------------------------------------------
-- State Tracking
----------------------------------------------------

local PlayerStreaks = {}          -- Consecutive kill streaks: [steamID] = {count, lastKillTime}
local BurstKills = {}             -- Burst kill tracking: [steamID] = {firstKillTime, count}
local RecentDamage = {}           -- For Impressive: [attacker][victim] = time of last damage

----------------------------------------------------
-- Helper: Get player streak data
----------------------------------------------------

local function GetStreakData(ply)
    local sid = ply:SteamID64()
    PlayerStreaks[sid] = PlayerStreaks[sid] or { count = 0, lastKillTime = 0 }
    return PlayerStreaks[sid]
end

local function GetBurstData(ply)
    local sid = ply:SteamID64()
    BurstKills[sid] = BurstKills[sid] or { firstKillTime = 0, count = 0 }
    return BurstKills[sid]
end

----------------------------------------------------
-- Helper: Play announcement sound
----------------------------------------------------

local function PlayAnnouncement(soundPath)
    if not CONFIG.ENABLED then return end
    
    -- Play globally for all players
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:EmitSound(soundPath, CONFIG.VOLUME, CONFIG.PITCH)
        end
    end
end

----------------------------------------------------
-- Helper: Check and trigger announcements
----------------------------------------------------

local function CheckAnnouncements(attacker, victim)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    
    local curTime = CurTime()
    
    -- Update consecutive streak
    local streakData = GetStreakData(attacker)
    streakData.count = streakData.count + 1
    streakData.lastKillTime = curTime
    
    -- Check consecutive announcements
    for id, ann in pairs(ANNOUNCEMENTS) do
        if ann.condition == "consecutive" and streakData.count == ann.threshold then
            PlayAnnouncement(ann.sound)
            print(string.format("[TDMRP Kill Announce] %s: %s (%d consecutive)", attacker:Nick(), ann.name, streakData.count))
            break
        end
    end
    
    -- Update burst kills
    local burstData = GetBurstData(attacker)
    if burstData.firstKillTime == 0 or (curTime - burstData.firstKillTime) > CONFIG.BURST_WINDOW then
        -- Start new burst
        burstData.firstKillTime = curTime
        burstData.count = 1
    else
        -- Continue burst
        burstData.count = burstData.count + 1
    end
    
    -- Check burst announcements
    for id, ann in pairs(ANNOUNCEMENTS) do
        if ann.condition == "burst" and burstData.count == ann.threshold then
            PlayAnnouncement(ann.sound)
            print(string.format("[TDMRP Kill Announce] %s: %s (%d in burst)", attacker:Nick(), ann.name, burstData.count))
            break
        end
    end
    
    -- Check Impressive (revenge kill)
    local impressiveAnn = ANNOUNCEMENTS[5]
    if impressiveAnn and RecentDamage[attacker] then
        for teammate, damageTime in pairs(RecentDamage[attacker]) do
            if IsValid(teammate) and teammate:IsPlayer() and (curTime - damageTime) <= CONFIG.REVENGE_WINDOW then
                -- Victim recently damaged attacker's teammate
                PlayAnnouncement(impressiveAnn.sound)
                print(string.format("[TDMRP Kill Announce] %s: %s (revenge on %s)", attacker:Nick(), impressiveAnn.name, victim:Nick()))
                break
            end
        end
    end
end

----------------------------------------------------
-- Hook: Track damage for Impressive
----------------------------------------------------

hook.Add("EntityTakeDamage", "TDMRP_TrackDamageForImpressive", function(ent, dmginfo)
    if not IsValid(ent) or not ent:IsPlayer() then return end
    
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == ent then return end
    
    -- Track damage from victim to attacker's teammates
    pcall(function()
        local attackerTeam = attacker:GetTeam()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply ~= attacker then
                local plyTeam = ply:GetTeam()
                if plyTeam == attackerTeam then
                    RecentDamage[ply] = RecentDamage[ply] or {}
                    RecentDamage[ply][ent] = CurTime()
                end
            end
        end
    end)
end)

----------------------------------------------------
-- Hook: Process kills and announcements
----------------------------------------------------

hook.Add("PlayerDeath", "TDMRP_KillAnnouncements", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end
    
    -- Process announcements for this kill
    CheckAnnouncements(attacker, victim)
    
    -- Reset victim's streaks
    local victimSid = victim:SteamID64()
    PlayerStreaks[victimSid] = nil
    BurstKills[victimSid] = nil
end)

----------------------------------------------------
-- Timer: Reset old streaks and damage tracking
----------------------------------------------------

timer.Create("TDMRP_KillAnnouncements_Cleanup", 30, 0, function()
    local curTime = CurTime()
    
    -- Reset consecutive streaks that are too old
    for sid, data in pairs(PlayerStreaks) do
        if (curTime - data.lastKillTime) > CONFIG.CONSECUTIVE_RESET_TIME then
            PlayerStreaks[sid] = nil
        end
    end
    
    -- Reset burst kills that are too old
    for sid, data in pairs(BurstKills) do
        if (curTime - data.firstKillTime) > CONFIG.BURST_WINDOW then
            BurstKills[sid] = nil
        end
    end
    
    -- Clean up old damage tracking
    for ply, damages in pairs(RecentDamage) do
        for victim, time in pairs(damages) do
            if (curTime - time) > CONFIG.REVENGE_WINDOW then
                damages[victim] = nil
            end
        end
        if table.Count(damages) == 0 then
            RecentDamage[ply] = nil
        end
    end
end)

----------------------------------------------------
-- ConVar: Enable/disable announcements
----------------------------------------------------

CreateConVar("tdmrp_quake_announcements", "1", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Enable Quake-style kill announcements (1=enabled)")

----------------------------------------------------
-- Console Commands: Test announcements
----------------------------------------------------

for id, ann in pairs(ANNOUNCEMENTS) do
    concommand.Add("tdmrp_test_announcement_" .. id, function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsAdmin() then return end
        
        PlayAnnouncement(ann.sound)
        ply:ChatPrint(string.format("[TDMRP] Testing announcement: %s", ann.name))
    end)
end

concommand.Add("tdmrp_test_announcement_all", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    for id, ann in pairs(ANNOUNCEMENTS) do
        timer.Simple(id * 2, function() -- Stagger playback
            PlayAnnouncement(ann.sound)
        end)
    end
    
    ply:ChatPrint("[TDMRP] Testing all announcements (staggered)")
end)

----------------------------------------------------
-- Cleanup on disconnect
----------------------------------------------------

hook.Add("PlayerDisconnected", "TDMRP_KillAnnouncements_Cleanup", function(ply)
    if not IsValid(ply) then return end
    
    local sid = ply:SteamID64()
    PlayerStreaks[sid] = nil
    BurstKills[sid] = nil
    RecentDamage[ply] = nil
end)

print("[TDMRP] sv_tdmrp_kill_announcements.lua loaded - Quake kill announcements enabled")