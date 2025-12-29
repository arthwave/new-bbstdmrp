-- ent_tdmrp_capture_display/cl_init.lua
-- Client-side rendering for capture point display

include("shared.lua")

-- Ownership constants
local OWNER_NEUTRAL = 0
local OWNER_COP = 1
local OWNER_CRIM = 2
local OWNER_CONTESTED = 3

-- Color mapping
local OWNER_COLORS = {
    [OWNER_NEUTRAL] = Color(200, 200, 200, 255),      -- White
    [OWNER_COP] = Color(80, 150, 255, 255),           -- Blue
    [OWNER_CRIM] = Color(255, 150, 40, 255),          -- Orange
    [OWNER_CONTESTED] = Color(255, 50, 50, 255),      -- Red
}

local OWNER_NAMES = {
    [OWNER_NEUTRAL] = "NEUTRAL",
    [OWNER_COP] = "POLICE",
    [OWNER_CRIM] = "CRIMINAL",
    [OWNER_CONTESTED] = "CONTESTED",
}

function ENT:Draw()
    self:DrawModel()
    
    -- Only render display if within 3000 units
    local camPos = LocalPlayer():EyePos()
    local entPos = self:GetPos()
    if camPos:Distance(entPos) > 3000 then return end
    
    -- Get data from networked vars
    local pointID = self:GetNWString("TDMRP_CapturePointID", "")
    if pointID == "" then return end
    
    local owner = tonumber(self:GetNWInt("TDMRP_CapturePointOwner", 0)) or 0
    local progress = tonumber(self:GetNWInt("TDMRP_CapturePointProgress", 0)) or 0
    local pointName = self:GetNWString("TDMRP_CapturePointName", "Point " .. pointID)
    
    -- Get display position and angle from shared definitions
    local displayOffset = Vector(8, 0, 25)  -- Default fallback
    local displayAngle = Angle(0, 0, 90)   -- Default fallback
    
    if TDMRP and TDMRP.CapturePoints and TDMRP.CapturePoints.Points and TDMRP.CapturePoints.Points[pointID] then
        local point = TDMRP.CapturePoints.Points[pointID]
        displayOffset = point.displayOffset or displayOffset
        displayAngle = point.displayAngle or displayAngle
    end
    
    -- Calculate panel position using the global offset
    local offsetPos = entPos + displayOffset
    
    -- Render 3D text panel using cam.Start3D2D with global angle
    cam.Start3D2D(offsetPos, displayAngle, 0.1)
        
        -- Background panel
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(0, 0, 300, 200)
        
        -- Border
        local borderColor = OWNER_COLORS[owner] or OWNER_COLORS[OWNER_NEUTRAL]
        surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, 255)
        surface.DrawOutlinedRect(0, 0, 300, 200, 3)
        
        -- Point Name (top)
        surface.SetFont("DermaLarge")
        surface.SetTextColor(255, 255, 255, 255)
        surface.SetTextPos(10, 10)
        surface.DrawText(pointName)
        
        -- Owner Status (middle)
        local statusText = OWNER_NAMES[owner] or "UNKNOWN"
        surface.SetFont("DermaDefault")
        surface.SetTextColor(borderColor.r, borderColor.g, borderColor.b, 255)
        surface.SetTextPos(10, 60)
        surface.DrawText(statusText)
        
        -- Progress bar background
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawRect(10, 100, 280, 30)
        
        -- Progress bar fill
        local fillWidth = math.max(0, (progress / 100) * 280)
        surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, 200)
        surface.DrawRect(10, 100, fillWidth, 30)
        
        -- Progress text
        surface.SetFont("DermaDefault")
        surface.SetTextColor(255, 255, 255, 255)
        surface.SetTextPos(20, 110)
        surface.DrawText(progress .. "%")
        
    cam.End3D2D()
end
