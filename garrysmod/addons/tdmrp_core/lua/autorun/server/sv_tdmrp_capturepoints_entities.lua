----------------------------------------------------
-- TDMRP Capture Points Entity Spawning
----------------------------------------------------

if CLIENT then return end

TDMRP.CapturePoints.Entities = TDMRP.CapturePoints.Entities or {}

----------------------------------------------------
-- Spawn all capture point entities
----------------------------------------------------
local function SpawnCapturePointEntities()
    -- Clear existing display entities first
    for _, ent in ipairs(ents.FindByClass("ent_tdmrp_capture_display")) do
        ent:Remove()
    end
    
    -- Safety check: ensure core system is loaded
    if not TDMRP.CapturePoints.GetAllPoints then
        print("[TDMRP] ERROR: GetAllPoints not available yet")
        return
    end
    
    local points = TDMRP.CapturePoints.GetAllPoints()
    if not points or table.Count(points) == 0 then
        print("[TDMRP] ERROR: No capture points found")
        return
    end
    
    for pointID, point in pairs(points) do
        -- Spawn display entity
        local ent = ents.Create("ent_tdmrp_capture_display")
        
        if not IsValid(ent) then
            print("[TDMRP] Failed to create capture point entity for " .. pointID)
            continue
        end
        
        ent:SetPos(point.position)  -- Ground level
        ent:SetAngles(Angle(0, point.yaw or 0, 0))  -- Apply yaw rotation
        ent:Spawn()
        
        -- Store metadata via networked vars
        ent:SetNWString("TDMRP_CapturePointID", tostring(pointID))
        ent:SetNWString("TDMRP_CapturePointName", point.name)
        ent:SetNWInt("TDMRP_CapturePointOwner", 0)  -- NEUTRAL
        ent:SetNWInt("TDMRP_CapturePointProgress", 0)
        
        TDMRP.CapturePoints.Entities[pointID] = ent
        
        print("[TDMRP] Spawned capture point display: " .. pointID .. " (" .. point.name .. ") at " .. tostring(point.position))
    end
    print("[TDMRP] Total capture point displays spawned: " .. table.Count(TDMRP.CapturePoints.Entities))
end

----------------------------------------------------
-- Update capture point visuals
----------------------------------------------------
local function UpdateCapturePointVisuals()
    for pointID, ent in pairs(TDMRP.CapturePoints.Entities) do
        if not IsValid(ent) then continue end
        
        local data = TDMRP.CapturePoints.PointData[pointID]
        if not data then continue end
        
        -- Sync networked vars to clients for rendering
        ent:SetNWInt("TDMRP_CapturePointOwner", data.owner)
        ent:SetNWInt("TDMRP_CapturePointProgress", math.floor(data.progress))
    end
end

----------------------------------------------------
-- Spawn entities on server start
----------------------------------------------------
timer.Simple(5, function()
    SpawnCapturePointEntities()
    print("[TDMRP] Capture point entities spawned")
end)

----------------------------------------------------
-- Update visuals every frame
----------------------------------------------------
hook.Add("Think", "TDMRP_UpdateCapturePointVisuals", function()
    UpdateCapturePointVisuals()
end)

print("[TDMRP] Capture Points entity system loaded")
