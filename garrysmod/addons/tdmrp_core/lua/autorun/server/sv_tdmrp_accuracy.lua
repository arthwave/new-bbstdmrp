----------------------------------------------------
-- TDMRP Accuracy System - Server
-- Note: The actual spread modification is done in sh_tdmrp_weapon_mixin.lua
-- via GetModifiedSpread() which hooks into ShootBullet directly.
-- This file is kept for future server-side accuracy features.
----------------------------------------------------

if CLIENT then return end

TDMRP = TDMRP or {}
TDMRP.Accuracy = TDMRP.Accuracy or {}

print("[TDMRP] sv_tdmrp_accuracy.lua loaded")
