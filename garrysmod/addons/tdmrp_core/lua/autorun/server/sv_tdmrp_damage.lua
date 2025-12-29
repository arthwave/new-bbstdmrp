-- sv_tdmrp_damage.lua
-- Class-based damage rules for TDMRP

-- Helper: get tdmrp_class from a player (civilian / criminal / cop / zombie)
local function TDMRP_GetClass(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil end
    if not ply.getJobTable then return nil end

    local job = ply:getJobTable()
    if not job then return nil end

    return job.tdmrp_class -- we set this in jobs.lua
end

local function TDMRP_IsPlayerAttacker(ent)
    if not IsValid(ent) then return false, nil end

    -- Direct player
    if ent:IsPlayer() then return true, ent end

    -- Vehicle with driver
    if ent:IsVehicle() then
        local driver = ent:GetDriver()
        if IsValid(driver) and driver:IsPlayer() then
            return true, driver
        end
    end

    return false, nil
end

hook.Add("EntityTakeDamage", "TDMRP_ClassDamageRules", function(target, dmginfo)
    -- Only care about players taking damage
    if not IsValid(target) or not target:IsPlayer() then return end

    local isPlayerAttacker, attacker = TDMRP_IsPlayerAttacker(dmginfo:GetAttacker())
    if not isPlayerAttacker then
        -- Environment, NPCs, props, etc: allowed
        return
    end

    local tClass = TDMRP_GetClass(target)
    local aClass = TDMRP_GetClass(attacker)

    -- If either doesn't have a tdmrp_class (e.g. some admin job), do nothing
    if not tClass or not aClass then return end

    ----------------------------------------------------
    -- CIVILIANS: zero PvP involvement
    --  - Civilians cannot damage any players
    --  - Civilians cannot be damaged by any players
    ----------------------------------------------------
    if tClass == "civilian" or aClass == "civilian" then
        -- Block any player-vs-player damage involving a civilian
        dmginfo:SetDamage(0)
        dmginfo:ScaleDamage(0)

        if attacker ~= target and aClass == "civilian" then
            attacker:ChatPrint("[TDMRP] Civilians cannot participate in PvP.")
        elseif attacker ~= target and tClass == "civilian" then
            attacker:ChatPrint("[TDMRP] You cannot harm civilian-class players.")
        end

        return true -- stop further processing
    end
    ----------------------------------------------------
    -- FRIENDLY-FIRE BLOCK:  
    -- Prevent damage within the same combat class.
    -- (Cop→Cop, Criminal→Criminal, Zombie→Zombie)
    ----------------------------------------------------
    if aClass == tClass then
        dmginfo:SetDamage(0)
        dmginfo:ScaleDamage(0)

        if attacker ~= target then
            attacker:ChatPrint("[TDMRP] Friendly fire is disabled for your class.")
        end

        return true
    end

    ----------------------------------------------------
    -- At this point, neither side is civilian.
    -- Classes left: criminal, cop, zombie (once you add zombie jobs)
    --
    -- Rules recap:
    --  - Criminal: KOS vs Cops & Zombies (allowed)
    --  - Cop: KOS vs Criminals & Zombies (allowed)
    --  - Zombie: KOS vs all non-civ classes (allowed)
    --
    -- We are NOT blocking friendly fire within same combat class
    -- (cop vs cop, criminal vs criminal, zombie vs zombie) for now.
    ----------------------------------------------------

    -- Example: if you later want to block friendly fire by class, you can:
    -- if aClass == tClass then
    --     dmginfo:SetDamage(0)
    --     dmginfo:ScaleDamage(0)
    --     attacker:ChatPrint("[TDMRP] Friendly fire is disabled for your class.")
    --     return true
    -- end

    -- Otherwise: allow damage to go through.
end)
