-- sh_tdmrp_bp.lua
-- Shared BP (Bob Points) helper functions + simple persistence

local PLAYER = FindMetaTable("Player")

-- Internal: save BP to data/ by SteamID64 (server-side only)
local function TDMRP_SaveBP(ply, value)
    if not SERVER then return end
    if not IsValid(ply) or not ply.SteamID64 then return end

    local sid = ply:SteamID64()
    if not sid then return end

    if not file.IsDir("tdmrp_bp", "DATA") then
        file.CreateDir("tdmrp_bp")
    end

    local path = "tdmrp_bp/" .. sid .. ".txt"
    file.Write(path, tostring(value or 0))
end

-- Get current BP (Bob Points)
function PLAYER:GetBP()
    return self:GetNWInt("TDMRP_BP", 0)
end

-- Set BP directly
function PLAYER:SetBP(amount)
    local value = math.max(0, math.floor(amount or 0))
    self:SetNWInt("TDMRP_BP", value)

    -- Persist on server
    TDMRP_SaveBP(self, value)
end

-- Add (or subtract) BP
function PLAYER:AddBP(amount)
    if not isnumber(amount) then return end
    self:SetBP(self:GetBP() + amount)
end