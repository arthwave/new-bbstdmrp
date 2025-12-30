-- Galil (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "Galil SAR"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 3
SWEP.SlotPos = 3

SWEP.ViewModel = "models/weapons/cstrike/c_rif_galil.mdl"
SWEP.WorldModel = "models/weapons/w_rif_galil.mdl"
SWEP.HoldType = "ar2"

SWEP.Primary.Sound = Sound("Weapon_Galil.Single")
SWEP.Primary.Damage = 25
SWEP.Primary.RPM = 650
SWEP.Primary.Recoil = 0.65
SWEP.Primary.Spread = 0.017
SWEP.Primary.ClipSize = 35
SWEP.Primary.DefaultClip = 35
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "smg1"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-6.361, -10.12, 2.599)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(-6.361, -10.12, 2.599)
SWEP.SightsAng = Vector(0, 0, 0)

SWEP.TDMRP_ShortName = "Galil"
SWEP.TDMRP_WeaponType = "rifle"
