# Copilot / AI Agent Instructions for TDMRP

Concise guidance for AI coding agents working in this Garry's Mod multiplayer custom darkrp server with an emphasis on team deathmatch set on a hosted server platform called ElixrNode. The server is fundamentally inspired by the original server that has long since been offline called "Bob's TDMRP" but reimagined with new features, mechanics, and a fresh coat of paint.

## Key concepts/acronyms
- **BB's TDMRP**: The name of the custom Garry's Mod DarkRP server being worked on. Stands for "Breach's and Boom's Team Deathmatch Roleplay".
- **TDMRP**: Abbreviation for the gamemode, used in code namespaces and file names.
- **M9K**: A popular Garry's Mod weapon base/addon called "M9K". The server uses a modified version of this addon for its weaponry.
- **tdmrp_m9k_***: The custom weapon class prefix used in TDMRP for all M9K-based weapons. This is distinct from the base `m9k_*` classes.
- **Mixin**: A programming pattern used in TDMRP to inject additional functionality into base weapon classes. Which should always be used for weapon stat modifications, rarity scaling, and modifier effects.
- **Prefix**: A type of weapon modifier applied through crafting that affects weapon stats and behavior. Obtained using emerald gems. Prefixes are limited to changing core weapon stats like damage, rpm, recoil, spread, handling, reload speed, and magazine size.
- **Suffix**: Another type of weapon modifier applied through crafting that often adds special effects or behaviors to weapons. Obtained using sapphire gems. Suffixes can add unique effects like elemental damage, status effects, or special interactions on hit. As a rule, suffixes must change the guns material effects/sounds/visuals and not core stats unless explicitly stated.
- **Gems**: Crafting materials used to apply prefixes/suffixes to weapons. Different gem types correspond to different crafting effects.
- **Active Skills**: Special abilities or powers that players can use in combat, often tied to their chosen job or class.
- **BP**: Breach Points, an in game player stat used for job progression and unlocking new jobs. BP is earned solely through time spent on the server at a rate of 1 BP per minute.
- **DT**: stands for damage threshold, a stat that reduces incoming damage by a flat amount. If a player has 5 DT, they will reduce all incoming damage by 5 points. that means if they have high enough DT they can completely negate small arms fire as well as shotgun pellets. dt is visually constructed on the player HUD as the number of DT followed by an "Armor" name  i.e. "5 DT (Standard Kevlar)
- **Tier/Rarity**: The classification system for weapon quality/rarity in TDMRP which is in addition to any crafted elements. There are 5 tiers/rarities: Common, Uncommon, Rare, Legendary, and Unique. unique tier is reserved for hand-crafted special weapons created by server admins. The rest can be obtained through normal gameplay and crafting. Common tier would be considered a tdmrp_m9k_* weapon with no modifications or stat boosts but its stats are considered the baseline. Higher tiers have progressively better stat scaling applied.
- **Control Points**: Designated areas on the map that teams can capture and hold to earn money and gems over time. Upon a team capturing all points, that team is to be rewarded. This is a core gameplay element for the PvP aspect of TDMRP.
- **Combat Style**: The overall gameplay approach for players on TDMRP, which emphasizes fast-paced PvP combat using a variety of customizable weapons, custom skills per job. Combat style should be aggressive and dynamic, encouraging players to engage in battles for control points and resources. It should also be reminiscent of classic arena shooters with an emphasis on quick reflexes and strategic use of weaponry like Quake and Unreal Tournament.
- **Custom Sounds/Models/Effects**: TDMRP utilizes a variety of custom assets to enhance the gameplay experience. This includes unique weapon sounds, player models, and visual effects that differentiate it from standard DarkRP servers. Custom sound should be arcade gamey and impactful to match the fast-paced combat style. Suggestions for sound,model, and effect style inspirations include classic arena/arcade shooters and action games from the late 90s and early 2000s.
- **Instance**: A data structure representing a specific weapon with its unique stats, rarity, and modifiers. Used for inventory storage and persistence.
- **NWInt/NWString**: Networked variables used to store weapon stats and modifier IDs on the weapon entities.
- **F4 Menu**: The in-game menu accessed by pressing F4, used for inventory management, purchasing weapons, and crafting.
- **ElixrNode**: The hosting platform where the TDMRP server is deployed.
- **DarkRP**: A popular roleplay gamemode for Garry's Mod that TDMRP is based on.
- **SV/CL/SH Prefixes**: File naming conventions indicating Server-only (SV), Client-only (CL), and Shared (SH) code files.
- **HUD**: Heads-Up Display, the in-game interface elements showing player information such as health, ammo, and weapon stats.
- **Difference between job and class**: Jobs are specific roles players can choose (e.g., Police Officer, Thief), while classes are broader categories grouping jobs (e.g., Cop class includes all police-related jobs).
- **Job Progression**: The system by which players can advance through different jobs or ranks within a class, often unlocking new abilities or equipment. This is done by unlocking jobs by hitting certain BP milestones.
- **Events**: Special occurrences or activities on the server that provide unique gameplay experiences, rewards, or challenges for players. Events can be scheduled or spontaneous and often involve community participation. They are yet to be implemented but the concept is generally a map that the server switches to for a limited time where players are subject to a sequential style PvE experience that culminates in a boss battle, upon completion the server admins begin spawning loot and rewards for players to fight over picking up. e.g. server switches to abandoned hospital, players progress thru hospital shooting tougher and tougher zombies, final phase is a boss zombie, players are then teleported to a victory room/area where rewards are distributed as a free for all.
- **Player Markets**: A feature allowing players to buy and sell items, weapons, or resources among themselves. This system is yet to be implemented but the concept generally involves an in-game marketplace where players can list items for sale at set prices, browse listings from other players, and complete transactions using in-game currency. It encourages player interaction and a dynamic economy within the server.
- **Combat Sound Effects**: Audio cues associated with combat actions, the agent must primarily suggest sounds from the Quake games as the original server used these to high affect. These sounds are designed to enhance the immersive experience of fast-paced combat on the TDMRP server. They should be distinct, impactful, and fit the overall arcade-style aesthetic of the server.
- **Player XP**: A system soon to be implemented that tracks player experience points (XP) earned through various activities on the server. The current vision for XP is that it will be a system applicable to only cops and criminals where players earn XP through kills, assists, and capture of control points which are used to level up. As you level up, you gain access to neat little buffs that are useful but can also be fun or cool in some way.



---
## What are we doing here?
This file provides instructions for AI coding agents working on a custom garry's mod DarkRP server called "BB's TDMRP" a custom darkrp server inspired by the original "Bob's TDMRP". The concept of the server is a mix of classic DarkRP roleplay elements with an emphasis on weaponry, weapon customization/guncrafting, and player job/class progression through a tiered weapon system complemented by a complete list of jobs joinable by the player divided in 4 classes but only 3 are implemented as of right now - Civilian, Cop, Criminal, and a soon to be implemented Peacekeeper class. Civilians class jobs are exempt from the team death match aspect, while Cop and Criminal jobs are focused on PvP combat. Peacekeeper classes are to be implemented in the future that can fight both Cop and Criminal jobs as a sort of mediator if either class is winning too hard. Civilian jobs as a whole are intended for people who do not wish to engage in combat but still want to enjoy the roleplay and economy aspects of DarkRP. The server emphasizes fast-paced combat, weapon customization through a gem crafting system, and player progression through earning Breach Points (BP) over time spent on the server. The goal is to create an engaging and dynamic gameplay experience that combines the best elements of DarkRP with innovative features and mechanics. Job progression is tied to BP milestones, unlocking new jobs within each class. The weapon system is built around modified M9K weapons with a unique tier and rarity system, allowing players to customize their loadouts through crafting prefixes and suffixes using gems. The server also features control points for team-based PvP combat, encouraging players to strategize and work together to dominate the map. 

## If you are unsure of the correct approach
Agent must ask for clarification before proceeding.

## ⚠️ CRITICAL: Bind Timer Persistence System (STABLE)

**IMPORTANT FOR ALL FUTURE SESSIONS:**

The bind timer persistence system is FULLY WORKING as of Dec 18, 2025. Before making ANY changes to weapon initialization, inventory, or respawn code, read:

**File:** `/bobs/BIND_SYSTEM_ARCHITECTURE.md` - Complete documentation with testing checklist

**Quick Reference:**
- Bind timers survive: In-session death ✅, Server restart ✅, Job changes ✅
- DO NOT change: Order of `SetPendingInstance()` → `ply:Give()` in spawn_orchestrator.lua
- DO NOT remove: TDMRP_Crafted flag, HUD fallback chain, NWFloat backups
- MUST SET: Both TDMRP_BindExpire AND TDMRP_BindRemaining on weapons
- ALWAYS: Use absolute unix timestamps in JSON, relative seconds in instances

If working on bind/weapon/inventory/respawn systems:
1. Read BIND_SYSTEM_ARCHITECTURE.md first
2. Run the Testing Checklist before deploying
3. Look for ⚠️ comments in code - those mark critical sections
4. Check console for verification logs listed in architecture doc

If you break bind persistence:
- Symptom: Bind shows in-session, disappears after death/restart
- Root cause: Usually wrong order of SetPendingInstance/Give or removed fallback
- Fix: Check the Golden Rules in BIND_SYSTEM_ARCHITECTURE.md

Status: ✅ STABLE - All tests passing, bind timers persistent across all scenarios

## If you are unsure of the correct approach
Agent must ask for clarification before proceeding.
## Creative Direction
Creative direction should be inspired by the original "Bob's TDMRP" server but reimagined with fresh ideas, modern mechanics, and a polished presentation. Agent must ask for clarification if unsure about any aspect of the creative direction or implementation details.
## For any and all creation and modification of lua scripts
- Follow the architecture and coding patterns established in existing TDMRP files.
- Ask clarifying questions if unsure about the correct or intended approach.

## ⚠️ CRITICAL: Reference Folders (DO NOT USE AT RUNTIME)

**The `bob weapons/` folder is REFERENCE ONLY.**

This folder contains the original Bob's TDMRP weapon code for historical reference. It should:
- ❌ NEVER be loaded by the server at runtime
- ❌ NEVER be assumed to exist on the server
- ❌ NEVER be inherited from directly
- ✅ ONLY be used as reference when implementing features
- ✅ If code is needed from it, COPY it into `tdmrp_core/` addon

**All CSS weapons (`weapon_tdmrp_cs_*`) must be completely self-contained within `tdmrp_core/`.**
They must function without the `bob weapons/` folder existing.

---

## ⚠️ CRITICAL: Weapon Architecture

**MANDATORY: All weapon interactions MUST use `tdmrp_m9k_*` class names. NEVER use base `m9k_*` weapons.**

### Only acceptable uses of `m9k_*`:
1. **Registry keys** - `TDMRP.M9KRegistry["m9k_glock"]` for metadata lookup
2. **SWEP inheritance** - `SWEP.Base = "m9k_glock"` in weapon definitions
3. **Internal conversion** - `tdmrp_m9k_*` → `m9k_*` for registry lookup only

### All runtime code MUST use `tdmrp_m9k_*`:
```lua
-- ✅ CORRECT
ply:Give("tdmrp_m9k_glock")
ents.Create("tdmrp_m9k_glock")
ply:HasWeapon("tdmrp_m9k_glock")
item.class = "tdmrp_m9k_glock"
local weapons = {"tdmrp_m9k_glock", "tdmrp_m9k_ak47"}

-- ❌ NEVER DO THIS
ply:Give("m9k_glock")
ents.Create("m9k_glock")
```

**Why:** `tdmrp_m9k_*` weapons have the mixin system with tier scaling. Base `m9k_*` bypasses our entire stat/tier/gem system.

---

## ⚠️ DEFINITIVE WEAPON LIST (63 Total - Only weapons with valid M9K bases)

**CSS Weapons (21) - Class prefix: `weapon_tdmrp_cs_*`**

| Type | Weapons |
|------|---------|
| **Pistols** | glock18, usp, p228, five_seven, elites, desert_eagle |
| **SMGs** | mp5a5, p90, mac10, tmp, ump_45 |
| **Rifles** | ak47, m4a1, aug, famas, sg552, galil |
| **Shotgun** | pumpshotgun |
| **Snipers** | awp, scout |
| **Melee** | knife |

**M9K Weapons (42) - Class prefix: `tdmrp_m9k_*`**
**NOTE: Only these M9K weapons have valid base classes installed**

| Type | Weapons |
|------|---------|
| **Pistols** | colt1911, hk45, m92beretta, sig_p229r, luger |
| **Revolvers** | coltpython, deagle, m29satan, model500, ragingbull, model627 |
| **SMGs** | mp5sd, mp7, thompson, uzi, mp40, mp9, bizonp19 |
| **PDWs** | honeybadger, vector, magpulpdr |
| **Rifles** | an94, fal, g36, l85, m416, scar, tar21, val, ak74, amd65, f2000, g3a3, m16a4_acog, acr |
| **Shotguns** | spas12, 1887winchester, jackhammer |
| **Snipers** | intervention, barret_m82 |
| **LMGs** | m249lmg, m60 |

**⚠️ MISSING BASE CLASSES (DO NOT USE):**
These wrappers exist but their base m9k_* classes are not installed:
glock, mp5, ump45, m4a1, ak47, tec9, mossberg590, ithacam37, striker12, usas, m24, svu, dragunov, pkm

**Full Class Names for Reference:**
```
-- CSS Weapons (21)
weapon_tdmrp_cs_glock18, weapon_tdmrp_cs_usp, weapon_tdmrp_cs_p228,
weapon_tdmrp_cs_five_seven, weapon_tdmrp_cs_elites, weapon_tdmrp_cs_desert_eagle,
weapon_tdmrp_cs_mp5a5, weapon_tdmrp_cs_p90, weapon_tdmrp_cs_mac10,
weapon_tdmrp_cs_tmp, weapon_tdmrp_cs_ump_45, weapon_tdmrp_cs_ak47,
weapon_tdmrp_cs_m4a1, weapon_tdmrp_cs_aug, weapon_tdmrp_cs_famas,
weapon_tdmrp_cs_sg552, weapon_tdmrp_cs_galil, weapon_tdmrp_cs_pumpshotgun,
weapon_tdmrp_cs_awp, weapon_tdmrp_cs_scout, weapon_tdmrp_cs_knife

-- M9K Weapons (42 with valid bases)
tdmrp_m9k_colt1911, tdmrp_m9k_hk45, tdmrp_m9k_m92beretta, tdmrp_m9k_sig_p229r,
tdmrp_m9k_luger, tdmrp_m9k_coltpython, tdmrp_m9k_deagle,
tdmrp_m9k_m29satan, tdmrp_m9k_model500, tdmrp_m9k_ragingbull, tdmrp_m9k_model627,
tdmrp_m9k_mp5sd, tdmrp_m9k_mp7, tdmrp_m9k_thompson,
tdmrp_m9k_uzi, tdmrp_m9k_mp40, tdmrp_m9k_bizonp19, tdmrp_m9k_mp9,
tdmrp_m9k_honeybadger, tdmrp_m9k_vector, tdmrp_m9k_magpulpdr, tdmrp_m9k_an94,
tdmrp_m9k_fal, tdmrp_m9k_g36, tdmrp_m9k_l85, tdmrp_m9k_m416, tdmrp_m9k_scar,
tdmrp_m9k_tar21, tdmrp_m9k_val, tdmrp_m9k_ak74, tdmrp_m9k_amd65, tdmrp_m9k_f2000,
tdmrp_m9k_g3a3, tdmrp_m9k_m16a4_acog, tdmrp_m9k_acr,
tdmrp_m9k_spas12, tdmrp_m9k_1887winchester, tdmrp_m9k_jackhammer,
tdmrp_m9k_intervention, tdmrp_m9k_barret_m82,
tdmrp_m9k_m249lmg, tdmrp_m9k_m60
```

---

## Rarity System

**Always display RARITY NAME, never "Tier N" or "T1":**

| Tier | Rarity | Color |
|------|--------|-------|
| 1 | Common | Gray |
| 2 | Uncommon | Green |
| 3 | Rare | Blue |
| 4 | Legendary | Orange |
| 5 | Unique | Purple/Rainbow (hand-crafted specials) |

Scaling multipliers defined in `TDMRP_WeaponMixin.TierScaling`.

---

## Gem System (Crafting Materials)

Gems are **crafting materials**, not stat boosters:

| Gem | Purpose |
|-----|---------|
| `blood_sapphire` | Roll random **suffix** on weapon |
| `blood_emerald` | Roll random **prefix** on weapon |
| `blood_ruby` | **Salvage** - removes all attributes/bind, refunds gems (sapphire, emerald, amethyst @ 1 per 20min bind time, no refund if <20min) |
| `blood_diamond` | **Duplicate** weapon to inventory |
| `blood_amethyst` | **Bind Time Extension** - increases weapon bind time by 20 minutes per gem |


---

## Prefix/Suffix Crafting

Active system. Example: **"Legendary Sturdy AK-47 of Annihilation"**
- Prefix from emerald crafting
- Suffix from sapphire crafting
- Stored in `inst.craft.prefixId` / `inst.craft.suffixId`

---

## Key Files

| File | Purpose |
|------|---------|
| `sh_tdmrp_m9k_registry.lua` | Weapon metadata, `TDMRP.M9KRegistry`, helper functions |
| `sh_tdmrp_weapon_mixin.lua` | `TDMRP_WeaponMixin.Setup()`, tier scaling, NWInt stats |
| `sh_tdmrp_instances.lua` | Instance system, `BuildInstanceFromSWEP`, `ApplyInstanceToSWEP` |
| `sv_tdmrp_inventory.lua` | Inventory persistence, equip/store/drop handlers |
| `sv_tdmrp_shop.lua` | F4 weapon shop (sells Common tier only) |
| `sv_tdmrp_gemcraft.lua` | Gem crafting logic |
| `cl_tdmrp_weaponhud.lua` | Bottom-right weapon stats HUD |
| `cl_tdmrp_f4_inventory.lua` | F4 inventory UI |

---
## For any interaction with M9K-based weapons, ALWAYS use the `tdmrp_m9k_*` class names. This is non-negotiable. We are to never use base `m9k_*` classes in runtime code. Failure to comply will break weapon stats, tiers, and modifiers.

## Architecture Flow

### Buying from Shop:
1. Client sends buy request for `tdmrp_m9k_*`
2. Server creates weapon via `ply:Give("tdmrp_m9k_*")`
3. Weapon `Initialize()` called
4. `TDMRP_WeaponMixin.Setup(wep)` applies Common tier scaling

### Storing to Inventory:
1. `TDMRP_BuildInstanceFromSWEP(ply, wep)` captures weapon state
2. `TDMRP_InstanceToItem(inst)` converts to inventory format
3. JSON saved to `data/tdmrp/inv/<steamid64>.txt`

### Equipping from Inventory:
1. `ply:Give("tdmrp_m9k_*")` creates weapon (Common default)
2. `TDMRP.ApplyInstanceToSWEP(wep, inst)` sets correct tier
3. Calls `ApplyTierScaling` and `SetNetworkedStats` directly (avoids re-initialize)

### Dropping Weapons:
1. 5-second owner-only pickup window
2. Instance data attached to dropped entity
3. Anyone can pickup after timeout

---

## File Naming

- `sh_` = Shared (server + client)
- `sv_` = Server only
- `cl_` = Client only

---

## Validation Commands

**Server console:**
```
lua_openscript autorun/sh_tdmrp_weapon_mixin.lua
lua_openscript autorun/server/sv_tdmrp_shop.lua
```

**Client console:**
```
lua_openscript_cl autorun/client/cl_tdmrp_weaponhud.lua
```

**In-game testing:**
```
tdmrp_settier 3        -- Set held weapon to Rare
tdmrp_store_current    -- Store held weapon to inventory
```

---

## Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| HUD not showing | `TDMRP.IsM9KWeapon()` returning false | Check weapon class starts with `tdmrp_m9k_` |
| Stats showing 0 | NWInts not set | Ensure `SetNetworkedStats()` called after tier change |
| Tier resets on equip | `Initialize()` called after `ApplyInstanceToSWEP` | Use `ApplyTierScaling` directly, not full `Setup()` |
| Wrong weapon name | Helper function not loaded | Check `AddCSLuaFile()` in shared files |

---

## Modifier System Architecture

TDMRP uses a **Mixin Hook Injection** pattern for weapon customization via the **prefix/suffix crafting system**. The mixin injects hooks into core weapon functions to modify behavior based on the applied prefix/suffix.

### Core Stats

| Stat | Property | Affects | Hook Location |
|------|----------|---------|---------------|
| **Damage** | `Primary.Damage` | Bullet damage | `ShootBullet()` |
| **RPM** | `Primary.RPM` | Fire rate | `PrimaryAttack()` |
| **Spread** | `Primary.Spread` | Hip-fire accuracy | `ShootBulletInformation()` |
| **Recoil** | `Primary.KickUp/Down/Horizontal` | Visual kick | `ShootBullet()` |
| **Handling** | `TDMRP_Handling` | Draw/ADS speed | `Deploy()`, `SetIronsights()` |
| **Reload** | Animation duration modifier | Reload speed | `Reload()` |
| **Magazine** | `Primary.ClipSize` | Ammo capacity | (Static stat) |

### Wrapped M9K Functions

These functions are dynamically wrapped by `TDMRP_WeaponMixin.InstallHooks()`:

| Function | Hooks Available | Purpose |
|----------|-----------------|---------|
| `PrimaryAttack()` | `OnPreFire`, `OnPostFire` | Fire sound, muzzle effects, RPM |
| `ShootBullet()` | `OnBulletFired` | Tracer, damage modification |
| `RicochetCallback()` | `OnBulletHit` | Impact effects, penetration |
| `Deploy()` | `OnDeploy` | Draw speed (handling) |
| `Reload()` | `OnReload` | Reload speed |

### Prefix/Suffix Hook Schema

Prefixes and suffixes are defined in `sh_tdmrp_gemcraft.lua` with optional hook functions:

```lua
TDMRP.Gems.Prefixes["Heavy"] = {
    name = "Heavy",
    stats = {
        damage = 0.12,      -- +12% damage
        magazine = 0.40,    -- +40% magazine
        handling = -0.15,   -- -15% handling
    },
    description = "Increased firepower at the cost of mobility",
    
    -- Optional hook functions:
    GetFireSound = function(wep) return "path/to/heavy_sound.wav" end,
    ModifyDamage = function(wep, baseDamage) return baseDamage * 1.12 end,
    OnDeploy = function(wep) -- Custom deploy behavior end,
}

TDMRP.Gems.Suffixes["of_Burning"] = {
    tier = 1,
    name = "of Burning",
    effect = "burning",
    description = "Targets catch fire - damage over time",
    stats = { damage = 0.08 },
    
    -- Optional hook functions:
    OnBulletHit = function(wep, tr, dmginfo)
        if tr.Entity and tr.Entity:IsPlayer() then
            tr.Entity:Ignite(5) -- Set target on fire
        end
    end,
}
```

### Instance Storage

Prefix/suffix IDs persist in weapon instances via NWStrings:

```lua
wep:GetNWString("TDMRP_PrefixID", "")  -- e.g., "Heavy"
wep:GetNWString("TDMRP_SuffixID", "")  -- e.g., "of_Burning"
```

### Adding New Hooks to Prefixes/Suffixes

1. Add hook function to prefix/suffix definition in `sh_tdmrp_gemcraft.lua`
2. Hooks auto-integrate via `RunModifierHook()` calls in wrapped functions
3. Prefixes/suffixes are applied via F4 crafting menu (emerald/sapphire gems)

### Key Modifier Files

| File | Purpose |
|------|---------|
| `sh_tdmrp_weapon_mixin.lua` | Hook installation, `RunModifierHook()` |
| `sh_tdmrp_gemcraft.lua` | Prefix/suffix definitions |
| `sv_tdmrp_gemcraft.lua` | Crafting logic, `ApplyPrefixStatMods()` |
| `sh_tdmrp_instances.lua` | Prefix/suffix persistence via NWStrings |

---

## Notes for AI Edits

- **Always use `tdmrp_m9k_*`** - This is non-negotiable, m9k_* breaks everything
- **Display rarity names** - "Legendary" not "Tier 4" or "T4"
- **Respect modifier architecture** - New weapon behaviors go through modifier system, not per-weapon overrides
- Keep edits minimal and follow `sh_/sv_/cl_` naming
- Add debug prints sparingly: `[TDMRP] FunctionName: key=value`

---

## Session Summary: Inventory System Overhaul (Dec 18, 2025)

### Overview
Comprehensive system audit and implementation of 14+ critical fixes across the TDMRP inventory, instance, and UI systems. All changes focused on data integrity, network synchronization, and user-facing improvements.

### Critical Fixes Implemented

#### 1. Inventory Persistence & Reliability (sv_tdmrp_inventory.lua)
- **CONFIG Block**: MAX_SLOTS (30), WEAPON_DESPAWN_TIME (300s), AUTO_BACKUP_DIR
- **Validation**: `ValidateWeaponClass()` prevents invalid weapon equip/drop
- **Capacity Warnings**: `CheckInventoryCapacity()` alerts players at 80%+ full
- **Corruption Recovery**: Automated backup/restore with `data/tdmrp/inv_backups/` directory
- **Slot Mapping**: `BuildSlotMap()` + `GetItemIDFromSlot()` ensure consistent ordering across server restarts
- **Despawn Timer**: World weapons cleanup after 5 minutes with owner-only pickup window
- **Crash Safety**: `pcall` wrapping in `TDMRP_InventoryEquip` and `TDMRP_InventoryDrop` prevents cascade failures

#### 2. Network Format Enhancement (SendNewInventoryFormat)
Server sends full item data to client including:
- `prefixId`, `suffixId` - Crafted modifier IDs
- `amethyst` - Bind time extension gem count
- `handling` - Draw/ADS speed stat
- `bound_until` - Bind timer Unix timestamp
- `cosmetic.name` - Custom weapon cosmetic name
- `version` - Instance format version for future migrations

#### 3. Instance Versioning (sh_tdmrp_instances.lua)
- **INSTANCE_VERSION = 1** constant defined
- **Version Field**: Added to all instances via `BuildInstanceFromSWEP()`
- **Migration Function**: `MigrateInstance()` handles format changes for future versions
- **Forward Compatibility**: `ItemToInstance()` preserves version on conversion

#### 4. Bind Timer Synchronization
- **New Helper**: `TDMRP.SendBindUpdateToPlayer()` in sv_tdmrp_gemcraft.lua
- **Real-time Sync**: `AddBindTime()` (sv_tdmrp_binding.lua) calls sync after bind changes
- **Persistent TestBindWeapons**: Stores prefix/suffix data for crafted weapons across respawns
- **Penalty Logging**: RestoreBoundWeapons() logs all penalty application with timestamps

#### 5. Client-Side UI Improvements (cl_tdmrp_f4_inventory.lua)

**Rarity Display Standards:**
- COMMON (Tier 1) - Gray, badge shows "C"
- UNCOMMON (Tier 2) - Green, badge shows "U"
- RARE (Tier 3) - Blue, badge shows "R"
- LEGENDARY (Tier 4) - Gold, badge shows "L"
- UNIQUE (Tier 5) - Purple, badge shows "★"

**New UI Features:**
- Rarity names displayed instead of "TIER X" throughout inventory
- Full weapon names with prefix/suffix (e.g., "Heavy AK-47 of Burning")
- Bind timer countdown display (e.g., "⏱ BOUND: 15m 30s")
- Cosmetic name display in quotes
- Handling stat added to stats panel
- Amethyst gem color (Purple #9B59B6) added to gem displays
- Crafted indicator (★) shows for weapons with modifiers
- Bind clock icon (⏱) on slot view for bound weapons
- Enhanced gem descriptions (Suffix/Prefix/Salvage/Duplicate/+20m)

**New Helper Functions:**
- `GetBindTimeRemaining()` - Formats countdown as "15h 30m" or "45m 30s" or "30s"
- `RARITY_NAMES` table - Maps tier → display name
- `RARITY_SHORT` table - Maps tier → single-letter badge code

#### 6. Gem System Consistency
- Added amethyst color to `sh_tdmrp_ui_theme.lua`: `Color(155, 89, 182, 255)`
- All 5 gem types now properly colored and described throughout UI
- Gem dots correctly display on inventory slots

### Network Strings Verified
- `TDMRP_InventoryData` - Full inventory sync with enhanced format ✅
- `TDMRP_InventoryUpdate` - Incremental updates with new fields ✅
- `TDMRP_InventoryEquip` - Equip request with validation ✅
- `TDMRP_InventoryDrop` - Drop request with despawn timer ✅
- `TDMRP_InventoryStore` - Store equipped weapon ✅
- `TDMRP_RequestInventory` - Refresh request ✅

### Testing & Verification
- **Lua Syntax**: All modified files verified error-free ✅
  - sv_tdmrp_inventory.lua
  - sh_tdmrp_instances.lua
  - cl_tdmrp_f4_inventory.lua
  - sh_tdmrp_weapon_mixin.lua
  - sv_tdmrp_gemcraft.lua
  - sv_tdmrp_binding.lua
  - sh_tdmrp_ui_theme.lua

### Files Modified (Summary)
1. **sv_tdmrp_inventory.lua** - 7 major edits (CONFIG, helpers, validation, crash-safety)
2. **sh_tdmrp_instances.lua** - Version field + migration system
3. **cl_tdmrp_f4_inventory.lua** - Complete UI overhaul with rarity display
4. **sh_tdmrp_weapon_mixin.lua** - Pending instance timeout (2s → 5s)
5. **sv_tdmrp_gemcraft.lua** - Added `SendBindUpdateToPlayer()` helper
6. **sv_tdmrp_binding.lua** - Bind sync calls integrated
7. **sh_tdmrp_ui_theme.lua** - Added amethyst gem color

### Important Patterns Established

**For Future Inventory Work:**
- Always check `ValidateWeaponClass()` before giving weapons
- Use `BuildSlotMap()` for consistent ordering, never raw item table iteration
- Wrap all player actions in `pcall()` with descriptive error messages
- Call `TDMRP_SaveInventory()` before AND after modifying inventories
- Use rarity names (COMMON/UNCOMMON/RARE/LEGENDARY/UNIQUE) in all UIs

**For Future Network Updates:**
- Keep enhanced format fields in `SendNewInventoryFormat()` for client sync
- Use `GetBindTimeRemaining()` helper for all bind timer displays
- Apply version migration in `ItemToInstance()` for backwards compatibility
- Preserve cosmetic names and prefix/suffix IDs through all conversions

**For Future Crafting Work:**
- Always call `TDMRP.SendBindUpdateToPlayer()` after bind changes
- Log all penalty applications with timestamps
- Update `TestBindWeapons` immediately after weapon modifications
- Store full instance data including `craft` metadata

### Known Working Integrations
- Spawn orchestrator penalty logging: ✅ Comprehensive with timestamps
- Gem crafting bind system: ✅ Synced with full data persistence
- Weapon drop/pickup: ✅ Despawn timer + instance attachment verified
- F4 inventory UI: ✅ Displays all new fields with proper formatting
- Instance versioning: ✅ Migration-ready for future changes

### Next Priority Areas (For Future Sessions)
1. Weapon modification UI (display prefix/suffix effects in shop/HUD)
2. Crafting success/failure feedback system
3. Bind time extension notification on amethyst use
4. Cosmetic preview in inventory
5. Weapon comparison system for shop

---

## Session 2: Bind Status Persistence Fix (Dec 18, 2025)

### Problem Fixed
Bind status was not persisting across deaths, job changes, and inventory storage/loading cycles.

### Root Cause
`bound_until` was stored as relative remaining seconds in JSON, which became stale after server restarts.

### Solution: Absolute Timestamp for JSON

- **JSON (persistent)**: Store as `os.time()` (absolute unix timestamp)
- **Instance (runtime)**: Work with relative remaining seconds  
- **Network (transit)**: Send remaining seconds to client
- **NWFloat (entity)**: Use CurTime() + remaining

#### Implementation

**BuildInstanceFromSWEP**: `inst.bound_until = os.time() + remaining` (convert to absolute)

**ItemToInstance**: `remaining = inst.bound_until - os.time()` (convert to relative)

**SendNewInventoryFormat**: Check expiration and send remaining seconds

**ApplyInstanceToSWEP**: `NWFloat = CurTime() + remaining` (apply to entity)

### Files Modified
- `sh_tdmrp_instances.lua` (3 edits)
- `sv_tdmrp_inventory.lua` (1 edit)

### Result
✅ Bind timers survive server restarts, deaths, job changes, and inventory cycles
