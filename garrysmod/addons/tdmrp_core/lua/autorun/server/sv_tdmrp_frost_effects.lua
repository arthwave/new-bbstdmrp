----------------------------------------------------
-- TDMRP Frost Suffix Effects (Server-Side)
-- Handles slow mechanics and death explosions
----------------------------------------------------

if CLIENT then return end

util.AddNetworkString("TDMRP_FrostSlowUpdate")
util.AddNetworkString("TDMRP_FrostDeathExplosion")

-- Track frost slow levels and timers per player
TDMRP = TDMRP or {}
TDMRP.Frost = TDMRP.Frost or {}
TDMRP.Frost.PlayerSlows = {}  -- [ply] = { level, expiryTime, decayTimer }

----------------------------------------------------
-- Apply Frost Slow to Target
----------------------------------------------------

function TDMRP_ApplyFrostSlow(target, attacker, weapon)
    if not IsValid(target) or not target:IsPlayer() then return end
    if not IsValid(attacker) then return end
    
    local slowConfig = TDMRP.Gems.Suffixes.of_Frost
    if not slowConfig then return end
    
    -- Get current slow level
    local currentData = TDMRP.Frost.PlayerSlows[target] or { level = 0, expiryTime = 0, decayTimer = nil }
    
    -- Calculate new slow level (capped at maxSlowLevel)
    local newSlowLevel = math.min(
        currentData.level + slowConfig.slowPerHit,
        slowConfig.maxSlowLevel
    )
    
    -- Cancel old decay timer if exists
    if currentData.decayTimer then
        timer.Remove(currentData.decayTimer)
    end
    
    -- Store new slow data
    local expiryTime = CurTime() + slowConfig.slowDuration
    TDMRP.Frost.PlayerSlows[target] = {
        level = newSlowLevel,
        expiryTime = expiryTime,
        decayTimer = nil,  -- Will be set below
        attacker = attacker
    }
    
    -- Create decay timer
    local decayTimerId = "TDMRP_FrostDecay_" .. target:EntIndex()
    timer.Create(decayTimerId, slowConfig.slowDuration, 1, function()
        if IsValid(target) then
            TDMRP.Frost.PlayerSlows[target] = nil
            -- Network update to client
            net.Start("TDMRP_FrostSlowUpdate")
                net.WriteEntity(target)
                net.WriteFloat(0)
            net.SendPVS(target:GetPos())
        end
    end)
    
    TDMRP.Frost.PlayerSlows[target].decayTimer = decayTimerId
    
    -- Network update to clients
    net.Start("TDMRP_FrostSlowUpdate")
        net.WriteEntity(target)
        net.WriteFloat(newSlowLevel)
    net.SendPVS(target:GetPos())
    
    -- Send frost vignette to victim (blue tint)
    if TDMRP.SendEffectVignette then
        TDMRP.SendEffectVignette(target, Color(100, 180, 255, 60), slowConfig.slowDuration)
    end
    
    -- Send center message to victim about being slowed
    if TDMRP.SendCenterMessage and newSlowLevel >= slowConfig.slowPerHit * 2 then
        -- Only show message when significantly slowed (2+ stacks)
        TDMRP.SendCenterMessage(target, "FROSTED - " .. math.floor(newSlowLevel) .. "% SLOWED", Color(100, 180, 255), 1.5)
    end
    
    print(string.format("[TDMRP Frost] %s slowed by %s: %.1f%% (total: %.1f%%)", 
        target:Nick(), attacker:Nick(), slowConfig.slowPerHit, newSlowLevel))
end

----------------------------------------------------
-- Movement Speed Hook
----------------------------------------------------

-- Hook into player movement to apply slow
local function TDMRP_ApplyFrostMovement(ply, moveData)
    local slowData = TDMRP.Frost.PlayerSlows[ply]
    if not slowData or slowData.level <= 0 then return end
    
    -- Check if expired
    if CurTime() > slowData.expiryTime then
        TDMRP.Frost.PlayerSlows[ply] = nil
        return
    end
    
    -- Apply movement speed reduction
    -- slowLevel is 0-50 (percentage), so 0.5 = 50% slow
    local slowMultiplier = 1 - (slowData.level / 100)
    moveData:SetMaxSpeed(moveData:GetMaxSpeed() * slowMultiplier)
    moveData:SetMaxClientSpeed(moveData:GetMaxClientSpeed() * slowMultiplier)
end

hook.Add("Move", "TDMRP_FrostSlow", TDMRP_ApplyFrostMovement)

----------------------------------------------------
-- Frost Death Explosion
----------------------------------------------------

function TDMRP_FrostDeathExplosion(victim, attacker, weapon)
    if not IsValid(victim) or not IsValid(attacker) or not IsValid(weapon) then return end
    
    local deathPos = victim:GetPos()
    local slowConfig = TDMRP.Gems.Suffixes.of_Frost
    
    -- Damage nearby enemies with light AOE
    local nearbyEnts = ents.FindInSphere(deathPos, slowConfig.explosionRadius)
    for _, ent in ipairs(nearbyEnts) do
        if not IsValid(ent) then continue end
        
        -- Skip victim (already dead) and attacker
        if ent == victim or ent == attacker then continue end
        
        -- Only damage players and NPCs
        if ent:IsPlayer() or ent:IsNPC() then
            -- Skip friendly fire
            if ent:IsPlayer() and attacker:IsPlayer() then
                if attacker:Team() == ent:Team() then
                    continue
                end
            end
            
            -- Calculate distance-based damage falloff
            local distToTarget = deathPos:Distance(ent:GetPos())
            local damageFalloff = math.max(0, 1 - (distToTarget / slowConfig.explosionRadius))
            local explosionDamage = slowConfig.explosionDamage * damageFalloff
            
            if explosionDamage > 0.5 then
                -- Apply damage
                local dmg = DamageInfo()
                dmg:SetDamage(explosionDamage)
                dmg:SetAttacker(attacker)
                dmg:SetInflictor(weapon)
                dmg:SetDamageType(DMG_FREEZE)
                dmg:SetDamagePosition(deathPos)
                
                pcall(function() ent:TakeDamage(dmg) end)
                
                -- Light knockback
                local knockbackDir = (ent:GetPos() - deathPos):GetNormalized()
                local knockbackForce = 20 * damageFalloff
                if IsValid(ent) then
                    ent:SetVelocity(ent:GetVelocity() + knockbackDir * knockbackForce)
                end
            end
        end
    end
    
    -- Play death explosion sound
    sound.Play("tdmrp/suffixsounds/offrostdeath.mp3", deathPos, 100, 100)
    
    -- Network the explosion visual to all clients
    net.Start("TDMRP_FrostDeathExplosion")
        net.WriteVector(deathPos)
    net.Broadcast()
    
    print(string.format("[TDMRP Frost] Death explosion triggered at victim position"))
end

----------------------------------------------------
-- Cleanup on Player Disconnect
----------------------------------------------------

hook.Add("PlayerDisconnected", "TDMRP_FrostCleanup", function(ply)
    if TDMRP.Frost.PlayerSlows[ply] and TDMRP.Frost.PlayerSlows[ply].decayTimer then
        timer.Remove(TDMRP.Frost.PlayerSlows[ply].decayTimer)
    end
    TDMRP.Frost.PlayerSlows[ply] = nil
end)

----------------------------------------------------
-- Death Hook for Frost Weapon Kills
----------------------------------------------------

hook.Add("PlayerDeath", "TDMRP_FrostDeathHook", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    
    -- The inflictor is often the player or world, not the weapon
    -- We need to check the attacker's active weapon instead
    local weapon = attacker:GetActiveWeapon()
    if not IsValid(weapon) then return end
    
    -- Check if weapon has Frost suffix
    local suffixId = weapon:GetNWString("TDMRP_SuffixID", "")
    if suffixId ~= "of_Frost" then return end
    
    print("[TDMRP Frost] Death by frost weapon detected! Triggering explosion...")
    
    -- Trigger frost death explosion
    TDMRP_FrostDeathExplosion(victim, attacker, weapon)
end)

print("[TDMRP] sv_tdmrp_frost_effects.lua loaded")
