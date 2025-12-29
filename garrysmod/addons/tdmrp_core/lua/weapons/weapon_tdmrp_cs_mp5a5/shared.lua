-- MP5A5 (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "H&K MP5"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 2
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/cstrike/c_smg_mp5.mdl"
SWEP.WorldModel = "models/weapons/w_smg_mp5.mdl"
SWEP.HoldType = "smg"

SWEP.Primary.Sound = Sound("Weapon_MP5Navy.Single")
SWEP.Primary.Damage = 18
SWEP.Primary.RPM = 800
SWEP.Primary.Recoil = 0.8
SWEP.Primary.Spread = 0.020
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "smg1"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-4.5, -8, 2.5)
SWEP.IronSightsAng = Vector(0.5, 0, 0)
SWEP.SightsPos = Vector(-4.5, -8, 2.5)
SWEP.SightsAng = Vector(0.5, 0, 0)

SWEP.TDMRP_ShortName = "MP5"
SWEP.TDMRP_WeaponType = "smg"
