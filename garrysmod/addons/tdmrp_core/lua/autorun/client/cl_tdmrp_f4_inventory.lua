----------------------------------------------------
-- TDMRP F4 Menu - Inventory Tab
-- Grid inventory with full instance preservation
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.F4Menu = TDMRP.F4Menu or {}
TDMRP.Inventory = TDMRP.Inventory or {}

----------------------------------------------------
-- Inventory Configuration
----------------------------------------------------

local Config = {
    slotSize = 70,
    slotPadding = 6,
    maxSlots = 30, -- 6x5 grid
    cols = 6,
}

----------------------------------------------------
-- State
----------------------------------------------------

local scrollOffset = 0
local maxScroll = 0
local hoveredSlot = nil
local selectedSlot = nil
local dragSlot = nil
local dragOffset = { x = 0, y = 0 }
local contextMenuOpen = false
local contextMenuPos = { x = 0, y = 0 }
local contextMenuSlot = nil
local lastClickTime = 0

----------------------------------------------------
-- Local inventory cache (synced from server)
----------------------------------------------------

TDMRP.Inventory.Items = TDMRP.Inventory.Items or {}

----------------------------------------------------
-- 3D Weapon Model Rendering (for details panel)
----------------------------------------------------

local modelPanels = {}  -- Cache of model panels
local modelContainer = nil
local lastDisplayedClass = nil  -- Track which weapon model is currently displayed

local function GetWeaponWorldModel(class)
    -- First try: Get from actual weapon entity in player inventory
    local ply = LocalPlayer()
    if IsValid(ply) then
        for _, wep in ipairs(ply:GetWeapons()) do
            if wep:GetClass() == class then
                local model = wep:GetModel()
                if model and model ~= "" and util.IsValidModel(model) then
                    return model
                end
            end
        end
    end
    
    -- Second try: Strip all prefixes and look in registry
    local baseClass = class:gsub("^tdmrp_", ""):gsub("^m9k_", "")
    
    if TDMRP.M9KRegistry then
        -- Try with base name
        if TDMRP.M9KRegistry[baseClass] then
            local meta = TDMRP.M9KRegistry[baseClass]
            if meta.worldModel and util.IsValidModel(meta.worldModel) then
                return meta.worldModel
            end
        end
        
        -- Try with m9k_ prefix
        local m9kName = "m9k_" .. baseClass
        if TDMRP.M9KRegistry[m9kName] then
            local meta = TDMRP.M9KRegistry[m9kName]
            if meta.worldModel and util.IsValidModel(meta.worldModel) then
                return meta.worldModel
            end
        end
    end
    
    -- Third try: Standard weapons.GetStored with base class
    local baseWepInfo = weapons and weapons.GetStored and weapons.GetStored("m9k_" .. baseClass)
    if baseWepInfo and baseWepInfo.WorldModel then
        if util.IsValidModel(baseWepInfo.WorldModel) then
            return baseWepInfo.WorldModel
        end
    end
    
    -- Last resort fallback
    return "models/weapons/w_pist_p228.mdl"
end

local function GetOrCreateInventoryModelPanel(class, x, y, size)
    local cacheKey = class .. "_" .. size
    
    if IsValid(modelPanels[cacheKey]) then
        local panel = modelPanels[cacheKey]
        panel:SetPos(x, y)
        panel:SetVisible(true)
        return panel
    end
    
    -- Create container if needed (parent to F4 menu)
    local menuPanel = TDMRP.F4Menu.GetPanel()
    if not IsValid(menuPanel) then return nil end
    
    if not IsValid(modelContainer) then
        modelContainer = vgui.Create("DPanel", menuPanel)
        modelContainer:SetPos(0, 0)
        modelContainer:SetSize(ScrW(), ScrH())
        modelContainer:SetMouseInputEnabled(false)
        modelContainer:SetKeyboardInputEnabled(false)
        modelContainer.Paint = function() end
    end
    
    -- Create model panel
    local panel = vgui.Create("DModelPanel", modelContainer)
    panel:SetPos(x, y)
    panel:SetSize(size, size)
    panel:SetModel(GetWeaponWorldModel(class))
    panel:SetFOV(50)
    -- Zoomed out 30%: increased distance from 30 to ~40, centered at origin
    panel:SetCamPos(Vector(40, 0, 0))
    panel:SetLookAt(Vector(0, 0, 0))
    panel:SetMouseInputEnabled(false)
    
    -- STATIC ANGLE - no rotation for inventory preview
    panel.LayoutEntity = function(self, ent)
        if IsValid(ent) then
            ent:SetAngles(Angle(0, 45, 0))  -- Fixed 45 degree angle
        end
    end
    
    modelPanels[cacheKey] = panel
    return panel
end

local function ClearInventoryModelPanels()
    for _, panel in pairs(modelPanels) do
        if IsValid(panel) then
            panel:Remove()
        end
    end
    modelPanels = {}
    lastDisplayedClass = nil
end

local function RenderInventoryWeaponModel(x, y, w, h, class)
    if not class or class == "" then return end
    
    -- Clear old models if switching weapons
    if lastDisplayedClass ~= class then
        ClearInventoryModelPanels()
        lastDisplayedClass = class
    end
    
    -- Draw background
    draw.RoundedBox(6, x, y, w, h, Color(13, 13, 13, 255))
    
    local modelSize = math.min(w - 20, h - 20)
    local modelX = x + (w - modelSize) / 2
    local modelY = y + (h - modelSize) / 2
    
    local panel = GetOrCreateInventoryModelPanel(class, modelX, modelY, modelSize)
    if IsValid(panel) then
        panel:SetAlpha(255)
        panel:SetVisible(true)
    end
end

----------------------------------------------------
-- Paint Function
----------------------------------------------------

local function PaintInventory(x, y, w, h, alpha, mx, my, scroll)
    local C = TDMRP.UI.Colors
    local ply = LocalPlayer()
    
    -- Header
    draw.SimpleText("INVENTORY", "TDMRP_Header", x + 20, y + 12, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    local itemCount = table.Count(TDMRP.Inventory.Items)
    draw.SimpleText(itemCount .. "/" .. Config.maxSlots .. " items", "TDMRP_Body", x + w - 25, y + 15, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    
    -- Grid area
    local gridX = x + 20
    local gridY = y + 55
    local gridW = Config.cols * (Config.slotSize + Config.slotPadding) - Config.slotPadding
    local gridH = h - 70
    
    -- Grid background
    draw.RoundedBox(6, gridX - 10, gridY - 10, gridW + 20, gridH + 10, ColorAlpha(C.bg_dark, alpha))
    
    -- Draw slots
    hoveredSlot = nil
    
    local rows = math.ceil(Config.maxSlots / Config.cols)
    local totalHeight = rows * (Config.slotSize + Config.slotPadding)
    maxScroll = math.max(0, totalHeight - gridH)
    
    for slot = 1, Config.maxSlots do
        local row = math.floor((slot - 1) / Config.cols)
        local col = (slot - 1) % Config.cols
        
        local slotX = gridX + col * (Config.slotSize + Config.slotPadding)
        local slotY = gridY + row * (Config.slotSize + Config.slotPadding) - scrollOffset
        
        -- Only draw if on screen
        if slotY + Config.slotSize >= gridY and slotY <= gridY + gridH then
            local item = TDMRP.Inventory.Items[slot]
            local isHovered = mx >= slotX and mx <= slotX + Config.slotSize and my >= slotY and my <= slotY + Config.slotSize and my >= gridY and my <= gridY + gridH
            local isSelected = (slot == selectedSlot)
            local isDragging = (slot == dragSlot)
            
            if isHovered and not isDragging then
                hoveredSlot = slot
            end
            
            -- Slot background
            local slotBg = C.bg_light
            if isSelected then
                slotBg = C.accent_dark
            elseif isHovered and not dragSlot then
                slotBg = C.bg_hover
            elseif dragSlot and isHovered then
                slotBg = Color(60, 100, 60) -- Drop target indicator
            end
            
            if not isDragging then
                draw.RoundedBox(4, slotX, slotY, Config.slotSize, Config.slotSize, ColorAlpha(slotBg, alpha))
            end
            
            -- Draw item if exists
            if item and not isDragging then
                DrawInventoryItem(slotX, slotY, Config.slotSize, item, alpha, C, isHovered)
            end
            
            -- Selection outline
            if isSelected and not isDragging then
                surface.SetDrawColor(ColorAlpha(C.accent, alpha))
                surface.DrawOutlinedRect(slotX, slotY, Config.slotSize, Config.slotSize, 2)
            end
        end
    end
    
    -- Draw dragged item
    if dragSlot and TDMRP.Inventory.Items[dragSlot] then
        local item = TDMRP.Inventory.Items[dragSlot]
        local dragX = mx - dragOffset.x
        local dragY = my - dragOffset.y
        
        draw.RoundedBox(4, dragX, dragY, Config.slotSize, Config.slotSize, ColorAlpha(C.bg_hover, alpha * 0.9))
        DrawInventoryItem(dragX, dragY, Config.slotSize, item, alpha * 0.9, C, false)
    end
    
    -- Right panel: Item details
    local detailX = gridX + gridW + 25
    local detailW = w - detailX - 10 + x
    local detailY = gridY - 10
    local detailH = gridH + 10
    
    draw.RoundedBox(6, detailX, detailY, detailW, detailH, ColorAlpha(C.bg_dark, alpha))
    
    local displaySlot = hoveredSlot or selectedSlot
    local displayItem = displaySlot and TDMRP.Inventory.Items[displaySlot]
    
    if displayItem then
        DrawItemDetails(detailX, detailY, detailW, detailH, displayItem, alpha, C)
    else
        draw.SimpleText("Select or hover an item", "TDMRP_Body", detailX + detailW/2, detailY + detailH/2, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Context menu
    if contextMenuOpen and contextMenuSlot then
        DrawContextMenu(contextMenuPos.x, contextMenuPos.y, alpha, mx, my, C)
    end
    
    -- Action buttons (bottom)
    local btnY = y + h - 45
    local btnW = 100
    local btnH = 35
    local btnSpacing = 8
    
    -- Store button (store current equipped weapon)
    local storeX = gridX
    local storeHover = mx >= storeX and mx <= storeX + btnW and my >= btnY and my <= btnY + btnH
    local ply = LocalPlayer()
    local activeWep = IsValid(ply) and ply:GetActiveWeapon()
    local canStore = IsValid(activeWep) and activeWep:IsWeapon()
    
    local storeBg = canStore and (storeHover and C.gem.emerald or Color(30, 100, 50)) or C.bg_light
    draw.RoundedBox(4, storeX, btnY, btnW, btnH, ColorAlpha(storeBg, alpha))
    draw.SimpleText("STORE", "TDMRP_BodyBold", storeX + btnW/2, btnY + btnH/2, ColorAlpha(canStore and C.text_primary or C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Equip button
    local equipX = storeX + btnW + btnSpacing
    local equipHover = mx >= equipX and mx <= equipX + btnW and my >= btnY and my <= btnY + btnH
    local canEquip = selectedSlot and TDMRP.Inventory.Items[selectedSlot]
    
    local equipBg = canEquip and (equipHover and C.accent or C.accent_dark) or C.bg_light
    draw.RoundedBox(4, equipX, btnY, btnW, btnH, ColorAlpha(equipBg, alpha))
    draw.SimpleText("EQUIP", "TDMRP_BodyBold", equipX + btnW/2, btnY + btnH/2, ColorAlpha(canEquip and C.text_primary or C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Drop button
    local dropX = equipX + btnW + btnSpacing
    local dropHover = mx >= dropX and mx <= dropX + btnW and my >= btnY and my <= btnY + btnH
    local canDrop = selectedSlot and TDMRP.Inventory.Items[selectedSlot]
    
    local dropBg = canDrop and (dropHover and C.warning or Color(120, 90, 30)) or C.bg_light
    draw.RoundedBox(4, dropX, btnY, btnW, btnH, ColorAlpha(dropBg, alpha))
    draw.SimpleText("DROP", "TDMRP_BodyBold", dropX + btnW/2, btnY + btnH/2, ColorAlpha(canDrop and C.text_primary or C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Refresh button
    local refreshX = dropX + btnW + btnSpacing
    local refreshHover = mx >= refreshX and mx <= refreshX + btnW and my >= btnY and my <= btnY + btnH
    
    local refreshBg = refreshHover and C.bg_hover or C.bg_light
    draw.RoundedBox(4, refreshX, btnY, btnW, btnH, ColorAlpha(refreshBg, alpha))
    draw.SimpleText("REFRESH", "TDMRP_BodyBold", refreshX + btnW/2, btnY + btnH/2, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

----------------------------------------------------
-- Helper: Draw Inventory Item
----------------------------------------------------

-- Rarity short codes for slot badges
local RARITY_SHORT = {
    [1] = "C",   -- Common
    [2] = "U",   -- Uncommon
    [3] = "R",   -- Rare
    [4] = "L",   -- Legendary
    [5] = "★",   -- Unique (star symbol)
}

function DrawInventoryItem(x, y, size, item, alpha, C, isHovered)
    -- Get weapon display info using helpers
    local displayName = TDMRP.GetWeaponDisplayName and TDMRP.GetWeaponDisplayName(item.class) or item.class
    local shortName = TDMRP.GetWeaponShortName and TDMRP.GetWeaponShortName(item.class) or string.sub(item.class, 1, 6)
    
    -- Safely get tier color with fallback to gray
    local tier = item.tier or 1
    tier = math.Clamp(tier, 1, 5)  -- Ensure tier is valid
    local tierColor = C.tier and C.tier[tier] or Color(180, 180, 180, 255)
    local rarityShort = RARITY_SHORT[tier] or "C"
    
    -- Tier background tint
    draw.RoundedBox(4, x + 2, y + 2, size - 4, size - 4, ColorAlpha(tierColor, alpha * 0.15))
    
    -- Weapon initials (first 2 chars of short name)
    local initials = string.upper(string.sub(shortName, 1, 2))
    draw.SimpleText(initials, "TDMRP_Header", x + size/2, y + size/2 - 8, ColorAlpha(tierColor, alpha * 0.6), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Rarity badge (top right) - show letter instead of "T1"
    draw.RoundedBox(3, x + size - 18, y + 3, 15, 14, ColorAlpha(tierColor, alpha * 0.5))
    draw.SimpleText(rarityShort, "TDMRP_Tiny", x + size - 10, y + 10, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Crafted star (shows if has prefix or suffix)
    if item.crafted or (item.prefixId and item.prefixId ~= "") or (item.suffixId and item.suffixId ~= "") then
        draw.SimpleText("★", "TDMRP_Small", x + 4, y + 2, ColorAlpha(C.legendary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Bind indicator (top left, small clock if bound)
    if item.bound_until and item.bound_until > 0 and item.bound_until > os.time() then
        draw.SimpleText("⏱", "TDMRP_Tiny", x + (item.crafted and 14 or 4), y + 4, ColorAlpha(C.gem.diamond, alpha * 0.8), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Gem dots (bottom)
    local gemX = x + 5
    local gemY = y + size - 12
    local gemNames = { "sapphire", "emerald", "ruby", "diamond", "amethyst" }
    local gemColors = {
        sapphire = C.gem.sapphire,
        emerald = C.gem.emerald,
        ruby = C.gem.ruby,
        diamond = C.gem.diamond,
        amethyst = C.gem.amethyst or Color(155, 89, 182, 255),
    }
    for _, gemName in ipairs(gemNames) do
        local count = item.gems and item.gems[gemName] or 0
        if count > 0 then
            local gemColor = gemColors[gemName] or C.text_muted
            draw.RoundedBox(3, gemX, gemY, 8, 8, ColorAlpha(gemColor, alpha))
            gemX = gemX + 10
        end
    end
    
    -- Short name (bottom center) - truncate if needed
    local slotName = shortName
    if #slotName > 6 then slotName = string.sub(slotName, 1, 5) .. ".." end
    draw.SimpleText(slotName, "TDMRP_Tiny", x + size/2, y + size - 3, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end

----------------------------------------------------
-- Rarity Names (per copilot-instructions.md)
----------------------------------------------------

local RARITY_NAMES = {
    [1] = "COMMON",
    [2] = "UNCOMMON",
    [3] = "RARE",
    [4] = "LEGENDARY",
    [5] = "UNIQUE",
}

----------------------------------------------------
-- Helper: Get formatted bind time remaining
----------------------------------------------------

local function GetBindTimeRemaining(bound_until)
    if not bound_until or bound_until <= 0 then return nil end
    
    -- Defensive: detect corrupted values (unix timestamps or huge numbers)
    -- Reasonable max bind time: 30 days = 2,592,000 seconds
    if bound_until > 2592000 then
        -- Corrupted value, ignore it
        return nil
    end
    
    -- bound_until from network is ALREADY remaining seconds, not a timestamp
    local remaining = bound_until
    if remaining <= 0 then return nil end
    
    local hours = math.floor(remaining / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    local seconds = remaining % 60
    
    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    elseif minutes > 0 then
        return string.format("%dm %ds", minutes, seconds)
    else
        return string.format("%ds", seconds)
    end
end

----------------------------------------------------
-- Helper: Modifier utilities
----------------------------------------------------

local function IsPercentModifier(v)
    if not v then return false end
    -- small fractional values represent percent (e.g. 0.12 => 12%)
    if math.abs(v) > 0 and math.abs(v) < 5 then
        return true
    end
    return false
end

local function FormatModifierValue(v)
    if not v or v == 0 then return nil end
    if IsPercentModifier(v) then
        return string.format((v > 0) and "+%.0f%%" or "%.0f%%", v * 100)
    else
        return string.format((v > 0) and "+%s" or "%s", tostring(v))
    end
end

local function CombineModifierTables(prefStats, suffStats)
    local out = {}
    if prefStats then
        for k, v in pairs(prefStats) do out[k] = (out[k] or 0) + v end
    end
    if suffStats then
        for k, v in pairs(suffStats) do out[k] = (out[k] or 0) + v end
    end
    return out
end


----------------------------------------------------
-- Helper: Draw Item Details Panel
----------------------------------------------------

function DrawItemDetails(x, y, w, h, item, alpha, C)
    -- Get weapon display info using helpers
    local displayName = TDMRP.GetWeaponDisplayName and TDMRP.GetWeaponDisplayName(item.class) or item.class
    
    -- Fallback: if displayName is empty, use short name or class name
    if not displayName or displayName == "" then
        displayName = TDMRP.GetWeaponShortName and TDMRP.GetWeaponShortName(item.class) or item.class
    end
    
    -- Final fallback: extract from class name if all else fails
    if not displayName or displayName == "" then
        displayName = string.upper(string.sub(item.class, 11)) -- Remove "tdmrp_m9k_" prefix
    end
    
    -- Safely get tier color with fallback
    local tier = item.tier or 1
    tier = math.Clamp(tier, 1, 5)
    local tierColor = C.tier and C.tier[tier] or Color(180, 180, 180, 255)
    local rarityName = RARITY_NAMES[tier] or "COMMON"
    
    local yOff = y + 15
    
    -- Build full weapon name with prefix/suffix
    local fullName = displayName
    if item.prefixId and item.prefixId ~= "" then
        local prefixData = TDMRP.Gems and TDMRP.Gems.Prefixes and TDMRP.Gems.Prefixes[item.prefixId]
        local prefixName = prefixData and prefixData.name or item.prefixId
        fullName = prefixName .. " " .. fullName
    end
    if item.suffixId and item.suffixId ~= "" then
        local suffixData = TDMRP.Gems and TDMRP.Gems.Suffixes and TDMRP.Gems.Suffixes[item.suffixId]
        local suffixName = suffixData and suffixData.name or item.suffixId
        fullName = fullName .. " " .. suffixName
    end
    
    -- Weapon name with prefix/suffix
    draw.SimpleText(fullName, "TDMRP_BodyBold", x + w/2, yOff, ColorAlpha(tierColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    yOff = yOff + 25
    
    -- Rarity display (use rarity name instead of "TIER X")
    draw.RoundedBox(4, x + w/2 - 45, yOff, 90, 24, ColorAlpha(tierColor, alpha * 0.3))
    draw.SimpleText(rarityName, "TDMRP_SmallBold", x + w/2, yOff + 12, ColorAlpha(tierColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    yOff = yOff + 35
    
    -- Crafted indicator
    if item.crafted then
        draw.SimpleText("★ CRAFTED", "TDMRP_SmallBold", x + w/2, yOff, ColorAlpha(C.legendary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        yOff = yOff + 20
    end
    
    -- Bind timer display
    local bindTime = GetBindTimeRemaining(item.bound_until)
    if bindTime then
        draw.SimpleText("⏱ BOUND: " .. bindTime, "TDMRP_Small", x + w/2, yOff, ColorAlpha(C.gem.diamond, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        yOff = yOff + 18
    end
    
    -- Cosmetic name display
    if item.cosmetic_name and item.cosmetic_name ~= "" then
        draw.SimpleText("\"" .. item.cosmetic_name .. "\"", "TDMRP_Small", x + w/2, yOff, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        yOff = yOff + 18
    end
    
    -- 3D WEAPON MODEL RENDER (large center area)
    local modelHeight = 200
    local modelY = yOff + 20
    RenderInventoryWeaponModel(x + 30, modelY, w - 60, modelHeight, item.class)
    yOff = modelY + modelHeight + 20
    
    -- Divider
    surface.SetDrawColor(ColorAlpha(C.bg_light, alpha))
    surface.DrawRect(x + 15, yOff, w - 30, 1)
    yOff = yOff + 15
    
    -- Stats
    draw.SimpleText("STATS", "TDMRP_SmallBold", x + 15, yOff, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    yOff = yOff + 20
    
    -- Prepare modifier data (prefix + suffix)
    local prefixData = item.prefixId and item.prefixId ~= "" and TDMRP.Gems and TDMRP.Gems.Prefixes and TDMRP.Gems.Prefixes[item.prefixId]
    local suffixData = item.suffixId and item.suffixId ~= "" and TDMRP.Gems and TDMRP.Gems.Suffixes and TDMRP.Gems.Suffixes[item.suffixId]
    local combinedMods = CombineModifierTables(prefixData and prefixData.stats or nil, suffixData and suffixData.stats or nil)

    local stats = {
        { key = "damage", name = "Damage", value = item.stats and item.stats.damage or "?", color = C.accent },
        { key = "rpm", name = "RPM", value = item.stats and item.stats.rpm or "?", color = C.text_primary },
        { key = "accuracy", name = "Accuracy", value = item.stats and item.stats.accuracy and string.format("%.1f", item.stats.accuracy) or "?", color = C.text_primary },
        { key = "recoil", name = "Recoil", value = item.stats and item.stats.recoil and string.format("%.2f", item.stats.recoil) or "?", color = C.text_primary },
        { key = "handling", name = "Handling", value = item.stats and item.stats.handling or "?", color = C.info },
    }

    for _, stat in ipairs(stats) do
        draw.SimpleText(stat.name .. ":", "TDMRP_Small", x + 20, yOff, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(tostring(stat.value), "TDMRP_SmallBold", x + w - 20, yOff, ColorAlpha(stat.color, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

        -- Draw stat delta from modifiers (if present)
        local mod = combinedMods and combinedMods[stat.key] or nil
        if mod and mod ~= 0 then
            local modStr = FormatModifierValue(mod)
            if modStr then
                local modColor = mod > 0 and Color(80, 220, 120) or Color(220, 80, 80)
                draw.SimpleText("(" .. modStr .. ")", "TDMRP_Tiny", x + w - 90, yOff + 1, ColorAlpha(modColor, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            end
        end

        yOff = yOff + 18
    end
    
    -- Gems section
    yOff = yOff + 10
    surface.SetDrawColor(ColorAlpha(C.bg_light, alpha))
    surface.DrawRect(x + 15, yOff, w - 30, 1)
    yOff = yOff + 15
    
    -- Modifiers section (Prefix/Suffix effects)
    if (item.prefixId and item.prefixId ~= "") or (item.suffixId and item.suffixId ~= "") then
        draw.SimpleText("MODIFIERS", "TDMRP_SmallBold", x + 15, yOff, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        yOff = yOff + 20
        
        -- Prefix info
        if item.prefixId and item.prefixId ~= "" then
            local prefixData = TDMRP.Gems and TDMRP.Gems.Prefixes and TDMRP.Gems.Prefixes[item.prefixId]
            if prefixData then
                local prefixColor = Color(80, 220, 120, 255)  -- Green for prefix
                draw.SimpleText("PREFIX:", "TDMRP_Small", x + 20, yOff, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(prefixData.name, "TDMRP_SmallBold", x + 100, yOff, ColorAlpha(prefixColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                yOff = yOff + 18
                if prefixData.description then
                    draw.SimpleText(prefixData.description, "TDMRP_Tiny", x + 20, yOff, ColorAlpha(C.text_muted, alpha * 0.8), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    yOff = yOff + 14
                end
            end
        end
        
        -- Suffix info
        if item.suffixId and item.suffixId ~= "" then
            local suffixData = TDMRP.Gems and TDMRP.Gems.Suffixes and TDMRP.Gems.Suffixes[item.suffixId]
            if suffixData then
                local suffixColor = Color(80, 160, 255, 255)  -- Blue for suffix
                draw.SimpleText("SUFFIX:", "TDMRP_Small", x + 20, yOff, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(suffixData.name, "TDMRP_SmallBold", x + 100, yOff, ColorAlpha(suffixColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                yOff = yOff + 18
                if suffixData.description then
                    draw.SimpleText(suffixData.description, "TDMRP_Tiny", x + 20, yOff, ColorAlpha(C.text_muted, alpha * 0.8), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    yOff = yOff + 14
                end
            end
        end
        
        yOff = yOff + 10
        surface.SetDrawColor(ColorAlpha(C.bg_light, alpha))
        surface.DrawRect(x + 15, yOff, w - 30, 1)
        yOff = yOff + 15
    end
    
    draw.SimpleText("GEMS", "TDMRP_SmallBold", x + 15, yOff, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    yOff = yOff + 20
    
    local hasGems = false
    local gemNames = { "sapphire", "emerald", "ruby", "diamond", "amethyst" }
    local gemBonuses = {
        sapphire = "Suffix Crafting",
        emerald = "Prefix Crafting",
        ruby = "Salvage",
        diamond = "Duplicate",
        amethyst = "+20m Bind Time",
    }
    local gemColors = {
        sapphire = C.gem.sapphire,
        emerald = C.gem.emerald,
        ruby = C.gem.ruby,
        diamond = C.gem.diamond,
        amethyst = Color(155, 89, 182, 255), -- Purple for amethyst
    }
    
    for _, gemName in ipairs(gemNames) do
        local count = item.gems and item.gems[gemName] or 0
        if count > 0 then
            hasGems = true
            local gemColor = gemColors[gemName] or C.text_primary
            draw.RoundedBox(4, x + 20, yOff, 12, 12, ColorAlpha(gemColor, alpha))
            draw.SimpleText(string.upper(gemName) .. " x" .. count, "TDMRP_Small", x + 38, yOff, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(gemBonuses[gemName], "TDMRP_Tiny", x + w - 20, yOff + 2, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            yOff = yOff + 18
        end
    end
    
    if not hasGems then
        draw.SimpleText("No gems socketed", "TDMRP_Small", x + 20, yOff, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Item ID (bottom)
    draw.SimpleText("ID: " .. (item.id or "?"), "TDMRP_Tiny", x + w/2, y + h - 15, ColorAlpha(C.text_muted, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end

----------------------------------------------------
-- Helper: Draw Context Menu
----------------------------------------------------

function DrawContextMenu(x, y, alpha, mx, my, C)
    local menuW = 120
    local menuH = 100
    local itemH = 25
    
    -- Clamp to screen
    if x + menuW > ScrW() then x = ScrW() - menuW end
    if y + menuH > ScrH() then y = ScrH() - menuH end
    
    draw.RoundedBox(4, x, y, menuW, menuH, ColorAlpha(C.bg_medium, alpha))
    surface.SetDrawColor(ColorAlpha(C.accent, alpha))
    surface.DrawOutlinedRect(x, y, menuW, menuH, 1)
    
    local options = {
        { name = "Equip", action = "equip" },
        { name = "Drop", action = "drop" },
        { name = "Inspect", action = "inspect" },
        { name = "Cancel", action = "cancel" },
    }
    
    for i, opt in ipairs(options) do
        local optY = y + (i-1) * itemH
        local isHovered = mx >= x and mx <= x + menuW and my >= optY and my <= optY + itemH
        
        if isHovered then
            draw.RoundedBox(0, x + 2, optY + 2, menuW - 4, itemH - 2, ColorAlpha(C.accent, alpha * 0.3))
        end
        
        local textColor = opt.action == "cancel" and C.text_muted or (opt.action == "drop" and C.warning or C.text_primary)
        draw.SimpleText(opt.name, "TDMRP_Small", x + 10, optY + itemH/2, ColorAlpha(textColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

----------------------------------------------------
-- Click Handler
----------------------------------------------------

local function OnInventoryClick(relX, relY, w, h)
    local C = TDMRP.UI.Colors
    
    local gridX = 20
    local gridY = 55
    local gridW = Config.cols * (Config.slotSize + Config.slotPadding)
    local gridH = h - 70
    
    -- Close context menu on any click
    if contextMenuOpen then
        -- Check if clicking context menu option
        local menuW = 120
        local itemH = 25
        local options = { "equip", "drop", "inspect", "cancel" }
        
        for i, action in ipairs(options) do
            local optY = contextMenuPos.y + (i-1) * itemH
            if relX >= contextMenuPos.x and relX <= contextMenuPos.x + menuW and relY >= optY and relY <= optY + itemH then
                if action == "equip" and contextMenuSlot then
                    EquipFromSlot(contextMenuSlot)
                elseif action == "drop" and contextMenuSlot then
                    DropFromSlot(contextMenuSlot)
                elseif action == "inspect" then
                    selectedSlot = contextMenuSlot
                end
                
                contextMenuOpen = false
                contextMenuSlot = nil
                return
            end
        end
        
        contextMenuOpen = false
        contextMenuSlot = nil
        return
    end
    
    -- Check action buttons
    local btnY = h - 45
    local btnW = 100
    local btnH = 35
    local btnSpacing = 8
    
    -- Store button
    local storeX = gridX
    if relX >= storeX and relX <= storeX + btnW and relY >= btnY and relY <= btnY + btnH then
        StoreCurrentWeapon()
        return
    end
    
    -- Equip button
    local equipX = storeX + btnW + btnSpacing
    if relX >= equipX and relX <= equipX + btnW and relY >= btnY and relY <= btnY + btnH then
        if selectedSlot and TDMRP.Inventory.Items[selectedSlot] then
            EquipFromSlot(selectedSlot)
        end
        return
    end
    
    -- Drop button
    local dropX = equipX + btnW + btnSpacing
    if relX >= dropX and relX <= dropX + btnW and relY >= btnY and relY <= btnY + btnH then
        if selectedSlot and TDMRP.Inventory.Items[selectedSlot] then
            DropFromSlot(selectedSlot)
        end
        return
    end
    
    -- Refresh button
    local refreshX = dropX + btnW + btnSpacing
    if relX >= refreshX and relX <= refreshX + btnW and relY >= btnY and relY <= btnY + btnH then
        RequestInventory()
        surface.PlaySound("UI/buttonclick.wav")
        return
    end
    
    -- Check slot click
    if relX >= gridX and relX <= gridX + gridW and relY >= gridY and relY <= gridY + gridH then
        for slot = 1, Config.maxSlots do
            local row = math.floor((slot - 1) / Config.cols)
            local col = (slot - 1) % Config.cols
            
            local slotX = gridX + col * (Config.slotSize + Config.slotPadding)
            local slotY = gridY + row * (Config.slotSize + Config.slotPadding) - scrollOffset
            
            if relX >= slotX and relX <= slotX + Config.slotSize and relY >= slotY and relY <= slotY + Config.slotSize then
                if TDMRP.Inventory.Items[slot] then
                    selectedSlot = slot
                    surface.PlaySound("UI/buttonclick.wav")
                else
                    selectedSlot = nil
                end
                return
            end
        end
    end
end

----------------------------------------------------
-- Right-click Handler
----------------------------------------------------

hook.Add("GUIMousePressed", "TDMRP_InventoryRightClick", function(mouseCode)
    if mouseCode ~= MOUSE_RIGHT then return end
    if not TDMRP.F4Menu or not TDMRP.F4Menu.IsOpen then return end
    if TDMRP.F4Menu.CurrentTab ~= "inventory" then return end
    
    if hoveredSlot and TDMRP.Inventory.Items[hoveredSlot] then
        contextMenuOpen = true
        contextMenuPos = { x = gui.MouseX(), y = gui.MouseY() }
        contextMenuSlot = hoveredSlot
    end
end)

----------------------------------------------------
-- Scroll Handler
----------------------------------------------------

local function OnInventoryScroll(delta)
    scrollOffset = math.Clamp(scrollOffset - delta * 40, 0, maxScroll)
end

----------------------------------------------------
-- Actions
----------------------------------------------------

function StoreCurrentWeapon()
    local ply = LocalPlayer()
    local wep = IsValid(ply) and ply:GetActiveWeapon()
    
    if not IsValid(wep) or not wep:IsWeapon() then
        chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "No valid weapon in hands to store!")
        return
    end
    
    net.Start("TDMRP_InventoryStore")
    net.SendToServer()
    
    surface.PlaySound("items/ammopickup.wav")
end

function EquipFromSlot(slot)
    local item = TDMRP.Inventory.Items[slot]
    if not item then return end
    
    net.Start("TDMRP_InventoryEquip")
        net.WriteInt(slot, 8)
    net.SendToServer()
    
    surface.PlaySound("items/gunpickup2.wav")
end

function DropFromSlot(slot)
    local item = TDMRP.Inventory.Items[slot]
    if not item then return end
    
    net.Start("TDMRP_InventoryDrop")
        net.WriteInt(slot, 8)
    net.SendToServer()
    
    surface.PlaySound("physics/metal/metal_box_impact_soft1.wav")
end

function RequestInventory()
    net.Start("TDMRP_RequestInventory")
    net.SendToServer()
end

----------------------------------------------------
-- Network: Receive inventory data (enhanced format)
----------------------------------------------------

net.Receive("TDMRP_InventoryData", function()
    local count = net.ReadInt(16)
    
    TDMRP.Inventory.Items = {}
    
    for i = 1, count do
        local slot = net.ReadInt(8)
        local item = {
            id = net.ReadInt(32),
            class = net.ReadString(),
            tier = net.ReadInt(8),
            crafted = net.ReadBool(),
            prefixId = net.ReadString(),
            suffixId = net.ReadString(),
            gems = {
                sapphire = net.ReadInt(8),
                emerald = net.ReadInt(8),
                ruby = net.ReadInt(8),
                diamond = net.ReadInt(8),
                amethyst = net.ReadInt(8),
            },
            stats = {
                damage = net.ReadInt(16),
                rpm = net.ReadInt(16),
                accuracy = net.ReadFloat(),
                recoil = net.ReadFloat(),
                handling = net.ReadInt(16),
            },
            bound_until = net.ReadFloat(),
            cosmetic_name = net.ReadString(),
        }
        
        -- Mark as crafted if has prefix/suffix
        if (item.prefixId and item.prefixId ~= "") or (item.suffixId and item.suffixId ~= "") then
            item.crafted = true
        end
        
        TDMRP.Inventory.Items[slot] = item
    end
    
    print("[TDMRP] Inventory synced: " .. count .. " items")
end)

net.Receive("TDMRP_InventoryUpdate", function()
    local action = net.ReadString()
    local slot = net.ReadInt(8)
    
    if action == "remove" then
        TDMRP.Inventory.Items[slot] = nil
        if selectedSlot == slot then selectedSlot = nil end
        chat.AddText(Color(255, 200, 100), "[TDMRP] ", Color(255, 255, 255), "Item removed from inventory")
    elseif action == "add" then
        local item = {
            id = net.ReadInt(32),
            class = net.ReadString(),
            tier = net.ReadInt(8),
            crafted = net.ReadBool(),
            prefixId = net.ReadString(),
            suffixId = net.ReadString(),
            gems = {
                sapphire = net.ReadInt(8),
                emerald = net.ReadInt(8),
                ruby = net.ReadInt(8),
                diamond = net.ReadInt(8),
                amethyst = net.ReadInt(8),
            },
            stats = {
                damage = net.ReadInt(16),
                rpm = net.ReadInt(16),
                accuracy = net.ReadFloat(),
                recoil = net.ReadFloat(),
                handling = net.ReadInt(16),
            },
            bound_until = net.ReadFloat(),
            cosmetic_name = net.ReadString(),
        }
        
        -- Mark as crafted if has prefix/suffix
        if (item.prefixId and item.prefixId ~= "") or (item.suffixId and item.suffixId ~= "") then
            item.crafted = true
        end
        
        TDMRP.Inventory.Items[slot] = item
        chat.AddText(Color(100, 255, 100), "[TDMRP] ", Color(255, 255, 255), "Item added to inventory (Slot " .. slot .. ")")
    end
end)

----------------------------------------------------
-- Request inventory on menu open
----------------------------------------------------

hook.Add("TDMRP_F4MenuOpened", "TDMRP_RequestInventoryOnOpen", function()
    RequestInventory()
end)

----------------------------------------------------
-- Cleanup Model Panels
----------------------------------------------------

hook.Add("TDMRP_F4MenuClosed", "TDMRP_InventoryCleanupModels", function()
    ClearInventoryModelPanels()
    if IsValid(modelContainer) then
        modelContainer:Remove()
        modelContainer = nil
    end
end)

hook.Add("TDMRP_F4TabChanged", "TDMRP_InventoryTabChange", function(newTab, oldTab)
    -- Clear models when switching away from inventory tab
    if oldTab == "inventory" then
        ClearInventoryModelPanels()
        if IsValid(modelContainer) then
            modelContainer:Remove()
            modelContainer = nil
        end
    end
end)

----------------------------------------------------
-- Register Tab (deferred to handle load order)
----------------------------------------------------

local function RegisterInventoryTab()
    if TDMRP.F4Menu and TDMRP.F4Menu.RegisterTab then
        TDMRP.F4Menu.RegisterTab("inventory", PaintInventory, OnInventoryClick, OnInventoryScroll)
    end
end

if TDMRP.F4Menu and TDMRP.F4Menu.Ready then
    RegisterInventoryTab()
else
    hook.Add("TDMRP_F4MenuReady", "TDMRP_RegisterInventoryTab", RegisterInventoryTab)
end

print("[TDMRP] cl_tdmrp_f4_inventory.lua loaded")
