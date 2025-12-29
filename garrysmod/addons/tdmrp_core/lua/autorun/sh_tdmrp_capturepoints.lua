----------------------------------------------------
-- TDMRP Capture Points System - Shared Layer
----------------------------------------------------

TDMRP = TDMRP or {}
TDMRP.CapturePoints = TDMRP.CapturePoints or {}

if SERVER then
    AddCSLuaFile()
end

----------------------------------------------------
-- Constants
----------------------------------------------------
TDMRP.CapturePoints.CAPTURE_TIME_PER_PHASE = 10  -- seconds (neutral->cop, cop->crim, etc.)
TDMRP.CapturePoints.CAPTURE_RADIUS = 200         -- units
TDMRP.CapturePoints.INACTIVITY_TIMEOUT = 30      -- seconds before decay starts
TDMRP.CapturePoints.PASSIVE_REWARD_INTERVAL = 90 -- seconds (all 5 captured)
TDMRP.CapturePoints.PLAYER_PROXIMITY_CHECK = 0.1 -- seconds (server think hook frequency)

----------------------------------------------------
-- Ownership States
----------------------------------------------------
TDMRP.CapturePoints.OWNER_NEUTRAL = 0
TDMRP.CapturePoints.OWNER_COP = 1
TDMRP.CapturePoints.OWNER_CRIM = 2
TDMRP.CapturePoints.OWNER_CONTESTED = 3

----------------------------------------------------
-- Capture Point Definitions
----------------------------------------------------
TDMRP.CapturePoints.Points = {
    TS = {
        id = "TS",
        name = "Train Station",
        position = Vector(1336.43, -4591.97, 656.03),
        yaw = 90,  -- North
        radius = TDMRP.CapturePoints.CAPTURE_RADIUS,
        displayOffset = Vector(15, 18, 90),  -- Offset from position for display panel
        displayAngle = Angle(0, 180, 90),   -- Angle for display panel
        owner = TDMRP.CapturePoints.OWNER_NEUTRAL,
        progress = 0,
        last_interaction = 0,
        captured_by = nil  -- nil, "cop", or "crim"
    },
    
    CoS = {
        id = "CoS",
        name = "Cop Spawn",
        position = Vector(3658.75, 1703.97, 656.03),
        yaw = 270,  -- South
        radius = TDMRP.CapturePoints.CAPTURE_RADIUS,
        displayOffset = Vector(-15, -18, 90),
        displayAngle = Angle(0, 0, 90),
        owner = TDMRP.CapturePoints.OWNER_NEUTRAL,
        progress = 0,
        last_interaction = 0,
        captured_by = nil
    },
    
    MT = {
        id = "MT",
        name = "Movie Theater",
        position = Vector(-2423.97, 2251.86, 840.03),
        yaw = 0,  -- East
        radius = TDMRP.CapturePoints.CAPTURE_RADIUS,
        displayOffset = Vector(18, -15, 90),
        displayAngle = Angle(0, 90, 90),
        owner = TDMRP.CapturePoints.OWNER_NEUTRAL,
        progress = 0,
        last_interaction = 0,
        captured_by = nil
    },
    
    CrS = {
        id = "CrS",
        name = "Criminal Spawn",
        position = Vector(-2767.97, 5470.38, 848.03),
        yaw = 0,  -- East
        radius = TDMRP.CapturePoints.CAPTURE_RADIUS,
        displayOffset = Vector(18, -15, 90),
        displayAngle = Angle(0, 90, 90),
        owner = TDMRP.CapturePoints.OWNER_NEUTRAL,
        progress = 0,
        last_interaction = 0,
        captured_by = nil
    },
    
    BA = {
        id = "BA",
        name = "Back Alley",
        position = Vector(2127.97, 2542.67, 1152.03),
        yaw = 180,  -- South
        radius = TDMRP.CapturePoints.CAPTURE_RADIUS,
        displayOffset = Vector(-18, 15, 90),
        displayAngle = Angle(0, -90, 90),
        owner = TDMRP.CapturePoints.OWNER_NEUTRAL,
        progress = 0,
        last_interaction = 0,
        captured_by = nil
    },
}

----------------------------------------------------
-- Helper: Get point by ID
----------------------------------------------------
function TDMRP.CapturePoints.GetPointByID(id)
    return TDMRP.CapturePoints.Points[id]
end

----------------------------------------------------
-- Helper: Get all points
----------------------------------------------------
function TDMRP.CapturePoints.GetAllPoints()
    return TDMRP.CapturePoints.Points
end

----------------------------------------------------
-- Helper: Count owned points for a team
----------------------------------------------------
function TDMRP.CapturePoints.CountOwnedByTeam(teamOwner)
    local count = 0
    for id, point in pairs(TDMRP.CapturePoints.Points) do
        if point.owner == teamOwner then
            count = count + 1
        end
    end
    return count
end

----------------------------------------------------
-- Helper: Check if team controls all 5 points
----------------------------------------------------
function TDMRP.CapturePoints.TeamControlsAll(teamOwner)
    return TDMRP.CapturePoints.CountOwnedByTeam(teamOwner) == 5
end

----------------------------------------------------
-- Helper: Get owner name for display
----------------------------------------------------
function TDMRP.CapturePoints.GetOwnerName(owner)
    if owner == TDMRP.CapturePoints.OWNER_COP then
        return "Cops"
    elseif owner == TDMRP.CapturePoints.OWNER_CRIM then
        return "Criminals"
    else
        return "Neutral"
    end
end

----------------------------------------------------
-- Helper: Get owner color
----------------------------------------------------
function TDMRP.CapturePoints.GetOwnerColor(owner)
    if owner == TDMRP.CapturePoints.OWNER_COP then
        return Color(80, 150, 255, 255)  -- Blue
    elseif owner == TDMRP.CapturePoints.OWNER_CRIM then
        return Color(255, 120, 0, 255)  -- Orange
    elseif owner == TDMRP.CapturePoints.OWNER_CONTESTED then
        return Color(255, 0, 0, 255)  -- Red
    else
        return Color(255, 255, 255, 255)  -- White (Neutral)
    end
end

print("[TDMRP] Capture Points system loaded (shared)")
