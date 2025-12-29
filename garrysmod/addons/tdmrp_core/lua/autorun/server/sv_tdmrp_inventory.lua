-- sv_tdmrp_inventory.lua
-- Basic TDMRP per-player inventory + net API for UI
-- Version 2.0: Enhanced with crash-safety, validation, and normalization

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.Inventory = TDMRP.Inventory or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

local CONFIG = {
    MAX_SLOTS = 30,                    -- Maximum inventory slots
    WEAPON_DESPAWN_TIME = 300,         -- 5 minutes world weapon cleanup
    INVENTORY_WARNING_PERCENT = 80,    -- Warn at 80% capacity
    DATA_VERSION = 1,                  -- Inventory format version
}

local INV_DIR = "tdmrp/inv"
local INV_BACKUP_DIR = "tdmrp/inv_backups"

----------------------------------------
-- Filesystem helpers
----------------------------------------
local function EnsureInvDir()
    if not file.IsDir("tdmrp", "DATA") then
        file.CreateDir("tdmrp")
    end
    if not file.IsDir(INV_DIR, "DATA") then
        file.CreateDir(INV_DIR)
    end
    if not file.IsDir(INV_BACKUP_DIR, "DATA") then
        file.CreateDir(INV_BACKUP_DIR)
    end
end

EnsureInvDir()

local function InvFileName(steamID64)
    return string.format("%s/%s.txt", INV_DIR, steamID64)
end

local function BackupFileName(steamID64, timestamp)
    return string.format("%s/%s_%d.txt", INV_BACKUP_DIR, steamID64, timestamp or os.time())
end

----------------------------------------
-- Bind time validator (ensures relative seconds for JSON storage)
----------------------------------------
local function ValidateAndFixBindTime(item)
    if not item or item.kind ~= "weapon" then return end
    
    local bound = item.bound_until or 0
    if bound == 0 then return end
    
    -- CRITICAL: Inventory JSON must store bound_until as RELATIVE REMAINING SECONDS
    -- This FREEZES the timer while the weapon is in inventory
    -- DO NOT convert to absolute unix timestamps - that causes 10:32 → 32151209 corruption
    
    -- If bound_until is a huge number (> 30 days or looks like unix timestamp), it's corrupted
    -- Reset it
    local MAX_BIND_SECONDS = 2592000  -- 30 days
    if bound > MAX_BIND_SECONDS then
        print(string.format("[TDMRP] ValidateAndFixBindTime: Detected corrupted bind_until=%.0f. Resetting to 0", bound))
        item.bound_until = 0
        return
    end
    
    -- Otherwise trust the stored relative seconds value - it's frozen in inventory
end


----------------------------------------
-- Validation Helpers
----------------------------------------

-- Validate weapon class exists in game
local function ValidateWeaponClass(class)
    if not class or class == "" then
        return false, "Invalid class (empty)"
    end
    if not weapons.GetStored(class) then
        return false, "Weapon class not registered: " .. class
    end
    return true
end

-- Get inventory fill percentage
local function GetInventoryFillPercent(inv)
    if not inv or not inv.items then return 0 end
    local count = 0
    for _, itm in pairs(inv.items) do
        if itm.kind == "weapon" then
            count = count + 1
        end
    end
    return math.floor((count / CONFIG.MAX_SLOTS) * 100)
end

-- Check if inventory is nearly full and warn
local function CheckInventoryCapacity(ply, inv)
    local percent = GetInventoryFillPercent(inv)
    if percent >= CONFIG.INVENTORY_WARNING_PERCENT then
        local count = 0
        for _, itm in pairs(inv.items) do
            if itm.kind == "weapon" then count = count + 1 end
        end
        ply:ChatPrint(string.format("[TDMRP] Inventory at %d%% capacity (%d/%d slots)", percent, count, CONFIG.MAX_SLOTS))
    end
end

----------------------------------------
-- Core inventory: load/save/access
----------------------------------------
function TDMRP_GetInventory(ply)
    if not IsValid(ply) or not ply.SteamID64 then return nil end

    local sid = ply:SteamID64()
    TDMRP.Inventory[sid] = TDMRP.Inventory[sid] or {
        version    = CONFIG.DATA_VERSION,
        nextItemID = 1,
        items      = {}
    }
    return TDMRP.Inventory[sid]
end

function TDMRP_LoadInventory(ply)
    if not IsValid(ply) or not ply.SteamID64 then return end

    local sid  = ply:SteamID64()
    local path = InvFileName(sid)

    if not file.Exists(path, "DATA") then
        TDMRP.Inventory[sid] = {
            version    = CONFIG.DATA_VERSION,
            nextItemID = 1,
            items      = {}
        }
        return
    end

    local raw = file.Read(path, "DATA")
    if not raw or raw == "" then
        TDMRP.Inventory[sid] = {
            version    = CONFIG.DATA_VERSION,
            nextItemID = 1,
            items      = {}
        }
        return
    end

    local ok, data = pcall(util.JSONToTable, raw)
    if not ok or type(data) ~= "table" then
        -- CORRUPTION RECOVERY: Backup and reset
        print(string.format("[TDMRP] CORRUPTED INVENTORY for %s - backing up and resetting", sid))
        
        -- Create backup of corrupted data
        local backupPath = BackupFileName(sid)
        file.Write(backupPath, raw)
        print(string.format("[TDMRP] Corrupted data backed up to: %s", backupPath))
        
        -- Notify player
        if IsValid(ply) then
            ply:ChatPrint("[TDMRP] Your inventory was corrupted and has been reset. Admins have been notified.")
        end
        
        TDMRP.Inventory[sid] = {
            version    = CONFIG.DATA_VERSION,
            nextItemID = 1,
            items      = {}
        }
        return
    end

    -- Migrate old format if needed
    data.version    = data.version or 1
    data.nextItemID = data.nextItemID or 1
    data.items      = data.items or {}
    
    -- CRITICAL: Validate and fix all bind times in loaded inventory
    for itemID, item in pairs(data.items) do
        ValidateAndFixBindTime(item)
    end

    TDMRP.Inventory[sid] = data
    print("[TDMRP] Loaded inventory for", ply:Nick(), sid, "#items=", table.Count(data.items))
end

function TDMRP_SaveInventory(ply)
    if not IsValid(ply) or not ply.SteamID64 then return false end

    local sid = ply:SteamID64()
    local inv = TDMRP.Inventory[sid]
    if not inv then return false end

    -- Ensure version is set
    inv.version = inv.version or CONFIG.DATA_VERSION

    local path = InvFileName(sid)
    
    -- Safe save with pcall
    local ok, err = pcall(function()
        local json = util.TableToJSON(inv, true)
        file.Write(path, json)
    end)
    
    if not ok then
        print(string.format("[TDMRP] ERROR: Failed to save inventory for %s: %s", sid, tostring(err)))
        return false
    end
    
    return true
end

hook.Add("PlayerInitialSpawn", "TDMRP_LoadInventory", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            TDMRP_LoadInventory(ply)
        end
    end)
end)

hook.Add("PlayerDisconnected", "TDMRP_SaveInventory", function(ply)
    TDMRP_SaveInventory(ply)
end)

hook.Add("ShutDown", "TDMRP_SaveAllInventories", function()
    for _, ply in ipairs(player.GetAll()) do
        TDMRP_SaveInventory(ply)
    end
end)

----------------------------------------
-- Add / remove items
----------------------------------------
function TDMRP_AddItem(ply, itemData)
    local inv = TDMRP_GetInventory(ply)
    if not inv then return nil end

    -- Stackable kinds
    if itemData.kind == "gem" or itemData.kind == "scrap" then
        local key = itemData.kind == "gem" and itemData.gem or "scrap"

        for _, itm in pairs(inv.items) do
            if itm.kind == itemData.kind then
                if itm.kind == "gem" and itm.gem == key then
                    itm.amount = (itm.amount or 0) + (itemData.amount or 1)
                    return itm.id
                elseif itm.kind == "scrap" then
                    itm.amount = (itm.amount or 0) + (itemData.amount or 1)
                    return itm.id
                end
            end
        end
    end

    local id = inv.nextItemID or 1
    inv.nextItemID = id + 1

    itemData.id = id
    inv.items[id] = itemData

    return id
end

function TDMRP_RemoveItem(ply, itemID, amount)
    local inv = TDMRP_GetInventory(ply)
    if not inv then return false end

    local itm = inv.items[itemID]
    if not itm then return false end

    amount = amount or 1

    if itm.kind == "gem" or itm.kind == "scrap" then
        itm.amount = (itm.amount or 1) - amount
        if itm.amount <= 0 then
            inv.items[itemID] = nil
        end
    else
        inv.items[itemID] = nil
    end

    return true
end

-- Convenience for scrap + gems
function TDMRP_AddScrap(ply, amount)
    amount = amount or 1
    if amount <= 0 then return end

    return TDMRP_AddItem(ply, {
        kind   = "scrap",
        amount = amount
    })
end

function TDMRP_AddGem(ply, gemID, amount)
    amount = amount or 1
    if not gemID or amount <= 0 then return end

    return TDMRP_AddItem(ply, {
        kind   = "gem",
        gem    = gemID,
        amount = amount
    })
end

----------------------------------------
-- Store current weapon (debug / optional)
----------------------------------------
local DefaultWeaponBlacklist = {
    ["weapon_physgun"]    = true,
    ["weapon_physcannon"] = true,
    ["gmod_tool"]         = true,
    ["gmod_camera"]       = true,
    ["keys"]              = true,
    ["pocket"]            = true,
    ["weapon_fists"]      = true
}

function TDMRP_IsStoreForbidden(class)
    -- Block tools / utility stuff only
    if DefaultWeaponBlacklist[class] then
        return true
    end

    -- Allow everything else for now (including HL2 / CS:S / Bobs SWEPs)
    return false
end

local function StoreCurrentWeapon(ply)
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or not wep:IsWeapon() then
        ply:ChatPrint("[TDMRP] No valid weapon in hands to store.")
        return
    end

    local class = wep:GetClass()
    if TDMRP_IsStoreForbidden(class) then
        ply:ChatPrint("[TDMRP] You cannot store this weapon.")
        return
    end

        -- Build a full instance description from the gun we’re holding
    local inst, err = TDMRP_BuildInstanceFromSWEP(ply, wep)
    if not inst then
        ply:ChatPrint("[TDMRP] This weapon cannot be stored: " .. tostring(err or "unknown error"))
        return
    end

    -- Turn that instance into an inventory item skeleton
    local item = TDMRP_InstanceToItem(inst)
    if not item then
        ply:ChatPrint("[TDMRP] Failed to convert weapon to inventory item.")
        return
    end
    
    if item.cosmetic and item.cosmetic.name ~= "" then
        print(string.format("[TDMRP] Stored weapon with custom name: '%s'", item.cosmetic.name))
    end

    -- DEBUG: Log bind status when storing
    if inst.bound_until and inst.bound_until > 0 then
        print(string.format("[TDMRP] Stored weapon with bind timer: %.1f seconds (instance=%s, item=%s)", 
            inst.bound_until, inst.bound_until or "nil", item.bound_until or "nil"))
    else
        print("[TDMRP] Stored weapon has NO bind timer in instance")
    end


    local id = TDMRP_AddItem(ply, item)
    if id then
        ply:StripWeapon(class)
        ply:ChatPrint(string.format("[TDMRP] Stored weapon: %s.", class, id))
        TDMRP_SaveInventory(ply)
    else
        ply:ChatPrint("[TDMRP] Failed to store weapon.")
    end
end
----------------------------------------
-- Helper: Equip weapon from inventory item
----------------------------------------
function TDMRP_GiveInventoryWeapon(ply, item)
    if not IsValid(ply) or not item or item.kind ~= "weapon" then return end
    
    local class = item.class
    if not class or class == "" or not weapons.GetStored(class) then
        if IsValid(ply) then
            ply:ChatPrint("[TDMRP] Invalid weapon class: " .. tostring(class))
        end
        return
    end
    
    -- Convert item to instance
    local inst = nil
    if TDMRP.ItemToInstance then
        inst = TDMRP.ItemToInstance(item)
    end
    
    -- DEBUG: Log what was read from item
    if inst then
        if inst.cosmetic and inst.cosmetic.name ~= "" then
            print(string.format("[TDMRP] Retrieving weapon with custom name: '%s'", inst.cosmetic.name))
        else
            print("[TDMRP] Retrieved weapon has NO custom name")
        end
        
        if inst.bound_until and inst.bound_until > 0 then
            print(string.format("[TDMRP] Retrieving weapon with bind timer: %.1f seconds", inst.bound_until))
        else
            print("[TDMRP] Retrieved weapon has NO bind timer")
        end
    end
    
    -- Give weapon
    local wep = ply:Give(class)
    if not IsValid(wep) then
        ply:ChatPrint("[TDMRP] Failed to equip weapon " .. tostring(class) .. ".")
        return
    end
    
    -- Apply full instance data (stats, cosmetics, bind time, etc.)
    if inst and TDMRP.ApplyInstanceToSWEP then
        TDMRP.ApplyInstanceToSWEP(wep, inst)
    end
    
    ply:SelectWeapon(class)
end
concommand.Add("tdmrp_store_current", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    StoreCurrentWeapon(ply)
end)

concommand.Add("tdmrp_list_inventory", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local inv = TDMRP_GetInventory(ply)
    if not inv then
        ply:ChatPrint("[TDMRP] No inventory loaded.")
        return
    end

    ply:ChatPrint("[TDMRP] Inventory contents:")
    for id, itm in pairs(inv.items) do
        if itm.kind == "weapon" then
            ply:ChatPrint(string.format("  #%d weapon: %s (Tier %d)", id, itm.class, itm.tier or 1))
        elseif itm.kind == "gem" then
            ply:ChatPrint(string.format("  #%d gem: %s x%d", id, itm.gem or "unknown", itm.amount or 1))
        elseif itm.kind == "scrap" then
            ply:ChatPrint(string.format("  #%d scrap x%d", id, itm.amount or 1))
        else
            ply:ChatPrint(string.format("  #%d %s", id, itm.kind or "unknown"))
        end
    end
end)

----------------------------------------
-- Net: Inventory UI support
----------------------------------------
util.AddNetworkString("TDMRP_Inventory_Request")
util.AddNetworkString("TDMRP_Inventory_Data")
util.AddNetworkString("TDMRP_Inventory_UseItem")
util.AddNetworkString("TDMRP_Inventory_DropItem")

local function TDMRP_SendInventory(ply)
    local inv = TDMRP_GetInventory(ply)
    if not inv then 
        print("[TDMRP] No inventory for " .. ply:GetName())
        return 
    end

    local list = {}
    for id, itm in pairs(inv.items) do
        local copy = table.Copy(itm)
        copy.id = id
        table.insert(list, copy)
        
        -- Debug gem items
        if itm.kind == "gem" then
            print(string.format("[TDMRP] Found gem: id=%s, gem=%s, amount=%d", id, itm.gem or "nil", itm.amount or 1))
        end
    end

    print("[TDMRP] Sending " .. #list .. " items to " .. ply:GetName())
    net.Start("TDMRP_Inventory_Data")
    net.WriteTable(list)
    net.Send(ply)
end

net.Receive("TDMRP_Inventory_Request", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then 
        print("[TDMRP] Inventory request from invalid player")
        return 
    end
    print("[TDMRP] Sending inventory to " .. ply:GetName())
    TDMRP_SendInventory(ply)
end)

-- Helper to give weapon from inventory (equips but does NOT remove)
-- Helper to give weapon from inventory (equips but does NOT remove)
local function TDMRP_GiveInventoryWeapon(ply, item)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not item or item.kind ~= "weapon" then return end

    local class = item.class
    if not class or class == "" then return end

    -- Still enforce: no duplicate of the same weapon class in hands
    if ply:HasWeapon(class) then
        ply:ChatPrint("[TDMRP] You already have this weapon equipped. Store or drop it first.")
        return
    end

    -- Convert item to instance BEFORE Give() so we can set it as pending
    local inst = nil
    if TDMRP_ItemToInstance then
        inst = TDMRP_ItemToInstance(item)
    end
    
    -- Set pending instance BEFORE Give() - this allows Setup() to apply it
    -- before Equip() can reset the tier
    if inst and TDMRP.SetPendingInstance then
        TDMRP.SetPendingInstance(ply, class, inst)
    end

    -- Give a fresh SWEP of this class
    local wep = ply:Give(class)
    if not IsValid(wep) then
        ply:ChatPrint("[TDMRP] Failed to equip weapon " .. tostring(class) .. ".")
        return
    end

    -- Apply full instance data (stats, cosmetics, bind time, etc.) after Give()
    -- The tier is already locked from pending instance
    if inst and TDMRP.ApplyInstanceToSWEP then
        TDMRP.ApplyInstanceToSWEP(wep, inst)
        -- Verify bind time was restored
        if inst.bound_until and inst.bound_until > 0 then
            local remaining = wep:GetNWFloat("TDMRP_BindExpire", 0) - CurTime()
            print(string.format("[TDMRP Inventory] GiveInventoryWeapon restored bind: %.1f seconds remaining", remaining))
        end
    elseif not inst then
        -- Fallback to legacy direct NW copying (just in case)
        wep:SetNWInt("TDMRP_Tier", item.tier or 1)

        if item.stats then
            for k, v in pairs(item.stats) do
                local key = "TDMRP_" .. string.upper(k)
                if isnumber(v) then
                    wep:SetNWInt(key, v)
                end
            end
        end

        if item.cosmetic then
            if item.cosmetic.name and item.cosmetic.name ~= "" then
                wep:SetNWString("TDMRP_CustomName", item.cosmetic.name)
            end
            if item.cosmetic.material and item.cosmetic.material ~= "" then
                wep:SetNWString("TDMRP_Material", item.cosmetic.material)
            end
        end

        -- Restore bind time if weapon is bound
        if item.bound_until and item.bound_until > 0 then
            local newExpire = CurTime() + item.bound_until
            wep:SetNWFloat("TDMRP_BindExpire", newExpire)
            wep:SetNWFloat("TDMRP_BindUntil", item.bound_until)
            print(string.format("[TDMRP Inventory] Restored bind timer: %.1f seconds remaining", item.bound_until))
        else
            wep:SetNWFloat("TDMRP_BindUntil", 0)
            wep:SetNWFloat("TDMRP_BindExpire", 0)
        end
    end

    ply:SelectWeapon(class)
end



net.Receive("TDMRP_Inventory_UseItem", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local itemID = net.ReadUInt(16)
    local inv = TDMRP_GetInventory(ply)
    if not inv then return end

    local item = inv.items[itemID]
    if not item then return end

    if item.kind == "weapon" then
        -- Equip weapon (keep it in inventory; drop is how you get rid of it)
        TDMRP_GiveInventoryWeapon(ply, item)

    elseif item.kind == "gem" then
        -- TODO: hook into real gem logic
        hook.Run("TDMRP_UseGem", ply, item.gem, itemID, item)
        ply:ChatPrint("[TDMRP] Using gem logic is not fully implemented yet.")
        -- When implemented, remember to consume from inventory:
        -- TDMRP_RemoveItem(ply, itemID, 1)

    elseif item.kind == "scrap" then
        -- Placeholder: scrap is mostly for crafting, not "use" directly
        ply:ChatPrint("[TDMRP] Scrap is used for crafting; no direct use yet.")

    else
        hook.Run("TDMRP_UseMisc", ply, itemID, item)
        ply:ChatPrint("[TDMRP] Using this item type is not implemented yet.")
    end

    TDMRP_SaveInventory(ply)
    TDMRP_SendInventory(ply)
end)

net.Receive("TDMRP_Inventory_DropItem", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local itemID = net.ReadUInt(16)
    local inv = TDMRP_GetInventory(ply)
    if not inv then return end

    local item = inv.items[itemID]
    if not item then return end

    local forward  = ply:GetAimVector()
    local spawnPos = ply:EyePos() + forward * 40

    if item.kind == "weapon" then
        local class = item.class
        if class and weapons.GetStored(class) then
            local ent = ents.Create(class)
            if IsValid(ent) then
                ent:SetPos(spawnPos)
                ent:Spawn()

                -- Convert item back to instance and apply to dropped weapon
                if TDMRP.ItemToInstance and TDMRP.ApplyInstanceToSWEP then
                    local inst = TDMRP.ItemToInstance(item)
                    if inst then
                        TDMRP.ApplyInstanceToSWEP(ent, inst)
                        ent.TDMRP_InstanceID = inst.id
                    end
                end

                -- Mark for E-key pickup with 5-second owner lock
                ent.TDMRP_RequireUse = true
                ent.TDMRP_DroppedBy = ply
                ent.TDMRP_DropTime = CurTime()
                ent.TDMRP_OwnerSteamID = ply:SteamID64()

                local phys = ent:GetPhysicsObject()
                if IsValid(phys) then
                    phys:Wake()
                    phys:SetVelocity(forward * 200)
                end
            end

            -- Remove from inventory now that it's a world item
            TDMRP_RemoveItem(ply, itemID, 1)
            
            local displayName = (item.cosmetic and item.cosmetic.name ~= "" and item.cosmetic.name) or class
            ply:ChatPrint(string.format("[TDMRP] Dropped weapon: %s (5 sec exclusive pickup)", displayName))
        end

    elseif item.kind == "gem" then
        ply:ChatPrint("[TDMRP] Dropping gems into the world is not implemented yet.")

    elseif item.kind == "scrap" then
        ply:ChatPrint("[TDMRP] Dropping scrap into the world is not implemented yet.")

    else
        ply:ChatPrint("[TDMRP] Dropping this item type is not implemented yet.")
    end

    TDMRP_SaveInventory(ply)
    TDMRP_SendInventory(ply)
end)

----------------------------------------
-- NEW: Network strings for new F4 menu inventory tab
----------------------------------------
util.AddNetworkString("TDMRP_RequestInventory")
util.AddNetworkString("TDMRP_InventoryData")
util.AddNetworkString("TDMRP_InventoryUpdate")
util.AddNetworkString("TDMRP_InventoryEquip")
util.AddNetworkString("TDMRP_InventoryDrop")
util.AddNetworkString("TDMRP_InventoryStore")
util.AddNetworkString("TDMRP_CraftUpgrade")
util.AddNetworkString("TDMRP_CraftGem")
util.AddNetworkString("TDMRP_CraftSalvage")
util.AddNetworkString("TDMRP_CraftResult")

----------------------------------------
-- NEW: Slot-to-ID Mapping System
-- Client uses slots (1-30), server stores by ID
-- This mapping ensures consistency
----------------------------------------

-- Build slot-to-ID map from inventory (weapons only)
local function BuildSlotMap(inv)
    if not inv or not inv.items then return {}, {} end
    
    local slotToID = {}  -- slot (1-30) -> item ID
    local idToSlot = {}  -- item ID -> slot (1-30)
    local slot = 1
    
    -- Consistent ordering: sort by ID for deterministic slot assignment
    local sortedIDs = {}
    for id, itm in pairs(inv.items) do
        if itm.kind == "weapon" then
            table.insert(sortedIDs, id)
        end
    end
    table.sort(sortedIDs)
    
    for _, id in ipairs(sortedIDs) do
        if slot <= CONFIG.MAX_SLOTS then
            slotToID[slot] = id
            idToSlot[id] = slot
            slot = slot + 1
        end
    end
    
    return slotToID, idToSlot
end

-- Get item ID from slot number
local function GetItemIDFromSlot(ply, slot)
    local inv = TDMRP_GetInventory(ply)
    if not inv then return nil end
    
    local slotToID, _ = BuildSlotMap(inv)
    return slotToID[slot]
end

----------------------------------------
-- NEW: Crafting Configuration
----------------------------------------
local CraftConfig = {
    upgradeCosts = {
        [2] = 5000,
        [3] = 15000,
        [4] = 40000,
        [5] = 100000,
    },
    craftChance = {
        [2] = 0.95,
        [3] = 0.85,
        [4] = 0.70,
        [5] = 0.50,
    },
    gemCosts = {
        sapphire = 25000,
        emerald = 30000,
        ruby = 50000,
        diamond = 100000,
    },
}

----------------------------------------
-- NEW: New inventory format sender (for cl_tdmrp_f4_inventory.lua)
-- Must be declared before net.Receive that calls it
-- Uses slot-based format for consistency
----------------------------------------
local function SendNewInventoryFormat(ply)
    if not IsValid(ply) then return end
    
    local inv = TDMRP_GetInventory(ply)
    if not inv then return end
    
    -- Build slot map for consistent ordering
    local slotToID, _ = BuildSlotMap(inv)
    
    -- Build weapon items in slot order
    local weaponItems = {}
    
    for slot, id in pairs(slotToID) do
        local itm = inv.items[id]
        if itm and itm.kind == "weapon" then
            -- CRITICAL: bound_until in JSON is ALREADY remaining seconds (frozen in inventory)
            -- Send it directly without recalculation
            -- This ensures bind time doesn't decay while weapon is stored
            local bound_until = itm.bound_until or 0
            
            -- Debug: log if weapon has bind time
            if bound_until > 0 then
                print(string.format("[TDMRP] SendNewInventoryFormat: Slot %d - %s has bind time: %.1f seconds remaining (frozen)", slot, itm.class, bound_until))
            end
            
            weaponItems[slot] = {
                id = id,
                class = itm.class or "",
                tier = itm.tier or 1,
                crafted = (itm.craft and itm.craft.crafted) or false,
                prefixId = (itm.craft and itm.craft.prefixId) or "",
                suffixId = (itm.craft and itm.craft.suffixId) or "",
                gems = itm.gems or { sapphire = 0, emerald = 0, ruby = 0, diamond = 0, amethyst = 0 },
                stats = itm.stats or { damage = 25, rpm = 600, accuracy = 1, recoil = 1, handling = 100 },
                bound_until = bound_until,
                cosmetic = itm.cosmetic or { name = "", material = "" },
            }
            
            if itm.cosmetic and itm.cosmetic.name ~= "" then
                print(string.format("[TDMRP] SendNewInventoryFormat: Slot %d sending custom name '%s'", slot, itm.cosmetic.name))
            end
        end
    end
    
    local count = table.Count(weaponItems)
    
    net.Start("TDMRP_InventoryData")
        net.WriteInt(count, 16)
        
        for slot, item in pairs(weaponItems) do
            net.WriteInt(slot, 8)
            net.WriteInt(item.id or 0, 32)
            net.WriteString(item.class or "")
            net.WriteInt(item.tier or 1, 8)
            net.WriteBool(item.crafted or false)
            net.WriteString(item.prefixId or "")
            net.WriteString(item.suffixId or "")
            net.WriteInt(item.gems and item.gems.sapphire or 0, 8)
            net.WriteInt(item.gems and item.gems.emerald or 0, 8)
            net.WriteInt(item.gems and item.gems.ruby or 0, 8)
            net.WriteInt(item.gems and item.gems.diamond or 0, 8)
            net.WriteInt(item.gems and item.gems.amethyst or 0, 8)
            net.WriteInt(item.stats and item.stats.damage or 25, 16)
            net.WriteInt(item.stats and item.stats.rpm or 600, 16)
            net.WriteFloat(item.stats and item.stats.accuracy or 1)
            net.WriteFloat(item.stats and item.stats.recoil or 1)
            net.WriteInt(item.stats and item.stats.handling or 100, 16)
            net.WriteFloat(item.bound_until or 0)
            net.WriteString(item.cosmetic and item.cosmetic.name or "")
        end
    net.Send(ply)
    
    -- Check and warn about inventory capacity
    CheckInventoryCapacity(ply, inv)
end

----------------------------------------
-- NEW: Alias for new inventory request
----------------------------------------
net.Receive("TDMRP_RequestInventory", function(_, ply)
    if not IsValid(ply) then return end
    SendNewInventoryFormat(ply)
end)

----------------------------------------
-- NEW: Equip from new inventory UI
-- Uses slot-to-ID mapping for correct item lookup
----------------------------------------
net.Receive("TDMRP_InventoryEquip", function(_, ply)
    local slot = net.ReadInt(8)
    if not IsValid(ply) then return end
    
    local inv = TDMRP_GetInventory(ply)
    if not inv then return end
    
    -- Use slot-to-ID mapping for correct lookup
    local targetItemID = GetItemIDFromSlot(ply, slot)
    if not targetItemID then
        ply:ChatPrint("[TDMRP] No weapon in that slot!")
        return
    end
    
    local targetItem = inv.items[targetItemID]
    if not targetItem or targetItem.kind ~= "weapon" then
        ply:ChatPrint("[TDMRP] Invalid item in slot!")
        return
    end
    
    -- VALIDATION: Check weapon class exists
    local valid, reason = ValidateWeaponClass(targetItem.class)
    if not valid then
        ply:ChatPrint("[TDMRP] Cannot equip: " .. (reason or "unknown error"))
        print(string.format("[TDMRP] Invalid weapon class in inventory: %s for %s", targetItem.class, ply:Nick()))
        return
    end
    
    -- CRASH SAFETY: Save before modification
    TDMRP_SaveInventory(ply)
    
    -- Use existing equip logic (wrapped in pcall)
    local ok, err = pcall(function()
        TDMRP_GiveInventoryWeapon(ply, targetItem)
        TDMRP_RemoveItem(ply, targetItemID, 1)
    end)
    
    if not ok then
        print(string.format("[TDMRP] ERROR during equip for %s: %s", ply:Nick(), tostring(err)))
        ply:ChatPrint("[TDMRP] Error equipping weapon. Please try again.")
    end
    
    -- Save after modification
    TDMRP_SaveInventory(ply)
    SendNewInventoryFormat(ply)
end)

----------------------------------------
-- NEW: Drop from new inventory UI (with 5-sec owner lock + despawn timer)
-- Uses slot-to-ID mapping for correct item lookup
----------------------------------------
net.Receive("TDMRP_InventoryDrop", function(_, ply)
    local slot = net.ReadInt(8)
    if not IsValid(ply) then return end
    
    local inv = TDMRP_GetInventory(ply)
    if not inv then return end
    
    -- Use slot-to-ID mapping for correct lookup
    local targetItemID = GetItemIDFromSlot(ply, slot)
    if not targetItemID then
        ply:ChatPrint("[TDMRP] No weapon in that slot!")
        return
    end
    
    local targetItem = inv.items[targetItemID]
    if not targetItem or targetItem.kind ~= "weapon" then
        ply:ChatPrint("[TDMRP] Invalid item in slot!")
        return
    end
    
    -- VALIDATION: Check weapon class exists
    local valid, reason = ValidateWeaponClass(targetItem.class)
    if not valid then
        ply:ChatPrint("[TDMRP] Cannot drop: " .. (reason or "invalid weapon"))
        return
    end
    
    -- Check if weapon is bound - prevent drop if bound
    -- bound_until stores REMAINING seconds, not absolute timestamp
    if targetItem.bound_until and targetItem.bound_until > 0 then
        local remaining = targetItem.bound_until
        local mins = math.floor(remaining / 60)
        local secs = math.floor(remaining % 60)
        ply:ChatPrint("[TDMRP] Cannot drop bound weapon! Unbind it first using Blood Ruby (" .. string.format("%02d:%02d", mins, secs) .. " remaining)")
        return
    end
    
    -- CRASH SAFETY: Save before modification
    TDMRP_SaveInventory(ply)
    
    -- Spawn weapon in world (wrapped in pcall)
    local ok, err = pcall(function()
        local forward = ply:GetAimVector()
        local spawnPos = ply:EyePos() + forward * 50
        local class = targetItem.class
        
        if class and weapons.GetStored(class) then
            local ent = ents.Create(class)
            if IsValid(ent) then
                ent:SetPos(spawnPos)
                ent:Spawn()
                
                -- Convert item to instance and apply to dropped weapon
                if TDMRP.ItemToInstance and TDMRP.ApplyInstanceToSWEP then
                    local inst = TDMRP.ItemToInstance(targetItem)
                    if inst then
                        TDMRP.ApplyInstanceToSWEP(ent, inst)
                        ent.TDMRP_InstanceID = inst.id
                    end
                end
                
                -- Mark for E-key pickup with 5-second owner lock
                ent.TDMRP_RequireUse = true
                ent.TDMRP_DroppedBy = ply
                ent.TDMRP_DropTime = CurTime()
                ent.TDMRP_OwnerSteamID = ply:SteamID64()
                
                -- DESPAWN TIMER: Remove world weapon after 5 minutes if not picked up
                ent.TDMRP_DespawnTime = CurTime() + CONFIG.WEAPON_DESPAWN_TIME
                timer.Simple(CONFIG.WEAPON_DESPAWN_TIME, function()
                    if IsValid(ent) and ent.TDMRP_DespawnTime then
                        print(string.format("[TDMRP] Despawning unclaimed weapon: %s", class))
                        ent:Remove()
                    end
                end)
                
                local phys = ent:GetPhysicsObject()
                if IsValid(phys) then
                    phys:Wake()
                    phys:SetVelocity(forward * 200)
                end
            end
        end
        
        TDMRP_RemoveItem(ply, targetItemID, 1)
    end)
    
    if not ok then
        print(string.format("[TDMRP] ERROR during drop for %s: %s", ply:Nick(), tostring(err)))
        ply:ChatPrint("[TDMRP] Error dropping weapon. Please try again.")
    end
    
    TDMRP_SaveInventory(ply)
    SendNewInventoryFormat(ply)
    
    local displayName = (targetItem.cosmetic and targetItem.cosmetic.name ~= "") and targetItem.cosmetic.name or (targetItem.class or "unknown")
    ply:ChatPrint("[TDMRP] Dropped weapon: " .. displayName .. " (5 sec exclusive pickup, despawns in 5 min)")
end)

----------------------------------------
-- NEW: Store current weapon from UI
----------------------------------------
net.Receive("TDMRP_InventoryStore", function(_, ply)
    if not IsValid(ply) then return end
    StoreCurrentWeapon(ply)
    SendNewInventoryFormat(ply)
end)

----------------------------------------
-- NEW: Helper to send craft result
----------------------------------------
local function SendCraftResult(ply, success, resultType, message)
    net.Start("TDMRP_CraftResult")
        net.WriteBool(success)
        net.WriteString(resultType)
        net.WriteString(message)
    net.Send(ply)
end

----------------------------------------
-- NEW: Craft Upgrade Handler
----------------------------------------
net.Receive("TDMRP_CraftUpgrade", function(_, ply)
    local wep = net.ReadEntity()
    
    if not IsValid(ply) or not IsValid(wep) then return end
    if wep:GetOwner() ~= ply then return end
    
    local currentTier = wep:GetNWInt("TDMRP_Tier", 1)
    if currentTier >= 5 then
        SendCraftResult(ply, false, "upgrade", "Weapon is already at maximum tier!")
        return
    end
    
    local nextTier = currentTier + 1
    local cost = CraftConfig.upgradeCosts[nextTier]
    
    if not ply:canAfford(cost) then
        SendCraftResult(ply, false, "upgrade", "You can't afford this upgrade!")
        return
    end
    
    ply:addMoney(-cost)
    
    local chance = CraftConfig.craftChance[nextTier]
    local roll = math.random()
    
    if roll <= chance then
        wep:SetNWInt("TDMRP_Tier", nextTier)
        wep:SetNWBool("TDMRP_Crafted", true)
        
        if TDMRP.ApplyM9KInstance then
            local inst = {
                class = wep:GetClass(),
                tier = nextTier,
                crafted = true,
                gems = {
                    sapphire = wep:GetNWInt("TDMRP_Gem_Sapphire", 0),
                    emerald = wep:GetNWInt("TDMRP_Gem_Emerald", 0),
                    ruby = wep:GetNWInt("TDMRP_Gem_Ruby", 0),
                    diamond = wep:GetNWInt("TDMRP_Gem_Diamond", 0),
                },
            }
            TDMRP.ApplyM9KInstance(wep, inst)
        end
        
        SendCraftResult(ply, true, "upgrade", "Weapon upgraded to Tier " .. nextTier .. "!")
        print("[TDMRP] " .. ply:Nick() .. " upgraded " .. wep:GetClass() .. " to T" .. nextTier)
    else
        local class = wep:GetClass()
        ply:StripWeapon(class)
        SendCraftResult(ply, false, "upgrade", "Upgrade failed! Your weapon was destroyed.")
        print("[TDMRP] " .. ply:Nick() .. " failed upgrade on " .. class .. " - weapon destroyed")
    end
end)

----------------------------------------
-- NEW: Craft Gem Handler
----------------------------------------
net.Receive("TDMRP_CraftGem", function(_, ply)
    local wep = net.ReadEntity()
    local gemType = net.ReadString()
    
    if not IsValid(ply) or not IsValid(wep) then return end
    if wep:GetOwner() ~= ply then return end
    
    local cost = CraftConfig.gemCosts[gemType]
    if not cost then
        SendCraftResult(ply, false, "gem", "Invalid gem type!")
        return
    end
    
    if not ply:canAfford(cost) then
        SendCraftResult(ply, false, "gem", "You can't afford this gem!")
        return
    end
    
    ply:addMoney(-cost)
    
    local nwKey = "TDMRP_Gem_" .. string.upper(string.sub(gemType, 1, 1)) .. string.sub(gemType, 2)
    local currentCount = wep:GetNWInt(nwKey, 0)
    wep:SetNWInt(nwKey, currentCount + 1)
    wep:SetNWBool("TDMRP_Crafted", true)
    
    if TDMRP.ApplyM9KInstance then
        local inst = {
            class = wep:GetClass(),
            tier = wep:GetNWInt("TDMRP_Tier", 1),
            crafted = true,
            gems = {
                sapphire = wep:GetNWInt("TDMRP_Gem_Sapphire", 0),
                emerald = wep:GetNWInt("TDMRP_Gem_Emerald", 0),
                ruby = wep:GetNWInt("TDMRP_Gem_Ruby", 0),
                diamond = wep:GetNWInt("TDMRP_Gem_Diamond", 0),
            },
        }
        TDMRP.ApplyM9KInstance(wep, inst)
    end
    
    SendCraftResult(ply, true, "gem", string.upper(gemType) .. " gem added!")
    print("[TDMRP] " .. ply:Nick() .. " added " .. gemType .. " gem to " .. wep:GetClass())
end)

----------------------------------------
-- NEW: Salvage Handler
----------------------------------------
net.Receive("TDMRP_CraftSalvage", function(_, ply)
    local wep = net.ReadEntity()
    
    if not IsValid(ply) or not IsValid(wep) then return end
    if wep:GetOwner() ~= ply then return end
    
    local class = wep:GetClass()
    local tier = wep:GetNWInt("TDMRP_Tier", 1)
    
    local meta = TDMRP.GetM9KMeta and TDMRP.GetM9KMeta(class)
    local basePrice = meta and meta.basePrice or 1000
    local tierMult = TDMRP.TierMultipliers and TDMRP.TierMultipliers[tier] or { price = 1 }
    local fullValue = basePrice * tierMult.price
    local salvageValue = math.floor(fullValue * 0.3)
    
    ply:StripWeapon(class)
    ply:addMoney(salvageValue)
    
    SendCraftResult(ply, true, "salvage", "Weapon salvaged for " .. DarkRP.formatMoney(salvageValue) .. "!")
    print("[TDMRP] " .. ply:Nick() .. " salvaged " .. class .. " T" .. tier .. " for $" .. salvageValue)
end)

print("[TDMRP] sv_tdmrp_inventory.lua loaded (with net + UI + crafting support)")