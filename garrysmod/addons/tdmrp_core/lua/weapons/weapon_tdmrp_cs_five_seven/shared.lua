-- Five-Seven (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "FN Five-Seven"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 1
SWEP.SlotPos = 4

SWEP.ViewModel = "models/weapons/cstrike/c_pist_fiveseven.mdl"
SWEP.WorldModel = "models/weapons/w_pist_fiveseven.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary.Sound = Sound("Weapon_FiveSeven.Single")
SWEP.Primary.Damage = 20
SWEP.Primary.RPM = 400
SWEP.Primary.Recoil = 1.1
SWEP.Primary.Spread = 0.015
SWEP.Primary.ClipSize = 20
SWEP.Primary.DefaultClip = 20
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-5.9, -10.8, 2.85)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(-5.9, -10.8, 2.85)
SWEP.SightsAng = Vector(0, 0, 0)

SWEP.TDMRP_ShortName = "Five-Seven"
SWEP.TDMRP_WeaponType = "pistol"
