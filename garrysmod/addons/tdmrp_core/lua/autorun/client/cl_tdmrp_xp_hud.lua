----------------------------------------------------
-- TDMRP XP HUD - Client Display
-- Shows level and XP progress bar on main HUD
-- Positioned near bottom-left player status panel
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.XP = TDMRP.XP or {}
TDMRP.XP.ClientData = TDMRP.XP.ClientData or {}

----------------------------------------------------
-- Fonts
----------------------------------------------------

surface.CreateFont("TDMRP_XP_Level", {
    font = "Roboto Condensed",
    size = 18,
    weight = 700,
    antialias = true
})

surface.CreateFont("TDMRP_XP_Progress", {
    font = "Roboto Condensed",
    size = 12,
    weight = 500,
    antialias = true
})

----------------------------------------------------
-- Client-side XP Storage
----------------------------------------------------

TDMRP.XP.ClientData.TotalXP = 0
TDMRP.XP.ClientData.LastGainTime = 0
TDMRP.XP.ClientData.LastGainAmount = 0
TDMRP.XP.ClientData.LastGainReason = ""

----------------------------------------------------
-- Network Receivers
----------------------------------------------------

-- Sync total XP from server
net.Receive("TDMRP_XP_Sync", function()
    local xp = net.ReadUInt(32)
    TDMRP.XP.ClientData.TotalXP = xp
end)

-- XP gain notification
net.Receive("TDMRP_XP_Gain", function()
    local amount = net.ReadUInt(16)
    local reason = net.ReadString()
    
    TDMRP.XP.ClientData.LastGainTime = CurTime()
    TDMRP.XP.ClientData.LastGainAmount = amount
    TDMRP.XP.ClientData.LastGainReason = reason
    
    -- Play sound
    surface.PlaySound("buttons/button14.wav")
    
    -- Chat message
    chat.AddText(Color(100, 200, 100), "[XP] ", Color(255, 255, 255), string.format("+%d XP (%s)", amount, reason))
end)

-- Level up notification
net.Receive("TDMRP_XP_LevelUp", function()
    local newLevel = net.ReadUInt(8)
    
    -- Play level up sound
    surface.PlaySound("buttons/button15.wav")
    
    -- Screen flash effect (optional, using notification)
    notification.AddProgress("tdmrp_levelup", string.format("LEVEL UP! You reached Level %d!", newLevel))
    timer.Simple(3, function()
        notification.Kill("tdmrp_levelup")
    end)
end)

----------------------------------------------------
-- HUD Drawing
----------------------------------------------------

local function DrawXPHUD()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- Only show for combat classes
    local team = ply:Team()
    if not RPExtraTeams or not RPExtraTeams[team] then return end
    
    local job = RPExtraTeams[team]
    local jobClass = job.tdmrp_class or "civilian"
    
    if jobClass ~= "cop" and jobClass ~= "criminal" then
        return -- Don't show for civilians
    end
    
    local C = TDMRP.UI and TDMRP.UI.Colors or {
        bg_dark = Color(13, 13, 13, 250),
        bg_medium = Color(22, 22, 22, 250),
        text_primary = Color(255, 255, 255, 255),
        text_secondary = Color(160, 160, 160, 255),
        accent = Color(204, 0, 0, 255),
        success = Color(0, 204, 102, 255),
    }
    
    -- Position the XP panel centered at the top, occupying one-third of screen width (minimal)
    local scrW, scrH = ScrW(), ScrH()
    local xpPanelW = math.floor(scrW / 3)
    local xpPanelH = 36
    local xpPanelX = math.floor((scrW - xpPanelW) / 2)
    local xpPanelY = 12

    -- Minimal background
    draw.RoundedBox(4, xpPanelX, xpPanelY, xpPanelW, xpPanelH, Color(13, 13, 13, 200))
    surface.SetDrawColor(204, 0, 0, 200)
    surface.DrawRect(xpPanelX, xpPanelY + 6, 3, xpPanelH - 12)
    draw.RoundedBox(4, xpPanelX + 8, xpPanelY + 6, xpPanelW - 16, xpPanelH - 12, Color(22, 22, 22, 180))

    -- Get XP data
    local totalXP = TDMRP.XP.ClientData.TotalXP or 0
    local level = TDMRP.XP.GetLevelFromXP(totalXP)
    local progress = TDMRP.XP.GetLevelProgress(totalXP)

    -- Small level badge (left)
    local levelText = string.format("L %d", level)
    draw.SimpleText(levelText, "TDMRP_XP_Progress", xpPanelX + 14, xpPanelY + xpPanelH / 2, C.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    -- Slim progress bar
    local barX = xpPanelX + 60
    local barY = xpPanelY + xpPanelH / 2 - 4
    local barW = xpPanelW - 74
    local barH = 8
    draw.RoundedBox(4, barX, barY, barW, barH, Color(20, 20, 20, 150))
    local fillW = math.max(2, barW * progress)
    local fillColor = C.success
    if level >= TDMRP.XP.Config.MAX_LEVEL then fillColor = C.accent end
    draw.RoundedBox(4, barX, barY, fillW, barH, fillColor)

    -- Percentage text at right
    local percentText = string.format("%d%%", math.floor(progress * 100))
    draw.SimpleText(percentText, "TDMRP_XP_Progress", barX + barW - 6, barY + barH / 2, C.text_primary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    -- Small XP gain popup above the panel (centered)
    local timeSinceGain = CurTime() - TDMRP.XP.ClientData.LastGainTime
    if timeSinceGain < 2 and TDMRP.XP.ClientData.LastGainAmount > 0 then
        local alpha = math.Clamp(255 * (1 - timeSinceGain / 2), 0, 255)
        local popupX = xpPanelX + xpPanelW / 2
        local popupY = xpPanelY - 18

        local popupText = string.format("+%d XP", TDMRP.XP.ClientData.LastGainAmount)
        draw.SimpleText(popupText, "TDMRP_XP_Progress", popupX, popupY, ColorAlpha(C.success, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

hook.Add("HUDPaint", "TDMRP_XP_HUD", DrawXPHUD)

----------------------------------------------------
-- Level Reward Indicators (on scoreboard or TAB)
----------------------------------------------------

local function DrawLevelRewards()
    -- TODO: Add to scoreboard or separate UI showing:
    -- - Level 5: HP Regeneration (+5 HP/s)
    -- - Level 10: Damage Boost (+10%)
end

print("[TDMRP] cl_tdmrp_xp_hud.lua loaded (XP HUD display)")
