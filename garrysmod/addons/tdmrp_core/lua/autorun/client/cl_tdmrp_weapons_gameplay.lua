-- cl_tdmrp_weapons_gameplay.lua
-- Apply TDMRP weapon stats to actual gameplay mechanics
-- - Spread/Accuracy: affects bullet cone
-- - Recoil: affects view punch
-- - Handling: affects aim speed and recoil recovery
-- - Reload: affects reload time

if not CLIENT then return end

TDMRP = TDMRP or {}
TDMRP.WeaponGameplay = TDMRP.WeaponGameplay or {}

-- Track weapon-specific stat modifiers
local weaponStatModifiers = {}

---------------------------------------------------------
-- Helper: Get or create stat modifier entry for a weapon
---------------------------------------------------------
local function GetWeaponStatEntry(wep)
    if not IsValid(wep) then return nil end
    
    local entIndex = wep:EntIndex()
    if not weaponStatModifiers[entIndex] then
        weaponStatModifiers[entIndex] = {
            originalCone      = wep.Primary and wep.Primary.Cone or 0,
            originalDelay     = wep.Primary and wep.Primary.Delay or 0,
            originalRecoil    = wep.Primary and wep.Primary.Recoil or 0,
            originalAimSpeed  = wep.AimSpeed or 0.1,
            originalReloadTime = wep.Primary and wep.Primary.ReloadTime or 2,
        }
    end
    return weaponStatModifiers[entIndex]
end

---------------------------------------------------------
-- Apply stat modifiers to a SWEP when deployed
---------------------------------------------------------
function TDMRP.WeaponGameplay.ApplyStatModifiers(wep)
    if not IsValid(wep) or not wep:IsWeapon() then return end
    
    -- Only apply to TDMRP weapons (must be tdmrp_m9k_*)
    if not TDMRP.IsM9KWeapon or not TDMRP.IsM9KWeapon(wep) then return end
    
    local ply = wep:GetOwner()
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    -- Read TDMRP stats
    local accuracy = wep:GetNWInt("TDMRP_Accuracy", 66)
    local recoil   = wep:GetNWInt("TDMRP_Recoil", 25)
    local handling = wep:GetNWInt("TDMRP_Handling", 100)
    local reload   = wep:GetNWInt("TDMRP_Reload", 50)
    local spread   = wep:GetNWFloat("TDMRP_BaseSpread", 0)
    local baseSpread = wep:GetNWFloat("TDMRP_BaseSpread", 0)
    
    -- Get original stats for this weapon
    local entry = GetWeaponStatEntry(wep)
    if not entry then return end
    
    -- Normalize stats to 0..1 ranges
    local accuracyNorm = math.Clamp(accuracy, 0, 95) / 95     -- 0=bad, 1=perfect
    local recoilNorm   = math.Clamp(recoil, 5, 250) / 250     -- 0=low, 1=high
    local handlingNorm = math.Clamp(handling, 0, 250) / 250   -- 0=bad, 1=perfect
    local reloadNorm   = math.Clamp(reload, 0, 100) / 100     -- 0=slow, 1=fast
    
    if not wep.Primary then return end
    
    -----------------------------------------
    -- Apply Accuracy/Spread
    -----------------------------------------
    -- Higher accuracy = tighter cone
    local minCone = entry.originalCone * 0.3  -- Best: 30% of base
    local maxCone = entry.originalCone * 1.5  -- Worst: 150% of base
    local appliedCone = Lerp(accuracyNorm, maxCone, minCone)
    wep.Primary.Cone = appliedCone
    
    -----------------------------------------
    -- Apply Recoil to view punch
    -----------------------------------------
    -- Store recoil setting for Fire hook to use
    wep.TDMRP_RecoilMultiplier = Lerp(recoilNorm, 0.5, 2.0)  -- 0.5x to 2.0x
    
    -----------------------------------------
    -- Apply Handling to aim speed
    -----------------------------------------
    -- Higher handling = faster ADS
    if entry.originalAimSpeed > 0 then
        local minAimSpeed = entry.originalAimSpeed * 0.5  -- Slow
        local maxAimSpeed = entry.originalAimSpeed * 2.0  -- Fast
        wep.AimSpeed = Lerp(handlingNorm, minAimSpeed, maxAimSpeed)
    end
    
    -----------------------------------------
    -- Apply Reload stat to reload time
    -----------------------------------------
    -- Higher reload = faster reload
    if entry.originalReloadTime > 0 then
        local minReloadTime = entry.originalReloadTime * 0.6  -- 60% of base (40% faster)
        local maxReloadTime = entry.originalReloadTime * 1.4  -- 140% of base (40% slower)
        wep.Primary.ReloadTime = Lerp(reloadNorm, maxReloadTime, minReloadTime)
    end
end

---------------------------------------------------------
-- Hook: Apply modifiers when weapon is deployed
---------------------------------------------------------
hook.Add("PlayerSwitchWeapon", "TDMRP_ApplyGameplayStats", function(ply, oldWep, newWep)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    if IsValid(newWep) then
        timer.Simple(0, function()
            if IsValid(newWep) then
                TDMRP.WeaponGameplay.ApplyStatModifiers(newWep)
            end
        end)
    end
end)

---------------------------------------------------------
-- Hook: Apply modifiers when weapon is given (delayed to sync NW vars)
---------------------------------------------------------
hook.Add("OnEntityCreated", "TDMRP_ApplyGameplayOnPickup", function(ent)
    if not IsValid(ent) or not ent:IsWeapon() then return end
    
    -- Delay a bit to let NW variables sync from server
    timer.Simple(0.1, function()
        if IsValid(ent) and TDMRP.IsM9KWeapon and TDMRP.IsM9KWeapon(ent) then
            local ply = ent:GetOwner()
            if IsValid(ply) and ply:IsPlayer() then
                TDMRP.WeaponGameplay.ApplyStatModifiers(ent)
            end
        end
    end)
end)

---------------------------------------------------------
-- Hook: Apply modifiers on weapon fire (for dynamic recoil patterns)
---------------------------------------------------------
hook.Add("EntityFireBullets", "TDMRP_ApplyRecoil", function(ent, data)
    if not IsValid(ent) or not ent:IsPlayer() then return end
    
    local ply = ent
    local wep = ply:GetActiveWeapon()
    
    if not IsValid(wep) or not TDMRP.IsM9KWeapon or not TDMRP.IsM9KWeapon(wep) then return end
    
    -- Get recoil multiplier from weapon (set in ApplyStatModifiers)
    local recoilMult = wep.TDMRP_RecoilMultiplier or 1.0
    
    -- Get recoil pattern for this weapon based on shots fired
    local shotsFired = wep.TDMRP_ShotsFired or 1
    local pattern = TDMRP.RecoilPatterns and TDMRP.RecoilPatterns.GetPattern
    
    if pattern then
        local recoilPattern = pattern(wep:GetClass(), shotsFired)
        local pitch = recoilPattern[1] * recoilMult
        local yaw = recoilPattern[2] * recoilMult
        
        ply:ViewPunch(Angle(pitch, yaw, 0))
    else
        -- Fallback to simple random punch if pattern not found
        local recoil = wep:GetNWInt("TDMRP_Recoil", 25)
        local recoilNorm = math.Clamp(recoil, 5, 250) / 250
        local punchScale = Lerp(recoilNorm, 0.3, 1.2)
        
        ply:ViewPunch(Angle(
            math.Rand(-0.5, -0.2) * punchScale,
            math.Rand(-0.2, 0.2) * punchScale,
            0
        ))
    end
    
    -- Play quad damage overlay sound if active (with 0.05s cooldown to avoid spam on high fire rate weapons)
    if ply:GetNWBool("TDMRP_SkillActive", false) then
        local activeSkillID = ply:GetNWString("TDMRP_ActiveSkillID", "")
        if activeSkillID == "quaddamage" then
            -- Check if enough time has passed since last overlay sound
            ply.TDMRP_LastOverlaySoundTime = ply.TDMRP_LastOverlaySoundTime or 0
            if CurTime() >= ply.TDMRP_LastOverlaySoundTime + 0.05 then
                local skillData = TDMRP.ActiveSkills.GetSkillData("quaddamage")
                if skillData and skillData.overlaySound then
                    -- EmitSound plays local to the player, so both player and nearby entities hear it
                    ply:EmitSound(skillData.overlaySound, 104, 100)
                    ply.TDMRP_LastOverlaySoundTime = CurTime()
                end
            end
        end
    end
end)

---------------------------------------------------------
-- Listen for stat changes (NW var updates) and reapply
---------------------------------------------------------
local lastAccuracy = 0
local lastRecoil = 0
local lastHandling = 0
local lastReload = 0

hook.Add("Think", "TDMRP_UpdateWeaponGameplay", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not TDMRP.IsM9KWeapon or not TDMRP.IsM9KWeapon(wep) then return end
    
    -- Check if stats changed
    local accuracy = wep:GetNWInt("TDMRP_Accuracy", 66)
    local recoil   = wep:GetNWInt("TDMRP_Recoil", 25)
    local handling = wep:GetNWInt("TDMRP_Handling", 100)
    local reload   = wep:GetNWInt("TDMRP_Reload", 50)
    
    if accuracy ~= lastAccuracy or recoil ~= lastRecoil or 
       handling ~= lastHandling or reload ~= lastReload then
        TDMRP.WeaponGameplay.ApplyStatModifiers(wep)
        lastAccuracy = accuracy
        lastRecoil = recoil
        lastHandling = handling
        lastReload = reload
    end
end)

---------------------------------------------------------
-- Clean up tracking when weapon is dropped
---------------------------------------------------------
hook.Add("OnEntityDestroyed", "TDMRP_CleanupWeaponStats", function(ent)
    if not IsValid(ent) or not ent:IsWeapon() then return end
    local entIndex = ent:EntIndex()
    weaponStatModifiers[entIndex] = nil
end)

print("[TDMRP] cl_tdmrp_weapons_gameplay.lua loaded (weapon stat gameplay mechanics)")
