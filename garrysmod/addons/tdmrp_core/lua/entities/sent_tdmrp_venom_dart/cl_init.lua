include("shared.lua")

local GLOW_COLOR = Color(50, 255, 50, 200)
local GLOW_CORE = Color(150, 255, 150, 255)
local TRAIL_COLOR = Color(80, 255, 80, 150)

function ENT:Initialize()
    self.TrailPositions = {}
    self.MaxTrailPositions = 8
    self.LastTrailTime = 0
    self.TrailInterval = 0.015
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    local pos = self:GetPos()
    local dir = self:GetVelocity():GetNormalized()
    
    self:DrawGlow(pos)
    self:DrawNeedle(pos, dir)
    self:DrawTrail(pos)
end

function ENT:DrawGlow(pos)
    local size = self.GlowSize
    local pulseSize = size + math.sin(CurTime() * 20) * 2
    
    -- Outer neon glow
    render.SetMaterial(Material("sprites/light_glow02_add"))
    render.DrawSprite(pos, pulseSize * 2, pulseSize * 2, GLOW_COLOR)
    
    -- Inner bright core
    render.DrawSprite(pos, pulseSize * 0.5, pulseSize * 0.5, GLOW_CORE)
end

function ENT:DrawNeedle(pos, dir)
    local needleLength = 30
    local startPos = pos - dir * needleLength
    
    -- Main needle beam
    render.SetMaterial(Material("effects/laser1"))
    render.DrawBeam(startPos, pos, 3, 0, 1, GLOW_COLOR)
    
    -- Inner bright core line
    render.SetMaterial(Material("sprites/physbeam"))
    render.DrawBeam(startPos, pos, 1.5, 0, 1, GLOW_CORE)
end

function ENT:DrawTrail(pos)
    if CurTime() - self.LastTrailTime > self.TrailInterval then
        self.LastTrailTime = CurTime()
        table.insert(self.TrailPositions, 1, {pos = pos, time = CurTime()})
        
        while #self.TrailPositions > self.MaxTrailPositions do
            table.remove(self.TrailPositions)
        end
    end
    
    if #self.TrailPositions < 2 then return end
    
    render.SetMaterial(Material("sprites/light_glow02_add"))
    
    for i = 1, #self.TrailPositions - 1 do
        local p1 = self.TrailPositions[i]
        local alpha = 200 * (1 - (i - 1) / self.MaxTrailPositions)
        local size = 5 * (1 - (i - 1) / self.MaxTrailPositions)
        
        render.DrawSprite(p1.pos, size, size, Color(80, 255, 80, alpha))
    end
end

function ENT:Think()
    -- Spawn poison drip particles
    local emitter = ParticleEmitter(self:GetPos())
    if emitter then
        local particle = emitter:Add("particles/smokey", self:GetPos())
        if particle then
            particle:SetVelocity(VectorRand() * 5)
            particle:SetLifeTime(0)
            particle:SetDieTime(0.25)
            particle:SetStartAlpha(80)
            particle:SetEndAlpha(0)
            particle:SetStartSize(2)
            particle:SetEndSize(0.5)
            particle:SetColor(50, 255, 50)
            particle:SetGravity(Vector(0, 0, -50))
        end
        emitter:Finish()
    end
end

-- Impact effect
net.Receive("TDMRP_VenomImpact", function()
    local pos = net.ReadVector()
    
    -- Toxic splash effect
    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 12 do
            local particle = emitter:Add("particles/smokey", pos)
            if particle then
                particle:SetVelocity(VectorRand() * 80)
                particle:SetLifeTime(0)
                particle:SetDieTime(0.6)
                particle:SetStartAlpha(200)
                particle:SetEndAlpha(0)
                particle:SetStartSize(8)
                particle:SetEndSize(15)
                particle:SetColor(50, 200, 50)
                particle:SetGravity(Vector(0, 0, 20))
            end
        end
        
        -- Bright green sparks
        for i = 1, 6 do
            local particle = emitter:Add("effects/spark", pos)
            if particle then
                particle:SetVelocity(VectorRand() * 120)
                particle:SetLifeTime(0)
                particle:SetDieTime(0.3)
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(3)
                particle:SetEndSize(1)
                particle:SetColor(100, 255, 100)
                particle:SetGravity(Vector(0, 0, -300))
            end
        end
        emitter:Finish()
    end
end)
