-- UMP-45 (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "H&K UMP-45"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 2
SWEP.SlotPos = 5

SWEP.ViewModel = "models/weapons/cstrike/c_smg_ump45.mdl"
SWEP.WorldModel = "models/weapons/w_smg_ump45.mdl"
SWEP.HoldType = "smg"

SWEP.Primary.Sound = Sound("Weapon_UMP45.Single")
SWEP.Primary.Damage = 19
SWEP.Primary.RPM = 667
SWEP.Primary.Recoil = 0.9
SWEP.Primary.Spread = 0.024
SWEP.Primary.ClipSize = 25
SWEP.Primary.DefaultClip = 25
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "smg1"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-4.7, -8.8, 2.45)
SWEP.IronSightsAng = Vector(0.45, 0, 0)
SWEP.SightsPos = Vector(-4.7, -8.8, 2.45)
SWEP.SightsAng = Vector(0.45, 0, 0)

SWEP.TDMRP_ShortName = "UMP-45"
SWEP.TDMRP_WeaponType = "smg"
