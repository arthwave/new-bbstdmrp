-- sv_tdmrp_jobchange.lua
-- Force-death + cosmetic explosion on job change (TDMRP style)

-- Helper: spawn a cosmetic explosion at a position
local function TDMRP_JobChangeExplosion(pos)
    if not pos then return end

    -- Visual explosion effect
    local ed = EffectData()
    ed:SetOrigin(pos + Vector(0, 0, 10)) -- slightly above ground
    util.Effect("Explosion", ed, true, true)

    -- Sound (heard locally around the position)
    sound.Play("ambient/explosions/explode_4.wav", pos, 90, 100, 1)

    -- Optional: small screenshake for nearby players
    util.ScreenShake(pos, 5, 5, 0.5, 500)
end

hook.Add("OnPlayerChangedTeam", "TDMRP_JobChangeForceDeath", function(ply, before, after)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    -- Ignore non-changes or invalid team IDs
    if before == after then return end
    if before == nil or after == nil then return end

    -- If they're already dead, just let respawn happen normally
    if not ply:Alive() then return end

    -- Store the OLD job class so weapon drop hooks know what job they HAD
    local oldJob = RPExtraTeams and RPExtraTeams[before]
    if oldJob then
        ply.TDMRP_OldJobClass = oldJob.tdmrp_class
        print("[TDMRP JobChange] Storing old job class: " .. tostring(ply.TDMRP_OldJobClass))
    end

    -- Store a flag so we know this death came from a job change
    ply.TDMRP_JobChangeDeath = true

    -- Cosmetic explosion at their current position
    local pos = ply:GetPos()
    TDMRP_JobChangeExplosion(pos)

    -- Kill the player so they respawn as the new job
    -- Use Kill() instead of KillSilent so they get a normal death experience
    ply:Kill()
end)

-- Optional: if you ever want to treat these deaths differently, you can hook PlayerDeath and check ply.TDMRP_JobChangeDeath
-- hook.Add("PlayerDeath", "TDMRP_JobChangeDeathFlagClear", function(victim, inflictor, attacker)
--     if victim.TDMRP_JobChangeDeath then
--         -- Custom logic here if needed
--         victim.TDMRP_JobChangeDeath = nil
--     end
-- end)
