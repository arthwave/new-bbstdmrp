-- SG552 (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "SG552 Commando"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 3
SWEP.SlotPos = 5

SWEP.ViewModel = "models/weapons/cstrike/c_rif_sg552.mdl"
SWEP.WorldModel = "models/weapons/w_rif_sg552.mdl"
SWEP.HoldType = "ar2"

SWEP.Primary.Sound = Sound("Weapon_SG552.Single")
SWEP.Primary.Damage = 30
SWEP.Primary.RPM = 632
SWEP.Primary.Recoil = 0.58
SWEP.Primary.Spread = 0.021
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "ar2"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-6.0, -14.8, 2.5)
SWEP.IronSightsAng = Vector(2.15, 0.05, -0.35)
SWEP.SightsPos = Vector(-6.0, -14.8, 2.5)
SWEP.SightsAng = Vector(2.15, 0.05, -0.35)

SWEP.TDMRP_ShortName = "SG552"
SWEP.TDMRP_WeaponType = "rifle"
