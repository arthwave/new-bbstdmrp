-- sent_tdmrp_shatter_rock/init.lua
-- Shatter suffix projectile - server-side logic

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/rock001a.mdl")
    self:SetModelScale(self.RockScale)
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    
    -- Make it smaller collision-wise
    self:SetCollisionBounds(Vector(-4, -4, -4), Vector(4, 4, 4))
    
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(5)
        phys:EnableGravity(true)
        phys:SetDragCoefficient(0)  -- No air resistance
    end
    
    self.SpawnTime = CurTime()
    self.HasExploded = false
    
    -- Set material for visual effect
    self:SetMaterial("phoenix_storms/thruster")
end

function ENT:SetProjectileVelocity(direction)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        -- Apply initial velocity
        local velocity = direction * self.ProjectileSpeed
        phys:SetVelocity(velocity)
        
        -- Reduce gravity effect for slight arc (not full gravity)
        phys:EnableGravity(false)  -- We'll apply custom gravity in Think
    end
    
    self.FlightDirection = direction
end

function ENT:Think()
    -- Check lifetime
    if CurTime() - self.SpawnTime > self.LifeTime then
        self:Remove()
        return
    end
    
    -- Apply custom gravity for slight arc
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        local gravityForce = Vector(0, 0, -self.Gravity * phys:GetMass())
        phys:ApplyForceCenter(gravityForce * FrameTime() * 66)  -- Scale by frametime
    end
    
    self:NextThink(CurTime())
    return true
end

function ENT:PhysicsCollide(data, phys)
    -- Prevent double explosion
    if self.HasExploded then return end
    self.HasExploded = true
    
    local hitPos = data.HitPos
    local hitEntity = data.HitEntity
    local owner = self:GetOwnerPlayer()
    local weapon = self:GetOwnerWeapon()
    local baseDamage = self:GetBaseDamage()
    
    -- Create explosion effect
    self:CreateExplosion(hitPos, owner, weapon, baseDamage)
    
    -- Remove projectile
    self:Remove()
end

function ENT:CreateExplosion(pos, attacker, weapon, baseDamage)
    if not IsValid(attacker) then return end
    
    -- Play impact sound (random)
    local impactSounds = {
        "tdmrp/suffixsounds/shatterimpact1.mp3",
        "tdmrp/suffixsounds/shatterimpact2.mp3"
    }
    sound.Play(impactSounds[math.random(1, 2)], pos, 80, math.random(95, 105), 1.0)
    
    -- Visual explosion effect - use AR2Explosion for smaller blast
    -- (standard "Explosion" ignores SetScale)
    local effectData = EffectData()
    effectData:SetOrigin(pos)
    effectData:SetScale(0.25)
    effectData:SetMagnitude(1)
    util.Effect("AR2Explosion", effectData)
    
    -- Rock debris effect
    local debrisEffect = EffectData()
    debrisEffect:SetOrigin(pos)
    debrisEffect:SetScale(1)
    util.Effect("GlassImpact", debrisEffect)
    
    -- Dust cloud for rock theme
    local dustEffect = EffectData()
    dustEffect:SetOrigin(pos)
    dustEffect:SetScale(0.5)
    util.Effect("WheelDust", dustEffect)
    
    -- Send visual effect to clients
    net.Start("TDMRP_ShatterExplosion")
        net.WriteVector(pos)
    net.Broadcast()
    
    -- Deal AOE damage with falloff
    local radius = self.ExplosionRadius
    local nearbyEnts = ents.FindInSphere(pos, radius)
    
    for _, ent in ipairs(nearbyEnts) do
        if not IsValid(ent) then continue end
        if ent == attacker then continue end  -- Don't hurt self
        
        -- Only damage players and NPCs
        if not (ent:IsPlayer() or ent:IsNPC()) then continue end
        
        -- Team check for players
        if ent:IsPlayer() and ent:Team() == attacker:Team() then continue end
        
        -- Calculate distance falloff
        local dist = pos:Distance(ent:GetPos() + Vector(0, 0, 36))  -- Aim at center mass
        local falloff = 1 - (dist / radius)
        falloff = math.Clamp(falloff, self.ExplosionDamageMin, self.ExplosionDamageMax)
        
        local finalDamage = baseDamage * falloff
        
        -- Apply damage
        local dmgInfo = DamageInfo()
        dmgInfo:SetDamage(finalDamage)
        dmgInfo:SetAttacker(attacker)
        dmgInfo:SetInflictor(IsValid(weapon) and weapon or attacker)
        dmgInfo:SetDamageType(DMG_BLAST)
        dmgInfo:SetDamagePosition(pos)
        
        ent:TakeDamageInfo(dmgInfo)
    end
end

function ENT:OnRemove()
    -- Cleanup
end
