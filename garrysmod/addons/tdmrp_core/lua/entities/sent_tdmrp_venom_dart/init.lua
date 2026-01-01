AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/hunter/plates/plate.mdl")
    self:SetModelScale(0.1)
    self:SetNoDraw(true)
    
    self:PhysicsInitSphere(3, "metal")
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(0.5)
        phys:EnableGravity(false)
        phys:SetDragCoefficient(0)
        phys:EnableCollisions(true)
    end
    
    self.SpawnTime = CurTime()
    self.HasHit = false
    self.FlightDirection = Vector(0, 0, 0)
end

function ENT:SetProjectileVelocity(direction)
    self.FlightDirection = direction:GetNormalized()
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(self.FlightDirection * self.ProjectileSpeed)
    end
end

function ENT:Think()
    if CurTime() - self.SpawnTime > self.LifeTime then
        self:Remove()
        return
    end
    
    -- Keep velocity constant (no gravity decay)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(self.FlightDirection * self.ProjectileSpeed)
    end
    
    self:NextThink(CurTime())
    return true
end

function ENT:PhysicsCollide(data, phys)
    if self.HasHit then return end
    self.HasHit = true
    
    local hitPos = data.HitPos
    local hitEntity = data.HitEntity
    local owner = self:GetOwnerPlayer()
    local weapon = self:GetOwnerWeapon()
    local baseDamage = self:GetBaseDamage()
    
    self:DealDamage(hitPos, hitEntity, owner, weapon, baseDamage)
    self:Remove()
end

function ENT:DealDamage(pos, hitEntity, attacker, weapon, baseDamage)
    if not IsValid(attacker) then return end
    
    -- Impact sound - poison hiss
    sound.Play("npc/headcrab_poison/ph_hiss1.wav", pos, 75, math.random(95, 105), 1.0)
    
    -- Broadcast impact effect
    net.Start("TDMRP_VenomImpact")
        net.WriteVector(pos)
    net.Broadcast()
    
    if IsValid(hitEntity) and (hitEntity:IsPlayer() or hitEntity:IsNPC()) then
        -- Team check for players
        if hitEntity:IsPlayer() and hitEntity:Team() == attacker:Team() then return end
        
        -- Deal direct damage (reduced by -35%)
        local dmgInfo = DamageInfo()
        dmgInfo:SetDamage(baseDamage)
        dmgInfo:SetAttacker(attacker)
        dmgInfo:SetInflictor(IsValid(weapon) and weapon or attacker)
        dmgInfo:SetDamageType(DMG_POISON)
        dmgInfo:SetDamagePosition(pos)
        
        hitEntity:TakeDamageInfo(dmgInfo)
        
        -- Apply poison stacks
        if TDMRP and TDMRP.Venom then
            TDMRP.Venom.ApplyPoison(hitEntity, attacker, weapon)
        end
    end
end
