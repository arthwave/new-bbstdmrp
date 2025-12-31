-- sv_tdmrp_homing.lua
-- Server-side homing projectile spawning system

if not SERVER then return end

print("[TDMRP] sv_tdmrp_homing.lua LOADING...")

TDMRP = TDMRP or {}
TDMRP.Homing = TDMRP.Homing or {}

-- Network string for impact effect
util.AddNetworkString("TDMRP_HomingImpact")

-- Spawn a homing dart projectile
function TDMRP.Homing.SpawnProjectile(owner, weapon, muzzlePos, direction, baseDamage)
    if not IsValid(owner) then return nil end
    if not IsValid(weapon) then return nil end
    
    local dart = ents.Create("sent_tdmrp_homing_dart")
    if not IsValid(dart) then 
        print("[TDMRP Homing] ERROR: Failed to create sent_tdmrp_homing_dart entity")
        return nil 
    end
    
    dart:SetPos(muzzlePos)
    dart:SetAngles(direction:Angle())
    dart:SetOwnerPlayer(owner)
    dart:SetOwnerWeapon(weapon)
    dart:SetBaseDamage(baseDamage)
    dart:SetStartPos(muzzlePos)
    dart:SetIsLocked(false)
    dart:Spawn()
    dart:Activate()
    
    -- Set projectile velocity
    dart:SetProjectileVelocity(direction)
    
    print("[TDMRP Homing] Spawned dart at " .. tostring(muzzlePos))
    
    return dart
end

-- Fire homing dart(s) from weapon
function TDMRP.Homing.FireFromWeapon(wep)
    if not IsValid(wep) then 
        print("[TDMRP Homing] FireFromWeapon: Invalid weapon")
        return 
    end
    
    local owner = wep:GetOwner()
    if not IsValid(owner) then 
        print("[TDMRP Homing] FireFromWeapon: Invalid owner")
        return 
    end
    
    print("[TDMRP Homing] Firing dart from " .. wep:GetClass())
    
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
    
    -- Play ORIGINAL gun sound first
    if wep.Primary and wep.Primary.Sound then
        wep:EmitSound(wep.Primary.Sound, 75, math.random(98, 102), 0.9)
    elseif wep.ShootSound then
        wep:EmitSound(wep.ShootSound, 75, math.random(98, 102), 0.9)
    end
    
    -- Layer the homing dart sound on top
    local fireSounds = {
        "tdmrp/suffixsounds/ofhoming1.mp3",
        "tdmrp/suffixsounds/ofhoming2.mp3"
    }
    wep:EmitSound(fireSounds[math.random(1, 2)], 80, math.random(95, 105), 1.0)
    
    if isShotgun then
        local dartCount = math.min(numPellets, 4)
        local spreadBase = wep.Primary and wep.Primary.Spread or 0.05
        
        for i = 1, dartCount do
            local spreadX = math.Rand(-spreadBase, spreadBase)
            local spreadY = math.Rand(-spreadBase, spreadBase)
            
            local aimDir = owner:GetAimVector()
            local right = aimDir:Angle():Right()
            local up = aimDir:Angle():Up()
            
            local spreadDir = (aimDir + right * spreadX + up * spreadY):GetNormalized()
            local dartDamage = baseDamage / dartCount * 1.2
            
            TDMRP.Homing.SpawnProjectile(owner, wep, muzzlePos, spreadDir, dartDamage)
        end
    else
        local aimDir = owner:GetAimVector()
        local spread = 0.005
        local spreadX = math.Rand(-spread, spread)
        local spreadY = math.Rand(-spread, spread)
        
        local right = aimDir:Angle():Right()
        local up = aimDir:Angle():Up()
        local finalDir = (aimDir + right * spreadX + up * spreadY):GetNormalized()
        
        TDMRP.Homing.SpawnProjectile(owner, wep, muzzlePos, finalDir, baseDamage)
    end
end

print("[TDMRP] sv_tdmrp_homing.lua loaded - Homing projectile system ready")
print("[TDMRP] TDMRP.Homing.FireFromWeapon exists: " .. tostring(TDMRP.Homing.FireFromWeapon ~= nil))
