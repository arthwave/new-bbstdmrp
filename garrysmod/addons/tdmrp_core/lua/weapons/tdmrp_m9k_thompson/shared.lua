----------------------------------------------------
-- tdmrp_m9k_thompson
-- TDMRP Weapon: Thompson M1A1
-- Auto-generated - Regenerate with VS Code tooling
----------------------------------------------------

if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "m9k_thompson"

SWEP.PrintName = "Thompson M1A1"
SWEP.Category = "TDMRP SMGs"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.TDMRP_ShortName = "TOMMY"
SWEP.TDMRP_WeaponType = "smg"
SWEP.TDMRP_BaseClass = "m9k_thompson"

SWEP.Tier = 1

function SWEP:Initialize()
    if self.BaseClass and self.BaseClass.Initialize then
        self.BaseClass.Initialize(self)
    end
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(self)
    end
end

function SWEP:Deploy()
    local ret = true
    if self.BaseClass and self.BaseClass.Deploy then
        ret = self.BaseClass.Deploy(self)
    end
    if SERVER and TDMRP_WeaponMixin and TDMRP_WeaponMixin.SetNetworkedStats then
        TDMRP_WeaponMixin.SetNetworkedStats(self)
    end
    return ret
end

function SWEP:Equip(newOwner)
    if self.BaseClass and self.BaseClass.Equip then
        self.BaseClass.Equip(self, newOwner)
    end
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
