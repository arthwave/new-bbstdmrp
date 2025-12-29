-- shared.lua

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "TDMRP Weapon Pickup"
ENT.Spawnable = false

-- Optional: network vars if you want, but not strictly needed
function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "WeaponClass")
end
