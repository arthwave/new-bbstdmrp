-- sh_tdmrp_gemcraft.lua
-- Gem crafting system: prefixes (emeralds) and suffixes (sapphires)
-- Prefixes modify stats, suffixes provide gameplay effects

if SERVER then
    AddCSLuaFile()
end

TDMRP = TDMRP or {}
TDMRP.Gems = TDMRP.Gems or {}

---------------------------------------------------------
-- GEM TIER COSTS
---------------------------------------------------------
TDMRP.Gems.CraftingCosts = {
    [1] = 5000,    -- Common
    [2] = 7500,    -- Uncommon
    [3] = 10000,   -- Rare
    [4] = 15000,   -- Epic
    [5] = 25000,   -- Legendary
}

---------------------------------------------------------
-- EMERALD PREFIXES (Stat Modifiers)
-- All 10 prefixes are shared across all weapon tiers
-- Players choose one when crafting
---------------------------------------------------------
TDMRP.Gems.Prefixes = {
    Heavy = {
        name = "Heavy",
        stats = {
            damage = 0.12,      -- +12% damage
            magazine = 0.40,    -- +40% magazine
            handling = -0.15,   -- -15% handling
            reload = -0.10,     -- -10% reload speed
        },
        description = "Increased firepower at the cost of mobility"
    },
    Light = {
        name = "Light",
        stats = {
            damage = -0.08,     -- -8% damage
            magazine = -0.25,   -- -25% magazine
            handling = 0.20,    -- +20% handling
            reload = 0.15,      -- +15% reload speed
        },
        description = "Swift and nimble, sacrifices raw power"
    },
    Precision = {
        name = "Precision",
        stats = {
            spread = -0.20,     -- -20% spread (tighter)
            accuracy = 0.15,    -- +15% accuracy
            rpm = -0.10,        -- -10% RPM
        },
        description = "Tighter grouping for skilled marksmen"
    },
    Aggressive = {
        name = "Aggressive",
        stats = {
            rpm = 0.18,         -- +18% RPM
            recoil = 0.12,      -- +12% recoil
            magazine = -0.15,   -- -15% magazine
        },
        description = "Higher fire rate demands control"
    },
    Steady = {
        name = "Steady",
        stats = {
            recoil = -0.18,     -- -18% recoil
            handling = 0.10,    -- +10% handling
            rpm = -0.08,        -- -8% RPM
        },
        description = "Controlled and stable"
    },
    Piercing = {
        name = "Piercing",
        stats = {
            damage = 0.15,
            spread = 0.08,
            rpm = -0.05,
        },
        description = "Armor-penetrating rounds"
    },
    Blazing = {
        name = "Blazing",
        stats = {
            rpm = 0.22,
            recoil = 0.15,
            damage = 0.05,
        },
        description = "Scorching fire rate"
    },
    Swift = {
        name = "Swift",
        stats = {
            handling = 0.25,
            reload = 0.20,
            damage = -0.10,
        },
        description = "Lightning-fast operation"
    },
    Reinforced = {
        name = "Reinforced",
        stats = {
            magazine = 0.30,
            recoil = -0.10,
            rpm = -0.08,
        },
        description = "Built for endurance"
    },
    Balanced = {
        name = "Balanced",
        stats = {
            damage = 0.05,
            rpm = 0.05,
            accuracy = 0.08,
            handling = 0.08,
        },
        description = "Jack of all trades, master of none"
    },
}

print("[TDMRP GemCraft] Gem definitions loaded. Prefixes count: " .. table.Count(TDMRP.Gems.Prefixes))
print("[TDMRP GemCraft] Suffixes count: " .. (TDMRP.Gems.Suffixes and table.Count(TDMRP.Gems.Suffixes) or "not loaded yet"))

---------------------------------------------------------
-- SAPPHIRE SUFFIXES (Gameplay Effects)
-- All suffixes are now unified tier with meaningful, exciting effects
---------------------------------------------------------
TDMRP.Gems.Suffixes = {
    of_Doubleshot = {
        name = "of Doubleshot",
        effect = "doubleshot",
        description = "Fires two bullets per shot",
        stats = { 
            damage = -0.25,      -- Reduced per-projectile damage to balance
            recoil = 1.0,        -- Doubled recoil
            handling = -0.10,    -- Slightly reduced handling
        },
        material = "phoenix_storms/Future_vents",
        ammoCost = 2,           -- Consumes 2 ammo per shot (forward compatible)
        soundEffect = "tdmrp/suffixsounds/ofdoubleshot1.mp3",  -- Layered on top of gunshot
        
        -- Hook: Fire twice per trigger pull with tighter spread
        OnPreFire = function(wep)
            if not IsValid(wep) then return end
            -- Mark that we should fire twice on the next shot
            wep.TDMRP_DoubleShotNextFire = true
        end,
        
        -- Hook: During bullet fire, adjust num_bullets to 2 instead of 1
        OnBulletFired = function(wep)
            if not IsValid(wep) then return end
            -- Clear the flag after we've fired
            wep.TDMRP_DoubleShotNextFire = false
        end,
    },
    
    of_Shrapnel = {
        name = "of Shrapnel",
        effect = "shrapnel",
        description = "Bullets explode on impact, hitting nearby enemies",
        stats = { 
            damage = -0.40,      -- Reduced per-projectile damage for balance
            rpm = -0.50,         -- 50% fire rate reduction
            recoil = 0.75,       -- Increased recoil from explosions
            handling = -0.20,    -- Handling penalty
        },
        material = "models/props_canal/metalcrate001d",
        ammoCost = 1,           -- Normal ammo cost (single shot)
        soundEffect = "tdmrp/suffixsounds/ofshrapnel.mp3",
        
        -- Hook: Explosion on bullet hit
        OnBulletHit = function(wep, tr, dmginfo)
            if not IsValid(wep) then return end
            
            local hitPos = tr.HitPos
            local attacker = wep:GetOwner()
            if not IsValid(attacker) then return end
            
            local explosionRadius = 100
            local baseDamage = dmginfo:GetDamage()
            
            -- Create prop-based shrapnel burst effect (server-side only)
            if SERVER then
                local shrapnelCount = 8
                local shrapnelSpeed = 1200
                local shrapnelScale = 0.3  -- Scale down rocks to 30% size
                
                for i = 1, shrapnelCount do
                    -- Calculate random direction (cone outward)
                    local angle = (i / shrapnelCount) * math.pi * 2
                    local pitch = math.Rand(-45, 45) * math.pi / 180
                    
                    local direction = Vector(
                        math.cos(angle) * math.cos(pitch),
                        math.sin(angle) * math.cos(pitch),
                        math.sin(pitch)
                    ):GetNormalized()
                    
                    local velocity = direction * (shrapnelSpeed + math.Rand(-200, 200))
                    
                    -- Create rock prop for shrapnel
                    local prop = ents.Create("prop_physics")
                    if IsValid(prop) then
                        prop:SetModel("models/props_junk/rock001a.mdl")
                        prop:SetPos(hitPos + direction * 15)
                        prop:SetModelScale(shrapnelScale, 0)
                        prop:SetColor(Color(255, 165, 0, 255))  -- Orange glow
                        prop:Spawn()
                        
                        -- Store owner and owner's job for damage checks
                        prop:SetOwner(attacker)
                        prop.TDMRP_OwnerJob = attacker:Team()
                        
                        -- Apply velocity
                        local phys = prop:GetPhysicsObject()
                        if IsValid(phys) then
                            phys:SetVelocity(velocity)
                        end
                        
                        -- Hook damage to prevent friendly fire
                        prop.OnTakeDamage = function(self, dmginfo)
                            local victim = dmginfo:GetAttacker()
                            if IsValid(victim) and victim:IsPlayer() then
                                -- Don't damage the owner
                                if victim == attacker then
                                    return
                                end
                                -- Don't damage same job class
                                if victim:Team() == self.TDMRP_OwnerJob then
                                    return
                                end
                            end
                            -- Allow damage from other sources
                        end
                        
                        -- Remove prop after 0.5 seconds
                        timer.Simple(0.5, function()
                            if IsValid(prop) then
                                prop:Remove()
                            end
                        end)
                    end
                end
            end
            
            -- Debounce explosion sound (prevent multiple sounds at same location in quick succession)
            local soundKey = "ShrapnelExplosion_" .. math.floor(hitPos.x) .. "_" .. math.floor(hitPos.y) .. "_" .. math.floor(hitPos.z)
            if not TDMRP.LastExplosionSoundTime then
                TDMRP.LastExplosionSoundTime = {}
            end
            local currentTime = CurTime()
            if not TDMRP.LastExplosionSoundTime[soundKey] or (currentTime - TDMRP.LastExplosionSoundTime[soundKey]) > 0.1 then
                sound.Play("weapons/explode3.wav", hitPos, 75, 100)
                TDMRP.LastExplosionSoundTime[soundKey] = currentTime
            end
            
            -- Find all entities (players, NPCs, props) within explosion radius
            if SERVER then
                local nearbyEnts = ents.FindInSphere(hitPos, explosionRadius)
                for _, ent in ipairs(nearbyEnts) do
                    if not IsValid(ent) then continue end
                    
                    -- Skip attacker and the entity that was directly hit
                    if ent == attacker or ent == tr.Entity then continue end
                    
                    -- Damage players and NPCs
                    if ent:IsPlayer() or ent:IsNPC() then
                        local distToTarget = hitPos:Distance(ent:GetPos())
                        
                        -- Scale damage with distance: full at center (0), zero at radius edge
                        local damageFalloff = math.max(0, 1 - (distToTarget / explosionRadius))
                        local explosionDamage = baseDamage * damageFalloff
                        
                        if explosionDamage > 0 then
                            -- Apply damage
                            local dmg = DamageInfo()
                            dmg:SetDamage(explosionDamage)
                            dmg:SetAttacker(attacker)
                            dmg:SetInflictor(wep)
                            dmg:SetDamageType(DMG_BLAST)
                            
                            -- Players: check team immunity
                            if ent:IsPlayer() and attacker:IsPlayer() then
                                if attacker:Team() == ent:Team() then
                                    continue -- Skip friendly fire
                                end
                            end
                            
                            -- Apply damage safely
                            pcall(function() ent:TakeDamage(dmg) end)
                            
                            -- Apply knockback away from explosion center
                            local knockbackDir = (ent:GetPos() - hitPos):GetNormalized()
                            local knockbackForce = 50 * damageFalloff
                            if IsValid(ent) then
                                ent:SetVelocity(ent:GetVelocity() + knockbackDir * knockbackForce)
                            end
                        end
                    -- Damage props (ragdolls and damageable props)
                    elseif ent:IsRagdoll() or (ent:GetClass() and ent:GetClass():find("prop_")) then
                        local distToTarget = hitPos:Distance(ent:GetPos())
                        local damageFalloff = math.max(0, 1 - (distToTarget / explosionRadius))
                        local explosionDamage = baseDamage * damageFalloff
                        
                        if explosionDamage > 0 and (ent:Health() or 0) > 0 then
                            local dmg = DamageInfo()
                            dmg:SetDamage(explosionDamage)
                            dmg:SetAttacker(attacker)
                            dmg:SetInflictor(wep)
                            dmg:SetDamageType(DMG_BLAST)
                            pcall(function() ent:TakeDamage(dmg) end)
                        end
                    end
                end
            end
        end,
    },
    
    of_ChainLightning = {
        name = "of ChainLightning",
        material = "models/alyx/emptool_glow",
        description = "Bullets chain to nearby enemies with electrical arcs",
        stats = {
            damage = -0.30,      -- Reduced base damage for balance
            rpm = -0.20,         -- 20% fire rate reduction
            recoil = 0.5,        -- Slight recoil increase
            handling = -0.15,    -- Handling penalty
        },
        ammoCost = 1,           -- Normal ammo cost
        soundEffect = "tdmrp/suffixsounds/ofchainlightning1.mp3",
        
        -- Hook: Send initial shot beam to all clients
        OnBulletFired = function(wep)
            if SERVER then
                local owner = wep:GetOwner()
                if not IsValid(owner) then return end
                
                -- Get muzzle position
                local muzzleAttachment = wep:LookupAttachment("muzzle")
                local muzzlePos = owner:EyePos()
                
                if muzzleAttachment and muzzleAttachment > 0 then
                    local attachData = wep:GetAttachment(muzzleAttachment)
                    if attachData then
                        muzzlePos = attachData.Pos
                    end
                end
                
                -- Trace to get impact point
                local tr = util.QuickTrace(owner:EyePos(), owner:GetAimVector() * 10000, owner)
                
                -- Send beam to all clients
                net.Start("TDMRP_ChainBeam")
                    net.WriteVector(muzzlePos)
                    net.WriteVector(tr.HitPos)
                    net.WriteFloat(0.2)  -- 0.2s lifespan
                net.Broadcast()
            end
        end,
        
        -- Hook: Chain lightning on bullet hit
        OnBulletHit = function(wep, tr, dmginfo)
            if not SERVER then 
                print("[TDMRP ChainLightning] OnBulletHit called on CLIENT - early exit")
                return 
            end
            
            print("[TDMRP ChainLightning] OnBulletHit FIRED on SERVER")
            
            if not IsValid(wep) then 
                print("[TDMRP ChainLightning] Invalid weapon")
                return 
            end
            
            local hitPos = tr.HitPos
            local hitEntity = tr.Entity
            local attacker = wep:GetOwner()
            
            print(string.format("[TDMRP ChainLightning] Hit pos: %.1f,%.1f,%.1f | Attacker: %s", 
                hitPos.x, hitPos.y, hitPos.z, (IsValid(attacker) and attacker:GetName() or "INVALID")))
            
            if not IsValid(attacker) or not attacker:IsPlayer() then 
                print("[TDMRP ChainLightning] Invalid attacker or not a player")
                return 
            end
            
            local chainRadius = 200
            local maxChains = 3
            local chainDamagePercent = 0.75
            local baseDamage = dmginfo:GetDamage()
            local chainDamage = baseDamage * chainDamagePercent
            
            print(string.format("[TDMRP ChainLightning] Base damage: %.1f | Chain damage: %.1f | Radius: %d", 
                baseDamage, chainDamage, chainRadius))
            
            -- Find all nearby players AND NPCs
            local candidates = {}
            
            -- Check all players
            local allPlayers = player.GetAll()
            print(string.format("[TDMRP ChainLightning] Total players on server: %d", #allPlayers))
            
            for _, ply in ipairs(allPlayers) do
                if not IsValid(ply) then continue end
                
                if ply == attacker then 
                    print(string.format("[TDMRP ChainLightning] Skipping %s (self)", ply:GetName()))
                    continue 
                end
                
                if IsValid(hitEntity) and ply == hitEntity then 
                    print(string.format("[TDMRP ChainLightning] Skipping %s (initial hit)", ply:GetName()))
                    continue 
                end
                
                if ply:Team() == attacker:Team() then 
                    print(string.format("[TDMRP ChainLightning] Skipping %s (same team)", ply:GetName()))
                    continue 
                end
                
                local distToPlayer = hitPos:Distance(ply:GetPos())
                print(string.format("[TDMRP ChainLightning] %s at distance %.1f", ply:GetName(), distToPlayer))
                
                if distToPlayer <= chainRadius then
                    print(string.format("[TDMRP ChainLightning] %s IN RANGE - adding as candidate", ply:GetName()))
                    table.insert(candidates, {
                        entity = ply,
                        distance = distToPlayer,
                        name = ply:GetName()
                    })
                end
            end
            
            -- Check all NPCs
            local allNPCs = ents.FindByClass("npc_*")
            print(string.format("[TDMRP ChainLightning] Total NPCs on map: %d", #allNPCs))
            
            for _, npc in ipairs(allNPCs) do
                if not IsValid(npc) then continue end
                
                if IsValid(hitEntity) and npc == hitEntity then 
                    print(string.format("[TDMRP ChainLightning] Skipping NPC (initial hit)"))
                    continue 
                end
                
                -- Skip NPCs with no health
                if not npc:Health() or npc:Health() <= 0 then
                    continue
                end
                
                local distToNPC = hitPos:Distance(npc:GetPos())
                print(string.format("[TDMRP ChainLightning] NPC %s at distance %.1f", npc:GetClass(), distToNPC))
                
                if distToNPC <= chainRadius then
                    print(string.format("[TDMRP ChainLightning] NPC %s IN RANGE - adding as candidate", npc:GetClass()))
                    table.insert(candidates, {
                        entity = npc,
                        distance = distToNPC,
                        name = npc:GetClass()
                    })
                end
            end
            
            print(string.format("[TDMRP ChainLightning] Found %d candidates for chaining", #candidates))
            
            -- Sort by distance
            table.sort(candidates, function(a, b)
                return a.distance < b.distance
            end)
            
            -- Apply chain damage
            local chainsApplied = 0
            for i = 1, math.min(maxChains, #candidates) do
                local targetData = candidates[i]
                local target = targetData.entity
                local targetName = targetData.name
                local targetPos = target:GetPos()
                
                -- Calculate randomized body hit position (chest/torso area)
                local bodyHitPos = targetPos + Vector(
                    math.Rand(-8, 8),   -- Random X offset
                    math.Rand(-8, 8),   -- Random Y offset
                    math.Rand(30, 50)   -- Height range: lower chest to upper chest/neck
                )
                
                print(string.format("[TDMRP ChainLightning] Chain %d: %s at %.1f distance", i, targetName, targetData.distance))
                
                if not IsValid(target) or target:Health() <= 0 then 
                    print(string.format("[TDMRP ChainLightning] Target %s invalid or dead", targetName))
                    continue 
                end
                
                -- DEBUG: Check health before damage
                local healthBefore = target:Health()
                print(string.format("[TDMRP ChainLightning] Health BEFORE: %s = %.1f", targetName, healthBefore))
                
                -- Apply damage
                local dmg = DamageInfo()
                dmg:SetDamage(chainDamage)
                dmg:SetAttacker(attacker)
                dmg:SetInflictor(wep)
                dmg:SetDamageType(DMG_SHOCK)
                dmg:SetDamagePosition(targetPos)
                dmg:SetDamageForce(Vector(1, 0, 0) * chainDamage * 100)  -- Add force
                
                print(string.format("[TDMRP ChainLightning] Applying %.1f damage to %s", chainDamage, targetName))
                
                -- Try both methods
                local damageApplied = false
                if target.TakeDamageInfo then
                    print(string.format("[TDMRP ChainLightning] Using TakeDamageInfo() for %s", targetName))
                    pcall(function() target:TakeDamageInfo(dmg) damageApplied = true end)
                else
                    print(string.format("[TDMRP ChainLightning] Using TakeDamage() for %s", targetName))
                    pcall(function() target:TakeDamage(dmg) damageApplied = true end)
                end
                
                -- DEBUG: Check health after damage
                local healthAfter = target:Health()
                print(string.format("[TDMRP ChainLightning] Health AFTER: %s = %.1f (delta: %.1f)", targetName, healthAfter, healthBefore - healthAfter))
                
                if healthAfter >= healthBefore then
                    print(string.format("[TDMRP ChainLightning] WARNING: Damage did not apply to %s!", targetName))
                end
                
                -- Calculate upper chest position for damage number
                local damageNumberPos = bodyHitPos + Vector(0, 0, 10)  -- Slightly above hit position
                
                -- Send chain damage hitnumber
                if SERVER then
                    TDMRP_SendChainDamageNumber(attacker, target, chainDamage, damageNumberPos)
                end
                
                -- Play sound at body hit position
                sound.Play("npc/roller/charged_spin.wav", bodyHitPos, 75, 100)
                print(string.format("[TDMRP ChainLightning] Played arc sound at %s", targetName))
                
                -- Send chain beam to all clients (use randomized body hit position)
                net.Start("TDMRP_ChainBeam")
                    net.WriteVector(hitPos)
                    net.WriteVector(bodyHitPos)  -- Use randomized body position
                    net.WriteFloat(0.25)  -- 0.25s lifespan for chain arcs
                net.Broadcast()
                
                print(string.format("[TDMRP ChainLightning] Sent chain beam to %s", targetName))
                
                chainsApplied = chainsApplied + 1
            end
            
            print(string.format("[TDMRP ChainLightning] === COMPLETE === Applied %d chains ===", chainsApplied))
        end,
    },
}

print("[TDMRP GemCraft] Gem definitions loaded. Prefixes: " .. table.Count(TDMRP.Gems.Prefixes) .. " (shared), Suffixes: " .. table.Count(TDMRP.Gems.Suffixes) .. " (unified tier)")
