-- sent_tdmrp_shatter_rock/cl_init.lua
-- Shatter suffix projectile - client-side rendering

include("shared.lua")

function ENT:Initialize()
    self.TrailPositions = {}
    self.LastPos = self:GetPos()
end

function ENT:Draw()
    self:DrawModel()
    
    -- Draw yellow tracer trail
    self:DrawTracer()
end

function ENT:DrawTracer()
    local curPos = self:GetPos()
    local startPos = self:GetStartPos()
    
    if not startPos or startPos == Vector(0,0,0) then
        startPos = self.LastPos or curPos
    end
    
    -- Store trail positions for smooth rendering
    table.insert(self.TrailPositions, 1, curPos)
    if #self.TrailPositions > 10 then
        table.remove(self.TrailPositions)
    end
    
    -- Draw tracer beam
    local tracerColor = Color(255, 220, 50, 255)  -- Yellow
    
    render.SetMaterial(Material("sprites/light_glow02_add"))
    
    -- Draw trail segments
    for i = 1, #self.TrailPositions - 1 do
        local p1 = self.TrailPositions[i]
        local p2 = self.TrailPositions[i + 1]
        
        local alpha = 255 * (1 - (i / #self.TrailPositions))
        local width = 3 * (1 - (i / #self.TrailPositions))
        
        render.DrawBeam(p1, p2, width, 0, 1, Color(tracerColor.r, tracerColor.g, tracerColor.b, alpha))
    end
    
    -- Draw glow at projectile position
    render.DrawSprite(curPos, 12, 12, tracerColor)
    
    self.LastPos = curPos
end

function ENT:Think()
    -- Update trail
end
