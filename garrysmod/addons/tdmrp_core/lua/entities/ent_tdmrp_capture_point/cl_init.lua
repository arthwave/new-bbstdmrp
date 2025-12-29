function ENT:Initialize()
    -- Client-only setup
end

function ENT:Draw()
    -- Draw the base model
    self:DrawModel()
    
    -- 3D overlay rendering
    self:DrawCapturePointVisuals()
end

function ENT:DrawCapturePointVisuals()
    local pos = self:GetPos()
    local owner = self:GetOwner()
    local progress = self:GetProgress()
    local pointID = self:GetPointID()
    local meta = self:GetPointMeta()
    
    -- Calculate status bar position (above entity)
    local barPos = pos + Vector(0, 0, 80)
    local barWidth = 60
    local barHeight = 4
    local barColor = self:GetColorForOwner(owner)
    
    -- Draw status bar background
    local camPos = LocalPlayer():GetCamPos()
    local distToBar = barPos:Distance(camPos)
    
    if distToBar > 3000 then return end  -- Don't render if too far
    
    -- Setup 3D rendering
    cam.Start3D(camPos)
    
    -- Draw background bar
    render.SetMaterial(Material("white"))
    render.DrawQuadEasy(
        barPos,
        EyeVector(),
        barWidth,
        barHeight,
        Color(30, 30, 30, 200),
        0
    )
    
    -- Draw progress bar
    if progress > 0 then
        render.DrawQuadEasy(
            barPos + Vector((-barWidth / 2) + (barWidth * progress / 2), 0, 0),
            EyeVector(),
            barWidth * progress,
            barHeight,
            barColor,
            0
        )
    end
    
    cam.End3D()
    
    -- Draw point name text (2D screen space)
    local screenPos = pos:ToScreen()
    if screenPos.visible then
        surface.SetFont("TDMRP_CapturePointsHUD")
        
        local textWidth = surface.GetTextSize(pointID)
        draw.SimpleText(
            pointID,
            "TDMRP_CapturePointsHUD",
            screenPos.x,
            screenPos.y - 30,
            barColor,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER
        )
        
        -- Draw capture radius indicator (thin circle outline) when nearby
        local ply = LocalPlayer()
        if IsValid(ply) and ply:GetPos():Distance(pos) < 300 then
            surface.SetDrawColor(barColor.r, barColor.g, barColor.b, 100)
            
            -- Simple circle outline
            for angle = 0, 359, 10 do
                local rad = math.rad(angle)
                local x1 = screenPos.x + math.cos(rad) * 20
                local y1 = screenPos.y + math.sin(rad) * 20
                
                local rad2 = math.rad(angle + 10)
                local x2 = screenPos.x + math.cos(rad2) * 20
                local y2 = screenPos.y + math.sin(rad2) * 20
                
                surface.DrawLine(x1, y1, x2, y2)
            end
        end
    end
end
