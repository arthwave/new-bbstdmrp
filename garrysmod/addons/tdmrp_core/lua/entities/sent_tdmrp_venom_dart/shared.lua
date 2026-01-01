ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Venom Dart"
ENT.Author = "TDMRP"
ENT.Category = "TDMRP"
ENT.Spawnable = false
ENT.AdminSpawnable = false

-- Projectile settings
ENT.ProjectileSpeed = 2200
ENT.LifeTime = 3
ENT.GlowSize = 6
ENT.TrailLength = 8

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "OwnerPlayer")
    self:NetworkVar("Entity", 1, "OwnerWeapon")
    self:NetworkVar("Float", 0, "BaseDamage")
    self:NetworkVar("Vector", 0, "StartPos")
end
