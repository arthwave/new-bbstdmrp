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

    of_Momentum = {
        name = "of Momentum",
        effect = "momentum",
        description = "Each shot pushes enemies backward with explosive force",
        stats = {
            damage = 0.05,       -- Slight damage boost
            handling = -0.20,    -- Reduced handling (heavy weapon)
            rpm = -0.10,         -- Slightly slower fire rate
        },
        material = "Models/effects/comball_tape",  -- Energy/explosive material
        ammoCost = 1,           -- Normal ammo cost
        
        -- Hook: Play layered fire sound
        OnPreFire = function(wep)
            if SERVER then
                local owner = wep:GetOwner()
                if IsValid(owner) then
                    sound.Play("tdmrp/suffixsounds/ofmomentum.mp3", owner:GetPos(), 80, math.random(95, 105), 0.9)
                end
            end
        end,
        
        -- Hook: Apply knockback on hit
        OnBulletHit = function(wep, tr, dmginfo)
            if not SERVER then return end
            
            local hitEntity = tr.Entity
            if not IsValid(hitEntity) then return end
            
            -- Only knock back entities that can be pushed
            if not (hitEntity:IsPlayer() or hitEntity:IsNPC() or hitEntity:GetPhysicsObject()) then
                return
            end
            
            -- Calculate knockback direction (from weapon to target)
            local owner = wep:GetOwner()
            if not IsValid(owner) then return end
            
            local knockbackDir = (tr.HitPos - owner:GetPos()):GetNormalized()
            local knockbackForce = 500  -- Moderate knockback
            
            -- Apply knockback
            if hitEntity:IsPlayer() or hitEntity:IsNPC() then
                -- For players/NPCs, use velocity
                local vel = hitEntity:GetVelocity()
                hitEntity:SetVelocity(vel + knockbackDir * knockbackForce)
            else
                -- For physics objects, use physics
                local phys = hitEntity:GetPhysicsObject()
                if IsValid(phys) then
                    phys:ApplyForceCenter(knockbackDir * knockbackForce * phys:GetMass())
                end
            end
            
            -- Play impact sound locally at hit position
            local hitPos = tr.HitPos
            sound.Play("tdmrp/suffixsounds/ofmomentum.mp3", hitPos, 80, 100, 1.0)
            
            -- Also play sound locally to the weapon owner for hit confirmation
            if IsValid(owner) and owner:IsPlayer() then
                owner:EmitSound("tdmrp/suffixsounds/ofmomentum.mp3", 75, 100, 0.7)
            end
        end,
    },
    
    of_Frost = {
        name = "of Frost",
        effect = "frost",
        description = "Slows enemies with icy ammunition. Kills explode in frozen shards.",
        stats = {
            damage = -0.15,      -- Slight damage penalty
            rpm = -0.35,         -- 35% fire rate reduction (deliberate shots)
            recoil = -0.10,      -- Slight recoil reduction (precision weapon)
            handling = 0.05,     -- Tiny handling boost (counter slowness)
        },
        material = "models/props_combine/combine_interface_disp",  -- Ice-like material
        ammoCost = 1,           -- Normal ammo cost
        
        -- Frost-specific config
        maxSlowLevel = 50,      -- 50% movement speed reduction cap
        slowPerHit = 12.5,      -- 12.5% per bullet hit
        slowDuration = 4,       -- 4 seconds before slow decays
        explosionRadius = 100,
        explosionDamage = 25,
        
        -- Emit Frost sound as a layer (plays on top of default weapon sound)
        -- NOTE: Use sound.Play() at player position instead of wep:EmitSound() to avoid audio clipping issues
        OnPreFire = function(wep)
            if SERVER then
                local owner = wep:GetOwner()
                if not IsValid(owner) then return end
                
                if not wep.TDMRP_FrostSoundIndex then
                    wep.TDMRP_FrostSoundIndex = 0
                end
                wep.TDMRP_FrostSoundIndex = (wep.TDMRP_FrostSoundIndex % 3) + 1
                local soundIdx = wep.TDMRP_FrostSoundIndex
                local frostSound = "tdmrp/suffixsounds/offrost" .. soundIdx .. ".mp3"
                
                -- Use sound.Play at player position for reliable layered audio
                sound.Play(frostSound, owner:GetPos(), 85, 100, 1.0)
            end
        end,
        
        -- Hook: Send icicle beam(s) to all clients (muzzle to impact)
        -- For shotguns, spawn multiple beams (one per pellet)
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
                
                -- Determine if shotgun (check class or Primary.NumShots)
                local numPellets = wep.Primary and wep.Primary.NumShots or 1
                local isShotgun = numPellets and numPellets > 1
                
                -- Trace to get impact point(s)
                local baseTrace = util.QuickTrace(owner:EyePos(), owner:GetAimVector() * 10000, owner)
                
                if isShotgun then
                    -- Send multiple beams for shotgun pellets (spread pattern)
                    for i = 1, math.min(numPellets, 8) do  -- Cap at 8 visual beams to avoid network spam
                        -- Calculate spread offset for each pellet
                        local angleOffset = ((i - 1) / math.max(1, numPellets - 1)) * math.pi * 2
                        local spreadAmount = 0.15  -- 15% spread variation
                        local offsetAngle = AngleRand()
                        offsetAngle:RotateAroundAxis(owner:GetAimVector(), angleOffset)
                        
                        local spreadDir = owner:GetAimVector() + offsetAngle:Forward() * spreadAmount
                        local tr = util.QuickTrace(owner:EyePos(), spreadDir * 10000, owner)
                        
                        net.Start("TDMRP_FrostBeam")
                            net.WriteVector(muzzlePos)
                            net.WriteVector(tr.HitPos)
                            net.WriteFloat(0.15)
                        net.Broadcast()
                    end
                else
                    -- Single beam for rifles/pistols
                    net.Start("TDMRP_FrostBeam")
                        net.WriteVector(muzzlePos)
                        net.WriteVector(baseTrace.HitPos)
                        net.WriteFloat(0.15)  -- 0.15s lifespan (shorter, colder feel)
                    net.Broadcast()
                end
            end
        end,
        
        -- Hook: Apply slow on bullet hit
        OnBulletHit = function(wep, tr, dmginfo)
            if not IsValid(wep) or not SERVER then return end
            
            local hitPos = tr.HitPos
            local hitEntity = tr.Entity
            local attacker = wep:GetOwner()
            
            if not IsValid(attacker) or not IsValid(hitEntity) then return end
            
            -- Only apply slow to players and NPCs
            if hitEntity:IsPlayer() or hitEntity:IsNPC() then
                -- Trigger server-side frost effect handler
                TDMRP_ApplyFrostSlow(hitEntity, attacker, wep)
            end
            
            -- Play alternating frost hit sound (round-robin)
            if not wep.TDMRP_FrostSoundIndex then
                wep.TDMRP_FrostSoundIndex = 0
            end
            wep.TDMRP_FrostSoundIndex = (wep.TDMRP_FrostSoundIndex % 3) + 1
            local soundFile = "tdmrp/suffixsounds/offrost" .. wep.TDMRP_FrostSoundIndex .. ".mp3"
            sound.Play(soundFile, hitPos, 75, 100)
        end,
        
        -- Hook: Detect Frost weapon kills
        OnPlayerDeath = function(victim, attacker, weapon)
            if not SERVER then return end
            if not IsValid(attacker) or not IsValid(victim) then return end
            if not IsValid(weapon) then return end
            
            -- Check if killer has a Frost weapon and it was used in the kill
            local suffixId = weapon:GetNWString("TDMRP_SuffixID", "")
            if suffixId ~= "of_Frost" then return end
            
            -- Trigger frost death explosion
            TDMRP_FrostDeathExplosion(victim, attacker, weapon)
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
        
        -- Hook: Send initial shot beam(s) to all clients
        -- For shotguns, spawn multiple beams (one per pellet)
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
                
                -- Determine if shotgun (check class or Primary.NumShots)
                local numPellets = wep.Primary and wep.Primary.NumShots or 1
                local isShotgun = numPellets and numPellets > 1
                
                -- Trace to get impact point(s)
                local baseTrace = util.QuickTrace(owner:EyePos(), owner:GetAimVector() * 10000, owner)
                
                if isShotgun then
                    -- Send multiple beams for shotgun pellets (spread pattern)
                    for i = 1, math.min(numPellets, 8) do  -- Cap at 8 visual beams to avoid network spam
                        -- Calculate spread offset for each pellet
                        local angleOffset = ((i - 1) / math.max(1, numPellets - 1)) * math.pi * 2
                        local spreadAmount = 0.15  -- 15% spread variation
                        local offsetAngle = AngleRand()
                        offsetAngle:RotateAroundAxis(owner:GetAimVector(), angleOffset)
                        
                        local spreadDir = owner:GetAimVector() + offsetAngle:Forward() * spreadAmount
                        local tr = util.QuickTrace(owner:EyePos(), spreadDir * 10000, owner)
                        
                        net.Start("TDMRP_ChainBeam")
                            net.WriteVector(muzzlePos)
                            net.WriteVector(tr.HitPos)
                            net.WriteFloat(0.2)  -- 0.2s lifespan
                        net.Broadcast()
                    end
                else
                    -- Single beam for rifles/pistols
                    net.Start("TDMRP_ChainBeam")
                        net.WriteVector(muzzlePos)
                        net.WriteVector(baseTrace.HitPos)
                        net.WriteFloat(0.2)  -- 0.2s lifespan
                    net.Broadcast()
                end
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
    
    of_Shatter = {
        name = "of Shatter",
        effect = "shatter",
        description = "Fires explosive rock projectiles that shatter on impact",
        stats = {
            damage = -0.20,      -- 20% damage reduction (balanced by AOE)
            rpm = -0.30,         -- 30% fire rate reduction (projectile weapon)
            recoil = 0.20,       -- 20% more recoil
            handling = -0.10,    -- Slight handling penalty
        },
        material = "phoenix_storms/thruster",
        ammoCost = 1,
        
        -- Flag to indicate this suffix uses projectile instead of hitscan
        projectileWeapon = true,
        
        -- Hook: Fire projectile instead of bullet
        OnPreFire = function(wep)
            -- Mark that we should block the hitscan bullet
            wep.TDMRP_BlockHitscan = true
        end,
        
        -- Hook: Spawn rock projectile (called after bullet would fire)
        OnBulletFired = function(wep)
            if SERVER and TDMRP and TDMRP.Shatter then
                -- Fire the shatter projectile(s)
                TDMRP.Shatter.FireFromWeapon(wep)
            end
        end,
        
        -- Reset hitscan block after firing
        OnPostFire = function(wep)
            wep.TDMRP_BlockHitscan = false
        end,
    },
    
    of_Homing = {
        name = "of Homing",
        effect = "homing",
        description = "Fires homing darts that seek out enemies",
        stats = {
            damage = -0.15,
            rpm = -0.25,
            handling = -0.10,
        },
        material = "phoenix_storms/top",
        ammoCost = 1,
        projectileWeapon = true,
        OnPreFire = function(wep)
            wep.TDMRP_BlockHitscan = true
            print("[TDMRP Homing] OnPreFire - BlockHitscan set to true")
        end,
        OnBulletFired = function(wep)
            print("[TDMRP Homing] OnBulletFired called, SERVER=" .. tostring(SERVER))
            if SERVER then
                if TDMRP and TDMRP.Homing and TDMRP.Homing.FireFromWeapon then
                    print("[TDMRP Homing] Calling FireFromWeapon")
                    TDMRP.Homing.FireFromWeapon(wep)
                else
                    print("[TDMRP Homing] ERROR: TDMRP.Homing.FireFromWeapon not found!")
                    print("[TDMRP Homing] TDMRP exists: " .. tostring(TDMRP ~= nil))
                    print("[TDMRP Homing] TDMRP.Homing exists: " .. tostring(TDMRP and TDMRP.Homing ~= nil))
                end
            end
        end,
        OnPostFire = function(wep)
            wep.TDMRP_BlockHitscan = false
        end,
    },
    
    of_Venom = {
        name = "of Venom",
        effect = "venom",
        description = "Fires poison darts that stack venom DoT (5 dmg/tick, max 3 stacks, 5s duration)",
        stats = {
            damage = -0.35,
            handling = -0.05,
        },
        material = "phoenix_storms/pack2/interior_sides",
        projectileWeapon = true,
        OnPreFire = function(wep)
            wep.TDMRP_BlockHitscan = true
        end,
        OnBulletFired = function(wep)
            if SERVER then
                if TDMRP and TDMRP.Venom and TDMRP.Venom.FireFromWeapon then
                    TDMRP.Venom.FireFromWeapon(wep)
                end
            end
        end,
        OnPostFire = function(wep)
            wep.TDMRP_BlockHitscan = false
        end,
    },
    
    of_Chrome = {
        name = "of Chrome",
        effect = "chrome",
        description = "Deals % of target's max health as damage. Ignores headshots, DT reduced by 50%.",
        stats = {
            -- No base stat changes - damage is recalculated as % HP
            rpm = -0.10,        -- Slight RPM reduction
            handling = -0.05,   -- Minor handling penalty
        },
        material = "phoenix_storms/mat/mat_phx_metallic",
        isChrome = true,  -- Flag for HUD to show % HP damage
        
        -- Chrome tier scaling multipliers
        tierScaling = {
            [1] = 0.90,   -- Common: 90%
            [2] = 0.95,   -- Uncommon: 95%
            [3] = 1.00,   -- Rare: 100% (baseline)
            [4] = 1.10,   -- Legendary: 110%
            [5] = 1.15,   -- Unique: 115%
        },
        
        -- Shotgun buckshot falloff config
        buckshotFalloffStart = 100,   -- Full damage up to 100 units
        buckshotFalloffEnd = 200,     -- Reduced to 25% at 200+ units
        buckshotFalloffMin = 0.25,    -- Minimum 25% damage beyond falloff
        
        -- Play Chrome sound on fire with ±10% pitch variance
        OnPreFire = function(wep)
            if SERVER then
                local owner = wep:GetOwner()
                if not IsValid(owner) then return end
                
                local pitch = 100 + math.random(-10, 10)
                sound.Play("tdmrp/suffixsounds/ofchrome1.mp3", owner:GetPos(), 85, pitch, 1.0)
            end
        end,
        
        -- Override damage calculation on bullet hit
        OnBulletHit = function(wep, tr, dmginfo)
            if not SERVER then return end
            
            local target = tr.Entity
            if not IsValid(target) then return end
            if not (target:IsPlayer() or target:IsNPC()) then return end
            
            local owner = wep:GetOwner()
            if not IsValid(owner) then return end
            
            -- Team check for players
            if target:IsPlayer() and target:Team() == owner:Team() then return end
            
            -- Get target's max health (cap NPCs at 200)
            local maxHP = target:GetMaxHealth()
            if target:IsNPC() then
                maxHP = math.min(maxHP, 200)
            end
            
            -- Get weapon's current damage (includes prefix modifiers)
            local baseDamage = dmginfo:GetDamage()
            
            -- Calculate % HP damage (damage / 2 = % of max HP)
            local percentHP = baseDamage / 2
            
            -- Get tier scaling
            local tier = wep:GetNWInt("TDMRP_Tier", 1)
            local suffix = TDMRP.Gems.Suffixes.of_Chrome
            local tierMult = suffix.tierScaling[tier] or 1.0
            
            -- Apply tier scaling
            percentHP = percentHP * tierMult
            
            -- Check if shotgun buckshot mode for falloff
            local numShots = wep.Primary and wep.Primary.NumShots or 1
            local shotgunMode = wep:GetNWInt("TDMRP_ShotgunMode", 0)
            local isBuckshot = numShots > 1 and shotgunMode ~= 1
            
            if isBuckshot then
                -- Apply shotgun buckshot falloff
                local distance = tr.StartPos:Distance(tr.HitPos)
                local falloffMult = 1.0
                
                if distance > suffix.buckshotFalloffStart then
                    if distance >= suffix.buckshotFalloffEnd then
                        falloffMult = suffix.buckshotFalloffMin
                    else
                        -- Gradual falloff between 100-200 units
                        local falloffRange = suffix.buckshotFalloffEnd - suffix.buckshotFalloffStart
                        local falloffProgress = (distance - suffix.buckshotFalloffStart) / falloffRange
                        falloffMult = 1.0 - (falloffProgress * (1.0 - suffix.buckshotFalloffMin))
                    end
                end
                
                percentHP = percentHP * falloffMult
            end
            
            -- Calculate final damage
            local finalDamage = maxHP * (percentHP / 100)
            
            -- Apply DT reduction (Chrome reduces DT effectiveness by 50%)
            -- We set the damage, and the DT system will process it later
            -- So we need to pre-compensate: if target has DT, we add 50% of what DT would block
            if target:IsPlayer() then
                local dt = target:GetNWInt("TDMRP_DT", 0)
                if dt > 0 then
                    -- DT normally blocks 'dt' damage flat
                    -- Chrome makes DT only 50% effective, so we add back 50% of blocked damage
                    local dtBlocked = math.min(dt, finalDamage)
                    local dtBypass = dtBlocked * 0.5
                    finalDamage = finalDamage + dtBypass
                end
            end
            
            -- Set the modified damage (ignores headshot multiplier by replacing damage entirely)
            dmginfo:SetDamage(finalDamage)
            dmginfo:SetDamageType(DMG_GENERIC)  -- Remove bullet type to avoid headshot bonus
        end,
    },
}

print("[TDMRP GemCraft] Gem definitions loaded. Prefixes: " .. table.Count(TDMRP.Gems.Prefixes) .. " (shared), Suffixes: " .. table.Count(TDMRP.Gems.Suffixes) .. " (unified tier)")
