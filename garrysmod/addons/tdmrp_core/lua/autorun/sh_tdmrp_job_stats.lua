-- sh_tdmrp_job_stats.lua
-- Shared job stats definitions and helpers
-- Defines default stats for each job class and specific job overrides

if SERVER then
    AddCSLuaFile()
end

TDMRP = TDMRP or {}
TDMRP.JobStats = TDMRP.JobStats or {}

----------------------------------------------------
-- Default Stats by Class
----------------------------------------------------

TDMRP.JobStats.ClassDefaults = {
    civilian = {
        hp = 100,
        ap = 0,
        dt = 0,
        dt_name = "None",
        walk_speed = 260,
        run_speed = 360,
        jump_power = 170,
    },
    cop = {
        hp = 150,
        ap = 30,
        dt = 3,
        dt_name = "Lightweight Kevlar",
        walk_speed = 200,
        run_speed = 300,
        jump_power = 160,
    },
    criminal = {
        hp = 150,
        ap = 30,
        dt = 3,
        dt_name = "Lightweight Kevlar",
        walk_speed = 210,
        run_speed = 310,
        jump_power = 160,
    },
    peacekeeper = {
        hp = 2000,
        ap = 0,
        dt = 0,
        dt_name = "Divine Protection",
        walk_speed = 220,
        run_speed = 320,
        jump_power = 200,
    },
}

----------------------------------------------------
-- DT (Damage Threshold) Definitions
-- Maps DT values to armor names
----------------------------------------------------

TDMRP.JobStats.DTNames = {
    [0]  = "None",
    [3]  = "Lightweight Kevlar",
    [4]  = "Surplus Kevlar",
    [5]  = "Heavy Duty Kevlar",
    [7]  = "Advanced Kevlar",
    [10] = "Rookie Kevlar",
    [12] = "Prototype Bulletshield",
    [15] = "Mark VI Mjolnir",
}

----------------------------------------------------
-- Movement Speed Presets
----------------------------------------------------

TDMRP.JobStats.MovementPresets = {
    normal = {
        walk = 200,
        run = 300,
        jump = 160,
    },
    slow = {
        walk = 140,
        run = 180,
        jump = 100,
    },
    fast = {
        walk = 240,
        run = 360,
        jump = 180,
    },
    recon = {
        walk = 300, -- +50% of 200
        run = 450,  -- +50% of 300
        jump = 160,
    },
    yamakazi = {
        walk = 320, -- 160% of 200
        run = 480,  -- 160% of 300
        jump = 200,
    },
    masterchief = {
        walk = 240, -- 120% of 200
        run = 360,  -- 120% of 300
        jump = 240, -- 1.5x of 160
    },
}

----------------------------------------------------
-- Helper: Get stats for a job
----------------------------------------------------

function TDMRP.JobStats.GetStatsForJob(jobTable)
    if not jobTable then return TDMRP.JobStats.ClassDefaults.civilian end
    
    local class = jobTable.tdmrp_class or "civilian"
    local defaults = TDMRP.JobStats.ClassDefaults[class] or TDMRP.JobStats.ClassDefaults.civilian
    
    -- Build stats from job table, falling back to class defaults
    local stats = {
        hp = jobTable.tdmrp_hp or defaults.hp,
        ap = jobTable.tdmrp_ap or defaults.ap,
        dt = jobTable.tdmrp_dt or defaults.dt,
        dt_name = jobTable.tdmrp_dt_name or defaults.dt_name,
        walk_speed = jobTable.tdmrp_walk_speed or defaults.walk_speed,
        run_speed = jobTable.tdmrp_run_speed or defaults.run_speed,
        jump_power = jobTable.tdmrp_jump_power or defaults.jump_power,
        transparency = jobTable.tdmrp_transparency or nil,
    }
    
    return stats
end

----------------------------------------------------
-- Helper: Get DT name from value
----------------------------------------------------

function TDMRP.JobStats.GetDTName(dtValue)
    return TDMRP.JobStats.DTNames[dtValue] or ("+" .. dtValue .. " DT")
end

----------------------------------------------------
-- Client-side: Get local player's DT for HUD
----------------------------------------------------

if CLIENT then
    function TDMRP.JobStats.GetLocalPlayerDT()
        local ply = LocalPlayer()
        if not IsValid(ply) then return 0, "None" end
        
        local dt = ply:GetNWInt("TDMRP_DT", 0)
        local dtName = ply:GetNWString("TDMRP_DTName", "None")
        
        return dt, dtName
    end
end

----------------------------------------------------
-- Server-side: Apply DT damage reduction
----------------------------------------------------

if SERVER then
    -- Hook into damage to apply DT reduction
    hook.Add("EntityTakeDamage", "TDMRP_ApplyDTReduction", function(target, dmginfo)
        if not IsValid(target) or not target:IsPlayer() then return end
        
        local dt = target:GetNWInt("TDMRP_DT", 0)
        if dt <= 0 then return end
        
        local originalDamage = dmginfo:GetDamage()
        local reducedDamage = math.max(0, originalDamage - dt)
        
        -- Only reduce if there's actual reduction happening
        if reducedDamage < originalDamage then
            dmginfo:SetDamage(reducedDamage)
            
            -- Debug output (can be disabled in production)
            -- print(string.format("[TDMRP DT] %s took %d damage (reduced from %d by %d DT)",
            --     target:Nick(), reducedDamage, originalDamage, dt))
        end
    end)
end

print("[TDMRP] sh_tdmrp_job_stats.lua loaded (job stats definitions)")
