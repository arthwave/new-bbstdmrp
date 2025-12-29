----------------------------------------------------
-- TDMRP XP System - Shared Definitions
-- Unified XP pool across all combat jobs (Cop + Criminal)
-- Session-based (resets on disconnect)
----------------------------------------------------

TDMRP = TDMRP or {}
TDMRP.XP = TDMRP.XP or {}

if SERVER then
    AddCSLuaFile()
end

----------------------------------------------------
-- XP Sources & Rewards
----------------------------------------------------

TDMRP.XP.Config = {
    -- XP Rewards
    KILL_XP = 10,
    ASSIST_XP = 5,
    CAPTURE_XP = 25,
    
    -- Level Thresholds (exponential scaling)
    MAX_LEVEL = 20,
    BASE_XP = 100,          -- XP needed for level 2
    EXPONENT = 1.15,        -- Exponential growth factor
    
    -- Level Rewards
    REGEN_LEVEL = 5,        -- Level at which HP regen unlocks
    REGEN_AMOUNT = 5,       -- HP per second at level 5+
    
    DAMAGE_LEVEL = 10,      -- Level at which damage boost unlocks
    DAMAGE_BONUS = 0.10,    -- 10% damage increase at level 10+

    -- NPC kills (granted when a player slays an NPC)
    NPC_KILL_XP = 5,
}

----------------------------------------------------
-- Level Threshold Calculation
----------------------------------------------------

function TDMRP.XP.GetXPForLevel(level)
    if level <= 1 then return 0 end
    if level > TDMRP.XP.Config.MAX_LEVEL then 
        return TDMRP.XP.GetXPForLevel(TDMRP.XP.Config.MAX_LEVEL)
    end
    
    -- Exponential formula: XP = BASE_XP * (level - 1)^EXPONENT
    local xp = TDMRP.XP.Config.BASE_XP * math.pow(level - 1, TDMRP.XP.Config.EXPONENT)
    return math.floor(xp)
end

----------------------------------------------------
-- Get level from total XP
----------------------------------------------------

function TDMRP.XP.GetLevelFromXP(totalXP)
    if totalXP < 0 then return 1 end
    
    for level = 1, TDMRP.XP.Config.MAX_LEVEL do
        local required = TDMRP.XP.GetXPForLevel(level + 1)
        if totalXP < required then
            return level
        end
    end
    
    return TDMRP.XP.Config.MAX_LEVEL
end

----------------------------------------------------
-- Get XP progress for current level (0.0 to 1.0)
----------------------------------------------------

function TDMRP.XP.GetLevelProgress(totalXP)
    local level = TDMRP.XP.GetLevelFromXP(totalXP)
    
    if level >= TDMRP.XP.Config.MAX_LEVEL then
        return 1.0 -- Max level
    end
    
    local currentLevelXP = TDMRP.XP.GetXPForLevel(level)
    local nextLevelXP = TDMRP.XP.GetXPForLevel(level + 1)
    local xpIntoLevel = totalXP - currentLevelXP
    local xpNeededForLevel = nextLevelXP - currentLevelXP
    
    if xpNeededForLevel <= 0 then return 1.0 end
    
    return math.Clamp(xpIntoLevel / xpNeededForLevel, 0, 1)
end

----------------------------------------------------
-- Get XP display string for HUD
----------------------------------------------------

function TDMRP.XP.GetXPDisplayString(totalXP)
    local level = TDMRP.XP.GetLevelFromXP(totalXP)
    
    if level >= TDMRP.XP.Config.MAX_LEVEL then
        return string.format("Level %d (MAX)", level)
    end
    
    local currentLevelXP = TDMRP.XP.GetXPForLevel(level)
    local nextLevelXP = TDMRP.XP.GetXPForLevel(level + 1)
    local xpIntoLevel = totalXP - currentLevelXP
    local xpNeededForLevel = nextLevelXP - currentLevelXP
    
    return string.format("Level %d (%d/%d XP)", level, xpIntoLevel, xpNeededForLevel)
end

----------------------------------------------------
-- Check if player has specific level rewards
----------------------------------------------------

function TDMRP.XP.HasRegenReward(totalXP)
    local level = TDMRP.XP.GetLevelFromXP(totalXP)
    return level >= TDMRP.XP.Config.REGEN_LEVEL
end

function TDMRP.XP.HasDamageReward(totalXP)
    local level = TDMRP.XP.GetLevelFromXP(totalXP)
    return level >= TDMRP.XP.Config.DAMAGE_LEVEL
end

----------------------------------------------------
-- Level Threshold Table (for reference)
----------------------------------------------------

if CLIENT then
    -- Print level table on client load (for debugging)
    timer.Simple(1, function()
        print("[TDMRP XP] Level Thresholds:")
        for i = 1, TDMRP.XP.Config.MAX_LEVEL do
            local xp = TDMRP.XP.GetXPForLevel(i)
            print(string.format("  Level %2d: %d XP", i, xp))
        end
    end)
end

print("[TDMRP] sh_tdmrp_xp.lua loaded (XP system definitions)")
