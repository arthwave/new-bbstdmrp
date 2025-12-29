-- cl_tdmrp_hud.lua
-- TDMRP Enhanced HUD with 3D playermodel face render
-- Bottom-left status panel with segmented HP/armor bars

if SERVER then return end

----------------------------
-- Fonts (match weapon HUD)
----------------------------
surface.CreateFont("TDMRP_HUD_Name", {
    font = "Roboto Condensed",
    size = 20,
    weight = 700,
    antialias = true
})

surface.CreateFont("TDMRP_HUD_Job", {
    font = "Roboto Condensed",
    size = 16,
    weight = 600,
    antialias = true
})

surface.CreateFont("TDMRP_HUD_Money", {
    font = "Roboto Condensed",
    size = 16,
    weight = 600,
    antialias = true
})

surface.CreateFont("TDMRP_HUD_Stats", {
    font = "Roboto Condensed",
    size = 14,
    weight = 400,
    antialias = true
})

surface.CreateFont("TDMRP_HUD_StatsBold", {
    font = "Roboto Condensed",
    size = 36,
    weight = 700,
    antialias = true
})

surface.CreateFont("TDMRP_HUD_ActiveSkill", {
    font = "Roboto Condensed",
    size = 12,
    weight = 600,
    antialias = true
})

----------------------------
-- 3D Playermodel Panel
----------------------------
local modelPanel = nil
local lastJobTeam = -1
local lastMaterial = ""

local function CreateModelPanel()
    if IsValid(modelPanel) then
        modelPanel:Remove()
    end
    
    modelPanel = vgui.Create("DModelPanel")
    modelPanel:SetSize(100, 100)
    modelPanel:SetModel(LocalPlayer():GetModel())
    
    -- Disable mouse rotation
    function modelPanel:LayoutEntity(ent)
        -- Keep entity locked in place, no rotation
        return
    end
    
    -- Set camera to face view
    local ent = modelPanel:GetEntity()
    if IsValid(ent) then
        local headBone = ent:LookupBone("ValveBiped.Bip01_Head1")
        if headBone then
            local headPos = ent:GetBonePosition(headBone)
            modelPanel:SetCamPos(headPos + Vector(19, 0, 0))
            modelPanel:SetLookAt(headPos)
        else
            -- Fallback camera position (25% further out)
            modelPanel:SetCamPos(Vector(63, 0, 65))
            modelPanel:SetLookAt(Vector(0, 0, 65))
        end
        
        modelPanel:SetFOV(40)
        ent:SetAngles(Angle(0, 0, 0))
    end
end

----------------------------
-- Segmented Bar Drawing
----------------------------
local function DrawSegmentedBar(x, y, w, h, current, max, color, segmentHP)
    segmentHP = segmentHP or 10
    
    local totalSegments = math.ceil(max / segmentHP)
    local filledHP = math.min(current, max)
    local filledSegments = filledHP / segmentHP
    
    local segmentWidth = (w - (totalSegments - 1) * 2) / totalSegments -- 2px gap between segments
    
    for i = 1, totalSegments do
        local segX = x + (i - 1) * (segmentWidth + 2)
        
        -- Determine fill for this segment
        local fillPercent = 0
        if i <= math.floor(filledSegments) then
            fillPercent = 1 -- Fully filled
        elseif i == math.ceil(filledSegments) then
            fillPercent = filledSegments - math.floor(filledSegments) -- Partial fill
        end
        
        -- Draw segment background (empty)
        surface.SetDrawColor(20, 20, 20, 200)
        surface.DrawRect(segX, y, segmentWidth, h)
        
        -- Draw filled portion
        if fillPercent > 0 then
            surface.SetDrawColor(color.r, color.g, color.b, 255)
            surface.DrawRect(segX, y, segmentWidth * fillPercent, h)
        end
        
        -- Draw segment border
        surface.SetDrawColor(60, 60, 60, 150)
        surface.DrawOutlinedRect(segX, y, segmentWidth, h)
    end
end

----------------------------
-- Main HUD Draw
----------------------------
local lastMoney = 0
local moneyDelta = 0
local moneyDeltaTime = 0

-- Remove conflicting DarkRP HUD hooks
local darkrpHooks = {"DarkRP_HUD", "DarkRP_LocalPlayerHUD", "DarkRP_Hungermod", "TDMRP_DrawHUD_Main"}
for _, hookName in ipairs(darkrpHooks) do
    hook.Remove("HUDPaint", hookName)
end

hook.Add("HUDPaint", "TDMRP_StatusHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then 
        -- Hide model panel when dead
        if IsValid(modelPanel) then
            modelPanel:SetVisible(false)
        end
        return 
    end
    
    -- Show model panel when alive
    if IsValid(modelPanel) then
        modelPanel:SetVisible(true)
    end
    
    -- Update model panel on job change
    local currentTeam = ply:Team()
    if currentTeam ~= lastJobTeam then
        lastJobTeam = currentTeam
        CreateModelPanel()
    end
    
    -- Sync material with active skill
    if IsValid(modelPanel) then
        local ent = modelPanel:GetEntity()
        if IsValid(ent) then
            local plyMat = ply:GetMaterial()
            if plyMat ~= lastMaterial then
                lastMaterial = plyMat
                ent:SetMaterial(plyMat)
            end
        end
    end
    
    -- Panel dimensions (match weapon HUD: 420x135)
    local panelX = 20
    local panelY = ScrH() - 155
    local panelW = 420
    local panelH = 135
    
    -- Draw main panel background (match weapon HUD)
    draw.RoundedBox(6, panelX, panelY, panelW, panelH, Color(13, 13, 13, 250))
    
    -- Draw left accent bar (RED like weapon HUD)
    surface.SetDrawColor(204, 0, 0, 255)
    surface.DrawRect(panelX, panelY + 4, 3, panelH - 8)
    
    -- Render 3D face (centered vertically in panel)
    if IsValid(modelPanel) then
        local faceSize = 100
        local faceX = panelX + 10
        local faceY = panelY + (panelH - faceSize) / 2  -- Center vertically
        modelPanel:SetPos(faceX, faceY)
        modelPanel:PaintManual()
    end
    
    -- DT Display at top-left corner of HUD (sticking out)
    if TDMRP and TDMRP.DT and TDMRP.DT.IsCombatJob then
        local dt = TDMRP.DT.GetTotalDT(ply)
        local dtName = TDMRP.DT.GetDTName(ply)
        
        if dt > 0 then
            local dtText = dt .. " DT (" .. dtName .. ")"
            
            surface.SetFont("TDMRP_HUD_Job")
            local textW, textH = surface.GetTextSize(dtText)
            
            -- Position at top-left corner, sticking out above the panel
            local dtX = panelX
            local dtY = panelY - textH - 6
            
            -- Background pill for DT
            draw.RoundedBox(4, dtX, dtY, textW + 12, textH + 4, Color(40, 40, 40, 220))
            
            -- DT color based on value (thresholds: 5, 10)
            local dtColor = Color(150, 150, 150)  -- Gray for low DT
            if dt >= 10 then
                dtColor = Color(255, 100, 100)  -- Red for 10+ DT
            elseif dt >= 5 then
                dtColor = Color(255, 200, 100)  -- Orange for 5-9 DT
            end
            
            draw.SimpleText(dtText, "TDMRP_HUD_Job", dtX + 6, dtY + 2, dtColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end
    
    -- Money and BP Display at top-right corner (floating above HUD)
    surface.SetFont("TDMRP_HUD_Job")
    local statTextH = select(2, surface.GetTextSize("BP"))
    
    local moneyBPY = panelY - statTextH - 6
    
    -- BP (Bob Points) - top right, orange
    local bp = 0
    if ply.GetBP then
        bp = ply:GetBP()
    end
    local bpText = "BP: " .. bp
    local bpW = surface.GetTextSize(bpText)
    draw.RoundedBox(4, panelX + panelW - bpW - 12, moneyBPY - 2, bpW + 12, statTextH + 4, Color(40, 40, 40, 220))
    draw.SimpleText(bpText, "TDMRP_HUD_Job", panelX + panelW - 6, moneyBPY, Color(255, 170, 0), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    
    -- Money - top right, left of BP
    local currentMoney = ply:getDarkRPVar("money") or 0
    local moneyText = "$" .. string.Comma(currentMoney)
    local moneyW = surface.GetTextSize(moneyText)
    draw.RoundedBox(4, panelX + panelW - bpW - moneyW - 24, moneyBPY - 2, moneyW + 12, statTextH + 4, Color(40, 40, 40, 220))
    draw.SimpleText(moneyText, "TDMRP_HUD_Money", panelX + panelW - bpW - 18, moneyBPY, Color(0, 204, 102), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    
    -- Text area start X (adjusted for larger panel)
    local textX = panelX + 125
    local textY = panelY + 10
    
    -- Player name + job on same line with m-dash
    local playerName = string.upper(ply:Nick())
    local jobName = team.GetName(ply:Team()) or "Citizen"
    draw.SimpleText(playerName .. " — " .. jobName, "TDMRP_HUD_Name", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Health bar (wide, fills most of the space)
    textY = textY + 30
    local hp = ply:Health()
    local maxHP = ply:GetMaxHealth()
    local barWidth = 230
    DrawSegmentedBar(textX, textY, barWidth, 18, hp, maxHP, Color(204, 0, 0), 10)
    
    -- HP text (green) - 36pt BOLD, centered in right space
    local hpText = tostring(hp)
    draw.SimpleText(hpText, "TDMRP_HUD_StatsBold", panelX + 387, textY + 9, Color(0, 204, 102), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Armor bar (wide, fills most of the space)
    local armor = ply:Armor()
    local maxArmor = ply:GetMaxArmor() or 100
    if maxArmor > 0 then
        textY = textY + 30
        DrawSegmentedBar(textX, textY, barWidth, 18, armor, maxArmor, Color(100, 150, 255), 10)
        
        -- Armor text (blue) - 36pt BOLD, centered in right space
        local armorText = tostring(armor)
        draw.SimpleText(armorText, "TDMRP_HUD_StatsBold", panelX + 387, textY + 9, Color(100, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Active Skill Section
    local skillData = nil
    local skillID = nil
    local job = RPExtraTeams and RPExtraTeams[ply:Team()]
    
    if job and TDMRP and TDMRP.ActiveSkills and TDMRP.ActiveSkills.JobSkills then
        skillID = TDMRP.ActiveSkills.JobSkills[job.name]
        if skillID then
            skillData = TDMRP.ActiveSkills.Skills[skillID]
        end
    end
    
    if skillData then
        -- Position below armor bar
        local skillY = textY + 24
        
        -- Left side: "Active Skill" stacked text
        draw.SimpleText("Active", "TDMRP_HUD_Job", textX, skillY, Color(160, 160, 160), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Skill", "TDMRP_HUD_Job", textX, skillY + 16, Color(160, 160, 160), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Bar position
        local barX = textX + 50
        local barY = skillY + 2
        local barWidth = 200
        local barHeight = 16
        
        -- Check cooldown
        local cooldownRemaining = math.max(0, TDMRP.ActiveSkills.LocalCooldown - CurTime())
        local skillCooldown = skillData.cooldown or 10
        
        if cooldownRemaining > 0 then
            -- On cooldown: light gray background
            surface.SetDrawColor(120, 120, 120, 255)
            surface.DrawRect(barX, barY, barWidth, barHeight)
            
            -- Dark gray cooldown fill (fills as cooldown depletes)
            local cooldownPercent = math.Clamp(1 - (cooldownRemaining / skillCooldown), 0, 1)
            surface.SetDrawColor(60, 60, 60, 255)
            surface.DrawRect(barX, barY, barWidth * cooldownPercent, barHeight)
        else
            -- Ready: use skill's vignette color
            local vignetteCol = skillData.vignetteColor or Color(100, 150, 255, 255)
            surface.SetDrawColor(vignetteCol.r, vignetteCol.g, vignetteCol.b, 255)
            surface.DrawRect(barX, barY, barWidth, barHeight)
        end
        
        -- Skill name centered on bar at 50% opacity
        draw.SimpleText(skillData.name, "TDMRP_HUD_ActiveSkill", barX + barWidth/2, barY + barHeight/2, Color(255, 255, 255, 127), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- Initialize panel on load
hook.Add("InitPostEntity", "TDMRP_InitHUD", function()
    timer.Simple(1, CreateModelPanel)
end)

print("[TDMRP] Enhanced HUD loaded")
