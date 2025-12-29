-- sv_tdmrp_weapondrop.lua
-- Override DarkRP's /drop and preserve TDMRP weapon identity
-- Updated for new TDMRP SWEP architecture with 5-second owner-only pickup

if not SERVER then return end

TDMRP = TDMRP or {}

-- Configuration
local OWNER_PICKUP_TIME = 5 -- seconds before anyone can pick up dropped weapon

----------------------------------------------------------------------
-- Helper: Check if weapon is a TDMRP weapon (new or legacy)
----------------------------------------------------------------------
local function IsTDMRPWeapon(wep)
    if not IsValid(wep) then return false end
    local class = wep:GetClass()
    
    -- New derived SWEPs start with "tdmrp_m9k_"
    if string.sub(class, 1, 10) == "tdmrp_m9k_" then
        return true
    end
    
    -- Use M9K registry check as fallback
    if TDMRP.IsM9KWeapon and TDMRP.IsM9KWeapon(wep) then
        return true
    end
    
    return false
end

----------------------------------------------------------------------
-- Override DarkRP /drop using chat command hook
----------------------------------------------------------------------
hook.Add("PlayerSay", "TDMRP_OverrideDropCommand", function(ply, text)
    if not IsValid(ply) then return end
    
    local lower = string.lower(text)
    if lower ~= "/drop" and lower ~= "!drop" then return end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then
        ply:ChatPrint("[TDMRP] You must be holding a weapon to drop it.")
        return ""
    end
    
    local class = wep:GetClass()
    
    -- TDMRP: Check if weapon is bound FIRST (before DarkRP checks)
    if TDMRP.Binding and TDMRP.Binding.GetRemainingTime then
        local remaining = TDMRP.Binding.GetRemainingTime(wep)
        if remaining > 0 then
            local mins = math.floor(remaining / 60)
            local secs = math.floor(remaining % 60)
            ply:ChatPrint(string.format("[TDMRP] Cannot drop bound weapon! Unbind it first using Blood Ruby (%02d:%02d remaining)", mins, secs))
            return ""
        end
    end
    
    -- Check if can drop (use DarkRP's hook if available - this runs all hooks)
    if hook.Call then
        local can = hook.Call("canDropWeapon", GAMEMODE, ply, wep)
        if can == false then
            ply:ChatPrint("[TDMRP] You cannot drop this weapon.")
            return ""
        end
    elseif GAMEMODE and GAMEMODE.canDropWeapon then
        local can, reason = GAMEMODE:canDropWeapon(ply, wep)
        if not can then
            ply:ChatPrint(reason or "You cannot drop this weapon.")
            return ""
        end
    end
    
    -- Build instance from current weapon (captures all TDMRP data)
    local inst = nil
    if IsTDMRPWeapon(wep) and TDMRP_BuildInstanceFromSWEP then
        inst = TDMRP_BuildInstanceFromSWEP(ply, wep)
    end
    
    -- Strip the weapon
    ply:StripWeapon(class)
    
    -- Spawn dropped entity
    local dropped = ents.Create(class)
    if not IsValid(dropped) then
        ply:ChatPrint("[TDMRP] Failed to drop weapon.")
        return ""
    end
    
    dropped:SetPos(ply:GetShootPos() + ply:GetAimVector() * 50)
    dropped:SetAngles(ply:EyeAngles())
    dropped:Spawn()
    
    -- Mark for E-key pickup with owner lock
    dropped.TDMRP_RequireUse = true
    dropped.TDMRP_DroppedBy = ply
    dropped.TDMRP_DropTime = CurTime()
    dropped.TDMRP_OwnerSteamID = ply:SteamID64()
    
    -- Apply TDMRP instance data to dropped weapon
    if inst and TDMRP.ApplyInstanceToSWEP then
        TDMRP.ApplyInstanceToSWEP(dropped, inst)
        dropped.TDMRP_InstanceID = inst.id
        
        local displayName = (inst.cosmetic and inst.cosmetic.name ~= "") and inst.cosmetic.name or class
        print(string.format("[TDMRP Drop] %s dropped %s (tier %d)", 
            ply:Nick(), displayName, inst.tier or 1))
    end
    
    -- Physics
    local phys = dropped:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetVelocity(ply:GetAimVector() * 200)
    end
    
    ply:ChatPrint("[TDMRP] Dropped weapon. You have " .. OWNER_PICKUP_TIME .. " seconds exclusive pickup.")
    
    return ""
end)

----------------------------------------------------------------------
-- Block auto-pickup for dropped weapons (require E key press)
----------------------------------------------------------------------
hook.Add("PlayerCanPickupWeapon", "TDMRP_BlockAutoPickup", function(ply, wep)
    if not IsValid(wep) then return end
    
    -- If this weapon requires Use (E key) to pickup, block auto-pickup
    if wep.TDMRP_RequireUse then
        return false
    end
end)

----------------------------------------------------------------------
-- Allow E key pickup for dropped weapons with owner-lock logic
----------------------------------------------------------------------
hook.Add("PlayerUse", "TDMRP_UsePickup", function(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return end
    if not ent:IsWeapon() then return end
    if not ent.TDMRP_RequireUse then return end
    
    local class = ent:GetClass()
    
    -- Check 5-second owner-only pickup window
    if ent.TDMRP_DropTime and ent.TDMRP_OwnerSteamID then
        local elapsed = CurTime() - ent.TDMRP_DropTime
        if elapsed < OWNER_PICKUP_TIME then
            -- Only owner can pick up during this window
            if ply:SteamID64() ~= ent.TDMRP_OwnerSteamID then
                local remaining = math.ceil(OWNER_PICKUP_TIME - elapsed)
                ply:ChatPrint("[TDMRP] This weapon is locked to its owner for " .. remaining .. " more seconds.")
                return false
            end
        end
    end
    
    -- Prevent immediate re-pickup by dropper (0.5 sec delay)
    if ent.TDMRP_DroppedBy == ply and ent.TDMRP_DropTime then
        if CurTime() - ent.TDMRP_DropTime < 0.5 then
            return false
        end
    end
    
    -- Check if player already has this weapon class
    if ply:HasWeapon(class) then
        ply:ChatPrint("[TDMRP] You already have this weapon type equipped.")
        return false
    end
    
    -- Build instance from world weapon before removing it
    local inst = nil
    if IsTDMRPWeapon(ent) then
        if ent.TDMRP_InstanceID and TDMRP.GetWeaponInstance then
            inst = TDMRP.GetWeaponInstance(ent.TDMRP_InstanceID)
        end
        if not inst and TDMRP_BuildInstanceFromSWEP then
            inst = TDMRP_BuildInstanceFromSWEP(nil, ent)
            -- Check if bound
            if inst and inst.bound_until and inst.bound_until > 0 then
                print(string.format("[TDMRP Pickup] Found bound weapon in instance: %.1f seconds remaining", inst.bound_until))
            end
        end
    end
    
    -- Set pending instance BEFORE Give() to prevent tier reset
    if inst and TDMRP.SetPendingInstance then
        TDMRP.SetPendingInstance(ply, class, inst)
    end
    
    -- Give the weapon to the player
    local given = ply:Give(class)
    if not IsValid(given) then
        ply:ChatPrint("[TDMRP] Failed to pick up weapon.")
        return false
    end
    
    -- Apply full instance data (tier already locked from pending)
    if inst and TDMRP.ApplyInstanceToSWEP then
        TDMRP.ApplyInstanceToSWEP(given, inst)
        given.TDMRP_InstanceID = inst.id
        
        local displayName = (inst.cosmetic and inst.cosmetic.name ~= "") and inst.cosmetic.name or class
        local bindStatus = ""
        if inst.bound_until and inst.bound_until > 0 then
            bindStatus = string.format(" (BOUND: %.1f seconds)", inst.bound_until)
        end
        print(string.format("[TDMRP Pickup] %s picked up %s (tier %d)%s", 
            ply:Nick(), displayName, inst.tier or 1, bindStatus))
    end
    
    -- Remove the world weapon
    ent:Remove()
    
    -- Select the weapon
    timer.Simple(0, function()
        if IsValid(ply) and IsValid(given) then
            ply:SelectWeapon(class)
        end
    end)
    
    return false -- Consume the use event
end)

----------------------------------------------------------------------
-- Fallback: Restore TDMRP data on normal weapon pickup (non-dropped)
-- NOTE: This hook also fires during ply:Give() - we must skip those cases
----------------------------------------------------------------------
hook.Add("PlayerCanPickupWeapon", "TDMRP_RestoreWeaponOnPickup", function(ply, wep)
    if not IsValid(ply) or not IsValid(wep) then return end
    if wep.TDMRP_RequireUse then return end -- Handled by UsePickup hook
    if not IsTDMRPWeapon(wep) then return end
    
    -- CRITICAL: Skip if weapon has no owner (world weapon) but was JUST spawned
    -- This prevents overwriting pending instances during Give() calls
    -- A weapon that was legitimately dropped will have TDMRP_DropTime set
    if not wep.TDMRP_DropTime then
        -- Weapon wasn't dropped by a player, likely spawned fresh via Give() or ents.Create()
        -- Don't interfere with the pending instance system
        return
    end

    -- Check if this world weapon has TDMRP data (tier != default)
    local tier = wep:GetNWInt("TDMRP_Tier", -1)
    if tier == -1 then return end
    
    -- Build instance from world weapon
    local inst = nil
    if wep.TDMRP_InstanceID and TDMRP.GetWeaponInstance then
        inst = TDMRP.GetWeaponInstance(wep.TDMRP_InstanceID)
    end
    if not inst and TDMRP_BuildInstanceFromSWEP then
        inst = TDMRP_BuildInstanceFromSWEP(nil, wep)
    end
    
    -- Set pending instance BEFORE the pickup completes
    -- This ensures Initialize/Equip can apply the tier immediately
    if inst and TDMRP.SetPendingInstance then
        TDMRP.SetPendingInstance(ply, wep:GetClass(), inst)
    end
    
    -- After pickup, apply full instance to held weapon (cosmetics, craft data, etc.)
    timer.Simple(0, function()
        if not IsValid(ply) or not inst then return end

        local heldWep = ply:GetWeapon(wep:GetClass())
        if not IsValid(heldWep) then return end

        if TDMRP.ApplyInstanceToSWEP then
            TDMRP.ApplyInstanceToSWEP(heldWep, inst)
            heldWep.TDMRP_InstanceID = inst.id
        end
    end)
end)

print("[TDMRP] sv_tdmrp_weapondrop.lua loaded (5-sec owner lock, instance preservation)")

