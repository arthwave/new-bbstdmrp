-- sv_tdmrp_venom.lua
-- Server-side venom projectile spawning and poison DoT system

if not SERVER then return end

print("[TDMRP] sv_tdmrp_venom.lua LOADING...")

TDMRP = TDMRP or {}
TDMRP.Venom = TDMRP.Venom or {}

-- Config
TDMRP.Venom.MaxStacks = 3
TDMRP.Venom.DamagePerStack = 5
TDMRP.Venom.Duration = 5
TDMRP.Venom.TickInterval = 1

-- Network strings
util.AddNetworkString("TDMRP_VenomImpact")
util.AddNetworkString("TDMRP_VenomStatus")

-- Pain sounds (alternating)
local painSounds = {
    "ambient/levels/canals/toxic_slime_sizzle3.wav",
    "ambient/levels/canals/toxic_slime_sizzle4.wav"
}

-- Track poisoned entities
TDMRP.Venom.Poisoned = TDMRP.Venom.Poisoned or {}

-- Apply poison to target
function TDMRP.Venom.ApplyPoison(target, attacker, weapon)
    if not IsValid(target) then return end
    
    local targetID = target:IsPlayer() and target:SteamID64() or target:EntIndex()
    
    local poisonData = TDMRP.Venom.Poisoned[targetID] or {
        target = target,
        attacker = attacker,
        weapon = weapon,
        stacks = 0,
        expire = 0,
        lastTick = 0,
        soundIndex = 1
    }
    
    -- Add stack (max 3)
    poisonData.stacks = math.min(poisonData.stacks + 1, TDMRP.Venom.MaxStacks)
    poisonData.expire = CurTime() + TDMRP.Venom.Duration
    poisonData.attacker = attacker  -- Update attacker to most recent
    poisonData.weapon = weapon
    
    TDMRP.Venom.Poisoned[targetID] = poisonData
    
    -- Sync to client
    TDMRP.Venom.SyncPoisonStatus(target, poisonData.stacks, poisonData.expire)
    
    print("[TDMRP Venom] Applied poison to " .. tostring(target) .. " - Stacks: " .. poisonData.stacks)
end

-- Sync poison status to client for vignette
function TDMRP.Venom.SyncPoisonStatus(target, stacks, expire)
    if not IsValid(target) or not target:IsPlayer() then return end
    
    net.Start("TDMRP_VenomStatus")
        net.WriteUInt(stacks, 4)
        net.WriteFloat(expire)
    net.Send(target)
end

-- Spawn a venom dart projectile
function TDMRP.Venom.SpawnProjectile(owner, weapon, muzzlePos, direction, baseDamage)
    if not IsValid(owner) then return nil end
    if not IsValid(weapon) then return nil end
    
    local dart = ents.Create("sent_tdmrp_venom_dart")
    if not IsValid(dart) then 
        print("[TDMRP Venom] ERROR: Failed to create sent_tdmrp_venom_dart entity")
        return nil 
    end
    
    dart:SetPos(muzzlePos)
    dart:SetAngles(direction:Angle())
    dart:SetOwnerPlayer(owner)
    dart:SetOwnerWeapon(weapon)
    dart:SetBaseDamage(baseDamage)
    dart:SetStartPos(muzzlePos)
    dart:Spawn()
    dart:Activate()
    
    dart:SetProjectileVelocity(direction)
    
    return dart
end

-- Fire venom dart(s) from weapon
function TDMRP.Venom.FireFromWeapon(wep)
    if not IsValid(wep) then return end
    
    local owner = wep:GetOwner()
    if not IsValid(owner) then return end
    
    -- Get muzzle position
    local muzzleAttachment = wep:LookupAttachment("muzzle")
    local muzzlePos = owner:GetShootPos()
    
    if muzzleAttachment and muzzleAttachment > 0 then
        local attachData = wep:GetAttachment(muzzleAttachment)
        if attachData then
            muzzlePos = attachData.Pos
        end
    end
    
    -- Get base damage from weapon
    local baseDamage = wep.Primary and wep.Primary.Damage or 30
    
    -- Check if shotgun (multiple pellets)
    local numPellets = wep.Primary and wep.Primary.NumShots or 1
    local isShotgun = numPellets and numPellets > 1
    
    -- Play ORIGINAL gun sound first (M9K already plays this, but ensure it plays)
    if wep.Primary and wep.Primary.Sound then
        wep:EmitSound(wep.Primary.Sound, 75, math.random(98, 102), 0.9)
    elseif wep.ShootSound then
        wep:EmitSound(wep.ShootSound, 75, math.random(98, 102), 0.9)
    end
    
    -- Layer the venom dart sound using sound.Play for reliability
    sound.Play("weapons/crossbow/bolt_fly4.wav", owner:GetPos(), 85, math.random(90, 110), 1.0)
    
    if isShotgun then
        local dartCount = numPellets
        local spreadBase = wep.Primary and wep.Primary.Spread or 0.05
        
        for i = 1, dartCount do
            local spreadX = math.Rand(-spreadBase, spreadBase)
            local spreadY = math.Rand(-spreadBase, spreadBase)
            
            local aimDir = owner:GetAimVector()
            local right = aimDir:Angle():Right()
            local up = aimDir:Angle():Up()
            
            local spreadDir = (aimDir + right * spreadX + up * spreadY):GetNormalized()
            local dartDamage = baseDamage / dartCount * 1.2
            
            TDMRP.Venom.SpawnProjectile(owner, wep, muzzlePos, spreadDir, dartDamage)
        end
    else
        local aimDir = owner:GetAimVector()
        local spread = 0.003
        local spreadX = math.Rand(-spread, spread)
        local spreadY = math.Rand(-spread, spread)
        
        local right = aimDir:Angle():Right()
        local up = aimDir:Angle():Up()
        local finalDir = (aimDir + right * spreadX + up * spreadY):GetNormalized()
        
        TDMRP.Venom.SpawnProjectile(owner, wep, muzzlePos, finalDir, baseDamage)
    end
end

-- Poison tick processing
local function ProcessPoisonTicks()
    local currentTime = CurTime()
    
    for targetID, data in pairs(TDMRP.Venom.Poisoned) do
        local target = data.target
        
        -- Check if expired or target invalid
        if not IsValid(target) or currentTime > data.expire then
            -- Clear poison
            if IsValid(target) and target:IsPlayer() then
                TDMRP.Venom.SyncPoisonStatus(target, 0, 0)
            end
            TDMRP.Venom.Poisoned[targetID] = nil
            continue
        end
        
        -- Check if player is alive
        if target:IsPlayer() and not target:Alive() then
            TDMRP.Venom.SyncPoisonStatus(target, 0, 0)
            TDMRP.Venom.Poisoned[targetID] = nil
            continue
        end
        
        -- Check if NPC is alive
        if target:IsNPC() and target:Health() <= 0 then
            TDMRP.Venom.Poisoned[targetID] = nil
            continue
        end
        
        -- Process tick if interval passed
        if currentTime - data.lastTick >= TDMRP.Venom.TickInterval then
            data.lastTick = currentTime
            
            -- Calculate damage (bypasses armor - true damage)
            local tickDamage = TDMRP.Venom.DamagePerStack * data.stacks
            
            -- Apply damage directly to health (bypassing armor)
            if target:IsPlayer() then
                target:SetHealth(math.max(0, target:Health() - tickDamage))
                
                -- Check for death
                if target:Health() <= 0 then
                    -- Kill with proper attacker credit
                    local dmgInfo = DamageInfo()
                    dmgInfo:SetDamage(1)
                    dmgInfo:SetAttacker(IsValid(data.attacker) and data.attacker or target)
                    dmgInfo:SetInflictor(IsValid(data.weapon) and data.weapon or target)
                    dmgInfo:SetDamageType(DMG_POISON)
                    target:TakeDamageInfo(dmgInfo)
                end
            else
                -- NPCs take normal damage
                local dmgInfo = DamageInfo()
                dmgInfo:SetDamage(tickDamage)
                dmgInfo:SetAttacker(IsValid(data.attacker) and data.attacker or game.GetWorld())
                dmgInfo:SetInflictor(IsValid(data.weapon) and data.weapon or game.GetWorld())
                dmgInfo:SetDamageType(DMG_POISON)
                target:TakeDamageInfo(dmgInfo)
            end
            
            -- Play pain sound (alternating)
            local soundPath = painSounds[data.soundIndex]
            sound.Play(soundPath, target:GetPos(), 70, math.random(95, 105), 0.8)
            data.soundIndex = (data.soundIndex % 2) + 1
            
            -- Spawn poison cloud on victim (visible to everyone)
            local effectPos = target:GetPos() + Vector(0, 0, 40)
            net.Start("TDMRP_VenomCloud")
                net.WriteVector(effectPos)
                net.WriteUInt(data.stacks, 4)
            net.Broadcast()
            
            print("[TDMRP Venom] Tick damage: " .. tickDamage .. " to " .. tostring(target) .. " (Stacks: " .. data.stacks .. ")")
        end
    end
end

-- Add network string for cloud effect
util.AddNetworkString("TDMRP_VenomCloud")

-- Run poison tick processor
timer.Create("TDMRP_VenomTickProcessor", 0.1, 0, ProcessPoisonTicks)

-- Clean up on player disconnect
hook.Add("PlayerDisconnected", "TDMRP_VenomCleanup", function(ply)
    local steamID = ply:SteamID64()
    if TDMRP.Venom.Poisoned[steamID] then
        TDMRP.Venom.Poisoned[steamID] = nil
    end
end)

-- Clean up on death
hook.Add("PlayerDeath", "TDMRP_VenomDeathCleanup", function(victim, inflictor, attacker)
    local steamID = victim:SteamID64()
    if TDMRP.Venom.Poisoned[steamID] then
        TDMRP.Venom.Poisoned[steamID] = nil
        TDMRP.Venom.SyncPoisonStatus(victim, 0, 0)
    end
end)

print("[TDMRP] sv_tdmrp_venom.lua loaded - Venom projectile and poison DoT system ready")
