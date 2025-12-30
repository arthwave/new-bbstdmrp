----------------------------------------------------
-- TDMRP Weapon Loadout System
-- Manages 63-weapon arsenal (21 CS:S + 42 M9K)
-- Filters shop, spawns, and loot to active weapons only
----------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

-- CRITICAL: ALL weapon classes MUST be the TDMRP wrappers
-- CSS = weapon_tdmrp_cs_*
-- M9K = tdmrp_m9k_*
-- NEVER use base m9k_* classes in this list!

TDMRP = TDMRP or {}

TDMRP.ActiveWeaponLoadout = {
    ----------------------------------------------------
    -- CSS WEAPONS (21) - weapon_tdmrp_cs_*
    ----------------------------------------------------
    -- Pistols (6)
    "weapon_tdmrp_cs_glock18",
    "weapon_tdmrp_cs_usp",
    "weapon_tdmrp_cs_p228",
    "weapon_tdmrp_cs_five_seven",
    "weapon_tdmrp_cs_elites",
    "weapon_tdmrp_cs_desert_eagle",
    -- SMGs (5)
    "weapon_tdmrp_cs_mp5a5",
    "weapon_tdmrp_cs_p90",
    "weapon_tdmrp_cs_mac10",
    "weapon_tdmrp_cs_tmp",
    "weapon_tdmrp_cs_ump_45",
    -- Rifles (6)
    "weapon_tdmrp_cs_ak47",
    "weapon_tdmrp_cs_m4a1",
    "weapon_tdmrp_cs_aug",
    "weapon_tdmrp_cs_famas",
    "weapon_tdmrp_cs_sg552",
    "weapon_tdmrp_cs_galil",
    -- Shotgun (1)
    "weapon_tdmrp_cs_pumpshotgun",
    -- Snipers (2)
    "weapon_tdmrp_cs_awp",
    "weapon_tdmrp_cs_scout",
    -- Melee (1)
    "weapon_tdmrp_cs_knife",
    
    ----------------------------------------------------
    -- M9K WEAPONS (42) - tdmrp_m9k_* (only those with valid bases)
    ----------------------------------------------------
    -- Pistols (5)
    "tdmrp_m9k_colt1911",
    "tdmrp_m9k_hk45",
    "tdmrp_m9k_m92beretta",
    "tdmrp_m9k_sig_p229r",
    "tdmrp_m9k_luger",
    -- Revolvers (6)
    "tdmrp_m9k_coltpython",
    "tdmrp_m9k_deagle",
    "tdmrp_m9k_m29satan",
    "tdmrp_m9k_model500",
    "tdmrp_m9k_ragingbull",
    "tdmrp_m9k_model627",
    -- SMGs (8)
    "tdmrp_m9k_mp5sd",
    "tdmrp_m9k_mp7",
    "tdmrp_m9k_thompson",
    "tdmrp_m9k_uzi",
    "tdmrp_m9k_mp40",
    "tdmrp_m9k_mp9",
    "tdmrp_m9k_bizonp19",
    -- PDWs (3)
    "tdmrp_m9k_honeybadger",
    "tdmrp_m9k_vector",
    "tdmrp_m9k_magpulpdr",
    -- Rifles (14)
    "tdmrp_m9k_an94",
    "tdmrp_m9k_fal",
    "tdmrp_m9k_g36",
    "tdmrp_m9k_l85",
    "tdmrp_m9k_m416",
    "tdmrp_m9k_scar",
    "tdmrp_m9k_tar21",
    "tdmrp_m9k_val",
    "tdmrp_m9k_ak74",
    "tdmrp_m9k_amd65",
    "tdmrp_m9k_f2000",
    "tdmrp_m9k_g3a3",
    "tdmrp_m9k_m16a4_acog",
    "tdmrp_m9k_acr",
    -- Shotguns (3)
    "tdmrp_m9k_spas12",
    "tdmrp_m9k_1887winchester",
    "tdmrp_m9k_jackhammer",
    -- Snipers (2)
    "tdmrp_m9k_intervention",
    "tdmrp_m9k_barret_m82",
    -- LMGs (3)
    "tdmrp_m9k_m249lmg",
    "tdmrp_m9k_m60",
}

-- Build lookup table for fast checking
TDMRP.ActiveWeaponsLookup = {}
for _, wepClass in ipairs(TDMRP.ActiveWeaponLoadout) do
    TDMRP.ActiveWeaponsLookup[wepClass] = true
end

-- Helper: Check if weapon is in active loadout
function TDMRP.IsActiveWeapon(weaponClass)
    return TDMRP.ActiveWeaponsLookup[weaponClass] == true
end

-- Helper: Get all active weapons
function TDMRP.GetActiveWeapons()
    return TDMRP.ActiveWeaponLoadout
end

-- Helper: Get all active weapons of a type
function TDMRP.GetActiveWeaponsByType(weaponType)
    local result = {}
    for _, class in ipairs(TDMRP.ActiveWeaponLoadout) do
        local meta = TDMRP.GetM9KMeta(class)
        if meta and meta.type == weaponType then
            table.insert(result, class)
        end
    end
    return result
end

-- Override: Random weapon selection (for loot/drops)
-- Now uses only active weapons
local originalGetRandomWeapon = TDMRP.GetRandomWeapon
function TDMRP.GetRandomWeapon()
    local totalWeight = 0
    local activeWeapons = {}
    
    for _, class in ipairs(TDMRP.ActiveWeaponLoadout) do
        local meta = TDMRP.GetM9KMeta(class)
        if meta then
            local weight = meta.lootWeight or 1
            totalWeight = totalWeight + weight
            table.insert(activeWeapons, {class = class, weight = weight})
        end
    end
    
    if totalWeight == 0 then
        return TDMRP.ActiveWeaponLoadout[1] or "weapon_tdmrp_cs_glock18"
    end
    
    local roll = math.random(1, totalWeight)
    local accumulated = 0
    
    for _, weapon in ipairs(activeWeapons) do
        accumulated = accumulated + weapon.weight
        if roll <= accumulated then
            return weapon.class
        end
    end
    
    return TDMRP.ActiveWeaponLoadout[1] or "weapon_tdmrp_cs_glock18"
end

-- Debug/verification
print("[TDMRP] Weapon Loadout System Initialized")
print("[TDMRP] Total Active Weapons: " .. #TDMRP.ActiveWeaponLoadout)
print("[TDMRP]   CSS Weapons: 18")
print("[TDMRP]   M9K Weapons: 42")
print("[TDMRP] Ready for deployment (no M9K addon dependency)")
