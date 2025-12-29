-- P228 (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "SIG P228"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 1
SWEP.SlotPos = 3

SWEP.ViewModel = "models/weapons/cstrike/c_pist_p228.mdl"
SWEP.WorldModel = "models/weapons/w_pist_p228.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary.Sound = Sound("Weapon_P228.Single")
SWEP.Primary.Damage = 13
SWEP.Primary.RPM = 600
SWEP.Primary.Recoil = 1.3
SWEP.Primary.Spread = 0.012
SWEP.Primary.ClipSize = 13
SWEP.Primary.DefaultClip = 13
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-5.8, -11, 2.9)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(-5.8, -11, 2.9)
SWEP.SightsAng = Vector(0, 0, 0)

SWEP.TDMRP_ShortName = "P228"
SWEP.TDMRP_WeaponType = "pistol"
