-- Desert Eagle (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "Desert Eagle"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 1
SWEP.SlotPos = 6

SWEP.ViewModel = "models/weapons/cstrike/c_pist_deagle.mdl"
SWEP.WorldModel = "models/weapons/w_pist_deagle.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary.Sound = Sound("Weapon_Deagle.Single")
SWEP.Primary.Damage = 30
SWEP.Primary.RPM = 400
SWEP.Primary.Recoil = 2.0
SWEP.Primary.Spread = 0.020
SWEP.Primary.ClipSize = 7
SWEP.Primary.DefaultClip = 7
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-6.2, -10.5, 3.0)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(-6.2, -10.5, 3.0)
SWEP.SightsAng = Vector(0, 0, 0)

SWEP.TDMRP_ShortName = "Desert Eagle"
SWEP.TDMRP_WeaponType = "pistol"
