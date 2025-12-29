----------------------------------------------------
-- TDMRP Active Skills System - Server Logic
----------------------------------------------------

if CLIENT then return end

util.AddNetworkString("TDMRP_ActivateSkill")
util.AddNetworkString("TDMRP_SkillActivated")
util.AddNetworkString("TDMRP_SkillCooldown")

TDMRP = TDMRP or {}
TDMRP.ActiveSkills = TDMRP.ActiveSkills or {}

-- Store player cooldowns (persists through death, not map changes)
TDMRP.ActiveSkills.PlayerCooldowns = TDMRP.ActiveSkills.PlayerCooldowns or {}

-- Store active buffs
TDMRP.ActiveSkills.ActiveBuffs = TDMRP.ActiveSkills.ActiveBuffs or {}

----------------------------------------------------
-- Get player's assigned skill
----------------------------------------------------
local function GetPlayerSkill(ply)
    local teamID = ply:Team()
    local job = RPExtraTeams and RPExtraTeams[teamID]
    if not job then return nil end
    
    return TDMRP.ActiveSkills.GetSkillForJob(job.name)
end

----------------------------------------------------
-- Check if skill is on cooldown
----------------------------------------------------
local function IsOnCooldown(ply, skillID)
    local steamID = ply:SteamID()
    if not TDMRP.ActiveSkills.PlayerCooldowns[steamID] then return false end
    
    local cooldownEnd = TDMRP.ActiveSkills.PlayerCooldowns[steamID][skillID]
    if not cooldownEnd then return false end
    
    return CurTime() < cooldownEnd
end

----------------------------------------------------
-- Get remaining cooldown time
----------------------------------------------------
local function GetCooldownRemaining(ply, skillID)
    local steamID = ply:SteamID()
    if not TDMRP.ActiveSkills.PlayerCooldowns[steamID] then return 0 end
    
    local cooldownEnd = TDMRP.ActiveSkills.PlayerCooldowns[steamID][skillID]
    if not cooldownEnd then return 0 end
    
    return math.max(0, cooldownEnd - CurTime())
end

----------------------------------------------------
-- Set skill on cooldown
----------------------------------------------------
local function SetCooldown(ply, skillID, duration)
    local steamID = ply:SteamID()
    TDMRP.ActiveSkills.PlayerCooldowns[steamID] = TDMRP.ActiveSkills.PlayerCooldowns[steamID] or {}
    TDMRP.ActiveSkills.PlayerCooldowns[steamID][skillID] = CurTime() + duration
    
    -- Notify client of cooldown
    net.Start("TDMRP_SkillCooldown")
        net.WriteString(skillID)
        net.WriteFloat(duration)
    net.Send(ply)
end

----------------------------------------------------
-- Apply material to player and viewmodel
----------------------------------------------------
local function ApplyMaterial(ply, material, skillID)
    if material then
        ply:SetMaterial(material)
        ply:SetNWBool("TDMRP_SkillActive", true)
        if skillID then
            ply:SetNWString("TDMRP_ActiveSkillID", skillID)
        end
        print("[TDMRP Skills] Applied material to player: " .. material)
        print("[TDMRP Skills] Set TDMRP_SkillActive to true")
        if skillID then
            print("[TDMRP Skills] Set active skill ID to: " .. skillID)
        end
        
        -- Apply to hands/arms viewmodel
        local hands = ply:GetHands()
        if IsValid(hands) then
            hands:SetMaterial(material)
            print("[TDMRP Skills] Applied material to hands")
        else
            print("[TDMRP Skills] Hands not valid")
        end
        
        -- Apply to active weapon (both world and viewmodel)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) then
            print("[TDMRP Skills] Weapon class: " .. wep:GetClass())
            wep:SetMaterial(material)
            print("[TDMRP Skills] Applied material to weapon entity")
            print("[TDMRP Skills] Weapon material after set: " .. wep:GetMaterial())
            
            local vm = ply:GetViewModel()
            if IsValid(vm) then
                vm:SetMaterial(material)
                -- Set all submaterials (viewmodels often use submaterials)
                for i = 0, 31 do
                    vm:SetSubMaterial(i, material)
                end
                print("[TDMRP Skills] Applied material to viewmodel and submaterials")
            else
                print("[TDMRP Skills] Viewmodel not valid")
            end
        else
            print("[TDMRP Skills] Weapon not valid")
        end
        
        -- Store material on player for weapon switching
        ply.TDMRP_ActiveSkillMaterial = material
    end
end

----------------------------------------------------
-- Remove material from player and viewmodel
----------------------------------------------------
local function RemoveMaterial(ply)
    ply:SetMaterial("")
    ply:SetNWBool("TDMRP_SkillActive", false)
    
    -- Remove from hands
    local hands = ply:GetHands()
    if IsValid(hands) then
        hands:SetMaterial("")
    end
    
    -- Remove from weapon
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        wep:SetMaterial("")
    end
    
    -- Remove from weapon viewmodel
    local vm = ply:GetViewModel()
    if IsValid(vm) then
        vm:SetMaterial("")
        -- Clear all submaterials
        for i = 0, 31 do
            vm:SetSubMaterial(i, nil)
        end
    end
    
    ply.TDMRP_ActiveSkillMaterial = nil
end

----------------------------------------------------
-- Invincibility Skill
----------------------------------------------------
local function ActivateInvincibility(ply, skillData)
    ApplyMaterial(ply, skillData.material, "invincibility")
    ply:GodEnable()
    
    -- Store buff
    TDMRP.ActiveSkills.ActiveBuffs[ply] = {
        skill = "invincibility",
        endTime = CurTime() + skillData.duration
    }
    
    -- Remove after duration
    timer.Simple(skillData.duration, function()
        if IsValid(ply) then
            ply:GodDisable()
            RemoveMaterial(ply)
            TDMRP.ActiveSkills.ActiveBuffs[ply] = nil
        end
    end)
end

----------------------------------------------------
-- Speed Skill
----------------------------------------------------
local function ActivateSpeed(ply, skillData)
    ApplyMaterial(ply, skillData.material, "speed")
    
    -- Store original speed
    local originalWalk = ply:GetWalkSpeed()
    local originalRun = ply:GetRunSpeed()
    
    -- Quadruple speed
    ply:SetWalkSpeed(originalWalk * 4)
    ply:SetRunSpeed(originalRun * 4)
    
    -- Store buff
    TDMRP.ActiveSkills.ActiveBuffs[ply] = {
        skill = "speed",
        endTime = CurTime() + skillData.duration,
        originalWalk = originalWalk,
        originalRun = originalRun
    }
    
    -- Restore after duration
    timer.Simple(skillData.duration, function()
        if IsValid(ply) then
            ply:SetWalkSpeed(originalWalk)
            ply:SetRunSpeed(originalRun)
            RemoveMaterial(ply)
            TDMRP.ActiveSkills.ActiveBuffs[ply] = nil
        end
    end)
end

----------------------------------------------------
-- Quad Damage Skill
----------------------------------------------------
local function ActivateQuadDamage(ply, skillData)
    ApplyMaterial(ply, skillData.material, "quaddamage")
    
    -- Store buff (damage multiplier handled in EntityTakeDamage hook)
    TDMRP.ActiveSkills.ActiveBuffs[ply] = {
        skill = "quaddamage",
        endTime = CurTime() + skillData.duration
    }
    
    -- Remove after duration
    timer.Simple(skillData.duration, function()
        if IsValid(ply) then
            RemoveMaterial(ply)
            TDMRP.ActiveSkills.ActiveBuffs[ply] = nil
        end
    end)
end

----------------------------------------------------
-- Healing Aura Skill
----------------------------------------------------
local function ActivateHealingAura(ply, skillData)
    local teamID = ply:Team()
    local job = RPExtraTeams and RPExtraTeams[teamID]
    if not job then return end
    
    local jobClass = job.tdmrp_class
    
    -- Store buff
    TDMRP.ActiveSkills.ActiveBuffs[ply] = {
        skill = "healingaura",
        endTime = CurTime() + skillData.duration
    }
    
    -- Healing tick timer
    local tickCount = 0
    local maxTicks = skillData.duration -- 1 heal per second
    
    timer.Create("TDMRP_HealAura_" .. ply:SteamID(), 1, maxTicks, function()
        if not IsValid(ply) or not ply:Alive() then 
            timer.Remove("TDMRP_HealAura_" .. ply:SteamID())
            return 
        end
        
        tickCount = tickCount + 1
        local pos = ply:GetPos()
        
        -- Find nearby players
        for _, target in ipairs(player.GetAll()) do
            if IsValid(target) and target:Alive() then
                local dist = target:GetPos():Distance(pos)
                
                if dist <= skillData.radius then
                    -- Check if same combat class
                    local targetTeamID = target:Team()
                    local targetJob = RPExtraTeams and RPExtraTeams[targetTeamID]
                    if targetJob and targetJob.tdmrp_class == jobClass then
                        -- Heal target
                        local newHealth = math.min(target:Health() + skillData.healAmount, target:GetMaxHealth())
                        target:SetHealth(newHealth)
                        
                        -- Play heal sound
                        target:EmitSound("items/medshot4.wav", 50, 100)
                        
                        -- Send heal effect to client
                        net.Start("TDMRP_SkillActivated")
                            net.WriteString("healingaura_tick")
                            net.WriteEntity(ply)
                        net.Send(target)
                    end
                end
            end
        end
        
        -- Remove buff on last tick
        if tickCount >= maxTicks then
            TDMRP.ActiveSkills.ActiveBuffs[ply] = nil
        end
    end)
end

----------------------------------------------------
-- Berserk Skill
----------------------------------------------------
local function ActivateBerserk(ply, skillData)
    ApplyMaterial(ply, skillData.material, "berserk")
    
    -- Store buff (fire rate handled in Think hook)
    TDMRP.ActiveSkills.ActiveBuffs[ply] = {
        skill = "berserk",
        endTime = CurTime() + skillData.duration
    }
    
    -- Remove after duration
    timer.Simple(skillData.duration, function()
        if IsValid(ply) then
            RemoveMaterial(ply)
            TDMRP.ActiveSkills.ActiveBuffs[ply] = nil
        end
    end)
end

----------------------------------------------------
-- Regeneration Skill
----------------------------------------------------
local function ActivateRegeneration(ply, skillData)
    ApplyMaterial(ply, skillData.material, "regeneration")
    
    -- Store buff
    TDMRP.ActiveSkills.ActiveBuffs[ply] = {
        skill = "regeneration",
        endTime = CurTime() + skillData.duration
    }
    
    -- Regeneration tick timer (heal every 0.5 seconds, 2 ticks per heal point)
    local tickCount = 0
    local maxTicks = skillData.duration * 2  -- 2 ticks per second (0.5s interval)
    
    timer.Create("TDMRP_Regen_" .. ply:SteamID(), 0.5, maxTicks, function()
        if not IsValid(ply) or not ply:Alive() then 
            timer.Remove("TDMRP_Regen_" .. ply:SteamID())
            return 
        end
        
        tickCount = tickCount + 1
        local pos = ply:GetPos()
        
        -- Heal player every 2 ticks (every 1 second, heal 5 HP)
        if tickCount % 2 == 0 then
            local newHealth = math.min(ply:Health() + skillData.healAmount, ply:GetMaxHealth())
            ply:SetHealth(newHealth)
            
            -- Play healing sound for player and nearby players
            ply:EmitSound("items/medshot4.wav", 70, 100)
            
            -- Also play for nearby players
            for _, target in ipairs(player.GetAll()) do
                if target ~= ply and IsValid(target) then
                    local dist = target:GetPos():Distance(pos)
                    if dist <= 1000 then  -- Audible range
                        target:EmitSound("items/medshot4.wav", 70, 100)
                    end
                end
            end
        end
        
        -- Remove buff on last tick
        if tickCount >= maxTicks then
            TDMRP.ActiveSkills.ActiveBuffs[ply] = nil
        end
    end)
    
    -- Remove after duration
    timer.Simple(skillData.duration, function()
        if IsValid(ply) then
            RemoveMaterial(ply)
            TDMRP.ActiveSkills.ActiveBuffs[ply] = nil
            timer.Remove("TDMRP_Regen_" .. ply:SteamID())
        end
    end)
end

----------------------------------------------------
-- Main activation handler
----------------------------------------------------
local function ActivateSkill(ply, skillID)
    local skillData = TDMRP.ActiveSkills.GetSkillData(skillID)
    if not skillData then return false end
    
    -- Play sound (localized to player area)
    ply:EmitSound(skillData.sound, 80, 100)
    
    -- Activate specific skill
    if skillID == "invincibility" then
        ActivateInvincibility(ply, skillData)
    elseif skillID == "speed" then
        ActivateSpeed(ply, skillData)
    elseif skillID == "quaddamage" then
        ActivateQuadDamage(ply, skillData)
    elseif skillID == "healingaura" then
        ActivateHealingAura(ply, skillData)
    elseif skillID == "berserk" then
        ActivateBerserk(ply, skillData)
    elseif skillID == "regeneration" then
        ActivateRegeneration(ply, skillData)
    end
    
    -- Set cooldown
    SetCooldown(ply, skillID, skillData.cooldown)
    
    -- Notify client of activation
    net.Start("TDMRP_SkillActivated")
        net.WriteString(skillID)
        net.WriteEntity(ply)
    net.Send(ply)
    
    return true
end

----------------------------------------------------
-- Network handler: Player wants to activate skill
----------------------------------------------------
net.Receive("TDMRP_ActivateSkill", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- Get player's assigned skill
    local skillID = GetPlayerSkill(ply)
    if not skillID then 
        ply:ChatPrint("[TDMRP] Your job does not have an active skill!")
        return 
    end
    
    -- Check cooldown
    if IsOnCooldown(ply, skillID) then
        local remaining = GetCooldownRemaining(ply, skillID)
        ply:ChatPrint("[TDMRP] Skill on cooldown! " .. math.ceil(remaining) .. " seconds remaining.")
        return
    end
    
    -- Activate
    if ActivateSkill(ply, skillID) then
        local skillData = TDMRP.ActiveSkills.GetSkillData(skillID)
        ply:ChatPrint("[TDMRP] " .. skillData.name .. " activated!")
    end
end)

----------------------------------------------------
-- Hook: Clear all cooldowns on job change
----------------------------------------------------
hook.Add("OnPlayerChangedTeam", "TDMRP_ClearSkillCooldowns", function(ply, oldTeam, newTeam)
    local steamID = ply:SteamID()
    
    -- Clear all skill cooldowns for this player
    TDMRP.ActiveSkills.PlayerCooldowns[steamID] = {}
    
    -- Notify client that cooldowns are cleared
    local newJob = RPExtraTeams and RPExtraTeams[newTeam]
    if newJob then
        local newSkillID = TDMRP.ActiveSkills.GetSkillForJob(newJob.name)
        if newSkillID then
            net.Start("TDMRP_SkillCooldown")
                net.WriteString(newSkillID)
                net.WriteFloat(0) -- 0 = no cooldown
            net.Send(ply)
        end
    end
end)

----------------------------------------------------
-- Hook: Re-apply material when switching weapons
----------------------------------------------------
hook.Add("PlayerSwitchWeapon", "TDMRP_ReapplySkillMaterial", function(ply, oldWep, newWep)
    if not IsValid(ply) or not IsValid(newWep) then return end
    
    -- If player has an active skill material, apply it to the new weapon
    if ply.TDMRP_ActiveSkillMaterial then
        timer.Simple(0.1, function()
            if IsValid(ply) and IsValid(newWep) then
                newWep:SetMaterial(ply.TDMRP_ActiveSkillMaterial)
                
                local vm = ply:GetViewModel()
                if IsValid(vm) then
                    vm:SetMaterial(ply.TDMRP_ActiveSkillMaterial)
                    -- Set all submaterials
                    for i = 0, 31 do
                        vm:SetSubMaterial(i, ply.TDMRP_ActiveSkillMaterial)
                    end
                end
            end
        end)
    end
end)

----------------------------------------------------
-- Hook: Invincibility - Block damage and play feedback
----------------------------------------------------
hook.Add("EntityTakeDamage", "TDMRP_InvincibilityBlock", function(target, dmginfo)
    if not IsValid(target) or not target:IsPlayer() then return end

    local buff = TDMRP.ActiveSkills.ActiveBuffs[target]
    if buff and buff.skill == "invincibility" and CurTime() < buff.endTime then
        -- Block all damage
        dmginfo:SetDamage(0)
        dmginfo:ScaleDamage(0)
        
        -- Play sound and particle feedback
        local attacker = dmginfo:GetAttacker()
        if IsValid(attacker) then
            -- Play random metal clank sound
            local clankSounds = {
                "physics/metal/metal_box_impact_bullet1.wav",
                "physics/metal/metal_box_impact_bullet2.wav",
                "physics/metal/metal_box_impact_bullet3.wav"
            }
            local randomClank = clankSounds[math.random(1, #clankSounds)]

            -- Play to attacker: emit directly for players, play at position for NPCs/entities
            if attacker:IsPlayer() then
                attacker:EmitSound(randomClank, 75, 100)
            else
                -- For NPCs or other entities, play the sound at their position so nearby players hear it
                if attacker.GetPos then
                    sound.Play(randomClank, attacker:GetPos(), 75, 100)
                end
            end

            -- Always play to the target (victim) as well
            target:EmitSound(randomClank, 75, 100)

            -- Create spark particle effect at impact point, safe fallback for normal
            local effectData = EffectData()
            local origin = target:GetPos() + target:OBBCenter()
            local normalVec = Vector(0, 0, 1)
            if IsValid(attacker) and attacker.GetPos then
                local ok, dir = pcall(function() return (target:GetPos() - attacker:GetPos()):GetNormalized() end)
                if ok and dir then normalVec = dir end
            end
            effectData:SetOrigin(origin)
            effectData:SetNormal(normalVec)
            util.Effect("Sparks", effectData)
        end
        
        return true
    end
end)

----------------------------------------------------
-- Hook: Quad Damage multiplier
----------------------------------------------------

hook.Add("EntityTakeDamage", "TDMRP_QuadDamage", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    
    -- Check if attacker has quad damage active
    local buff = TDMRP.ActiveSkills.ActiveBuffs[attacker]
    if buff and buff.skill == "quaddamage" and CurTime() < buff.endTime then
        dmginfo:ScaleDamage(4)
        -- Mark this damage as quad damage so hitnumbers can display it specially
        dmginfo.TDMRP_IsQuadDamage = true
    end
end)

----------------------------------------------------
-- Hook: Berserk fire rate modifier
----------------------------------------------------
hook.Add("Think", "TDMRP_BerserkFireRate", function()
    for ply, buff in pairs(TDMRP.ActiveSkills.ActiveBuffs) do
        if IsValid(ply) and buff.skill == "berserk" and CurTime() < buff.endTime then
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and wep.Primary then
                -- Store original delay if not stored
                if not wep.TDMRP_OriginalDelay then
                    wep.TDMRP_OriginalDelay = wep.Primary.Delay
                end
                
                -- Triple fire rate = divide delay by 3
                wep.Primary.Delay = wep.TDMRP_OriginalDelay / 3
            end
        elseif IsValid(ply) and buff.skill == "berserk" and CurTime() >= buff.endTime then
            -- Restore original fire rate
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and wep.TDMRP_OriginalDelay then
                wep.Primary.Delay = wep.TDMRP_OriginalDelay
                wep.TDMRP_OriginalDelay = nil
            end
        end
    end
end)

----------------------------------------------------
-- Hook: Clean up on disconnect
----------------------------------------------------
hook.Add("PlayerDisconnected", "TDMRP_CleanupSkills", function(ply)
    TDMRP.ActiveSkills.ActiveBuffs[ply] = nil
    timer.Remove("TDMRP_HealAura_" .. ply:SteamID())
end)

print("[TDMRP] sv_tdmrp_activeskills.lua loaded (server skill logic)")
