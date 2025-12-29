-- FAMAS (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "FAMAS G2"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 3
SWEP.SlotPos = 4

SWEP.ViewModel = "models/weapons/cstrike/c_rif_famas.mdl"
SWEP.WorldModel = "models/weapons/w_rif_famas.mdl"
SWEP.HoldType = "ar2"

SWEP.Primary.Sound = Sound("Weapon_FAMAS.Single")
SWEP.Primary.Damage = 28
SWEP.Primary.RPM = 667
SWEP.Primary.Recoil = 0.60
SWEP.Primary.Spread = 0.022
SWEP.Primary.ClipSize = 25
SWEP.Primary.DefaultClip = 25
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "ar2"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-5.5, -13.2, 2.4)
SWEP.IronSightsAng = Vector(2.0, 0, -0.2)
SWEP.SightsPos = Vector(-5.5, -13.2, 2.4)
SWEP.SightsAng = Vector(2.0, 0, -0.2)

SWEP.TDMRP_ShortName = "FAMAS"
SWEP.TDMRP_WeaponType = "rifle"
