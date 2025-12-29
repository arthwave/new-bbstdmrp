-- P90 (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "FN P90"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 2
SWEP.SlotPos = 2

SWEP.ViewModel = "models/weapons/cstrike/c_smg_p90.mdl"
SWEP.WorldModel = "models/weapons/w_smg_p90.mdl"
SWEP.HoldType = "smg"

SWEP.Primary.Sound = Sound("Weapon_P90.Single")
SWEP.Primary.Damage = 15
SWEP.Primary.RPM = 857
SWEP.Primary.Recoil = 0.7
SWEP.Primary.Spread = 0.025
SWEP.Primary.ClipSize = 50
SWEP.Primary.DefaultClip = 50
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "smg1"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-4.8, -9, 2.4)
SWEP.IronSightsAng = Vector(0.4, 0, 0)
SWEP.SightsPos = Vector(-4.8, -9, 2.4)
SWEP.SightsAng = Vector(0.4, 0, 0)

SWEP.TDMRP_ShortName = "P90"
SWEP.TDMRP_WeaponType = "smg"
