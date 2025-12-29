----------------------------------------------------
-- TDMRP Capture Points Core Logic
----------------------------------------------------

if CLIENT then return end

util.AddNetworkString("TDMRP_CapturePointUpdate")
util.AddNetworkString("TDMRP_CapturePointCaptured")

TDMRP.CapturePoints.PointData = TDMRP.CapturePoints.PointData or {}
TDMRP.CapturePoints.PlayerInRadius = TDMRP.CapturePoints.PlayerInRadius or {}
TDMRP.CapturePoints.LastPassiveRewardTime = TDMRP.CapturePoints.LastPassiveRewardTime or 0

----------------------------------------------------
-- Initialize point data from persistence file
----------------------------------------------------
local function InitializePointData()
    local dataPath = "data/tdmrp/capturepoints.json"
    
    -- Create directory if needed
    if not file.Exists("data/tdmrp", "DATA") then
        file.CreateDir("data/tdmrp")
    end
    
    -- Always reset all points to neutral on map start
    -- (Don't load from previous map state)
    for id, point in pairs(TDMRP.CapturePoints.GetAllPoints()) do
        TDMRP.CapturePoints.PointData[id] = {
            owner = TDMRP.CapturePoints.OWNER_NEUTRAL,
            progress = 0,
            last_interaction = CurTime(),
            captured_by = nil
        }
    end
    SavePointData()
    print("[TDMRP] Initialized all capture points to NEUTRAL")
end

----------------------------------------------------
-- Save point data to file
----------------------------------------------------
function SavePointData()
    local dataPath = "data/tdmrp/capturepoints.json"
    local jsonStr = util.TableToJSON(TDMRP.CapturePoints.PointData)
    file.Write(dataPath, jsonStr)
end

----------------------------------------------------
-- Sync point state to all clients
----------------------------------------------------
local function SyncPointToClients(pointID)
    local point = TDMRP.CapturePoints.GetPointByID(pointID)
    local data = TDMRP.CapturePoints.PointData[pointID]
    
    if not point or not data then return end
    
    net.Start("TDMRP_CapturePointUpdate")
        net.WriteString(pointID)
        net.WriteUInt(data.owner, 2)
        net.WriteFloat(data.progress / 100)  -- 0-1 normalized
        net.WriteString(data.captured_by or "")
    net.Broadcast()
end

----------------------------------------------------
-- Get number of players in radius for a team
----------------------------------------------------
local function CountPlayersInRadius(pointID, teamClass)
    local point = TDMRP.CapturePoints.GetPointByID(pointID)
    if not point then return 0 end
    
    local count = 0
    for _, ply in ipairs(player.GetAll()) do
        if not ply:Alive() then continue end
        
        local job = ply:getJobTable()
        if not job or job.tdmrp_class ~= teamClass then continue end
        
        if ply:GetPos():Distance(point.position) <= point.radius then
            count = count + 1
        end
    end
    
    return count
end

----------------------------------------------------
-- Get speed multiplier based on player count
----------------------------------------------------
local function GetCaptureSpeedMultiplier(playerCount)
    if playerCount >= 3 then
        return 1.5
    elseif playerCount == 2 then
        return 1.25
    else
        return 1.0
    end
end

----------------------------------------------------
-- Update capture point progress
----------------------------------------------------
local lastThinkTime = CurTime()
local function UpdateCaptureProgress()
    local now = CurTime()
    local deltaTime = now - lastThinkTime
    lastThinkTime = now
    
    for pointID, point in pairs(TDMRP.CapturePoints.GetAllPoints()) do
        local data = TDMRP.CapturePoints.PointData[pointID]
        if not data then continue end
        
        -- Count cops and crims in radius
        local copCount = CountPlayersInRadius(pointID, "cop")
        local crimCount = CountPlayersInRadius(pointID, "criminal")
        
        -- Check contested state
        if copCount > 0 and crimCount > 0 then
            -- Both teams present = contested (freeze progress, turn red)
            data.owner = TDMRP.CapturePoints.OWNER_CONTESTED
            -- Don't increment progress when contested
        elseif copCount > 0 then
            -- Only cops present
            data.last_interaction = now
            
            -- If crims owned this point, must decay to neutral first before cops can capture
            if data.owner == TDMRP.CapturePoints.OWNER_CRIM and data.progress > 0 then
                -- Decay the crim progress
                local decayRate = 100 / TDMRP.CapturePoints.CAPTURE_TIME_PER_PHASE
                data.progress = data.progress - (decayRate * deltaTime)
                
                if data.progress <= 0 then
                    data.progress = 0
                    data.owner = TDMRP.CapturePoints.OWNER_NEUTRAL
                    data.captured_by = nil
                end
            else
                -- Progress toward cop capture
                local speedMult = GetCaptureSpeedMultiplier(copCount)
                local progressRate = (100 / TDMRP.CapturePoints.CAPTURE_TIME_PER_PHASE) * speedMult
                data.progress = data.progress + (progressRate * deltaTime)
                
                if data.progress >= 100 then
                    -- Capture complete - NOW change owner
                    data.progress = 100
                    if data.owner ~= TDMRP.CapturePoints.OWNER_COP then
                        -- Ownership changed to cop
                        data.owner = TDMRP.CapturePoints.OWNER_COP
                        data.captured_by = "cop"
                        OnPointCaptured(pointID, "cop")
                    else
                        -- Already cop owned, just maintain
                        data.owner = TDMRP.CapturePoints.OWNER_COP
                    end
                end
            end
        elseif crimCount > 0 then
            -- Only crims present
            data.last_interaction = now
            
            -- If cops owned this point, must decay to neutral first before crims can capture
            if data.owner == TDMRP.CapturePoints.OWNER_COP and data.progress > 0 then
                -- Decay the cop progress
                local decayRate = 100 / TDMRP.CapturePoints.CAPTURE_TIME_PER_PHASE
                data.progress = data.progress - (decayRate * deltaTime)
                
                if data.progress <= 0 then
                    data.progress = 0
                    data.owner = TDMRP.CapturePoints.OWNER_NEUTRAL
                    data.captured_by = nil
                end
            else
                -- Progress toward crim capture
                local speedMult = GetCaptureSpeedMultiplier(crimCount)
                local progressRate = (100 / TDMRP.CapturePoints.CAPTURE_TIME_PER_PHASE) * speedMult
                data.progress = data.progress + (progressRate * deltaTime)
                
                if data.progress >= 100 then
                    -- Capture complete - NOW change owner
                    data.progress = 100
                    if data.owner ~= TDMRP.CapturePoints.OWNER_CRIM then
                        -- Ownership changed to crim
                        data.owner = TDMRP.CapturePoints.OWNER_CRIM
                        data.captured_by = "criminal"
                        OnPointCaptured(pointID, "criminal")
                    else
                        -- Already crim owned, just maintain
                        data.owner = TDMRP.CapturePoints.OWNER_CRIM
                    end
                end
            end
        else
            -- No one in radius, start decay after inactivity timeout
            local inactiveTime = now - data.last_interaction
            
            if inactiveTime > TDMRP.CapturePoints.INACTIVITY_TIMEOUT then
                -- Only decay partially captured points (0 < progress < 100)
                -- Fully captured points (progress = 100) stay captured until contested
                if data.owner ~= TDMRP.CapturePoints.OWNER_NEUTRAL and data.progress > 0 and data.progress < 100 then
                    -- Decay rate is proportional to the time it took to capture
                    -- If it took 5s to get to 50%, it should take 5s to decay from 50% to 0%
                    local decayRate = 100 / TDMRP.CapturePoints.CAPTURE_TIME_PER_PHASE
                    data.progress = data.progress - (decayRate * deltaTime)
                    
                    if data.progress <= 0 then
                        data.progress = 0
                        data.owner = TDMRP.CapturePoints.OWNER_NEUTRAL
                        data.captured_by = nil
                    end
                end
            end
        end
        
        SyncPointToClients(pointID)
    end
end

----------------------------------------------------
-- Called when a point is fully captured
----------------------------------------------------
function OnPointCaptured(pointID, capturedBy)
    local point = TDMRP.CapturePoints.GetPointByID(pointID)
    if not point then return end
    
    print("[TDMRP] Point " .. pointID .. " captured by " .. capturedBy)
    
    -- Grant rewards to players in radius
    GrantCaptureRewards(pointID, capturedBy)
    
    -- Check if team now controls all 5 points
    local ownerConstant = (capturedBy == "cop") and TDMRP.CapturePoints.OWNER_COP or TDMRP.CapturePoints.OWNER_CRIM
    if TDMRP.CapturePoints.TeamControlsAll(ownerConstant) then
        OnAllPointsCaptured(capturedBy)
    end
    
    -- Announce capture
    BroadcastCaptureAnnouncement(pointID, capturedBy)
    
    -- Save data
    SavePointData()
end

----------------------------------------------------
-- Called when a team captures all 5 points
----------------------------------------------------
function OnAllPointsCaptured(capturedBy)
    print("[TDMRP] " .. capturedBy .. " captured all 5 points!")
    
    -- Announce globally
    local teamName = (capturedBy == "cop") and "Cops" or "Criminals"
    local msg = "The " .. teamName .. " have captured the city!"
    
    for _, ply in ipairs(player.GetAll()) do
        ply:ChatPrint(msg)
    end
    
    -- Grant gems to team
    GrantAllPointsCapturedRewards(capturedBy)
end

----------------------------------------------------
-- Broadcast capture announcement to clients
----------------------------------------------------
function BroadcastCaptureAnnouncement(pointID, capturedBy)
    local point = TDMRP.CapturePoints.GetPointByID(pointID)
    if not point then return end
    
    net.Start("TDMRP_CapturePointCaptured")
        net.WriteString(pointID)
        net.WriteString(capturedBy)
        net.WriteString(point.name)
    net.Broadcast()
end

----------------------------------------------------
-- Grant on-capture rewards
----------------------------------------------------
function GrantCaptureRewards(pointID, capturedBy)
    local point = TDMRP.CapturePoints.GetPointByID(pointID)
    if not point then return end
    
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) or not ply:Alive() then continue end
        
        local job = ply:getJobTable()
        if not job then continue end
        
        -- Check if player is in radius and correct team
        if ply:GetPos():Distance(point.position) <= point.radius and 
           ((capturedBy == "cop" and job.tdmrp_class == "cop") or 
            (capturedBy == "criminal" and job.tdmrp_class == "criminal")) then
            
            -- Give money using DarkRP
            if ply.addMoney then
                ply:addMoney(500)
            elseif ply.AddMoney then
                ply:AddMoney(500)
            end
            
            -- Add XP if system exists
            if TDMRP.XP and TDMRP.XP.AddXP then
                TDMRP.XP.AddXP(ply, 200)
            end
            
            ply:ChatPrint("[TDMRP] Captured point! +200 XP, +$500")
        end
    end
end

----------------------------------------------------
-- Grant all 5 captured rewards
----------------------------------------------------
function GrantAllPointsCapturedRewards(capturedBy)
    local gems = {"blood_emerald", "blood_sapphire", "blood_ruby", "blood_diamond", "blood_amethyst"}
    
    for _, ply in ipairs(player.GetAll()) do
        local job = ply:getJobTable()
        if not job then continue end
        
        -- Check if player is on winning team
        if (capturedBy == "cop" and job.tdmrp_class == "cop") or 
           (capturedBy == "criminal" and job.tdmrp_class == "criminal") then
            
            -- Grant 5 random gems
            for i = 1, 5 do
                local randomGem = gems[math.random(#gems)]
                if TDMRP.Inventory and TDMRP.Inventory.AddGem then
                    TDMRP.Inventory.AddGem(ply, randomGem, 1)
                end
            end
            
            ply:ChatPrint("[TDMRP] Team captured all points! +5 gems")
        end
    end
end

----------------------------------------------------
-- Passive reward timer (every 90s if all 5 held)
----------------------------------------------------
timer.Create("TDMRP_CapturePoints_PassiveRewards", TDMRP.CapturePoints.PASSIVE_REWARD_INTERVAL, 0, function()
    for pointID, point in pairs(TDMRP.CapturePoints.GetAllPoints()) do
        -- Check if any point is contested or neutral (means team lost control)
        local data = TDMRP.CapturePoints.PointData[pointID]
        if not data or data.owner ~= TDMRP.CapturePoints.OWNER_COP then
            -- Not all cop points, check if all crim
            break
        end
    end
    
    -- Check cop control
    if TDMRP.CapturePoints.TeamControlsAll(TDMRP.CapturePoints.OWNER_COP) then
        GrantPassiveReward("cop")
    end
    
    -- Check crim control
    if TDMRP.CapturePoints.TeamControlsAll(TDMRP.CapturePoints.OWNER_CRIM) then
        GrantPassiveReward("criminal")
    end
end)

----------------------------------------------------
-- Grant passive rewards
----------------------------------------------------
function GrantPassiveReward(teamType)
    local gems = {"blood_emerald", "blood_sapphire", "blood_ruby", "blood_diamond", "blood_amethyst"}
    local randomGem = gems[math.random(#gems)]
    local randomMoney = math.random(500, 1500)
    
    for _, ply in ipairs(player.GetAll()) do
        local job = ply:getJobTable()
        if not job then continue end
        
        if (teamType == "cop" and job.tdmrp_class == "cop") or 
           (teamType == "criminal" and job.tdmrp_class == "criminal") then
            
            ply:AddMoney(randomMoney)
            
            if TDMRP.Inventory and TDMRP.Inventory.AddGem then
                TDMRP.Inventory.AddGem(ply, randomGem, 1)
            end
            
            ply:ChatPrint("[TDMRP] Control bonus! +" .. randomMoney .. "$, +1 gem")
        end
    end
end

----------------------------------------------------
-- Main think hook for capture logic
----------------------------------------------------
hook.Add("Think", "TDMRP_CapturePointsThink", function()
    UpdateCaptureProgress()
end)

----------------------------------------------------
-- Cleanup on player disconnect
----------------------------------------------------
hook.Add("PlayerDisconnected", "TDMRP_CapturePointsCleanup", function(ply)
    SavePointData()
end)

----------------------------------------------------
-- Initialize on server start
----------------------------------------------------
InitializePointData()

print("[TDMRP] Capture Points core logic loaded")
