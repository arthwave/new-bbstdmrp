AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/plates/plate.mdl")
    self:SetModelScale(0.1)
    self:SetNoDraw(true)
    
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
    self.ScanInterval = 0.1
    
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
    if CurTime() - self.SpawnTime > self.LifeTime then
        self:Remove()
        return
    end
    
    local currentTarget = self:GetLockedTarget()
    
    if IsValid(currentTarget) then
        self:HomeTowardTarget(currentTarget)
    else
        if CurTime() - self.LastScanTime > self.ScanInterval then
            self.LastScanTime = CurTime()
            self:ScanForTargets()
        end
    end
    
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
    
    -- Scan players
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        if ply == owner then continue end
        if not ply:Alive() then continue end
        if ply:Team() == owner:Team() then continue end
        
        local targetPos = ply:GetPos() + Vector(0, 0, 40)
        local toTarget = targetPos - myPos
        local dist = toTarget:Length()
        
        if dist > self.ScanRange then continue end
        
        local dirToTarget = toTarget:GetNormalized()
        local dotProduct = myDir:Dot(dirToTarget)
        local angleToTarget = math.acos(math.Clamp(dotProduct, -1, 1))
        
        if angleToTarget > halfAngle then continue end
        
        local tr = util.TraceLine({
            start = myPos,
            endpos = targetPos,
            filter = {self, owner},
            mask = MASK_SHOT
        })
        
        if tr.Entity ~= ply and tr.Hit then continue end
        
        if dist < bestDist then
            bestDist = dist
            bestTarget = ply
        end
    end
    
    -- Scan NPCs
    for _, npc in ipairs(ents.FindByClass("npc_*")) do
        if not IsValid(npc) then continue end
        if npc:Health() <= 0 then continue end
        
        local targetPos = npc:GetPos() + Vector(0, 0, 40)
        local toTarget = targetPos - myPos
        local dist = toTarget:Length()
        
        if dist > self.ScanRange then continue end
        
        local dirToTarget = toTarget:GetNormalized()
        local dotProduct = myDir:Dot(dirToTarget)
        local angleToTarget = math.acos(math.Clamp(dotProduct, -1, 1))
        
        if angleToTarget > halfAngle then continue end
        
        local tr = util.TraceLine({
            start = myPos,
            endpos = targetPos,
            filter = {self, owner},
            mask = MASK_SHOT
        })
        
        if tr.Entity ~= npc and tr.Hit then continue end
        
        if dist < bestDist then
            bestDist = dist
            bestTarget = npc
        end
    end
    
    if IsValid(bestTarget) then
        self:LockOnTarget(bestTarget)
    end
end

function ENT:LockOnTarget(target)
    self:SetLockedTarget(target)
    self:SetIsLocked(true)
    
    if self.ScanSound then
        self.ScanSound:Stop()
    end
    
    self:EmitSound("npc/manhack/mh_blade_snick1.wav", 75, math.random(95, 105), 1.0)
    self.CurrentSpeed = self.LockedSpeed
end

function ENT:HomeTowardTarget(target)
    local isAlive = false
    if target:IsPlayer() then
        isAlive = target:Alive()
    elseif target:IsNPC() then
        isAlive = target:Health() > 0
    end
    
    if not IsValid(target) or not isAlive then
        self:SetLockedTarget(NULL)
        self:SetIsLocked(false)
        self.CurrentSpeed = self.ProjectileSpeed
        if self.ScanSound then
            self.ScanSound:Play()
        end
        return
    end
    
    local myPos = self:GetPos()
    local targetPos = target:GetPos() + Vector(0, 0, 40)
    local toTarget = (targetPos - myPos):GetNormalized()
    
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
    
    if self.ScanSound then
        self.ScanSound:Stop()
    end
    
    self:DealDamage(hitPos, hitEntity, owner, weapon, baseDamage)
    self:Remove()
end

function ENT:DealDamage(pos, hitEntity, attacker, weapon, baseDamage)
    if not IsValid(attacker) then return end
    
    local impactSounds = {
        "npc/manhack/grind_flesh1.wav",
        "npc/manhack/grind_flesh2.wav"
    }
    sound.Play(impactSounds[math.random(1, 2)], pos, 75, math.random(95, 105), 1.0)
    
    net.Start("TDMRP_HomingImpact")
        net.WriteVector(pos)
    net.Broadcast()
    
    if IsValid(hitEntity) and (hitEntity:IsPlayer() or hitEntity:IsNPC()) then
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
    if self.ScanSound then
        self.ScanSound:Stop()
    end
end
