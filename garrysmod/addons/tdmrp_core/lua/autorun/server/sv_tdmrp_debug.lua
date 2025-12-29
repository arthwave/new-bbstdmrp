-- sv_tdmrp_debug.lua
-- Debug helper: set tier of currently held weapon for testing.

if not SERVER then return end

local function SetHeldWeaponTier(ply, newTier)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not wep:IsWeapon() then
        ply:ChatPrint("[TDMRP] No valid weapon in hands.")
        return
    end

    local class = wep:GetClass()

    -- Clamp tier between 1 and 5
    newTier = tonumber(newTier) or 1
    newTier = math.Clamp(newTier, 1, 5)

    -- Check if this is a TDMRP weapon (either legacy or new system)
    local isTDMRPWeapon = false
    
    -- Check new system: tdmrp_m9k_* weapons with mixin
    if string.StartWith(class, "tdmrp_m9k_") and wep.Tier and TDMRP_WeaponMixin then
        isTDMRPWeapon = true
        wep.Tier = newTier
        
        -- Re-apply mixin to recalculate stats
        if TDMRP_WeaponMixin.Setup then
            TDMRP_WeaponMixin.Setup(wep)
        end
        
        local tierNames = {
            [1] = "Common",
            [2] = "Uncommon",
            [3] = "Rare",
            [4] = "Legendary",
            [5] = "Unique"
        }
        
        ply:ChatPrint(string.format("[TDMRP] Set %s to %s (Tier %d).", 
            TDMRP.GetWeaponDisplayName and TDMRP.GetWeaponDisplayName(class) or class,
            tierNames[newTier] or "Unknown",
            newTier))
        
        print(string.format("[TDMRP Debug] %s -> %s | Dmg=%d RPM=%d", 
            class, tierNames[newTier] or ("T" .. newTier),
            wep.Primary and wep.Primary.Damage or 0,
            wep.Primary and wep.Primary.RPM or 0))
        
        return
    end
    
    -- Check legacy system
    if TDMRP.GetWeaponMeta and TDMRP.NewWeaponInstance then
        local meta = TDMRP.GetWeaponMeta(class)
        if meta then
            isTDMRPWeapon = true
            
            local instID = wep.TDMRP_WeaponID
            local inst = instID and TDMRP.WeaponInstances and TDMRP.WeaponInstances[instID] or nil

            if inst then
                inst.tier = newTier
            else
                inst = TDMRP.NewWeaponInstance(class, newTier)
                if inst then
                    wep.TDMRP_WeaponID = inst.id
                end
            end

            if inst then
                if TDMRP.RecalculateInstanceStats then
                    TDMRP.RecalculateInstanceStats(inst)
                end
                if TDMRP.ApplyInstanceToSWEP then
                    TDMRP.ApplyInstanceToSWEP(wep, inst)
                end
                
                local tierName = (TDMRP.Tiers and TDMRP.Tiers[newTier] and TDMRP.Tiers[newTier].name) or ("Tier " .. newTier)
                ply:ChatPrint(string.format("[TDMRP] Set %s to %s.", class, tierName))
            end
            
            return
        end
    end
    
    -- Not a TDMRP weapon
    if not isTDMRPWeapon then
        ply:ChatPrint("[TDMRP] This weapon is not a TDMRP weapon: " .. tostring(class))
    end
end

concommand.Add("tdmrp_settier", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() then
        print("[TDMRP] tdmrp_settier must be run by a player.")
        return
    end

    local tierArg = args[1]
    if not tierArg then
        ply:ChatPrint("[TDMRP] Usage: tdmrp_settier <1-5>")
        return
    end

    SetHeldWeaponTier(ply, tierArg)
end)

----------------------------------------------------
-- Prefix/Suffix Debug Commands
----------------------------------------------------

concommand.Add("tdmrp_setprefix", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local prefixId = args[1]
    if not prefixId then
        ply:ChatPrint("[TDMRP] Usage: tdmrp_setprefix <prefix_id>")
        ply:ChatPrint("[TDMRP] Available: Heavy, Light, Precision, Aggressive, Steady, Piercing, Blazing, Swift, Reinforced, Balanced")
        return
    end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then
        ply:ChatPrint("[TDMRP] No weapon in hands.")
        return
    end
    
    if not TDMRP or not TDMRP.Gems or not TDMRP.Gems.Prefixes then
        ply:ChatPrint("[TDMRP] Gem system not loaded.")
        return
    end
    
    local prefix = TDMRP.Gems.Prefixes[prefixId]
    if not prefix then
        ply:ChatPrint("[TDMRP] Unknown prefix: " .. prefixId)
        return
    end
    
    -- Set the prefix
    wep:SetNWString("TDMRP_PrefixID", prefixId)
    wep:SetNWBool("TDMRP_Crafted", true)
    
    -- Apply prefix stat modifiers
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.ApplyTierScaling then
        -- Re-apply tier scaling first to get clean base
        local tier = wep.Tier or wep:GetNWInt("TDMRP_Tier", 1)
        TDMRP_WeaponMixin.ApplyTierScaling(wep, tier)
    end
    
    -- Apply prefix stats (this is in sv_tdmrp_gemcraft.lua but we need it here)
    if TDMRP.Gems and TDMRP.Gems.Prefixes then
        local pref = TDMRP.Gems.Prefixes[prefixId]
        if pref and pref.stats then
            local s = pref.stats
            
            if s.damage and wep.Primary then
                wep.Primary.Damage = math.floor(wep.Primary.Damage * (1 + s.damage))
            end
            if s.rpm and wep.Primary then
                wep.Primary.RPM = math.floor(wep.Primary.RPM * (1 + s.rpm))
                wep.Primary.Delay = 60 / wep.Primary.RPM
            end
            if s.spread and wep.Primary then
                wep.Primary.Spread = wep.Primary.Spread * (1 + s.spread)
            end
            if s.recoil and wep.Primary then
                local mult = (1 + s.recoil)
                wep.Primary.KickUp = wep.Primary.KickUp * mult
                wep.Primary.KickDown = wep.Primary.KickDown * mult
                wep.Primary.KickHorizontal = wep.Primary.KickHorizontal * mult
            end
            if s.handling then
                wep.TDMRP_Handling = math.Clamp(math.floor((wep.TDMRP_Handling or 100) * (1 + s.handling)), 0, 250)
            end
            if s.magazine and wep.Primary then
                local baseMag = wep.TDMRP_BaseMagSize or wep.Primary.ClipSize or 30
                wep.Primary.ClipSize = math.floor(baseMag * (1 + s.magazine))
            end
            
            -- Update NWInts
            if TDMRP_WeaponMixin and TDMRP_WeaponMixin.SetNetworkedStats then
                TDMRP_WeaponMixin.SetNetworkedStats(wep)
            end
        end
    end
    
    ply:ChatPrint(string.format("[TDMRP] Applied prefix: %s", prefix.name))
end)

concommand.Add("tdmrp_setsuffix", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local suffixId = args[1]
    if not suffixId then
        ply:ChatPrint("[TDMRP] Usage: tdmrp_setsuffix <suffix_id>")
        ply:ChatPrint("[TDMRP] Examples: of_Burning, of_Freezing, of_Piercing, of_Shocking, of_Bleeding")
        ply:ChatPrint("[TDMRP] Tier 2: of_Inferno, of_Blizzard, of_Shattering, of_Wounding, of_Tempest")
        ply:ChatPrint("[TDMRP] Tier 3+: of_Hellfire, of_Lightning, of_Cataclysm, of_Oblivion, etc.")
        return
    end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then
        ply:ChatPrint("[TDMRP] No weapon in hands.")
        return
    end
    
    if not TDMRP or not TDMRP.Gems or not TDMRP.Gems.Suffixes then
        ply:ChatPrint("[TDMRP] Gem system not loaded.")
        return
    end
    
    local suffix = TDMRP.Gems.Suffixes[suffixId]
    if not suffix then
        ply:ChatPrint("[TDMRP] Unknown suffix: " .. suffixId)
        return
    end
    
    -- Set the suffix
    wep:SetNWString("TDMRP_SuffixID", suffixId)
    wep:SetNWBool("TDMRP_Crafted", true)
    
    -- Network custom tracer if suffix has one
    if suffix.TracerName then
        wep:SetNWString("TDMRP_TracerName", suffix.TracerName)
    else
        wep:SetNWString("TDMRP_TracerName", "")
    end
    
    ply:ChatPrint(string.format("[TDMRP] Applied suffix: %s (Tier %d)", suffix.name, suffix.tier or 1))
    if suffix.OnBulletHit then
        ply:ChatPrint("[TDMRP] Effect: " .. (suffix.description or "No description"))
    else
        ply:ChatPrint("[TDMRP] WARNING: No OnBulletHit hook implemented yet")
    end
end)

concommand.Add("tdmrp_clearcrafting", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then
        ply:ChatPrint("[TDMRP] No weapon in hands.")
        return
    end
    
    wep:SetNWString("TDMRP_PrefixID", "")
    wep:SetNWString("TDMRP_SuffixID", "")
    wep:SetNWString("TDMRP_TracerName", "")
    wep:SetNWBool("TDMRP_Crafted", false)
    
    -- Reset to tier-scaled stats
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.ApplyTierScaling then
        local tier = wep.Tier or wep:GetNWInt("TDMRP_Tier", 1)
        TDMRP_WeaponMixin.ApplyTierScaling(wep, tier)
        TDMRP_WeaponMixin.SetNetworkedStats(wep)
    end
    
    ply:ChatPrint("[TDMRP] Cleared all prefix/suffix crafting")
end)

concommand.Add("tdmrp_spawndummy", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local tr = ply:GetEyeTrace()
    if not tr.Hit then
        ply:ChatPrint("[TDMRP] Look at a surface to spawn dummy")
        return
    end
    
    -- Spawn NPC at trace location
    local npc = ents.Create("npc_citizen")
    if not IsValid(npc) then
        ply:ChatPrint("[TDMRP] Failed to create NPC")
        return
    end
    
    npc:SetPos(tr.HitPos + Vector(0, 0, 10))
    npc:SetAngles(Angle(0, ply:EyeAngles().yaw + 180, 0))
    npc:Spawn()
    npc:Activate()
    
    -- Make it stay still
    npc:SetSchedule(SCHED_IDLE_STAND)
    
    -- Store marker for easy cleanup
    npc.TDMRP_TestDummy = true
    
    ply:ChatPrint("[TDMRP] Spawned test dummy (shoot it to test suffix effects)")
end)

concommand.Add("tdmrp_cleardummies", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local count = 0
    for _, npc in ipairs(ents.FindByClass("npc_*")) do
        if IsValid(npc) and npc.TDMRP_TestDummy then
            npc:Remove()
            count = count + 1
        end
    end
    
    ply:ChatPrint(string.format("[TDMRP] Removed %d test dummies", count))
end)

print("[TDMRP] sv_tdmrp_debug.lua loaded (tier command)")
