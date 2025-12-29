----------------------------------------------------
-- TDMRP Active Skills System - Shared Definitions
----------------------------------------------------

TDMRP = TDMRP or {}
TDMRP.ActiveSkills = TDMRP.ActiveSkills or {}

----------------------------------------------------
-- Skill Definitions
----------------------------------------------------
TDMRP.ActiveSkills.Skills = {
    invincibility = {
        name = "Invincibility",
        duration = 10, -- seconds
        cooldown = 10, -- 5 minutes
        sound = "tdmrp/skills/invincibility1.wav",
        material = "models/props_combine/portalball001_sheet",
        vignetteColor = Color(100, 150, 255, 80), -- Blue
        description = "Become invulnerable to all damage"
    },
    
    speed = {
        name = "Lightning Speed",
        duration = 12, -- seconds
        cooldown = 12, -- 2 minutes
        sound = "tdmrp/skills/speed1.wav",
        material = "phoenix_storms/wire/pcb_blue",
        vignetteColor = Color(200, 100, 255, 80), -- Purple
        description = "Quadruple your movement speed",
        
        OnActiveEffect = function(skillData, cooldownRemaining)
            -- Purple rectangle overlay at 5% opacity
            surface.SetDrawColor(138, 43, 226, 13)
            surface.DrawRect(0, 0, ScrW(), ScrH())
            
            -- Radial warp effect - concentric ripples from screen center
            local centerX = ScrW() / 2
            local centerY = ScrH() / 2
            local maxDist = math.sqrt(centerX^2 + centerY^2)
            local waveSpeed = CurTime() * 8
            
            surface.SetDrawColor(138, 43, 226, 40)
            
            -- Draw concentric circles with wave distortion
            for radius = 10, maxDist, 5 do
                local distortion = math.sin((radius / maxDist) * 3 + waveSpeed) * 15
                local distortedRadius = radius + distortion
                
                -- Draw circle segments (approximated with many points)
                for angle = 0, 360, 4 do
                    local rad = math.rad(angle)
                    local x1 = centerX + math.cos(rad) * distortedRadius
                    local y1 = centerY + math.sin(rad) * distortedRadius
                    
                    local nextRad = math.rad(angle + 4)
                    local x2 = centerX + math.cos(nextRad) * distortedRadius
                    local y2 = centerY + math.sin(nextRad) * distortedRadius
                    
                    surface.DrawLine(x1, y1, x2, y2)
                end
            end
        end
    },
    
    quaddamage = {
        name = "Quad Damage",
        duration = 10, -- seconds
        cooldown = 10, -- 4 minutes
        sound = "tdmrp/skills/quaddamage1.wav",
        overlaySound = "tdmrp/skills/quaddamageshootsound.wav", -- Sound played on each gunshot
        material = "phoenix_storms/wire/pcb_red",
        vignetteColor = Color(255, 150, 50, 80), -- Orange
        description = "Deal quadruple damage"
    },
    
    healingaura = {
        name = "Healing Aura",
        duration = 10, -- seconds
        cooldown = 10, -- 3 minutes
        sound = "tdmrp/skills/healingaura1.wav",
        material = nil, -- No material change, uses particle effects
        vignetteColor = Color(100, 255, 100, 80), -- Green
        healAmount = 50, -- HP per second
        radius = 500, -- units
        description = "Heal yourself and nearby allies"
    },
    
    berserk = {
        name = "Berserk",
        duration = 8, -- seconds
        cooldown = 8, -- 5 minutes
        sound = "tdmrp/skills/berserk1.wav",
        material = "phoenix_storms/wire/pcb_green",
        vignetteColor = Color(255, 50, 50, 80), -- Red
        description = "Triple your fire rate"
    }
}

----------------------------------------------------
-- Job to Skill Mapping
----------------------------------------------------
TDMRP.ActiveSkills.JobSkills = {
    -- Berserk Users
    ["Marine"] = "berserk",
    ["Terrorist"] = "berserk",
    
    -- Invincibility Users
    ["T.A.N.K"] = "invincibility",
    ["Armored Unit"] = "invincibility",
    
    -- Healing Aura Users
    ["Police Medic"] = "healingaura",
    ["Rogue Medic"] = "healingaura",
    
    -- Speed Users
    ["Stealth Unit"] = "speed",
    ["Yamakazi"] = "speed",
    
    -- Quad Damage Users
    ["SWAT"] = "quaddamage",
    ["Gangster"] = "quaddamage"
}

----------------------------------------------------
-- Helper: Get skill for job name
----------------------------------------------------
function TDMRP.ActiveSkills.GetSkillForJob(jobName)
    return TDMRP.ActiveSkills.JobSkills[jobName]
end

----------------------------------------------------
-- Helper: Get skill data
----------------------------------------------------
function TDMRP.ActiveSkills.GetSkillData(skillID)
    return TDMRP.ActiveSkills.Skills[skillID]
end

print("[TDMRP] sh_tdmrp_activeskills.lua loaded (skill definitions)")
