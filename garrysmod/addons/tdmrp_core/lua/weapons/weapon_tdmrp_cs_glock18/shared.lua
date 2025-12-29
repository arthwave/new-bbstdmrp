-- Glock-18 (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "Glock-18"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 1
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/cstrike/c_pist_glock18.mdl"
SWEP.WorldModel = "models/weapons/w_pist_glock18.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary.Sound = Sound("Weapon_Glock.Single")
SWEP.Primary.Damage = 12
SWEP.Primary.RPM = 600
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Spread = 0.014
SWEP.Primary.ClipSize = 19
SWEP.Primary.DefaultClip = 19
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-5.781, -11.721, 3)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(-5.781, -11.721, 3)
SWEP.SightsAng = Vector(0, 0, 0)

SWEP.TDMRP_ShortName = "Glock-18"
SWEP.TDMRP_WeaponType = "pistol"
