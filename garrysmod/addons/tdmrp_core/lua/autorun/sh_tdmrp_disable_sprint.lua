----------------------------------------------------
-- TDMRP: Disable M9K Sprint Animation Restriction
-- This prevents the running animation that blocks shooting
----------------------------------------------------

-- Hook into weapon initialization to override sprint behavior
hook.Add("OnEntityCreated", "TDMRP_DisableSprint", function(ent)
    if not IsValid(ent) or not ent:IsWeapon() then return end
    
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        
        -- Check if it's an M9K weapon (uses bobs_gun_base)
        if ent.Base == "bobs_gun_base" or string.StartWith(ent:GetClass(), "m9k_") or string.StartWith(ent:GetClass(), "tdmrp_m9k_") then
            -- Set run sights to same as normal sights (no sprint animation override)
            if ent.SightsPos and ent.SightsAng then
                ent.RunSightsPos = ent.SightsPos
                ent.RunSightsAng = ent.SightsAng
            end
        end
    end)
end)

print("[TDMRP] Sprint restriction disabled for M9K weapons")
