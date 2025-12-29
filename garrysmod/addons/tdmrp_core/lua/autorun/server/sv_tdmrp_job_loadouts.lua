-- sv_tdmrp_job_loadouts.lua
-- Default loadout system for cop/criminal jobs with TDMRP weapon instances

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.JobLoadouts = TDMRP.JobLoadouts or {}

----------------------------------------------------
-- Job Loadout Definitions
-- Format: {sidearm = "class", primary = "class", knife = true (optional)}
----------------------------------------------------

TDMRP.JobLoadouts = {
    -- POLICE JOBS (sorted by BP requirement / power level)
    ["Police Recruit"] = {
        sidearm = "weapon_real_cs_usp",           -- Basic pistol
        primary = "weapon_real_cs_mp5a5"          -- Basic SMG
    },
    ["SWAT"] = {
        sidearm = "weapon_real_cs_p228",          -- Decent pistol
        primary = "weapon_real_cs_pumpshotgun"    -- CQC shotgun
    },
    ["Spetznatz"] = {
        sidearm = "weapon_real_cs_usp",
        primary = "weapon_real_cs_scout"          -- Sniper
    },
    ["Police Medic"] = {
        sidearm = "weapon_real_cs_usp",
        primary = "weapon_real_cs_famas"          -- Mid-tier rifle
    },
    ["Marine"] = {
        sidearm = "weapon_real_cs_five-seven",    -- Better pistol
        primary = "weapon_real_cs_m4a1"           -- Solid rifle
    },
    ["Quartermaster"] = {
        sidearm = "weapon_real_cs_five-seven",
        primary = "weapon_real_cs_m4a1"
    },
    ["Vanguard"] = {
        sidearm = "weapon_real_cs_desert_eagle",  -- High-damage pistol
        primary = "weapon_real_cs_xm1014"         -- Auto shotgun
    },
    ["Stealth Unit"] = {
        sidearm = "weapon_real_cs_usp",
        primary = "weapon_real_cs_scout"          -- Sniper for stealth
    },
    ["Armored Unit"] = {
        sidearm = "weapon_real_cs_desert_eagle",
        primary = "weapon_real_cs_m249"           -- Heavy LMG
    },
    ["Jill Valentine"] = {
        sidearm = "weapon_real_cs_desert_eagle",
        primary = "weapon_real_cs_aug"            -- Elite rifle
    },
    ["Mayor"] = {
        sidearm = "weapon_real_cs_five-seven",
        primary = "weapon_real_cs_famas"
    },
    
    -- CRIMINAL JOBS (sorted by BP requirement / power level)
    ["Gangster"] = {
        sidearm = "weapon_real_cs_glock18",       -- Basic pistol
        primary = "weapon_real_cs_mac10"          -- Basic SMG
    },
    ["Thief"] = {
        sidearm = "weapon_real_cs_glock18",
        primary = "weapon_real_cs_tmp"            -- Stealth SMG
    },
    ["Yamakazi"] = {
        sidearm = "weapon_real_cs_elites",        -- Fast dual pistols
        primary = "weapon_real_cs_p90",           -- Fast SMG
        knife = true                              -- Special knife
    },
    ["Terrorist Sniper"] = {
        sidearm = "weapon_real_cs_glock18",
        primary = "weapon_real_cs_g3sg1"          -- Sniper
    },
    ["Rogue Medic"] = {
        sidearm = "weapon_real_cs_p228",
        primary = "weapon_real_cs_galil"          -- Mid-tier rifle
    },
    ["Trafficker"] = {
        sidearm = "weapon_real_cs_five-seven",
        primary = "weapon_real_cs_ak47"           -- Classic rifle
    },
    ["Terrorist"] = {
        sidearm = "weapon_real_cs_p228",
        primary = "weapon_real_cs_ak47"
    },
    ["The Big Cheese"] = {
        sidearm = "weapon_real_cs_desert_eagle",
        primary = "weapon_real_cs_m249"           -- Heavy LMG
    },
    ["Raider"] = {
        sidearm = "weapon_real_cs_desert_eagle",
        primary = "weapon_real_cs_xm1014"         -- Auto shotgun
    },
    ["T.A.N.K"] = {
        sidearm = "weapon_real_cs_desert_eagle",
        primary = "weapon_real_cs_m249"
    },
    ["Mob Boss"] = {
        sidearm = "weapon_real_cs_five-seven",
        primary = "weapon_real_cs_sg552"          -- Elite rifle
    },
}

----------------------------------------------------
-- Helper: Create weapon instance at random tier (1-4)
----------------------------------------------------
local function CreateRandomTierWeapon(className)
    -- Convert to registry key if needed and check M9K registry
    local regKey = TDMRP.GetRegistryKey and TDMRP.GetRegistryKey(className) or className
    if not TDMRP.M9KRegistry or not TDMRP.M9KRegistry[regKey] then
        print("[TDMRP Loadouts] WARNING: Unknown weapon class: " .. tostring(className))
        return nil
    end
    
    -- Random tier 1-4
    local tier = math.random(1, 4)
    
    -- Use the proper TDMRP instance creation function (same as shop)
    if TDMRP.NewWeaponInstance then
        local inst = TDMRP.NewWeaponInstance(className, tier)
        print("[TDMRP Loadouts] Created instance via NewWeaponInstance: tier=" .. tier .. ", finalDmg=" .. (inst.finalDamage or 0))
        return inst
    else
        -- Fallback: manual instance creation with computed stats
        local finalStats = TDMRP.ComputeFinalStats and TDMRP.ComputeFinalStats(className, tier, nil) or {}
        
        local instance = {
            class = className,
            tier = tier,
            prefixID = nil,
            suffixID = nil,
            -- Calculated final stats for ApplyInstanceToSWEP
            finalDamage = finalStats.damage or 0,
            finalRPM = finalStats.rpm or 0,
            finalRecoil = finalStats.recoil or 0,
            finalSpread = finalStats.spread or 0,
        }
        
        print("[TDMRP Loadouts] Created manual instance: tier=" .. tier .. ", finalDmg=" .. instance.finalDamage)
        return instance
    end
end

----------------------------------------------------
-- Helper: Give weapon instance to player
----------------------------------------------------
local function GiveWeaponInstance(ply, instance)
    if not IsValid(ply) or not instance then return end
    
    local wep = ply:Give(instance.class)
    if not IsValid(wep) then
        print("[TDMRP Loadouts] Failed to give weapon: " .. tostring(instance.class))
        return
    end
    
    -- Apply instance to weapon (sets tier, stats, NWInts for HUD)
    if TDMRP.ApplyInstanceToSWEP then
        TDMRP.ApplyInstanceToSWEP(wep, instance)
    end
    
    -- Store instance ID for tracking (optional, for future features)
    local instanceID = math.random(1000, 65535)
    wep:SetNWInt("TDMRP_InstanceID", instanceID)
    
    print("[TDMRP Loadouts] Gave " .. ply:Nick() .. " a tier-" .. instance.tier .. " " .. instance.class)
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
----------------------------------------------------
local function GiveWeaponAmmo(ply, className)
    if not IsValid(ply) or not className then return end
    
    -- Get weapon metadata to determine type
    local meta = TDMRP.GetWeaponMeta(className)
    if not meta or not meta.type then 
        print("[TDMRP Loadouts] No metadata for weapon: " .. className)
        return 
    end
    
    local ammoType = AMMO_MAP[meta.type]
    if not ammoType then
        print("[TDMRP Loadouts] No ammo mapping for weapon type: " .. meta.type)
        return
    end
    
    print("[TDMRP Loadouts] Giving ammo for " .. className .. " (type: " .. meta.type .. ", ammo: " .. ammoType .. ")")
    
    -- Get the weapon's actual ammo type from the SWEP
    local wep = ply:GetWeapon(className)
    local ammoTypeName = "Pistol" -- default
    
    if IsValid(wep) and wep.Primary then
        ammoTypeName = wep.Primary.Ammo or "Pistol"
    end
    
    -- Give ammo directly (3x magazine worth)
    local ammoPerPack = 30 -- default amount per pack
    
    -- Adjust ammo per pack based on weapon type
    if meta.type == "pistol" then ammoPerPack = 20
    elseif meta.type == "smg" then ammoPerPack = 30
    elseif meta.type == "rifle" then ammoPerPack = 30
    elseif meta.type == "shotgun" then ammoPerPack = 8
    elseif meta.type == "sniper" then ammoPerPack = 10
    elseif meta.type == "lmg" then ammoPerPack = 100
    elseif meta.type == "melee" then ammoPerPack = 1
    end
    
    -- Give 3 packs worth of ammo
    local totalAmmo = ammoPerPack * 3
    ply:GiveAmmo(totalAmmo, ammoTypeName, true)
    
    print("[TDMRP Loadouts] Gave " .. ply:Nick() .. " " .. totalAmmo .. " rounds of " .. ammoTypeName .. " for " .. className)
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
    
    -- Give knife first (if applicable)
    if loadout.knife then
        local knifeInstance = CreateRandomTierWeapon("weapon_real_cs_knife")
        if knifeInstance then
            GiveWeaponInstance(ply, knifeInstance)
            -- Give ammo for knife
            timer.Simple(0.3, function()
                if IsValid(ply) then
                    GiveWeaponAmmo(ply, "weapon_real_cs_knife")
                end
            end)
        end
    end
    
    -- Give sidearm
    if loadout.sidearm then
        local sidearmInstance = CreateRandomTierWeapon(loadout.sidearm)
        if sidearmInstance then
            GiveWeaponInstance(ply, sidearmInstance)
            -- Give ammo for sidearm
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
            -- Give ammo for primary
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
-- Hook: Give loadout on spawn
----------------------------------------------------
hook.Add("PlayerLoadout", "TDMRP_JobLoadouts", function(ply)
    local teamID = ply:Team()
    local job = RPExtraTeams and RPExtraTeams[teamID]
    if not job then return end
    
    local jobClass = job.tdmrp_class
    
    -- If cop or criminal, block default DarkRP loadout
    if jobClass == "cop" or jobClass == "criminal" then
        -- Return true to block default DarkRP weapons
        return true
    end
end)

hook.Add("PlayerSpawn", "TDMRP_GiveJobLoadouts", function(ply)
    -- Clear test bind data
    if TDMRP.TestBindWeapons then
        TDMRP.TestBindWeapons[ply:SteamID64()] = nil
    end
    
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    local jobClass = job and job.tdmrp_class or "civilian"
    
    -- Only give loadout for combat classes
    -- Civilians keep their bound weapons (restored by spawn_orchestrator)
    if jobClass == "cop" or jobClass == "criminal" then
        timer.Simple(0.2, function()
            if IsValid(ply) then
                GiveJobLoadout(ply)
            end
        end)
    end
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
