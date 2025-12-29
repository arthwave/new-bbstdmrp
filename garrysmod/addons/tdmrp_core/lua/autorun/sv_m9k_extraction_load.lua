----------------------------------------------------
-- TDMRP M9K Framework Initialization
-- Sets up ConVars and globals that M9K weapons expect
-- Weapons are auto-loaded by GMod from weapons/ folder
----------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

-- ⚠️ M9K FRAMEWORK: Create ConVars that M9K weapons expect
-- M9K weapons reference these globals - provide defaults since original addon is not loaded
if not GetConVar("M9KDefaultClip") then
    CreateConVar("M9KDefaultClip", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "M9K default clip multiplier")
end

if not GetConVar("M9KDamageMultiplier") then
    CreateConVar("M9KDamageMultiplier", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "M9K damage multiplier")
end

if not GetConVar("M9KUniqueSlots") then
    CreateConVar("M9KUniqueSlots", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "M9K unique weapon slots")
end

if not GetConVar("M9KDisablePenetration") then
    CreateConVar("M9KDisablePenetration", "0", FCVAR_REPLICATED + FCVAR_ARCHIVE, "Disable M9K penetration")
end

if not GetConVar("M9KDynamicRecoil") then
    CreateConVar("M9KDynamicRecoil", "1", FCVAR_REPLICATED + FCVAR_ARCHIVE, "M9K dynamic recoil")
end

if not GetConVar("DebugM9K") then
    CreateConVar("DebugM9K", "0", FCVAR_REPLICATED + FCVAR_ARCHIVE, "M9K debug mode")
end

-- ⚠️ SAFETY: Patch gmod.GetGamemode() for M9K weapons
-- M9K code calls this during weapon load before gamemode exists
-- Provide a safe wrapper that returns a table with a dummy Name
local orig_GetGamemode = gmod.GetGamemode
function gmod.GetGamemode()
    local gm = orig_GetGamemode()
    if not gm then
        return {Name = "Unknown"}  -- Safe fallback
    end
    return gm
end

-- ⚠️ NOTE: Weapons are loaded automatically by GMod from the weapons/ folder
-- DO NOT manually include() weapon files - that breaks SWEP context
-- Base classes (bobs_gun_base, etc.) are also auto-loaded by GMod

-- List of 42 extracted M9K weapons for reference/tracking
local M9K_EXTRACTED_WEAPONS = {
    -- Pistols (5)
    "m9k_colt1911",
    "m9k_hk45",
    "m9k_m92beretta",
    "m9k_sig_p229r",
    "m9k_luger",
    
    -- Revolvers (6)
    "m9k_coltpython",
    "m9k_deagle",
    "m9k_m29satan",
    "m9k_model500",
    "m9k_ragingbull",
    "m9k_model627",
    
    -- SMGs (5)
    "m9k_mp5sd",
    "m9k_mp7",
    "m9k_thompson",
    "m9k_uzi",
    "m9k_mp40",
    
    -- PDWs (3)
    "m9k_honeybadger",
    "m9k_vector",
    "m9k_magpulpdr",
    
    -- Assault Rifles (13)
    "m9k_an94",
    "m9k_fal",
    "m9k_g36",
    "m9k_l85",
    "m9k_m416",
    "m9k_scar",
    "m9k_tar21",
    "m9k_val",
    "m9k_ak74",
    "m9k_amd65",
    "m9k_f2000",
    "m9k_g3a3",
    "m9k_m16a4_acog",
    "m9k_acr",
    
    -- Shotguns (3)
    "m9k_spas12",
    "m9k_1887winchester",
    "m9k_jackhammer",
    
    -- Snipers (2)
    "m9k_intervention",
    "m9k_barret_m82",
    
    -- LMGs (2)
    "m9k_m249lmg",
    "m9k_m60",
    
    -- Misc (2)
    "m9k_mp9",
    "m9k_bizonp19",
}

-- Register extracted weapons in TDMRP system
if TDMRP then
    TDMRP.ExtractedM9KWeapons = M9K_EXTRACTED_WEAPONS
    print("[TDMRP] M9K framework initialized - " .. #M9K_EXTRACTED_WEAPONS .. " weapons in tdmrp_core")
end
