-- sent_tdmrp_shatter_rock/shared.lua
-- Shatter suffix projectile - shared definitions

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Shatter Rock"
ENT.Author = "TDMRP"
ENT.Category = "TDMRP"
ENT.Spawnable = false
ENT.AdminSpawnable = false

-- Projectile settings
ENT.RockScale = 0.2           -- 20% of original size
ENT.ProjectileSpeed = 3500    -- Units per second (fast direct path)
ENT.Gravity = 5               -- Minimal gravity (nearly straight line)
ENT.ExplosionRadius = 90      -- AOE damage radius
ENT.ExplosionDamageMin = 0.4  -- 40% damage at edge
ENT.ExplosionDamageMax = 1.0  -- 100% damage at center
ENT.LifeTime = 5              -- Max lifetime before auto-remove

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "OwnerPlayer")
    self:NetworkVar("Entity", 1, "OwnerWeapon")
    self:NetworkVar("Float", 0, "BaseDamage")
    self:NetworkVar("Vector", 0, "StartPos")
end
