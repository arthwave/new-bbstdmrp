ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Capture Point"
ENT.Author = "TDMRP"
ENT.Purpose = "Control point for team capture objectives"

ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "PointID")
    self:NetworkVar("Int", 0, "Owner")
    self:NetworkVar("Float", 0, "Progress")
end

-- Point metadata indexed by ID
local POINT_META = {
    ["TS"] = { name = "Training Sector", x = 1336.43, y = -4591.97, z = 656.03 },
    ["CoS"] = { name = "Center of Sector", x = 3658.75, y = 1703.97, z = 656.03 },
    ["MT"] = { name = "Manufacturing Tower", x = -2423.97, y = 2251.86, z = 840.03 },
    ["CrS"] = { name = "Crystalline Structure", x = -2767.97, y = 5470.38, z = 848.03 },
    ["BA"] = { name = "Bridge Approach", x = 2127.97, y = 2542.67, z = 1152.03 },
}

function ENT:GetPointMeta()
    return POINT_META[self:GetPointID()] or { name = "Unknown" }
end

function ENT:GetColorForOwner(owner)
    if owner == 1 then  -- COP
        return Color(80, 150, 255, 255)
    elseif owner == 2 then  -- CRIMINAL
        return Color(255, 120, 0, 255)
    elseif owner == 3 then  -- CONTESTED
        return Color(255, 0, 0, 255)
    else  -- NEUTRAL
        return Color(200, 200, 200, 255)
    end
end
