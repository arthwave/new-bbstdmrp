-- sv_tdmrp_job_loadouts.lua
-- Default loadout system for cop/criminal jobs with TDMRP weapon instances

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.JobLoadouts = TDMRP.JobLoadouts or {}

----------------------------------------------------
-- Job Loadout Definitions
-- Format: {sidearm = "class", primary = "class", knife = true (optional)}
-- ALL CLASSES MUST BE TDMRP wrappers (tdmrp_m9k_* or weapon_tdmrp_cs_*)
----------------------------------------------------

TDMRP.JobLoadouts = {
    ----------------------------------------------------
    -- POLICE JOBS (sorted by BP requirement / power level)
    ----------------------------------------------------
    
    -- STARTER (0 BP, locked after 60)
    ["Police Recruit"] = {
        sidearm = "weapon_tdmrp_cs_usp",           -- Basic reliable pistol
        primary = "weapon_tdmrp_cs_mp5a5"          -- Classic SMG
    },
    
    -- TIER 2 (60 BP)
    ["SWAT"] = {
        sidearm = "tdmrp_m9k_hk45",                -- Tactical pistol
        primary = "weapon_tdmrp_cs_m4a1"          -- Standard issue rifle
    },
    ["Field Surgeon"] = {
        sidearm = "weapon_tdmrp_cs_p228",         -- Compact sidearm
        primary = "weapon_tdmrp_cs_famas"         -- Burst rifle for support
    },
    ["Armsmaster"] = {
        sidearm = "tdmrp_m9k_sig_p229r",          -- Reliable pistol
        primary = "tdmrp_m9k_m416"                -- Versatile rifle
    },
    
    -- TIER 3 (100 BP)
    ["Marine"] = {
        sidearm = "weapon_tdmrp_cs_desert_eagle", -- High-damage pistol
        primary = "tdmrp_m9k_scar"                -- Battle rifle
    },
    ["Special Forces"] = {
        sidearm = "tdmrp_m9k_colt1911",           -- Classic sidearm
        primary = "weapon_tdmrp_cs_scout"         -- Sniper for precision
    },
    
    -- TIER 4 (120 BP)
    ["Recon"] = {
        sidearm = "weapon_tdmrp_cs_five_seven",   -- Armor-piercing pistol
        primary = "tdmrp_m9k_honeybadger"         -- Suppressed PDW for stealth
    },
    
    -- BP LOSS ZONE
    ["Vanguard"] = {
        sidearm = "tdmrp_m9k_deagle",             -- Hand cannon
        primary = "weapon_tdmrp_cs_aug"           -- Scoped assault rifle
    },
    ["Armored Unit"] = {
        sidearm = "tdmrp_m9k_model500",           -- Massive revolver
        primary = "tdmrp_m9k_m249lmg"             -- LMG for suppression
    },
    ["Mayor"] = {
        sidearm = "tdmrp_m9k_coltpython",         -- Elegant revolver
        primary = "weapon_tdmrp_cs_sg552"         -- Scoped commando rifle
    },
    
    -- ELITE (1000 BP)
    ["Master Chief"] = {
        sidearm = "tdmrp_m9k_m29satan",           -- Satan's Hand
        primary = "tdmrp_m9k_barret_m82"          -- Anti-materiel rifle
    },
    
    ----------------------------------------------------
    -- CRIMINAL JOBS (sorted by BP requirement / power level)
    ----------------------------------------------------
    
    -- STARTER (0 BP, locked after 60)
    ["Gangster Initiate"] = {
        sidearm = "weapon_tdmrp_cs_glock18",      -- Street pistol
        primary = "weapon_tdmrp_cs_mac10"         -- Cheap SMG
    },
    
    -- TIER 2 (60 BP)
    ["Thief"] = {
        sidearm = "weapon_tdmrp_cs_p228",         -- Compact for stealth
        primary = "weapon_tdmrp_cs_tmp"           -- Silent SMG
    },
    ["Dr. Evil"] = {
        sidearm = "weapon_tdmrp_cs_usp",          -- Silenced pistol
        primary = "weapon_tdmrp_cs_galil"         -- Budget rifle
    },
    ["Merchant of Death"] = {
        sidearm = "tdmrp_m9k_hk45",               -- Quality sidearm
        primary = "weapon_tdmrp_cs_ak47"          -- Classic AK
    },
    
    -- TIER 3 (100 BP)
    ["Mercenary"] = {
        sidearm = "weapon_tdmrp_cs_desert_eagle", -- Hand cannon
        primary = "tdmrp_m9k_an94"                -- Russian precision rifle
    },
    ["Deadeye"] = {
        sidearm = "tdmrp_m9k_luger",              -- Classic pistol
        primary = "tdmrp_m9k_intervention"        -- Sniper rifle
    },
    
    -- TIER 4 (120 BP)
    ["Yamakazi"] = {
        sidearm = "weapon_tdmrp_cs_elites",       -- Dual pistols
        primary = "weapon_tdmrp_cs_p90",          -- High-cap SMG
        knife = true                              -- Throwing knife
    },
    
    -- BP LOSS ZONE
    ["Raider"] = {
        sidearm = "tdmrp_m9k_ragingbull",         -- Massive revolver
        primary = "tdmrp_m9k_jackhammer"          -- Auto shotgun
    },
    ["T.A.N.K."] = {
        sidearm = "tdmrp_m9k_model627",           -- Sturdy revolver
        primary = "tdmrp_m9k_m60"                 -- General purpose MG
    },
    ["Mob Boss"] = {
        sidearm = "tdmrp_m9k_coltpython",         -- Stylish revolver
        primary = "tdmrp_m9k_val"                 -- Suppressed rifle
    },
    
    -- ELITE (1000 BP)
    ["Duke Nukem"] = {
        sidearm = "tdmrp_m9k_m29satan",           -- Satan's Hand
        primary = "tdmrp_m9k_m60"                 -- M60 LMG - "Hail to the king, baby!"
    },
}

----------------------------------------------------
-- Helper: Create weapon instance at random tier (1-4)
-- Handles both tdmrp_m9k_* and weapon_tdmrp_cs_* classes
----------------------------------------------------
local function CreateRandomTierWeapon(className)
    -- Determine weapon type
    local isCSS = string.sub(className, 1, 16) == "weapon_tdmrp_cs_"
    local isTDMRPM9K = string.sub(className, 1, 10) == "tdmrp_m9k_"
    local isBaseM9K = string.sub(className, 1, 4) == "m9k_"
    
    -- Convert base m9k_ to tdmrp_m9k_ if needed
    if isBaseM9K and not isTDMRPM9K then
        className = "tdmrp_" .. className
        isTDMRPM9K = true
    end
    
    -- Random tier 1-4
    local tier = math.random(1, 4)
    
    -- For M9K weapons, check registry
    if isTDMRPM9K then
        local regKey = string.gsub(className, "^tdmrp_", "")  -- m9k_xxx
        if TDMRP.M9KRegistry and not TDMRP.M9KRegistry[regKey] then
            print("[TDMRP Loadouts] WARNING: Unknown M9K weapon class: " .. tostring(className))
            -- Still allow it to be created - may work anyway
        end
    end
    
    -- Create instance
    local instance = {
        class = className,
        tier = tier,
        prefixID = nil,
        suffixID = nil,
        finalDamage = 0,
        finalRPM = 0,
        finalRecoil = 0,
        finalSpread = 0,
    }
    
    -- Try to compute final stats if system available
    if TDMRP.ComputeFinalStats then
        local finalStats = TDMRP.ComputeFinalStats(className, tier, nil)
        instance.finalDamage = finalStats.damage or 0
        instance.finalRPM = finalStats.rpm or 0
        instance.finalRecoil = finalStats.recoil or 0
        instance.finalSpread = finalStats.spread or 0
    end
    
    print("[TDMRP Loadouts] Created instance: " .. className .. " (Tier " .. tier .. ")")
    return instance
end

----------------------------------------------------
-- Helper: Give weapon instance to player
-- Works with both tdmrp_m9k_* and weapon_tdmrp_cs_*
----------------------------------------------------
local function GiveWeaponInstance(ply, instance)
    if not IsValid(ply) or not instance then return end
    
    local wep = ply:Give(instance.class)
    if not IsValid(wep) then
        print("[TDMRP Loadouts] Failed to give weapon: " .. tostring(instance.class))
        return
    end
    
    -- Set tier directly
    wep.Tier = instance.tier or 1
    
    -- Apply mixin setup
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(wep)
    end
    
    -- Apply instance if system available
    if TDMRP.ApplyInstanceToSWEP then
        TDMRP.ApplyInstanceToSWEP(wep, instance)
    end
    
    -- Store instance ID for tracking
    local instanceID = math.random(1000, 65535)
    wep:SetNWInt("TDMRP_InstanceID", instanceID)
    
    print("[TDMRP Loadouts] Gave " .. ply:Nick() .. " a Tier " .. instance.tier .. " " .. instance.class)
end

----------------------------------------------------
-- Strip default DarkRP tools from combat jobs
----------------------------------------------------
local function StripRoleplayTools(ply)
    if not IsValid(ply) then return end
    
    -- Remove all default DarkRP tools
    local toolsToRemove = {
        "keys",
        "pocket",
        "weapon_physcannon",
        "weapon_physgun",
        "gmod_tool",
        "gmod_camera"
    }
    
    for _, tool in ipairs(toolsToRemove) do
        if ply:HasWeapon(tool) then
            ply:StripWeapon(tool)
        end
    end
end

----------------------------------------------------
-- Ammo type mapping for weapons
----------------------------------------------------
local AMMO_MAP = {
    pistol = "item_ammo_pistol_large",
    smg = "item_ammo_smg1_large",
    rifle = "item_ammo_smg1_large",
    shotgun = "item_box_buckshot",
    sniper = "item_ammo_smg1_large",
    lmg = "item_ammo_smg1_large",
    melee = "item_ammo_crossbow",  -- Knife
}

-- Fallback ammo if large versions don't exist
local AMMO_FALLBACK = {
    item_ammo_pistol_large = "item_ammo_pistol",
    item_ammo_smg1_large = "item_ammo_smg1",
}

----------------------------------------------------
-- Give ammo for weapon type
-- Works with both tdmrp_m9k_* and weapon_tdmrp_cs_*
----------------------------------------------------
local function GiveWeaponAmmo(ply, className)
    if not IsValid(ply) or not className then return end
    
    -- Get weapon metadata to determine type
    local meta = nil
    local isCSS = string.sub(className, 1, 16) == "weapon_tdmrp_cs_"
    
    if isCSS then
        -- CSS weapon types (hardcoded since no registry)
        local CSS_TYPES = {
            ["weapon_tdmrp_cs_glock18"] = "pistol",
            ["weapon_tdmrp_cs_usp"] = "pistol",
            ["weapon_tdmrp_cs_p228"] = "pistol",
            ["weapon_tdmrp_cs_five_seven"] = "pistol",
            ["weapon_tdmrp_cs_elites"] = "pistol",
            ["weapon_tdmrp_cs_desert_eagle"] = "pistol",
            ["weapon_tdmrp_cs_mp5a5"] = "smg",
            ["weapon_tdmrp_cs_p90"] = "smg",
            ["weapon_tdmrp_cs_mac10"] = "smg",
            ["weapon_tdmrp_cs_tmp"] = "smg",
            ["weapon_tdmrp_cs_ump_45"] = "smg",
            ["weapon_tdmrp_cs_ak47"] = "rifle",
            ["weapon_tdmrp_cs_m4a1"] = "rifle",
            ["weapon_tdmrp_cs_aug"] = "rifle",
            ["weapon_tdmrp_cs_famas"] = "rifle",
            ["weapon_tdmrp_cs_sg552"] = "rifle",
            ["weapon_tdmrp_cs_galil"] = "rifle",
            ["weapon_tdmrp_cs_pumpshotgun"] = "shotgun",
            ["weapon_tdmrp_cs_awp"] = "sniper",
            ["weapon_tdmrp_cs_scout"] = "sniper",
            ["weapon_tdmrp_cs_knife"] = "melee",
        }
        meta = { type = CSS_TYPES[className] or "rifle" }
    else
        -- M9K weapon - try registry
        local regKey = string.gsub(className, "^tdmrp_", "")
        meta = TDMRP.GetWeaponMeta and TDMRP.GetWeaponMeta(regKey)
        if not meta then
            meta = TDMRP.M9KRegistry and TDMRP.M9KRegistry[regKey]
        end
    end
    
    if not meta or not meta.type then 
        print("[TDMRP Loadouts] No metadata for weapon: " .. className .. ", defaulting to rifle ammo")
        meta = { type = "rifle" }
    end
    
    -- Get the weapon's actual ammo type from the SWEP
    local wep = ply:GetWeapon(className)
    local ammoTypeName = "Pistol" -- default
    
    if IsValid(wep) and wep.Primary then
        ammoTypeName = wep.Primary.Ammo or "Pistol"
    end
    
    -- Adjust ammo amount based on weapon type
    local ammoPerPack = 30
    if meta.type == "pistol" then ammoPerPack = 20
    elseif meta.type == "smg" then ammoPerPack = 30
    elseif meta.type == "rifle" then ammoPerPack = 30
    elseif meta.type == "shotgun" then ammoPerPack = 8
    elseif meta.type == "sniper" then ammoPerPack = 10
    elseif meta.type == "lmg" then ammoPerPack = 100
    elseif meta.type == "melee" then ammoPerPack = 5  -- Throwing knives
    end
    
    -- Give 3 packs worth of ammo
    local totalAmmo = ammoPerPack * 3
    ply:GiveAmmo(totalAmmo, ammoTypeName, true)
    
    print("[TDMRP Loadouts] Gave " .. ply:Nick() .. " " .. totalAmmo .. " rounds of " .. ammoTypeName)
end

----------------------------------------------------
-- Give default loadout to player
----------------------------------------------------
local function GiveJobLoadout(ply)
    if not IsValid(ply) then return end
    
    local teamID = ply:Team()
    local job = RPExtraTeams and RPExtraTeams[teamID]
    if not job then return end
    
    local jobName = job.name
    local jobClass = job.tdmrp_class
    
    -- Only give loadouts to cop/criminal jobs
    if jobClass ~= "cop" and jobClass ~= "criminal" then return end
    
    -- Strip roleplay tools
    StripRoleplayTools(ply)
    
    -- Get loadout for this job
    local loadout = TDMRP.JobLoadouts[jobName]
    if not loadout then
        print("[TDMRP Loadouts] No loadout defined for job: " .. jobName)
        return
    end
    
    print("[TDMRP Loadouts] Giving loadout to " .. ply:Nick() .. " (" .. jobName .. ")")
    
    -- Give knife first (if applicable) - uses TDMRP CSS knife
    if loadout.knife then
        local knifeInstance = CreateRandomTierWeapon("weapon_tdmrp_cs_knife")
        if knifeInstance then
            GiveWeaponInstance(ply, knifeInstance)
            timer.Simple(0.3, function()
                if IsValid(ply) then
                    -- Give throwing knife ammo (XBowBolt)
                    ply:GiveAmmo(10, "XBowBolt", true)
                end
            end)
        end
    end
    
    -- Give sidearm
    if loadout.sidearm then
        local sidearmInstance = CreateRandomTierWeapon(loadout.sidearm)
        if sidearmInstance then
            GiveWeaponInstance(ply, sidearmInstance)
            timer.Simple(0.4, function()
                if IsValid(ply) then
                    GiveWeaponAmmo(ply, loadout.sidearm)
                end
            end)
        end
    end
    
    -- Give primary
    if loadout.primary then
        local primaryInstance = CreateRandomTierWeapon(loadout.primary)
        if primaryInstance then
            GiveWeaponInstance(ply, primaryInstance)
            timer.Simple(0.5, function()
                if IsValid(ply) then
                    GiveWeaponAmmo(ply, loadout.primary)
                end
            end)
        end
    end
    
    -- Select primary weapon
    if loadout.primary then
        timer.Simple(0.6, function()
            if IsValid(ply) and ply:HasWeapon(loadout.primary) then
                ply:SelectWeapon(loadout.primary)
            end
        end)
    end
end

----------------------------------------------------
-- Hook: Combat role spawn handling
-- Combat roles get physgun + toolgun only, then select loadout via UI
----------------------------------------------------
hook.Add("PlayerLoadout", "TDMRP_JobLoadouts", function(ply)
    local teamID = ply:Team()
    local job = RPExtraTeams and RPExtraTeams[teamID]
    if not job then return end
    
    local jobClass = job.tdmrp_class
    
    -- Combat roles (cop/criminal): Block default DarkRP weapons
    -- They will get physgun + toolgun, then select weapons via loadout UI
    if jobClass == "cop" or jobClass == "criminal" then
        -- Give physgun and toolgun only
        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            ply:Give("weapon_physgun")
            ply:Give("gmod_tool")
            ply:SelectWeapon("weapon_physgun")
        end)
        -- Return true to block default DarkRP weapons
        return true
    end
    
    -- Civilians: Let DarkRP handle their loadout normally
end)

hook.Add("PlayerSpawn", "TDMRP_GiveJobLoadouts", function(ply)
    -- Clear test bind data
    if TDMRP.TestBindWeapons then
        TDMRP.TestBindWeapons[ply:SteamID64()] = nil
    end
    
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    local jobClass = job and job.tdmrp_class or "civilian"
    
    -- Combat roles: DO NOT auto-give loadout
    -- They will select weapons via the loadout UI (cl_tdmrp_loadout_ui.lua)
    -- The loadout UI will trigger and they'll pick their weapons there
    
    -- Civilians keep their default DarkRP behavior
    -- (restored by spawn_orchestrator if they have bound weapons)
end)

----------------------------------------------------
-- Handle weapon drops on death
-- CLEAN SYSTEM: Bound weapons stay, unbound weapons drop
----------------------------------------------------
hook.Add("PlayerDeath", "TDMRP_OnPlayerDeath", function(victim, inflictor, attacker)
    if not IsValid(victim) then return end
    
    local weapons = victim:GetWeapons()
    if not weapons or #weapons == 0 then 
        print("[TDMRP Death] No weapons to process")
        return 
    end
    
    local deathPos = victim:GetPos() + Vector(0, 0, 40) -- Slightly above player
    local boundCount = 0
    local droppedCount = 0
    
    print(string.format("[TDMRP Death] Processing %d weapons for %s", #weapons, victim:Nick()))
    
    -- Iterate through weapons: drop unbound, keep bound
    for i, wep in ipairs(weapons) do
        if not IsValid(wep) then 
            print(string.format("[TDMRP Death] Weapon %d: Invalid entity, skipping", i))
            continue 
        end
        
        local class = wep:GetClass()
        
        -- Debug info for M9K check
        local isM9K = TDMRP.IsM9KWeapon and TDMRP.IsM9KWeapon(wep)
        
        -- Only process TDMRP combat weapons
        if not isM9K then
            print(string.format("[TDMRP Death] Weapon %d (%s): Not a TDMRP weapon (IsM9KWeapon=%s), skipping", i, class, tostring(TDMRP.IsM9KWeapon(wep) or false)))
            continue
        end
        
        -- Check if this weapon is BOUND
        local bindExpire = wep:GetNWFloat("TDMRP_BindExpire", 0)
        local remaining = bindExpire > 0 and (bindExpire - CurTime()) or 0
        local isBinding = remaining > 0
        
        -- Also check instance for bound_until
        local instanceBound = false
        if wep.TDMRP_Instance and wep.TDMRP_Instance.bound_until and wep.TDMRP_Instance.bound_until > 0 then
            instanceBound = true
            print(string.format("[TDMRP Death] >> Instance has bound_until: %.1f seconds", wep.TDMRP_Instance.bound_until))
        end
        
        -- Also check fallback storage for test binds
        local testBound = false
        local testBindInfo = TDMRP.TestBindWeapons and TDMRP.TestBindWeapons[victim:SteamID64()]
        if testBindInfo and testBindInfo.entID == wep:EntIndex() and testBindInfo.expireTime > CurTime() then
            testBound = true
            remaining = testBindInfo.expireTime - CurTime()
            print(string.format("[TDMRP Death] >> Test bind found: expires in %.1f seconds", remaining))
        end
        
        print(string.format("[TDMRP Death] Weapon %d (EntID=%d) (%s): BindExpire=%.1f, CurTime=%.1f, Remaining=%.1f, IsBound=%s, InstanceBound=%s, TestBound=%s", i, wep:EntIndex(), class, bindExpire, CurTime(), remaining, tostring(isBinding), tostring(instanceBound), tostring(testBound)))
        
        if isBinding or instanceBound or testBound then
            -- KEEP bound weapons in player inventory
            print(string.format("[TDMRP Death] >> PRESERVING bound weapon: %s (%.1f sec remaining)", class, remaining > 0 and remaining or (wep.TDMRP_Instance and wep.TDMRP_Instance.bound_until or 0)))
            boundCount = boundCount + 1
        else
            -- DROP unbound weapons to ground with explosion effect
            print(string.format("[TDMRP Death] >> DROPPING unbound weapon: %s", class))
            
            -- Create dropped weapon entity directly
            local droppedWep = ents.Create(class)
            if not IsValid(droppedWep) then 
                print(string.format("[TDMRP Death] Failed to create entity for %s", class))
                continue 
            end
            
            droppedWep:SetPos(deathPos)
            droppedWep:SetAngles(Angle(0, 0, 0))
            
            -- Copy all TDMRP stats/NWVars BEFORE spawning
            droppedWep:SetNWInt("TDMRP_Tier", wep:GetNWInt("TDMRP_Tier", 0))
            droppedWep:SetNWInt("TDMRP_Damage", wep:GetNWInt("TDMRP_Damage", 0))
            droppedWep:SetNWInt("TDMRP_RPM", wep:GetNWInt("TDMRP_RPM", 0))
            droppedWep:SetNWInt("TDMRP_Accuracy", wep:GetNWInt("TDMRP_Accuracy", 0))
            droppedWep:SetNWInt("TDMRP_Recoil", wep:GetNWInt("TDMRP_Recoil", 0))
            droppedWep:SetNWInt("TDMRP_Handling", wep:GetNWInt("TDMRP_Handling", 0))
            droppedWep:SetNWString("TDMRP_PrefixID", wep:GetNWString("TDMRP_PrefixID", ""))
            droppedWep:SetNWString("TDMRP_SuffixID", wep:GetNWString("TDMRP_SuffixID", ""))
            droppedWep:SetNWString("TDMRP_CustomName", wep:GetNWString("TDMRP_CustomName", ""))
            droppedWep:SetNWInt("TDMRP_InstanceID", wep:GetNWInt("TDMRP_InstanceID", 0))
            
            -- Spawn after copying data
            droppedWep:Spawn()
            
            -- Apply radial explosion force for scatter effect
            local phys = droppedWep:GetPhysicsObject()
            if IsValid(phys) then
                phys:Wake()
                
                -- Random direction outward from death position
                local angle = math.random(0, 360)
                local pitch = math.random(-30, 30)
                local dir = Angle(pitch, angle, 0):Forward()
                
                -- Radial scatter force (200-400 units)
                local force = dir * math.random(200, 400)
                force.z = math.random(150, 300) -- Upward component
                
                phys:SetVelocity(force)
                phys:AddAngleVelocity(VectorRand() * 200) -- Add spin
            end
            
            print(string.format("[TDMRP Death] Dropped unbound weapon: %s", class))
            droppedCount = droppedCount + 1
        end
    end
    
    print(string.format("[TDMRP Death] %s died: %d bound weapons preserved, %d unbound dropped", victim:Nick(), boundCount, droppedCount))
end)

----------------------------------------------------
-- Block DarkRP pocket item drop for combat jobs
----------------------------------------------------
-- Must run BEFORE DarkRP's "DropPocketItems" hook
-- Using HOOK_HIGH priority to run first
local HOOK_HIGH = -2

hook.Add("PlayerDeath", "TDMRP_BlockPocketDrop", function(ply)
    if not IsValid(ply) then return end
    
    local teamID = ply:Team()
    local job = RPExtraTeams and RPExtraTeams[teamID]
    if not job then return end
    
    local jobClass = job.tdmrp_class
    
    -- If cop or criminal, clear pocket before DarkRP can drop it
    if jobClass == "cop" or jobClass == "criminal" then
        -- Clear pocket table to prevent DarkRP from dropping items
        if ply.darkRPPocket then
            print("[TDMRP Loadouts] Clearing pocket for combat job: " .. (job.name or "unknown"))
            ply.darkRPPocket = nil
        end
    end
end, HOOK_HIGH)

----------------------------------------------------
-- Block weapon drops for non-TDMRP weapons
----------------------------------------------------
hook.Add("canDropWeapon", "TDMRP_BlockNonCombatWeaponDrop", function(ply, weapon)
    if not IsValid(weapon) then return end
    
    local class = weapon:GetClass()
    
    -- Only allow dropping weapons that are tdmrp_m9k_*
    if not TDMRP.IsM9KWeapon or not TDMRP.IsM9KWeapon(class) then
        return false
    end
    
    -- Allow TDMRP combat weapons to drop
    return true
end)

print("[TDMRP] sv_tdmrp_job_loadouts.lua loaded (combat job loadouts + death weapon drop)")
