----------------------------------------------------
-- TDMRP Capture Points Debug Helper
-- Use to get coordinates for capture point placement
----------------------------------------------------

if not SERVER then return end

----------------------------------------------------
-- Command: Print current player position
----------------------------------------------------
concommand.Add("tdmrp_getpos", function(ply, cmd, args)
    if not IsValid(ply) then 
        print("[TDMRP] Console player detected, cannot get position")
        return 
    end
    
    local pos = ply:GetPos()
    local posStr = string.format("Vector(%.2f, %.2f, %.2f)", pos.x, pos.y, pos.z)
    
    -- Print to player's chat
    ply:ChatPrint("[TDMRP] Your position: " .. posStr)
    
    -- Print to console (both player and server)
    print("[TDMRP] " .. ply:GetName() .. " position: " .. posStr)
    
    -- Also print with Lua table format for easy copy-paste
    print("  Lua format: {x = " .. pos.x .. ", y = " .. pos.y .. ", z = " .. pos.z .. "}")
end, nil, "Print your current position (for capture point placement)")

----------------------------------------------------
-- Alternative: Print all nearby players and their positions
----------------------------------------------------
concommand.Add("tdmrp_getpos_nearby", function(ply, cmd, args)
    local radius = tonumber(args[1]) or 300
    
    if not IsValid(ply) then 
        print("[TDMRP] Console player detected")
        return 
    end
    
    local pos = ply:GetPos()
    print("[TDMRP] Searching for players within " .. radius .. " units of " .. tostring(pos))
    
    for _, target in ipairs(player.GetAll()) do
        if target:GetPos():Distance(pos) <= radius then
            local tpos = target:GetPos()
            local dist = target:GetPos():Distance(pos)
            print("  " .. target:GetName() .. " (" .. string.format("%.1f", dist) .. "u away): Vector(" .. 
                  string.format("%.2f", tpos.x) .. ", " .. string.format("%.2f", tpos.y) .. ", " .. 
                  string.format("%.2f", tpos.z) .. ")")
        end
    end
end, nil, "Print positions of nearby players (optional radius in units, default 300)")

print("[TDMRP] Capture Points debug helper loaded")
print("[TDMRP] Use 'tdmrp_getpos' command in-game to print your position")
