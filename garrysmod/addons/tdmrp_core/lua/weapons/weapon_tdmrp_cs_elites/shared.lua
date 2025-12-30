-- Dual Elites (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "Dual Elites"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 1
SWEP.SlotPos = 5

SWEP.ViewModel = "models/weapons/cstrike/c_pist_elite.mdl"
SWEP.WorldModel = "models/weapons/w_pist_elite.mdl"
SWEP.HoldType = "pistol"

SWEP.Primary.Sound = Sound("Weapon_Elites.Single")
SWEP.Primary.Damage = 18
SWEP.Primary.RPM = 400
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Spread = 0.018
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "pistol"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-5.5, -10, 2.7)
SWEP.IronSightsAng = Vector(0, 0, 0)
SWEP.SightsPos = Vector(-5.5, -10, 2.7)
SWEP.SightsAng = Vector(0, 0, 0)

SWEP.TDMRP_ShortName = "Dual Elites"
SWEP.TDMRP_WeaponType = "pistol"
