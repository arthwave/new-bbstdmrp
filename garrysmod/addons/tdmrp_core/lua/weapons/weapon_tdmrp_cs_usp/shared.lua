-- USP (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "H&K USP"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 1
SWEP.SlotPos = 2

SWEP.ViewModel = "models/weapons/cstrike/c_pist_usp.mdl"
SWEP.WorldModel = "models/weapons/w_pist_usp.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary.Sound = Sound("Weapon_USP.Single")
SWEP.Primary.Damage = 15
SWEP.Primary.RPM = 600
SWEP.Primary.Recoil = 1.2
SWEP.Primary.Spread = 0.013
SWEP.Primary.ClipSize = 12
SWEP.Primary.DefaultClip = 12
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-6.15, -10.5, 2.8)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(-6.15, -10.5, 2.8)
SWEP.SightsAng = Vector(0, 0, 0)

SWEP.TDMRP_ShortName = "USP"
SWEP.TDMRP_WeaponType = "pistol"
