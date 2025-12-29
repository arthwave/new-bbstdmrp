-- ent_tdmrp_capture_display/init.lua
-- Server-side capture point display entity
-- Syncs capture point data to clients for rendering

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Local ownership constants
local OWNER_NEUTRAL = 0

function ENT:Initialize()
    self:SetModel("models/props/cs_assault/TicketMachine.mdl")
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)  -- Allow player collision
    
    -- Default color (darkened)
    self:SetColor(Color(30, 30, 30, 255))
    
    -- Initialize networked variables
    self:SetNWInt("TDMRP_CapturePointID", 0)
    self:SetNWInt("TDMRP_CapturePointOwner", OWNER_NEUTRAL)      -- 0=neutral, 1=cop, 2=crim, 3=contested
    self:SetNWInt("TDMRP_CapturePointProgress", 0)   -- 0-100
    self:SetNWString("TDMRP_CapturePointID", "")     -- String ID like "TS", "CoS", etc.
    self:SetNWString("TDMRP_CapturePointName", "")
end

function ENT:Think()
    -- Keep syncing data from capture points system
    local pointID = self:GetNWString("TDMRP_CapturePointID", "")
    if pointID ~= "" and TDMRP and TDMRP.CapturePoints then
        local pointData = TDMRP.CapturePoints.PointData[pointID]
        if pointData then
            self:SetNWInt("TDMRP_CapturePointOwner", pointData.owner)
            self:SetNWInt("TDMRP_CapturePointProgress", math.floor(pointData.progress))
        end
    end
    
    self:NextThink(CurTime() + 0.1)
    return true
end
