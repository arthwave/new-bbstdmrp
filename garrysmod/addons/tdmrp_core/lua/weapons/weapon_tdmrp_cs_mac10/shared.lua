-- MAC-10 (CS:S Wrapper)
if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tdmrp_cs_base"
SWEP.PrintName = "MAC-10"
SWEP.Category = "TDMRP CSS Weapons"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Slot = 2
SWEP.SlotPos = 3

SWEP.ViewModel = "models/weapons/cstrike/c_smg_mac10.mdl"
SWEP.WorldModel = "models/weapons/w_smg_mac10.mdl"
SWEP.HoldType = "smg"

SWEP.Primary.Sound = Sound("Weapon_MAC10.Single")
SWEP.Primary.Damage = 14
SWEP.Primary.RPM = 1200
SWEP.Primary.Recoil = 0.9
SWEP.Primary.Spread = 0.028
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "smg1"

SWEP.Secondary.IronFOV = 55
SWEP.IronSightsPos = Vector(-4.6, -8.5, 2.6)
SWEP.IronSightsAng = Vector(0.3, 0, 0)
SWEP.SightsPos = Vector(-4.6, -8.5, 2.6)
SWEP.SightsAng = Vector(0.3, 0, 0)

SWEP.TDMRP_ShortName = "MAC-10"
SWEP.TDMRP_WeaponType = "smg"
