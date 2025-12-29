-- entities/tdmrp_loot_orb/cl_init.lua

include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local lootType = self:GetNWString("TDMRP_LootType", "money")
    local lootSub  = self:GetNWString("TDMRP_LootSub", "")

    -- Simple glow sprite
    local pos = self:GetPos()
    local col = self:GetColor()

    render.SetMaterial(Material("sprites/light_glow02_add"))
    render.DrawSprite(pos, 12, 12, col)
end

function ENT:Think()
    -- Soft dynamic light for aura
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        local col = self:GetColor()
        dlight.pos      = self:GetPos()
        dlight.r        = col.r
        dlight.g        = col.g
        dlight.b        = col.b
        dlight.brightness = 2
        dlight.Decay    = 600
        dlight.Size     = 120
        dlight.DieTime  = CurTime() + 0.1
    end
end
