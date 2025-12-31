-- sent_tdmrp_homing_dart/init.lua
-- Homing suffix projectile - server-side logic

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    -- Use a small invisible physics object
    self:SetModel("models/hunter/plates/plate.mdl")
    self:SetModelScale(0.1)
    self:SetNoDraw(true)  -- We draw custom visuals client-side
    
    self:PhysicsInitSphere(4, "metal")
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(1)
        phys:EnableGravity(false)
        phys:SetDragCoefficient(0)
        phys:EnableCollisions(true)
    end
    
    self.SpawnTime = CurTime()
    self.HasHit = false
    self.CurrentSpeed = self.ProjectileSpeed
    self.FlightDirection = Vector(0, 0, 0)
    self.LastScanTime = 0
    self.ScanInterval = 0.1  -- Scan every 0.1 seconds
    
    -- Start scanning sound (looping)
    self.ScanSound = CreateSound(self, "npc/manhack/mh_engine_loop1.wav")
    if self.ScanSound then
        self.ScanSound:SetSoundLevel(60)
        self.ScanSound:Play()
    end
end

function ENT:SetProjectileVelocity(direction)
    self.FlightDirection = direction:GetNormalized()
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(self.FlightDirection * self.CurrentSpeed)
    end
end

function ENT:Think()
    -- Check lifetime
    if CurTime() - self.SpawnTime > self.LifeTime then
        self:Remove()
        return
    end
    
    local owner = self:GetOwnerPlayer()
    local currentTarget = self:GetLockedTarget()
    
    -- If we have a locked target, home in on it
    if IsValid(currentTarget) then
        self:HomeTowardTarget(currentTarget)
    else
        -- Scan for new targets periodically
        if CurTime() - self.LastScanTime > self.ScanInterval then
            self.LastScanTime = CurTime()
            self:ScanForTargets()
        end
    end
    
    -- Update velocity
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(self.FlightDirection * self.CurrentSpeed)
    end
    
    self:NextThink(CurTime())
    return true
end

function ENT:ScanForTargets()
    local owner = self:GetOwnerPlayer()
    if not IsValid(owner) then return end
    
    local myPos = self:GetPos()
    local myDir = self.FlightDirection
    local halfAngle = math.rad(self.ScanAngle / 2)
    
    local bestTarget = nil
    local bestDist = self.ScanRange + 1
    
    -- Find all potential targets
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        if ply == owner then continue end
        if not ply:Alive() then continue end
        
        -- Team check
        if ply:Team() == owner:Team() then continue end
        
        local targetPos = ply:GetPos() + Vector(0, 0, 40)  -- Aim at chest
        local toTarget = targetPos - myPos
        local dist = toTarget:Length()
        
        -- Check if within range
        if dist > self.ScanRange then continue end
        
        -- Check if within cone angle
        local dirToTarget = toTarget:GetNormalized()
        local dotProduct = myDir:Dot(dirToTarget)
        local angleToTarget = math.acos(math.Clamp(dotProduct, -1, 1))
        
        if angleToTarget > halfAngle then continue end
        
        -- Check line of sight
        local tr = util.TraceLine({
            start = myPos,
            endpos = targetPos,
            filter = {self, owner},
            mask = MASK_SHOT
        })
        
        if tr.Entity ~= ply and tr.Hit then continue end
        
        -- This target is valid, check if it's the closest
        if dist < bestDist then
            bestDist = dist
            bestTarget = ply
        end
    end
    
    -- Lock onto best target
    if IsValid(bestTarget) then
        self:LockOnTarget(bestTarget)
    end
end

function ENT:LockOnTarget(target)
    self:SetLockedTarget(target)
    self:SetIsLocked(true)
    
    -- Stop scan sound, play lock-on sound
    if self.ScanSound then
        self.ScanSound:Stop()
    end
    
    -- Play blade snick sound
    self:EmitSound("npc/manhack/mh_blade_snick1.wav", 75, math.random(95, 105), 1.0)
    
    -- Boost speed
    self.CurrentSpeed = self.LockedSpeed
    
    print("[TDMRP Homing] Locked onto " .. target:Nick())
end

function ENT:HomeTowardTarget(target)
    if not IsValid(target) or not target:Alive() then
        -- Target lost, clear and rescan
        self:SetLockedTarget(NULL)
        self:SetIsLocked(false)
        self.CurrentSpeed = self.ProjectileSpeed
        
        -- Restart scan sound
        if self.ScanSound then
            self.ScanSound:Play()
        end
        return
    end
    
    local myPos = self:GetPos()
    local targetPos = target:GetPos() + Vector(0, 0, 40)  -- Aim at chest
    local toTarget = (targetPos - myPos):GetNormalized()
    
    -- Smoothly turn toward target
    local lerpFactor = self.HomingStrength * FrameTime()
    self.FlightDirection = LerpVector(lerpFactor, self.FlightDirection, toTarget):GetNormalized()
end

function ENT:PhysicsCollide(data, phys)
    if self.HasHit then return end
    self.HasHit = true
    
    local hitPos = data.HitPos
    local hitEntity = data.HitEntity
    local owner = self:GetOwnerPlayer()
    local weapon = self:GetOwnerWeapon()
    local baseDamage = self:GetBaseDamage()
    
    -- Stop sounds
    if self.ScanSound then
        self.ScanSound:Stop()
    end
    
    -- Deal damage
    self:DealDamage(hitPos, hitEntity, owner, weapon, baseDamage)
    
    self:Remove()
end

function ENT:DealDamage(pos, hitEntity, attacker, weapon, baseDamage)
    if not IsValid(attacker) then return end
    
    -- Play impact sound (grind flesh)
    local impactSounds = {
        "npc/manhack/grind_flesh1.wav",
        "npc/manhack/grind_flesh2.wav"
    }
    sound.Play(impactSounds[math.random(1, 2)], pos, 75, math.random(95, 105), 1.0)
    
    -- Send impact effect to clients
    net.Start("TDMRP_HomingImpact")
        net.WriteVector(pos)
    net.Broadcast()
    
    -- Deal damage to hit entity
    if IsValid(hitEntity) and (hitEntity:IsPlayer() or hitEntity:IsNPC()) then
        -- Team check for players
        if hitEntity:IsPlayer() and hitEntity:Team() == attacker:Team() then return end
        
        local dmgInfo = DamageInfo()
        dmgInfo:SetDamage(baseDamage)
        dmgInfo:SetAttacker(attacker)
        dmgInfo:SetInflictor(IsValid(weapon) and weapon or attacker)
        dmgInfo:SetDamageType(DMG_SLASH)
        dmgInfo:SetDamagePosition(pos)
        
        hitEntity:TakeDamageInfo(dmgInfo)
    end
end

function ENT:OnRemove()
    -- Stop sounds
    if self.ScanSound then
        self.ScanSound:Stop()
    end
end
