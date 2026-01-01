-- sv_tdmrp_shatter.lua
-- Server-side shatter projectile spawning system

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.Shatter = TDMRP.Shatter or {}

-- Network string for explosion effect
util.AddNetworkString("TDMRP_ShatterExplosion")

-- Spawn a shatter rock projectile
function TDMRP.Shatter.SpawnProjectile(owner, weapon, muzzlePos, direction, baseDamage)
    if not IsValid(owner) then return nil end
    if not IsValid(weapon) then return nil end
    
    local rock = ents.Create("sent_tdmrp_shatter_rock")
    if not IsValid(rock) then 
        print("[TDMRP Shatter] ERROR: Failed to create sent_tdmrp_shatter_rock entity")
        return nil 
    end
    
    rock:SetPos(muzzlePos)
    rock:SetAngles(direction:Angle())
    rock:SetOwnerPlayer(owner)
    rock:SetOwnerWeapon(weapon)
    rock:SetBaseDamage(baseDamage)
    rock:SetStartPos(muzzlePos)
    rock:Spawn()
    rock:Activate()
    
    -- Set projectile velocity
    rock:SetProjectileVelocity(direction)
    
    return rock
end

-- Fire shatter projectile(s) from weapon
function TDMRP.Shatter.FireFromWeapon(wep)
    if not IsValid(wep) then 
        print("[TDMRP Shatter] FireFromWeapon: Invalid weapon")
        return 
    end
    
    local owner = wep:GetOwner()
    if not IsValid(owner) then 
        print("[TDMRP Shatter] FireFromWeapon: Invalid owner")
        return 
    end
    
    print("[TDMRP Shatter] Firing projectile from " .. wep:GetClass())
    
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
    
    -- Play ORIGINAL gun sound first (base weapon sound)
    if wep.Primary and wep.Primary.Sound then
        wep:EmitSound(wep.Primary.Sound, 75, math.random(98, 102), 0.9)
    elseif wep.ShootSound then
        wep:EmitSound(wep.ShootSound, 75, math.random(98, 102), 0.9)
    end
    
    -- Layer the shatter rock sound using sound.Play for reliability
    local fireSounds = {
        "tdmrp/suffixsounds/ofshatter1.mp3",
        "tdmrp/suffixsounds/ofshatter2.mp3"
    }
    local chosenSound = fireSounds[math.random(1, 2)]
    sound.Play(chosenSound, owner:GetPos(), 85, math.random(95, 105), 1.0)
    
    if isShotgun then
        -- Spawn multiple rocks for shotgun
        local spreadBase = wep.Primary and wep.Primary.Spread or 0.05
        
        for i = 1, numPellets do
            -- Calculate spread for each pellet
            local spreadX = math.Rand(-spreadBase, spreadBase) * 2
            local spreadY = math.Rand(-spreadBase, spreadBase) * 2
            
            local aimDir = owner:GetAimVector()
            local right = aimDir:Angle():Right()
            local up = aimDir:Angle():Up()
            
            local spreadDir = (aimDir + right * spreadX + up * spreadY):GetNormalized()
            
            -- Shotgun pellet damage is divided
            local pelletDamage = baseDamage / numPellets * 1.5  -- Slight bonus for pellets
            
            TDMRP.Shatter.SpawnProjectile(owner, wep, muzzlePos, spreadDir, pelletDamage)
        end
    else
        -- Single projectile for rifles/pistols
        local aimDir = owner:GetAimVector()
        
        -- Apply weapon spread
        local spread = wep.Primary and wep.Primary.Spread or 0.01
        local spreadX = math.Rand(-spread, spread)
        local spreadY = math.Rand(-spread, spread)
        
        local right = aimDir:Angle():Right()
        local up = aimDir:Angle():Up()
        local finalDir = (aimDir + right * spreadX + up * spreadY):GetNormalized()
        
        TDMRP.Shatter.SpawnProjectile(owner, wep, muzzlePos, finalDir, baseDamage)
    end
end

print("[TDMRP] sv_tdmrp_shatter.lua loaded - Shatter projectile system ready")
