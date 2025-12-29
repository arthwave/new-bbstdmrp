----------------------------------------------------
-- TDMRP Accuracy System
-- Movement penalty for accuracy, sniper bonuses, shotgun crosshair
-- Per-weapon base spread and movement penalty customization
----------------------------------------------------

TDMRP = TDMRP or {}
TDMRP.Accuracy = TDMRP.Accuracy or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

TDMRP.Accuracy.Config = {
    -- Default movement spread multipliers (used if weapon not in WeaponStats)
    normalMovingMultiplier = 5,       -- 5x spread when moving for normal guns
    sniperMovingMultiplier = 15,      -- 15x spread when moving for snipers (50% more than before)
    sniperStillBonus = 0.1,           -- 10% of base spread when standing still (laser accurate)
    
    -- Velocity thresholds
    stillThreshold = 10,              -- Below this = standing still
    walkThreshold = 100,              -- Below this = walking, above = running
    
    -- Weapon type detection (fallback)
    sniperAmmoTypes = {
        ["SniperPenetratedRound"] = true,
    },
    
    shotgunAmmoTypes = {
        ["buckshot"] = true,
        ["slam"] = true,
    },
}

----------------------------------------------------
-- Per-Weapon Stats Table
-- baseSpread: Base accuracy when standing still (lower = more accurate)
-- movePenalty: Multiplier when moving at full speed (higher = worse accuracy)
-- Note: Snipers ignore baseSpread (use sniperStillBonus instead)
----------------------------------------------------

TDMRP.Accuracy.WeaponStats = {
    ----------------------------------------------------
    -- PISTOLS - Light, decent accuracy, moderate move penalty
    ----------------------------------------------------
    ["m9k_colt1911"] = {
        baseSpread = 0.018,      -- Classic .45, good accuracy
        movePenalty = 3.5,       -- Light, easy to shoot while moving
    },
    ["m9k_glock"] = {
        baseSpread = 0.015,      -- Very accurate polymer pistol
        movePenalty = 3.0,       -- Lightweight, best pistol for moving
    },
    ["m9k_hk45"] = {
        baseSpread = 0.016,      -- Modern, accurate
        movePenalty = 3.2,       -- Ergonomic design
    },
    ["m9k_luger"] = {
        baseSpread = 0.022,      -- Old design, less accurate
        movePenalty = 3.8,       -- Awkward grip angle
    },
    ["m9k_m92beretta"] = {
        baseSpread = 0.017,      -- Military standard, reliable
        movePenalty = 3.3,       -- Well-balanced
    },
    ["m9k_sig_p229r"] = {
        baseSpread = 0.014,      -- Premium accuracy
        movePenalty = 3.4,       -- Heavier, but quality
    },
    ["m9k_usp"] = {
        baseSpread = 0.015,      -- Excellent accuracy
        movePenalty = 3.2,       -- Ergonomic, match-grade
    },
    
    ----------------------------------------------------
    -- REVOLVERS - Powerful, accurate when still, punished when moving
    ----------------------------------------------------
    ["m9k_coltpython"] = {
        baseSpread = 0.012,      -- Match-grade revolver
        movePenalty = 4.5,       -- Heavy barrel, hard to control moving
    },
    ["m9k_deagle"] = {
        baseSpread = 0.020,      -- Semi-auto, more spread
        movePenalty = 5.5,       -- Very heavy, huge recoil
    },
    ["m9k_m29satan"] = {
        baseSpread = 0.014,      -- Dirty Harry's gun, accurate
        movePenalty = 5.0,       -- .44 Magnum kick
    },
    ["m9k_model3russian"] = {
        baseSpread = 0.025,      -- Antique, less refined
        movePenalty = 4.2,       -- Lighter caliber
    },
    ["m9k_model500"] = {
        baseSpread = 0.016,      -- Modern, well-made
        movePenalty = 6.5,       -- .500 S&W - massive recoil
    },
    ["m9k_model627"] = {
        baseSpread = 0.013,      -- 8-shot accuracy
        movePenalty = 4.8,       -- Performance center quality
    },
    ["m9k_ragingbull"] = {
        baseSpread = 0.015,      -- Compensated barrel
        movePenalty = 5.2,       -- .454 Casull power
    },
    ["m9k_remington1858"] = {
        baseSpread = 0.028,      -- Civil war era
        movePenalty = 4.0,       -- Black powder, slow
    },
    ["m9k_scoped_taurus"] = {
        baseSpread = 0.008,      -- Scoped for precision
        movePenalty = 5.8,       -- Scope makes moving hard
    },
    
    ----------------------------------------------------
    -- SMGs - Spray weapons, loose accuracy, good while moving
    ----------------------------------------------------
    ["m9k_bizonp19"] = {
        baseSpread = 0.032,      -- High capacity, less accurate
        movePenalty = 2.8,       -- Designed for mobility
    },
    ["m9k_mp40"] = {
        baseSpread = 0.035,      -- WW2 open bolt
        movePenalty = 3.2,       -- Heavy steel construction
    },
    ["m9k_mp5"] = {
        baseSpread = 0.024,      -- Gold standard SMG accuracy
        movePenalty = 2.5,       -- Roller-delayed perfection
    },
    ["m9k_mp5sd"] = {
        baseSpread = 0.026,      -- Suppressed, slightly less accurate
        movePenalty = 2.6,       -- Balanced with suppressor
    },
    ["m9k_mp7"] = {
        baseSpread = 0.022,      -- PDW accuracy
        movePenalty = 2.2,       -- Ultra-compact, very mobile
    },
    ["m9k_mp9"] = {
        baseSpread = 0.030,      -- Compact machine pistol
        movePenalty = 2.4,       -- Fast and light
    },
    ["m9k_smgp90"] = {
        baseSpread = 0.020,      -- Bullpup accuracy
        movePenalty = 2.3,       -- Ergonomic design
    },
    ["m9k_sten"] = {
        baseSpread = 0.040,      -- Crude wartime design
        movePenalty = 3.5,       -- Stamped metal, wobbly
    },
    ["m9k_tec9"] = {
        baseSpread = 0.045,      -- Cheap and inaccurate
        movePenalty = 3.0,       -- Light but poorly made
    },
    ["m9k_thompson"] = {
        baseSpread = 0.028,      -- .45 ACP punch
        movePenalty = 3.8,       -- Heavy, wood furniture
    },
    ["m9k_ump45"] = {
        baseSpread = 0.026,      -- Modern .45 SMG
        movePenalty = 2.8,       -- Well-designed
    },
    ["m9k_usc"] = {
        baseSpread = 0.024,      -- Civilian accuracy
        movePenalty = 2.6,       -- Semi-auto stability
    },
    ["m9k_uzi"] = {
        baseSpread = 0.034,      -- Open bolt spray
        movePenalty = 2.9,       -- Compact but bouncy
    },
    
    ----------------------------------------------------
    -- PDWs - Compact rifles, good accuracy, mobile
    ----------------------------------------------------
    ["m9k_honeybadger"] = {
        baseSpread = 0.018,      -- Integrally suppressed
        movePenalty = 3.0,       -- Compact but rifle-caliber
    },
    ["m9k_kac_pdw"] = {
        baseSpread = 0.020,      -- Short barrel
        movePenalty = 2.8,       -- Designed for mobility
    },
    ["m9k_magpulpdr"] = {
        baseSpread = 0.019,      -- Bullpup precision
        movePenalty = 2.6,       -- Compact layout
    },
    ["m9k_vector"] = {
        baseSpread = 0.022,      -- Super Kriss recoil system
        movePenalty = 2.4,       -- Best-in-class stability
    },
    
    ----------------------------------------------------
    -- ASSAULT RIFLES - Balanced accuracy and mobility
    ----------------------------------------------------
    ["m9k_acr"] = {
        baseSpread = 0.016,      -- Modern modular rifle
        movePenalty = 4.2,       -- Adaptive combat rifle
    },
    ["m9k_ak47"] = {
        baseSpread = 0.028,      -- Loose tolerances
        movePenalty = 4.8,       -- Heavy, kicks hard
    },
    ["m9k_ak74"] = {
        baseSpread = 0.024,      -- Improved AK accuracy
        movePenalty = 4.5,       -- 5.45mm lighter recoil
    },
    ["m9k_amd65"] = {
        baseSpread = 0.030,      -- Short barrel AK
        movePenalty = 4.2,       -- Compact, less stable
    },
    ["m9k_an94"] = {
        baseSpread = 0.018,      -- Precision 2-round burst
        movePenalty = 5.0,       -- Complex mechanism
    },
    ["m9k_auga3"] = {
        baseSpread = 0.017,      -- Bullpup accuracy
        movePenalty = 3.8,       -- Well-balanced
    },
    ["m9k_f2000"] = {
        baseSpread = 0.019,      -- Futuristic bullpup
        movePenalty = 3.6,       -- Ergonomic design
    },
    ["m9k_fal"] = {
        baseSpread = 0.020,      -- Battle rifle accuracy
        movePenalty = 5.5,       -- 7.62 NATO kick
    },
    ["m9k_famas"] = {
        baseSpread = 0.022,      -- French bullpup
        movePenalty = 4.0,       -- High RPM, less stable
    },
    ["m9k_g36"] = {
        baseSpread = 0.018,      -- German precision
        movePenalty = 4.0,       -- Polymer, lighter
    },
    ["m9k_g3a3"] = {
        baseSpread = 0.019,      -- Roller-delayed accuracy
        movePenalty = 5.2,       -- 7.62 battle rifle
    },
    ["m9k_l85"] = {
        baseSpread = 0.016,      -- Bullpup accuracy
        movePenalty = 4.2,       -- British precision
    },
    ["m9k_m14sp"] = {
        baseSpread = 0.014,      -- DMR-level accuracy
        movePenalty = 5.8,       -- Heavy, wood stock
    },
    ["m9k_m16a4_acog"] = {
        baseSpread = 0.015,      -- ACOG precision
        movePenalty = 4.5,       -- Optic adds weight
    },
    ["m9k_m416"] = {
        baseSpread = 0.014,      -- HK quality
        movePenalty = 4.0,       -- Best-in-class rifle
    },
    ["m9k_m4a1"] = {
        baseSpread = 0.017,      -- Standard carbine
        movePenalty = 3.8,       -- Light, maneuverable
    },
    ["m9k_scar"] = {
        baseSpread = 0.015,      -- SOCOM accuracy
        movePenalty = 4.8,       -- 7.62 version
    },
    ["m9k_tar21"] = {
        baseSpread = 0.018,      -- Israeli bullpup
        movePenalty = 3.6,       -- Compact design
    },
    ["m9k_val"] = {
        baseSpread = 0.016,      -- Suppressed accuracy
        movePenalty = 3.4,       -- Built for stealth
    },
    ["m9k_vikhr"] = {
        baseSpread = 0.020,      -- Compact assault rifle
        movePenalty = 3.2,       -- Meant for close quarters
    },
    ["m9k_winchester73"] = {
        baseSpread = 0.010,      -- Lever action Winchester (tightest)
        movePenalty = 5.5,       -- Old west accuracy
    },
    
    ----------------------------------------------------
    -- SHOTGUNS - Wide spread by nature, move penalty varies
    -- Note: baseSpread values match actual M9K weapon Primary.Spread
    -- These are aimcone values (spread radius in radians)
    ----------------------------------------------------
    ["m9k_1887winchester"] = {
        baseSpread = 0.042,      -- Lever action Winchester
        movePenalty = 4.5,       -- One-handed terminator style
    },
    ["m9k_1897winchester"] = {
        baseSpread = 0.040,      -- Trench gun spread
        movePenalty = 4.2,       -- Pump action
    },
    ["m9k_browningauto5"] = {
        baseSpread = 0.030,      -- Semi-auto consistency
        movePenalty = 4.0,       -- Smooth cycling
    },
    ["m9k_dbarrel"] = {
        baseSpread = 0.035,      -- Coach gun (average of spreads)
        movePenalty = 5.0,       -- Two barrels, heavy
    },
    ["m9k_ithacam37"] = {
        baseSpread = 0.023,      -- Classic pump - tightest shotgun
        movePenalty = 4.3,       -- Reliable design
    },
    ["m9k_jackhammer"] = {
        baseSpread = 0.045,      -- Full auto spread
        movePenalty = 5.5,       -- Drum fed beast
    },
    ["m9k_m3"] = {
        baseSpread = 0.0326,     -- Tactical shotgun
        movePenalty = 3.8,       -- Modern design
    },
    ["m9k_mossberg590"] = {
        baseSpread = 0.030,      -- Military spec
        movePenalty = 4.0,       -- Reliable pump
    },
    ["m9k_remington870"] = {
        baseSpread = 0.035,      -- Police standard
        movePenalty = 4.2,       -- Classic pump
    },
    ["m9k_spas12"] = {
        baseSpread = 0.030,      -- Combat shotgun
        movePenalty = 4.5,       -- Heavy but accurate
    },
    ["m9k_striker12"] = {
        baseSpread = 0.040,      -- Rotary spread
        movePenalty = 5.2,       -- Drum magazine
    },
    ["m9k_usas"] = {
        baseSpread = 0.048,      -- Full auto chaos
        movePenalty = 5.8,       -- 20-round drum
    },
    
    ----------------------------------------------------
    -- SNIPER RIFLES - Precision weapons, severe move penalty
    -- Note: baseSpread ignored, uses sniperStillBonus when still
    ----------------------------------------------------
    ["m9k_aw50"] = {
        baseSpread = 0.002,      -- Anti-material precision
        movePenalty = 18.0,      -- Huge rifle, nearly immobile
    },
    ["m9k_barret_m82"] = {
        baseSpread = 0.003,      -- .50 BMG accuracy
        movePenalty = 21.0,      -- 30 pound rifle
    },
    ["m9k_contender"] = {
        baseSpread = 0.004,      -- Hunting pistol
        movePenalty = 9.0,       -- Single shot, lighter
    },
    ["m9k_dragunov"] = {
        baseSpread = 0.005,      -- DMR accuracy
        movePenalty = 12.0,      -- Semi-auto flexibility
    },
    ["m9k_intervention"] = {
        baseSpread = 0.002,      -- Match-grade bolt
        movePenalty = 16.5,      -- Heavy precision rifle
    },
    ["m9k_m24"] = {
        baseSpread = 0.003,      -- Military sniper
        movePenalty = 15.0,      -- Remington 700 action
    },
    ["m9k_m98b"] = {
        baseSpread = 0.002,      -- .338 Lapua precision
        movePenalty = 18.0,      -- Long range beast
    },
    ["m9k_psg1"] = {
        baseSpread = 0.003,      -- German precision
        movePenalty = 13.5,      -- Semi-auto sniper
    },
    ["m9k_remington7615p"] = {
        baseSpread = 0.006,      -- Police rifle
        movePenalty = 10.5,      -- Lighter caliber
    },
    ["m9k_sl8"] = {
        baseSpread = 0.004,      -- Civilian G36
        movePenalty = 11.25,     -- Sporting rifle
    },
    ["m9k_svt40"] = {
        baseSpread = 0.007,      -- WW2 semi-auto
        movePenalty = 12.75,     -- Wood and steel
    },
    ["m9k_svu"] = {
        baseSpread = 0.004,      -- Bullpup sniper
        movePenalty = 12.0,      -- Compact SVD
    },
    
    ----------------------------------------------------
    -- LIGHT MACHINE GUNS - Suppression weapons, bad accuracy
    ----------------------------------------------------
    ["m9k_ares_shrike"] = {
        baseSpread = 0.035,      -- Belt-fed AR platform
        movePenalty = 6.0,       -- Modern LMG
    },
    ["m9k_fg42"] = {
        baseSpread = 0.028,      -- Paratroop rifle
        movePenalty = 5.5,       -- Lighter LMG
    },
    ["m9k_m1918bar"] = {
        baseSpread = 0.030,      -- .30-06 suppression
        movePenalty = 6.5,       -- Heavy wood and steel
    },
    ["m9k_m249lmg"] = {
        baseSpread = 0.038,      -- SAW spread
        movePenalty = 7.0,       -- Belt-fed beast
    },
    ["m9k_m60"] = {
        baseSpread = 0.040,      -- Vietnam era suppression
        movePenalty = 8.0,       -- "The Pig" is heavy
    },
    ["m9k_minigun"] = {
        baseSpread = 0.055,      -- Spray and pray
        movePenalty = 10.0,      -- You're not moving with this
    },
    ["m9k_pkm"] = {
        baseSpread = 0.042,      -- Russian general purpose
        movePenalty = 7.5,       -- 7.62x54R belt-fed
    },
}

----------------------------------------------------
-- Helper: Get base m9k class from weapon
----------------------------------------------------

function TDMRP.Accuracy.GetBaseClass(wep)
    if not IsValid(wep) then return nil end
    
    local className = wep:GetClass()
    
    -- Convert tdmrp_m9k_xxx to m9k_xxx for lookup
    if string.StartWith(className, "tdmrp_m9k_") then
        return string.sub(className, 7)  -- Remove "tdmrp_" prefix
    elseif string.StartWith(className, "m9k_") then
        return className
    end
    
    return nil
end

----------------------------------------------------
-- Helper: Get weapon stats from table
----------------------------------------------------

function TDMRP.Accuracy.GetWeaponStats(wep)
    local baseClass = TDMRP.Accuracy.GetBaseClass(wep)
    if baseClass and TDMRP.Accuracy.WeaponStats[baseClass] then
        return TDMRP.Accuracy.WeaponStats[baseClass]
    end
    return nil
end

----------------------------------------------------
-- Helper: Get weapon type
----------------------------------------------------

function TDMRP.Accuracy.GetWeaponType(wep)
    if not IsValid(wep) then return "normal" end
    
    local class = wep:GetClass()
    local ammoType = wep.Primary and wep.Primary.Ammo or ""
    local base = wep.Base or ""
    
    -- Explicit sniper list (all M9K snipers)
    local sniperList = {
        ["m9k_aw50"] = true,
        ["m9k_barret_m82"] = true,
        ["m9k_contender"] = true,
        ["m9k_dragunov"] = true,
        ["m9k_intervention"] = true,
        ["m9k_m24"] = true,
        ["m9k_m98b"] = true,
        ["m9k_psg1"] = true,
        ["m9k_remington7615p"] = true,
        ["m9k_sl8"] = true,
        ["m9k_svt40"] = true,
        ["m9k_svu"] = true,
    }
    
    -- Check for sniper by explicit list first
    if sniperList[class] or sniperList[string.gsub(class, "^tdmrp_", "")] then
        return "sniper"
    end
    
    -- Check for shotgun
    if TDMRP.Accuracy.Config.shotgunAmmoTypes[ammoType] or 
       string.find(base, "shotty") or
       string.find(string.lower(class), "shotgun") then
        return "shotgun"
    end
    
    -- Fallback checks for sniper
    if TDMRP.Accuracy.Config.sniperAmmoTypes[ammoType] or
       string.find(base, "scoped") or
       (wep.IsSniperRifle) then
        return "sniper"
    end
    
    return "normal"
end

----------------------------------------------------
-- Helper: Calculate movement multiplier
----------------------------------------------------

function TDMRP.Accuracy.GetMovementMultiplier(ply, weaponType, wep)
    if not IsValid(ply) then return 1 end
    
    local velocity = ply:GetVelocity():Length2D()
    local cfg = TDMRP.Accuracy.Config
    
    -- Get per-weapon move penalty if available
    local movePenalty = nil
    if IsValid(wep) then
        local stats = TDMRP.Accuracy.GetWeaponStats(wep)
        if stats and stats.movePenalty then
            movePenalty = stats.movePenalty
        end
    end
    
    -- Fallback to defaults based on weapon type
    if not movePenalty then
        if weaponType == "sniper" then
            movePenalty = cfg.sniperMovingMultiplier
        else
            movePenalty = cfg.normalMovingMultiplier
        end
    end
    
    -- Standing still
    if velocity < cfg.stillThreshold then
        if weaponType == "sniper" then
            return cfg.sniperStillBonus  -- Laser accurate for snipers
        end
        return 1  -- Normal accuracy for others
    end
    
    -- Moving - interpolate from 1x (or sniper bonus) to max penalty
    -- Use walkThreshold as the "full speed" point, but allow going beyond
    local moveFraction = math.Clamp((velocity - cfg.stillThreshold) / (cfg.walkThreshold - cfg.stillThreshold), 0, math.huge)
    
    if weaponType == "sniper" then
        -- Snipers: interpolate from still bonus to max penalty, then continue climbing beyond
        local multiplier = Lerp(math.Clamp(moveFraction, 0, 1), cfg.sniperStillBonus, movePenalty)
        
        -- Beyond walkThreshold, continue scaling upward
        if moveFraction > 1 then
            multiplier = movePenalty * (1 + (moveFraction - 1) * 0.5)  -- 50% additional penalty per 100 velocity beyond threshold
        end
        
        return multiplier
    else
        -- Normal guns: interpolate from 1x to max penalty
        local multiplier = Lerp(math.Clamp(moveFraction, 0, 1), 1, movePenalty)
        
        -- Beyond walkThreshold, continue scaling upward
        if moveFraction > 1 then
            multiplier = movePenalty * (1 + (moveFraction - 1) * 0.5)
        end
        
        return multiplier
    end
end

----------------------------------------------------
-- Helper: Get base spread for weapon
----------------------------------------------------

function TDMRP.Accuracy.GetBaseSpread(wep)
    if not IsValid(wep) then return 0.01 end
    
    local weaponType = TDMRP.Accuracy.GetWeaponType(wep)
    local stats = TDMRP.Accuracy.GetWeaponStats(wep)
    
    -- Use per-weapon baseSpread if available (but not for snipers when still)
    if stats and stats.baseSpread then
        return stats.baseSpread
    end
    
    -- Fallback to weapon's defined spread
    return wep.Primary and wep.Primary.Spread or 0.01
end

----------------------------------------------------
-- Helper: Get current spread for crosshair
----------------------------------------------------

function TDMRP.Accuracy.GetCurrentSpread(ply, wep)
    if not IsValid(ply) or not IsValid(wep) then return 0.01 end
    
    local weaponType = TDMRP.Accuracy.GetWeaponType(wep)
    local baseSpread = TDMRP.Accuracy.GetBaseSpread(wep)
    
    -- Use iron sight accuracy if ADS
    if wep.GetIronsights and wep:GetIronsights() and ply:KeyDown(IN_ATTACK2) then
        local ironAccuracy = wep.Primary and wep.Primary.IronAccuracy
        if ironAccuracy then
            baseSpread = ironAccuracy
        else
            baseSpread = baseSpread * 0.5
        end
    end
    
    local multiplier = TDMRP.Accuracy.GetMovementMultiplier(ply, weaponType, wep)
    
    return baseSpread * multiplier
end

print("[TDMRP] sh_tdmrp_accuracy.lua loaded - 52 weapons configured")
