# Gem Crafting System - Testing Guide

## Quick Start

### 1. Server Console - Give Yourself Gems

```
tdmrp_givegem blood_emerald 5
tdmrp_givegem blood_sapphire 5
```

### 2. In-Game - Access Crafting Menu

**Method A: Via F4 Menu**
- Press `F4` to open the main menu
- Click the "Crafting" tab
- Hold any TDMRP weapon and click "Open Crafter"

**Method B: Console Command (once implemented)**
- Hold a weapon and type: `tdmrp_gemcraft` in console

### 3. In the Crafting Menu

1. **Select Prefix (Emerald)**
   - Green buttons show all emerald prefixes for your weapon's tier
   - Hover to see stat modifiers (+12% damage, -15% handling, etc.)
   - Click to select

2. **View Suffixes (Sapphire)**
   - Listed on the right side
   - 5 different suffixes available for your weapon's tier
   - One will be randomly selected on craft

3. **Confirm & Craft**
   - Verify gem costs (1 Emerald + 1 Sapphire)
   - Check money cost (scales by tier: $5K-$25K)
   - Click "Craft Weapon"

4. **Post-Craft**
   - Weapon is now locked as "Crafted"
   - Prefix stats are applied permanently
   - Suffix is random
   - Weapon display name updates with prefix + suffix + tier

---

## What to Test

### ✅ Core Crafting Flow
- [ ] Open F4 → Crafting tab loads
- [ ] Click "Open Crafter" with weapon selected
- [ ] Crafting menu opens with weapon preview
- [ ] Prefixes display correctly with stat modifiers
- [ ] Suffixes display for correct tier
- [ ] Gem counts update correctly

### ✅ Validation & Errors
- [ ] Error if no weapon held when opening crafter
- [ ] Error if weapon is not a TDMRP gun
- [ ] Error if insufficient gems (need 1 emerald + 1 sapphire)
- [ ] Error if insufficient money for tier cost
- [ ] Error if weapon already crafted (should suggest Ruby reset)

### ✅ Crafting Execution
- [ ] Prefixes selected apply correct stat modifiers
- [ ] Sapphire suffix randomly selected (not player choice yet)
- [ ] Weapon marked as "TDMRP_Crafted" (true)
- [ ] Gems consumed from inventory on craft
- [ ] Player sees success chat message with prefix+suffix

### ✅ HUD Display
- [ ] Weapon HUD panel shows at bottom-right when holding TDMRP weapon
- [ ] Bind time displays as "Unbound" if not bound
- [ ] Stats show with + modifiers applied
- [ ] Weapon name updates to show crafted status

### ✅ Inventory Sync
- [ ] Crafted weapon can be picked up from ground (weapon pickup)
- [ ] Stats persist when pulling from inventory
- [ ] Crafted metadata preserved on drop/pickup cycle

---

## Tier System

| Tier | Name | Common Cost | Example Prefixes |
|------|------|-------------|------------------|
| 1 | Common | $5,000 | Heavy, Light, Precision |
| 2 | Uncommon | $7,500 | Piercing, Blazing, Toxic |
| 3 | Rare | $10,000 | Shattering, Tempest, Venom |
| 4 | Epic | $15,000 | Cataclysm, Velocity, Plague |
| 5 | Legendary | $25,000 | Apocalypse, Transcendence, Oblivion |

---

## Debug Commands

### Give Gems
```
tdmrp_givegem blood_emerald <amount>
tdmrp_givegem blood_sapphire <amount>
tdmrp_givegem blood_ruby <amount>       (for reset - future)
tdmrp_givegem blood_amethyst <amount>   (for bind - future)
tdmrp_givegem blood_diamond <amount>    (for dupe - future)
```

### Craft Weapon (Console)
```
tdmrp_craft <prefix_id>
```
Example: `tdmrp_craft heavy`

Will craft your currently held weapon with the specified prefix.
Requires 1 Emerald + 1 Sapphire in inventory.

---

## Known Limitations (Phase 1)

- ❌ Suffix selection not available (random on craft)
- ❌ Suffix effects not implemented (gameplay part)
- ❌ Ruby (reset) not implemented
- ❌ Amethyst (bind) not implemented  
- ❌ Diamond (dupe) not implemented
- ❌ Weapon name customization not in UI
- ❌ Material cosmetics not in UI

---

## File Structure

```
lua/autorun/
├── sh_tdmrp_gemcraft.lua          (Shared: Gem definitions)
├── server/
│   └── sv_tdmrp_gemcraft.lua      (Server: Crafting logic)
└── client/
    ├── cl_tdmrp_gemcraft.lua      (Client: Crafting UI)
    ├── cl_tdmrp_f4.lua            (Updated: Crafting tab)
    └── cl_tdmrp_hud.lua           (Updated: Bind time display)
```

---

## Expected Chat Messages

**Success:**
```
[TDMRP] Crafted Desert Eagle of Burning (prefix: heavy, suffix: burning).
```

**Failure Examples:**
```
[TDMRP] You must be holding a weapon.
[TDMRP] This weapon cannot be modified.
[TDMRP] You need 1 Blood Emerald and 1 Blood Sapphire.
[TDMRP] You don't have enough money ($15000).
[TDMRP] This weapon is already crafted. Use a Blood Ruby to reset it.
```

---

## Next Steps (Phase 2)

1. **Implement Suffix Effects**
   - Burning: Apply fire damage over time
   - Freezing: Slow enemy movement
   - Piercing: Bypass armor
   - Stunning: Chance to stun
   - Etc.

2. **Post-Craft Gems**
   - Ruby: Reset weapon to uncrafted (costs money)
   - Amethyst: Bind weapon (20 min per gem, show countdown on HUD)
   - Diamond: Duplicate weapon (clone current stats)

3. **UI Enhancements**
   - Suffix selection (currently random)
   - Weapon name customization
   - Material cosmetic selection
   - Preview of suffix effects

4. **Sound System**
   - Suffix-specific sound effects
   - Crafting completion sounds
   - Error notification sounds

---

## Troubleshooting

### Crafting menu doesn't open
- Make sure you're holding a TDMRP weapon
- Check server console for errors with `tdmrp_craft` command
- Verify `cl_tdmrp_gemcraft.lua` is loaded (check console on game start)

### Gems not consumed
- Check server console for "Craft failed" messages
- Verify inventory sync working (try using inventory tab first)
- Make sure gems are type "gem" in inventory, not "scrap"

### Stats not updating on weapon
- Confirm weapon has NW variables set (`TDMRP_Damage`, `TDMRP_RPM`, etc.)
- Check that prefix stats are actually being applied (server console print)
- Verify base weapon stats aren't zero

### Bind time not showing
- Requires `TDMRP_BindUntil` NW float to be set on weapon
- Amethyst binding not yet implemented (Phase 2)

---

**Last Updated:** Phase 1 Implementation
**Status:** Ready for in-game testing
