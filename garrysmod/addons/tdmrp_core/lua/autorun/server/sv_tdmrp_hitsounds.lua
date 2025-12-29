----------------------------------------------------
-- TDMRP Hit Feedback Sounds - Server
----------------------------------------------------

if CLIENT then return end

----------------------------------------------------
-- Hitgroup-based feedback sounds (headshots, bodyshots)
-- Uses ScalePlayerDamage for proper hitgroup detection
-- NOTE: Invincibility sounds handled in sv_tdmrp_activeskills.lua
----------------------------------------------------
hook.Add("ScalePlayerDamage", "TDMRP_HitSounds", function(ply, hitgroup, dmginfo)
    if not IsValid(ply) then return end
    
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    
    -- Skip sound if target has invincibility (metal clank plays instead)
    local targetBuff = TDMRP.ActiveSkills and TDMRP.ActiveSkills.ActiveBuffs and TDMRP.ActiveSkills.ActiveBuffs[ply]
    if targetBuff and targetBuff.skill == "invincibility" and CurTime() < targetBuff.endTime then
        return
    end
    
    -- Play sounds based on hitgroup
    if hitgroup == HITGROUP_HEAD then
        -- Headshot sound - play to both attacker and victim
        attacker:EmitSound("tdmrp/bodysounds/dink.wav", 75, 100)
        ply:EmitSound("tdmrp/bodysounds/dink.wav", 75, 100)
    --elseif hitgroup >= HITGROUP_CHEST and hitgroup <= HITGROUP_RIGHTLEG then
        -- Body hit sound - play to both attacker and victim
   --     attacker:EmitSound("tdmrp/bodysounds/dink.wav", 70, 100)
   --     ply:EmitSound("tdmrp/bodysounds/dink.wav", 70, 100)
    end
    
    -- Future: Add headshot damage multipliers here
    -- if hitgroup == HITGROUP_HEAD then
    --     dmginfo:ScaleDamage(2.0)  -- 2x headshot damage
    -- end
end)

print("[TDMRP] sv_tdmrp_hitsounds.lua loaded (hit feedback sounds)")

----------------------------------------------------
-- Console command: Test dink sound
----------------------------------------------------
concommand.Add("tdmrp_test_dink", function(ply, cmd, args)
    if not IsValid(ply) then return end
    ply:EmitSound("tdmrp/bodysounds/dink.wav", 70, 100)
    ply:ChatPrint("[TDMRP] Testing dink sound!")
end, nil, "Test the dink body hit sound")

----------------------------------------------------
-- Console command: Test metal impact hard1 sound
----------------------------------------------------
concommand.Add("tdmrp_test_metal", function(ply, cmd, args)
    if not IsValid(ply) then return end
    ply:EmitSound("physics/metal/metal_box_impact_bullet3.wav", 75, 100)
    ply:ChatPrint("[TDMRP] Testing metal impact hard1 sound!")
end, nil, "Test the metal impact hard1 sound")
