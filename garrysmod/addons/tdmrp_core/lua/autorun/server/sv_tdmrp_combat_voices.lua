----------------------------------------------------
-- TDMRP Combat Voices - Impressive Kill System
-- Plays impressive.mp3 on combat role kills with 20% chance
-- Awards +100 XP, +$100, and chat notification
----------------------------------------------------

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.CombatVoices = TDMRP.CombatVoices or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

local CONFIG = {
    IMPRESSIVE_KILL_CHANCE = 0.20,      -- 20% chance
    IMPRESSIVE_KILL_XP = 100,
    IMPRESSIVE_KILL_MONEY = 100,
    IMPRESSIVE_KILL_SOUND = "tdmrp/quake/impressive.mp3",
    SOUND_VOLUME = 100,
    SOUND_PITCH = 100,
    SOUND_LEVEL = 80,                  -- dB level for sound attenuation
}

----------------------------------------------------
-- Helper: Check if both players are combat roles
----------------------------------------------------

local function IsCombatKill(attacker, victim)
    -- Both must be players
    if not IsValid(attacker) or not attacker:IsPlayer() then return false end
    if not IsValid(victim) or not victim:IsPlayer() then return false end
    
    -- Can't be self-kill
    if attacker == victim then return false end
    
    -- Both must be combat roles (cop or criminal)
    if not TDMRP.DT.IsCombatJob(attacker) then return false end
    if not TDMRP.DT.IsCombatJob(victim) then return false end
    
    return true
end

----------------------------------------------------
-- Helper: Play impressive kill sound at location
----------------------------------------------------

local function PlayImpressiveKillSound(pos)
    -- Emit sound at the death location so nearby players hear it
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            ply:EmitSound(CONFIG.IMPRESSIVE_KILL_SOUND, CONFIG.SOUND_VOLUME, CONFIG.SOUND_PITCH, 1, CHAN_AUTO)
        end
    end
end

----------------------------------------------------
-- Hook: Detect impressive kills on player death
----------------------------------------------------

hook.Add("PlayerDeath", "TDMRP_ImpressiveKill", function(victim, inflictor, attacker)
    -- Random chance check (20%)
    if math.random() > CONFIG.IMPRESSIVE_KILL_CHANCE then return end
    
    -- Validate combat kill
    if not IsCombatKill(attacker, victim) then return end
    
    -- Get attacker position for sound emission
    local pos = attacker:GetPos()
    
    -- Play impressive kill sound
    PlayImpressiveKillSound(pos)
    
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
    
    -- Console debug log
    print(string.format("[TDMRP Combat Voices] %s (Impressive Kill vs %s) - +%d XP +$%d", 
        attacker:Nick(), victim:Nick(), CONFIG.IMPRESSIVE_KILL_XP, CONFIG.IMPRESSIVE_KILL_MONEY))
end)

print("[TDMRP] Combat voices system loaded (Impressive Kill)")
