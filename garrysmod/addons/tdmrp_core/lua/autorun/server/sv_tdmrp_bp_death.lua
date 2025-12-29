-- sv_tdmrp_bp_death.lua
-- BP penalties on death using per-job settings

if not SERVER then return end

local function TDMRP_GetJobClass(ply)
    if not IsValid(ply) or not ply.getJobTable then return nil, nil end
    local job = ply:getJobTable()
    if not job then return nil, nil end
    return job.tdmrp_class, job
end

hook.Add("PlayerDeath", "TDMRP_BpLossOnDeath", function(victim, inflictor, attacker)
    if not IsValid(victim) or not victim:IsPlayer() then return end
    if not victim.GetBP or not victim.AddBP then return end

    -- Skip deaths caused purely by job switching
    if victim.TDMRP_JobChangeDeath then
        victim.TDMRP_JobChangeDeath = nil
        return
    end

    local class, job = TDMRP_GetJobClass(victim)
    if not job then return end

    -- Only combat classes can lose BP
    if class ~= "cop" and class ~= "criminal" then return end

    -- Per-job BP loss value
    local loss = job.tdmrp_bp_on_death or 0
    if loss <= 0 then return end -- no BP penalty defined for this job

    local cur = victim:GetBP()
    if cur <= 0 then return end

    if loss > cur then
        loss = cur
    end

    victim:AddBP(-loss)

    local jobName = job.name or "this job"
    victim:ChatPrint(string.format(
        "[TDMRP] You lost %d BP for dying as %s (you now have %d BP).",
        loss, jobName, victim:GetBP()
    ))
end)
