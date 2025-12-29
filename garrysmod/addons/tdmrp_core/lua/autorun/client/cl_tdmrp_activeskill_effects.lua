-- TDMRP Active Skill Effects System
-- Renders per-skill visual effects when skills are active
-- Each skill can define custom effects via OnActiveEffect callback

if CLIENT then

hook.Add("RenderScreenspaceEffects", "TDMRP_SkillEffects", function()
    local ply = LocalPlayer()
    if not ply:IsValid() or not ply:Alive() then return end
    
    -- Get current job and skill ID
    local jobName = RPExtraTeams[ply:Team()] and RPExtraTeams[ply:Team()].name or nil
    if not jobName or not TDMRP.ActiveSkills.JobSkills[jobName] then return end
    
    local skillID = TDMRP.ActiveSkills.JobSkills[jobName]
    local skillData = TDMRP.ActiveSkills.Skills[skillID]
    
    if not skillData then return end
    
    -- Check if skill is currently active (cooldown running = skill was just activated)
    local cooldownRemaining = math.max(0, TDMRP.ActiveSkills.LocalCooldown - CurTime())
    local isActive = cooldownRemaining > 0
    
    if not isActive then return end
    
    -- Call skill's custom effect function if it exists
    if skillData.OnActiveEffect and isfunction(skillData.OnActiveEffect) then
        skillData.OnActiveEffect(skillData, cooldownRemaining)
    end
end)

end
