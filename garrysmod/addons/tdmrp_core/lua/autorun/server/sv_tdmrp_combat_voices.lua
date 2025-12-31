----------------------------------------------------
-- TDMRP Combat Voices System
-- Kill Confirmed, Enemy Spotted, and Impressive Kill sounds
-- Faction-specific voice lines for cops vs criminals
----------------------------------------------------

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.CombatVoices = TDMRP.CombatVoices or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

local CONFIG = {
    -- Impressive Kill (Quake-style bonus)
    IMPRESSIVE_KILL_CHANCE = 0.20,      -- 20% chance
    IMPRESSIVE_KILL_XP = 100,
    IMPRESSIVE_KILL_MONEY = 100,
    IMPRESSIVE_KILL_SOUND = "tdmrp/quake/impressive.mp3",
    
    -- Kill Confirmed Voice Lines
    KILL_CONFIRMED_CHANCE = 1.0,       -- 100% chance (testing)
    
    -- Enemy Spotted Voice Lines
    ENEMY_SPOTTED_CHANCE = 1.0,        -- 100% chance (testing)
    ENEMY_SPOTTED_DISTANCE = 1000,      -- Units for line of sight detection
    ENEMY_SPOTTED_COOLDOWN = 30,        -- Seconds before can trigger again
    
    -- Sound Settings
    SOUND_VOLUME = 85,                  -- Volume level
    SOUND_PITCH = 100,                  -- Pitch
    SOUND_LEVEL = 75,                   -- dB level (75 = ~1000 unit range)
    SOUND_MULTIPLIER = 3.0,             -- Volume multiplier (3.0 = 200% louder)
}

----------------------------------------------------
-- Sound Tables
----------------------------------------------------

local SOUNDS = {
    -- Cop Kill Confirmed (6 sounds)
    cop_kill = {
        "tdmrp/cvoice/copkillconfirmed1.mp3",
        "tdmrp/cvoice/copkillconfirmed2.mp3",
        "tdmrp/cvoice/copkillconfirmed3.mp3",
        "tdmrp/cvoice/copkillconfirmed4.mp3",
        "tdmrp/cvoice/copkillconfirmed5.mp3",
        "tdmrp/cvoice/copkillconfirmed6.mp3",
    },
    
    -- Criminal Kill Confirmed (6 sounds)
    criminal_kill = {
        "tdmrp/cvoice/crimkillconfirmed1.mp3",
        "tdmrp/cvoice/crimkillconfirmed2.mp3",
        "tdmrp/cvoice/crimkillconfirmed3.mp3",
        "tdmrp/cvoice/crimkillconfirmed4.mp3",
        "tdmrp/cvoice/crimkillconfirmed5.mp3",
        "tdmrp/cvoice/crimkillconfirmed6.mp3",
    },
    
    -- Cop Enemy Spotted (3 sounds)
    cop_spotted = {
        "tdmrp/cvoice/copenemyspotted1.mp3",
        "tdmrp/cvoice/copenemyspotted2.mp3",
        "tdmrp/cvoice/copenemyspotted3.mp3",
    },
    
    -- Criminal Enemy Spotted (3 sounds)
    criminal_spotted = {
        "tdmrp/cvoice/crimenemyspotted1.mp3",
        "tdmrp/cvoice/crimenemyspotted2.mp3",
        "tdmrp/cvoice/crimenemyspotted3.mp3",
    },
}

----------------------------------------------------
-- State Tracking
----------------------------------------------------

local LastSpottedTime = {}  -- [steamID] = CurTime() of last enemy spotted callout

----------------------------------------------------
-- Helper: Get random sound from table
----------------------------------------------------

local function GetRandomSound(soundTable)
    return soundTable[math.random(#soundTable)]
end

----------------------------------------------------
-- Helper: Get player's combat faction
-- Returns "cop", "criminal", or nil
----------------------------------------------------

local function GetCombatFaction(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil end
    if not TDMRP.DT or not TDMRP.DT.GetJobCategory then return nil end
    
    local category = TDMRP.DT.GetJobCategory(ply)
    if category == "cop" or category == "criminal" then
        return category
    end
    return nil
end

----------------------------------------------------
-- Helper: Check if two players are opposing factions
----------------------------------------------------

local function AreOpposingFactions(ply1, ply2)
    local faction1 = GetCombatFaction(ply1)
    local faction2 = GetCombatFaction(ply2)
    
    if not faction1 or not faction2 then return false end
    return faction1 ~= faction2
end

----------------------------------------------------
-- Helper: Play 3D sound at player location
----------------------------------------------------

local function PlayLocalSound(ply, soundPath)
    if not IsValid(ply) then return end
    
    sound.Play(soundPath, ply:GetPos(), CONFIG.SOUND_LEVEL, CONFIG.SOUND_PITCH, CONFIG.SOUND_MULTIPLIER)
end

----------------------------------------------------
-- Helper: Check line of sight between two players
----------------------------------------------------

local function HasLineOfSight(ply1, ply2)
    if not IsValid(ply1) or not IsValid(ply2) then return false end
    
    local startPos = ply1:EyePos()
    local endPos = ply2:EyePos()
    
    local tr = util.TraceLine({
        start = startPos,
        endpos = endPos,
        filter = ply1,
        mask = MASK_VISIBLE_AND_NPCS,
    })
    
    return tr.Entity == ply2 or not tr.Hit
end

----------------------------------------------------
-- KILL CONFIRMED SYSTEM
----------------------------------------------------

local function TryPlayKillConfirmed(attacker, victim)
    -- Random chance check (50%)
    if math.random() > CONFIG.KILL_CONFIRMED_CHANCE then return end
    
    -- Must be opposing factions
    if not AreOpposingFactions(attacker, victim) then return end
    
    -- Get attacker's faction and play appropriate sound
    local faction = GetCombatFaction(attacker)
    if not faction then return end
    
    local soundTable = faction == "cop" and SOUNDS.cop_kill or SOUNDS.criminal_kill
    local soundPath = GetRandomSound(soundTable)
    
    -- Delay sound by 1.75 seconds to avoid interference with combat sounds
    timer.Simple(1.75, function()
        if IsValid(attacker) then
            PlayLocalSound(attacker, soundPath)
        end
    end)
    
    print(string.format("[TDMRP Combat Voices] %s (%s) Kill Confirmed (delayed 1.75s) vs %s - %s", 
        attacker:Nick(), faction, victim:Nick(), soundPath))
end

----------------------------------------------------
-- ENEMY SPOTTED SYSTEM
----------------------------------------------------

local function CanTriggerSpotted(ply)
    local sid = ply:SteamID64()
    local lastTime = LastSpottedTime[sid] or 0
    return CurTime() - lastTime >= CONFIG.ENEMY_SPOTTED_COOLDOWN
end

local function SetSpottedCooldown(ply)
    local sid = ply:SteamID64()
    LastSpottedTime[sid] = CurTime()
end

local function TryPlayEnemySpotted(spotter, target)
    -- Check cooldown
    if not CanTriggerSpotted(spotter) then return end
    
    -- Random chance check (50%)
    if math.random() > CONFIG.ENEMY_SPOTTED_CHANCE then return end
    
    -- Must be opposing factions
    if not AreOpposingFactions(spotter, target) then return end
    
    -- Check distance
    local distance = spotter:GetPos():Distance(target:GetPos())
    if distance > CONFIG.ENEMY_SPOTTED_DISTANCE then return end
    
    -- Check line of sight
    if not HasLineOfSight(spotter, target) then return end
    
    -- Get spotter's faction and play appropriate sound
    local faction = GetCombatFaction(spotter)
    if not faction then return end
    
    local soundTable = faction == "cop" and SOUNDS.cop_spotted or SOUNDS.criminal_spotted
    local soundPath = GetRandomSound(soundTable)
    
    -- Play sound at spotter's location
    PlayLocalSound(spotter, soundPath)
    
    -- Set cooldown
    SetSpottedCooldown(spotter)
    
    print(string.format("[TDMRP Combat Voices] %s (%s) Enemy Spotted: %s (%.0f units) - %s", 
        spotter:Nick(), faction, target:Nick(), distance, soundPath))
end

----------------------------------------------------
-- IMPRESSIVE KILL SYSTEM (Quake bonus)
----------------------------------------------------

local function TryPlayImpressiveKill(attacker, victim)
    -- Random chance check (20%)
    if math.random() > CONFIG.IMPRESSIVE_KILL_CHANCE then return end
    
    -- Must be opposing factions
    if not AreOpposingFactions(attacker, victim) then return end
    
    -- Play impressive sound to all players
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:EmitSound(CONFIG.IMPRESSIVE_KILL_SOUND, 100, CONFIG.SOUND_PITCH, CONFIG.SOUND_MULTIPLIER, CHAN_AUTO)
        end
    end
    
    -- Award XP (if XP system exists)
    if TDMRP.XP and TDMRP.XP.AddXP then
        TDMRP.XP.AddXP(attacker, CONFIG.IMPRESSIVE_KILL_XP, "Impressive Kill")
    end
    
    -- Award money
    if attacker.addMoney then
        attacker:addMoney(CONFIG.IMPRESSIVE_KILL_MONEY)
    end
    
    -- Chat notification
    attacker:ChatPrint(string.format("[TDMRP] Impressive Kill! - +%d XP +$%d", 
        CONFIG.IMPRESSIVE_KILL_XP, CONFIG.IMPRESSIVE_KILL_MONEY))
    
    print(string.format("[TDMRP Combat Voices] %s (Impressive Kill vs %s) - +%d XP +$%d", 
        attacker:Nick(), victim:Nick(), CONFIG.IMPRESSIVE_KILL_XP, CONFIG.IMPRESSIVE_KILL_MONEY))
end

----------------------------------------------------
-- Hook: Player Death (Kill Confirmed + Impressive)
----------------------------------------------------

hook.Add("PlayerDeath", "TDMRP_CombatVoices_Kill", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not IsValid(victim) or not victim:IsPlayer() then return end
    if attacker == victim then return end
    
    -- Try kill confirmed voice line
    TryPlayKillConfirmed(attacker, victim)
    
    -- Try impressive kill (separate roll)
    TryPlayImpressiveKill(attacker, victim)
end)

----------------------------------------------------
-- Think Hook: Enemy Spotted Detection
----------------------------------------------------

local NextSpottedCheck = 0
local SPOTTED_CHECK_INTERVAL = 0.5  -- Check every 0.5 seconds

hook.Add("Think", "TDMRP_CombatVoices_EnemySpotted", function()
    local curTime = CurTime()
    if curTime < NextSpottedCheck then return end
    NextSpottedCheck = curTime + SPOTTED_CHECK_INTERVAL
    
    -- Get all combat players
    local combatPlayers = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            local faction = GetCombatFaction(ply)
            if faction then
                table.insert(combatPlayers, { ply = ply, faction = faction })
            end
        end
    end
    
    -- Check each pair of opposing faction players
    for i, data1 in ipairs(combatPlayers) do
        for j, data2 in ipairs(combatPlayers) do
            if i ~= j and data1.faction ~= data2.faction then
                -- Only check if player can trigger spotted (cooldown)
                if CanTriggerSpotted(data1.ply) then
                    TryPlayEnemySpotted(data1.ply, data2.ply)
                end
            end
        end
    end
end)

----------------------------------------------------
-- Cleanup on disconnect
----------------------------------------------------

hook.Add("PlayerDisconnected", "TDMRP_CombatVoices_Cleanup", function(ply)
    if not IsValid(ply) then return end
    local sid = ply:SteamID64()
    if sid then
        LastSpottedTime[sid] = nil
    end
end)

print("[TDMRP] Combat voices system loaded (Kill Confirmed, Enemy Spotted, Impressive Kill)")
