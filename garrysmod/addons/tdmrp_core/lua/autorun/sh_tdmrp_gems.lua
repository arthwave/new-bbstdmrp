-- sh_tdmrp_gems.lua
-- Shared gem utility functions for TDMRP
-- NOTE: Prefix and Suffix tables are defined in sh_tdmrp_gemcraft.lua

if SERVER then
    AddCSLuaFile()
end

TDMRP = TDMRP or {}
TDMRP.Gems = TDMRP.Gems or {}

----------------------------------------------------
-- Utility: safe copy helper
----------------------------------------------------
local function ShallowCopy(tbl)
    if not tbl then return nil end
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = v
    end
    return out
end

----------------------------------------------------
-- GEM TYPE IDS (for loot / inventory cross-reference)
-- These string IDs match sv_tdmrp_drops + loot orb colors:
--   "blood_ruby", "blood_sapphire", "blood_emerald",
--   "blood_amethyst", "blood_diamond", "scrap_metal"
----------------------------------------------------

TDMRP.Gems.Types = {
    blood_ruby     = { id = "blood_ruby",     kind = "ruby"     },
    blood_sapphire = { id = "blood_sapphire", kind = "sapphire" },
    blood_emerald  = { id = "blood_emerald",  kind = "emerald"  },
    blood_amethyst = { id = "blood_amethyst", kind = "amethyst" },
    blood_diamond  = { id = "blood_diamond",  kind = "diamond"  },
    scrap_metal    = { id = "scrap_metal",    kind = "scrap"    },
}

----------------------------------------------------
-- STANDARD CRAFT DATA MODEL (per weapon instance)
--
-- Fields:
--   crafted      : bool (has emerald+sapphire craft applied)
--   prefixId     : string or nil (prefix name, e.g., "Heavy")
--   suffixId     : string or nil (suffix name, e.g., "Blazing")
--   customName   : string or nil (player chosen)
--   materialName : string or nil (selected with material tool)
--   bindUntil    : number (CurTime() timestamp; 0 = unbound)
--   prefixMods   : table copy of prefix.stats at craft time
--   suffixData   : table copy of suffix config at craft time
----------------------------------------------------

function TDMRP.Gems.DefaultCraftData()
    return {
        crafted      = false,
        prefixId     = nil,
        suffixId     = nil,
        customName   = nil,
        materialName = nil,
        bindUntil    = 0,

        prefixMods   = nil,
        suffixData   = nil,
    }
end

function TDMRP.Gems.EnsureCraftData(container)
    if not container then return nil end

    if not container.CraftData then
        container.CraftData = TDMRP.Gems.DefaultCraftData()
    end

    return container.CraftData
end

----------------------------------------------------
-- LOOKUP HELPERS
----------------------------------------------------

function TDMRP.Gems.GetPrefix(id)
    if not id then return nil end
    return TDMRP.Gems.Prefixes and TDMRP.Gems.Prefixes[id]
end

function TDMRP.Gems.GetSuffix(id)
    if not id then return nil end
    return TDMRP.Gems.Suffixes and TDMRP.Gems.Suffixes[id]
end

function TDMRP.Gems.GetPrefixStats(id)
    local def = TDMRP.Gems.GetPrefix(id)
    if not def or not def.stats then return nil end
    return ShallowCopy(def.stats)
end

function TDMRP.Gems.GetSuffixStats(id)
    local def = TDMRP.Gems.GetSuffix(id)
    if not def or not def.stats then return nil end
    return ShallowCopy(def.stats)
end

-- Random suffix from all available suffixes
function TDMRP.Gems.RandomSuffixId()
    if not TDMRP.Gems.Suffixes or table.Count(TDMRP.Gems.Suffixes) == 0 then
        return nil
    end
    
    local keys = {}
    for k, _ in pairs(TDMRP.Gems.Suffixes) do
        table.insert(keys, k)
    end
    
    if #keys == 0 then return nil end
    return keys[math.random(1, #keys)]
end

-- Helper to build a display name from base + prefix/suffix
function TDMRP.Gems.BuildDisplayName(baseName, tierName, prefixId, suffixId, customName)
    if customName and customName ~= "" then
        return customName
    end

    baseName = baseName or "Weapon"
    tierName = tierName or ""

    local prefix = TDMRP.Gems.GetPrefix(prefixId)
    local suffix = TDMRP.Gems.GetSuffix(suffixId)

    local name = baseName

    if prefix and prefix.name and prefix.name ~= "" then
        name = prefix.name .. " " .. name
    end

    if suffix and suffix.name and suffix.name ~= "" then
        name = name .. " " .. suffix.name
    end

    return name
end

print("[TDMRP] sh_tdmrp_gems.lua loaded (utility functions ready)")
