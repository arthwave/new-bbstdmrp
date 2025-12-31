-- sent_tdmrp_homing_dart/shared.lua
-- Homing suffix projectile - shared definitions

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Homing Dart"
ENT.Author = "TDMRP"
ENT.Category = "TDMRP"
ENT.Spawnable = false
ENT.AdminSpawnable = false

-- Projectile settings
ENT.ProjectileSpeed = 1800        -- Initial speed (slower to allow homing)
ENT.LockedSpeed = 3500            -- Speed when locked onto target
ENT.ScanRange = 600               -- How far ahead to scan for targets
ENT.ScanAngle = 60                -- Cone angle (degrees) for target detection
ENT.HomingStrength = 15           -- How aggressively it turns toward target (higher = sharper turns)
ENT.LifeTime = 4                  -- Max lifetime before auto-remove

-- Visual settings
ENT.GlowSize = 8                  -- Base glow size
ENT.LockedGlowSize = 14           -- Glow size when locked on
ENT.TrailLength = 10              -- Trail segment count

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "OwnerPlayer")
    self:NetworkVar("Entity", 1, "OwnerWeapon")
    self:NetworkVar("Entity", 2, "LockedTarget")
    self:NetworkVar("Float", 0, "BaseDamage")
    self:NetworkVar("Vector", 0, "StartPos")
    self:NetworkVar("Bool", 0, "IsLocked")
end
