----------------------------------------------------
-- TDMRP CS:S Weapon Wrapper Base
-- Thin wrapper that inherits from weapon_real_base
-- All core functionality is in weapon_real_base
----------------------------------------------------

print("[TDMRP] Loading weapon_tdmrp_cs_base...")

if SERVER then
    AddCSLuaFile()
end

-- Inherit from our self-contained real weapon base
SWEP.Base = "weapon_real_base"

-- TDMRP Flags (weapon_real_base sets these but we ensure they're set)
SWEP.IsTDMRPWeapon = true
SWEP.IsTDMRPCSSWeapon = true
SWEP.UseMixinSystem = true
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.Tier = 1

-- Default stats (can be overridden by child weapons)
SWEP.Primary.RPM = 600
SWEP.Primary.Damage = 25
SWEP.Primary.Spread = 0.02
SWEP.Primary.Recoil = 0.5
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

----------------------------------------------------
-- SetTier / GetTier - Allow tier changes
----------------------------------------------------
function SWEP:SetTier(newTier)
    if not SERVER then return end
    newTier = math.Clamp(newTier or 1, 1, 4)
    self.Tier = newTier
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(self)
    end
end

function SWEP:GetTier()
    return self.Tier or 1
end

print("[TDMRP] weapon_tdmrp_cs_base loaded - Thin wrapper for CSS weapons")
