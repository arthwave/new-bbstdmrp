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

-- Flag to prevent recursion
local initializingWeapon = {}

function SWEP:Initialize()
    -- Prevent stack overflow from recursive calls
    local id = tostring(self)
    if initializingWeapon[id] then return end
    initializingWeapon[id] = true
    
    -- Set weapon hold type (this is all weapon_real_base does in Initialize)
    self:SetWeaponHoldType(self.HoldType or "pistol")
    
    -- Apply TDMRP mixin system for tier scaling
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(self)
    end
    
    initializingWeapon[id] = nil
end

local deployingWeapon = {}

function SWEP:Deploy()
    -- Prevent stack overflow from recursive calls
    local id = tostring(self)
    if deployingWeapon[id] then return true end
    deployingWeapon[id] = true
    
    -- Set networked stats for HUD
    if SERVER and TDMRP_WeaponMixin and TDMRP_WeaponMixin.SetNetworkedStats then
        TDMRP_WeaponMixin.SetNetworkedStats(self)
    end
    
    deployingWeapon[id] = nil
    return true
end

local equippingWeapon = {}

function SWEP:Equip(newOwner)
    -- Prevent stack overflow from recursive calls  
    local id = tostring(self)
    if equippingWeapon[id] then return end
    equippingWeapon[id] = true
    
    -- Reapply mixin on equip
    if SERVER and TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(self)
    end
    
    equippingWeapon[id] = nil
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
