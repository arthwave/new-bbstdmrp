-- AK-47 (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "AK-47"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 3
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/cstrike/c_rif_ak47.mdl"
SWEP.WorldModel = "models/weapons/w_rif_ak47.mdl"
SWEP.HoldType = "ar2"

SWEP.Primary.Sound = Sound("Weapon_AK47.Single")
SWEP.Primary.Damage = 33
SWEP.Primary.RPM = 600
SWEP.Primary.Recoil = 0.65
SWEP.Primary.Spread = 0.023
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "ar2"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-6.56, -16.24, 2.799)
SWEP.IronSightsAng = Vector(2.299, 0.1, -0.5)
SWEP.SightsPos = Vector(-6.56, -16.24, 2.799)
SWEP.SightsAng = Vector(2.299, 0.1, -0.5)

SWEP.TDMRP_ShortName = "AK-47"
SWEP.TDMRP_WeaponType = "rifle"
