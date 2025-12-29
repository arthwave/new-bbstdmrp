-- sv_tdmrp_pickupguard.lua
-- Prevent players from picking up a weapon if they already have that class equipped

if not SERVER then return end

TDMRP = TDMRP or {}

-- Store last duplicate weapon message time per player
TDMRP.DuplicateWeaponMessageTime = TDMRP.DuplicateWeaponMessageTime or {}

-- Helper: decide if this is one of *our* combat guns (must be tdmrp_m9k_*)
local function TDMRP_IsOurGun(wep)
    if not IsValid(wep) or not wep:IsWeapon() then return false end

    -- Use the M9K weapon check from sh_tdmrp_m9k_registry.lua
    if TDMRP.IsM9KWeapon then
        return TDMRP.IsM9KWeapon(wep)
    end

    -- Fallback: check if class starts with tdmrp_m9k_
    local class = wep:GetClass()
    return string.sub(class, 1, 10) == "tdmrp_m9k_"
end

hook.Add("PlayerCanPickupWeapon", "TDMRP_BlockDuplicateGunPickup", function(ply, wep)
    if not IsValid(ply) or not IsValid(wep) then return end
    if not TDMRP_IsOurGun(wep) then return end

    local class = wep:GetClass()

    -- If the player already has this SWEP class, block pickup.
    if ply:HasWeapon(class) then
        -- Allow silent pickup for dropped weapons (they handle their own duplicate check in PlayerUse)
        if wep.TDMRP_RequireUse then
            return false  -- silently block (no chat message)
        end
        
        -- For other pickups (shop, etc), show the message with 10 second cooldown
        local steamID = ply:SteamID()
        local lastMessageTime = TDMRP.DuplicateWeaponMessageTime[steamID] or 0
        
        if CurTime() - lastMessageTime >= 10 then
            ply:ChatPrint("[TDMRP] You already have this weapon equipped. Store or drop it first.")
            TDMRP.DuplicateWeaponMessageTime[steamID] = CurTime()
        end
        
        return false  -- deny pickup, leave weapon on the ground
    end
end)

-- Clean up on disconnect
hook.Add("PlayerDisconnected", "TDMRP_CleanupDuplicateMessageTime", function(ply)
    TDMRP.DuplicateWeaponMessageTime[ply:SteamID()] = nil
end)

print("[TDMRP] sv_tdmrp_pickupguard.lua loaded (duplicate pickup protection)")
