-- sh_tdmrp_loadout_pools.lua
-- Shared loadout pool definitions for TDMRP
-- Each combat job has 2-3 weapon options per slot (Primary, Secondary, Gear)
-- Players select from these pools on spawn

TDMRP = TDMRP or {}
TDMRP.LoadoutPools = TDMRP.LoadoutPools or {}

if SERVER then
    AddCSLuaFile()
end

----------------------------------------------------
-- LOADOUT STRUCTURE
-- Each job defines:
--   Primary   = { list of tdmrp_m9k_* or weapon_tdmrp_cs_* rifles, SMGs, etc }
--   Secondary = { list of tdmrp_m9k_* or weapon_tdmrp_cs_* pistols, sidearms }
--   Gear      = { list of utility items: grenades, medkits, etc }
----------------------------------------------------

-- CRITICAL: ALL weapons MUST use tdmrp_m9k_* or weapon_tdmrp_cs_* class names
-- NEVER use base m9k_* or weapon_cs_* classes

----------------------------------------------------
-- COP CLASS LOADOUTS
----------------------------------------------------

-- Police Recruit (Starter - basic loadout)
TDMRP.LoadoutPools["policerecruit"] = {
    Primary = {
        "tdmrp_m9k_mp5sd",
        "tdmrp_m9k_mp7",
        "weapon_tdmrp_cs_mp5a5",
    },
    Secondary = {
        "tdmrp_m9k_colt1911",
        "weapon_tdmrp_cs_usp",
        "tdmrp_m9k_m92beretta",
    },
    Gear = {
        "weapon_medkit",  -- Basic healing
    },
}

-- SWAT (Assault rifle specialist)
TDMRP.LoadoutPools["swat"] = {
    Primary = {
        "tdmrp_m9k_acr",
        "tdmrp_m9k_g36",
        "weapon_tdmrp_cs_m4a1",
    },
    Secondary = {
        "tdmrp_m9k_colt1911",
        "weapon_tdmrp_cs_usp",
        "tdmrp_m9k_sig_p229r",
    },
    Gear = {
        "weapon_frag",
        "weapon_flashbang",
    },
}

-- Field Surgeon (Medic - lighter weapons, heal focus)
TDMRP.LoadoutPools["fieldsurgeon"] = {
    Primary = {
        "tdmrp_m9k_mp5sd",
        "tdmrp_m9k_mp7",
        "weapon_tdmrp_cs_mp5a5",
    },
    Secondary = {
        "tdmrp_m9k_colt1911",
        "tdmrp_m9k_m92beretta",
    },
    Gear = {
        "weapon_healgun",  -- Special medic weapon
        "weapon_medkit",
    },
}

-- Armsmaster (Combat engineer - versatile)
TDMRP.LoadoutPools["armsmaster"] = {
    Primary = {
        "weapon_tdmrp_cs_m4a1",
        "tdmrp_m9k_scar",
        "tdmrp_m9k_acr",
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "tdmrp_m9k_m29satan",
    },
    Gear = {
        "weapon_sentry_deployer",  -- Special: deploy sentry
        "weapon_frag",
    },
}

-- Marine (Close-range specialist)
TDMRP.LoadoutPools["marine"] = {
    Primary = {
        "tdmrp_m9k_spas12",
        "tdmrp_m9k_1887winchester",
        "weapon_tdmrp_cs_pumpshotgun",
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "tdmrp_m9k_m29satan",
        "tdmrp_m9k_ragingbull",
    },
    Gear = {
        "weapon_frag",
        "weapon_smoke",
    },
}

-- Special Forces (Sniper)
TDMRP.LoadoutPools["specialforces"] = {
    Primary = {
        "tdmrp_m9k_intervention",
        "tdmrp_m9k_barret_m82",
        "weapon_tdmrp_cs_awp",
    },
    Secondary = {
        "tdmrp_m9k_colt1911",
        "tdmrp_m9k_m92beretta",
        "weapon_tdmrp_cs_usp",
    },
    Gear = {
        "weapon_smoke",
        "weapon_flashbang",
    },
}

-- Recon (Stealth - light weapons)
TDMRP.LoadoutPools["recon"] = {
    Primary = {
        "tdmrp_m9k_mp5sd",
        "tdmrp_m9k_honeybadger",
        "tdmrp_m9k_vector",
    },
    Secondary = {
        "tdmrp_m9k_hk45",
        "tdmrp_m9k_m92beretta",
    },
    Gear = {
        "weapon_smoke",
        "weapon_tdmrp_cs_knife",  -- Silent takedown
    },
}

-- Vanguard (Heavy assault)
TDMRP.LoadoutPools["vanguard"] = {
    Primary = {
        "tdmrp_m9k_m249lmg",
        "tdmrp_m9k_m60",
        "weapon_tdmrp_cs_famas",
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "tdmrp_m9k_m29satan",
    },
    Gear = {
        "weapon_frag",
        "weapon_flashbang",
    },
}

-- Armored Unit (Heavy tank - slow, heavy weapons)
TDMRP.LoadoutPools["armoredunit"] = {
    Primary = {
        "tdmrp_m9k_m249lmg",
        "tdmrp_m9k_m60",
        "weapon_tdmrp_cs_aug",
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "tdmrp_m9k_m29satan",
        "tdmrp_m9k_ragingbull",
    },
    Gear = {
        "weapon_medkit",
    },
}

-- Mayor (Support/Command)
TDMRP.LoadoutPools["mayor"] = {
    Primary = {
        "weapon_tdmrp_cs_m4a1",
        "tdmrp_m9k_mp5sd",
        "tdmrp_m9k_acr",
    },
    Secondary = {
        "tdmrp_m9k_colt1911",
        "tdmrp_m9k_deagle",
    },
    Gear = {
        "weapon_medkit",
        "weapon_binoculars",  -- Command tool
    },
}

-- Master Chief (Elite - best of the best)
TDMRP.LoadoutPools["masterchief"] = {
    Primary = {
        "weapon_tdmrp_cs_m4a1",
        "tdmrp_m9k_scar",
        "tdmrp_m9k_g36",
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "weapon_tdmrp_cs_desert_eagle",
    },
    Gear = {
        "weapon_plasmarifle",  -- Special active skill weapon
        "weapon_frag",
    },
}

----------------------------------------------------
-- CRIMINAL CLASS LOADOUTS
----------------------------------------------------

-- Gangster Initiate (Starter - basic loadout)
TDMRP.LoadoutPools["gangsterinitiate"] = {
    Primary = {
        "tdmrp_m9k_mp9",
        "tdmrp_m9k_uzi",
        "weapon_tdmrp_cs_mac10",
    },
    Secondary = {
        "tdmrp_m9k_colt1911",
        "tdmrp_m9k_m92beretta",
        "tdmrp_m9k_coltpython",
    },
    Gear = {
        "weapon_medkit",
    },
}

-- Thief (Assault specialist)
TDMRP.LoadoutPools["thief"] = {
    Primary = {
        "weapon_tdmrp_cs_ak47",
        "tdmrp_m9k_amd65",
        "tdmrp_m9k_ak74",
    },
    Secondary = {
        "tdmrp_m9k_colt1911",
        "tdmrp_m9k_coltpython",
        "tdmrp_m9k_m92beretta",
    },
    Gear = {
        "weapon_frag",
        "weapon_smoke",
    },
}

-- Dr. Evil (Criminal medic)
TDMRP.LoadoutPools["drevil"] = {
    Primary = {
        "tdmrp_m9k_mp5sd",
        "tdmrp_m9k_bizonp19",
        "weapon_tdmrp_cs_p90",
    },
    Secondary = {
        "tdmrp_m9k_colt1911",
        "tdmrp_m9k_m92beretta",
    },
    Gear = {
        "weapon_healgun",
        "weapon_medkit",
    },
}

-- Merchant of Death (Criminal gun dealer)
TDMRP.LoadoutPools["merchantofdeath"] = {
    Primary = {
        "weapon_tdmrp_cs_ak47",
        "tdmrp_m9k_amd65",
        "tdmrp_m9k_fal",
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "tdmrp_m9k_m29satan",
    },
    Gear = {
        "weapon_drone_targeter",  -- For drone strike skill
        "weapon_frag",
    },
}

-- Mercenary (Close-range combat)
TDMRP.LoadoutPools["mercenary"] = {
    Primary = {
        "tdmrp_m9k_spas12",
        "tdmrp_m9k_1887winchester",
        "tdmrp_m9k_jackhammer",
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "tdmrp_m9k_ragingbull",
        "tdmrp_m9k_m29satan",
    },
    Gear = {
        "weapon_frag",
        "weapon_smoke",
    },
}

-- Deadeye (Sniper)
TDMRP.LoadoutPools["deadeye"] = {
    Primary = {
        "tdmrp_m9k_intervention",
        "tdmrp_m9k_barret_m82",
        "weapon_tdmrp_cs_awp",
    },
    Secondary = {
        "tdmrp_m9k_colt1911",
        "weapon_tdmrp_cs_usp",
        "tdmrp_m9k_m92beretta",
    },
    Gear = {
        "weapon_smoke",
        "weapon_flashbang",
    },
}

-- Yamakazi (Glass cannon - knives + pistols)
TDMRP.LoadoutPools["yamakazi"] = {
    Primary = {
        "weapon_tdmrp_cs_knife",  -- Primary knife!
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "tdmrp_m9k_ragingbull",
        "tdmrp_m9k_m29satan",
    },
    Gear = {
        "weapon_throwing_knife",  -- For Knife Storm
        "weapon_smoke",
    },
}

-- Raider (Auto shotgun specialist)
TDMRP.LoadoutPools["raider"] = {
    Primary = {
        "tdmrp_m9k_spas12",
        "tdmrp_m9k_jackhammer",
        "weapon_tdmrp_cs_pumpshotgun",
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "tdmrp_m9k_ragingbull",
    },
    Gear = {
        "weapon_frag",
        "weapon_flashbang",
    },
}

-- T.A.N.K. (Heavy tank)
TDMRP.LoadoutPools["tank"] = {
    Primary = {
        "tdmrp_m9k_m249lmg",
        "tdmrp_m9k_m60",
        "weapon_tdmrp_cs_aug",
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "tdmrp_m9k_m29satan",
        "tdmrp_m9k_ragingbull",
    },
    Gear = {
        "weapon_medkit",
    },
}

-- Mob Boss (Support/Command)
TDMRP.LoadoutPools["mobboss"] = {
    Primary = {
        "weapon_tdmrp_cs_ak47",
        "tdmrp_m9k_mp5sd",
        "tdmrp_m9k_fal",
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "tdmrp_m9k_coltpython",
    },
    Gear = {
        "weapon_medkit",
        "weapon_binoculars",
    },
}

-- Duke Nukem (Elite - raw power)
TDMRP.LoadoutPools["dukenukem"] = {
    Primary = {
        "tdmrp_m9k_spas12",
        "tdmrp_m9k_jackhammer",
        "tdmrp_m9k_m249lmg",
    },
    Secondary = {
        "tdmrp_m9k_deagle",
        "tdmrp_m9k_m29satan",
    },
    Gear = {
        "weapon_rpg",  -- Duke's explosive personality
        "weapon_frag",
    },
}

----------------------------------------------------
-- HELPER FUNCTIONS
----------------------------------------------------

-- Get loadout pool for a job command
function TDMRP.GetLoadoutPool(jobCommand)
    return TDMRP.LoadoutPools[string.lower(jobCommand)]
end

-- Get loadout pool for a player's current job
function TDMRP.GetPlayerLoadoutPool(ply)
    if not IsValid(ply) then return nil end
    
    local jobTable = ply:getJobTable()
    if not jobTable or not jobTable.command then return nil end
    
    return TDMRP.GetLoadoutPool(jobTable.command)
end

-- Validate that a weapon is in a player's pool for a given slot
function TDMRP.IsWeaponInPool(ply, weaponClass, slot)
    local pool = TDMRP.GetPlayerLoadoutPool(ply)
    if not pool then return false end
    
    local slotWeapons = pool[slot]
    if not slotWeapons then return false end
    
    for _, wepClass in ipairs(slotWeapons) do
        if wepClass == weaponClass then
            return true
        end
    end
    
    return false
end

-- Get list of jobs with loadout pools (combat jobs)
function TDMRP.GetCombatJobs()
    local jobs = {}
    for jobCmd, _ in pairs(TDMRP.LoadoutPools) do
        table.insert(jobs, jobCmd)
    end
    return jobs
end

-- Check if a job is a combat job
function TDMRP.IsCombatJob(jobCommand)
    return TDMRP.LoadoutPools[string.lower(jobCommand)] ~= nil
end

print("[TDMRP] sh_tdmrp_loadout_pools.lua loaded - " .. table.Count(TDMRP.LoadoutPools) .. " job loadouts defined")
