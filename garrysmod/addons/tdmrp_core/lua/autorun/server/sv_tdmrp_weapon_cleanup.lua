----------------------------------------------------
-- TDMRP Weapon Cleanup System
-- Automatically removes dropped tdmrp_m9k weapons from the map
-- after a configurable timeout (default 30 seconds)
----------------------------------------------------

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.WeaponCleanup = TDMRP.WeaponCleanup or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

local CONFIG = {
    ENABLED = true,                    -- Enable/disable cleanup
    CLEANUP_TIMEOUT = 30,              -- Seconds before dropped weapon is removed
    CHECK_INTERVAL = 2,                -- How often to scan for expired weapons (seconds)
    VERBOSE = true,                    -- Print cleanup messages to console
}

----------------------------------------------------
-- State
----------------------------------------------------

local lastCleanupTime = 0
local cleanupStats = {
    removed = 0,
    checked = 0,
}

----------------------------------------------------
-- Helper: Get weapon display name for logging
----------------------------------------------------

local function GetWeaponName(wep)
    if not IsValid(wep) then return "Unknown" end
    
    if TDMRP and TDMRP.M9KRegistry then
        local baseClass = string.Replace(wep:GetClass(), "tdmrp_m9k_", "m9k_")
        local regEntry = TDMRP.M9KRegistry[baseClass]
        if regEntry and regEntry.name then
            return regEntry.name
        end
    end
    
    local printName = wep:GetPrintName()
    if printName and printName ~= "" then
        return printName
    end
    
    return wep:GetClass()
end

----------------------------------------------------
-- Track weapon drop time
----------------------------------------------------

hook.Add("PlayerDroppedWeapon", "TDMRP_TrackWeaponDropTime", function(ply, wep)
    if not IsValid(wep) then return end
    
    -- Only track TDMRP M9K weapons
    if not TDMRP.IsM9KWeapon or not TDMRP.IsM9KWeapon(wep) then return end
    
    -- Mark the drop time
    wep:SetNWFloat("TDMRP_DropTime", CurTime())
    
    if CONFIG.VERBOSE then
        print(string.format("[TDMRP Cleanup] Weapon dropped: %s (will expire at %.1f)", GetWeaponName(wep), CurTime() + CONFIG.CLEANUP_TIMEOUT))
    end
end)

----------------------------------------------------
-- Cleanup loop: Remove expired weapons
----------------------------------------------------

hook.Add("Think", "TDMRP_WeaponCleanupLoop", function()
    if not CONFIG.ENABLED then return end
    
    local curTime = CurTime()
    
    -- Throttle checks to avoid constant full entity iteration
    if curTime - lastCleanupTime < CONFIG.CHECK_INTERVAL then return end
    lastCleanupTime = curTime
    
    -- Scan all entities for expired weapons
    local removed = 0
    local checked = 0
    
    for _, ent in ipairs(ents.GetAll()) do
        if not IsValid(ent) then continue end
        if not ent:IsWeapon() then continue end
        
        -- Only check TDMRP M9K weapons
        if not TDMRP.IsM9KWeapon or not TDMRP.IsM9KWeapon(ent) then continue end
        
        -- Skip if weapon has an owner (still equipped or being held)
        if IsValid(ent:GetOwner()) then continue end
        
        checked = checked + 1
        
        -- Check if weapon has been dropped and expired
        local dropTime = ent:GetNWFloat("TDMRP_DropTime", 0)
        if dropTime <= 0 then
            -- If we didn't catch the drop hook or weapon was placed on ground by another system,
            -- start tracking time now so the weapon will be cleaned up after the timeout window.
            ent:SetNWFloat("TDMRP_DropTime", CurTime())
            if CONFIG.VERBOSE then
                print(string.format("[TDMRP Cleanup] Now tracking ground weapon: %s (marked at %.1f)", GetWeaponName(ent), CurTime()))
            end
        else
            local timeOnGround = curTime - dropTime

            
            if timeOnGround > CONFIG.CLEANUP_TIMEOUT then
                if CONFIG.VERBOSE then
                    print(string.format("[TDMRP Cleanup] Removing expired weapon: %s (on ground for %.1fs)", GetWeaponName(ent), timeOnGround))
                end
                
                ent:Remove()
                removed = removed + 1
            end
        end
    end
    
    -- Update stats
    cleanupStats.removed = cleanupStats.removed + removed
    cleanupStats.checked = checked
    
    if removed > 0 and CONFIG.VERBOSE then
        print(string.format("[TDMRP Cleanup] Cleaned up %d expired weapons (checked %d total)", removed, checked))
    end
end)

----------------------------------------------------
-- Admin command: Force cleanup
----------------------------------------------------

concommand.Add("tdmrp_cleanup_now", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local removed = 0
    local checked = 0
    
    for _, ent in ipairs(ents.GetAll()) do
        if not IsValid(ent) then continue end
        if not ent:IsWeapon() then continue end
        if not TDMRP.IsM9KWeapon or not TDMRP.IsM9KWeapon(ent) then continue end
        if IsValid(ent:GetOwner()) then continue end
        
        checked = checked + 1
        ent:Remove()
        removed = removed + 1
    end
    
    ply:ChatPrint(string.format("[TDMRP] Force cleanup complete: removed %d weapons, checked %d total", removed, checked))
    print(string.format("[TDMRP Cleanup] Admin force cleanup by %s: removed %d weapons", ply:Nick(), removed))
end)

----------------------------------------------------
-- Admin command: Check cleanup stats
----------------------------------------------------

concommand.Add("tdmrp_cleanup_stats", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    
    local msg = string.format(
        "[TDMRP Cleanup Stats] Enabled: %s | Timeout: %ds | Check Interval: %ds | Total Removed: %d",
        CONFIG.ENABLED and "Yes" or "No",
        CONFIG.CLEANUP_TIMEOUT,
        CONFIG.CHECK_INTERVAL,
        cleanupStats.removed
    )
    
    ply:ChatPrint(msg)
end)

----------------------------------------------------
-- Startup message
----------------------------------------------------

print("[TDMRP] sv_tdmrp_weapon_cleanup.lua loaded")
print(string.format("[TDMRP Cleanup] Cleanup system enabled: %s (timeout: %ds, check: every %ds)", 
    CONFIG.ENABLED and "Yes" or "No", CONFIG.CLEANUP_TIMEOUT, CONFIG.CHECK_INTERVAL))
