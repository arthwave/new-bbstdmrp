-- Client-side visual effects for capture points
-- Creates glow/color effects on capture point entities

if SERVER then return end

-- Color definitions for each team
local TEAM_COLORS = {
	[0] = Color(200, 200, 200, 100),   -- NEUTRAL - White (dim)
	[1] = Color(80, 150, 255, 150),    -- COP - Blue
	[2] = Color(255, 150, 40, 150),    -- CRIMINAL - Orange
	[3] = Color(255, 50, 50, 200),     -- CONTESTED - Red (bright)
}

-- Apply color glow to display entities based on ownership
hook.Add("Think", "TDMRP_CapturePointVisuals", function()
	for _, ent in ipairs(ents.FindByClass("ent_tdmrp_capture_display")) do
		if not IsValid(ent) then continue end
		
		local owner = ent:GetNWInt("TDMRP_CapturePointOwner", 0)
		local color = TEAM_COLORS[owner] or TEAM_COLORS[0]
		
		-- Apply color to entity for visibility
		ent:SetColor(color)
	end
end)

-- Draw 3D text above capture points for additional visual feedback
hook.Add("PostDrawTranslucentRenderables", "TDMRP_CapturePointText", function()
	for _, ent in ipairs(ents.FindByClass("ent_tdmrp_capture_display")) do
		if not IsValid(ent) then continue end
		
		local owner = ent:GetNWInt("TDMRP_CapturePointOwner", 0)
		local progress = ent:GetNWInt("TDMRP_CapturePointProgress", 0)
		local name = ent:GetNWString("TDMRP_CapturePointName", "Unknown")
		
		local pos = ent:GetPos() + Vector(0, 0, 160)  -- Higher above entity to avoid clipping
		local color = TEAM_COLORS[owner] or TEAM_COLORS[0]
		
		-- Get ownership text
		local ownerText = "NEUTRAL"
		if owner == 1 then ownerText = "COP" 
		elseif owner == 2 then ownerText = "CRIMINAL"
		elseif owner == 3 then ownerText = "CONTESTED" end
		
		-- Draw point name (slightly smaller)
		cam.Start3D2D(pos + Vector(0, 0, 15), Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.8)
			draw.SimpleText(name, "HudHintTextLarge", 0, 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
		
		-- Draw ownership and progress text (slightly smaller)
		local statusText = ownerText .. " (" .. progress .. "%)"
		cam.Start3D2D(pos - Vector(0, 0, 15), Angle(0, LocalPlayer():EyeAngles().y - 90, 90), 0.96)
			draw.SimpleText(statusText, "HudHintTextLarge", 0, 0, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		cam.End3D2D()
	end
end)

print("[TDMRP] Capture point visual effects loaded (glow + text)")
