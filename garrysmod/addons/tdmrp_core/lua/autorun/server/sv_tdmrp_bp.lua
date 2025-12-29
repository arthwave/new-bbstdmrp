-- sv_tdmrp_bp.lua
-- Server-side BP generation + loading on join

if not SERVER then return end

-- Load BP from disk when player first joins
local function TDMRP_LoadBP(ply)
    if not IsValid(ply) or not ply.SteamID64 then return end

    local sid = ply:SteamID64()
    if not sid then return end

    if not file.IsDir("tdmrp_bp", "DATA") then
        file.CreateDir("tdmrp_bp")
    end

    local path = "tdmrp_bp/" .. sid .. ".txt"

    if file.Exists(path, "DATA") then
        local contents = file.Read(path, "DATA") or "0"
        local value = tonumber(contents) or 0
        ply:SetBP(value)
    else
        ply:SetBP(0)
    end
end

hook.Add("PlayerInitialSpawn", "TDMRP_LoadBP_OnJoin", function(ply)
    TDMRP_LoadBP(ply)
end)

-- Optional: save once more on disconnect (just in case)
hook.Add("PlayerDisconnected", "TDMRP_SaveBP_OnLeave", function(ply)
    if ply.GetBP then
        local bp = ply:GetBP()
        if not file.IsDir("tdmrp_bp", "DATA") then
            file.CreateDir("tdmrp_bp")
        end
        local sid = ply:SteamID64()
        if not sid then return end
        file.Write("tdmrp_bp/" .. sid .. ".txt", tostring(bp or 0))
    end
end)

-- BP generation over time
local BP_PER_TICK = 1          -- 1 BP
local BP_TICK_INTERVAL = 60    -- every 60 seconds

timer.Create("TDMRP_BP_Generator", BP_TICK_INTERVAL, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:IsPlayer() and ply.AddBP then
            ply:AddBP(BP_PER_TICK)
        end
    end
end)