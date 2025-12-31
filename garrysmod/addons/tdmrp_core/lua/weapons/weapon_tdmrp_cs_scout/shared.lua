-- Scout (CS:S Wrapper - Scoped Sniper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_scoped_base"
SWEP.PrintName = "Steyr Scout"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 5
SWEP.SlotPos = 2

SWEP.ViewModel = "models/weapons/cstrike/c_snip_scout.mdl"
SWEP.WorldModel = "models/weapons/w_snip_scout.mdl"
SWEP.HoldType = "ar2"

SWEP.Primary.Sound = Sound("Weapon_SCOUT.Single")
SWEP.Primary.Damage = 50
SWEP.Primary.RPM = 50  -- Bolt action
SWEP.Primary.Recoil = 1.5  -- Reduced from 5
SWEP.Primary.Spread = 0.0005
SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "smg1"
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

SWEP.IronSightsPos = Vector(-6.68, -10.521, 3.4)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(-6.68, -10.521, 3.4)
SWEP.SightsAng = Vector(0, 0, 0)

SWEP.TDMRP_ShortName = "Scout"
SWEP.TDMRP_WeaponType = "sniper"
