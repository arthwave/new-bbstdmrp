-- sent_tdmrp_homing_dart/cl_init.lua
-- Homing suffix projectile - client-side rendering

include("shared.lua")

local glowMaterial = Material("sprites/light_glow02_add")
local beamMaterial = Material("trails/laser")

function ENT:Initialize()
    self.TrailPositions = {}
    self.LastPos = self:GetPos()
    self.ParticleNextTime = 0
end

function ENT:Draw()
    -- Don't draw the model, draw custom visuals instead
    self:DrawGlow()
    self:DrawTracer()
    self:SpawnParticles()
end

function ENT:DrawGlow()
    local pos = self:GetPos()
    local isLocked = self:GetIsLocked()
    
    -- Color and size based on lock state
    local glowColor = isLocked and Color(255, 50, 50, 255) or Color(255, 100, 100, 255)
    local glowSize = isLocked and self.LockedGlowSize or self.GlowSize
    
    -- Pulsing effect when locked
    if isLocked then
        local pulse = math.sin(CurTime() * 15) * 0.3 + 1
        glowSize = glowSize * pulse
    end
    
    render.SetMaterial(glowMaterial)
    render.DrawSprite(pos, glowSize * 2, glowSize * 2, glowColor)
    
    -- Inner brighter core
    local coreColor = isLocked and Color(255, 200, 200, 255) or Color(255, 150, 150, 255)
    render.DrawSprite(pos, glowSize, glowSize, coreColor)
end

function ENT:DrawTracer()
    local curPos = self:GetPos()
    local isLocked = self:GetIsLocked()
    
    -- Store trail positions
    table.insert(self.TrailPositions, 1, curPos)
    if #self.TrailPositions > self.TrailLength then
        table.remove(self.TrailPositions)
    end
    
    -- Trail color - brighter red when locked
    local trailColor = isLocked and Color(255, 50, 50, 255) or Color(255, 80, 80, 200)
    
    render.SetMaterial(beamMaterial)
    
    -- Draw trail segments
    for i = 1, #self.TrailPositions - 1 do
        local p1 = self.TrailPositions[i]
        local p2 = self.TrailPositions[i + 1]
        
        local alpha = 255 * (1 - (i / #self.TrailPositions))
        local width = 3 * (1 - (i / #self.TrailPositions))
        
        if isLocked then
            width = width * 1.5  -- Thicker trail when locked
        end
        
        render.DrawBeam(p1, p2, width, 0, 1, Color(trailColor.r, trailColor.g, trailColor.b, alpha))
    end
    
    self.LastPos = curPos
end

function ENT:SpawnParticles()
    if CurTime() < self.ParticleNextTime then return end
    self.ParticleNextTime = CurTime() + 0.02
    
    local pos = self:GetPos()
    local isLocked = self:GetIsLocked()
    
    local emitter = ParticleEmitter(pos)
    if not emitter then return end
    
    -- Small red particle trail
    local particle = emitter:Add("effects/spark", pos)
    if particle then
        particle:SetVelocity(VectorRand() * 20)
        particle:SetLifeTime(0)
        particle:SetDieTime(isLocked and 0.15 or 0.1)
        particle:SetStartAlpha(isLocked and 255 or 180)
        particle:SetEndAlpha(0)
        particle:SetStartSize(isLocked and 3 or 2)
        particle:SetEndSize(0)
        particle:SetColor(255, isLocked and 50 or 100, isLocked and 50 or 100)
        particle:SetGravity(Vector(0, 0, 0))
    end
    
    emitter:Finish()
end

function ENT:Think()
    -- Client-side think for smooth visuals
end
