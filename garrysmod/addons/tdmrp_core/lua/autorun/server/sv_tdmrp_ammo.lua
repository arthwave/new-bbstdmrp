-- sv_tdmrp_ammo.lua
-- Server-side logic for buying ammo from the F4 Ammo tab

if not SERVER then return end

util.AddNetworkString("TDMRP_BuyAmmo")

----------------------------------------------------
-- Who can use the Ammo shop? All combat roles
----------------------------------------------------
local function IsAmmoVendor(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    local job = ply.getJobTable and ply:getJobTable() or nil
    local cls = job and job.tdmrp_class

    -- All combat roles: criminal / cop / zombie
    if cls == "criminal" then return true end
    if cls == "cop"      then return true end
    if cls == "zombie"   then return true end

    return false
end

----------------------------------------------------
-- Ammo definitions
-- NOTE: ammoType strings ("Pistol", "SMG1", etc.) may
-- need tweaking depending on your weapon pack's Primary.Ammo
----------------------------------------------------
local AmmoDefs = {
    rifle_smg = {
        display  = "Rifle/Sniper Ammo",
        price    = 250,
        -- Adjust these ammo types / amounts to taste
        grants = {
            { type = "SMG1",  amount = 60 },  -- SMG / rifle-type
            { type = "AR2",   amount = 60 },  -- AR-type (if used)
        }
    },

    pistol = {
        display  = "Pistol Ammo",
        price    = 150,
        grants = {
            { type = "Pistol", amount = 60 },
        }
    },

    buckshot = {
        display  = "Buckshot Ammo",
        price    = 200,
        grants = {
            { type = "Buckshot", amount = 32 },
        }
    },

    projectile = {
        display  = "Projectile Ammo",
        price    = 250,
        grants = {
            { type = "XBowBolt", amount = 15 },
        }
    }
}

----------------------------------------------------
-- Actually give ammo to the player
----------------------------------------------------
local function GiveAmmoForDef(ply, def)
    if not def or not def.grants then return false end
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    for _, grant in ipairs(def.grants) do
        local ammoType = grant.type
        local amount   = tonumber(grant.amount) or 0

        if ammoType and amount > 0 then
            local given = ply:GiveAmmo(amount, ammoType, true)
            -- Optional debug:
            -- print(string.format("[TDMRP] Gave %d of ammo '%s' to %s (returned %d)",
            --     amount, ammoType, ply:Nick(), given))
        end
    end

    return true
end

----------------------------------------------------
-- Net receive: Buy ammo
----------------------------------------------------
net.Receive("TDMRP_BuyAmmo", function(len, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local ammoID = net.ReadString() or ""
    if ammoID == "" then return end

    local def = AmmoDefs[ammoID]
    if not def then
        ply:ChatPrint("[TDMRP] Unknown ammo type.")
        return
    end

    if not IsAmmoVendor(ply) then
        ply:ChatPrint("[TDMRP] Your job cannot use the ammo shop.")
        return
    end

    local price = def.price or 0
    if price <= 0 then
        ply:ChatPrint("[TDMRP] This ammo cannot be purchased.")
        return
    end

    local money = ply.getDarkRPVar and ply:getDarkRPVar("money") or 0
    if money < price then
        ply:ChatPrint("[TDMRP] You can't afford this ammo (" .. price .. "$).")
        return
    end

    -- Take the money
    if ply.addMoney then
        ply:addMoney(-price)
    end

    local success = GiveAmmoForDef(ply, def)
    if not success then
        -- Refund on failure
        if ply.addMoney then
            ply:addMoney(price)
        end
        ply:ChatPrint("[TDMRP] Failed to give ammo; purchase refunded.")
        return
    end

    ply:ChatPrint("[TDMRP] Purchased " .. (def.display or "ammo") .. ".")
end)

print("[TDMRP] sv_tdmrp_ammo.lua loaded (GiveAmmo-based)")
