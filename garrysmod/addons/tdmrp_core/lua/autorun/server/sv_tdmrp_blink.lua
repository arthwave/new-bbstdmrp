----------------------------------------------------
-- TDMRP Blink Skill - Server Side
----------------------------------------------------

if CLIENT then return end

print("[TDMRP Blink] Server-side file loading...")

-- No need for AddCSLuaFile - autorun/client files load automatically

util.AddNetworkString("TDMRP_BlinkRequest")
util.AddNetworkString("TDMRP_BlinkExecute")
util.AddNetworkString("TDMRP_BlinkChargesUpdate")

print("[TDMRP Blink] Network strings registered")

TDMRP = TDMRP or {}
TDMRP.Blink = TDMRP.Blink or {}

----------------------------------------------------
-- Store player blink charges (per-player)
-- Structure: { chargeTimers = { timestamp, timestamp, timestamp }, lastChargeTime = CurTime() }
----------------------------------------------------
TDMRP.Blink.PlayerCharges = TDMRP.Blink.PlayerCharges or {}

----------------------------------------------------
-- Get remaining charges for a player
----------------------------------------------------
function TDMRP.Blink.GetRemainingCharges(ply)
    local steamID = ply:SteamID()
    if not TDMRP.Blink.PlayerCharges[steamID] then
        -- Initialize with 3 full charges
        TDMRP.Blink.PlayerCharges[steamID] = {
            chargeTimers = { 0, 0, 0 }, -- 0 means charge is available
            lastUpdateTime = CurTime()
        }
    end
    
    local data = TDMRP.Blink.PlayerCharges[steamID]
    local currentTime = CurTime()
    local remainingCharges = 0
    local nextChargeTime = math.huge
    
    -- Check each charge timer
    for i = 1, 3 do
        if data.chargeTimers[i] <= currentTime then
            -- Charge is available
            remainingCharges = remainingCharges + 1
            data.chargeTimers[i] = 0
        else
            -- Charge is on cooldown
            local timeUntilReady = data.chargeTimers[i] - currentTime
            if timeUntilReady < nextChargeTime then
                nextChargeTime = timeUntilReady
            end
        end
    end
    
    return remainingCharges, nextChargeTime
end

----------------------------------------------------
-- Use one charge (set it on recharge timer from skill config)
----------------------------------------------------
function TDMRP.Blink.UseCharge(ply)
    local steamID = ply:SteamID()
    if not TDMRP.Blink.PlayerCharges[steamID] then
        TDMRP.Blink.GetRemainingCharges(ply) -- Initialize
    end
    
    local data = TDMRP.Blink.PlayerCharges[steamID]
    local currentTime = CurTime()
    
    -- Get recharge time from skill config
    local rechargeTime = 1  -- Default to 1 second
    if TDMRP.ActiveSkills and TDMRP.ActiveSkills.Skills and TDMRP.ActiveSkills.Skills.blink then
        rechargeTime = TDMRP.ActiveSkills.Skills.blink.chargeRechargeTime or 1
    end
    
    -- Find the first available charge
    for i = 1, 3 do
        if data.chargeTimers[i] <= currentTime then
            -- Use this charge, set recharge timer based on skill config
            data.chargeTimers[i] = currentTime + rechargeTime
            return true
        end
    end
    
    return false -- No charges available
end

----------------------------------------------------
-- Sync charges to client
----------------------------------------------------
function TDMRP.Blink.SyncChargesToClient(ply)
    local steamID = ply:SteamID()
    local data = TDMRP.Blink.PlayerCharges[steamID]
    if not data then return end
    
    local remaining, nextChargeTime = TDMRP.Blink.GetRemainingCharges(ply)
    
    net.Start("TDMRP_BlinkChargesUpdate")
        net.WriteUInt(remaining, 3) -- 0-3 charges
        net.WriteFloat(nextChargeTime == math.huge and 0 or nextChargeTime) -- Time until next charge
    net.Send(ply)
end

----------------------------------------------------
-- Perform collision check for blink destination
-- Returns: (canBlink, finalPos, hitWall)
----------------------------------------------------
local function CheckBlinkDestination(startPos, direction, distance, filterPlayer)
    local traceData = {
        start = startPos,
        endpos = startPos + direction * distance,
        mins = Vector(-16, -16, 0),
        maxs = Vector(16, 16, 72),
        mask = MASK_PLAYERSOLID,
        filter = filterPlayer  -- CRITICAL: filter out the player doing the blink
    }
    
    local trace = util.TraceHull(traceData)
    
    print("[TDMRP Blink] TraceHull hit: " .. tostring(trace.Hit) .. " Entity: " .. tostring(trace.Entity) .. " Fraction: " .. trace.Fraction)
    
    -- If we hit something, try to find a valid spot before the obstacle
    if trace.Hit then
        -- Try positions gradually closer to start
        for testDist = distance, 50, -10 do
            traceData.endpos = startPos + direction * testDist
            trace = util.TraceHull(traceData)
            
            if not trace.Hit then
                -- Found a valid spot
                return true, startPos + direction * testDist, true
            end
        end
        
        -- Couldn't find valid spot, blink blocked
        return false, startPos, true
    end
    
    -- No obstacles, can blink to full distance
    return true, startPos + direction * distance, false
end

----------------------------------------------------
-- Execute blink on player
----------------------------------------------------
local function ExecuteBlink(ply, targetPos)
    if not IsValid(ply) then return end
    
    local startPos = ply:GetPos()
    local currentVelocity = ply:GetVelocity()
    
    -- targetPos is at eye height, we need ground position
    -- Trace down to find ground
    local groundTrace = util.TraceLine({
        start = targetPos,
        endpos = targetPos - Vector(0, 0, 100),
        mask = MASK_PLAYERSOLID,
        filter = ply
    })
    
    local groundPos = groundTrace.Hit and groundTrace.HitPos or (targetPos - Vector(0, 0, 36))
    
    print("[TDMRP Blink] ExecuteBlink called!")
    print("[TDMRP Blink]   Start pos: " .. tostring(startPos))
    print("[TDMRP Blink]   Target eye pos: " .. tostring(targetPos))
    print("[TDMRP Blink]   Ground pos: " .. tostring(groundPos))
    print("[TDMRP Blink]   Distance: " .. startPos:Distance(groundPos))
    
    -- Move player to ground position
    ply:SetPos(groundPos)
    
    -- Confirm new position
    timer.Simple(0, function()
        if IsValid(ply) then
            print("[TDMRP Blink]   After SetPos: " .. tostring(ply:GetPos()))
        end
    end)
    
    -- Maintain velocity
    ply:SetVelocity(currentVelocity)
    
    -- Play main blink sound to everyone
    ply:EmitSound("tdmrp/skills/blinkmain.mp3", 80, 100, 1.0)
    
    -- Play random layer sound with slight delay
    local layerSounds = { "tdmrp/skills/blinklayer1.mp3", "tdmrp/skills/blinklayer2.mp3" }
    local chosenSound = layerSounds[math.random(1, #layerSounds)]
    
    timer.Simple(0.05, function()
        if IsValid(ply) then
            ply:EmitSound(chosenSound, 75, 100, 0.8)
        end
    end)
    
    -- Network: Tell clients to draw rainbow tracer effect
    net.Start("TDMRP_BlinkExecute")
        net.WriteVector(startPos)
        net.WriteVector(targetPos)
        net.WriteEntity(ply)
    net.Broadcast()
    
    print("[TDMRP Blink] Player " .. ply:GetName() .. " blinked from " .. tostring(startPos) .. " to " .. tostring(targetPos))
end

----------------------------------------------------
-- Handle blink request from client
----------------------------------------------------
net.Receive("TDMRP_BlinkRequest", function(len, ply)
    print("[TDMRP Blink] === BLINK REQUEST RECEIVED FROM " .. tostring(ply) .. " ===")
    
    if not IsValid(ply) or not ply:Alive() then 
        print("[TDMRP Blink] Request rejected: player invalid or dead")
        return 
    end
    
    -- Verify player has Blink skill using DarkRP team system
    local jobName = team.GetName(ply:Team())
    if not jobName or jobName == "" then 
        print("[TDMRP Blink] Request rejected: jobName is nil or empty")
        return 
    end
    
    if not TDMRP.ActiveSkills or not TDMRP.ActiveSkills.GetSkillForJob then
        print("[TDMRP Blink] Request rejected: TDMRP.ActiveSkills not loaded")
        return
    end
    
    local skill = TDMRP.ActiveSkills.GetSkillForJob(jobName)
    print("[TDMRP Blink] Player job: " .. jobName .. ", skill: " .. tostring(skill))
    if skill ~= "blink" then 
        print("[TDMRP Blink] Request rejected: player doesn't have blink skill")
        return 
    end
    
    -- Check if player has charges available
    local remaining = TDMRP.Blink.GetRemainingCharges(ply)
    if remaining <= 0 then 
        print("[TDMRP Blink] Request rejected: no charges available")
        return 
    end
    
    print("[TDMRP Blink] Blink request accepted, remaining charges: " .. remaining)
    
    -- Get eye direction and blink distance from skill data
    if not TDMRP.ActiveSkills.Skills or not TDMRP.ActiveSkills.Skills.blink then
        print("[TDMRP Blink] Request rejected: blink skill data not loaded")
        return
    end
    
    local skillData = TDMRP.ActiveSkills.Skills.blink
    local direction = ply:GetAimVector()
    local distance = skillData.blinkDistance
    
    -- Check destination (allows small obstacles to be bypassed)
    local eyePos = ply:GetPos() + Vector(0, 0, 36)
    print("[TDMRP Blink] Checking destination from eye: " .. tostring(eyePos) .. " dir: " .. tostring(direction) .. " dist: " .. distance)
    
    local canBlink, targetPos = CheckBlinkDestination(eyePos, direction, distance, ply)
    print("[TDMRP Blink] canBlink: " .. tostring(canBlink) .. " targetPos: " .. tostring(targetPos))
    
    if not canBlink then
        -- Blink blocked by wall, notify player using center message system
        if TDMRP.SendCenterMessage then
            TDMRP.SendCenterMessage(ply, "Blink blocked by obstacle!", Color(255, 100, 100), 1.5)
        else
            ply:PrintMessage(HUD_PRINTCENTER, "Blink blocked by obstacle!")
        end
        return
    end
    
    -- Use a charge
    TDMRP.Blink.UseCharge(ply)
    
    -- Execute the blink
    ExecuteBlink(ply, targetPos)
    
    -- Sync updated charges to client
    TDMRP.Blink.SyncChargesToClient(ply)
end)

----------------------------------------------------
-- Sync charges to players on spawn/respawn
----------------------------------------------------
hook.Add("PlayerSpawn", "TDMRP_BlinkRespawn", function(ply)
    -- Restore full charges on respawn
    local steamID = ply:SteamID()
    TDMRP.Blink.PlayerCharges[steamID] = {
        chargeTimers = { 0, 0, 0 },
        lastUpdateTime = CurTime()
    }
    
    -- Sync to client (with delay to ensure player is fully initialized)
    timer.Simple(0.5, function()
        if IsValid(ply) then
            local jobName = team.GetName(ply:Team())
            if jobName and jobName ~= "" then
                TDMRP.Blink.SyncChargesToClient(ply)
            end
        end
    end)
end)

----------------------------------------------------
-- Periodic sync to keep clients updated
----------------------------------------------------
hook.Add("Think", "TDMRP_BlinkSyncCharges", function()
    if CurTime() % 0.5 < 0.01 then -- Every 0.5 seconds
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:Alive() then
                -- Get job name using DarkRP team system
                local jobName = team.GetName(ply:Team())
                if not jobName or jobName == "" then continue end
                
                -- Check if has blink skill
                if not TDMRP.ActiveSkills or not TDMRP.ActiveSkills.GetSkillForJob then continue end
                local skill = TDMRP.ActiveSkills.GetSkillForJob(jobName)
                
                if skill == "blink" then
                    TDMRP.Blink.SyncChargesToClient(ply)
                end
            end
        end
    end
end)

print("[TDMRP] sv_tdmrp_blink.lua loaded (server blink logic)")
