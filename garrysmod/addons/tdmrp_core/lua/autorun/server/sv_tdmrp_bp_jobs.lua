-- sv_tdmrp_bp_jobs.lua
-- Enforce BP requirements when changing jobs

if not SERVER then return end

hook.Add("playerCanChangeTeam", "TDMRP_BpJobRequirement", function(ply, teamID, force)
    if not IsValid(ply) or not ply.GetBP then return end
    if not RPExtraTeams or not RPExtraTeams[teamID] then return end

    local job = RPExtraTeams[teamID]
    local req = job.tdmrp_required_bp or 0
    if req <= 0 then return end -- no BP requirement

    local cur = ply:GetBP()

    if cur < req then
        local jobName = job.name or "this job"
        ply:ChatPrint(string.format(
            "[TDMRP] You need %d BP to become %s, but you only have %d BP.",
            req, jobName, cur
        ))
        return false, "Not enough BP for this job."
    end
end)
