----------------------------------------------------
-- TDMRP Capture Points HUD Display (Client)
----------------------------------------------------

if SERVER then return end

TDMRP.CapturePoints.LocalData = TDMRP.CapturePoints.LocalData or {}
TDMRP.CapturePoints.Notifications = TDMRP.CapturePoints.Notifications or {}

-- Create font for HUD
surface.CreateFont("TDMRP_CapturePointsHUD", {
    font = "Tahoma",
    size = 16,
    weight = 900,
    antialias = true
})

surface.CreateFont("TDMRP_CapturePointsNotif", {
    font = "Tahoma",
    size = 14,
    weight = 700,
    antialias = true
})

----------------------------------------------------
-- Network handler: Point update
----------------------------------------------------
net.Receive("TDMRP_CapturePointUpdate", function()
    local pointID = net.ReadString()
    local owner = net.ReadUInt(2)
    local progress = net.ReadFloat()
    local capturedBy = net.ReadString()
    
    TDMRP.CapturePoints.LocalData[pointID] = {
        owner = owner,
        progress = progress,
        capturedBy = capturedBy
    }
end)

----------------------------------------------------
-- Network handler: Capture announcement
----------------------------------------------------
net.Receive("TDMRP_CapturePointCaptured", function()
    local pointID = net.ReadString()
    local capturedBy = net.ReadString()
    local pointName = net.ReadString()
    
    -- Add notification
    table.insert(TDMRP.CapturePoints.Notifications, {
        pointID = pointID,
        pointName = pointName,
        capturedBy = capturedBy,
        created = CurTime(),
        duration = 5  -- Show for 5 seconds
    })
end)

----------------------------------------------------
-- Draw notifications
----------------------------------------------------
local function DrawNotifications(baseX, baseY)
    surface.SetFont("TDMRP_CapturePointsNotif")
    
    local notifY = baseY
    local now = CurTime()
    
    for i = #TDMRP.CapturePoints.Notifications, 1, -1 do
        local notif = TDMRP.CapturePoints.Notifications[i]
        
        -- Check if notification expired
        if now - notif.created > notif.duration then
            table.remove(TDMRP.CapturePoints.Notifications, i)
            continue
        end
        
        -- Calculate fade
        local age = now - notif.created
        local alpha = 255 * (1 - (age / notif.duration))
        
        -- Get team color
        local textColor = Color(255, 255, 255, alpha)
        if notif.capturedBy == "cop" then
            textColor = Color(80, 150, 255, alpha)
        elseif notif.capturedBy == "criminal" then
            textColor = Color(255, 120, 0, alpha)
        end
        
        -- Draw notification
        local text = "✓ " .. TDMRP.CapturePoints.GetOwnerName(
            (notif.capturedBy == "cop") and TDMRP.CapturePoints.OWNER_COP or TDMRP.CapturePoints.OWNER_CRIM
        ) .. " captured " .. notif.pointName
        
        draw.SimpleText(text, "TDMRP_CapturePointsNotif", baseX, notifY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        notifY = notifY + 25
    end
end

----------------------------------------------------
-- Draw HUD
----------------------------------------------------
local function DrawCapturePointsHUD()
    -- Show to ALL players (not just combat roles)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- HUD position: top left (matching original Bob's TDMRP design)
    local hudX = 20
    local hudY = 20
    local spacing = 60  -- Space between point acronyms
    
    surface.SetFont("TDMRP_CapturePointsHUD")
    
    -- Draw 5 points in a single horizontal row (left to right)
    local pointOrder = {"CrS", "MT", "TS", "BA", "CoS"}
    
    for idx, pointID in ipairs(pointOrder) do
        local data = TDMRP.CapturePoints.LocalData[pointID]
        
        -- Even without data, show placeholder
        if not data then
            data = {
                owner = TDMRP.CapturePoints.OWNER_NEUTRAL,
                progress = 0
            }
        end
        
        local x = hudX + ((idx - 1) * spacing)
        local y = hudY
        
        -- Get color based on owner
        local textColor = Color(255, 255, 255, 255)  -- Default white (neutral)
        
        if data.owner == TDMRP.CapturePoints.OWNER_COP then
            textColor = Color(80, 150, 255, 255)  -- Blue
        elseif data.owner == TDMRP.CapturePoints.OWNER_CRIM then
            textColor = Color(255, 120, 0, 255)  -- Orange
        elseif data.owner == TDMRP.CapturePoints.OWNER_CONTESTED then
            textColor = Color(255, 0, 0, 255)  -- Red (contested)
        end
        
        -- Draw point acronym
        draw.SimpleText(pointID, "TDMRP_CapturePointsHUD", x, y, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Draw notifications below HUD (offset down)
    DrawNotifications(hudX, hudY + 50)
end

----------------------------------------------------
-- Draw on HUDPaint
----------------------------------------------------
hook.Add("HUDPaint", "TDMRP_CapturePointsHUD", function()
    DrawCapturePointsHUD()
end)

print("[TDMRP] Capture Points HUD loaded")
