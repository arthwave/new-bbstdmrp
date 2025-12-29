TDMRP = TDMRP or {}

-- Tier constants
TDMRP.TIER_COMMON   = 1
TDMRP.TIER_UNCOMMON = 2
TDMRP.TIER_RARE     = 3
TDMRP.TIER_LEGEND   = 4
TDMRP.TIER_UNIQUE   = 5

TDMRP.TierNames = {
    [TDMRP.TIER_COMMON]   = "Common",
    [TDMRP.TIER_UNCOMMON] = "Uncommon",
    [TDMRP.TIER_RARE]     = "Rare",
    [TDMRP.TIER_LEGEND]   = "Legendary",
    [TDMRP.TIER_UNIQUE]   = "Unique",
}

-- Backwards-compatible table used by HUD + client code.
-- Each entry contains a `name` and `color` used by `cl_tdmrp_hud.lua`.
TDMRP_Tiers = TDMRP_Tiers or {
    [TDMRP.TIER_COMMON] = { name = TDMRP.TierNames[TDMRP.TIER_COMMON],   color = Color(200,200,200) },
    [TDMRP.TIER_UNCOMMON] = { name = TDMRP.TierNames[TDMRP.TIER_UNCOMMON], color = Color(100,220,100) },
    [TDMRP.TIER_RARE] = { name = TDMRP.TierNames[TDMRP.TIER_RARE],       color = Color(100,140,255) },
    [TDMRP.TIER_LEGEND] = { name = TDMRP.TierNames[TDMRP.TIER_LEGEND],   color = Color(220,160,60) },
    [TDMRP.TIER_UNIQUE] = { name = TDMRP.TierNames[TDMRP.TIER_UNIQUE],   color = Color(200,100,220) },
}

-- Drop config (for later combat drops)
TDMRP.DropConfig = {
    GemDropChance = 0.05, -- 5%
    GemTypes = { "blood_ruby", "blood_sapphire", "blood_emerald", "blood_diamond", "blood_amethyst" },

    WeaponDropChance = 0.05, -- 5%
    WeaponTierDropWeights = {
        -- no common in drops by design
        [TDMRP.TIER_UNCOMMON] = 0.80, -- 80%
        [TDMRP.TIER_RARE]     = 0.15, -- 15%
        [TDMRP.TIER_UNIQUE]   = 0.05, -- 5%
    }
}
-- Stat multipliers per tier (for instance-based weapons)
-- These are *ranges*; we roll a random value inside the range once per instance.
-- Common stays close to base, higher tiers get stronger damage/RPM,
-- lower recoil, and tighter spread.

TDMRP.TierStatMultipliers = {
    [TDMRP.TIER_COMMON] = {
        damage = {0.95, 1.05},   -- tiny ±5% wobble around base
        rpm    = {0.95, 1.05},
        recoil = {0.95, 1.05},   -- can be slightly better or worse
        spread = {0.95, 1.05},   -- >1 = less accurate, <1 = more accurate
    },

    [TDMRP.TIER_UNCOMMON] = {
        damage = {1.05, 1.15},   -- modest bump
        rpm    = {1.00, 1.10},
        recoil = {0.90, 1.00},   -- up to 10% less recoil
        spread = {0.90, 1.00},   -- up to 10% tighter
    },

    [TDMRP.TIER_RARE] = {
        damage = {1.15, 1.30},
        rpm    = {1.05, 1.15},
        recoil = {0.85, 0.95},   -- less recoil overall
        spread = {0.85, 0.95},   -- noticeably tighter
    },

    [TDMRP.TIER_LEGEND] = {
        damage = {1.30, 1.50},   -- chunky damage
        rpm    = {1.10, 1.25},   -- faster fire
        recoil = {0.75, 0.90},   -- up to 25% less recoil
        spread = {0.75, 0.90},   -- much more accurate
    },

    -- Tier 5 (UNIQUE) will be custom per-weapon later.
    -- We won’t roll it from this table; uniques get hand-authored stats.
}

