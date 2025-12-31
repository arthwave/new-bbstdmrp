-- AWP (CS:S Wrapper - Scoped Sniper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_scoped_base"
SWEP.PrintName = "AWP Dragon Lore"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 5
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/cstrike/c_snip_awp.mdl"
SWEP.WorldModel = "models/weapons/w_snip_awp.mdl"
SWEP.HoldType = "ar2"

SWEP.Primary.Sound = Sound("Weapon_AWP.Single")
SWEP.Primary.Damage = 80
SWEP.Primary.RPM = 40  -- Bolt action
SWEP.Primary.Recoil = 2.5
SWEP.Primary.Spread = 0.005
SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "ar2"
SWEP.Primary.NumShots = 1

-- Scope settings (6x zoom, MilDot sniper scope)
SWEP.UseScope = true
SWEP.ScopeZooms = {6}
SWEP.ScopeScale = 0.5
SWEP.ReticleScale = 0.6
SWEP.IronSightZoom = 1.3

-- M9K-style scope type (MilDot sniper scope)
SWEP.Secondary = SWEP.Secondary or {}
SWEP.Secondary.ScopeZoom = 6
SWEP.Secondary.UseMilDot = true

SWEP.IronSightsPos = Vector(-8.5, -15.0, 3.0)
SWEP.IronSightsAng = Vector(3.0, 0, 0)
SWEP.SightsPos = Vector(-8.5, -15.0, 3.0)
SWEP.SightsAng = Vector(3.0, 0, 0)

SWEP.TDMRP_ShortName = "AWP"
SWEP.TDMRP_WeaponType = "sniper"
