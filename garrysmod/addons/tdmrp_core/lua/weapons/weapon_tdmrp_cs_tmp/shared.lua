-- TMP (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "Steyr TMP"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 2
SWEP.SlotPos = 4

SWEP.ViewModel = "models/weapons/cstrike/c_smg_tmp.mdl"
SWEP.WorldModel = "models/weapons/w_smg_tmp.mdl"
SWEP.HoldType = "smg"

SWEP.Primary.Sound = Sound("Weapon_TMP.Single")
SWEP.Primary.Damage = 16
SWEP.Primary.RPM = 1091
SWEP.Primary.Recoil = 0.85
SWEP.Primary.Spread = 0.022
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "smg1"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-4.4, -8.2, 2.55)
SWEP.IronSightsAng = Vector(0.35, 0, 0)
SWEP.SightsPos = Vector(-4.4, -8.2, 2.55)
SWEP.SightsAng = Vector(0.35, 0, 0)

SWEP.TDMRP_ShortName = "TMP"
SWEP.TDMRP_WeaponType = "smg"
