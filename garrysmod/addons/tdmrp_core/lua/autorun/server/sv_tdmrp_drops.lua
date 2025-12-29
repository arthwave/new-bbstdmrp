-- sv_tdmrp_drops.lua
-- Kill drops: money + gem/scrap orbs that fly to the killer

if not SERVER then return end

----------------------------------------
-- CONFIG
----------------------------------------

-- Money range per valid kill
local MONEY_MIN = 100
local MONEY_MAX = 300

-- Flat chance per valid kill for a gem/scrap orb
local GEM_DROP_CHANCE = 0.05
local WEAPON_DROP_CHANCE = 0.15

-- If true: use tdmrp_class (civilian/criminal/cop/zombie) to decide
-- which kills are "valid" for drops.
-- If false: ANY PvP kill (attacker != victim) counts.
local USE_CLASS_FILTER = false   -- <--- start with false so it's not bricked

----------------------------------------
-- Class helpers (used only if USE_CLASS_FILTER = true)
----------------------------------------

-- Normalise to lowercase so "Cop", "cop", "COP" all work
local function TDMRP_GetClass(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return "unknown" end

    local cls = ply:GetNWString("tdmrp_class", "civilian") or "civilian"
    cls = string.lower(cls)

    if cls == "civ" or cls == "civillian" then cls = "civilian" end
    if cls == "police" or cls == "swat"     then cls = "cop"      end

    return cls
end

local function TDMRP_IsCombatClass(cls)
    cls = string.lower(cls or "")
    return cls == "cop" or cls == "criminal" or cls == "zombie"
end

-- Strict TDMRP matchup logic
local function TDMRP_IsValidCombatKill_ClassFiltered(attacker, victim)
    if not IsValid(attacker) or not attacker:IsPlayer() then return false end
    if not IsValid(victim)   or not victim:IsPlayer()   then return false end
    if attacker == victim then return false end

    local aClass = TDMRP_GetClass(attacker)
    local vClass = TDMRP_GetClass(victim)

    -- Civilians never generate drops (either as killer or victim)
    if not TDMRP_IsCombatClass(aClass) then return false end
    if not TDMRP_IsCombatClass(vClass) then return false end

    -- No rewards for same-class kills
    if aClass == vClass then return false end

    -- Valid matchups based on your design:
    --  Cop ↔ Criminal, Cop ↔ Zombie, Criminal ↔ Zombie
    if aClass == "cop" and (vClass == "criminal" or vClass == "zombie") then
        return true
    end
    if aClass == "criminal" and (vClass == "cop" or vClass == "zombie") then
        return true
    end
    if aClass == "zombie" and (vClass == "cop" or vClass == "criminal") then
        return true
    end

    return false
end

-- Simple fallback: any PvP kill counts (no class logic)
local function TDMRP_IsValidCombatKill_Any(attacker, victim)
    if not IsValid(attacker) or not attacker:IsPlayer() then return false end
    if not IsValid(victim)   or not victim:IsPlayer()   then return false end
    if attacker == victim then return false end
    return true
end

-- Wrapper used by the hook below
local function TDMRP_IsValidCombatKill(attacker, victim)
    if USE_CLASS_FILTER then
        return TDMRP_IsValidCombatKill_ClassFiltered(attacker, victim)
    else
        return TDMRP_IsValidCombatKill_Any(attacker, victim)
    end
end

----------------------------------------
-- Gem / scrap selection
----------------------------------------

local GemTable = {
    { id = "blood_ruby",     kind = "gem"   },
    { id = "blood_sapphire", kind = "gem"   },
    { id = "blood_emerald",  kind = "gem"   },
    { id = "blood_amethyst", kind = "gem"   },
    { id = "blood_diamond",  kind = "gem"   },
    { id = "scrap_metal",    kind = "scrap" },
}

local function RandomGemOrScrap()
    return GemTable[math.random(#GemTable)]
end

----------------------------------------
-- Tier roll for dropped weapons (no Commons)
-- 80% Uncommon (2), 15% Rare (3), 5% Unique (5)
----------------------------------------
local function TDMRP_RollDropTier()
    local r = math.Rand(0, 1)

    if r <= 0.80 then
        return 2 -- Uncommon
    elseif r <= 0.95 then
        return 3 -- Rare
    else
        return 5 -- Unique
    end
end


----------------------------------------
-- Weapon drop table (fill with real classnames)
----------------------------------------

-- Only classes that exist on your server should go here
-- and they should match whatever you configured in the shop.
local TDMRP_WeaponDropTable = {
    { class = "weapon_real_cs_p228",     label = "P228"   },
    { class = "weapon_real_cs_glock18", label = "GLOCK18"   },
    { class = "weapon_real_cs_usp",  label = "USP.45"   },
    { class = "weapon_real_cs_five-seven", label = "FIVE-SEVEN"   },
    { class = "weapon_real_cs_desert_eagle",  label = "DESERT EAGLE"   },
    { class = "weapon_real_cs_tmp",    label = "TMP" },
    { class = "weapon_real_cs_mac10",     label = "MAC10"   },
    { class = "weapon_real_cs_mp5a5", label = "MP5A5"   },
    { class = "weapon_real_cs_p90",  label = "P90"   },
    { class = "weapon_real_cs_ump_45", label = "UMP45"   },
    { class = "weapon_real_cs_famas",  label = "FAMAS"   },
    { class = "weapon_real_cs_galil",    label = "GALIL" },
    { class = "weapon_real_cs_m4a1",     label = "M4A1"   },
    { class = "weapon_real_cs_ak47", label = "AK47"   },
    { class = "weapon_real_cs_aug",  label = "AUG"   },
    { class = "weapon_real_cs_sg552", label = "SG552"   },
    { class = "weapon_real_cs_scout",  label = "SCOUT"   },
    { class = "weapon_real_cs_awp",    label = "AWP" },
    { class = "weapon_real_cs_g3sg1",     label = "G3SG1"   },
    { class = "weapon_real_cs_sg550", label = "SG550"   },
    { class = "weapon_real_cs_pumpshotgun",  label = "BENELLI M3"   },
    { class = "weapon_real_cs_xm1014", label = "BENELLI M4"   },
    { class = "weapon_real_cs_m249",  label = "M249"   },
    { class = "weapon_real_cs_elites",    label = "DUALIES" },
}

local function TDMRP_RandomWeaponClass()
    if #TDMRP_WeaponDropTable == 0 then return nil end
    local def = TDMRP_WeaponDropTable[math.random(#TDMRP_WeaponDropTable)]
    return def.class
end

----------------------------------------
-- Loot orb spawning
----------------------------------------

local function TDMRP_SpawnLootOrb(attacker, pos, lootType, lootSub, amount)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end

    local ent = ents.Create("tdmrp_loot_orb")
    if not IsValid(ent) then return end

    ent:SetPos(pos + Vector(0, 0, 10))
    ent.LootType = lootType
    ent.LootSub  = lootSub or ""
    ent.Amount   = amount or 0

    ent:Spawn()
    ent:Activate()

    if ent.SetupLoot then
        ent:SetupLoot(attacker, lootType, lootSub, amount)
    end
end

----------------------------------------
-- Main death hook
----------------------------------------

hook.Add("PlayerDeath", "TDMRP_KillDrops", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if not IsValid(victim)   or not victim:IsPlayer()   then return end

    if not TDMRP_IsValidCombatKill(attacker, victim) then return end

    local basePos = victim:LocalToWorld(victim:OBBCenter())

    -- 1) Money orb: always on valid kill
    local money = math.random(MONEY_MIN, MONEY_MAX)
    TDMRP_SpawnLootOrb(attacker, basePos, "money", nil, money)

    -- 2) Gem / scrap orb: 5% chance
    if math.Rand(0, 1) <= GEM_DROP_CHANCE then
        local g = RandomGemOrScrap()
        if g.kind == "scrap" then
            -- scrap metal orb (silver + white trail)
            TDMRP_SpawnLootOrb(attacker, basePos, "scrap", nil, 1)
        else
            -- gem orb (colored by gem id)
            TDMRP_SpawnLootOrb(attacker, basePos, "gem", g.id, 1)
        end
    end

     -- 3) Weapon drop: 15% chance (WEAPON_DROP_CHANCE)
    if math.Rand(0, 1) <= WEAPON_DROP_CHANCE then
        local wepClass = TDMRP_RandomWeaponClass()
        if wepClass then
            local tierID = TDMRP_RollDropTier()  -- 2 / 3 / 5

            -- LootType = "weapon", LootSub = weapon class, Amount = tier
            TDMRP_SpawnLootOrb(attacker, basePos, "weapon", wepClass, tierID)
        end
    end
end)

print("[TDMRP] sv_tdmrp_drops.lua loaded (USE_CLASS_FILTER = " .. tostring(USE_CLASS_FILTER) .. ")")
