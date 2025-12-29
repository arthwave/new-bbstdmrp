----------------------------------------------------
-- TDMRP Dynamic Recoil Patterns
-- Each weapon has a unique recoil personality
-- Patterns represent cumulative kick over successive shots
----------------------------------------------------

TDMRP = TDMRP or {}
TDMRP.RecoilPatterns = TDMRP.RecoilPatterns or {}

----------------------------------------------------
-- Recoil Pattern Definition
-- Each entry is [shotNumber] = { pitch, yaw }
-- Negative pitch = upward, positive yaw = right
-- All values will be scaled by recoil multiplier
----------------------------------------------------

TDMRP.RecoilPatterns.Weapons = {
    
    ----------------------------------------------------
    -- PISTOLS - Classic upward kick, quick recovery
    ----------------------------------------------------
    ["m9k_colt1911"] = {
        name = "1911 - Heavy up kick",
        shots = {
            [1] = {-0.8, 0.1},
            [2] = {-0.6, -0.1},
            [3] = {-0.5, 0.05},
            [4] = {-0.4, -0.05},
            [5] = {-0.3, 0.0},
        }
    },
    ["m9k_glock"] = {
        name = "Glock - Straight up",
        shots = {
            [1] = {-0.6, 0.0},
            [2] = {-0.5, 0.0},
            [3] = {-0.4, 0.0},
            [4] = {-0.3, 0.0},
            [5] = {-0.2, 0.0},
        }
    },
    ["m9k_hk45"] = {
        name = "HK45 - Controlled climb",
        shots = {
            [1] = {-0.7, 0.05},
            [2] = {-0.55, -0.05},
            [3] = {-0.45, 0.0},
            [4] = {-0.35, 0.0},
            [5] = {-0.25, 0.0},
        }
    },
    ["m9k_luger"] = {
        name = "Luger - Unpredictable",
        shots = {
            [1] = {-0.9, 0.15},
            [2] = {-0.5, -0.2},
            [3] = {-0.7, 0.1},
            [4] = {-0.4, -0.1},
            [5] = {-0.35, 0.05},
        }
    },
    ["m9k_m92beretta"] = {
        name = "M92 - Smooth operator",
        shots = {
            [1] = {-0.65, 0.0},
            [2] = {-0.5, 0.0},
            [3] = {-0.45, 0.0},
            [4] = {-0.35, 0.0},
            [5] = {-0.25, 0.0},
        }
    },
    ["m9k_sig_p229r"] = {
        name = "SIG P229 - Minimal kick",
        shots = {
            [1] = {-0.5, 0.0},
            [2] = {-0.4, 0.0},
            [3] = {-0.35, 0.0},
            [4] = {-0.25, 0.0},
            [5] = {-0.15, 0.0},
        }
    },
    ["m9k_usp"] = {
        name = "USP - Precision hold",
        shots = {
            [1] = {-0.55, 0.02},
            [2] = {-0.45, -0.02},
            [3] = {-0.4, 0.0},
            [4] = {-0.3, 0.0},
            [5] = {-0.2, 0.0},
        }
    },
    
    ----------------------------------------------------
    -- REVOLVERS - Heavy upward, powerful
    ----------------------------------------------------
    ["m9k_coltpython"] = {
        name = "Colt Python - Thunderous",
        shots = {
            [1] = {-1.2, 0.3},
            [2] = {-0.8, -0.2},
            [3] = {-0.9, 0.1},
            [4] = {-0.6, -0.1},
            [5] = {-0.5, 0.0},
        }
    },
    ["m9k_deagle"] = {
        name = "Desert Eagle - Brutal kick",
        shots = {
            [1] = {-1.4, 0.5},
            [2] = {-1.0, -0.4},
            [3] = {-0.8, 0.3},
            [4] = {-0.6, -0.2},
            [5] = {-0.4, 0.1},
        }
    },
    ["m9k_m29satan"] = {
        name = "S&W M29 - Magnum fury",
        shots = {
            [1] = {-1.3, 0.4},
            [2] = {-0.9, -0.3},
            [3] = {-0.85, 0.2},
            [4] = {-0.55, -0.15},
            [5] = {-0.45, 0.1},
        }
    },
    ["m9k_model3russian"] = {
        name = "Model 3 Russian - Gentle kick",
        shots = {
            [1] = {-0.7, 0.1},
            [2] = {-0.5, -0.1},
            [3] = {-0.45, 0.0},
            [4] = {-0.3, 0.0},
            [5] = {-0.2, 0.0},
        }
    },
    ["m9k_model500"] = {
        name = "Model 500 - Extreme recoil",
        shots = {
            [1] = {-1.6, 0.6},
            [2] = {-1.0, -0.5},
            [3] = {-0.8, 0.4},
            [4] = {-0.5, -0.2},
            [5] = {-0.3, 0.1},
        }
    },
    ["m9k_model627"] = {
        name = "Model 627 - Controlled power",
        shots = {
            [1] = {-1.0, 0.2},
            [2] = {-0.7, -0.15},
            [3] = {-0.6, 0.1},
            [4] = {-0.45, -0.05},
            [5] = {-0.35, 0.0},
        }
    },
    ["m9k_ragingbull"] = {
        name = "Raging Bull - Wild beast",
        shots = {
            [1] = {-1.25, 0.5},
            [2] = {-0.85, -0.35},
            [3] = {-0.75, 0.25},
            [4] = {-0.5, -0.15},
            [5] = {-0.35, 0.1},
        }
    },
    ["m9k_remington1858"] = {
        name = "Remington 1858 - Slow kick",
        shots = {
            [1] = {-1.1, 0.2},
            [2] = {-0.7, -0.1},
            [3] = {-0.6, 0.0},
            [4] = {-0.4, 0.0},
            [5] = {-0.3, 0.0},
        }
    },
    ["m9k_scoped_taurus"] = {
        name = "Scoped Taurus - Precision kick",
        shots = {
            [1] = {-0.8, 0.1},
            [2] = {-0.55, -0.1},
            [3] = {-0.45, 0.0},
            [4] = {-0.3, 0.0},
            [5] = {-0.2, 0.0},
        }
    },
    
    ----------------------------------------------------
    -- SMGs - Horizontal spray, bouncy
    ----------------------------------------------------
    ["m9k_bizonp19"] = {
        name = "PP-19 Bizon - Wandering fire",
        shots = {
            [1] = {-0.3, 0.2},
            [2] = {-0.25, -0.3},
            [3] = {-0.2, 0.25},
            [4] = {-0.15, -0.2},
            [5] = {-0.1, 0.15},
        }
    },
    ["m9k_mp40"] = {
        name = "MP40 - Vintage spray",
        shots = {
            [1] = {-0.4, 0.15},
            [2] = {-0.3, -0.2},
            [3] = {-0.25, 0.2},
            [4] = {-0.2, -0.15},
            [5] = {-0.15, 0.1},
        }
    },
    ["m9k_mp5"] = {
        name = "MP5 - Laser beam",
        shots = {
            [1] = {-0.25, 0.05},
            [2] = {-0.2, -0.05},
            [3] = {-0.15, 0.0},
            [4] = {-0.1, 0.0},
            [5] = {-0.05, 0.0},
        }
    },
    ["m9k_mp5sd"] = {
        name = "MP5SD - Suppressed control",
        shots = {
            [1] = {-0.2, 0.03},
            [2] = {-0.15, -0.03},
            [3] = {-0.12, 0.0},
            [4] = {-0.08, 0.0},
            [5] = {-0.05, 0.0},
        }
    },
    ["m9k_mp7"] = {
        name = "MP7 - Compact firepower",
        shots = {
            [1] = {-0.22, 0.08},
            [2] = {-0.18, -0.08},
            [3] = {-0.14, 0.05},
            [4] = {-0.1, -0.03},
            [5] = {-0.06, 0.0},
        }
    },
    ["m9k_mp9"] = {
        name = "MP9 - Bouncy compact",
        shots = {
            [1] = {-0.28, 0.12},
            [2] = {-0.22, -0.15},
            [3] = {-0.18, 0.12},
            [4] = {-0.12, -0.1},
            [5] = {-0.08, 0.08},
        }
    },
    ["m9k_smgp90"] = {
        name = "P90 - Steady stream",
        shots = {
            [1] = {-0.2, 0.1},
            [2] = {-0.18, -0.08},
            [3] = {-0.15, 0.06},
            [4] = {-0.12, -0.05},
            [5] = {-0.08, 0.03},
        }
    },
    ["m9k_sten"] = {
        name = "STEN - Wobbly fighter",
        shots = {
            [1] = {-0.35, 0.2},
            [2] = {-0.28, -0.25},
            [3] = {-0.22, 0.2},
            [4] = {-0.18, -0.18},
            [5] = {-0.12, 0.15},
        }
    },
    ["m9k_tec9"] = {
        name = "TEC-9 - Wild spray",
        shots = {
            [1] = {-0.3, 0.25},
            [2] = {-0.2, -0.3},
            [3] = {-0.25, 0.28},
            [4] = {-0.15, -0.22},
            [5] = {-0.1, 0.2},
        }
    },
    ["m9k_thompson"] = {
        name = "Thompson - .45 bounce",
        shots = {
            [1] = {-0.45, 0.15},
            [2] = {-0.35, -0.2},
            [3] = {-0.3, 0.18},
            [4] = {-0.22, -0.12},
            [5] = {-0.15, 0.1},
        }
    },
    ["m9k_ump45"] = {
        name = "UMP-45 - Heavy SMG kick",
        shots = {
            [1] = {-0.4, 0.12},
            [2] = {-0.32, -0.15},
            [3] = {-0.26, 0.1},
            [4] = {-0.2, -0.08},
            [5] = {-0.14, 0.05},
        }
    },
    ["m9k_usc"] = {
        name = "USC - Urban control",
        shots = {
            [1] = {-0.28, 0.08},
            [2] = {-0.22, -0.1},
            [3] = {-0.18, 0.06},
            [4] = {-0.14, -0.05},
            [5] = {-0.1, 0.03},
        }
    },
    ["m9k_uzi"] = {
        name = "Uzi - Classic spray",
        shots = {
            [1] = {-0.32, 0.18},
            [2] = {-0.25, -0.22},
            [3] = {-0.2, 0.2},
            [4] = {-0.16, -0.15},
            [5] = {-0.12, 0.12},
        }
    },
    
    ----------------------------------------------------
    -- PDWs - Compact, minimal recoil
    ----------------------------------------------------
    ["m9k_honeybadger"] = {
        name = "Honey Badger - Whisper",
        shots = {
            [1] = {-0.22, 0.05},
            [2] = {-0.18, -0.05},
            [3] = {-0.14, 0.0},
            [4] = {-0.1, 0.0},
            [5] = {-0.06, 0.0},
        }
    },
    ["m9k_kac_pdw"] = {
        name = "KAC PDW - Precision compact",
        shots = {
            [1] = {-0.2, 0.04},
            [2] = {-0.16, -0.04},
            [3] = {-0.12, 0.0},
            [4] = {-0.08, 0.0},
            [5] = {-0.04, 0.0},
        }
    },
    ["m9k_magpulpdr"] = {
        name = "Magpul PDR - Balanced burst",
        shots = {
            [1] = {-0.24, 0.06},
            [2] = {-0.19, -0.06},
            [3] = {-0.15, 0.03},
            [4] = {-0.11, -0.02},
            [5] = {-0.07, 0.0},
        }
    },
    ["m9k_vector"] = {
        name = "KRISS Vector - Tamed fury",
        shots = {
            [1] = {-0.18, 0.03},
            [2] = {-0.15, -0.03},
            [3] = {-0.12, 0.0},
            [4] = {-0.09, 0.0},
            [5] = {-0.06, 0.0},
        }
    },
    
    ----------------------------------------------------
    -- RIFLES - Varied personalities
    ----------------------------------------------------
    ["m9k_acr"] = {
        name = "ACR - Modular smoothness",
        shots = {
            [1] = {-0.35, 0.08},
            [2] = {-0.28, -0.06},
            [3] = {-0.22, 0.04},
            [4] = {-0.16, -0.03},
            [5] = {-0.1, 0.0},
        }
    },
    ["m9k_ak47"] = {
        name = "AK-47 - Bouncy beast",
        shots = {
            [1] = {-0.55, 0.25},
            [2] = {-0.42, -0.2},
            [3] = {-0.35, 0.2},
            [4] = {-0.26, -0.15},
            [5] = {-0.18, 0.1},
        }
    },
    ["m9k_ak74"] = {
        name = "AK-74 - Smooth 5.45",
        shots = {
            [1] = {-0.48, 0.2},
            [2] = {-0.38, -0.15},
            [3] = {-0.3, 0.15},
            [4] = {-0.22, -0.1},
            [5] = {-0.15, 0.08},
        }
    },
    ["m9k_amd65"] = {
        name = "AMD-65 - Short and wild",
        shots = {
            [1] = {-0.6, 0.3},
            [2] = {-0.45, -0.25},
            [3] = {-0.38, 0.22},
            [4] = {-0.28, -0.18},
            [5] = {-0.2, 0.12},
        }
    },
    ["m9k_an94"] = {
        name = "AN-94 - Precision setter",
        shots = {
            [1] = {-0.4, 0.05},
            [2] = {-0.32, -0.04},
            [3] = {-0.25, 0.03},
            [4] = {-0.18, -0.02},
            [5] = {-0.12, 0.0},
        }
    },
    ["m9k_auga3"] = {
        name = "AUG A3 - Bullpup precision",
        shots = {
            [1] = {-0.38, 0.06},
            [2] = {-0.3, -0.05},
            [3] = {-0.24, 0.03},
            [4] = {-0.18, -0.02},
            [5] = {-0.12, 0.0},
        }
    },
    ["m9k_f2000"] = {
        name = "F2000 - Futuristic control",
        shots = {
            [1] = {-0.35, 0.05},
            [2] = {-0.28, -0.04},
            [3] = {-0.22, 0.03},
            [4] = {-0.16, -0.02},
            [5] = {-0.1, 0.0},
        }
    },
    ["m9k_fal"] = {
        name = "FAL - Battle rifle kick",
        shots = {
            [1] = {-0.65, 0.15},
            [2] = {-0.5, -0.12},
            [3] = {-0.4, 0.1},
            [4] = {-0.28, -0.08},
            [5] = {-0.18, 0.05},
        }
    },
    ["m9k_famas"] = {
        name = "FAMAS - Rapid climber",
        shots = {
            [1] = {-0.42, 0.15},
            [2] = {-0.35, -0.12},
            [3] = {-0.3, 0.1},
            [4] = {-0.24, -0.08},
            [5] = {-0.18, 0.05},
        }
    },
    ["m9k_g36"] = {
        name = "G36 - German efficiency",
        shots = {
            [1] = {-0.36, 0.07},
            [2] = {-0.29, -0.06},
            [3] = {-0.23, 0.04},
            [4] = {-0.17, -0.03},
            [5] = {-0.11, 0.0},
        }
    },
    ["m9k_g3a3"] = {
        name = "G3A3 - 7.62 authority",
        shots = {
            [1] = {-0.62, 0.18},
            [2] = {-0.48, -0.15},
            [3] = {-0.38, 0.12},
            [4] = {-0.28, -0.1},
            [5] = {-0.18, 0.06},
        }
    },
    ["m9k_l85"] = {
        name = "L85A2 - Brit bullpup",
        shots = {
            [1] = {-0.37, 0.06},
            [2] = {-0.29, -0.05},
            [3] = {-0.23, 0.03},
            [4] = {-0.17, -0.02},
            [5] = {-0.11, 0.0},
        }
    },
    ["m9k_m14sp"] = {
        name = "M14 - DMR precision",
        shots = {
            [1] = {-0.7, 0.12},
            [2] = {-0.52, -0.1},
            [3] = {-0.4, 0.08},
            [4] = {-0.28, -0.06},
            [5] = {-0.16, 0.04},
        }
    },
    ["m9k_m16a4_acog"] = {
        name = "M16A4 - American standard",
        shots = {
            [1] = {-0.4, 0.09},
            [2] = {-0.32, -0.08},
            [3] = {-0.25, 0.06},
            [4] = {-0.18, -0.04},
            [5] = {-0.12, 0.02},
        }
    },
    ["m9k_m416"] = {
        name = "HK416 - Premium control",
        shots = {
            [1] = {-0.32, 0.06},
            [2] = {-0.26, -0.05},
            [3] = {-0.21, 0.03},
            [4] = {-0.15, -0.02},
            [5] = {-0.09, 0.0},
        }
    },
    ["m9k_m4a1"] = {
        name = "M4A1 - Tactical go-to",
        shots = {
            [1] = {-0.34, 0.08},
            [2] = {-0.27, -0.06},
            [3] = {-0.21, 0.04},
            [4] = {-0.15, -0.03},
            [5] = {-0.09, 0.0},
        }
    },
    ["m9k_scar"] = {
        name = "SCAR-H - Heavy hitter",
        shots = {
            [1] = {-0.6, 0.16},
            [2] = {-0.46, -0.13},
            [3] = {-0.36, 0.1},
            [4] = {-0.26, -0.08},
            [5] = {-0.16, 0.05},
        }
    },
    ["m9k_tar21"] = {
        name = "TAR-21 - Israeli compact",
        shots = {
            [1] = {-0.38, 0.08},
            [2] = {-0.3, -0.07},
            [3] = {-0.24, 0.05},
            [4] = {-0.18, -0.03},
            [5] = {-0.12, 0.02},
        }
    },
    ["m9k_val"] = {
        name = "AS VAL - Stealth sniper",
        shots = {
            [1] = {-0.5, 0.08},
            [2] = {-0.39, -0.06},
            [3] = {-0.3, 0.04},
            [4] = {-0.21, -0.03},
            [5] = {-0.12, 0.0},
        }
    },
    ["m9k_vikhr"] = {
        name = "SR-3 Vikhr - Quiet killer",
        shots = {
            [1] = {-0.45, 0.07},
            [2] = {-0.35, -0.06},
            [3] = {-0.27, 0.04},
            [4] = {-0.19, -0.03},
            [5] = {-0.11, 0.0},
        }
    },
    ["m9k_winchester73"] = {
        name = "Winchester 1873 - Lever kick",
        shots = {
            [1] = {-0.8, 0.2},
            [2] = {-0.55, -0.15},
            [3] = {-0.4, 0.1},
            [4] = {-0.25, -0.08},
            [5] = {-0.12, 0.0},
        }
    },
    
    ----------------------------------------------------
    -- SHOTGUNS - Massive vertical punch
    ----------------------------------------------------
    ["m9k_1887winchester"] = {
        name = "1887 Winchester - Western fury",
        shots = {
            [1] = {-1.8, 0.2},
            [2] = {-1.4, -0.15},
            [3] = {-1.1, 0.1},
        }
    },
    ["m9k_1897winchester"] = {
        name = "1897 Trench - Trench warfare",
        shots = {
            [1] = {-1.9, 0.15},
            [2] = {-1.5, -0.1},
            [3] = {-1.2, 0.08},
        }
    },
    ["m9k_browningauto5"] = {
        name = "Browning Auto-5 - Smooth pump",
        shots = {
            [1] = {-1.5, 0.1},
            [2] = {-1.2, -0.08},
            [3] = {-0.95, 0.05},
        }
    },
    ["m9k_dbarrel"] = {
        name = "Double Barrel - Both barrels",
        shots = {
            [1] = {-2.2, 0.35},
            [2] = {-1.6, -0.25},
        }
    },
    ["m9k_ithacam37"] = {
        name = "Ithaca M37 - Tight shot",
        shots = {
            [1] = {-1.4, 0.08},
            [2] = {-1.1, -0.06},
            [3] = {-0.9, 0.04},
        }
    },
    ["m9k_jackhammer"] = {
        name = "Jackhammer - Full auto beast",
        shots = {
            [1] = {-1.6, 0.2},
            [2] = {-1.25, -0.15},
            [3] = {-1.0, 0.12},
            [4] = {-0.8, -0.08},
            [5] = {-0.6, 0.05},
        }
    },
    ["m9k_m3"] = {
        name = "M3 Tactical - Combat ready",
        shots = {
            [1] = {-1.5, 0.12},
            [2] = {-1.2, -0.1},
            [3] = {-0.95, 0.07},
        }
    },
    ["m9k_mossberg590"] = {
        name = "Mossberg 590 - Military pump",
        shots = {
            [1] = {-1.55, 0.13},
            [2] = {-1.22, -0.1},
            [3] = {-0.98, 0.08},
        }
    },
    ["m9k_remington870"] = {
        name = "Remington 870 - Police special",
        shots = {
            [1] = {-1.5, 0.11},
            [2] = {-1.2, -0.09},
            [3] = {-0.95, 0.06},
        }
    },
    ["m9k_spas12"] = {
        name = "SPAS-12 - Combat shotgun",
        shots = {
            [1] = {-1.45, 0.1},
            [2] = {-1.15, -0.08},
            [3] = {-0.9, 0.05},
        }
    },
    ["m9k_striker12"] = {
        name = "Striker-12 - Drum fed chaos",
        shots = {
            [1] = {-1.7, 0.22},
            [2] = {-1.32, -0.18},
            [3] = {-1.05, 0.14},
            [4] = {-0.82, -0.1},
            [5] = {-0.6, 0.06},
        }
    },
    ["m9k_usas"] = {
        name = "USAS-12 - Full auto horror",
        shots = {
            [1] = {-1.8, 0.25},
            [2] = {-1.4, -0.2},
            [3] = {-1.1, 0.16},
            [4] = {-0.85, -0.12},
            [5] = {-0.6, 0.08},
        }
    },
    
    ----------------------------------------------------
    -- SNIPERS - Single massive punch
    ----------------------------------------------------
    ["m9k_aw50"] = {
        name = "AW50 - Anti-material",
        shots = {
            [1] = {-7.5, 0.3},
        }
    },
    ["m9k_barret_m82"] = {
        name = "Barrett M82 - .50 BMG fury",
        shots = {
            [1] = {-8.4, 0.45},
        }
    },
    ["m9k_contender"] = {
        name = "Contender G2 - Hunting rifle",
        shots = {
            [1] = {-4.5, 0.15},
        }
    },
    ["m9k_dragunov"] = {
        name = "SVD Dragunov - Russian semi",
        shots = {
            [1] = {-6.0, 0.24},
        }
    },
    ["m9k_intervention"] = {
        name = "Intervention - Precision bolt",
        shots = {
            [1] = {-6.9, 0.21},
        }
    },
    ["m9k_m24"] = {
        name = "M24 - Military sniper",
        shots = {
            [1] = {-6.3, 0.18},
        }
    },
    ["m9k_m98b"] = {
        name = "M98B - .338 Lapua",
        shots = {
            [1] = {-7.2, 0.27},
        }
    },
    ["m9k_psg1"] = {
        name = "PSG-1 - German precision",
        shots = {
            [1] = {-5.7, 0.15},
        }
    },
    ["m9k_remington7615p"] = {
        name = "Remington 7615P - Police rifle",
        shots = {
            [1] = {-4.8, 0.12},
        }
    },
    ["m9k_sl8"] = {
        name = "SL8 - Sporting rifle",
        shots = {
            [1] = {-5.1, 0.15},
        }
    },
    ["m9k_svt40"] = {
        name = "SVT-40 - WW2 semi",
        shots = {
            [1] = {-5.4, 0.18},
        }
    },
    ["m9k_svu"] = {
        name = "SVU - Bullpup sniper",
        shots = {
            [1] = {-5.85, 0.21},
        }
    },
    
    ----------------------------------------------------
    -- LMGs - Climbing pattern, stabilizes then climbs
    ----------------------------------------------------
    ["m9k_ares_shrike"] = {
        name = "Ares Shrike - Belt-fed climber",
        shots = {
            [1] = {-0.5, 0.08},
            [2] = {-0.45, -0.06},
            [3] = {-0.42, 0.05},
            [4] = {-0.55, -0.1},
            [5] = {-0.65, 0.12},
        }
    },
    ["m9k_fg42"] = {
        name = "FG-42 - Paratroop gun",
        shots = {
            [1] = {-0.55, 0.1},
            [2] = {-0.48, -0.08},
            [3] = {-0.44, 0.06},
            [4] = {-0.6, -0.12},
            [5] = {-0.72, 0.15},
        }
    },
    ["m9k_m1918bar"] = {
        name = "M1918 BAR - Slow climb",
        shots = {
            [1] = {-0.48, 0.09},
            [2] = {-0.42, -0.07},
            [3] = {-0.39, 0.05},
            [4] = {-0.52, -0.1},
            [5] = {-0.62, 0.13},
        }
    },
    ["m9k_m249lmg"] = {
        name = "M249 SAW - Steady spray",
        shots = {
            [1] = {-0.42, 0.07},
            [2] = {-0.38, -0.06},
            [3] = {-0.35, 0.04},
            [4] = {-0.48, -0.08},
            [5] = {-0.58, 0.1},
        }
    },
    ["m9k_m60"] = {
        name = "M60 - The Pig",
        shots = {
            [1] = {-0.6, 0.12},
            [2] = {-0.52, -0.1},
            [3] = {-0.48, 0.08},
            [4] = {-0.65, -0.14},
            [5] = {-0.78, 0.16},
        }
    },
    ["m9k_minigun"] = {
        name = "Minigun - Spin-up horror",
        shots = {
            [1] = {-0.2, 0.05},
            [2] = {-0.25, -0.1},
            [3] = {-0.32, 0.12},
            [4] = {-0.48, -0.15},
            [5] = {-0.65, 0.18},
        }
    },
    ["m9k_pkm"] = {
        name = "PKM - Russian workhorse",
        shots = {
            [1] = {-0.58, 0.11},
            [2] = {-0.5, -0.09},
            [3] = {-0.46, 0.07},
            [4] = {-0.62, -0.12},
            [5] = {-0.74, 0.14},
        }
    },
}

----------------------------------------------------
-- Helper: Get recoil pattern for a weapon
----------------------------------------------------

function TDMRP.RecoilPatterns.GetPattern(weaponClass, shotNumber)
    local baseClass = weaponClass
    if string.StartWith(weaponClass, "tdmrp_m9k_") then
        baseClass = string.sub(weaponClass, 7)  -- Remove "tdmrp_" prefix
    end
    
    local pattern = TDMRP.RecoilPatterns.Weapons[baseClass]
    if not pattern then
        -- Fallback: return neutral recoil
        return {-0.1, 0}
    end
    
    -- Get the shot pattern or loop back to beginning if beyond defined shots
    local totalShots = table.Count(pattern.shots)
    local loopedShot = ((shotNumber - 1) % totalShots) + 1
    
    return pattern.shots[loopedShot] or {-0.1, 0}
end

print("[TDMRP] sh_tdmrp_recoil_patterns.lua loaded - 52 weapons with unique personalities")
