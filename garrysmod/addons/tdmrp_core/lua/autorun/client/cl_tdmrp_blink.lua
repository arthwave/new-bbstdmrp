----------------------------------------------------
-- TDMRP Blink Skill - Client Side
----------------------------------------------------

if SERVER then return end

print("[TDMRP Blink] ============================================")
print("[TDMRP Blink] CLIENT FILE IS LOADING NOW!")
print("[TDMRP Blink] ============================================")

TDMRP = TDMRP or {}
TDMRP.Blink = TDMRP.Blink or {}

----------------------------------------------------
-- Client-side blink state
----------------------------------------------------
TDMRP.Blink.RemainingCharges = 3
TDMRP.Blink.NextChargeTime = 0
TDMRP.Blink.LastBlinkAttempt = 0
TDMRP.Blink.ActiveTracers = {} -- Store active tracer effects
TDMRP.Blink.DebugMode = false -- Debug mode disabled

print("[TDMRP Blink] Client state initialized, charges: " .. TDMRP.Blink.RemainingCharges)

----------------------------------------------------
-- Helper: Draw filled circle (GMod doesn't have draw.Circle)
----------------------------------------------------
local function DrawFilledCircle(x, y, radius, color)
    local segments = 32
    local poly = {}
    for i = 0, segments do
        local angle = math.rad((i / segments) * 360)
        table.insert(poly, {
            x = x + math.cos(angle) * radius,
            y = y + math.sin(angle) * radius
        })
    end
    surface.SetDrawColor(color)
    draw.NoTexture()
    surface.DrawPoly(poly)
end

----------------------------------------------------
-- Helper: Draw circle outline
----------------------------------------------------
local function DrawCircleOutline(x, y, radius, color, thickness)
    thickness = thickness or 2
    local segments = 32
    surface.SetDrawColor(color)
    for i = 0, segments - 1 do
        local angle1 = math.rad((i / segments) * 360)
        local angle2 = math.rad(((i + 1) / segments) * 360)
        local x1 = x + math.cos(angle1) * radius
        local y1 = y + math.sin(angle1) * radius
        local x2 = x + math.cos(angle2) * radius
        local y2 = y + math.sin(angle2) * radius
        surface.DrawLine(x1, y1, x2, y2)
    end
end

----------------------------------------------------
-- Input Detection: Shift+Alt for Blink
----------------------------------------------------
hook.Add("Think", "TDMRP_BlinkInputDetect", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- Get job name using DarkRP method
    local jobName = team.GetName(ply:Team())
    if not jobName then return end
    
    -- Check player's skill
    local skill = TDMRP.ActiveSkills and TDMRP.ActiveSkills.GetSkillForJob and TDMRP.ActiveSkills.GetSkillForJob(jobName)
    if skill ~= "blink" then return end
    
    -- Check if both Alt (IN_WALK) and Shift (IN_SPEED) are pressed
    local altPressed = ply:KeyDown(IN_WALK)
    local shiftPressed = ply:KeyDown(IN_SPEED)
    
    if altPressed and shiftPressed then
        -- Prevent spam - only send once per 0.3 seconds
        if CurTime() > (TDMRP.Blink.LastBlinkAttempt or 0) + 0.3 then
            TDMRP.Blink.LastBlinkAttempt = CurTime()
            
            -- Check if we have charges
            if TDMRP.Blink.RemainingCharges > 0 then
                print("[TDMRP Blink] Sending blink request, charges: " .. TDMRP.Blink.RemainingCharges)
                -- Send blink request to server
                net.Start("TDMRP_BlinkRequest")
                net.SendToServer()
            else
                -- No charges, show message
                chat.AddText(Color(255, 100, 100), "[Blink] No charges available!")
            end
        end
    end
end)

----------------------------------------------------
-- Network: Receive charge updates
----------------------------------------------------
net.Receive("TDMRP_BlinkChargesUpdate", function()
    TDMRP.Blink.RemainingCharges = net.ReadUInt(3)
    TDMRP.Blink.NextChargeTime = net.ReadFloat()
    print("[TDMRP Blink Client] Charges updated: " .. TDMRP.Blink.RemainingCharges .. " remaining, next charge in: " .. TDMRP.Blink.NextChargeTime .. "s")
end)

----------------------------------------------------
-- Network: Receive blink execution (for tracer effects)
----------------------------------------------------
net.Receive("TDMRP_BlinkExecute", function()
    local startPos = net.ReadVector()
    local endPos = net.ReadVector()
    local blinkEntity = net.ReadEntity()
    
    -- Create tracer effect
    TDMRP.Blink.CreateRainbowTracer(startPos, endPos)
end)

----------------------------------------------------
-- Rainbow Tracer Effect (Nyan Cat style)
-- Draws a 2D rainbow effect trail from start to end position
----------------------------------------------------
function TDMRP.Blink.CreateRainbowTracer(startPos, endPos)
    local tracer = {
        startPos = startPos,
        endPos = endPos,
        startTime = CurTime(),
        duration = 0.5, -- Effect lasts 0.5 seconds
        segments = 30 -- Number of rainbow segments
    }
    
    table.insert(TDMRP.Blink.ActiveTracers, tracer)
end

----------------------------------------------------
-- Rainbow color cycle function
----------------------------------------------------
local function GetRainbowColor(index, maxIndex)
    local hue = (index / maxIndex) * 360
    local sat = 1.0
    local val = 1.0
    
    -- Simple HSV to RGB conversion
    local c = val * sat
    local h = hue / 60
    local x = c * (1 - math.abs((h % 2) - 1))
    
    local r, g, b
    if h < 1 then r, g, b = c, x, 0
    elseif h < 2 then r, g, b = x, c, 0
    elseif h < 3 then r, g, b = 0, c, x
    elseif h < 4 then r, g, b = 0, x, c
    elseif h < 5 then r, g, b = x, 0, c
    else r, g, b = c, 0, x
    end
    
    local m = val - c
    r, g, b = (r + m) * 255, (g + m) * 255, (b + m) * 255
    
    return Color(r, g, b, 255)
end

----------------------------------------------------
-- Draw rainbow tracers
----------------------------------------------------
hook.Add("PostDrawTranslucentRenderables", "TDMRP_BlinkTracers", function()
    local cam = GetViewEntity()
    if not IsValid(cam) then return end
    
    -- Clean up expired tracers
    for i = #TDMRP.Blink.ActiveTracers, 1, -1 do
        local tracer = TDMRP.Blink.ActiveTracers[i]
        local elapsed = CurTime() - tracer.startTime
        
        if elapsed > tracer.duration then
            table.remove(TDMRP.Blink.ActiveTracers, i)
        end
    end
    
    -- Draw active tracers
    for _, tracer in ipairs(TDMRP.Blink.ActiveTracers) do
        local elapsed = CurTime() - tracer.startTime
        local progress = elapsed / tracer.duration
        local fadeOut = 1 - progress -- Fade out over time
        
        -- Draw rainbow segments
        for i = 0, tracer.segments - 1 do
            local t1 = i / tracer.segments
            local t2 = (i + 1) / tracer.segments
            
            -- Interpolate positions
            local pos1 = tracer.startPos + (tracer.endPos - tracer.startPos) * t1
            local pos2 = tracer.startPos + (tracer.endPos - tracer.startPos) * t2
            
            -- Convert to screen space
            local screenPos1 = pos1:ToScreen()
            local screenPos2 = pos2:ToScreen()
            
            -- Get rainbow color for this segment
            local color = GetRainbowColor(i, tracer.segments)
            color.a = 255 * fadeOut * 0.8
            
            -- Draw line segment
            surface.SetDrawColor(color)
            surface.DrawLine(screenPos1.x, screenPos1.y, screenPos2.x, screenPos2.y)
            
            -- Draw wider trail for visual effect (double line offset)
            surface.SetDrawColor(color.r, color.g, color.b, color.a / 2)
            surface.DrawLine(screenPos1.x + 1, screenPos1.y + 1, screenPos2.x + 1, screenPos2.y + 1)
            surface.DrawLine(screenPos1.x - 1, screenPos1.y - 1, screenPos2.x - 1, screenPos2.y - 1)
        end
    end
end)

----------------------------------------------------
-- HUD: Draw blink charge indicator
-- This will be drawn alongside active skill display
----------------------------------------------------
hook.Add("HUDPaint", "TDMRP_BlinkHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- Get job name using DarkRP method
    local jobName = team.GetName(ply:Team())
    if not jobName then return end
    
    -- Only show if player has blink skill
    local skill = TDMRP.ActiveSkills and TDMRP.ActiveSkills.GetSkillForJob and TDMRP.ActiveSkills.GetSkillForJob(jobName)
    
    if skill ~= "blink" then 
        return 
    end
    
    -- Position: Left side, keep same Y values
    local scrW, scrH = ScrW(), ScrH()
    local x = 120
    local y = scrH - 210  -- moved right 10 and up 10 from previous position

    -- Title (left-side layout)
    draw.SimpleText("BLINK CHARGES", "DermaDefault", x + 110, y + 8, Color(100, 200, 255, 255), TEXT_ALIGN_CENTER)
    
    -- Draw 3 charge circles (centered horizontally)
    local chargeRadius = 12
    local chargeSpacing = 30
    local centerX = x + 110 -- panel center (panel width 220)
    local chargeStartX = centerX - chargeSpacing -- center the three circles
    local chargeY = y + 38

    for i = 1, 3 do
        local chargeX = chargeStartX + (i - 1) * chargeSpacing

        -- Available charge (filled) or recharging (outline)
        if i <= TDMRP.Blink.RemainingCharges then
            -- Charged - filled circle (bright blue)
            DrawFilledCircle(chargeX, chargeY, chargeRadius, Color(100, 200, 255, 255))

            -- Inner glow
            DrawFilledCircle(chargeX, chargeY, chargeRadius - 3, Color(150, 220, 255, 150))
        else
            -- Recharging - outline with timer
            DrawCircleOutline(chargeX, chargeY, chargeRadius, Color(100, 100, 100, 200), 2)

            -- Show recharge progress for the next charge
            if i == TDMRP.Blink.RemainingCharges + 1 and TDMRP.Blink.NextChargeTime > 0 then
                local timeLeft = TDMRP.Blink.NextChargeTime

                -- Timer text
                draw.SimpleText(math.ceil(timeLeft) .. "s", "DermaDefault", chargeX, chargeY, Color(150, 150, 255, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    -- (Removed status and keybind text per request)
end)

print("[TDMRP] cl_tdmrp_blink.lua loaded (client blink logic)")
