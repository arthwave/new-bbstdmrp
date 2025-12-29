----------------------------------------------------
-- TDMRP Damage Threshold (DT) System
-- Shared definitions and helper functions
-- DT provides flat damage reduction per point
----------------------------------------------------

TDMRP = TDMRP or {}
TDMRP.DT = TDMRP.DT or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

TDMRP.DT.Config = {
    -- Sound for bullet impacts on high DT targets
    impactSound = "physics/metal/metal_solid_impact_bullet3.wav",
    impactSoundCooldown = 0.25,  -- seconds
    
    -- Chat warning cooldown for shooting high DT targets
    warningCooldown = 1.0,  -- seconds
    
    -- DT threshold for playing impact sounds
    soundThreshold = 5,
}

----------------------------------------------------
-- Helper: Get job category (cop, criminal, civilian)
----------------------------------------------------

function TDMRP.DT.GetJobCategory(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return "civilian" end
    
    local teamID = ply:Team()
    local job = RPExtraTeams and RPExtraTeams[teamID]
    
    if not job then return "civilian" end
    
    local nameLower = string.lower(job.name or "")
    local catLower = string.lower(job.category or "")
    
    -- Check for police/cop
    if job.police or job.chief or job.mayor then
        return "cop"
    end
    
    -- Check category
    if catLower ~= "" then
        if string.find(catLower, "police") or string.find(catLower, "cop") or 
           string.find(catLower, "law") or string.find(catLower, "government") or 
           string.find(catLower, "civil protection") then
            return "cop"
        elseif string.find(catLower, "crim") or string.find(catLower, "gang") or 
               string.find(catLower, "illegal") then
            return "criminal"
        end
    end
    
    -- Check job name
    if string.find(nameLower, "police") or string.find(nameLower, "cop") or 
       string.find(nameLower, "officer") or string.find(nameLower, "swat") or 
       string.find(nameLower, "chief") or string.find(nameLower, "mayor") or 
       string.find(nameLower, "sheriff") or string.find(nameLower, "deputy") or 
       string.find(nameLower, "fbi") or string.find(nameLower, "secret service") or
       string.find(nameLower, "marine") or string.find(nameLower, "vanguard") or
       string.find(nameLower, "armored") or string.find(nameLower, "master chief") then
        return "cop"
    elseif string.find(nameLower, "thief") or string.find(nameLower, "gang") or 
           string.find(nameLower, "mob") or string.find(nameLower, "hitman") or 
           string.find(nameLower, "terrorist") or string.find(nameLower, "criminal") or 
           string.find(nameLower, "dealer") or string.find(nameLower, "kidnapper") or 
           string.find(nameLower, "raider") or string.find(nameLower, "cheese") or
           string.find(nameLower, "tank") or string.find(nameLower, "yakuza") or
           string.find(nameLower, "yamakazi") or string.find(nameLower, "mercenary") or
           string.find(nameLower, "deadeye") or string.find(nameLower, "duke") then
        return "criminal"
    end
    
    return "civilian"
end

----------------------------------------------------
-- Helper: Check if job is combat eligible (cop or criminal)
----------------------------------------------------

function TDMRP.DT.IsCombatJob(ply)
    local category = TDMRP.DT.GetJobCategory(ply)
    return category == "cop" or category == "criminal"
end

----------------------------------------------------
-- Helper: Get player's total DT from job stats
-- DT is now stored directly on job table as tdmrp_dt
----------------------------------------------------

function TDMRP.DT.GetTotalDT(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return 0 end
    
    -- DT is now applied by sh_tdmrp_job_stats.lua via PlayerSpawn
    -- We can read it from the job table or from a stored NWInt
    local baseDT = ply:GetNWInt("TDMRP_JobDT", 0)
    
    -- Get modifier DT from weapon prefix/suffix (future expansion)
    local modifierDT = ply:GetNWInt("TDMRP_BonusDT", 0)
    
    return baseDT + modifierDT
end

----------------------------------------------------
-- Helper: Get DT armor name for HUD display
----------------------------------------------------

function TDMRP.DT.GetDTName(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return "None" end
    
    return ply:GetNWString("TDMRP_DTName", "None")
end

----------------------------------------------------
-- Helper: Calculate damage after DT reduction
-- DT provides flat damage reduction
----------------------------------------------------

function TDMRP.DT.CalculateReducedDamage(damage, dt)
    if dt <= 0 then return damage end
    
    -- Flat reduction
    local reducedDamage = math.max(0, damage - dt)
    
    return reducedDamage
end

print("[TDMRP] sh_tdmrp_dr.lua loaded (now using DT system)")
