-- sv_tdmrp_shop.lua
-- TDMRP F4 weapon shop server logic
-- Sells Tier 1 (Common) weapons directly to player's hands

if not SERVER then return end

util.AddNetworkString("TDMRP_BuyWeapon")

----------------------------------------------------------------------
-- CSS Weapons Registry (server-side)
-- These weapons use weapon_tdmrp_cs_* class names
----------------------------------------------------------------------

local CSS_WEAPONS = {
    ["weapon_tdmrp_cs_glock18"] = { name = "Glock-18", basePrice = 500, type = "pistol" },
    ["weapon_tdmrp_cs_usp"] = { name = "USP", basePrice = 600, type = "pistol" },
    ["weapon_tdmrp_cs_p228"] = { name = "P228", basePrice = 550, type = "pistol" },
    ["weapon_tdmrp_cs_five_seven"] = { name = "Five-Seven", basePrice = 700, type = "pistol" },
    ["weapon_tdmrp_cs_elites"] = { name = "Dual Elites", basePrice = 900, type = "pistol" },
    ["weapon_tdmrp_cs_desert_eagle"] = { name = "Desert Eagle", basePrice = 1200, type = "pistol" },
    ["weapon_tdmrp_cs_mp5a5"] = { name = "MP5", basePrice = 1800, type = "smg" },
    ["weapon_tdmrp_cs_p90"] = { name = "P90", basePrice = 2200, type = "smg" },
    ["weapon_tdmrp_cs_mac10"] = { name = "MAC-10", basePrice = 1500, type = "smg" },
    ["weapon_tdmrp_cs_tmp"] = { name = "TMP", basePrice = 1300, type = "smg" },
    ["weapon_tdmrp_cs_ump_45"] = { name = "UMP-45", basePrice = 1600, type = "smg" },
    ["weapon_tdmrp_cs_ak47"] = { name = "AK-47", basePrice = 3500, type = "rifle" },
    ["weapon_tdmrp_cs_m4a1"] = { name = "M4A1", basePrice = 3800, type = "rifle" },
    ["weapon_tdmrp_cs_aug"] = { name = "AUG", basePrice = 4000, type = "rifle" },
    ["weapon_tdmrp_cs_famas"] = { name = "FAMAS", basePrice = 2800, type = "rifle" },
    ["weapon_tdmrp_cs_sg552"] = { name = "SG552", basePrice = 3600, type = "rifle" },
    ["weapon_tdmrp_cs_pumpshotgun"] = { name = "Pump Shotgun", basePrice = 2000, type = "shotgun" },
    ["weapon_tdmrp_cs_awp"] = { name = "AWP", basePrice = 6000, type = "sniper" },
    ["weapon_tdmrp_cs_knife"] = { name = "Knife", basePrice = 100, type = "melee" },
}

----------------------------------------------------------------------
-- Which jobs are weapon vendors?
-- Gun Dealer, Quartermaster, Trafficker can all sell weapons
----------------------------------------------------------------------

local function TDMRP_IsWeaponVendor(ply)
    if not IsValid(ply) then return false end

    local teamID = ply:Team()
    local jobName = ply.getDarkRPVar and ply:getDarkRPVar("job") or ""
    jobName = string.lower(jobName)
    
    -- Check by job name (most reliable)
    if string.find(jobName, "gun dealer") or string.find(jobName, "gundealer") then
        return "civ_gundealer"
    end
    if string.find(jobName, "quartermaster") then
        return "cop_quartermaster"
    end
    if string.find(jobName, "trafficker") then
        return "crim_trafficker"
    end
    
    -- Fallback: check by team constant if defined
    if TEAM_GUNDEALER and teamID == TEAM_GUNDEALER then
        return "civ_gundealer"
    end
    if TEAM_QUARTERMASTER and teamID == TEAM_QUARTERMASTER then
        return "cop_quartermaster"
    end
    if TEAM_TRAFFICKER and teamID == TEAM_TRAFFICKER then
        return "crim_trafficker"
    end

    return nil
end

----------------------------------------------------------------------
-- Shared helper: can this player receive another weapon of className?
----------------------------------------------------------------------

local function TDMRP_CanPlayerReceiveWeaponClass(ply, className)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not className or className == "" then return false end

    -- Check for the tdmrp version
    if ply:HasWeapon(className) then
        ply:ChatPrint("[TDMRP] You already have this weapon type equipped. Store or drop it first.")
        return false
    end

    -- Also check base M9K class to prevent duplicates
    local baseClass = TDMRP_GetBaseM9KClass and TDMRP_GetBaseM9KClass(className)
    if baseClass and ply:HasWeapon(baseClass) then
        ply:ChatPrint("[TDMRP] You already have this weapon type equipped (base version). Store or drop it first.")
        return false
    end

    return true
end

----------------------------------------------------------------------
-- Get TDMRP weapon class from M9K registry entry
----------------------------------------------------------------------

local function GetTDMRPClass(m9kClass)
    -- Convert m9k_glock -> tdmrp_m9k_glock
    if string.sub(m9kClass, 1, 4) == "m9k_" then
        return "tdmrp_" .. m9kClass
    end
    return m9kClass
end

----------------------------------------------------------------------
-- Network handler: buy weapon from F4 shop
----------------------------------------------------------------------

net.Receive("TDMRP_BuyWeapon", function(_, ply)
    if not IsValid(ply) then return end

    -- Client sends the weapon class name (e.g., "m9k_glock" or "weapon_tdmrp_cs_ak47")
    local weaponClass = net.ReadString()
    if not weaponClass or weaponClass == "" then return end

    -- Allow all classes (cop, criminal, civilian) to access weapon shop
    local jobTable = ply:getJobTable()
    if not jobTable or not jobTable.tdmrp_class then
        ply:ChatPrint("[TDMRP] Unable to determine job class.")
        return
    end
    
    -- Validate it's a known class
    if jobTable.tdmrp_class ~= "cop" and jobTable.tdmrp_class ~= "criminal" and jobTable.tdmrp_class ~= "civilian" then
        ply:ChatPrint("[TDMRP] Unknown job class.")
        return
    end

    -- Determine if this is a CSS weapon or M9K weapon
    -- "weapon_tdmrp_cs_" is 16 characters
    local isCSS = string.sub(weaponClass, 1, 16) == "weapon_tdmrp_cs_"
    local meta = nil
    local tdmrpClass = nil
    local price = 0
    
    if isCSS then
        -- CSS weapon - class IS the final class
        if not CSS_WEAPONS[weaponClass] then
            ply:ChatPrint("[TDMRP] Unknown CSS weapon: " .. tostring(weaponClass))
            return
        end
        meta = CSS_WEAPONS[weaponClass]
        tdmrpClass = weaponClass
        price = meta.basePrice or 0
    else
        -- M9K weapon - need to look up in registry
        if not TDMRP.M9KRegistry or not TDMRP.M9KRegistry[weaponClass] then
            ply:ChatPrint("[TDMRP] Unknown M9K weapon: " .. tostring(weaponClass))
            return
        end
        meta = TDMRP.M9KRegistry[weaponClass]
        tdmrpClass = GetTDMRPClass(weaponClass)
        price = meta.basePrice or 0
    end
    
    -- Validate weapon is in active loadout (60-weapon filter)
    if TDMRP.IsActiveWeapon then
        if not TDMRP.IsActiveWeapon(weaponClass) and not TDMRP.IsActiveWeapon(tdmrpClass) then
            ply:ChatPrint("[TDMRP] This weapon is not available in the current loadout.")
            return
        end
    end

    -- Get price (basePrice is the Tier 1 price)
    if price <= 0 then
        ply:ChatPrint("[TDMRP] This weapon cannot be purchased.")
        return
    end

    -- Prevent buying a second copy of same class if already equipped
    if not TDMRP_CanPlayerReceiveWeaponClass(ply, tdmrpClass) then
        return
    end

    -- Money check
    local money = ply.getDarkRPVar and ply:getDarkRPVar("money") or 0
    if money < price then
        ply:ChatPrint("[TDMRP] You can't afford this weapon (" .. price .. "$).")
        return
    end

    -- Take the money
    if ply.addMoney then
        ply:addMoney(-price)
    end

    ------------------------------------------------------------------
    -- Give the TDMRP weapon directly to player's hands
    ------------------------------------------------------------------
    local wep = ply:Give(tdmrpClass)
    
    if not IsValid(wep) then
        -- Refund if failed
        if ply.addMoney then
            ply:addMoney(price)
        end
        ply:ChatPrint("[TDMRP] Failed to give weapon; refunding.")
        return
    end

    -- Set tier to 1 (Common) and re-apply mixin setup
    -- (Initialize already ran during Give, but tier was not set yet)
    wep.Tier = 1
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.Setup then
        TDMRP_WeaponMixin.Setup(wep)
    end

    -- Select the weapon
    ply:SelectWeapon(tdmrpClass)

    -- Notify player
    ply:ChatPrint("[TDMRP] Purchased " .. (meta.name or tdmrpClass) .. " for $" .. price)
    
    print(string.format("[TDMRP Shop] %s bought %s (Tier 1 Common) for $%d", 
        ply:Nick(), tdmrpClass, price))
end)

print("[TDMRP] sv_tdmrp_shop.lua loaded (weapon shop - direct give)")
