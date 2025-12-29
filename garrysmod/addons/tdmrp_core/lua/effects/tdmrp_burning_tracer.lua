-- tdmrp_burning_tracer.lua
-- Fire-themed tracer effect for "of Burning" suffix

EFFECT.Mat = Material("effects/laser1")

function EFFECT:Init(data)
    self.EndPos = data:GetOrigin()
    
    -- Store weapon reference to track its movement
    self.Weapon = data:GetEntity()
    self.Owner = IsValid(self.Weapon) and self.Weapon:GetOwner() or nil
    
    -- Try to get initial position from viewmodel muzzle attachment (model-specific)
    self.StartPos = data:GetStart()
    if IsValid(self.Owner) then
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            local muzzleID = vm:LookupAttachment("muzzle")
            if muzzleID and muzzleID > 0 then
                local muzzleAttach = vm:GetAttachment(muzzleID)
                if muzzleAttach then
                    self.StartPos = muzzleAttach.Pos
                end
            end
        end
        
        -- Fallback: calculated offset if no muzzle attachment found
        if self.StartPos == data:GetStart() then
            local shootPos = self.Owner:GetShootPos()
            local aimDir = self.Owner:GetAimVector()
            local eyeAng = self.Owner:EyeAngles()
            
            local downOffset = eyeAng:Up() * -8
            local forwardOffset = aimDir * 20
            local rightOffset = eyeAng:Right() * 12
            
            self.StartPos = shootPos + downOffset + forwardOffset + rightOffset
        end
    end
    
    self.Entity:SetRenderBoundsWS(self.StartPos, self.EndPos)
    
    -- Tracer lifetime
    self.LifeTime = 0.15
    self.DieTime = CurTime() + self.LifeTime
    self.Alpha = 255
    
    -- Direction for particle trail
    self.Dir = (self.EndPos - self.StartPos):GetNormalized()
    self.Length = self.StartPos:Distance(self.EndPos)
end

function EFFECT:Think()
    -- Update start position to follow weapon's viewmodel (recoil animation)
    if IsValid(self.Weapon) and IsValid(self.Owner) then
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            local muzzleID = vm:LookupAttachment("muzzle")
            if muzzleID and muzzleID > 0 then
                local muzzleAttach = vm:GetAttachment(muzzleID)
                if muzzleAttach then
                    self.StartPos = muzzleAttach.Pos
                end
            end
        end
    end
    
    return CurTime() < self.DieTime
end

function EFFECT:Render()
    local lifePercent = math.Clamp((self.DieTime - CurTime()) / self.LifeTime, 0, 1)
    local alpha = 255 * lifePercent
    
    local startPos = self.StartPos
    local endPos = self.EndPos
    
    -- Outer orange glow
    render.SetMaterial(self.Mat)
    render.DrawBeam(
        startPos, 
        endPos, 
        16, 
        0, 
        1, 
        Color(255, 80, 0, alpha * 0.6)
    )
    
    -- Middle bright yellow-orange core
    render.DrawBeam(
        startPos, 
        endPos, 
        8, 
        0, 
        1, 
        Color(255, 150, 30, alpha * 0.9)
    )
    
    -- Inner bright yellow core
    render.DrawBeam(
        startPos, 
        endPos, 
        3, 
        0, 
        1, 
        Color(255, 255, 100, alpha)
    )
    
    -- Add some fire particles along the path (only once at Init, not every frame)
    if not self.ParticlesSpawned and lifePercent > 0.8 then
        self.ParticlesSpawned = true
        
        local particleCount = math.min(3, math.ceil(self.Length / 150)) -- Reduced count
        local emitter = ParticleEmitter(startPos) -- Single emitter for all particles
        
        if emitter then
            for i = 1, particleCount do
                local lerp = math.random() * 0.8 + 0.1
                local pos = LerpVector(lerp, startPos, endPos)
                
                local particle = emitter:Add("particles/fire1", pos)
                if particle then
                    particle:SetVelocity(VectorRand() * 20)
                    particle:SetLifeTime(0)
                    particle:SetDieTime(0.1)
                    particle:SetStartAlpha(150)
                    particle:SetEndAlpha(0)
                    particle:SetStartSize(4)
                    particle:SetEndSize(1)
                    particle:SetColor(255, 100 + math.random(0, 100), 0)
                    particle:SetAirResistance(50)
                    particle:SetGravity(Vector(0, 0, 30))
                end
            end
            emitter:Finish() -- Clean up emitter immediately
        end
    end
end
