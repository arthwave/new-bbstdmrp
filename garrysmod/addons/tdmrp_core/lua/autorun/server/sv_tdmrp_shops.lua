----------------------------------------------------
-- TDMRP Shop System - Server
-- Handles ammo and weapon purchases
----------------------------------------------------

if CLIENT then return end

TDMRP = TDMRP or {}

----------------------------------------------------
-- Network Strings
----------------------------------------------------

util.AddNetworkString("TDMRP_PurchaseAmmo")
util.AddNetworkString("TDMRP_AmmoPurchased")
util.AddNetworkString("TDMRP_PurchaseWeapon")
util.AddNetworkString("TDMRP_WeaponPurchased")
util.AddNetworkString("TDMRP_HitMarker")

----------------------------------------------------
-- Ammo Purchase Handler
----------------------------------------------------

net.Receive("TDMRP_PurchaseAmmo", function(len, ply)
    if not IsValid(ply) then return end
    
    local ammoType = net.ReadString()
    local ammoConfig = TDMRP.GetAmmoConfig(ammoType)
    
    if not ammoConfig then
        ply:ChatPrint("[TDMRP] Invalid ammo type!")
        return
    end
    
    local price = ammoConfig.price
    local amount = ammoConfig.amount
    local money = ply:getDarkRPVar("money") or 0
    
    if money < price then
        ply:ChatPrint("[TDMRP] You can't afford this ammo!")
        return
    end
    
    -- Deduct money
    ply:addMoney(-price)
    
    -- Give ammo
    ply:GiveAmmo(amount, ammoType, true)
    
    -- Notify client
    net.Start("TDMRP_AmmoPurchased")
        net.WriteString(ammoType)
        net.WriteInt(amount, 16)
    net.Send(ply)
    
    print("[TDMRP Shops] " .. ply:Nick() .. " purchased " .. amount .. " " .. ammoType .. " ammo for $" .. price)
end)

----------------------------------------------------
-- Weapon Purchase Handler
----------------------------------------------------

net.Receive("TDMRP_PurchaseWeapon", function(len, ply)
    if not IsValid(ply) then return end
    
    local weaponClass = net.ReadString()
    local tier = net.ReadInt(8)
    
    -- Validate weapon
    local meta = TDMRP.GetM9KMeta(weaponClass)
    if not meta then
        ply:ChatPrint("[TDMRP] Invalid weapon!")
        return
    end
    
    -- Validate tier
    tier = math.Clamp(tier, 1, 5)
    
    -- Calculate price
    local price = TDMRP.GetWeaponPrice(weaponClass, tier)
    local money = ply:getDarkRPVar("money") or 0
    
    if money < price then
        ply:ChatPrint("[TDMRP] You can't afford this weapon!")
        return
    end
    
    -- Check if player already has this weapon class
    for _, wep in ipairs(ply:GetWeapons()) do
        if wep:GetClass() == weaponClass then
            ply:ChatPrint("[TDMRP] You already have this weapon!")
            return
        end
    end
    
    -- Deduct money
    ply:addMoney(-price)
    
    -- Give weapon with tier
    local wep, instance = TDMRP.GiveM9KWeapon(ply, weaponClass, tier, false, {})
    
    if not IsValid(wep) then
        -- Refund if weapon creation failed
        ply:addMoney(price)
        ply:ChatPrint("[TDMRP] Failed to create weapon!")
        return
    end
    
    -- Notify client
    net.Start("TDMRP_WeaponPurchased")
        net.WriteString(weaponClass)
        net.WriteInt(tier, 8)
        net.WriteInt(price, 32)
    net.Send(ply)
    
    print("[TDMRP Shops] " .. ply:Nick() .. " purchased " .. meta.name .. " T" .. tier .. " for $" .. price)
end)

----------------------------------------------------
-- Hit Marker System
----------------------------------------------------

hook.Add("EntityTakeDamage", "TDMRP_SendHitMarker", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not IsValid(target) then return end
    
    -- Only send for player targets or NPCs
    if not target:IsPlayer() and not target:IsNPC() then return end
    
    -- Check if attacker is using M9K weapon
    local wep = attacker:GetActiveWeapon()
    if not IsValid(wep) or not TDMRP.IsM9KWeapon(wep) then return end
    
    -- Send hit marker
    net.Start("TDMRP_HitMarker")
    net.Send(attacker)
end)

----------------------------------------------------
-- Admin Commands
----------------------------------------------------

-- Give weapon command
concommand.Add("tdmrp_giveweapon", function(ply, cmd, args)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then
        ply:ChatPrint("[TDMRP] Admin only command!")
        return
    end
    
    if #args < 1 then
        ply:ChatPrint("[TDMRP] Usage: tdmrp_giveweapon <weapon_class> [tier] [crafted]")
        return
    end
    
    local weaponClass = args[1]
    local tier = tonumber(args[2]) or 1
    local crafted = args[3] == "true" or args[3] == "1"
    
    local meta = TDMRP.GetM9KMeta(weaponClass)
    if not meta then
        ply:ChatPrint("[TDMRP] Unknown weapon: " .. weaponClass)
        return
    end
    
    local wep, instance = TDMRP.GiveM9KWeapon(ply, weaponClass, tier, crafted, {})
    
    if IsValid(wep) then
        ply:ChatPrint("[TDMRP] Given: " .. meta.name .. " T" .. tier .. (crafted and " ★" or ""))
    else
        ply:ChatPrint("[TDMRP] Failed to give weapon!")
    end
end)

-- List weapons command
concommand.Add("tdmrp_listweapons", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    ply:ChatPrint("[TDMRP] Available M9K Weapons:")
    
    local weaponsByType = {}
    for class, meta in pairs(TDMRP.M9KRegistry) do
        weaponsByType[meta.type] = weaponsByType[meta.type] or {}
        table.insert(weaponsByType[meta.type], { class = class, name = meta.name })
    end
    
    for weaponType, weapons in pairs(weaponsByType) do
        ply:ChatPrint("  " .. string.upper(weaponType) .. ":")
        for _, wep in ipairs(weapons) do
            ply:ChatPrint("    - " .. wep.class .. " (" .. wep.name .. ")")
        end
    end
end)

-- NOTE: tdmrp_settier command is defined in sv_tdmrp_debug.lua
-- Removed duplicate legacy version that used TDMRP.ApplyM9KInstance (no longer exists)

print("[TDMRP] sv_tdmrp_shops.lua loaded - Shop system initialized")
