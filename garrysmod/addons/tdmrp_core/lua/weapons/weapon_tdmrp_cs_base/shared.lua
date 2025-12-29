----------------------------------------------------
-- TDMRP CS:S Weapon Wrapper Base
-- Wraps CS:S weapons with TDMRP mixin system
----------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

-- Inherit from our real weapon base
SWEP.Base = "weapon_real_base"
SWEP.IsTDMRPWeapon = true
SWEP.UseMixinSystem = true
SWEP.Spawnable = false
SWEP.AdminSpawnable = false
SWEP.Tier = 1

-- Default stats for CSS weapons
SWEP.Primary.RPM = 600
SWEP.Primary.Damage = 25
SWEP.Primary.Spread = 0.02
SWEP.Primary.Recoil = 0.5
SWEP.Primary.ClipSize = 30
SWEP.Primary.DefaultClip = 30
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "pistol"

function SWEP:Initialize()
    -- Call base class Initialize
    if self.BaseClass and self.BaseClass.Initialize then
        self.BaseClass.Initialize(self)
    end
    
    -- Apply TDMRP mixin system for tier scaling
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(self)
    end
end

function SWEP:Deploy()
    if self.BaseClass and self.BaseClass.Deploy then
        self.BaseClass.Deploy(self)
    end
    
    -- Set networked stats for HUD
    if SERVER and TDMRP_WeaponMixin and TDMRP_WeaponMixin.SetNetworkedStats then
        TDMRP_WeaponMixin.SetNetworkedStats(self)
    end
    
    return true
end

function SWEP:Equip(newOwner)
    if self.BaseClass and self.BaseClass.Equip then
        self.BaseClass.Equip(self, newOwner)
    end
    
    -- Reapply mixin on equip
    if SERVER and TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(self)
    end
end

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
