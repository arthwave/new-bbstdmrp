-- sh_tdmrp_instances.lua
-- Shared helpers for per-weapon "instances" (server + client aware)
-- Updated for new TDMRP SWEP architecture

if SERVER then
    AddCSLuaFile()
end

TDMRP = TDMRP or {}
TDMRP.Instances = TDMRP.Instances or {}

----------------------------------------
-- ID generator
----------------------------------------
local function GenerateInstanceID(ply, class)
    local sid = "world"
    if IsValid(ply) and ply:IsPlayer() then
        sid = ply:SteamID64() or ply:SteamID() or "unknown"
    end

    class = class or "unknown"

    -- Cheap unique-ish ID: STEAM + class + time + random
    return string.format("%s_%s_%d_%d", sid, class, os.time(), math.random(0, 99999))
end

----------------------------------------
-- Build instance from a SWEP (for storing in inventory)
-- Works with both old NWInt-based weapons and new TDMRP derived SWEPs
----------------------------------------

-- Instance version for future migrations
local INSTANCE_VERSION = 1

function TDMRP_BuildInstanceFromSWEP(ply, wep)
    if not IsValid(wep) or not wep:IsWeapon() then return nil end

    local class = wep:GetClass()
    if not class or class == "" then return nil end

    local inst = {}
    
    -- Version tracking for future migrations
    inst.version = INSTANCE_VERSION

    -- Preserve existing instance ID if one is already attached
    local existingID = wep.TDMRP_InstanceID
    if isstring(existingID) and existingID ~= "" then
        inst.id = existingID
    else
        inst.id = GenerateInstanceID(ply, class)
    end
    wep.TDMRP_InstanceID = inst.id

    inst.class = class
    inst.owner_steamid = (IsValid(ply) and (ply:SteamID64() or ply:SteamID())) or nil

    -- Get tier from SWEP property (new system) or NWInt (legacy)
    local tierSource = "default"
    if wep.Tier then
        inst.tier = wep.Tier
        tierSource = "wep.Tier"
    elseif wep.GetTier then
        inst.tier = wep:GetTier()
        tierSource = "wep:GetTier()"
    else
        inst.tier = wep:GetNWInt("TDMRP_Tier", 1)
        tierSource = "NWInt"
    end
    
    if SERVER then
        print(string.format("[TDMRP] BuildInstanceFromSWEP tier: %d (source: %s, wep.Tier=%s, NWInt=%d)", 
            inst.tier, tierSource, tostring(wep.Tier), wep:GetNWInt("TDMRP_Tier", 1)))
    end

    -- Get stats - prefer direct Primary table (new system) then NWInts (legacy)
    local primary = wep.Primary or {}
    inst.stats = {
        damage   = primary.Damage or wep:GetNWInt("TDMRP_Damage", 20),
        rpm      = primary.RPM or wep:GetNWInt("TDMRP_RPM", 600),
        accuracy = wep:GetNWInt("TDMRP_Accuracy", 60),
        recoil   = wep:GetNWInt("TDMRP_Recoil", 25),
        handling = wep:GetNWInt("TDMRP_Handling", 100),
    }
    
    -- Calculate accuracy from spread if not in NWInt
    if primary.Spread and inst.stats.accuracy == 60 then
        inst.stats.accuracy = math.Clamp(100 - (primary.Spread or 0.03) * 1000, 0, 100)
    end
    
    -- Calculate recoil from kick values if not in NWInt  
    if primary.KickUp and inst.stats.recoil == 25 then
        inst.stats.recoil = math.Clamp(primary.KickUp * 50, 0, 100)
    end
    
    if SERVER then
        print(string.format("[TDMRP] BuildInstanceFromSWEP: %s T%d Dmg=%d RPM=%d Acc=%.1f",
            class, inst.tier or 1, inst.stats.damage or 0, inst.stats.rpm or 0, inst.stats.accuracy or 0))
    end

    inst.cosmetic = {
        name     = wep:GetNWString("TDMRP_CustomName", "") ~= "" and wep:GetNWString("TDMRP_CustomName", "") or (wep.TDMRP_CustomName or ""),
        material = wep:GetNWString("TDMRP_Material", ""),
    }
    
    if SERVER and inst.cosmetic.name ~= "" then
        print(string.format("[TDMRP] BuildInstanceFromSWEP: Captured custom name '%s' on weapon %s (NWString or entity fallback)", inst.cosmetic.name, class))
    end

    -- Capture bind time - CRITICAL: Store as REMAINING SECONDS for JSON persistence
    -- This FREEZES bind time while in inventory - timer only decays when weapon is equipped
    -- When retrieving from inventory, we use the stored remaining seconds directly
    local bindExpire = wep:GetNWFloat("TDMRP_BindExpire", 0)
    if bindExpire > 0 then
        local remaining = bindExpire - CurTime()
        if remaining > 0 then
            -- Store as REMAINING SECONDS (not absolute timestamp)
            -- This freezes the timer while in inventory
            inst.bound_until = remaining
            if SERVER then
                print(string.format("[TDMRP] BuildInstanceFromSWEP: Weapon is bound, %.1f seconds remaining (stored as relative)", remaining))
            end
        else
            inst.bound_until = 0
        end
    else
        local legacyBound = wep:GetNWFloat("TDMRP_BindUntil", 0)
        -- Legacy value is already relative time, use as-is
        if legacyBound > 0 then
            inst.bound_until = legacyBound
        else
            inst.bound_until = 0
        end
    end

    inst.craft = {
        crafted  = wep:GetNWBool("TDMRP_Crafted", false),
        prefixId = wep:GetNWString("TDMRP_PrefixID", ""),
        suffixId = wep:GetNWString("TDMRP_SuffixID", ""),
        -- CRITICAL: Read material from entity property (not NWString which is unreliable on server)
        -- Entity property is set during crafting and persists on the weapon entity
        material = wep.TDMRP_StoredMaterial or wep:GetNWString("TDMRP_Material", ""),
        -- Store the actual stat values AFTER prefix/suffix were applied so they persist
        -- These represent what the weapon stats were at crafting time
        appliedStats = {
            damage   = inst.stats.damage,
            rpm      = inst.stats.rpm,
            accuracy = inst.stats.accuracy,
            recoil   = inst.stats.recoil,
            handling = inst.stats.handling,
        },
        -- Store prefix/suffix stat modifiers so they persist through inventory
        prefixStats = wep.TDMRP_PrefixStats or nil,
        suffixStats = wep.TDMRP_SuffixStats or nil,
    }
    
    if SERVER and (inst.craft.prefixId ~= "" or inst.craft.suffixId ~= "") then
        print(string.format("[TDMRP Build] craft data: crafted=%s, prefix=%s, suffix=%s, material=%s (entity_prop=%s, NWStr=%s)", 
            tostring(inst.craft.crafted), inst.craft.prefixId, inst.craft.suffixId, inst.craft.material or "nil",
            wep.TDMRP_StoredMaterial or "nil", wep:GetNWString("TDMRP_Material", "") or "nil"))
    end

    -- Store gems if present
    inst.gems = {
        sapphire = wep:GetNWInt("TDMRP_Gem_Sapphire", 0),
        emerald  = wep:GetNWInt("TDMRP_Gem_Emerald", 0),
        ruby     = wep:GetNWInt("TDMRP_Gem_Ruby", 0),
        diamond  = wep:GetNWInt("TDMRP_Gem_Diamond", 0),
    }

    TDMRP.Instances[inst.id] = inst
    return inst
end

----------------------------------------
-- Apply instance -> SWEP
-- Works with both new TDMRP derived SWEPs and legacy NWInt system
----------------------------------------
function TDMRP.ApplyInstanceToSWEP(wep, inst)
    if not IsValid(wep) or not inst then return end

    wep.TDMRP_InstanceID = inst.id

    -- Check if this is a new tdmrp_m9k_* weapon with mixin
    local class = wep:GetClass()
    local isNewSystem = string.StartWith(class, "tdmrp_m9k_") and wep.Tier ~= nil
    
    if isNewSystem and SERVER then
        -- New system: set tier and re-apply mixin to calculate stats from tier
        wep.Tier = inst.tier or 1
        
        -- CRITICAL: Lock the tier so subsequent Equip() calls don't reset it
        wep.TDMRP_TierLocked = true
        
        -- Don't call Setup() - it triggers Initialize which may reset tier
        -- Instead, manually apply tier scaling if base stats are already stored
        if wep.TDMRP_BaseDamage and TDMRP_WeaponMixin then
            if TDMRP_WeaponMixin.ApplyTierScaling then
                TDMRP_WeaponMixin.ApplyTierScaling(wep, wep.Tier)
            end
            if TDMRP_WeaponMixin.SetNetworkedStats then
                TDMRP_WeaponMixin.SetNetworkedStats(wep)
            end
        else
            -- First time, call full Setup to store base stats
            if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
                TDMRP_WeaponMixin.Setup(wep)
            end
        end
        
        -- Gems will be applied by mixin's ApplyGems if needed
        if inst.gems and TDMRP_WeaponMixin.ApplyGems then
            wep:SetNWInt("TDMRP_Gem_Sapphire", inst.gems.sapphire or 0)
            wep:SetNWInt("TDMRP_Gem_Emerald",  inst.gems.emerald or 0)
            wep:SetNWInt("TDMRP_Gem_Ruby",     inst.gems.ruby or 0)
            wep:SetNWInt("TDMRP_Gem_Diamond",  inst.gems.diamond or 0)
            TDMRP_WeaponMixin.ApplyGems(wep)
        end
    else
        -- Legacy system or client-side: use NWInts directly
        -- Set tier via SWEP method (new system) or NWInt (legacy)
        if wep.SetTier then
            wep:SetTier(inst.tier or 1)
        else
            wep:SetNWInt("TDMRP_Tier", inst.tier or 1)
        end

        -- Core stats (NWInts for HUD display)
        if inst.stats then
            wep:SetNWInt("TDMRP_Damage",   inst.stats.damage   or 20)
            wep:SetNWInt("TDMRP_RPM",      inst.stats.rpm      or 600)
            wep:SetNWInt("TDMRP_Accuracy", inst.stats.accuracy or 60)
            wep:SetNWInt("TDMRP_Recoil",   inst.stats.recoil   or 25)
            wep:SetNWInt("TDMRP_Handling", inst.stats.handling or 100)
        end

        -- Apply gems
        if inst.gems then
            wep:SetNWInt("TDMRP_Gem_Sapphire", inst.gems.sapphire or 0)
            wep:SetNWInt("TDMRP_Gem_Emerald",  inst.gems.emerald or 0)
            wep:SetNWInt("TDMRP_Gem_Ruby",     inst.gems.ruby or 0)
            wep:SetNWInt("TDMRP_Gem_Diamond",  inst.gems.diamond or 0)
        end
    end

    -- Cosmetics (both systems)
    if inst.cosmetic then
        wep:SetNWString("TDMRP_CustomName", inst.cosmetic.name or "")
        wep:SetNWString("TDMRP_Material",   inst.cosmetic.material or "")
        
        -- CRITICAL: Also store custom name on the weapon entity itself as fallback
        -- This ensures the name persists even if NWString hasn't synced to client yet
        wep.TDMRP_CustomName = inst.cosmetic.name or ""
        
        -- CRITICAL: Force a network message to client if we have a custom name
        -- This ensures the custom name appears immediately without waiting for NWString sync
        if SERVER and inst.cosmetic.name ~= "" and IsValid(wep:GetOwner()) then
            net.Start("TDMRP_SyncCustomName")
            net.WriteEntity(wep)
            net.WriteString(inst.cosmetic.name)
            net.Send(wep:GetOwner())
            if SERVER then
                print(string.format("[TDMRP] ApplyInstanceToSWEP: Sent network sync for custom name '%s' to owner", inst.cosmetic.name))
            end
        end
        
        if SERVER and inst.cosmetic.name ~= "" then
            print(string.format("[TDMRP] ApplyInstanceToSWEP: Applied custom name '%s' to weapon (stored on entity + NWString + network sync)", inst.cosmetic.name))
        end
    end

    -- Bind time (both systems)
    -- inst.bound_until comes from ItemToInstance which converts absolute -> relative remaining seconds
    -- So inst.bound_until should already be relative time (number of seconds remaining)
    if SERVER and inst.bound_until and inst.bound_until > 0 then
        -- inst.bound_until is already remaining seconds, convert to absolute for NWFloat
        local newExpire = CurTime() + inst.bound_until
        wep:SetNWFloat("TDMRP_BindExpire", newExpire)
        wep:SetNWFloat("TDMRP_BindUntil", inst.bound_until)  -- Legacy compat
        
        -- CRITICAL: Store remaining seconds on weapon for client-side fallback
        wep:SetNWFloat("TDMRP_BindRemaining", inst.bound_until)
        
        print(string.format("[TDMRP] ApplyInstanceToSWEP: Set bind NWFloats - expire=%.1f, remaining=%.1f", newExpire - CurTime(), inst.bound_until))
        
        -- Send explicit bind update to player to ensure client receives it immediately
        -- This bypasses NWFloat sync delays which can cause HUD to show 0 initially
        local owner = wep:GetOwner()
        if IsValid(owner) and owner:IsPlayer() then
            net.Start("TDMRP_BindUpdate")
            net.WriteEntity(wep)
            net.WriteFloat(newExpire)
            net.WriteFloat(inst.bound_until)  -- Also send remaining time
            net.Send(owner)
            print(string.format("[TDMRP] ApplyInstanceToSWEP: SENT bind update network message to %s", owner:Nick()))
        else
            print("[TDMRP] ApplyInstanceToSWEP: WARNING - owner not valid!")
        end
        
        print(string.format("[TDMRP] ApplyInstanceToSWEP: Applied bind timer - %.1f seconds remaining (expires at CurTime %.1f)", inst.bound_until, newExpire - CurTime()))
    else
        wep:SetNWFloat("TDMRP_BindExpire", 0)
        wep:SetNWFloat("TDMRP_BindUntil", 0)
        wep:SetNWFloat("TDMRP_BindRemaining", 0)
    end

    -- Craft meta (prefix/suffix flags) (both systems)
    if inst.craft then
        wep:SetNWBool("TDMRP_Crafted",   inst.craft.crafted or false)
        wep:SetNWString("TDMRP_PrefixID", inst.craft.prefixId or "")
        wep:SetNWString("TDMRP_SuffixID", inst.craft.suffixId or "")
        wep:SetNWString("TDMRP_Material",  inst.craft.material or "")  -- NEW: Restore suffix material
        
        -- CRITICAL: Also store material on the weapon entity itself for fallback
        -- This ensures material persists even if NWString hasn't synchronized to client yet
        wep.TDMRP_StoredMaterial = inst.craft.material or ""
        
        if SERVER then
            print(string.format("[TDMRP Apply] Craft data: crafted=%s, prefix=%s, suffix=%s, material=%s (empty=%s)", 
                tostring(inst.craft.crafted), inst.craft.prefixId or "none", inst.craft.suffixId or "none", 
                inst.craft.material or "none", (inst.craft.material == "" or not inst.craft.material) and "YES" or "NO"))
        end
        
        -- Apply material visually if present (use same pattern as active skills)
        if inst.craft.material and inst.craft.material ~= "" then
            if SERVER then
                print(string.format("[TDMRP Apply] APPLYING MATERIAL: %s", inst.craft.material))
            end
            wep:SetMaterial(inst.craft.material)
            
            -- Also apply to all submaterials
            for i = 0, 31 do
                wep:SetSubMaterial(i, inst.craft.material)
            end
            
            -- If owner has viewmodel, apply there too
            local owner = wep:GetOwner()
            if IsValid(owner) and owner:IsPlayer() then
                local vm = owner:GetViewModel()
                if IsValid(vm) then
                    vm:SetMaterial(inst.craft.material)
                    for i = 0, 31 do
                        vm:SetSubMaterial(i, inst.craft.material)
                    end
                end
            end
            
            if SERVER then
                print(string.format("[TDMRP] ApplyInstanceToSWEP: Applied suffix material from instance: %s (with submaterials)", inst.craft.material))
            end
        end
        
        -- SAFETY: If weapon has prefix or suffix, it should be marked as crafted
        -- This prevents crafted status from being lost due to data corruption
        if (inst.craft.prefixId and inst.craft.prefixId ~= "") or (inst.craft.suffixId and inst.craft.suffixId ~= "") then
            wep:SetNWBool("TDMRP_Crafted", true)
            if SERVER then
                print(string.format("[TDMRP] ApplyInstanceToSWEP: Forced crafted=true due to prefix/suffix presence (prefix=%s, suffix=%s)", 
                    inst.craft.prefixId or "none", inst.craft.suffixId or "none"))
            end
        end
        
        -- CRITICAL: Apply cosmetics FIRST before rebuilding craft display name
        -- This ensures custom names are preserved and not overwritten
        if inst.cosmetic then
            wep:SetNWString("TDMRP_CustomName", inst.cosmetic.name or "")
            wep:SetNWString("TDMRP_Material",   inst.cosmetic.material or "")
        end
        
        -- REBUILD CRAFT NAME from prefix/suffix data (only for display in parentheses under custom name)
        -- This is NOT the same as TDMRP_CustomName - this is just the crafted prefix/base/suffix name
        if (inst.craft.prefixId and inst.craft.prefixId ~= "") or (inst.craft.suffixId and inst.craft.suffixId ~= "") then
            -- Get base weapon name - use print name directly without TitleCase manipulation
            local baseName = wep:GetPrintName() or wep:GetClass()
            
            -- Only clean up class names if we're using the class fallback
            if not wep:GetPrintName() then
                baseName = baseName:gsub("^weapon_", ""):gsub("^tdmrp_m9k_", "")
                local function TitleCase(str)
                    return str:gsub("([^_])([A-Z])", "%1 %2"):gsub("_", " "):gsub("(%w)([%w']*)", function(a,b) return string.upper(a)..b end)
                end
                baseName = TitleCase(baseName)
            end
            
            local displayName = ""
            
            -- Add prefix name
            if inst.craft.prefixId and inst.craft.prefixId ~= "" and TDMRP.Gems and TDMRP.Gems.Prefixes then
                local prefix = TDMRP.Gems.Prefixes[inst.craft.prefixId]
                if prefix then
                    displayName = prefix.name .. " "
                end
            end
            
            displayName = displayName .. baseName
            
            -- Add suffix name
            if inst.craft.suffixId and inst.craft.suffixId ~= "" and TDMRP.Gems and TDMRP.Gems.Suffixes then
                local suffix = TDMRP.Gems.Suffixes[inst.craft.suffixId]
                if suffix then
                    displayName = displayName .. " " .. suffix.name
                end
            end
            
            -- Store crafted name on weapon for HUD to show alongside custom name
            -- DO NOT overwrite TDMRP_CustomName here - that contains the actual custom name!
            wep.TDMRP_CraftedName = displayName
            if SERVER then
                print(string.format("[TDMRP] ApplyInstanceToSWEP: Rebuilt display name: %s", displayName))
            end
        end
        
        -- Restore prefix/suffix stat modifiers to SWEP properties
        wep.TDMRP_PrefixStats = inst.craft.prefixStats
        wep.TDMRP_SuffixStats = inst.craft.suffixStats
        
        -- CRITICAL: If craft.appliedStats exist (new system), use those directly
        -- This preserves the exact stats the weapon had with prefix/suffix applied
        if inst.craft.appliedStats and (inst.craft.prefixId and inst.craft.prefixId ~= "") then
            -- Apply the stored stats directly (they already have prefix mods baked in)
            wep:SetNWInt("TDMRP_Damage", inst.craft.appliedStats.damage or inst.stats.damage or 20)
            wep:SetNWInt("TDMRP_RPM", inst.craft.appliedStats.rpm or inst.stats.rpm or 600)
            wep:SetNWInt("TDMRP_Accuracy", inst.craft.appliedStats.accuracy or inst.stats.accuracy or 60)
            wep:SetNWInt("TDMRP_Recoil", inst.craft.appliedStats.recoil or inst.stats.recoil or 25)
            wep:SetNWInt("TDMRP_Handling", inst.craft.appliedStats.handling or inst.stats.handling or 100)
            if SERVER then
                print(string.format("[TDMRP] Restored craft stats from appliedStats: Dmg=%d RPM=%d Acc=%d", 
                    inst.craft.appliedStats.damage, inst.craft.appliedStats.rpm, inst.craft.appliedStats.accuracy))
            end
        elseif inst.craft.prefixId and inst.craft.prefixId ~= "" then
            -- Fallback: recalculate prefix mods from base stats (which we just set above)
            local prefixData = TDMRP.Gems and TDMRP.Gems.Prefixes and TDMRP.Gems.Prefixes[inst.craft.prefixId]
            if prefixData and prefixData.stats then
                -- Get the BASE stats we just set
                local dmg = inst.stats.damage or 20
                local rpm = inst.stats.rpm or 600
                local acc = inst.stats.accuracy or 60
                local rec = inst.stats.recoil or 25
                local han = inst.stats.handling or 100
                
                local s = prefixData.stats
                if s.damage then dmg = math.floor(dmg * (1 + s.damage)) end
                if s.rpm then rpm = math.floor(rpm * (1 + s.rpm)) end
                if s.accuracy then acc = math.floor(acc * (1 + s.accuracy)) end
                if s.recoil then rec = math.floor(rec * (1 + s.recoil)) end
                if s.handling then han = math.floor(han * (1 + s.handling)) end
                
                wep:SetNWInt("TDMRP_Damage", math.max(1, dmg))
                wep:SetNWInt("TDMRP_RPM", math.max(60, rpm))
                wep:SetNWInt("TDMRP_Accuracy", math.Clamp(acc, 0, 95))
                wep:SetNWInt("TDMRP_Recoil", math.max(5, rec))
                wep:SetNWInt("TDMRP_Handling", math.Clamp(han, 0, 250))
                
                if SERVER then
                    print(string.format("[TDMRP] Recalculated prefix '%s' with stat mods: Dmg=%d RPM=%d Acc=%d", 
                        inst.craft.prefixId, dmg, rpm, acc))
                end
            end
        end
        
        -- Reinstall mixin hooks for suffix effects on server
        if SERVER and TDMRP_WeaponMixin and TDMRP_WeaponMixin.InstallHooks then
            TDMRP_WeaponMixin.InstallHooks(wep)
            if inst.craft.suffixId and inst.craft.suffixId ~= "" then
                print(string.format("[TDMRP] Reinstalled mixin hooks for suffix '%s'", inst.craft.suffixId))
            end
        end
    else
        wep:SetNWBool("TDMRP_Crafted", false)
        wep:SetNWString("TDMRP_PrefixID", "")
        wep:SetNWString("TDMRP_SuffixID", "")
    end
    
    if SERVER then
        print(string.format("[TDMRP] ApplyInstanceToSWEP: %s tier=%d crafted=%s (new_system=%s)", 
            inst.class or wep:GetClass(), inst.tier or 1, tostring(inst.craft and inst.craft.crafted), tostring(isNewSystem)))
    end
end

----------------------------------------
-- Registry lookup
----------------------------------------
function TDMRP.GetWeaponInstance(id)
    return id and TDMRP.Instances[id] or nil
end

----------------------------------------
-- Instance <-> inventory item conversion
----------------------------------------
function TDMRP.InstanceToItem(inst)
    if not inst then return nil end

    local item = {
        kind        = "weapon",
        class       = inst.class,
        tier        = inst.tier or 1,
        stats       = table.Copy(inst.stats or {}),
        cosmetic    = table.Copy(inst.cosmetic or {}),
        bound_until = inst.bound_until or 0,
        craft       = table.Copy(inst.craft or {}),
        gems        = table.Copy(inst.gems or {}),
        instance_id = inst.id,
        version     = inst.version or INSTANCE_VERSION,
    }

    return item
end

----------------------------------------
-- Instance Migration (for future format changes)
----------------------------------------
local function MigrateInstance(inst)
    if not inst then return inst end
    
    -- v0 (no version) → v1: Add version field
    if not inst.version or inst.version < 1 then
        inst.version = 1
    end
    
    -- Future migrations:
    -- if inst.version < 2 then ... end
    
    return inst
end

function TDMRP.ItemToInstance(item)
    if not item or item.kind ~= "weapon" then return nil end

    local class = item.class
    if not class or class == "" then return nil end

    local rawBound = item.bound_until or 0
    
    -- VALIDATE bind time: detect corrupted values (unix timestamps or huge numbers)
    -- Reasonable max bind time: 30 days = 2,592,000 seconds
    -- If > 30 days or looks like a unix timestamp (> 1 billion), it's corrupted
    local MAX_BIND_SECONDS = 2592000  -- 30 days
    if rawBound > MAX_BIND_SECONDS then
        if SERVER then
            print(string.format("[TDMRP] ItemToInstance: DETECTED CORRUPTED bind_until=%.0f (unix timestamp?). Resetting to 0", rawBound))
        end
        rawBound = 0
    end
    
    local inst = {
        version       = item.version or INSTANCE_VERSION,
        id            = item.instance_id or GenerateInstanceID(nil, class),
        class         = class,
        tier          = item.tier or 1,
        stats         = table.Copy(item.stats or {}),
        cosmetic      = table.Copy(item.cosmetic or {}),
        bound_until   = rawBound,
        craft         = table.Copy(item.craft or {}),
        gems          = table.Copy(item.gems or {}),
        owner_steamid = nil,
    }
    
    -- CRITICAL FIX: bound_until from JSON is already REMAINING SECONDS (frozen while in inventory)
    -- Use it directly WITHOUT subtracting from os.time()
    -- This ensures bind time doesn't decay while weapon is in inventory
    if inst.bound_until > 0 then
        if SERVER then
            print(string.format("[TDMRP] ItemToInstance: Weapon bound with %.1f seconds remaining (frozen in inventory)", inst.bound_until))
        end
    else
        if SERVER then
            print("[TDMRP] ItemToInstance: No bind timer on item")
        end
    end
    
    -- Migrate old format if needed
    inst = MigrateInstance(inst)
    
    -- Populate final stats for compatibility
    if inst.stats then
        inst.finalDamage = inst.stats.damage or 0
        inst.finalRPM = inst.stats.rpm or 0
        inst.finalRecoil = inst.stats.recoil or 0
        inst.finalSpread = inst.stats.spread or inst.stats.accuracy or 0
    else
        inst.finalDamage = 0
        inst.finalRPM = 0
        inst.finalRecoil = 0
        inst.finalSpread = 0
    end

    TDMRP.Instances[inst.id] = inst
    return inst
end

-- Convenience aliases so other files can call either style
function TDMRP_InstanceToItem(inst) return TDMRP.InstanceToItem(inst) end
function TDMRP_ItemToInstance(item) return TDMRP.ItemToInstance(item) end

print("[TDMRP] sh_tdmrp_instances.lua loaded (instance helpers)")
