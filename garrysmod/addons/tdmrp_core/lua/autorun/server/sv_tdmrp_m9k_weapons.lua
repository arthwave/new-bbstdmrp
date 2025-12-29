----------------------------------------------------
-- TDMRP M9K Weapon System - Server
-- Applies instance stats to M9K weapons
----------------------------------------------------

if CLIENT then return end

TDMRP = TDMRP or {}

----------------------------------------------------
-- Read Base Stats from M9K Weapons
----------------------------------------------------

local function ReadM9KBaseStats(className)
    local meta = TDMRP.GetM9KMeta(className)
    if not meta then return end
    
    -- Already cached?
    if meta.baseDamage then return end
    
    local wepTable = weapons.GetStored(className)
    if not wepTable or not wepTable.Primary then return end
    
    local primary = wepTable.Primary
    
    -- M9K uses these stat names
    meta.baseDamage = primary.Damage or 25
    meta.baseRPM = primary.RPM or 600
    meta.baseClipSize = primary.ClipSize or 15
    meta.baseSpread = primary.Spread or 0.02
    meta.baseIronAccuracy = primary.IronAccuracy or 0.01
    
    -- M9K recoil is 3-axis
    meta.baseKickUp = primary.KickUp or 0.5
    meta.baseKickDown = primary.KickDown or 0.3
    meta.baseKickHorizontal = primary.KickHorizontal or 0.3
    
    -- Combined recoil value for display
    meta.baseRecoil = meta.baseKickUp + meta.baseKickDown * 0.5 + meta.baseKickHorizontal * 0.5
    
    print("[TDMRP M9K] Cached base stats for " .. className .. " - DMG:" .. meta.baseDamage .. " RPM:" .. meta.baseRPM)
end

-- Cache all weapon stats on server start
hook.Add("InitPostEntity", "TDMRP_CacheM9KStats", function()
    timer.Simple(1, function()
        for className, _ in pairs(TDMRP.M9KRegistry) do
            ReadM9KBaseStats(className)
        end
        print("[TDMRP M9K] All weapon stats cached")
    end)
end)

----------------------------------------------------
-- Apply Instance Stats to Weapon Entity
----------------------------------------------------

function TDMRP.ApplyM9KInstance(wep, instance)
    if not IsValid(wep) then return false end
    if not instance then return false end
    
    local className = instance.class
    local meta = TDMRP.GetM9KMeta(className)
    if not meta then return false end
    
    -- Ensure base stats are cached
    ReadM9KBaseStats(className)
    
    local tier = instance.tier or 1
    local tierMult = TDMRP.TierMultipliers[tier]
    if not tierMult then return false end
    
    -- Calculate final stats
    local finalDamage = math.floor((meta.baseDamage or 25) * tierMult.damage)
    local finalRPM = math.floor((meta.baseRPM or 600) * tierMult.rpm)
    local finalSpread = (meta.baseSpread or 0.02) / tierMult.accuracy
    local finalIronAccuracy = (meta.baseIronAccuracy or 0.01) / tierMult.accuracy
    local finalKickUp = (meta.baseKickUp or 0.5) * tierMult.recoil
    local finalKickDown = (meta.baseKickDown or 0.3) * tierMult.recoil
    local finalKickHorizontal = (meta.baseKickHorizontal or 0.3) * tierMult.recoil
    
    -- Apply gem bonuses if crafted
    if instance.crafted and instance.gems then
        for _, gemType in ipairs(instance.gems) do
            if gemType == "sapphire" then
                -- Sapphire: +10% damage
                finalDamage = math.floor(finalDamage * 1.10)
            elseif gemType == "emerald" then
                -- Emerald: +15% accuracy
                finalSpread = finalSpread * 0.85
                finalIronAccuracy = finalIronAccuracy * 0.85
            elseif gemType == "ruby" then
                -- Ruby: +10% fire rate
                finalRPM = math.floor(finalRPM * 1.10)
            elseif gemType == "diamond" then
                -- Diamond: +5% all stats
                finalDamage = math.floor(finalDamage * 1.05)
                finalRPM = math.floor(finalRPM * 1.05)
                finalSpread = finalSpread * 0.95
                finalKickUp = finalKickUp * 0.95
                finalKickDown = finalKickDown * 0.95
                finalKickHorizontal = finalKickHorizontal * 0.95
            end
        end
    end
    
    -- Apply to weapon entity
    wep.Primary.Damage = finalDamage
    wep.Primary.RPM = finalRPM
    wep.Primary.Spread = finalSpread
    wep.Primary.IronAccuracy = finalIronAccuracy
    wep.Primary.KickUp = finalKickUp
    wep.Primary.KickDown = finalKickDown
    wep.Primary.KickHorizontal = finalKickHorizontal
    
    -- Store instance reference on weapon
    wep.TDMRP_Instance = instance
    wep.TDMRP_InstanceID = instance.id
    
    -- Set networked values for client HUD
    wep:SetNWInt("TDMRP_Tier", tier)
    wep:SetNWInt("TDMRP_Damage", finalDamage)
    wep:SetNWInt("TDMRP_RPM", finalRPM)
    wep:SetNWFloat("TDMRP_Spread", finalSpread)
    wep:SetNWFloat("TDMRP_Recoil", finalKickUp + finalKickDown * 0.5 + finalKickHorizontal * 0.5)
    wep:SetNWBool("TDMRP_Crafted", instance.crafted or false)
    wep:SetNWString("TDMRP_Gems", table.concat(instance.gems or {}, ","))
    wep:SetNWInt("TDMRP_InstanceID", instance.id)
    
    print("[TDMRP M9K] Applied instance " .. instance.id .. " to " .. className .. " T" .. tier)
    return true
end

----------------------------------------------------
-- Give Weapon with Instance
----------------------------------------------------

function TDMRP.GiveM9KWeapon(ply, className, tier, crafted, gems)
    if not IsValid(ply) then return nil end
    
    -- Ensure we're using tdmrp_m9k_* class (convert if needed for backwards compat)
    local tdmrpClass = className
    if string.StartWith(className, "m9k_") and not string.StartWith(className, "tdmrp_m9k_") then
        tdmrpClass = "tdmrp_" .. className
    end
    
    -- Lookup meta using base class for registry
    local meta = TDMRP.GetM9KMeta(tdmrpClass)
    if not meta then 
        print("[TDMRP M9K] Unknown weapon class: " .. tostring(tdmrpClass))
        return nil 
    end
    
    -- Give the TDMRP weapon directly
    local wep = ply:Give(tdmrpClass)
    if not IsValid(wep) then return nil end
    
    -- Set tier and apply via mixin (new system)
    wep.Tier = tier or 1
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(wep)
    end
    
    -- Apply gems if provided
    if gems then
        wep:SetNWInt("TDMRP_Gem_Sapphire", gems.sapphire or 0)
        wep:SetNWInt("TDMRP_Gem_Emerald", gems.emerald or 0)
        wep:SetNWInt("TDMRP_Gem_Ruby", gems.ruby or 0)
        wep:SetNWInt("TDMRP_Gem_Diamond", gems.diamond or 0)
        if TDMRP_WeaponMixin and TDMRP_WeaponMixin.ApplyGems then
            TDMRP_WeaponMixin.ApplyGems(wep)
        end
    end
    
    -- Set crafted flag
    if crafted then
        wep:SetNWBool("TDMRP_Crafted", true)
    end
    
    return wep
end

----------------------------------------------------
-- Spawn Weapon Entity with Instance
----------------------------------------------------

function TDMRP.SpawnM9KWeapon(pos, ang, className, tier, crafted, gems)
    -- Ensure we're using tdmrp_m9k_* class
    local tdmrpClass = className
    if string.StartWith(className, "m9k_") and not string.StartWith(className, "tdmrp_m9k_") then
        tdmrpClass = "tdmrp_" .. className
    end
    
    local meta = TDMRP.GetM9KMeta(tdmrpClass)
    if not meta then return nil end
    
    -- Create the TDMRP weapon entity directly
    local wep = ents.Create(tdmrpClass)
    if not IsValid(wep) then return nil end
    
    wep:SetPos(pos)
    wep:SetAngles(ang or Angle(0, 0, 0))
    
    -- Set tier before spawn so Initialize picks it up
    wep.Tier = tier or 1
    
    wep:Spawn()
    
    -- Set networked values
    wep:SetNWInt("TDMRP_Tier", tier or 1)
    wep:SetNWBool("TDMRP_Crafted", crafted or false)
    
    -- Apply gems if provided
    if gems then
        wep:SetNWInt("TDMRP_Gem_Sapphire", gems.sapphire or 0)
        wep:SetNWInt("TDMRP_Gem_Emerald", gems.emerald or 0)
        wep:SetNWInt("TDMRP_Gem_Ruby", gems.ruby or 0)
        wep:SetNWInt("TDMRP_Gem_Diamond", gems.diamond or 0)
    end
    
    return wep
end

----------------------------------------------------
-- Hook: Apply instance when player picks up weapon
----------------------------------------------------

hook.Add("PlayerCanPickupWeapon", "TDMRP_M9K_PickupInstance", function(ply, wep)
    if not IsValid(wep) then return end
    if not TDMRP.IsM9KWeapon(wep) then return end
    
    -- If weapon has an instance, it will be applied after pickup
    if wep.TDMRP_Instance then
        timer.Simple(0.1, function()
            if IsValid(ply) and IsValid(wep) and wep:GetOwner() == ply then
                TDMRP.ApplyM9KInstance(wep, wep.TDMRP_Instance)
            end
        end)
    end
end)

----------------------------------------------------
-- Hook: Handle weapon drops - preserve instance
----------------------------------------------------

hook.Add("PlayerDroppedWeapon", "TDMRP_M9K_DropPreserve", function(ply, wep)
    if not IsValid(wep) then return end
    if not TDMRP.IsM9KWeapon(wep) then return end
    
    -- Instance data is already on the weapon entity
    -- Just make sure NW values are set for display
    if wep.TDMRP_Instance then
        local inst = wep.TDMRP_Instance
        wep:SetNWInt("TDMRP_Tier", inst.tier)
        wep:SetNWBool("TDMRP_Crafted", inst.crafted or false)
        wep:SetNWInt("TDMRP_InstanceID", inst.id)
    end
end)

----------------------------------------------------
-- Hook: Player death - drop all M9K weapons with instances
-- (Bound weapons are protected and handled by sv_tdmrp_binding.lua)
----------------------------------------------------

----------------------------------------------------
-- DISABLED: Death drop handling moved to sv_tdmrp_job_loadouts.lua
-- The job_loadouts handler provides cleaner logic for bound/unbound weapons
----------------------------------------------------

-- Disabled old M9K death drop hook - use job_loadouts handler instead

--[[ OLD CODE - DO NOT USE
if false then
hook.Add("PlayerDeath", "TDMRP_M9K_DeathDrop", function(victim, inflictor, attacker)
    if not IsValid(victim) then return end
    
    local weapons = victim:GetWeapons()
    local dropPos = victim:GetPos() + Vector(0, 0, 30)
    
    for _, wep in ipairs(weapons) do
        if IsValid(wep) and TDMRP.IsM9KWeapon(wep) and wep.TDMRP_Instance then
            -- Check if weapon is bound (protected from dropping)
            local shouldDrop = true
            
            -- Check binding system
            if TDMRP.Binding and TDMRP.Binding.IsBound and TDMRP.Binding.IsBound(wep) then
                shouldDrop = false
            end
            
            -- Allow other hooks to block drop
            local hookResult = hook.Run("TDMRP_ShouldDropWeaponOnDeath", victim, wep)
            if hookResult == false then
                shouldDrop = false
            end
            
            if shouldDrop then
                local instance = wep.TDMRP_Instance
                -- Spawn dropped weapon
                local droppedWep, _ = TDMRP.SpawnM9KWeapon(
                    dropPos + VectorRand() * 20,
                    AngleRand(),
                    instance.class,
                    instance.tier,
                    instance.crafted,
                    instance.gems
                )
                
                if IsValid(droppedWep) then
                    -- Apply physics impulse
                    local phys = droppedWep:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:ApplyForceCenter(VectorRand() * 150)
                    end
                    
                    -- Copy instance ID
                    droppedWep.TDMRP_Instance = instance
                    droppedWep.TDMRP_InstanceID = instance.id
                end
            end
        end
    end
end)
end
--]]

----------------------------------------------------
-- Hook: Player spawn - give default loadout
----------------------------------------------------

-- DISABLED: Conflicting with spawn_orchestrator system
-- Old random starter weapon system was interfering with bound weapons restoration
-- The spawn_orchestrator now handles all weapon distribution for civilians
--[[
hook.Add("PlayerLoadout", "TDMRP_M9K_Loadout", function(ply)
    if not IsValid(ply) then return end
    
    -- Only give weapons if player has no M9K weapons
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end
        
        local hasM9K = false
        for _, wep in ipairs(ply:GetWeapons()) do
            if TDMRP.IsM9KWeapon(wep) then
                hasM9K = true
                break
            end
        end
        
        -- If no M9K weapons, give starter weapon based on job
        if not hasM9K then
            local teamID = ply:Team()
            local job = RPExtraTeams and RPExtraTeams[teamID]
            
            if job then
                local starterWeapon = nil
                local starterTier = TDMRP.GetRandomTier()
                
                -- Limit starter tier to 1-4
                if starterTier > 4 then starterTier = 4 end
                
                -- Give weapon based on job class
                local jobClass = job.tdmrp_class or "civilian"
                
                if jobClass == "police" then
                    -- Police get pistols
                    local policeWeapons = {"tdmrp_m9k_glock", "tdmrp_m9k_m92beretta", "tdmrp_m9k_usp", "tdmrp_m9k_sig_p229r"}
                    starterWeapon = policeWeapons[math.random(#policeWeapons)]
                elseif jobClass == "criminal" then
                    -- Criminals get variety
                    local criminalWeapons = {"tdmrp_m9k_glock", "tdmrp_m9k_tec9", "tdmrp_m9k_uzi", "tdmrp_m9k_colt1911"}
                    starterWeapon = criminalWeapons[math.random(#criminalWeapons)]
                else
                    -- Civilians get basic pistols
                    local civilianWeapons = {"tdmrp_m9k_glock", "tdmrp_m9k_colt1911", "tdmrp_m9k_m92beretta"}
                    starterWeapon = civilianWeapons[math.random(#civilianWeapons)]
                end
                
                if starterWeapon then
                    TDMRP.GiveM9KWeapon(ply, starterWeapon, starterTier, false, {})
                end
            end
        end
    end)
end)
]]

----------------------------------------------------
-- Network: Request weapon stats
----------------------------------------------------

util.AddNetworkString("TDMRP_RequestWeaponStats")
util.AddNetworkString("TDMRP_SendWeaponStats")

net.Receive("TDMRP_RequestWeaponStats", function(len, ply)
    if not IsValid(ply) then return end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not TDMRP.IsM9KWeapon(wep) then return end
    
    local instance = wep.TDMRP_Instance
    if not instance then return end
    
    net.Start("TDMRP_SendWeaponStats")
        net.WriteInt(instance.id, 32)
        net.WriteString(instance.class)
        net.WriteInt(instance.tier, 8)
        net.WriteBool(instance.crafted)
        net.WriteString(table.concat(instance.gems or {}, ","))
        net.WriteInt(wep:GetNWInt("TDMRP_Damage", 0), 16)
        net.WriteInt(wep:GetNWInt("TDMRP_RPM", 0), 16)
        net.WriteFloat(wep:GetNWFloat("TDMRP_Spread", 0))
        net.WriteFloat(wep:GetNWFloat("TDMRP_Recoil", 0))
    net.Send(ply)
end)

print("[TDMRP] sv_tdmrp_m9k_weapons.lua loaded - M9K weapon system initialized")
