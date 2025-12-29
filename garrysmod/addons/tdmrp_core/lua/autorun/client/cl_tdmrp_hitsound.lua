----------------------------------------------------
-- TDMRP Client Hit Sound - Maximum Volume Amplifier
-- Plays hitsound at full client-side volume for all damage
----------------------------------------------------

if not CLIENT then return end

-- Hook: Listen for damage and play hitsound locally at MAX volume
hook.Add("EntityTakeDamage", "TDMRP_ClientHitSound", function(target, dmginfo)
    -- Check if target is valid and player took damage
    if not IsValid(target) or not target:IsPlayer() then return end
    
    local dmg = dmginfo:GetDamage()
    if dmg <= 0 then return end
    
    -- Play hitsound at MAXIMUM local volume
    -- surface.PlaySound plays at full volume locally on the client
    surface.PlaySound("tdmrp/quake/newhitsound1.mp3")
end)

print("[TDMRP] Client hitsound amplifier loaded")
