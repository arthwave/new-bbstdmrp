include("shared.lua")

local GLOW_COLOR = Color(255, 50, 50, 200)
local TRAIL_COLOR = Color(255, 80, 80, 150)

function ENT:Initialize()
    self.TrailPositions = {}
    self.MaxTrailPositions = 10
    self.LastTrailTime = 0
    self.TrailInterval = 0.02
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    local pos = self:GetPos()
    local dir = self:GetVelocity():GetNormalized()
    
    self:DrawGlow(pos)
    self:DrawTracer(pos, dir)
    self:DrawTrail(pos)
end

function ENT:DrawGlow(pos)
    local size = self:GetIsLocked() and 20 or 14
    local pulseSize = size + math.sin(CurTime() * 15) * 3
    
    render.SetMaterial(Material("sprites/light_glow02_add"))
    render.DrawSprite(pos, pulseSize, pulseSize, GLOW_COLOR)
    
    local coreColor = Color(255, 150, 150, 255)
    render.DrawSprite(pos, pulseSize * 0.4, pulseSize * 0.4, coreColor)
end

function ENT:DrawTracer(pos, dir)
    local tracerLength = 60
    local startPos = pos - dir * tracerLength
    
    render.SetMaterial(Material("effects/laser1"))
    render.DrawBeam(startPos, pos, 4, 0, 1, GLOW_COLOR)
    
    render.SetMaterial(Material("sprites/physbeam"))
    render.DrawBeam(startPos, pos, 2, 0, 1, Color(255, 200, 200, 255))
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
        local p2 = self.TrailPositions[i + 1]
        
        local alpha1 = 255 * (1 - (i - 1) / self.MaxTrailPositions)
        local alpha2 = 255 * (1 - i / self.MaxTrailPositions)
        local size1 = 8 * (1 - (i - 1) / self.MaxTrailPositions)
        local size2 = 8 * (1 - i / self.MaxTrailPositions)
        
        render.DrawSprite(p1.pos, size1, size1, Color(255, 80, 80, alpha1))
    end
end

function ENT:Think()
    local emitter = ParticleEmitter(self:GetPos())
    if emitter then
        local particle = emitter:Add("particles/smokey", self:GetPos())
        if particle then
            particle:SetVelocity(VectorRand() * 10)
            particle:SetLifeTime(0)
            particle:SetDieTime(0.3)
            particle:SetStartAlpha(100)
            particle:SetEndAlpha(0)
            particle:SetStartSize(3)
            particle:SetEndSize(1)
            particle:SetColor(255, 100, 100)
            particle:SetGravity(Vector(0, 0, 0))
        end
        emitter:Finish()
    end
end

net.Receive("TDMRP_HomingImpact", function()
    local pos = net.ReadVector()
    
    local effectData = EffectData()
    effectData:SetOrigin(pos)
    effectData:SetMagnitude(2)
    effectData:SetScale(1)
    util.Effect("BloodImpact", effectData)
    
    local emitter = ParticleEmitter(pos)
    if emitter then
        for i = 1, 8 do
            local particle = emitter:Add("effects/spark", pos)
            if particle then
                particle:SetVelocity(VectorRand() * 150)
                particle:SetLifeTime(0)
                particle:SetDieTime(0.4)
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(4)
                particle:SetEndSize(1)
                particle:SetColor(255, 80, 80)
                particle:SetGravity(Vector(0, 0, -200))
            end
        end
        emitter:Finish()
    end
end)
