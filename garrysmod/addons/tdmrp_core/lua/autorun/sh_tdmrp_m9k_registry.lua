----------------------------------------------------
-- TDMRP M9K Weapon Registry
-- Shared weapon definitions for M9K weapon packs:
--   - Small Arms (pistols, revolvers, SMGs, PDWs)
--   - Assault Rifles (rifles)
--   - Heavy Weapons (shotguns, snipers, LMGs)
----------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

TDMRP = TDMRP or {}

----------------------------------------------------
-- M9K Detection Helper
----------------------------------------------------

function TDMRP.IsM9KWeapon(wepOrClass)
    if not wepOrClass then return false end
    
    local className = nil
    local wep = nil
    if type(wepOrClass) == "string" then
        className = wepOrClass
    elseif IsEntity(wepOrClass) and wepOrClass.GetClass then
        className = wepOrClass:GetClass()
        wep = wepOrClass
    end
    
    if not className then return false end
    
    -- Check for M9K weapons, TDMRP M9K weapons, and CSS weapons
    if string.StartWith(className, "m9k_") or 
       string.StartWith(className, "tdmrp_m9k_") or
       string.StartWith(className, "weapon_tdmrp_cs_") then
        return true
    end
    
    -- Also check for IsTDMRPWeapon flag on the entity
    if wep and wep.IsTDMRPWeapon then
        return true
    end
    
    return false
end

----------------------------------------------------
-- General TDMRP Weapon Detection (includes CSS)
----------------------------------------------------

function TDMRP.IsTDMRPWeaponGeneral(wepOrClass)
    if not wepOrClass then return false end
    
    local className = nil
    local wep = nil
    if type(wepOrClass) == "string" then
        className = wepOrClass
    elseif IsEntity(wepOrClass) and wepOrClass.GetClass then
        className = wepOrClass:GetClass()
        wep = wepOrClass
    end
    
    if not className then return false end
    
    -- Check class prefixes
    if string.StartWith(className, "tdmrp_m9k_") or
       string.StartWith(className, "weapon_tdmrp_cs_") then
        return true
    end
    
    -- Check for IsTDMRPWeapon flag
    if wep and wep.IsTDMRPWeapon then
        return true
    end
    
    return false
end

----------------------------------------------------
-- Weapon Registry
----------------------------------------------------

TDMRP.M9KRegistry = TDMRP.M9KRegistry or {}

-- Registry format:
-- class = SWEP class name
-- id = short identifier
-- name = display name
-- shortName = abbreviated name for HUD
-- type = pistol, revolver, smg, pdw
-- ammoType = HL2 ammo type
-- basePrice = tier 1 price

TDMRP.M9KRegistry = {
    ----------------------------------------------------
    -- PISTOLS
    ----------------------------------------------------
    ["m9k_colt1911"] = {
        id = "colt1911",
        name = "Colt 1911",
        shortName = "1911",
        type = "pistol",
        ammoType = "pistol",
        basePrice = 800,
        lootWeight = 10,
    },
    ["m9k_glock"] = {
        id = "glock",
        name = "Glock 17",
        shortName = "GLOCK",
        type = "pistol",
        ammoType = "pistol",
        basePrice = 600,
        lootWeight = 12,
    },
    ["m9k_hk45"] = {
        id = "hk45",
        name = "HK45",
        shortName = "HK45",
        type = "pistol",
        ammoType = "pistol",
        basePrice = 900,
        lootWeight = 8,
    },
    ["m9k_luger"] = {
        id = "luger",
        name = "Luger P08",
        shortName = "LUGER",
        type = "pistol",
        ammoType = "pistol",
        basePrice = 700,
        lootWeight = 8,
    },
    ["m9k_m92beretta"] = {
        id = "m92beretta",
        name = "Beretta M92",
        shortName = "M92",
        type = "pistol",
        ammoType = "pistol",
        basePrice = 750,
        lootWeight = 10,
    },
    ["m9k_sig_p229r"] = {
        id = "sig_p229r",
        name = "SIG P229R",
        shortName = "P229",
        type = "pistol",
        ammoType = "pistol",
        basePrice = 950,
        lootWeight = 7,
    },
    ["m9k_usp"] = {
        id = "usp",
        name = "H&K USP",
        shortName = "USP",
        type = "pistol",
        ammoType = "pistol",
        basePrice = 850,
        lootWeight = 9,
    },
    
    ----------------------------------------------------
    -- REVOLVERS (.357)
    ----------------------------------------------------
    ["m9k_coltpython"] = {
        id = "coltpython",
        name = "Colt Python",
        shortName = "PYTHON",
        type = "revolver",
        ammoType = "357",
        basePrice = 1200,
        lootWeight = 6,
    },
    ["m9k_deagle"] = {
        id = "deagle",
        name = "Desert Eagle",
        shortName = "DEAGLE",
        type = "pistol",
        ammoType = "357",
        basePrice = 1500,
        lootWeight = 5,
    },
    ["m9k_m29satan"] = {
        id = "m29satan",
        name = "S&W Model 29",
        shortName = "M29",
        type = "revolver",
        ammoType = "357",
        basePrice = 1400,
        lootWeight = 5,
    },
    ["m9k_model3russian"] = {
        id = "model3russian",
        name = "S&W Model 3",
        shortName = "MOD3",
        type = "revolver",
        ammoType = "357",
        basePrice = 900,
        lootWeight = 7,
    },
    ["m9k_model500"] = {
        id = "model500",
        name = "S&W Model 500",
        shortName = "M500",
        type = "revolver",
        ammoType = "357",
        basePrice = 2000,
        lootWeight = 3,
    },
    ["m9k_model627"] = {
        id = "model627",
        name = "S&W Model 627",
        shortName = "M627",
        type = "revolver",
        ammoType = "357",
        basePrice = 1300,
        lootWeight = 5,
    },
    ["m9k_ragingbull"] = {
        id = "ragingbull",
        name = "Taurus Raging Bull",
        shortName = "RAGING",
        type = "revolver",
        ammoType = "357",
        basePrice = 1600,
        lootWeight = 4,
    },
    ["m9k_remington1858"] = {
        id = "remington1858",
        name = "Remington 1858",
        shortName = "REM58",
        type = "revolver",
        ammoType = "357",
        basePrice = 800,
        lootWeight = 8,
    },
    ["m9k_scoped_taurus"] = {
        id = "scoped_taurus",
        name = "Scoped Taurus",
        shortName = "TAURUS",
        type = "revolver",
        ammoType = "357",
        basePrice = 1800,
        lootWeight = 3,
    },
    
    ----------------------------------------------------
    -- SMGs
    ----------------------------------------------------
    ["m9k_bizonp19"] = {
        id = "bizonp19",
        name = "PP-19 Bizon",
        shortName = "BIZON",
        type = "smg",
        ammoType = "smg1",
        basePrice = 2200,
        lootWeight = 5,
    },
    ["m9k_mp40"] = {
        id = "mp40",
        name = "MP40",
        shortName = "MP40",
        type = "smg",
        ammoType = "smg1",
        basePrice = 1800,
        lootWeight = 6,
    },
    ["m9k_mp5"] = {
        id = "mp5",
        name = "H&K MP5",
        shortName = "MP5",
        type = "smg",
        ammoType = "smg1",
        basePrice = 2500,
        lootWeight = 5,
    },
    ["m9k_mp5sd"] = {
        id = "mp5sd",
        name = "H&K MP5SD",
        shortName = "MP5SD",
        type = "smg",
        ammoType = "smg1",
        basePrice = 2800,
        lootWeight = 4,
    },
    ["m9k_mp7"] = {
        id = "mp7",
        name = "H&K MP7",
        shortName = "MP7",
        type = "smg",
        ammoType = "smg1",
        basePrice = 3000,
        lootWeight = 4,
    },
    ["m9k_mp9"] = {
        id = "mp9",
        name = "B&T MP9",
        shortName = "MP9",
        type = "smg",
        ammoType = "smg1",
        basePrice = 2600,
        lootWeight = 5,
    },
    ["m9k_smgp90"] = {
        id = "smgp90",
        name = "FN P90",
        shortName = "P90",
        type = "smg",
        ammoType = "smg1",
        basePrice = 3500,
        lootWeight = 3,
    },
    ["m9k_sten"] = {
        id = "sten",
        name = "STEN",
        shortName = "STEN",
        type = "smg",
        ammoType = "smg1",
        basePrice = 1500,
        lootWeight = 7,
    },
    ["m9k_tec9"] = {
        id = "tec9",
        name = "TEC-9",
        shortName = "TEC9",
        type = "smg",
        ammoType = "pistol",
        basePrice = 1200,
        lootWeight = 8,
    },
    ["m9k_thompson"] = {
        id = "thompson",
        name = "Thompson M1A1",
        shortName = "TOMMY",
        type = "smg",
        ammoType = "smg1",
        basePrice = 2400,
        lootWeight = 5,
    },
    ["m9k_ump45"] = {
        id = "ump45",
        name = "H&K UMP-45",
        shortName = "UMP45",
        type = "smg",
        ammoType = "smg1",
        basePrice = 2700,
        lootWeight = 4,
    },
    ["m9k_usc"] = {
        id = "usc",
        name = "H&K USC",
        shortName = "USC",
        type = "smg",
        ammoType = "smg1",
        basePrice = 2300,
        lootWeight = 5,
    },
    ["m9k_uzi"] = {
        id = "uzi",
        name = "IMI Uzi",
        shortName = "UZI",
        type = "smg",
        ammoType = "pistol",
        basePrice = 1800,
        lootWeight = 6,
    },
    
    ----------------------------------------------------
    -- PDWs (Personal Defense Weapons)
    ----------------------------------------------------
    ["m9k_honeybadger"] = {
        id = "honeybadger",
        name = "AAC Honey Badger",
        shortName = "BADGER",
        type = "pdw",
        ammoType = "smg1",
        basePrice = 4000,
        lootWeight = 2,
    },
    ["m9k_kac_pdw"] = {
        id = "kac_pdw",
        name = "KAC PDW",
        shortName = "KAC",
        type = "pdw",
        ammoType = "smg1",
        basePrice = 3800,
        lootWeight = 3,
    },
    ["m9k_magpulpdr"] = {
        id = "magpulpdr",
        name = "Magpul PDR",
        shortName = "PDR",
        type = "pdw",
        ammoType = "smg1",
        basePrice = 3600,
        lootWeight = 3,
    },
    ["m9k_vector"] = {
        id = "vector",
        name = "KRISS Vector",
        shortName = "VECTOR",
        type = "pdw",
        ammoType = "smg1",
        basePrice = 4500,
        lootWeight = 2,
    },
    
    ----------------------------------------------------
    -- ASSAULT RIFLES (M9K Assault Rifles Pack)
    ----------------------------------------------------
    ["m9k_acr"] = {
        id = "acr",
        name = "ACR",
        shortName = "ACR",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 4500,
    },
    ["m9k_ak47"] = {
        id = "ak47",
        name = "AK-47",
        shortName = "AK47",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 3500,
    },
    ["m9k_ak74"] = {
        id = "ak74",
        name = "AK-74",
        shortName = "AK74",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 3800,
    },
    ["m9k_amd65"] = {
        id = "amd65",
        name = "AMD-65",
        shortName = "AMD65",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 3200,
    },
    ["m9k_an94"] = {
        id = "an94",
        name = "AN-94",
        shortName = "AN94",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 5000,
    },
    ["m9k_auga3"] = {
        id = "auga3",
        name = "AUG A3",
        shortName = "AUG",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 4800,
    },
    ["m9k_f2000"] = {
        id = "f2000",
        name = "FN F2000",
        shortName = "F2000",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 5200,
    },
    ["m9k_fal"] = {
        id = "fal",
        name = "FN FAL",
        shortName = "FAL",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 4500,
    },
    ["m9k_famas"] = {
        id = "famas",
        name = "FAMAS",
        shortName = "FAMAS",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 4000,
    },
    ["m9k_g36"] = {
        id = "g36",
        name = "G36",
        shortName = "G36",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 4600,
    },
    ["m9k_g3a3"] = {
        id = "g3a3",
        name = "G3A3",
        shortName = "G3A3",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 4200,
    },
    ["m9k_l85"] = {
        id = "l85",
        name = "L85A2",
        shortName = "L85",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 4400,
    },
    ["m9k_m14sp"] = {
        id = "m14sp",
        name = "M14",
        shortName = "M14",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 4000,
    },
    ["m9k_m16a4_acog"] = {
        id = "m16a4",
        name = "M16A4 ACOG",
        shortName = "M16",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 4500,
    },
    ["m9k_m416"] = {
        id = "m416",
        name = "HK416",
        shortName = "HK416",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 5500,
    },
    ["m9k_m4a1"] = {
        id = "m4a1",
        name = "M4A1",
        shortName = "M4A1",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 4800,
    },
    ["m9k_scar"] = {
        id = "scar",
        name = "SCAR-H",
        shortName = "SCAR",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 5800,
    },
    ["m9k_tar21"] = {
        id = "tar21",
        name = "TAR-21",
        shortName = "TAR21",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 5000,
    },
    ["m9k_val"] = {
        id = "val",
        name = "AS VAL",
        shortName = "VAL",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 5500,
    },
    ["m9k_vikhr"] = {
        id = "vikhr",
        name = "SR-3 Vikhr",
        shortName = "VIKHR",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 5200,
    },
    ["m9k_winchester73"] = {
        id = "winchester73",
        name = "Winchester 1873",
        shortName = "WIN73",
        type = "rifle",
        ammoType = "ar2",
        basePrice = 3000,
    },
    
    ----------------------------------------------------
    -- SHOTGUNS (M9K Heavy Weapons Pack)
    ----------------------------------------------------
    ["m9k_1887winchester"] = {
        id = "1887winchester",
        name = "1887 Winchester",
        shortName = "1887",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 2500,
        slugEnabled = true,  -- Supports slug mode toggle
    },
    ["m9k_1897winchester"] = {
        id = "1897winchester",
        name = "1897 Trench Gun",
        shortName = "1897",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 2800,
        slugEnabled = true,  -- Supports slug mode toggle
    },
    ["m9k_browningauto5"] = {
        id = "browningauto5",
        name = "Browning Auto-5",
        shortName = "AUTO5",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 3200,
    },
    ["m9k_dbarrel"] = {
        id = "dbarrel",
        name = "Double Barrel",
        shortName = "DBARREL",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 2000,
    },
    ["m9k_ithacam37"] = {
        id = "ithacam37",
        name = "Ithaca M37",
        shortName = "M37",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 2600,
        slugEnabled = true,  -- Supports slug mode toggle
    },
    ["m9k_jackhammer"] = {
        id = "jackhammer",
        name = "Jackhammer",
        shortName = "JACK",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 4000,
        slugEnabled = true,  -- Supports slug mode toggle
    },
    ["m9k_m3"] = {
        id = "m3",
        name = "Benelli M3",
        shortName = "M3",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 3000,
        slugEnabled = true,  -- Supports slug mode toggle
    },
    ["m9k_mossberg590"] = {
        id = "mossberg590",
        name = "Mossberg 590",
        shortName = "M590",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 2800,
        slugEnabled = true,  -- Supports slug mode toggle
    },
    ["m9k_remington870"] = {
        id = "remington870",
        name = "Remington 870",
        shortName = "R870",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 2500,
        slugEnabled = true,  -- Supports slug mode toggle
    },
    ["m9k_spas12"] = {
        id = "spas12",
        name = "SPAS-12",
        shortName = "SPAS",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 3500,
        slugEnabled = true,  -- Supports slug mode toggle
    },
    ["m9k_striker12"] = {
        id = "striker12",
        name = "Striker-12",
        shortName = "STRIKER",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 3800,
        slugEnabled = true,  -- Supports slug mode toggle
    },
    ["m9k_usas"] = {
        id = "usas",
        name = "USAS-12",
        shortName = "USAS",
        type = "shotgun",
        ammoType = "buckshot",
        basePrice = 4200,
        slugEnabled = true,  -- Supports slug mode toggle
    },
    
    ----------------------------------------------------
    -- SNIPER RIFLES (M9K Heavy Weapons Pack)
    ----------------------------------------------------
    ["m9k_aw50"] = {
        id = "aw50",
        name = "AW50",
        shortName = "AW50",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 12000,
    },
    ["m9k_barret_m82"] = {
        id = "barret_m82",
        name = "Barrett M82",
        shortName = "M82",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 15000,
    },
    ["m9k_contender"] = {
        id = "contender",
        name = "Contender G2",
        shortName = "G2",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 5000,
    },
    ["m9k_dragunov"] = {
        id = "dragunov",
        name = "SVD Dragunov",
        shortName = "SVD",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 8000,
    },
    ["m9k_intervention"] = {
        id = "intervention",
        name = "Intervention",
        shortName = "INTER",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 10000,
    },
    ["m9k_m24"] = {
        id = "m24",
        name = "M24",
        shortName = "M24",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 7000,
    },
    ["m9k_m98b"] = {
        id = "m98b",
        name = "M98B",
        shortName = "M98B",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 11000,
    },
    ["m9k_psg1"] = {
        id = "psg1",
        name = "PSG-1",
        shortName = "PSG1",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 9000,
    },
    ["m9k_remington7615p"] = {
        id = "remington7615p",
        name = "Remington 7615P",
        shortName = "7615P",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 6000,
    },
    ["m9k_sl8"] = {
        id = "sl8",
        name = "SL8",
        shortName = "SL8",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 7500,
    },
    ["m9k_svt40"] = {
        id = "svt40",
        name = "SVT-40",
        shortName = "SVT40",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 5500,
    },
    ["m9k_svu"] = {
        id = "svu",
        name = "SVU",
        shortName = "SVU",
        type = "sniper",
        ammoType = "SniperPenetratedRound",
        basePrice = 8500,
    },
    
    ----------------------------------------------------
    -- LIGHT MACHINE GUNS (M9K Heavy Weapons Pack)
    ----------------------------------------------------
    ["m9k_ares_shrike"] = {
        id = "ares_shrike",
        name = "Ares Shrike",
        shortName = "SHRIKE",
        type = "lmg",
        ammoType = "ar2",
        basePrice = 12000,
    },
    ["m9k_fg42"] = {
        id = "fg42",
        name = "FG-42",
        shortName = "FG42",
        type = "lmg",
        ammoType = "ar2",
        basePrice = 8000,
    },
    ["m9k_m1918bar"] = {
        id = "m1918bar",
        name = "M1918 BAR",
        shortName = "BAR",
        type = "lmg",
        ammoType = "ar2",
        basePrice = 9000,
    },
    ["m9k_m249lmg"] = {
        id = "m249lmg",
        name = "M249",
        shortName = "M249",
        type = "lmg",
        ammoType = "ar2",
        basePrice = 14000,
    },
    ["m9k_m60"] = {
        id = "m60",
        name = "M60",
        shortName = "M60",
        type = "lmg",
        ammoType = "ar2",
        basePrice = 15000,
    },
    ["m9k_minigun"] = {
        id = "minigun",
        name = "Minigun",
        shortName = "MINI",
        type = "lmg",
        ammoType = "ar2",
        basePrice = 20000,
    },
    ["m9k_pkm"] = {
        id = "pkm",
        name = "PKM",
        shortName = "PKM",
        type = "lmg",
        ammoType = "ar2",
        basePrice = 13000,
    },
}

----------------------------------------------------
-- Tier System
----------------------------------------------------

TDMRP.TierMultipliers = {
    [1] = { damage = 1.00, rpm = 1.00, accuracy = 1.00, recoil = 1.00, price = 1.0 },
    [2] = { damage = 1.15, rpm = 1.05, accuracy = 1.10, recoil = 0.90, price = 1.5 },
    [3] = { damage = 1.30, rpm = 1.10, accuracy = 1.20, recoil = 0.80, price = 2.5 },
    [4] = { damage = 1.50, rpm = 1.15, accuracy = 1.35, recoil = 0.65, price = 4.0 },
    [5] = { damage = 1.75, rpm = 1.20, accuracy = 1.50, recoil = 0.50, price = 7.0 },
}

----------------------------------------------------
-- Helper Functions
----------------------------------------------------

-- Get weapon registry entry
function TDMRP.GetM9KMeta(className)
    return TDMRP.M9KRegistry[className]
end

-- Get price for weapon at specific tier
function TDMRP.GetWeaponPrice(className, tier)
    local meta = TDMRP.GetM9KMeta(className)
    if not meta then return 0 end
    
    tier = tier or 1
    local tierMult = TDMRP.TierMultipliers[tier]
    if not tierMult then return meta.basePrice end
    
    return math.floor(meta.basePrice * tierMult.price)
end

-- Get all weapons of a specific type
function TDMRP.GetWeaponsByType(weaponType)
    local result = {}
    for class, data in pairs(TDMRP.M9KRegistry) do
        if data.type == weaponType then
            result[class] = data
        end
    end
    return result
end

-- Get all weapon types
function TDMRP.GetWeaponTypes()
    return {"pistol", "revolver", "smg", "pdw"}
end

-- Get display name for weapon type
function TDMRP.GetWeaponTypeName(weaponType)
    local names = {
        pistol = "Pistols",
        revolver = "Revolvers",
        smg = "SMGs",
        pdw = "PDWs",
    }
    return names[weaponType] or weaponType
end

-- Generate random tier (weighted towards lower tiers)
function TDMRP.GetRandomTier()
    local roll = math.random(1, 100)
    if roll <= 45 then return 1      -- 45% Tier 1
    elseif roll <= 75 then return 2  -- 30% Tier 2
    elseif roll <= 90 then return 3  -- 15% Tier 3
    elseif roll <= 98 then return 4  -- 8% Tier 4
    else return 5 end                -- 2% Tier 5
end

-- Generate weighted random weapon
function TDMRP.GetRandomWeapon()
    local totalWeight = 0
    for _, data in pairs(TDMRP.M9KRegistry) do
        totalWeight = totalWeight + (data.lootWeight or 1)
    end
    
    local roll = math.random(1, totalWeight)
    local accumulated = 0
    
    for class, data in pairs(TDMRP.M9KRegistry) do
        accumulated = accumulated + (data.lootWeight or 1)
        if roll <= accumulated then
            return class
        end
    end
    
    -- Fallback
    return "m9k_glock"
end

----------------------------------------------------
-- Instance System
----------------------------------------------------

TDMRP.WeaponInstances = TDMRP.WeaponInstances or {}
TDMRP.NextInstanceID = TDMRP.NextInstanceID or 1

-- Create a new weapon instance
function TDMRP.CreateInstance(className, tier, crafted, gems)
    local meta = TDMRP.GetM9KMeta(className)
    if not meta then return nil end
    
    tier = tier or 1
    crafted = crafted or false
    gems = gems or {}
    
    local instanceID = TDMRP.NextInstanceID
    TDMRP.NextInstanceID = TDMRP.NextInstanceID + 1
    
    local instance = {
        id = instanceID,
        class = className,
        tier = tier,
        crafted = crafted,
        gems = gems,
        createdAt = os.time(),
    }
    
    TDMRP.WeaponInstances[instanceID] = instance
    return instance
end

-- Get instance by ID
function TDMRP.GetInstance(instanceID)
    return TDMRP.WeaponInstances[instanceID]
end

-- Generate display name for instance
function TDMRP.GetInstanceDisplayName(instance)
    if not instance then return "Unknown Weapon" end
    
    local meta = TDMRP.GetM9KMeta(instance.class)
    if not meta then return "Unknown Weapon" end
    
    local name = meta.name .. " T" .. instance.tier
    if instance.crafted then
        name = name .. " ★"
    end
    
    return name
end

-- Generate short display name for HUD
function TDMRP.GetInstanceShortName(instance)
    if not instance then return "???" end
    
    local meta = TDMRP.GetM9KMeta(instance.class)
    if not meta then return "???" end
    
    return meta.shortName
end

----------------------------------------------------
-- Ammo Configuration
----------------------------------------------------

TDMRP.AmmoTypes = {
    ["pistol"] = {
        name = "Pistol Rounds",
        shortName = "9mm",
        price = 50,
        amount = 30,
        icon = "P",
        model = "models/Items/BoxSRounds.mdl",
    },
    ["357"] = {
        name = ".357 Magnum",
        shortName = ".357",
        price = 75,
        amount = 18,
        icon = "M",
        model = "models/Items/357ammo.mdl",
    },
    ["smg1"] = {
        name = "SMG Rounds",
        shortName = "SMG",
        price = 80,
        amount = 60,
        icon = "S",
        model = "models/Items/BoxMRounds.mdl",
    },
    ["ar2"] = {
        name = "Rifle Rounds",
        shortName = "5.56",
        price = 100,
        amount = 60,
        icon = "R",
        model = "models/Items/combine_rifle_cartridge01.mdl",
    },
    ["buckshot"] = {
        name = "Shotgun Shells",
        shortName = "12ga",
        price = 80,
        amount = 24,
        icon = "B",
        model = "models/Items/BoxBuckshot.mdl",
    },
    ["SniperPenetratedRound"] = {
        name = "Sniper Rounds",
        shortName = ".50",
        price = 150,
        amount = 12,
        icon = "X",
        model = "models/Items/sniper_round_box.mdl",
    },
}

function TDMRP.GetAmmoConfig(ammoType)
    return TDMRP.AmmoTypes[ammoType]
end

----------------------------------------------------
-- Helper: Get metadata for a weapon class
-- Supports both m9k_* and tdmrp_m9k_* class names
----------------------------------------------------

function TDMRP.GetM9KMeta(class)
    if not class or class == "" then return nil end
    
    -- Try direct lookup first (m9k_* class)
    if TDMRP.M9KRegistry[class] then
        return TDMRP.M9KRegistry[class]
    end
    
    -- Try stripping tdmrp_ prefix
    if string.sub(class, 1, 6) == "tdmrp_" then
        local baseClass = string.sub(class, 7) -- "tdmrp_m9k_glock" -> "m9k_glock"
        if TDMRP.M9KRegistry[baseClass] then
            return TDMRP.M9KRegistry[baseClass]
        end
    end
    
    return nil
end

----------------------------------------------------
-- Helper: Get display name for a weapon class
----------------------------------------------------

function TDMRP.GetWeaponDisplayName(class)
    local meta = TDMRP.GetM9KMeta(class)
    if meta and meta.name then
        return meta.name
    end
    
    -- Fallback: clean up class name
    local name = class
    name = string.gsub(name, "^tdmrp_m9k_", "")
    name = string.gsub(name, "^m9k_", "")
    name = string.gsub(name, "_", " ")
    name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
    return name
end

----------------------------------------------------
-- Helper: Get short name for a weapon class
----------------------------------------------------

function TDMRP.GetWeaponShortName(class)
    local meta = TDMRP.GetM9KMeta(class)
    if meta and meta.shortName then
        return meta.shortName
    end
    
    -- Fallback: use first 6 chars of cleaned class name
    local name = class
    name = string.gsub(name, "^tdmrp_m9k_", "")
    name = string.gsub(name, "^m9k_", "")
    return string.upper(string.sub(name, 1, 6))
end

print("[TDMRP] sh_tdmrp_m9k_registry.lua loaded - " .. table.Count(TDMRP.M9KRegistry) .. " weapons registered")
