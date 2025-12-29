----------------------------------------------------
-- TDMRP Active Skills System - Client
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.ActiveSkills = TDMRP.ActiveSkills or {}

-- Track local cooldowns
TDMRP.ActiveSkills.LocalCooldown = 0

-- Track active vignette effect
TDMRP.ActiveSkills.ActiveVignette = nil

----------------------------------------------------
-- Input Detection: Alt + Shift
----------------------------------------------------
hook.Add("Think", "TDMRP_SkillInputDetect", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- Check if both Alt (IN_WALK) and Shift (IN_SPEED) are pressed
    local altPressed = ply:KeyDown(IN_WALK)
    local shiftPressed = ply:KeyDown(IN_SPEED)
    
    if altPressed and shiftPressed then
        -- Prevent spam - only send once per second
        if CurTime() > (ply.TDMRP_LastSkillAttempt or 0) + 0.5 then
            ply.TDMRP_LastSkillAttempt = CurTime()
            
            -- Send activation request to server
            net.Start("TDMRP_ActivateSkill")
            net.SendToServer()
        end
    end
end)

----------------------------------------------------
-- Network: Skill activated successfully
----------------------------------------------------
net.Receive("TDMRP_SkillActivated", function()
    local skillID = net.ReadString()
    local activator = net.ReadEntity()
    
    if skillID == "healingaura_tick" then
        -- Just a heal tick, play local effect
        return
    end
    
    local skillData = TDMRP.ActiveSkills.GetSkillData(skillID)
    if not skillData then return end
    
    -- If this is our skill, activate vignette
    if activator == LocalPlayer() then
        TDMRP.ActiveSkills.ActiveVignette = {
            color = skillData.vignetteColor,
            endTime = CurTime() + skillData.duration,
            intensity = 0 -- Will fade in
        }
    end
end)

----------------------------------------------------
-- Network: Skill cooldown update
----------------------------------------------------
net.Receive("TDMRP_SkillCooldown", function()
    local skillID = net.ReadString()
    local duration = net.ReadFloat()
    
    TDMRP.ActiveSkills.LocalCooldown = CurTime() + duration
end)

----------------------------------------------------
-- Draw vignette overlay (breathing/pulsing effect)
----------------------------------------------------
hook.Add("HUDPaint", "TDMRP_SkillVignette", function()
    local vignette = TDMRP.ActiveSkills.ActiveVignette
    if not vignette then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local timeLeft = vignette.endTime - CurTime()
    
    -- Fade out in last 0.5 seconds
    if timeLeft <= 0 then
        TDMRP.ActiveSkills.ActiveVignette = nil
        return
    end
    
    -- Calculate intensity (fade in at start, fade out at end, pulse in middle)
    local intensity = 1
    local totalDuration = 5 -- Assume 5 seconds for most skills
    local elapsed = totalDuration - timeLeft
    
    -- Fade in (first 0.3 seconds)
    if elapsed < 0.3 then
        intensity = elapsed / 0.3
    -- Fade out (last 0.5 seconds)
    elseif timeLeft < 0.5 then
        intensity = timeLeft / 0.5
    else
        -- Breathing pulse (60 BPM = 1 cycle per second)
        intensity = 0.7 + math.sin(CurTime() * math.pi * 2) * 0.3
    end
    
    vignette.intensity = intensity
    
    -- Draw radial gradient vignette (transparent center, translucent edges)
    local scrW, scrH = ScrW(), ScrH()
    
    local col = vignette.color
    local maxAlpha = col.a * intensity
    
    -- Edge fade distance (how far from edge the vignette extends)
    local edgeFade = math.min(scrW, scrH) * 0.25 -- 25% of smaller dimension
    local numSteps = 40
    
    -- Draw top edge
    for i = 0, numSteps do
        local progress = i / numSteps
        local y = progress * edgeFade
        local alpha = maxAlpha * (1 - progress) * (1 - progress)
        
        surface.SetDrawColor(col.r, col.g, col.b, alpha)
        surface.DrawRect(0, y, scrW, 1)
    end
    
    -- Draw bottom edge
    for i = 0, numSteps do
        local progress = i / numSteps
        local y = scrH - progress * edgeFade
        local alpha = maxAlpha * (1 - progress) * (1 - progress)
        
        surface.SetDrawColor(col.r, col.g, col.b, alpha)
        surface.DrawRect(0, y, scrW, 1)
    end
    
    -- Draw left edge
    for i = 0, numSteps do
        local progress = i / numSteps
        local x = progress * edgeFade
        local alpha = maxAlpha * (1 - progress) * (1 - progress)
        
        surface.SetDrawColor(col.r, col.g, col.b, alpha)
        surface.DrawRect(x, 0, 1, scrH)
    end
    
    -- Draw right edge
    for i = 0, numSteps do
        local progress = i / numSteps
        local x = scrW - progress * edgeFade
        local alpha = maxAlpha * (1 - progress) * (1 - progress)
        
        surface.SetDrawColor(col.r, col.g, col.b, alpha)
        surface.DrawRect(x, 0, 1, scrH)
    end
end)

----------------------------------------------------
-- Client-side viewmodel material override
----------------------------------------------------
hook.Add("PreDrawViewModel", "TDMRP_ViewModelMaterial", function(vm, ply, weapon)
    if not IsValid(vm) or not IsValid(ply) then return end
    
    -- Only apply if skill is actively running (networked bool)
    if ply:GetNWBool("TDMRP_SkillActive", false) then
        local material = ply:GetMaterial()
        if material and material ~= "" then
            -- Force the viewmodel to use the skill material
            vm:SetMaterial(material)
            
            -- Also set all submaterials
            for i = 0, 31 do
                vm:SetSubMaterial(i, material)
            end
        end
    else
        -- Skill not active, clear viewmodel materials
        vm:SetMaterial("")
        for i = 0, 31 do
            vm:SetSubMaterial(i, nil)
        end
    end
end)

----------------------------------------------------
-- Client-side weapon material override (materialization effect)
----------------------------------------------------
hook.Add("PostDrawViewModel", "TDMRP_WeaponMaterialEffect", function(vm, ply, weapon)
    if not IsValid(ply) then return end
    
    -- Only apply if skill is actively running
    local skillActive = ply:GetNWBool("TDMRP_SkillActive", false)
    
    if skillActive then
        local activeWep = ply:GetActiveWeapon()
        if IsValid(activeWep) then
            local material = ply:GetMaterial()
            
            if material and material ~= "" then
                -- Apply materialization material to weapon
                activeWep:SetMaterial(material)
                
                -- Apply to all submodels/submaterials for complete effect
                for i = 0, 31 do
                    activeWep:SetSubMaterial(i, material)
                end
            end
        end
    else
        -- Skill not active, clean up weapon materials
        local activeWep = ply:GetActiveWeapon()
        if IsValid(activeWep) then
            activeWep:SetMaterial("")
            for i = 0, 31 do
                activeWep:SetSubMaterial(i, nil)
            end
        end
    end
end)

----------------------------------------------------
-- Draw healing aura effects (green pulsing rings)
----------------------------------------------------
hook.Add("PostDrawTranslucentRenderables", "TDMRP_HealingAuraEffects", function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:Alive() then
            -- Check if they have healing aura material
            local mat = ply:GetMaterial()
            
            -- Draw green rings around players with healing aura active
            -- We detect this by checking if they have no material (healing aura doesn't change material)
            -- Instead, we'll draw particles when we receive the tick notification
            -- This section can be enhanced with particle effects if needed
        end
    end
end)

print("[TDMRP] cl_tdmrp_activeskills.lua loaded (client skill input & effects)")
