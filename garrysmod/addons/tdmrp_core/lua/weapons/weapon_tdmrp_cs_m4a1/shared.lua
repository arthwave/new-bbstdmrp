-- M4A1 (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "M4A1 Carbine"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 3
SWEP.SlotPos = 2

SWEP.ViewModel = "models/weapons/cstrike/c_rif_m4a1.mdl"
SWEP.WorldModel = "models/weapons/w_rif_m4a1.mdl"
SWEP.HoldType = "ar2"

SWEP.Primary.Sound = Sound("Weapon_M4A1.Single")
SWEP.Primary.Damage = 30
SWEP.Primary.RPM = 600
SWEP.Primary.Recoil = 0.55
SWEP.Primary.Spread = 0.020
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "ar2"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-6.2, -15.8, 2.7)
SWEP.IronSightsAng = Vector(2.2, 0.1, -0.4)
SWEP.SightsPos = Vector(-6.2, -15.8, 2.7)
SWEP.SightsAng = Vector(2.2, 0.1, -0.4)

SWEP.TDMRP_ShortName = "M4A1"
SWEP.TDMRP_WeaponType = "rifle"
