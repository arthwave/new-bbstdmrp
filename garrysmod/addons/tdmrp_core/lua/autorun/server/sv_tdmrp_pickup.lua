-- sv_tdmrp_pickup.lua
-- Look-at-weapon -> store into TDMRP inventory (called from client command)
-- Updated for new TDMRP SWEP architecture with owner-lock support

if not SERVER then return end

TDMRP = TDMRP or {}

util.AddNetworkString("TDMRP_StoreLookWeapon")

-- Configuration
local OWNER_PICKUP_TIME = 5 -- seconds before anyone can store dropped weapon

-------------------------------------------------
-- Helper: can this weapon entity be stored?
-------------------------------------------------
local function CanStoreWeaponEnt(ent, ply)
    if not IsValid(ent) or not ent:IsWeapon() then return false, "Not a valid weapon" end

    -- Only world weapons (no owner)
    if ent:GetOwner() ~= NULL then return false, "Weapon is held by someone" end

    local class = ent:GetClass()
    if not class or class == "" then return false, "Invalid weapon class" end

    -- Use your existing blacklist helper if present
    if TDMRP_IsStoreForbidden and TDMRP_IsStoreForbidden(class) then
        return false, "This weapon cannot be stored"
    end
    
    -- Check owner lock (5-second exclusive window)
    if ent.TDMRP_DropTime and ent.TDMRP_OwnerSteamID then
        local elapsed = CurTime() - ent.TDMRP_DropTime
        if elapsed < OWNER_PICKUP_TIME then
            if ply:SteamID64() ~= ent.TDMRP_OwnerSteamID then
                local remaining = math.ceil(OWNER_PICKUP_TIME - elapsed)
                return false, "Locked to owner for " .. remaining .. " more seconds"
            end
        end
    end

    return true
end

-------------------------------------------------
-- Handle store-weapon request from client
-------------------------------------------------
net.Receive("TDMRP_StoreLookWeapon", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not TDMRP_AddItem or not TDMRP_SaveInventory then return end

    -- Trace from player's eyes
    local startPos = ply:EyePos()
    local dir      = ply:GetAimVector()
    local tr       = util.TraceLine({
        start  = startPos,
        endpos = startPos + dir * 80, -- 80 units in front
        filter = ply
    })

    local ent = tr.Entity
    if not IsValid(ent) then
        ply:ChatPrint("[TDMRP] No valid weapon in front of you to store.")
        return
    end

    local canStore, reason = CanStoreWeaponEnt(ent, ply)
    if not canStore then
        ply:ChatPrint("[TDMRP] " .. (reason or "That weapon cannot be stored."))
        return
    end

    -------------------------------------------------
    -- Build item data using instance system
    -------------------------------------------------
    local item

    if ent.TDMRP_ItemData then
        -- Weapon came from inventory earlier: reuse full item data
        item = table.Copy(ent.TDMRP_ItemData)
    else
        -- Build instance from world weapon, then convert to item
        local inst = nil
        if TDMRP_BuildInstanceFromSWEP then
            inst = TDMRP_BuildInstanceFromSWEP(nil, ent)
        end
        
        if inst and TDMRP.InstanceToItem then
            item = TDMRP.InstanceToItem(inst)
        else
            -- Fallback: build item manually
            local class = ent:GetClass()
            item = {
                kind        = "weapon",
                class       = class,
                tier        = ent:GetNWInt("TDMRP_Tier", 1),
                stats       = {
                    accuracy = ent:GetNWInt("TDMRP_Accuracy", 60),
                    recoil   = ent:GetNWInt("TDMRP_Recoil",   25),
                    handling = ent:GetNWInt("TDMRP_Handling", 100),
                    rpm      = ent:GetNWInt("TDMRP_RPM",      600),
                    damage   = ent:GetNWInt("TDMRP_Damage",   20),
                },
                cosmetic    = {
                    name     = ent:GetNWString("TDMRP_CustomName", ""),
                    material = ent:GetNWString("TDMRP_Material", ""),
                },
                craft       = {
                    crafted  = ent:GetNWBool("TDMRP_Crafted", false),
                    prefixId = ent:GetNWString("TDMRP_PrefixID", ""),
                    suffixId = ent:GetNWString("TDMRP_SuffixID", ""),
                },
                gems        = {
                    sapphire = ent:GetNWInt("TDMRP_Gem_Sapphire", 0),
                    emerald  = ent:GetNWInt("TDMRP_Gem_Emerald", 0),
                    ruby     = ent:GetNWInt("TDMRP_Gem_Ruby", 0),
                    diamond  = ent:GetNWInt("TDMRP_Gem_Diamond", 0),
                },
                bound_until = ent:GetNWFloat("TDMRP_BindUntil", 0),
            }
        end
    end

    if not item or not item.class or item.class == "" then
        ply:ChatPrint("[TDMRP] Failed to read weapon data.")
        return
    end

    -------------------------------------------------
    -- Store in inventory
    -------------------------------------------------
    local id = TDMRP_AddItem(ply, item)
    if not id then
        ply:ChatPrint("[TDMRP] Failed to store weapon into inventory.")
        return
    end

    -- Remove the world weapon so it isn't picked up anymore
    ent:Remove()

    -- Persist and refresh
    TDMRP_SaveInventory(ply)

    local displayName = (item.cosmetic and item.cosmetic.name ~= "") and item.cosmetic.name or item.class
    ply:ChatPrint(string.format("[TDMRP] Stored weapon (#%d): %s (Tier %d)", 
        id, displayName, item.tier or 1))
end)

print("[TDMRP] sv_tdmrp_pickup.lua loaded (look-store with owner lock)")
