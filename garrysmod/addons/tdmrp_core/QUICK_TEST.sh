#!/usr/bin/env bash
# Quick Test Script - Gem Crafting System
# Copy-paste these commands into your server console

echo "=== TDMRP Gem Crafting - Quick Test Setup ==="

# Step 1: Give yourself gems
echo "[1/3] Giving gems..."
echo 'lua_run LocalPlayer():ConCommand("tdmrp_givegem blood_emerald 10")'
echo 'lua_run LocalPlayer():ConCommand("tdmrp_givegem blood_sapphire 10")'

# Step 2: Equip a gun (player must do manually)
echo "[2/3] Player must hold a valid TDMRP weapon"

# Step 3: Test crafting via F4 menu
echo "[3/3] Open F4 menu → Crafting tab → Open Crafter"
echo ""
echo "=== Console Commands for Testing ==="
echo ""
echo "# Give gems (replace X with quantity)"
echo "tdmrp_givegem blood_emerald 5"
echo "tdmrp_givegem blood_sapphire 5"
echo ""
echo "# Craft a weapon (hold weapon first, replace 'heavy' with prefix name)"
echo "tdmrp_craft heavy"
echo "tdmrp_craft light"
echo "tdmrp_craft precision"
echo "tdmrp_craft piercing"
echo ""
echo "# Available prefixes per tier:"
echo "# Tier 1: heavy, light, precision, aggressive, steady"
echo "# Tier 2: piercing, blazing, toxic, swift, reinforced"
echo "# Tier 3: shattering, tempest, venom, phantom, colossus"
echo "# Tier 4: cataclysm, velocity, plague, wraith, titan"
echo "# Tier 5: apocalypse, transcendence, oblivion, eternity, ascension"
echo ""
echo "=== What to Check ==="
echo ""
echo "✓ Gems appear in inventory after givegem"
echo "✓ F4 Crafting tab opens without errors"
echo "✓ Weapon model shows in crafter UI"
echo "✓ Prefixes display with stat modifiers"
echo "✓ Suffixes list shows 5 options"
echo "✓ Stats preview updates when prefix selected"
echo "✓ Craft button triggers net message"
echo "✓ Gems consumed from inventory on craft"
echo "✓ Weapon stats updated with prefix modifiers"
echo "✓ Chat shows success message"
echo "✓ HUD shows 'Unbound' at top"
echo ""
