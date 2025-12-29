-- AUG (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "Steyr AUG"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 3
SWEP.SlotPos = 3

SWEP.ViewModel = "models/weapons/cstrike/c_rif_aug.mdl"
SWEP.WorldModel = "models/weapons/w_rif_aug.mdl"
SWEP.HoldType = "ar2"

SWEP.Primary.Sound = Sound("Weapon_AUG.Single")
SWEP.Primary.Damage = 32
SWEP.Primary.RPM = 667
SWEP.Primary.Recoil = 0.50
SWEP.Primary.Spread = 0.018
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "ar2"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-5.8, -14.5, 2.6)
SWEP.IronSightsAng = Vector(2.1, 0, -0.3)
SWEP.SightsPos = Vector(-5.8, -14.5, 2.6)
SWEP.SightsAng = Vector(2.1, 0, -0.3)

SWEP.TDMRP_ShortName = "AUG"
SWEP.TDMRP_WeaponType = "rifle"
