-- Pump Shotgun (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "Pump Shotgun"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 4
SWEP.SlotPos = 1

SWEP.ViewModel = "models/weapons/cstrike/c_shot_pumpshotgun.mdl"
SWEP.WorldModel = "models/weapons/w_shot_pumpshotgun.mdl"
SWEP.HoldType = "shotgun"

SWEP.Primary.Sound = Sound("Weapon_Shotgun.Single")
SWEP.Primary.Damage = 20
SWEP.Primary.RPM = 120
SWEP.Primary.Recoil = 1.5
SWEP.Primary.Spread = 0.15
SWEP.Primary.ClipSize = 8
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "buckshot"
SWEP.Primary.NumShots = 6

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-5.5, -12, 2.8)
SWEP.IronSightsAng = Vector(1.5, 0, 0)
SWEP.SightsPos = Vector(-5.5, -12, 2.8)
SWEP.SightsAng = Vector(1.5, 0, 0)

SWEP.TDMRP_ShortName = "Pump Shotgun"
SWEP.TDMRP_WeaponType = "shotgun"
