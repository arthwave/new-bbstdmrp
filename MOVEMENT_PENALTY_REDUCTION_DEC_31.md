# Movement Penalty Reduction - Dec 31, 2025

## Overview
Reduced all weapon movement/running spread penalties by 50% across both M9K and CSS weapon systems to improve gameplay feel and reduce excessive bloom while maintaining some accuracy penalty.

---

## Changes Made

### 1. Global Penalty Scale (sh_tdmrp_accuracy.lua)

**Added new config parameter:**
```lua
movementPenaltyScale = 0.5  -- 50% reduction in all movement penalties
```

**How it works:**
- Formula: `1 + (penalty - 1) * scale`
- Example: 5x penalty becomes `1 + (5-1)*0.5 = 3x` (50% reduction)
- Applies to ALL weapons (M9K and CSS) automatically
- Also scales extra penalties beyond walk threshold

### 2. M9K Weapon Integration

**Already integrated via sh_tdmrp_weapon_mixin.lua:**
- M9K weapons call `TDMRP.Accuracy.GetMovementMultiplier()`
- Mixin applies multiplier to spread before firing
- No changes needed - works automatically with new scale

### 3. CSS Weapon Integration (weapon_real_base/shared.lua)

**Modified `RecoilPower()` function:**
```lua
-- Apply TDMRP accuracy system if available
if TDMRP and TDMRP.Accuracy and TDMRP.Accuracy.GetCurrentSpread then
    cone = TDMRP.Accuracy.GetCurrentSpread(self.Owner, self)
end
```

**Before:** CSS weapons used their own hardcoded movement checks  
**After:** CSS weapons now use the same TDMRP.Accuracy system as M9K weapons

---

## Example Penalty Reductions

| Weapon Type | Old Penalty | New Penalty | Reduction |
|-------------|-------------|-------------|-----------|
| **Normal Guns** (default) | 5x | 3x | 40% |
| **Pistols** (3.0-3.8x) | 3.5x avg | 2.25x avg | ~36% |
| **SMGs** (2.2-3.8x) | 2.8x avg | 1.9x avg | ~32% |
| **Assault Rifles** (4.0-5.5x) | 4.5x avg | 2.75x avg | ~39% |
| **Snipers** (default) | 15x | 8x | ~47% |
| **LMGs** (7.0-10.0x) | 8x avg | 4.5x avg | ~44% |

---

## Per-Weapon Examples

### Pistols
- **Glock** (movePenalty: 3.0): 3.0x → **2.0x**
- **Deagle** (movePenalty: 5.5): 5.5x → **3.25x**
- **Colt Python** (movePenalty: 4.5): 4.5x → **2.75x**

### SMGs
- **MP5** (movePenalty: 2.5): 2.5x → **1.75x**
- **MP7** (movePenalty: 2.2): 2.2x → **1.6x**
- **P90** (movePenalty: 2.3): 2.3x → **1.65x**

### Assault Rifles
- **AK-47** (movePenalty: 4.8): 4.8x → **2.9x**
- **M4A1** (movePenalty: 4.2): 4.2x → **2.6x**
- **SCAR** (movePenalty: 4.5): 4.5x → **2.75x**

### Snipers
- **AWP** (movePenalty: 9.0): 9.0x → **5.0x**
- **Scout** (movePenalty: 5.5): 5.5x → **3.25x**
- **Intervention** (movePenalty: 10.0): 10.0x → **5.5x**

---

## Technical Details

### Files Modified
1. **sh_tdmrp_accuracy.lua** (lines ~13-20, ~570-635)
   - Added `movementPenaltyScale` config parameter
   - Modified `GetMovementMultiplier()` to apply global scale
   - Scales both base penalties and "beyond threshold" penalties

2. **weapon_real_base/shared.lua** (lines ~296-346)
   - Modified `RecoilPower()` to use `TDMRP.Accuracy.GetCurrentSpread()`
   - CSS weapons now integrate with unified accuracy system

### Integration Points

**M9K Weapons:**
- `sh_tdmrp_weapon_mixin.lua` → `GetSpreadMultiplier()` → calls `TDMRP.Accuracy.GetMovementMultiplier()`
- Applied in `ShootBulletInformation()` hook before bullet fires

**CSS Weapons:**
- `weapon_real_base/shared.lua` → `RecoilPower()` → calls `TDMRP.Accuracy.GetCurrentSpread()`
- Applied to `cone` parameter before `CSShootBullet()`

---

## Adjusting the Scale

To change the penalty reduction, edit `sh_tdmrp_accuracy.lua`:

```lua
TDMRP.Accuracy.Config = {
    movementPenaltyScale = 0.5,  -- Change this value:
    -- 0.0 = No penalty (unrealistic)
    -- 0.25 = 75% reduction
    -- 0.5 = 50% reduction (CURRENT)
    -- 0.75 = 25% reduction
    -- 1.0 = No reduction (original penalties)
```

---

## Testing Checklist

- [x] M9K pistols have reduced bloom when moving
- [x] M9K rifles have reduced bloom when moving
- [x] M9K snipers still have significant penalty but less severe
- [x] CSS weapons (M4A1, AK-47, AWP, etc.) use same penalty system
- [x] Crosshair reflects new spread values correctly
- [x] Standing still accuracy unchanged
- [x] ADS accuracy bonus still applies

---

## Compatibility

✅ **Works with existing systems:**
- Tier/rarity scaling
- Prefix/suffix modifiers
- Stability stat from suffixes (stacks with penalty reduction)
- Crosshair bloom visualization
- Iron sights accuracy bonus

✅ **No breaking changes:**
- Per-weapon `movePenalty` values still used (just scaled down)
- Weapon stats table unchanged
- All 52 configured weapons work with new system

---

## Notes

- Standing still accuracy is **unchanged** (no penalty to reduce)
- Sniper "still bonus" (0.1x laser accuracy) is **unchanged**
- ADS (iron sights) accuracy bonus still applies on top of movement penalty
- Crouching benefits unchanged
- In-air penalties unchanged (handled separately in CSS weapons)

The system now provides a more forgiving shooting experience while still maintaining meaningful accuracy differences between weapon types and movement states.
