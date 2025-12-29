----------------------------------------------------
-- TDMRP Job Pain Sounds - Server Hook
-- Plays contextual pain sounds when players take damage
----------------------------------------------------

if not SERVER then return end

-- Hook: EntityTakeDamage to trigger pain sounds
hook.Add("EntityTakeDamage", "TDMRP_JobPainSounds", function(target, dmginfo)
    -- Play hit sound on ANY damage (players and NPCs) - LOUD and PROMINENT
    if IsValid(target) then
        target:EmitSound("tdmrp/quake/newhitsound1.mp3", 160, 100, 1, CHAN_AUTO)
    end
    
    -- Also emit to attacker (player or NPC)
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) then
        attacker:EmitSound("tdmrp/quake/newhitsound1.mp3", 160, 100, 1, CHAN_AUTO)
    end
    
    -- Only process pain sounds for players
    if not IsValid(target) or not target:IsPlayer() then return end
    
    -- Check damage threshold
    local dmg = dmginfo:GetDamage()
    print(string.format("[TDMRP Pain] %s took %.0f damage", target:GetName(), dmg))
    
    if dmg <= TDMRP.JobPainSounds.Config.MinDamage then 
        print("[TDMRP Pain] Damage too low, ignoring pain sound")
        return 
    end
    
    local targetJob = target:GetUserGroup()
    local config = TDMRP.JobPainSounds.Config
    local currentTime = CurTime()
    
    print(string.format("[TDMRP Pain] Job check: %s, Config exists: %s", targetJob, TDMRP.JobPainSounds.Config ~= nil))
    
    -- Get actual TDMRP job (not ULX admin group)
    if target.getJobTable then
        local jobTable = target:getJobTable()
        if jobTable and jobTable.command then
            targetJob = jobTable.command
            print(string.format("[TDMRP Pain] Got TDMRP job: %s", targetJob))
        end
    end
    
    -- Check if player is on debounce
    local playerID = target:SteamID64()
    local lastPainTime = TDMRP.JobPainSounds.LastPainTime[playerID] or 0
    
    if currentTime - lastPainTime < config.Debounce then
        print("[TDMRP Pain] On debounce, ignoring")
        return  -- Still on debounce
    end
    
    -- Get job classification
    local jobClass = TDMRP.JobPainSounds.JobClassification[targetJob]
    
    if jobClass == nil then
        print(string.format("[TDMRP Pain] Job '%s' not found in classification table", targetJob))
        return  -- Job exempt or not classified
    end
    
    -- Select sound group
    local soundGroup
    if jobClass == "human" then
        soundGroup = TDMRP.JobPainSounds.HumanSounds
    elseif jobClass == "humanoid" then
        soundGroup = TDMRP.JobPainSounds.HumanoidSounds
    else
        return
    end
    
    -- Pick random sound
    local soundFile = soundGroup[math.random(#soundGroup)]
    
    -- Calculate random pitch (80-120%)
    local pitch = math.random(config.PitchMin, config.PitchMax)
    
    -- Play pain sound
    target:EmitSound(soundFile, config.Volume, pitch)
    
    -- Update debounce
    TDMRP.JobPainSounds.LastPainTime[playerID] = currentTime
    
    -- DEBUG: Log pain sound
    print(string.format("[TDMRP Pain] %s (%s) took %.0f dmg - Playing %s [pitch %d%%]", 
        target:GetName(), targetJob, dmg, soundFile, pitch))
    
end)

print("[TDMRP] Server pain sound hook loaded")
