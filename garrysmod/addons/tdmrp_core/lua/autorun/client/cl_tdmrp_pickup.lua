-- cl_tdmrp_pickup.lua
-- Client helper: command to store the weapon you're looking at

if not CLIENT then return end

net.Receive("TDMRP_StoreLookWeapon", function()
    -- (Not used; server only receives this net.)
end)

concommand.Add("tdmrp_store_look", function()
    net.Start("TDMRP_StoreLookWeapon")
    net.SendToServer()
end)

print("[TDMRP] cl_tdmrp_pickup.lua loaded (command: tdmrp_store_look)")
