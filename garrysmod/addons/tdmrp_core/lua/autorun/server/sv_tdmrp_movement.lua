-- sv_tdmrp_movement.lua
-- Class-based movement for TDMRP (civ fast, freerunner faster, combat more grounded)

local function TDMRP_GetJobClass(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil, nil end
    if not ply.getJobTable then return nil, nil end

    local job = ply:getJobTable()
    if not job then return nil, nil end

    return job.tdmrp_class, job
end

local function TDMRP_ApplyMovement(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    -- Don't mess with spectators or people not in-game yet
    if ply:Team() == TEAM_SPECTATOR or ply:Team() == TEAM_UNASSIGNED then return end

    local class, job = TDMRP_GetJobClass(ply)

    -- Defaults (rough “combat baseline”)
    local walk = 200   -- base walk
    local run  = 300   -- base run
    local jump = 160   -- base jump power

    ----------------------------------------------------
    -- Class-based baselines
    ----------------------------------------------------
    if class == "civilian" then
        -- Civilians: faster overall, lighter feel
        walk = 260
        run  = 360
        jump = 170
    elseif class == "criminal" then
        -- Criminals: slightly above base, mobile but not parkour
        walk = 210
        run  = 310
        jump = 160
    elseif class == "cop" then
        -- Cops: more tactical, not slow but not zoomers
        walk = 200
        run  = 300
        jump = 160
    elseif class == "zombie" then
        -- Placeholder: zombies a bit lumbering but can hop
        walk = 190
        run  = 280
        jump = 190
    end

    ----------------------------------------------------
    -- Per-job overrides (Freerunner, etc.)
    ----------------------------------------------------
    if job and job.name == "Freerunner" then
        -- Freerunner: noticeably faster + higher jumps
        walk = 280
        run  = 380
        jump = 220
    end

    -- Apply to player
    ply:SetWalkSpeed(walk)
    ply:SetRunSpeed(run)
    ply:SetJumpPower(jump)

    -- Optional: prevent super-speed duck/hop exploits a bit
    ply:SetSlowWalkSpeed(walk * 0.8)
    ply:SetCrouchedWalkSpeed(0.6)
end

----------------------------------------------------
-- Hooks
----------------------------------------------------

-- Apply movement every time the player spawns
hook.Add("PlayerSpawn", "TDMRP_ApplyMovementOnSpawn", function(ply)
    -- Small delay to make sure DarkRP finished setting job/team
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        TDMRP_ApplyMovement(ply)
    end)
end)

-- Also re-apply when their team/job changes (for alive players)
hook.Add("OnPlayerChangedTeam", "TDMRP_ApplyMovementOnTeamChange", function(ply, before, after)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    -- They'll usually die and respawn on job change,
    -- but if they don't for some reason, this keeps speeds correct.
    TDMRP_ApplyMovement(ply)
end)
