-- sv_tdmrp_spawn_orchestrator.lua
-- Central spawn coordinator for TDMRP
-- Handles: Loadout UI, job stats, weapon giving, XP buffs

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.Spawn = TDMRP.Spawn or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

local CONFIG = {
    LOADOUT_TIMEOUT = 15,           -- Seconds before auto-spawn with defaults
    SPAWN_DELAY = 0.1,              -- Small delay after DarkRP finishes
    FREEZE_DURING_LOADOUT = true,   -- Freeze player during loadout selection
}

----------------------------------------------------
-- Network Strings
----------------------------------------------------

util.AddNetworkString("TDMRP_ShowLoadoutMenu")
util.AddNetworkString("TDMRP_LoadoutConfirmed")
util.AddNetworkString("TDMRP_LoadoutBypass")
util.AddNetworkString("TDMRP_LoadoutTimeout")
util.AddNetworkString("TDMRP_SpawnComplete")

----------------------------------------------------
-- Pending Spawns (players waiting for loadout selection)
-- Now also tracks bound weapons that will be restored
----------------------------------------------------

TDMRP.Spawn.PendingSpawns = TDMRP.Spawn.PendingSpawns or {}
TDMRP.Spawn.PendingBoundWeapons = TDMRP.Spawn.PendingBoundWeapons or {}

----------------------------------------------------
-- Helper: Get job data for player
----------------------------------------------------

local function GetPlayerJob(ply)
    if not IsValid(ply) then return nil end
    
    local teamID = ply:Team()
    if not RPExtraTeams then return nil end
    
    return RPExtraTeams[teamID]
end

----------------------------------------------------
-- Helper: Get TDMRP class for player
----------------------------------------------------

local function GetPlayerClass(ply)
    local job = GetPlayerJob(ply)
    if not job then return "civilian" end
    
    return job.tdmrp_class or "civilian"
end

----------------------------------------------------
-- Helper: Normalize loadout pool key
-- Prefer `job.command`, then `job.tdmrp_loadout_key`, then sanitized lowercased `job.name`
----------------------------------------------------
local function GetPoolKeyFromJob(job)
    if not job then return nil end
    if job.command and job.command ~= "" then
        return job.command
    end
    if job.tdmrp_loadout_key and job.tdmrp_loadout_key ~= "" then
        return job.tdmrp_loadout_key
    end
    if job.name and job.name ~= "" then
        return string.gsub(string.lower(tostring(job.name)), "%s+", "")
    end
    return nil
end

local function NormalizePoolKey(name)
    if not name then return nil end
    if TDMRP and TDMRP.LoadoutPools and TDMRP.LoadoutPools[name] then
        return name
    end
    -- sanitize
    local key = string.gsub(string.lower(tostring(name)), "%s+", "")
    return key
end

----------------------------------------------------
-- Helper: Is combat class (cop or criminal)
----------------------------------------------------

local function IsCombatClass(ply)
    local class = GetPlayerClass(ply)
    return class == "cop" or class == "criminal"
end

----------------------------------------------------
-- Helper: Collect bound weapons from player (on death)
-- Returns table of weapon data to restore on respawn
----------------------------------------------------

local function CollectBoundWeapons(ply)
    if not IsValid(ply) then return {} end
    
    local boundWeapons = {}
    local sid = ply:SteamID64()
    
    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) and TDMRP.IsM9KWeapon and TDMRP.IsM9KWeapon(wep) then
            local expireTime = wep:GetNWFloat("TDMRP_BindExpire", 0)
            local remaining = expireTime > 0 and (expireTime - CurTime()) or 0
            
            -- Check test bind storage (fallback)
            local testBindInfo = TDMRP.TestBindWeapons and TDMRP.TestBindWeapons[sid]
            if testBindInfo and testBindInfo.entID == wep:EntIndex() and testBindInfo.expireTime > CurTime() then
                remaining = testBindInfo.expireTime - CurTime()
                print(string.format("[TDMRP Spawn] Found test bind: %s (%.1f sec remaining)", wep:GetClass(), remaining))
            end
            
            -- Check instance binding
            local instanceBound = wep.TDMRP_Instance and wep.TDMRP_Instance.bound_until and wep.TDMRP_Instance.bound_until > 0
            if instanceBound and remaining <= 0 then
                remaining = wep.TDMRP_Instance.bound_until
                print(string.format("[TDMRP Spawn] Found instance binding: %s (%.1f sec)", wep:GetClass(), remaining))
            end
            
            if remaining > 0 then
                -- CRITICAL: Restore craft data from test bind if available
                -- This ensures prefix/suffix/material are preserved through death
                local testBindInfo = TDMRP.TestBindWeapons and TDMRP.TestBindWeapons[sid]
                print(string.format("[TDMRP Spawn] Checking testBindInfo: has_testBindWeapons=%s, testBindInfo=%s, wepEntID=%d", 
                    TDMRP.TestBindWeapons and "YES" or "NO", testBindInfo and "YES" or "NO", wep:EntIndex()))
                
                if testBindInfo and testBindInfo.entID == wep:EntIndex() then
                    print(string.format("[TDMRP Spawn] testBindInfo MATCHED (entID %d == %d)", testBindInfo.entID, wep:EntIndex()))
                    if testBindInfo.prefixId and testBindInfo.prefixId ~= "" then
                        wep:SetNWString("TDMRP_PrefixID", testBindInfo.prefixId)
                        print(string.format("[TDMRP Spawn] Restored prefix from test bind: %s", testBindInfo.prefixId))
                    end
                    if testBindInfo.suffixId and testBindInfo.suffixId ~= "" then
                        wep:SetNWString("TDMRP_SuffixID", testBindInfo.suffixId)
                        print(string.format("[TDMRP Spawn] Restored suffix from test bind: %s", testBindInfo.suffixId))
                    end
                    -- CRITICAL: Restore material from test bind (suffix visual effect)
                    if testBindInfo.material and testBindInfo.material ~= "" then
                        wep:SetNWString("TDMRP_Material", testBindInfo.material)
                        wep.TDMRP_StoredMaterial = testBindInfo.material
                        print(string.format("[TDMRP Spawn] Restored material from test bind: %s", testBindInfo.material))
                    else
                        print(string.format("[TDMRP Spawn] NO material in testBindInfo (material=%s)", testBindInfo.material or "nil"))
                    end
                    -- CRITICAL: Restore custom name from test bind
                    if testBindInfo.customName and testBindInfo.customName ~= "" then
                        wep:SetNWString("TDMRP_CustomName", testBindInfo.customName)
                        wep.TDMRP_CustomName = testBindInfo.customName
                        print(string.format("[TDMRP Spawn] Restored custom name from test bind: %s", testBindInfo.customName))
                    end
                    -- Always mark as crafted if it has prefix or suffix
                    if (testBindInfo.prefixId and testBindInfo.prefixId ~= "") or (testBindInfo.suffixId and testBindInfo.suffixId ~= "") then
                        wep:SetNWBool("TDMRP_Crafted", true)
                        print("[TDMRP Spawn] Marked as crafted due to prefix/suffix in test bind")
                    elseif testBindInfo.crafted then
                        wep:SetNWBool("TDMRP_Crafted", testBindInfo.crafted)
                        print("[TDMRP Spawn] Restored crafted flag from test bind: true")
                    end
                else
                    print(string.format("[TDMRP Spawn] testBindInfo MISSING or NOT MATCHED (testBindInfo=%s, expected entID=%s, got=%d)", 
                        testBindInfo and "YES" or "NO", testBindInfo and testBindInfo.entID or "nil", wep:EntIndex()))
                    print(string.format("[TDMRP Spawn] Weapon NWStrings: Material=%s, PrefixID=%s, SuffixID=%s, StoredMat=%s", 
                        wep:GetNWString("TDMRP_Material", ""), wep:GetNWString("TDMRP_PrefixID", ""), 
                        wep:GetNWString("TDMRP_SuffixID", ""), wep.TDMRP_StoredMaterial or "nil"))
                end
                
                -- Build instance from weapon
                local inst = TDMRP_BuildInstanceFromSWEP(ply, wep)
                if inst then
                    table.insert(boundWeapons, {
                        class = wep:GetClass(),
                        remaining = remaining,
                        instance = inst,
                        displayName = wep:GetPrintName() or wep:GetClass(),
                    })
                    print(string.format("[TDMRP Spawn] COLLECTED bound weapon: %s (%.1f sec remaining, material=%s)", wep:GetClass(), remaining, inst.craft.material or "nil"))
                end
            end
        end
    end
    
    return boundWeapons
end

----------------------------------------------------
-- Helper: Restore bound weapons to player
----------------------------------------------------

local function RestoreBoundWeapons(ply, boundWeapons, respawnPenalty)
    if not IsValid(ply) or not boundWeapons then return end
    
    respawnPenalty = respawnPenalty or 30  -- Default 30 sec penalty
    
    print(string.format("[TDMRP Spawn] RestoreBoundWeapons: %d weapons to restore", #boundWeapons))
    
    -- ⚠️ CRITICAL BIND SYSTEM: Do not reorder these steps without testing
    for _, weaponData in ipairs(boundWeapons) do
        local newRemaining = weaponData.remaining - respawnPenalty
        
        print(string.format("[TDMRP Spawn] >> Processing %s: remaining=%.1f, penalty=%d, newRemaining=%.1f", weaponData.class, weaponData.remaining, respawnPenalty, newRemaining))
        
        if newRemaining > 0 then
            -- Check if player already has this weapon
            if ply:HasWeapon(weaponData.class) then
                print(string.format("[TDMRP Spawn] >> Already has %s, stripping", weaponData.class))
                ply:StripWeapon(weaponData.class)
            end
            
            -- Update instance with new remaining time BEFORE Give()
            local inst = weaponData.instance
            inst.bound_until = newRemaining
            
            -- CRITICAL: Set pending instance BEFORE Give() so mixin's Setup() can apply it
            -- This ensures bind timer is applied during weapon initialization, not after
            if TDMRP.SetPendingInstance then
                TDMRP.SetPendingInstance(ply, weaponData.class, inst)
                print(string.format("[TDMRP Spawn] >> Set pending instance with bind_until=%.1f", newRemaining))
            end
            
            -- Give weapon back - this will trigger Setup() which reads pending instance
            print(string.format("[TDMRP Spawn] >> Giving weapon: %s", weaponData.class))
            local wep = ply:Give(weaponData.class)
            
            if IsValid(wep) then
                print(string.format("[TDMRP Spawn] >> Successfully gave weapon, entity: %d", wep:EntIndex()))
                print(string.format("[TDMRP Spawn] >> Player has weapon after Give: %s", ply:HasWeapon(weaponData.class) and "YES" or "NO"))
                
                -- CRITICAL: Attach instance to weapon entity so future collection can find it
                wep.TDMRP_Instance = inst
                wep.TDMRP_InstanceID = inst.id
                
                -- ENSURE CRAFTED FLAG IS SET if this weapon has a bind timer
                -- This allows HUD fallback logic to work after respawn
                if inst.bound_until and inst.bound_until > 0 then
                    wep:SetNWBool("TDMRP_Crafted", true)
                    print(string.format("[TDMRP Spawn] >> Set TDMRP_Crafted=true for bound weapon"))
                end
                
                -- Apply instance to weapon to ensure all data is synchronized
                -- (mixin's Setup() already applied tier, this ensures bind timer is set on NWFloats)
                if TDMRP.ApplyInstanceToSWEP then
                    print(string.format("[TDMRP Spawn] >> Applying instance to weapon"))
                    TDMRP.ApplyInstanceToSWEP(wep, inst)
                    
                    -- Force network variable sync to ensure client receives bind timer immediately
                    -- This prevents HUD from reading 0 before the NWFloat synchronizes
                    wep:CallOnRemove("TDMRP_BindTimerSync", function() end)  -- Force entity net update
                    
                    -- Additionally, if binding exists, verify it was applied correctly
                    if inst.bound_until and inst.bound_until > 0 then
                        local verifybindExpire = wep:GetNWFloat("TDMRP_BindExpire", 0)
                        local verifyRemaining = wep:GetNWFloat("TDMRP_BindRemaining", 0)
                        if verifybindExpire == 0 or verifyRemaining == 0 then
                            print(string.format("[TDMRP SPAWN WARNING] Bind timer not applied correctly: expire=%f, remaining=%f", verifybindExpire, verifyRemaining))
                        else
                            print(string.format("[TDMRP SPAWN] Verified bind timer: %.1f seconds remaining", verifyRemaining))
                        end
                    end
                end
                
                -- UPDATE TestBindWeapons with NEW weapon entity's EntIndex
                -- This ensures craft data can be found on next death collection
                if inst.craft and (inst.craft.prefixId ~= "" or inst.craft.suffixId ~= "" or inst.craft.crafted) then
                    local sid = ply:SteamID64()
                    TDMRP.TestBindWeapons = TDMRP.TestBindWeapons or {}
                    TDMRP.TestBindWeapons[sid] = {
                        entID = wep:EntIndex(),
                        expireTime = CurTime() + newRemaining,
                        class = wep:GetClass(),
                        prefixId = inst.craft.prefixId or "",
                        suffixId = inst.craft.suffixId or "",
                        material = inst.craft.material or "",  -- CRITICAL: Preserve suffix material through respawns
                        customName = inst.cosmetic.name or "",  -- CRITICAL: Preserve custom name through respawns
                        crafted = true,  -- Always true for weapons with modifiers
                    }
                    print(string.format("[TDMRP] Updated TestBindWeapons for crafted weapon: entID=%d (prefix=%s, suffix=%s, material=%s)", 
                        wep:EntIndex(), inst.craft.prefixId or "none", inst.craft.suffixId or "none", inst.craft.material or "none"))
                end
                
                print(string.format("[TDMRP Spawn] >> Player has weapon after ApplyInstance: %s", ply:HasWeapon(weaponData.class) and "YES" or "NO"))
                
                -- Format time for message
                local mins = math.floor(newRemaining / 60)
                local secs = math.floor(newRemaining % 60)
                local timeStr = string.format("%02d:%02d", mins, secs)
                
                ply:ChatPrint(string.format("[TDMRP] Bound %s restored! (-30s penalty, %s remaining)", 
                    weaponData.displayName, timeStr))
                
                print(string.format("[TDMRP Spawn] Restored bound weapon: %s (%.0fs remaining)", wep:GetClass(), newRemaining))
            else
                print(string.format("[TDMRP Spawn] >> FAILED to give weapon: %s (wep not valid)", weaponData.class))
            end
        else
            -- Binding expired from penalty
            print(string.format("[TDMRP Spawn] >> Binding expired: %s", weaponData.class))
            ply:ChatPrint(string.format("[TDMRP] Your %s binding expired due to the respawn penalty.", weaponData.displayName))
        end
    end
    
    -- Final check
    print(string.format("[TDMRP Spawn] Final weapon count for %s: %d weapons", ply:Nick(), #ply:GetWeapons()))
end

----------------------------------------------------
-- Helper: Check if player needs loadout menu
----------------------------------------------------

local function NeedsLoadoutMenu(ply)
    -- Only combat classes get loadout menu
    if not IsCombatClass(ply) then
        print("[TDMRP Spawn] NeedsLoadoutMenu: not a combat class for ", ply:Nick())
        return false
    end
    
    -- Check if loadout pools exist for this job
    local job = GetPlayerJob(ply)
    if not job then return false end
    
    local poolKey = GetPoolKeyFromJob(job)
    local pools = TDMRP.LoadoutPools and TDMRP.LoadoutPools[poolKey]
    if not pools then
        local available = {}
        if TDMRP.LoadoutPools then
            for k,_ in pairs(TDMRP.LoadoutPools) do table.insert(available, k) end
        end
        print(string.format("[TDMRP Spawn] NeedsLoadoutMenu: no pools for job '%s' (player %s). poolKey='%s' Available pool keys: %s",
            tostring(job.name), ply:Nick(), tostring(poolKey), table.concat(available, ", "))) 
    end
    return pools ~= nil
end

----------------------------------------------------
-- Core: Apply job stats (HP, AP, DT, movement)
----------------------------------------------------

function TDMRP.Spawn.ApplyJobStats(ply)
    if not IsValid(ply) then return end
    
    local job = GetPlayerJob(ply)
    if not job then return end
    
    -- Apply HP
    local maxHP = job.tdmrp_hp or 100
    ply:SetMaxHealth(maxHP)
    ply:SetHealth(maxHP)
    
    -- Apply Armor (AP)
    local armor = job.tdmrp_ap or 0
    ply:SetArmor(armor)
    
    -- Apply DT (Damage Threshold) via NWInt
    local dt = job.tdmrp_dt or 0
    local dtName = job.tdmrp_dt_name or "None"
    ply:SetNWInt("TDMRP_JobDT", dt)
    ply:SetNWString("TDMRP_DTName", dtName)
    
    -- Apply movement modifiers
    local walkSpeed = job.tdmrp_walk_speed or 390
    local runSpeed = job.tdmrp_run_speed or 540
    local jumpPower = job.tdmrp_jump_power or 160
    
    ply:SetWalkSpeed(walkSpeed)
    ply:SetRunSpeed(runSpeed)
    ply:SetJumpPower(jumpPower)
    ply:SetSlowWalkSpeed(walkSpeed * 0.8)
    ply:SetCrouchedWalkSpeed(0.6)
    
    -- Apply transparency for Recon
    if job.tdmrp_transparency then
        ply:SetRenderMode(RENDERMODE_TRANSALPHA)
        ply:SetColor(Color(255, 255, 255, job.tdmrp_transparency))
    else
        ply:SetRenderMode(RENDERMODE_NORMAL)
        ply:SetColor(Color(255, 255, 255, 255))
    end
    
    print(string.format("[TDMRP Spawn] Applied stats for %s: HP=%d AP=%d DT=%d (%s) Walk=%d Run=%d Jump=%d",
        ply:Nick(), maxHP, armor, dt, dtName, walkSpeed, runSpeed, jumpPower))
end

----------------------------------------------------
-- Core: Give combat role spawn ammo (5x of all ammo types)
-- Only for cop and criminal classes
----------------------------------------------------

function TDMRP.Spawn.GiveCombatAmmo(ply)
    if not IsValid(ply) then return end
    
    -- Only for combat roles
    if not IsCombatClass(ply) then return end
    
    -- Ammo types and amounts (5x multiplier)
    -- These match the F4 ammo shop types
    local ammoGrants = {
        { type = "SMG1",     amount = 60 * 5 },   -- Rifle/SMG ammo
        { type = "AR2",      amount = 60 * 5 },   -- AR-type ammo
        { type = "Pistol",   amount = 60 * 5 },   -- Pistol ammo
        { type = "Buckshot", amount = 32 * 5 },   -- Shotgun ammo
        { type = "XBowBolt", amount = 15 * 5 },   -- Projectile/Crossbow ammo (knife ammo)
    }
    
    for _, grant in ipairs(ammoGrants) do
        local given = ply:GiveAmmo(grant.amount, grant.type, true)
        if given > 0 then
            -- Silent success
        end
    end
    
    print(string.format("[TDMRP Spawn] Gave combat ammo to %s (5x all types)", ply:Nick()))
end

----------------------------------------------------
-- Core: Give loadout weapons
----------------------------------------------------

function TDMRP.Spawn.GiveLoadout(ply, primaryChoice, secondaryChoice, gearChoice)
    if not IsValid(ply) then return end
    
    local job = GetPlayerJob(ply)
    if not job then return end
    
    -- Get loadout pools for this job (use normalized pool key)
    local poolKey = GetPoolKeyFromJob(job)
    local pools = TDMRP.LoadoutPools and TDMRP.LoadoutPools[poolKey]
    
    if not pools then
        -- No pools defined, use legacy system
        if TDMRP.JobLoadouts and TDMRP.JobLoadouts[job.name] then
            local legacyLoadout = TDMRP.JobLoadouts[job.name]
            
            -- Give legacy weapons
            if legacyLoadout.primary then
                local wep = ply:Give(legacyLoadout.primary)
                if IsValid(wep) then
                    print("[TDMRP Spawn] Gave legacy primary: " .. legacyLoadout.primary)
                end
            end
            if legacyLoadout.sidearm then
                local wep = ply:Give(legacyLoadout.sidearm)
                if IsValid(wep) then
                    print("[TDMRP Spawn] Gave legacy secondary: " .. legacyLoadout.sidearm)
                end
            end
        end
        return
    end
    
    -- Get selections (use defaults if not specified)
    local primaryWeapon = nil
    local secondaryWeapon = nil
    local gearItem = nil
    
    -- Get bound weapon classes to skip conflicts
    local sid = ply:SteamID64()
    local boundWeapons = TDMRP.Spawn.PendingBoundWeapons[sid] or {}
    local boundClasses = {}
    for _, bw in ipairs(boundWeapons) do
        boundClasses[bw.class] = true
    end
    
    -- Primary selection (skip if player has bound primary)
    if pools.Primary and #pools.Primary > 0 then
        local idx = primaryChoice or 1
        idx = math.Clamp(idx, 1, #pools.Primary)
        primaryWeapon = pools.Primary[idx]
        
        -- Don't give if player has a bound weapon of same class
        if boundClasses[primaryWeapon] then
            print("[TDMRP Spawn] Skipping primary " .. primaryWeapon .. " - player has bound weapon of same class")
            primaryWeapon = nil
        end
    end
    
    -- Secondary selection (skip if player has bound secondary)
    if pools.Secondary and #pools.Secondary > 0 then
        local idx = secondaryChoice or 1
        idx = math.Clamp(idx, 1, #pools.Secondary)
        secondaryWeapon = pools.Secondary[idx]
        
        -- Don't give if player has a bound weapon of same class
        if boundClasses[secondaryWeapon] then
            print("[TDMRP Spawn] Skipping secondary " .. secondaryWeapon .. " - player has bound weapon of same class")
            secondaryWeapon = nil
        end
    end
    
    -- Gear selection
    if pools.Gear and #pools.Gear > 0 then
        local idx = gearChoice or 1
        idx = math.Clamp(idx, 1, #pools.Gear)
        gearItem = pools.Gear[idx]
    end
    
    -- Give primary weapon
    if primaryWeapon then
        local weaponClass = primaryWeapon
        
        -- Use TDMRP instance system if available
        if TDMRP.NewWeaponInstance and TDMRP.SetPendingInstance then
            local inst = TDMRP.NewWeaponInstance(weaponClass, 1) -- Common tier for loadout
            if inst then
                TDMRP.SetPendingInstance(ply, weaponClass, inst)
            end
        end
        
        local wep = ply:Give(weaponClass)
        if IsValid(wep) then
            print("[TDMRP Spawn] Gave primary: " .. weaponClass)
        end
    end
    
    -- Give secondary weapon
    if secondaryWeapon then
        local weaponClass = secondaryWeapon
        
        if TDMRP.NewWeaponInstance and TDMRP.SetPendingInstance then
            local inst = TDMRP.NewWeaponInstance(weaponClass, 1)
            if inst then
                TDMRP.SetPendingInstance(ply, weaponClass, inst)
            end
        end
        
        local wep = ply:Give(weaponClass)
        if IsValid(wep) then
            print("[TDMRP Spawn] Gave secondary: " .. weaponClass)
        end
    end
    
    -- Give gear item
    if gearItem then
        local itemClass = gearItem
        local wep = ply:Give(itemClass)
        if IsValid(wep) then
            print("[TDMRP Spawn] Gave gear: " .. itemClass)
        end
    end
    
    -- Store selections for persistence (use poolKey)
    TDMRP.Spawn.SaveLoadoutChoices(ply, poolKey or job.name, primaryChoice or 1, secondaryChoice or 1, gearChoice or 1)
end

----------------------------------------------------
-- Loadout Persistence
----------------------------------------------------

local LOADOUT_DIR = "tdmrp/loadouts"

local function EnsureLoadoutDir()
    if not file.IsDir("tdmrp", "DATA") then
        file.CreateDir("tdmrp")
    end
    if not file.IsDir(LOADOUT_DIR, "DATA") then
        file.CreateDir(LOADOUT_DIR)
    end
end

EnsureLoadoutDir()

function TDMRP.Spawn.SaveLoadoutChoices(ply, jobName, primary, secondary, gear)
    if not IsValid(ply) or not ply.SteamID64 then return end

    local sid = ply:SteamID64()
    local poolKey = NormalizePoolKey(jobName)
    local path = LOADOUT_DIR .. "/" .. sid .. ".txt"
    
    -- Load existing data
    local data = {}
    if file.Exists(path, "DATA") then
        local raw = file.Read(path, "DATA")
        if raw and raw ~= "" then
            data = util.JSONToTable(raw) or {}
        end
    end
    
    -- Update for this job (use normalized pool key)
    data[poolKey] = {
        primary = primary,
        secondary = secondary,
        gear = gear,
    }
    
    -- Save
    file.Write(path, util.TableToJSON(data, true))
end

function TDMRP.Spawn.GetLoadoutChoices(ply, jobName)
    if not IsValid(ply) or not ply.SteamID64 then return nil end

    local sid = ply:SteamID64()
    local poolKey = NormalizePoolKey(jobName)
    local path = LOADOUT_DIR .. "/" .. sid .. ".txt"
    
    if not file.Exists(path, "DATA") then return nil end
    
    local raw = file.Read(path, "DATA")
    if not raw or raw == "" then return nil end
    
    local data = util.JSONToTable(raw)
    if not data then return nil end
    
    return data[poolKey]
end

----------------------------------------------------
-- Core: Complete spawn process
----------------------------------------------------

function TDMRP.Spawn.CompleteSpawn(ply, primaryChoice, secondaryChoice, gearChoice, bypassLoadout)
    if not IsValid(ply) then return end
    
    local sid = ply:SteamID64()
    
    -- Unfreeze player
    if CONFIG.FREEZE_DURING_LOADOUT then
        ply:Freeze(false)
    end
    
    -- Apply job stats
    TDMRP.Spawn.ApplyJobStats(ply)
    
    -- Give combat ammo (5x all types for cop/criminal)
    TDMRP.Spawn.GiveCombatAmmo(ply)
    
    -- Give loadout weapons (unless bypassing)
    if not bypassLoadout then
        TDMRP.Spawn.GiveLoadout(ply, primaryChoice, secondaryChoice, gearChoice)
    else
        print("[TDMRP Spawn] Loadout bypassed for " .. ply:Nick() .. " - spawning with bound weapons only")
    end
    
    -- Restore bound weapons AFTER loadout (so they override any conflicts)
    local boundWeapons = TDMRP.Spawn.PendingBoundWeapons[sid]
    if boundWeapons and #boundWeapons > 0 then
        RestoreBoundWeapons(ply, boundWeapons, 30)  -- 30 second penalty
    end
    
    -- Clear pending data
    TDMRP.Spawn.PendingSpawns[sid] = nil
    TDMRP.Spawn.PendingBoundWeapons[sid] = nil
    timer.Remove("TDMRP_LoadoutTimeout_" .. sid)
    
    -- Apply XP buffs if applicable
    if TDMRP.XP and TDMRP.XP.ApplyLevelBuffs then
        TDMRP.XP.ApplyLevelBuffs(ply)
    end
    
    -- Notify client spawn is complete
    net.Start("TDMRP_SpawnComplete")
    net.Send(ply)
    
    print("[TDMRP Spawn] Spawn complete for " .. ply:Nick())
end

----------------------------------------------------
-- Net: Loadout Confirmed from client
----------------------------------------------------

net.Receive("TDMRP_LoadoutConfirmed", function(len, ply)
    if not IsValid(ply) then return end
    
    local sid = ply:SteamID64()
    if not TDMRP.Spawn.PendingSpawns[sid] then
        -- Not pending, ignore
        return
    end
    
    -- Read weapon classes sent by client
    local primaryClass = net.ReadString()
    local secondaryClass = net.ReadString()
    local gearClass = net.ReadString()
    
    print(string.format("[TDMRP Spawn] Received loadout from %s: %s, %s, %s", ply:Nick(), primaryClass, secondaryClass, gearClass))
    
    -- Find indices for persistence
    local job = GetPlayerJob(ply)
    local poolKey = job and GetPoolKeyFromJob(job)
    local pools = job and TDMRP.LoadoutPools and TDMRP.LoadoutPools[poolKey]
    
    local primaryIdx = 1
    local secondaryIdx = 1
    local gearIdx = 1
    
    if pools then
        -- Find index of chosen weapons in pools
        for i, wep in ipairs(pools.Primary or {}) do
            if wep == primaryClass then
                primaryIdx = i
                break
            end
        end
        for i, wep in ipairs(pools.Secondary or {}) do
            if wep == secondaryClass then
                secondaryIdx = i
                break
            end
        end
        for i, wep in ipairs(pools.Gear or {}) do
            if wep == gearClass then
                gearIdx = i
                break
            end
        end
    end
    
    -- Complete spawn with selections (not bypassing)
    TDMRP.Spawn.CompleteSpawn(ply, primaryIdx, secondaryIdx, gearIdx, false)
end)

----------------------------------------------------
-- Net: Loadout Bypass from client (spawn with bound weapons only)
----------------------------------------------------

net.Receive("TDMRP_LoadoutBypass", function(len, ply)
    if not IsValid(ply) then return end
    
    local sid = ply:SteamID64()
    if not TDMRP.Spawn.PendingSpawns[sid] then
        -- Not pending, ignore
        return
    end
    
    print(string.format("[TDMRP Spawn] %s bypassed loadout - spawning with bound weapons only", ply:Nick()))
    
    -- Complete spawn with bypass flag (no loadout weapons)
    TDMRP.Spawn.CompleteSpawn(ply, nil, nil, nil, true)
end)

----------------------------------------------------
-- Timeout handler
----------------------------------------------------

local function HandleLoadoutTimeout(ply)
    if not IsValid(ply) then return end
    
    local sid = ply:SteamID64()
    if not TDMRP.Spawn.PendingSpawns[sid] then return end
    
    -- Get saved choices or use defaults
    local job = GetPlayerJob(ply)
    local choices = job and TDMRP.Spawn.GetLoadoutChoices(ply, job.name)
    
    local primary = choices and choices.primary or 1
    local secondary = choices and choices.secondary or 1
    local gear = choices and choices.gear or 1
    
    -- Notify client of timeout
    net.Start("TDMRP_LoadoutTimeout")
    net.Send(ply)
    
    -- Complete spawn with defaults/saved choices
    TDMRP.Spawn.CompleteSpawn(ply, primary, secondary, gear)
end

----------------------------------------------------
-- Main Spawn Handler
----------------------------------------------------

local function OnPlayerSpawn(ply)
    if not IsValid(ply) then return end
    
    -- Skip if spectator or unassigned
    if ply:Team() == TEAM_SPECTATOR or ply:Team() == TEAM_UNASSIGNED then
        return
    end
    
    local job = GetPlayerJob(ply)
    local jobClass = job and job.tdmrp_class or "civilian"
    local sid = ply:SteamID64()
    
    print(string.format("[TDMRP Spawn] OnPlayerSpawn for %s - job=%s, jobClass=%s, sid=%s", ply:Nick(), job and job.name or "nil", jobClass, sid))
    
    -- For non-combat classes, get default DarkRP loadout, then restore bound weapons
    if jobClass == "civilian" then
        print(string.format("[TDMRP Spawn] Treating %s as civilian", ply:Nick()))
        TDMRP.Spawn.ApplyJobStats(ply)
        
        -- Strip any UNBOUND TDMRP weapons from civilians (they should only have DarkRP tools)
        -- Keep bound weapons for restoration
        for _, wep in ipairs(ply:GetWeapons()) do
            if IsValid(wep) and TDMRP.IsM9KWeapon and TDMRP.IsM9KWeapon(wep) then
                local expireTime = wep:GetNWFloat("TDMRP_BindExpire", 0)
                local isBound = expireTime > CurTime()
                
                -- Also check instance binding
                if not isBound and wep.TDMRP_Instance and wep.TDMRP_Instance.bound_until then
                    isBound = wep.TDMRP_Instance.bound_until > 0
                end
                
                -- Check test bind storage
                if not isBound then
                    local testBindInfo = TDMRP.TestBindWeapons and TDMRP.TestBindWeapons[sid]
                    if testBindInfo and testBindInfo.entID == wep:EntIndex() and testBindInfo.expireTime > CurTime() then
                        isBound = true
                    end
                end
                
                if not isBound then
                    print(string.format("[TDMRP Spawn] Stripping UNBOUND TDMRP weapon from civilian: %s", wep:GetClass()))
                    ply:StripWeapon(wep:GetClass())
                else
                    print(string.format("[TDMRP Spawn] Keeping bound TDMRP weapon on civilian: %s", wep:GetClass()))
                end
            end
        end
        
        -- Let DarkRP give default civilian loadout
        -- PlayerLoadout hook will be called to give standard weapons
        -- We just need to restore bound weapons AFTER that happens
        
        -- Schedule bound weapon restoration AFTER PlayerLoadout is called
        timer.Simple(0.5, function()
            if not IsValid(ply) then return end
            
            local boundWeapons = TDMRP.Spawn.PendingBoundWeapons[sid]
            print(string.format("[TDMRP Spawn] Checking bound weapons for %s (delayed): %s", ply:Nick(), boundWeapons and #boundWeapons or "nil"))
            if boundWeapons and #boundWeapons > 0 then
                RestoreBoundWeapons(ply, boundWeapons, 30)  -- 30 second penalty
                TDMRP.Spawn.PendingBoundWeapons[sid] = nil
                print(string.format("[TDMRP Spawn] Restored %d bound weapons for civilian %s", #boundWeapons, ply:Nick()))
            end
        end)
        return
    end
    
    print(string.format("[TDMRP Spawn] Not civilian (%s), continuing with loadout menu check", jobClass))
    
    -- Check if needs loadout menu
    if NeedsLoadoutMenu(ply) then
        
        -- Mark as pending
        TDMRP.Spawn.PendingSpawns[sid] = {
            startTime = CurTime(),
            jobName = job.name,
        }
        
        -- Freeze player during selection
        if CONFIG.FREEZE_DURING_LOADOUT then
            ply:Freeze(true)
        end
        
        -- Get loadout pools for this job
        local poolKey = GetPoolKeyFromJob(job)
        local pools = TDMRP.LoadoutPools and TDMRP.LoadoutPools[poolKey]
        if not pools then
            print("[TDMRP Spawn] ERROR: No loadout pools for " .. tostring(job.name) .. " (poolKey=" .. tostring(poolKey) .. ")")
            TDMRP.Spawn.CompleteSpawn(ply, 1, 1, 1)
            return
        end
        
        -- Get saved choices for this job
        local savedChoices = TDMRP.Spawn.GetLoadoutChoices(ply, poolKey)
        
        -- Get bound weapons for this player (saved on death)
        local boundWeapons = TDMRP.Spawn.PendingBoundWeapons[sid] or {}
        local boundClasses = {}
        local boundWeaponData = {}
        for _, bw in ipairs(boundWeapons) do
            boundClasses[bw.class] = true
            table.insert(boundWeaponData, {
                class = bw.class,
                displayName = bw.displayName or bw.class,
                remaining = bw.remaining,
            })
        end
        
        -- Send loadout menu to client with weapon class arrays, saved selections, and bound weapons
        net.Start("TDMRP_ShowLoadoutMenu")
            net.WriteTable(pools.Primary or {})
            net.WriteTable(pools.Secondary or {})
            net.WriteTable(pools.Gear or {})
            net.WriteUInt(savedChoices and savedChoices.primary or 0, 8) -- 0 = no saved choice
            net.WriteUInt(savedChoices and savedChoices.secondary or 0, 8)
            net.WriteUInt(savedChoices and savedChoices.gear or 0, 8)
            net.WriteTable(boundWeaponData)  -- Send bound weapon info for UI
        net.Send(ply)
        
        -- Set timeout
        timer.Create("TDMRP_LoadoutTimeout_" .. sid, CONFIG.LOADOUT_TIMEOUT, 1, function()
            HandleLoadoutTimeout(ply)
        end)
        
        print("[TDMRP Spawn] Showing loadout menu for " .. ply:Nick() .. " (" .. job.name .. ")")
    else
        -- No loadout menu needed, complete spawn immediately
        timer.Simple(CONFIG.SPAWN_DELAY, function()
            if IsValid(ply) then
                TDMRP.Spawn.CompleteSpawn(ply, 1, 1, 1)
            end
        end)
    end
end

----------------------------------------------------
-- Hooks
----------------------------------------------------

-- Override existing spawn hooks
hook.Add("PlayerSpawn", "TDMRP_SpawnOrchestrator", function(ply)
    -- Small delay to let DarkRP finish setting job
    timer.Simple(CONFIG.SPAWN_DELAY, function()
        if IsValid(ply) then
            OnPlayerSpawn(ply)
        end
    end)
end)

-- Block default DarkRP loadout for combat classes
hook.Add("PlayerLoadout", "TDMRP_BlockDefaultLoadout", function(ply)
    if IsCombatClass(ply) then
        return true -- Block default weapons
    end
end)

-- Clean up on disconnect
hook.Add("PlayerDisconnected", "TDMRP_SpawnCleanup", function(ply)
    if not IsValid(ply) or not ply.SteamID64 then return end
    
    local sid = ply:SteamID64()
    TDMRP.Spawn.PendingSpawns[sid] = nil
    timer.Remove("TDMRP_LoadoutTimeout_" .. sid)
end)

-- Mark bound weapons as protected BEFORE other death hooks (high priority)
hook.Add("PlayerSpawn", "TDMRP_MarkBoundWeaponsOnSpawn", function(ply)
    if not IsValid(ply) then return end
    timer.Simple(0.1, function()
        if IsValid(ply) then
            for _, wep in ipairs(ply:GetWeapons()) do
                if IsValid(wep) then
                    local expireTime = wep:GetNWFloat("TDMRP_BindExpire", 0)
                    if expireTime > 0 and (expireTime - CurTime()) > 0 then
                        print(string.format("[TDMRP] Bound weapon %s preserved: %.1f seconds", wep:GetClass(), expireTime - CurTime()))
                    end
                end
            end
        end
    end)
end)

-- Save bound weapons on death (for restore after loadout)
-- Bound weapons naturally stay in player inventory, so we just collect them
-- HIGH priority so this runs BEFORE PlayerSpawn hooks
hook.Add("PlayerDeath", "TDMRP_SpawnSaveBoundWeapons", function(ply)
    if not IsValid(ply) or not ply.SteamID64 then return end
    
    local sid = ply:SteamID64()
    
    -- Collect bound weapons for ANY class (including civilians)
    local boundWeapons = CollectBoundWeapons(ply)
    
    if #boundWeapons > 0 then
        TDMRP.Spawn.PendingBoundWeapons[sid] = boundWeapons
        print(string.format("[TDMRP Spawn] DEATH HOOK: Collected %d bound weapons for %s", #boundWeapons, ply:Nick()))
    else
        print(string.format("[TDMRP Spawn] DEATH HOOK: No bound weapons to collect for %s", ply:Nick()))
    end
    
    -- Cancel any pending loadout if player dies during selection
    if TDMRP.Spawn.PendingSpawns[sid] then
        TDMRP.Spawn.PendingSpawns[sid] = nil
        timer.Remove("TDMRP_LoadoutTimeout_" .. sid)
        ply:Freeze(false)
    end
end, 999)  -- HIGH PRIORITY: 999 ensures this runs first

-- Prevent noclip during loadout selection
hook.Add("PlayerNoClip", "TDMRP_SpawnBlockNoclip", function(ply, desiredState)
    if not IsValid(ply) or not ply.SteamID64 then return end
    
    local sid = ply:SteamID64()
    if TDMRP.Spawn.PendingSpawns[sid] then
        -- Block noclip during loadout
        return false
    end
end)

-- Block movement during loadout selection
hook.Add("SetupMove", "TDMRP_SpawnBlockMovement", function(ply, mv, cmd)
    if not IsValid(ply) or not ply.SteamID64 then return end
    
    local sid = ply:SteamID64()
    if TDMRP.Spawn.PendingSpawns[sid] then
        -- Zero out all movement
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
        mv:SetButtons(0)
    end
end)

print("[TDMRP] sv_tdmrp_spawn_orchestrator.lua loaded (central spawn coordinator)")
