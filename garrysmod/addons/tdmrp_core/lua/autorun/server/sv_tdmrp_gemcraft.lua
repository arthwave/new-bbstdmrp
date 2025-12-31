-- sv_tdmrp_gemcraft.lua
-- Server-side gem crafting logic (no UI yet)

if not SERVER then return end

TDMRP = TDMRP or {}
TDMRP.Gems = TDMRP.Gems or {}

local G = TDMRP.Gems

----------------------------------------------------
-- Safety helpers: inventory access
----------------------------------------------------

-- Small helper to safely grab the player's inventory table
local function GetInventorySafe(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil end
    if not TDMRP_GetInventory then return nil end

    local inv = TDMRP_GetInventory(ply)
    if not inv or not inv.items then return nil end

    return inv
end

-- Count how many of a given gemID the player has
-- gemID examples: "blood_emerald", "blood_sapphire", "blood_amethyst", etc.
local function CountGem(ply, gemID)
    local inv = GetInventorySafe(ply)
    if not inv then return 0 end

    local total = 0
    for id, item in pairs(inv.items) do
        if item.kind == "gem" and item.gem == gemID then
            total = total + (item.amount or 1)
        end
    end

    return total
end

-- Export globally for binding system
TDMRP.CountGem = CountGem

-- Consume N gems of a specific gemID from the inventory
-- Returns true if fully consumed, false if not enough
local function ConsumeGem(ply, gemID, amount)
    amount = amount or 0
    if amount <= 0 then return true end

    local inv = GetInventorySafe(ply)
    if not inv then return false end
    if not TDMRP_RemoveItem then return false end

    local remaining = amount

    -- Iterate over the inventory and wipe out stacks until we've removed 'amount'
    for id, item in pairs(inv.items) do
        if item.kind == "gem" and item.gem == gemID and remaining > 0 then
            local stackAmt = item.amount or 1

            if stackAmt > remaining then
                -- Remove only part of the stack
                TDMRP_RemoveItem(ply, id, remaining)
                remaining = 0
            else
                -- Remove whole stack
                TDMRP_RemoveItem(ply, id, stackAmt)
                remaining = remaining - stackAmt
            end
        end

        if remaining <= 0 then break end
    end

    -- Persist inventory after changes
    if TDMRP_SaveInventory then
        TDMRP_SaveInventory(ply)
    end

    return remaining <= 0
end

-- Export globally for binding system
TDMRP.ConsumeGem = ConsumeGem

----------------------------------------------------
-- Crafting validation
----------------------------------------------------

-- Returns: ok (bool), message (string)
-- prefixId is something like "heavy", "light", "vanguard", "marksman"
function G.CanCraftWeapon(ply, wep, prefixId)
    if not IsValid(ply) or not ply:IsPlayer() then
        return false, "Invalid player."
    end

    if not IsValid(wep) or not wep:IsWeapon() then
        return false, "You must be holding a weapon."
    end

    -- Only allow real guns, not tools / fists / keys etc (must be tdmrp_m9k_*)
    if not TDMRP.IsM9KWeapon or not TDMRP.IsM9KWeapon(wep) then
        return false, "This weapon cannot be modified."
    end

    local tier = wep:GetNWInt("TDMRP_Tier", 1)

    -- Don't allow crafting on Unique tier (5) or above
    if TDMRP and TDMRP.TIER_UNIQUE and tier >= TDMRP.TIER_UNIQUE then
        return false, "Unique weapons cannot be modified."
    end

    -- Don't allow double-crafting; use Ruby to reset later
    if wep:GetNWBool("TDMRP_Crafted", false) then
        return false, "This weapon is already crafted. Use a Blood Ruby to reset it."
    end

    -- Basic prefix validation, if shared prefix table exists
    if G.GetPrefix then
        local pref = G.GetPrefix(prefixId)
        if not pref then
            return false, "Unknown prefix: " .. tostring(prefixId or "nil")
        end
    elseif not prefixId or prefixId == "" then
        return false, "No prefix selected."
    end

    -- Check gem requirements: 1 Blood Emerald + 1 Blood Sapphire
    local emeraldCount  = CountGem(ply, "blood_emerald")
    local sapphireCount = CountGem(ply, "blood_sapphire")

    if emeraldCount < 1 or sapphireCount < 1 then
        return false, "You need 1 Blood Emerald and 1 Blood Sapphire."
    end

    return true, "OK"
end

----------------------------------------------------
-- Stat application helpers
----------------------------------------------------

-- Helper function to get tier-scaled base stats (without modifiers)
-- This ensures modifiers always apply to clean tier-scaled stats, not already-modified stats
local function GetTierScaledStats(wep)
    local tier = wep:GetNWInt("TDMRP_Tier", wep.Tier or 1)
    local scale = TDMRP_WeaponMixin and TDMRP_WeaponMixin.TierScaling and TDMRP_WeaponMixin.TierScaling[tier]
    if not scale then
        scale = { damage = 1, rpm = 1, spread = 1, recoil = 1, handling = 1 }
    end
    
    -- Get original base stats (pre-tier-scaling)
    local baseDmg = wep.TDMRP_BaseDamage or (wep.Primary and wep.Primary.Damage) or 25
    local baseRPM = wep.TDMRP_BaseRPM or (wep.Primary and wep.Primary.RPM) or 600
    local baseSpread = wep.TDMRP_BaseSpread or (wep.Primary and wep.Primary.Spread) or 0.03
    local baseKickUp = wep.TDMRP_BaseKickUp or (wep.Primary and wep.Primary.KickUp) or 0.5
    local baseKickDown = wep.TDMRP_BaseKickDown or (wep.Primary and wep.Primary.KickDown) or 0.3
    local baseKickHoriz = wep.TDMRP_BaseKickHoriz or (wep.Primary and wep.Primary.KickHorizontal) or 0.2
    local baseMagSize = wep.TDMRP_BaseMagSize or (wep.Primary and wep.Primary.ClipSize) or 30
    
    -- Apply tier scaling to get clean tier-scaled stats
    return {
        damage = math.Round(baseDmg * scale.damage),
        rpm = math.Round(baseRPM * scale.rpm),
        spread = baseSpread * scale.spread,
        kickUp = baseKickUp * scale.recoil,
        kickDown = baseKickDown * scale.recoil,
        kickHoriz = baseKickHoriz * scale.recoil,
        handling = math.Round(100 * (scale.handling or 1)),
        magSize = baseMagSize  -- Magazine doesn't scale with tier
    }
end

-- UNIFIED function to apply BOTH prefix AND suffix modifiers
-- Modifiers are applied multiplicatively: tierBase * (1 + prefixMod) * (1 + suffixMod)
-- This prevents additive stacking and ensures both modifiers combine correctly
-- EXPORTED globally so mixin can call it after tier scaling
local function ApplyAllCraftModifiers(wep)
    if not TDMRP or not TDMRP.Gems then return end
    
    local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
    local suffixId = wep:GetNWString("TDMRP_SuffixID", "")
    
    -- Get clean tier-scaled stats as starting point
    local tierStats = GetTierScaledStats(wep)
    
    -- Get modifier data
    local prefix = prefixId ~= "" and TDMRP.Gems.Prefixes and TDMRP.Gems.Prefixes[prefixId]
    local suffix = suffixId ~= "" and TDMRP.Gems.Suffixes and TDMRP.Gems.Suffixes[suffixId]
    
    local prefixStats = prefix and prefix.stats or {}
    local suffixStats = suffix and suffix.stats or {}
    
    -- Calculate combined multipliers (multiplicative)
    local damageMult = (1 + (prefixStats.damage or 0)) * (1 + (suffixStats.damage or 0))
    local rpmMult = (1 + (prefixStats.rpm or 0)) * (1 + (suffixStats.rpm or 0))
    local spreadMult = (1 + (prefixStats.spread or 0)) * (1 + (suffixStats.spread or 0))
    local recoilMult = (1 + (prefixStats.recoil or 0)) * (1 + (suffixStats.recoil or 0))
    local handlingMult = (1 + (prefixStats.handling or 0)) * (1 + (suffixStats.handling or 0))
    local magazineMult = (1 + (prefixStats.magazine or 0)) * (1 + (suffixStats.magazine or 0))
    
    -- Apply combined multipliers to tier-scaled base stats
    if wep.Primary then
        wep.Primary.Damage = math.floor(tierStats.damage * damageMult)
        wep.Primary.RPM = math.floor(tierStats.rpm * rpmMult)
        wep.Primary.Delay = 60 / wep.Primary.RPM
        wep.Primary.Spread = tierStats.spread * spreadMult
        wep.Primary.KickUp = tierStats.kickUp * recoilMult
        wep.Primary.KickDown = tierStats.kickDown * recoilMult
        wep.Primary.KickHorizontal = tierStats.kickHoriz * recoilMult
        wep.Primary.ClipSize = math.floor(tierStats.magSize * magazineMult)
    end
    
    wep.TDMRP_Handling = math.Clamp(math.floor(tierStats.handling * handlingMult), 0, 250)
    
    -- Store reload modifiers separately (applied via hooks)
    if prefixStats.reload then
        wep.TDMRP_PrefixReloadMod = (1 + prefixStats.reload)
    end
    if suffixStats.reload then
        wep.TDMRP_SuffixReloadMod = (1 + suffixStats.reload)
    end
    
    -- Store mag base if not set
    if not wep.TDMRP_BaseMagSize then
        wep.TDMRP_BaseMagSize = tierStats.magSize
    end
    
    -- Update networked stats for HUD display
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.SetNetworkedStats then
        TDMRP_WeaponMixin.SetNetworkedStats(wep)
    end
    
    print(string.format("[TDMRP] Applied combined modifiers (prefix=%s, suffix=%s): Dmg=%d (x%.2f) RPM=%d (x%.2f) Spread=%.3f (x%.2f)", 
        prefixId ~= "" and prefixId or "none",
        suffixId ~= "" and suffixId or "none",
        wep.Primary and wep.Primary.Damage or 0, damageMult,
        wep.Primary and wep.Primary.RPM or 0, rpmMult,
        wep.Primary and wep.Primary.Spread or 0, spreadMult))
end

-- Export ApplyAllCraftModifiers globally so mixin can use it
G.ApplyAllCraftModifiers = ApplyAllCraftModifiers

-- Legacy wrapper - calls unified function to apply all modifiers
local function ApplySuffixStatMods(wep, suffixId)
    if not TDMRP or not TDMRP.Gems or not TDMRP.Gems.Suffixes then return end
    local suffix = TDMRP.Gems.Suffixes[suffixId]
    if not suffix then return end
    
    -- Use unified function to apply all modifiers (combines prefix + suffix)
    ApplyAllCraftModifiers(wep)
end

-- Legacy wrapper - calls unified function to apply all modifiers
local function ApplyPrefixStatMods(wep, prefixId)
    if not TDMRP or not TDMRP.Gems or not TDMRP.Gems.Prefixes then return end
    local pref = TDMRP.Gems.Prefixes[prefixId]
    if not pref then return end
    
    -- Use unified function to apply all modifiers (combines prefix + suffix)
    ApplyAllCraftModifiers(wep)
end

local function PickRandomSuffix(tier)
    -- Pick a random suffix from all available suffixes (no tier restriction)
    if not TDMRP or not TDMRP.Gems or not TDMRP.Gems.Suffixes then return nil end

    local ids = {}
    for id, suffixData in pairs(TDMRP.Gems.Suffixes) do
        table.insert(ids, id)
    end

    if #ids == 0 then 
        print("[TDMRP GemCraft] WARNING: No suffixes found")
        return nil 
    end
    
    local chosen = ids[math.random(#ids)]
    print("[TDMRP GemCraft] Picked suffix '" .. chosen .. "' from " .. #ids .. " total options")
    return chosen
end

----------------------------------------------------
-- Core crafting: apply prefix + random suffix
----------------------------------------------------

-- Performs the actual crafting:
--  - validates
--  - consumes 1 emerald + 1 sapphire
--  - applies prefix stat buffs
--  - rolls a random suffix and stores it
--  - updates display name
-- Returns: ok (bool), suffixId or error message
-- Performs the actual crafting:
--  - validates
--  - consumes 1 emerald + 1 sapphire
--  - applies prefix stat buffs
--  - rolls a random suffix and stores it
--  - updates display name
--  - syncs to weapon instance + inventory (if present)
-- Returns: ok (bool), suffixId or error message
function G.CraftWeapon(ply, wep, prefixId)
    local ok, reason = G.CanCraftWeapon(ply, wep, prefixId)
    if not ok then
        return false, reason
    end

    -- Consume gems FIRST so we don't cheat if something fails later
    local okEmerald  = ConsumeGem(ply, "blood_emerald",  1)
    local okSapphire = ConsumeGem(ply, "blood_sapphire", 1)

    if not okEmerald or not okSapphire then
        return false, "Failed to consume gems. Inventory may be out of sync."
    end

    -- Get weapon tier BEFORE picking suffix
    local tier  = wep:GetNWInt("TDMRP_Tier", 1)

    -- Pick suffix based on weapon tier
    local suffixId = PickRandomSuffix(tier)

    -- Attach logical craft data table to the weapon
    local craft = G.EnsureCraftData and G.EnsureCraftData(wep) or nil

    if craft then
        craft.crafted      = true
        craft.prefixId     = prefixId
        craft.suffixId     = suffixId
        craft.tierAtCraft  = tier
        craft.baseClass    = wep:GetClass()
    end

    -- Mark on networked vars so clients / HUD can see it
    wep:SetNWBool("TDMRP_Crafted", true)
    wep:SetNWString("TDMRP_PrefixID", prefixId or "")
    wep:SetNWString("TDMRP_SuffixID", suffixId or "")
    
    -- Network custom tracer if suffix has one (so all clients can see it)
    if suffixId and TDMRP and TDMRP.Gems and TDMRP.Gems.Suffixes then
        local suffix = TDMRP.Gems.Suffixes[suffixId]
        if suffix and suffix.TracerName then
            wep:SetNWString("TDMRP_TracerName", suffix.TracerName)
        else
            wep:SetNWString("TDMRP_TracerName", "")
        end
    end
    
    -- Apply prefix stat tweaks on top of existing tier stats
    ApplyPrefixStatMods(wep, prefixId)

    ----------------------------------------------------------------
    -- Build nice display name for the gun (server-safe, no lang lib)
    ----------------------------------------------------------------
    local baseName = ""

    -- 1) Prefer a decent PrintName if available
    if wep.PrintName and wep.PrintName ~= "" and wep.PrintName ~= "Scripted Weapon" then
        baseName = wep.PrintName
    end

    -- 2) Fall back to GetPrintName if present (some SWEPs use this)
    if (not baseName or baseName == "" or baseName == "Scripted Weapon") and wep.GetPrintName then
        local tokenName = wep:GetPrintName()
        if tokenName and tokenName ~= "" and tokenName ~= "Scripted Weapon" then
            baseName = tokenName
        end
    end

    -- 3) Fall back to SWEP class
    if not baseName or baseName == "" or baseName == "Scripted Weapon" then
        baseName = wep:GetClass() or "Weapon"
    end

    -- 4) Optional cleanup for common prefixes (CS:S packs etc)
    baseName = baseName:gsub("^weapon_real_cs_", "")
    baseName = baseName:gsub("^weapon_", "")

    -- 5) Convert to title case (e.g., "desert_eagle" -> "Desert Eagle")
    local function TitleCase(str)
        return str:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
    end
    baseName = TitleCase(baseName)

    local tierName = ""
    if TDMRP and TDMRP.TierNames then
        tierName = TDMRP.TierNames[tier] or ""
    end

    local displayName

    if G.BuildDisplayName then
        displayName = G.BuildDisplayName(baseName, tierName, prefixId, suffixId, nil)
    else
        -- fallback: "Prefix Name of Suffix" (tier shown separately in HUD)
        local prettyPrefix = prefixId and string.upper(string.sub(prefixId, 1, 1)) .. string.sub(prefixId, 2) or ""
        local prettyBase   = baseName or "Weapon"

        if suffixId and suffixId ~= "" then
            local prettySuffix = suffixId:gsub("_", " ")
            displayName = string.Trim(prettyPrefix .. " " .. prettyBase .. " " .. prettySuffix)
        else
            displayName = string.Trim(prettyPrefix .. " " .. prettyBase)
        end
    end

    wep:SetNWString("TDMRP_CustomName", displayName or "")

    ------------------------------------------------
    -- NEW: Sync crafted state into instance + inv
    ------------------------------------------------
    if TDMRP_BuildInstanceFromSWEP and TDMRP_InstanceToItem and TDMRP_GetInventory then
        local inst = TDMRP_BuildInstanceFromSWEP(ply, wep)

        local inv = TDMRP_GetInventory(ply)
        if inv and inv.items and inst and inst.id then
            for id, item in pairs(inv.items) do
                if item.kind == "weapon" and item.instance_id == inst.id then
                    -- Replace stored item with updated instance snapshot
                    inv.items[id] = TDMRP_InstanceToItem(inst)

                    if TDMRP_SaveInventory then
                        TDMRP_SaveInventory(ply)
                    end
                    break
                end
            end
        end
    end

    -- Simple feedback to player
    if suffixId and suffixId ~= "" then
        ply:ChatPrint(string.format("[TDMRP] Crafted %s (prefix: %s, suffix: %s).",
            displayName or "your weapon",
            tostring(prefixId),
            tostring(suffixId)
        ))
    else
        ply:ChatPrint(string.format("[TDMRP] Crafted %s (prefix: %s).",
            displayName or "your weapon",
            tostring(prefixId)
        ))
    end

    return true, suffixId
end


----------------------------------------------------
-- Debug console command for testing
----------------------------------------------------

-- Usage (in-game console):
--   tdmrp_craft heavy
--   tdmrp_craft light
--   tdmrp_craft vanguard
--   tdmrp_craft marksman
--
-- Must be holding a valid gun and have:
--   1x blood_emerald + 1x blood_sapphire in your inventory.
concommand.Add("tdmrp_craft", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local prefixId = args[1] or "heavy"
    local wep = ply:GetActiveWeapon()

    if not IsValid(wep) then
        ply:ChatPrint("[TDMRP] You must be holding a weapon to craft it.")
        return
    end

    local ok, result = G.CraftWeapon(ply, wep, prefixId)
    if not ok then
        ply:ChatPrint("[TDMRP] Craft failed: " .. tostring(result))
    end
end)

----------------------------------------------------
-- Debug: give yourself gems via console
-- Usage (client console, while on your server):
--   tdmrp_givegem blood_emerald 5
--   tdmrp_givegem blood_sapphire 3
--   tdmrp_givegem blood_diamond 1
----------------------------------------------------

local function DebugGiveGem(ply, gemID, amount)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    amount = tonumber(amount) or 1
    if amount <= 0 then return end

    if not TDMRP_AddItem then
        print("[TDMRP] DebugGiveGem failed: TDMRP_AddItem is not defined. " ..
              "Wire this to your actual inventory add function.")
        return
    end

    local item = {
        kind   = "gem",
        gem    = gemID,
        amount = amount,
    }

    TDMRP_AddItem(ply, item)

    if TDMRP_SaveInventory then
        TDMRP_SaveInventory(ply)
    end

    ply:ChatPrint(string.format("[TDMRP] Given %d x %s.", amount, gemID))
end

concommand.Add("tdmrp_givegem", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local gemID = args[1] or "blood_emerald"
    local amount = args[2] or 1

    DebugGiveGem(ply, gemID, amount)
end)

----------------------------------------------------
-- Net handlers for client UI
----------------------------------------------------

util.AddNetworkString("TDMRP_CraftWeapon")
util.AddNetworkString("TDMRP_CraftSuccess")
util.AddNetworkString("TDMRP_CraftFailed")

net.Receive("TDMRP_CraftWeapon", function(len, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local prefixID = net.ReadString()
    local wep = ply:GetActiveWeapon()
    
    if not IsValid(wep) or not wep:IsWeapon() then
        net.Start("TDMRP_CraftFailed")
        net.WriteString("You must be holding a weapon.")
        net.Send(ply)
        return
    end
    
    local ok, result = G.CraftWeapon(ply, wep, prefixID)
    
    if ok then
        net.Start("TDMRP_CraftSuccess")
        net.WriteString(prefixID)
        net.WriteString(result or "")
        net.Send(ply)
    else
        net.Start("TDMRP_CraftFailed")
        net.WriteString(result or "Unknown error")
        net.Send(ply)
    end
end)

print("[TDMRP] sv_tdmrp_gemcraft.lua loaded (server crafting backend ready)")

----------------------------------------------------
-- NEW: Independent Roll Prefix / Roll Suffix System
-- Allows unlimited rerolls as long as player has gems
----------------------------------------------------

util.AddNetworkString("TDMRP_RollPrefix")
util.AddNetworkString("TDMRP_RollSuffix")
util.AddNetworkString("TDMRP_CraftResult")
util.AddNetworkString("TDMRP_RequestGemCounts")
util.AddNetworkString("TDMRP_GemCounts")
util.AddNetworkString("TDMRP_ApplyAmethyst")
util.AddNetworkString("TDMRP_BindUpdate")
util.AddNetworkString("TDMRP_SyncCustomName")
util.AddNetworkString("TDMRP_BindExpired")

----------------------------------------------------
-- NEW: Centralized Bind Timer Sync Helper
-- Call this whenever TDMRP_BindExpire changes on a weapon
-- Ensures client HUD updates immediately without delay
----------------------------------------------------

function TDMRP.SendBindUpdateToPlayer(ply, wep, newExpire)
    if not IsValid(ply) or not IsValid(wep) then return end
    
    -- Calculate remaining time from expireTime
    local remaining = newExpire > 0 and (newExpire - CurTime()) or 0
    if remaining < 0 then remaining = 0 end
    
    net.Start("TDMRP_BindUpdate")
    net.WriteEntity(wep)
    net.WriteFloat(newExpire or 0)
    net.WriteFloat(remaining)  -- Send remaining time as well
    net.Send(ply)
    
    print(string.format("[TDMRP] Sent bind update to %s: %.1f seconds remaining", ply:Nick(), remaining))
end

-- Alias for easier access
TDMRP.Binding = TDMRP.Binding or {}
TDMRP.Binding.SendUpdate = TDMRP.SendBindUpdateToPlayer

-- Helper: Get random prefix
local function GetRandomPrefix()
    if not TDMRP.Gems or not TDMRP.Gems.Prefixes then return nil end
    
    local keys = {}
    for k, _ in pairs(TDMRP.Gems.Prefixes) do
        table.insert(keys, k)
    end
    
    if #keys == 0 then return nil end
    return keys[math.random(#keys)]
end

-- Helper: Get random suffix (from any tier for now)
-- excludeSuffix: optional suffix ID to exclude from the roll (prevents rolling same suffix)
local function GetRandomSuffix(excludeSuffix)
    if not TDMRP.Gems or not TDMRP.Gems.Suffixes then return nil end
    
    local keys = {}
    for k, _ in pairs(TDMRP.Gems.Suffixes) do
        -- Skip if this is the suffix to exclude
        if excludeSuffix and k == excludeSuffix then
            -- Don't add to keys
        else
            table.insert(keys, k)
        end
    end
    
    if #keys == 0 then return nil end
    return keys[math.random(#keys)]
end

-- Helper: Build and set weapon display name from prefix/suffix/tier
local function UpdateWeaponDisplayName(wep)
    if not IsValid(wep) then return end
    
    -- Get base name
    local baseName = wep:GetPrintName() or wep:GetClass()
    baseName = baseName:gsub("^weapon_", ""):gsub("^tdmrp_m9k_", "")
    
    -- Convert to title case
    local function TitleCase(str)
        return str:gsub("([^_])([A-Z])", "%1 %2"):gsub("_", " "):gsub("(%w)([%w']*)", function(a,b) return string.upper(a)..b end)
    end
    baseName = TitleCase(baseName)
    
    -- Get tier name
    local tier = wep:GetNWInt("TDMRP_Tier", 1)
    local tierName = TDMRP.TierNames and TDMRP.TierNames[tier] or ""
    
    -- Build full name with prefix/suffix
    local displayName = ""
    
    local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
    if prefixId ~= "" and TDMRP.Gems and TDMRP.Gems.Prefixes then
        local prefix = TDMRP.Gems.Prefixes[prefixId]
        if prefix then
            displayName = prefix.name .. " "
        end
    end
    
    displayName = displayName .. baseName
    
    local suffixId = wep:GetNWString("TDMRP_SuffixID", "")
    if suffixId ~= "" and TDMRP.Gems and TDMRP.Gems.Suffixes then
        local suffix = TDMRP.Gems.Suffixes[suffixId]
        if suffix then
            displayName = displayName .. " " .. suffix.name
        end
    end
    
    -- Set on weapon
    wep:SetNWString("TDMRP_CustomName", displayName)
    print(string.format("[TDMRP] Updated weapon display name: %s", displayName))
end

-- Helper: Reset weapon to tier baseline stats (removes all prefix/suffix effects)
-- This MUST be called before applying new prefix/suffix to prevent stat stacking
local function ResetToTierBaseline(wep)
    if not IsValid(wep) then return end
    
    -- Get clean tier-scaled stats without any modifiers
    local tierStats = GetTierScaledStats(wep)
    
    -- Reset Primary table to tier baseline
    if wep.Primary then
        wep.Primary.Damage = tierStats.damage
        wep.Primary.RPM = tierStats.rpm
        wep.Primary.Delay = 60 / tierStats.rpm
        wep.Primary.Spread = tierStats.spread
        wep.Primary.KickUp = tierStats.kickUp
        wep.Primary.KickDown = tierStats.kickDown
        wep.Primary.KickHorizontal = tierStats.kickHoriz
        wep.Primary.ClipSize = tierStats.magSize
    end
    
    -- Reset handling
    wep.TDMRP_Handling = tierStats.handling
    
    -- Clear any reload modifiers from previous prefix/suffix
    wep.TDMRP_PrefixReloadMod = nil
    wep.TDMRP_SuffixReloadMod = nil
    
    -- Update networked stats immediately
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.SetNetworkedStats then
        TDMRP_WeaponMixin.SetNetworkedStats(wep)
    end
    
    print(string.format("[TDMRP] Reset weapon to tier baseline: Dmg=%d, RPM=%d, Spread=%.3f", 
        tierStats.damage, tierStats.rpm, tierStats.spread))
end

-- Export ResetToTierBaseline for potential use elsewhere
G.ResetToTierBaseline = ResetToTierBaseline

-- Helper: Apply prefix stat mods to weapon (DEPRECATED - use ApplyAllCraftModifiers instead)
-- This function now just calls the unified function to prevent stat stacking
local function ApplyPrefixToWeapon(wep, prefixId)
    if not IsValid(wep) then return end
    
    -- CRITICAL: Reset to baseline first, then apply all modifiers
    -- This ensures we don't stack stats when re-rolling prefixes
    ApplyAllCraftModifiers(wep)
    
    local prefix = TDMRP.Gems and TDMRP.Gems.Prefixes and TDMRP.Gems.Prefixes[prefixId]
    if prefix then
        print(string.format("[TDMRP] ApplyPrefixToWeapon: Applied prefix '%s' via unified system", prefixId))
    end
end

-- Send gem counts to client
local function SendGemCounts(ply)
    if not IsValid(ply) then return end
    
    local emeraldCount = CountGem(ply, "blood_emerald")
    local sapphireCount = CountGem(ply, "blood_sapphire")
    local amethystCount = CountGem(ply, "blood_amethyst")
    
    net.Start("TDMRP_GemCounts")
    net.WriteUInt(emeraldCount, 16)
    net.WriteUInt(sapphireCount, 16)
    net.WriteUInt(amethystCount, 16)
    net.Send(ply)
end

-- Request gem counts
net.Receive("TDMRP_RequestGemCounts", function(len, ply)
    if not IsValid(ply) then return end
    SendGemCounts(ply)
end)

-- Roll Prefix (costs 1 Blood Emerald)
net.Receive("TDMRP_RollPrefix", function(len, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    -- Get weapon from client-sent EntIndex
    local entIndex = net.ReadUInt(16)
    local wep = ents.GetByIndex(entIndex)
    
    -- Fallback to active weapon if invalid
    if not IsValid(wep) then
        wep = ply:GetActiveWeapon()
    end
    
    -- Validate weapon
    if not IsValid(wep) or not wep:IsWeapon() then
        net.Start("TDMRP_CraftResult")
        net.WriteBool(false)
        net.WriteString("prefix")
        net.WriteString("")
        net.WriteString("You must be holding a weapon!")
        net.Send(ply)
        return
    end
    
    -- Check if TDMRP weapon (must be tdmrp_m9k_*)
    if TDMRP.IsM9KWeapon and not TDMRP.IsM9KWeapon(wep) then
        net.Start("TDMRP_CraftResult")
        net.WriteBool(false)
        net.WriteString("prefix")
        net.WriteString("")
        net.WriteString("This weapon cannot be modified!")
        net.Send(ply)
        return
    end
    
    -- Check emerald count
    local emeraldCount = CountGem(ply, "blood_emerald")
    if emeraldCount < 1 then
        net.Start("TDMRP_CraftResult")
        net.WriteBool(false)
        net.WriteString("prefix")
        net.WriteString("")
        net.WriteString("You need 1 Blood Emerald!")
        net.Send(ply)
        return
    end
    
    -- Consume emerald
    ConsumeGem(ply, "blood_emerald", 1)
    
    -- Roll random prefix
    local prefixId = GetRandomPrefix()
    if not prefixId then
        net.Start("TDMRP_CraftResult")
        net.WriteBool(false)
        net.WriteString("prefix")
        net.WriteString("")
        net.WriteString("No prefixes available!")
        net.Send(ply)
        return
    end
    
    -- Apply prefix to weapon
    wep:SetNWString("TDMRP_PrefixID", prefixId)
    wep:SetNWBool("TDMRP_Crafted", true)
    ApplyPrefixToWeapon(wep, prefixId)
    
    -- Update display name to include new prefix
    UpdateWeaponDisplayName(wep)
    
    -- Update display name
    local prefix = TDMRP.Gems.Prefixes[prefixId]
    local prefixName = prefix and prefix.name or prefixId
    
    -- If weapon is bound, also store in test bind system to ensure persistence through crafting
    local bindExpire = wep:GetNWFloat("TDMRP_BindExpire", 0)
    if bindExpire > 0 then
        local sid = ply:SteamID64()
        TDMRP.TestBindWeapons = TDMRP.TestBindWeapons or {}
        TDMRP.TestBindWeapons[sid] = {
            entID = wep:EntIndex(),
            expireTime = bindExpire,
            class = wep:GetClass(),
            prefixId = wep:GetNWString("TDMRP_PrefixID", ""),
            suffixId = wep:GetNWString("TDMRP_SuffixID", ""),
            material = wep.TDMRP_StoredMaterial or wep:GetNWString("TDMRP_Material", ""),  -- CRITICAL: Preserve material
            customName = wep:GetNWString("TDMRP_CustomName", "") or wep.TDMRP_CustomName or "",  -- CRITICAL: Preserve custom name
            crafted = true,  -- Always true for weapons with modifiers
        }
        print(string.format("[TDMRP] Preserved bind during prefix craft: %.1f seconds (prefix=%s, suffix=%s, material=%s, customName=%s)", 
            bindExpire - CurTime(), wep:GetNWString("TDMRP_PrefixID", ""), wep:GetNWString("TDMRP_SuffixID", ""), wep.TDMRP_StoredMaterial or "none", wep:GetNWString("TDMRP_CustomName", "") or "none"))
    end
    
    -- Sync to instance - this captures the modified stats
    if TDMRP_BuildInstanceFromSWEP and TDMRP_SaveInventory then
        local inst = TDMRP_BuildInstanceFromSWEP(ply, wep)
        if inst then
            print(string.format("[TDMRP] Built instance with prefix: prefixId=%s, stats.damage=%d, bound_until=%s", 
                inst.craft.prefixId, inst.stats.damage, inst.bound_until or "nil"))
        end
        TDMRP_SaveInventory(ply)
    end
    
    -- Send success
    net.Start("TDMRP_CraftResult")
    net.WriteBool(true)
    net.WriteString("prefix")
    net.WriteString(prefixId)
    net.WriteString("Rolled prefix: " .. prefixName .. "!")
    net.Send(ply)
    
    print("[TDMRP] " .. ply:Nick() .. " rolled prefix: " .. prefixId)
end)

-- Roll Suffix (costs 1 Blood Sapphire)
net.Receive("TDMRP_RollSuffix", function(len, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    -- Get weapon from client-sent EntIndex
    local entIndex = net.ReadUInt(16)
    local wep = ents.GetByIndex(entIndex)
    
    -- Fallback to active weapon if invalid
    if not IsValid(wep) then
        wep = ply:GetActiveWeapon()
    end
    
    -- Validate weapon
    if not IsValid(wep) or not wep:IsWeapon() then
        net.Start("TDMRP_CraftResult")
        net.WriteBool(false)
        net.WriteString("suffix")
        net.WriteString("")
        net.WriteString("You must be holding a weapon!")
        net.Send(ply)
        return
    end
    
    -- Check if TDMRP weapon (must be tdmrp_m9k_*)
    if TDMRP.IsM9KWeapon and not TDMRP.IsM9KWeapon(wep) then
        net.Start("TDMRP_CraftResult")
        net.WriteBool(false)
        net.WriteString("suffix")
        net.WriteString("")
        net.WriteString("This weapon cannot be modified!")
        net.Send(ply)
        return
    end
    
    -- Check sapphire count
    local sapphireCount = CountGem(ply, "blood_sapphire")
    if sapphireCount < 1 then
        net.Start("TDMRP_CraftResult")
        net.WriteBool(false)
        net.WriteString("suffix")
        net.WriteString("")
        net.WriteString("You need 1 Blood Sapphire!")
        net.Send(ply)
        return
    end
    
    -- Consume sapphire
    ConsumeGem(ply, "blood_sapphire", 1)
    
    -- Get current suffix to exclude it from rolling
    local currentSuffixId = wep:GetNWString("TDMRP_SuffixID", "")
    
    -- Roll random suffix (excluding current suffix if it exists)
    local suffixId = GetRandomSuffix(currentSuffixId ~= "" and currentSuffixId or nil)
    if not suffixId then
        net.Start("TDMRP_CraftResult")
        net.WriteBool(false)
        net.WriteString("suffix")
        net.WriteString("")
        net.WriteString("No suffixes available!")
        net.Send(ply)
        return
    end
    
    -- Apply suffix to weapon
    wep:SetNWString("TDMRP_SuffixID", suffixId)
    wep:SetNWBool("TDMRP_Crafted", true)
    
    -- Get suffix data for material and name
    local suffix = TDMRP.Gems.Suffixes[suffixId]
    local suffixName = suffix and suffix.name or suffixId
    
    -- Apply suffix material if defined (now active)
    if suffix and suffix.material then
        wep:SetNWString("TDMRP_Material", suffix.material)
        
        -- CRITICAL: Also store material on the weapon entity itself (fallback for respawn)
        -- This ensures material persists through death/respawn even if NWString hasn't synced to client
        wep.TDMRP_StoredMaterial = suffix.material
        
        print(string.format("[TDMRP DEBUG] Suffix material from definition: %s", suffix.material))
        print(string.format("[TDMRP DEBUG] Weapon class: %s, IsValid: %s", wep:GetClass(), IsValid(wep)))
        
        -- Immediately apply material to weapon entity for visual feedback (use same pattern as active skills)
        wep:SetMaterial(suffix.material)
        print(string.format("[TDMRP DEBUG] Called SetMaterial on weapon, result: %s", wep:GetMaterial()))
        
        -- Also apply to all submaterials
        for i = 0, 31 do
            wep:SetSubMaterial(i, suffix.material)
        end
        print("[TDMRP DEBUG] Applied submaterials 0-31")
        
        -- If player is holding weapon, also apply to viewmodel
        local owner = wep:GetOwner()
        print(string.format("[TDMRP DEBUG] Owner: %s, IsValid: %s", owner, IsValid(owner)))
        if IsValid(owner) and owner:IsPlayer() then
            local vm = owner:GetViewModel()
            print(string.format("[TDMRP DEBUG] ViewModel valid: %s", IsValid(vm)))
            if IsValid(vm) then
                vm:SetMaterial(suffix.material)
                for i = 0, 31 do
                    vm:SetSubMaterial(i, suffix.material)
                end
                print("[TDMRP DEBUG] Applied material to viewmodel")
            end
        end
        
        print(string.format("[TDMRP] Applied suffix material: %s (with submaterials)", suffix.material))
    end
    
    -- Apply suffix stat modifiers (damage, recoil, spread, etc.)
    ApplySuffixStatMods(wep, suffixId)
    
    -- Update display name to include new suffix
    UpdateWeaponDisplayName(wep)
    
    -- If weapon is bound, also store in test bind system to ensure persistence through crafting
    local bindExpire = wep:GetNWFloat("TDMRP_BindExpire", 0)
    if bindExpire > 0 then
        local sid = ply:SteamID64()
        TDMRP.TestBindWeapons = TDMRP.TestBindWeapons or {}
        
        -- CRITICAL: Ensure we have the material from the weapon entity property first
        local materialToStore = wep.TDMRP_StoredMaterial or wep:GetNWString("TDMRP_Material", "")
        print(string.format("[TDMRP DEBUG SUFFIX] Before TestBindWeapons update: StoredMat=%s, NWStr=%s, Final=%s",
            wep.TDMRP_StoredMaterial or "nil", wep:GetNWString("TDMRP_Material", ""), materialToStore or "nil"))
        
        TDMRP.TestBindWeapons[sid] = {
            entID = wep:EntIndex(),
            expireTime = bindExpire,
            class = wep:GetClass(),
            prefixId = wep:GetNWString("TDMRP_PrefixID", ""),
            suffixId = wep:GetNWString("TDMRP_SuffixID", ""),
            material = materialToStore,  -- CRITICAL: Preserve suffix material
            customName = wep:GetNWString("TDMRP_CustomName", "") or wep.TDMRP_CustomName or "",  -- CRITICAL: Preserve custom name
            crafted = true,  -- Always true for weapons with modifiers
        }
        print(string.format("[TDMRP] Preserved bind during suffix craft: %.1f seconds (prefix=%s, suffix=%s, material=%s, customName=%s)", 
            bindExpire - CurTime(), wep:GetNWString("TDMRP_PrefixID", ""), wep:GetNWString("TDMRP_SuffixID", ""), materialToStore or "none", wep:GetNWString("TDMRP_CustomName", "") or "none"))
    end
    
    -- Sync to instance - this captures the modified suffix
    if TDMRP_BuildInstanceFromSWEP and TDMRP_SaveInventory then
        local inst = TDMRP_BuildInstanceFromSWEP(ply, wep)
        if inst then
            print(string.format("[TDMRP] Built instance with suffix: suffixId=%s, bound_until=%s", 
                inst.craft.suffixId, inst.bound_until or "nil"))
        end
        TDMRP_SaveInventory(ply)
    end
    
    -- Send success
    net.Start("TDMRP_CraftResult")
    net.WriteBool(true)
    net.WriteString("suffix")
    net.WriteString(suffixId)
    net.WriteString("Rolled suffix: " .. suffixName .. "!")
    net.Send(ply)
    
    print("[TDMRP] " .. ply:Nick() .. " rolled suffix: " .. suffixId)
end)

----------------------------------------------------
-- Blood Ruby: Salvage (Unbind + Refund Gems)
----------------------------------------------------
util.AddNetworkString("TDMRP_RubySalvage")

net.Receive("TDMRP_RubySalvage", function(len, ply)
    if not IsValid(ply) then return end
    
    -- Get weapon from client-sent EntIndex
    local entIndex = net.ReadUInt(16)
    local wep = ents.GetByIndex(entIndex)
    
    -- Fallback to active weapon if invalid
    if not IsValid(wep) then
        wep = ply:GetActiveWeapon()
    end
    if not IsValid(wep) then
        net.Start("TDMRP_CraftResult")
        net.WriteBool(false)
        net.WriteString("salvage")
        net.WriteString("")
        net.WriteString("You must be holding a weapon!")
        net.Send(ply)
        return
    end
    
    -- Check if TDMRP weapon
    if TDMRP.IsM9KWeapon and not TDMRP.IsM9KWeapon(wep) then
        net.Start("TDMRP_CraftResult")
        net.WriteBool(false)
        net.WriteString("salvage")
        net.WriteString("")
        net.WriteString("This weapon cannot be salvaged!")
        net.Send(ply)
        return
    end
    
    -- Check ruby count
    local rubyCount = CountGem(ply, "blood_ruby")
    if rubyCount < 1 then
        net.Start("TDMRP_CraftResult")
        net.WriteBool(false)
        net.WriteString("salvage")
        net.WriteString("")
        net.WriteString("You need 1 Blood Ruby!")
        net.Send(ply)
        return
    end
    
    -- Calculate refunds
    local refundSapphire = 0
    local refundEmerald = 0
    local refundAmethyst = 0
    
    -- Refund prefix/suffix gems if crafted
    if wep:GetNWBool("TDMRP_Crafted", false) then
        if wep:GetNWString("TDMRP_PrefixID", "") ~= "" then
            refundEmerald = refundEmerald + 1
        end
        if wep:GetNWString("TDMRP_SuffixID", "") ~= "" then
            refundSapphire = refundSapphire + 1
        end
    end
    
    -- Refund amethysts based on bind time remaining (1 per 20 minutes, min 20min to refund)
    local bindRemaining = 0
    if TDMRP.Binding and TDMRP.Binding.GetRemainingTime then
        bindRemaining = TDMRP.Binding.GetRemainingTime(wep)
    end
    
    if bindRemaining >= (20 * 60) then
        refundAmethyst = math.floor(bindRemaining / (20 * 60))
    end
    
    -- Consume ruby
    ConsumeGem(ply, "blood_ruby", 1)
    
    -- Remove all crafted attributes
    wep:SetNWBool("TDMRP_Crafted", false)
    wep:SetNWString("TDMRP_PrefixID", "")
    wep:SetNWString("TDMRP_SuffixID", "")
    wep:SetNWString("TDMRP_Material", "")
    
    -- Unbind weapon
    wep:SetNWFloat("TDMRP_BindExpire", 0)
    wep:SetNWFloat("TDMRP_BindUntil", 0)
    if TDMRP.Binding and TDMRP.Binding.Unbind then
        TDMRP.Binding.Unbind(wep)
    end
    
    -- Reset stats to base tier values (remove prefix mods)
    if TDMRP_WeaponMixin and TDMRP_WeaponMixin.ApplyTierScaling then
        local tier = wep:GetNWInt("TDMRP_Tier", 1)
        TDMRP_WeaponMixin.ApplyTierScaling(wep, tier)
        if TDMRP_WeaponMixin.SetNetworkedStats then
            TDMRP_WeaponMixin.SetNetworkedStats(wep)
        end
    end
    
    -- Refund gems to inventory
    if TDMRP_AddItem then
        if refundSapphire > 0 then
            TDMRP_AddItem(ply, { kind = "gem", gem = "blood_sapphire", amount = refundSapphire })
        end
        if refundEmerald > 0 then
            TDMRP_AddItem(ply, { kind = "gem", gem = "blood_emerald", amount = refundEmerald })
        end
        if refundAmethyst > 0 then
            TDMRP_AddItem(ply, { kind = "gem", gem = "blood_amethyst", amount = refundAmethyst })
        end
    end
    
    -- Save inventory
    if TDMRP_SaveInventory then
        TDMRP_SaveInventory(ply)
    end
    
    -- Build refund message
    local refundMsg = "Weapon salvaged!"
    if refundSapphire > 0 or refundEmerald > 0 or refundAmethyst > 0 then
        refundMsg = refundMsg .. " Refunded: "
        local refunds = {}
        if refundSapphire > 0 then table.insert(refunds, refundSapphire .. " Sapphire") end
        if refundEmerald > 0 then table.insert(refunds, refundEmerald .. " Emerald") end
        if refundAmethyst > 0 then table.insert(refunds, refundAmethyst .. " Amethyst") end
        refundMsg = refundMsg .. table.concat(refunds, ", ")
    end
    
    -- Send success
    net.Start("TDMRP_CraftResult")
    net.WriteBool(true)
    net.WriteString("salvage")
    net.WriteString("")
    net.WriteString(refundMsg)
    net.Send(ply)
    
    print(string.format("[TDMRP] %s salvaged weapon: refunded %d sapphire, %d emerald, %d amethyst", 
        ply:Nick(), refundSapphire, refundEmerald, refundAmethyst))
end)

----------------------------------------------------
-- Custom Weapon Naming System ($10,000)
----------------------------------------------------

util.AddNetworkString("TDMRP_SetCustomName")

local CUSTOM_NAME_COST = 10000
local CUSTOM_NAME_MAX_LENGTH = 32

net.Receive("TDMRP_SetCustomName", function(len, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    
    local entIndex = net.ReadUInt(16)
    local customName = net.ReadString()
    
    -- Validate input
    if string.len(customName) == 0 or string.len(customName) > CUSTOM_NAME_MAX_LENGTH then
        ply:ChatPrint("[TDMRP] Invalid custom name length!")
        return
    end
    
    -- Get weapon
    local wep = ents.GetByIndex(entIndex)
    if not IsValid(wep) or not TDMRP.IsM9KWeapon(wep) then
        ply:ChatPrint("[TDMRP] Weapon not found or invalid!")
        return
    end
    
    -- Verify player owns/has weapon
    if wep:GetOwner() ~= ply then
        ply:ChatPrint("[TDMRP] You don't own this weapon!")
        return
    end
    
    -- Check player has enough money
    local playerMoney = ply:getDarkRPVar("money") or 0
    if playerMoney < CUSTOM_NAME_COST then
        ply:ChatPrint("[TDMRP] You need $" .. string.format("%,d", CUSTOM_NAME_COST) .. " to customize a weapon!")
        return
    end
    
    -- Deduct money
    ply:addMoney(-CUSTOM_NAME_COST)
    
    -- Set custom name on weapon
    wep:SetNWString("TDMRP_CustomName", customName)
    wep.TDMRP_CustomName = customName  -- Also store on entity for fallback
    
    -- CRITICAL: If weapon is bound, update TestBindWeapons with new custom name
    -- This ensures custom names persist through death/respawn for bound weapons
    local bindExpire = wep:GetNWFloat("TDMRP_BindExpire", 0)
    if bindExpire > 0 then
        local sid = ply:SteamID64()
        TDMRP.TestBindWeapons = TDMRP.TestBindWeapons or {}
        if TDMRP.TestBindWeapons[sid] then
            TDMRP.TestBindWeapons[sid].customName = customName
            print(string.format("[TDMRP] Updated TestBindWeapons with custom name for bound weapon: %s", customName))
        end
    end
    
    -- Log and confirm
    print(string.format("[TDMRP] %s set custom name '%s' on weapon %s (cost: $%d)", 
        ply:Nick(), customName, wep:GetClass(), CUSTOM_NAME_COST))
    
    ply:ChatPrint("[TDMRP] Weapon renamed to: *" .. customName .. "*")
end)

print("[TDMRP] Independent roll prefix/suffix system loaded")