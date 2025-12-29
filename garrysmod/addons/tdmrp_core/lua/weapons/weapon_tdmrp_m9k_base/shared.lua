-- TDMRP M9K Base Wrapper
-- Initializes SWEP before M9K code executes

if SERVER then AddCSLuaFile("shared.lua") end

SWEP.PrintName = SWEP.PrintName or "M9K Weapon"
SWEP.Slot = SWEP.Slot or 2
SWEP.SlotPos = SWEP.SlotPos or 1
SWEP.DrawAmmo = true
SWEP.DrawWeaponInfoBox = false
SWEP.BounceWeaponIcon = false
SWEP.DrawCrosshair = true

-- Ensure TDMRP mixin is applied on Initialize
local originalInit = SWEP.Initialize or function() end
function SWEP:Initialize()
	originalInit(self)
	if TDMRP_WeaponMixin then
		TDMRP_WeaponMixin.Setup(self)
	end
end
