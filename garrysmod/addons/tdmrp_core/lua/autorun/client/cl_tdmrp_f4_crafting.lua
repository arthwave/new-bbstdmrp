----------------------------------------------------
-- TDMRP F4 Menu - Crafting Tab
-- Roll Prefix (Emerald) / Roll Suffix (Sapphire) system
-- Weapons can be continuously re-rolled
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.F4Menu = TDMRP.F4Menu or {}

----------------------------------------------------
-- Network Strings
----------------------------------------------------

-- These will be registered on server
-- Client receives: TDMRP_CraftResult, TDMRP_GemCounts

----------------------------------------------------
-- State
----------------------------------------------------

local selectedWeaponIndex = nil
local hoveredButton = nil
local craftAnim = nil -- { type = "prefix"|"suffix"|"amethyst", startTime, result }
local lastClickTime = 0
local gemCounts = { blood_emerald = 0, blood_sapphire = 0, blood_amethyst = 0, blood_ruby = 0 }
local prevGemCounts = { blood_emerald = 0, blood_sapphire = 0, blood_amethyst = 0, blood_ruby = 0 }
local gemAnim = nil -- { startTime, deltas = { emerald= -1, ... } }

-- Custom naming state
local customNamingCost = 10000
local customNameWindow = nil  -- Reference to the modal window
local currentWeaponForNaming = nil  -- Store weapon being customized
local customNameInput = ""  -- Current text being typed
local customNameActive = false  -- Whether custom naming input is active
local prevKeyStates = {}  -- Track previous key states to detect presses

----------------------------------------------------
-- Helper: Format number with thousands separator
----------------------------------------------------
local function FormatCurrency(amount)
    local formatted = tostring(amount)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end
----------------------------------------------------
-- Request gem counts from server
----------------------------------------------------

local function RequestGemCounts()
    if not LocalPlayer then return end
    net.Start("TDMRP_RequestGemCounts")
    net.SendToServer()
end

-- Receive gem counts
net.Receive("TDMRP_GemCounts", function()
    local e = net.ReadUInt(16)
    local s = net.ReadUInt(16)
    local a = net.ReadUInt(16)
    local r = net.ReadUInt(16)

    -- Compute deltas for a small pop animation
    prevGemCounts.blood_emerald = prevGemCounts.blood_emerald or gemCounts.blood_emerald
    prevGemCounts.blood_sapphire = prevGemCounts.blood_sapphire or gemCounts.blood_sapphire
    prevGemCounts.blood_amethyst = prevGemCounts.blood_amethyst or gemCounts.blood_amethyst
    prevGemCounts.blood_ruby = prevGemCounts.blood_ruby or gemCounts.blood_ruby

    gemCounts.blood_emerald = e
    gemCounts.blood_sapphire = s
    gemCounts.blood_amethyst = a
    gemCounts.blood_ruby = r

    local deltas = {
        blood_emerald = gemCounts.blood_emerald - (prevGemCounts.blood_emerald or 0),
        blood_sapphire = gemCounts.blood_sapphire - (prevGemCounts.blood_sapphire or 0),
        blood_amethyst = gemCounts.blood_amethyst - (prevGemCounts.blood_amethyst or 0),
        blood_ruby = gemCounts.blood_ruby - (prevGemCounts.blood_ruby or 0),
    }

    local anyChange = false
    for k, v in pairs(deltas) do if v ~= 0 then anyChange = true break end end
    if anyChange then
        gemAnim = { startTime = CurTime(), deltas = deltas }
    end
end)

-- Receive craft result
net.Receive("TDMRP_CraftResult", function()
    local success = net.ReadBool()
    local craftType = net.ReadString()
    local resultId = net.ReadString()
    local message = net.ReadString()
    
    if success then
        craftAnim = {
            type = craftType,
            startTime = CurTime(),
            result = resultId,
            success = true,
        }
        -- Play different success sounds per craft type
        if craftType == "prefix" then
            surface.PlaySound("items/suitchargeok1.wav")
        elseif craftType == "suffix" then
            surface.PlaySound("buttons/button17.wav")
        elseif craftType == "salvage" then
            surface.PlaySound("ambient/levels/labs/electric_explosion1.wav")
        else
            surface.PlaySound("items/suitchargeok1.wav")
        end
        chat.AddText(Color(100, 255, 100), "[TDMRP] ", Color(255, 255, 255), message)
    else
        surface.PlaySound("buttons/button10.wav")
        chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), message)
    end
    
    -- Refresh gem counts
    RequestGemCounts()
end)

-- Receive bind expiration notification
net.Receive("TDMRP_BindExpired", function()
    -- Play warning sound
    surface.PlaySound("buttons/button10.wav")
end)

----------------------------------------------------
-- Helper: Get player's TDMRP weapons
----------------------------------------------------

local function GetCraftableWeapons()
    local ply = LocalPlayer()
    if not IsValid(ply) then return {} end
    
    local weapons = {}
    for _, wep in ipairs(ply:GetWeapons()) do
        local class = wep:GetClass()
        
        -- Check if this is a TDMRP weapon (must be tdmrp_m9k_*)
        if TDMRP.IsM9KWeapon and TDMRP.IsM9KWeapon(class) then
            local meta = TDMRP.GetWeaponMeta and TDMRP.GetWeaponMeta(class)
            
            table.insert(weapons, {
                weapon = wep,
                class = class,
                meta = meta or { name = class, type = "weapon" },
                tier = wep:GetNWInt("TDMRP_Tier", 1),
                crafted = wep:GetNWBool("TDMRP_Crafted", false),
                prefixId = wep:GetNWString("TDMRP_PrefixID", ""),
                suffixId = wep:GetNWString("TDMRP_SuffixID", ""),
                customName = wep:GetNWString("TDMRP_CustomName", ""),
            })
        end
    end
    
    return weapons
end

----------------------------------------------------
-- Helper: Get prefix/suffix data
----------------------------------------------------

local function GetPrefixData(id)
    if not id or id == "" then return nil end
    if TDMRP.Gems and TDMRP.Gems.Prefixes then
        return TDMRP.Gems.Prefixes[id]
    end
    return nil
end

local function GetSuffixData(id)
    if not id or id == "" then return nil end
    if TDMRP.Gems and TDMRP.Gems.Suffixes then
        return TDMRP.Gems.Suffixes[id]
    end
    return nil
end

----------------------------------------------------
-- Modifier helpers (formatting + combine)
----------------------------------------------------

local function IsPercentModifier(v)
    if not v then return false end
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
    if prefStats then for k,v in pairs(prefStats) do out[k] = (out[k] or 0) + v end end
    if suffStats then for k,v in pairs(suffStats) do out[k] = (out[k] or 0) + v end end
    return out
end

----------------------------------------------------
-- Helper: Draw colored weapon name (Tier + Prefix + Name + Suffix)
----------------------------------------------------

local RARITY_NAMES = {
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Legendary",
    [5] = "Unique",
}

local function DrawWeaponNameColored(x, y, class, tier, prefixId, suffixId, alpha, C)
    if not C or not C.tier then return end
    
    -- Get weapon display name
    local displayName = TDMRP.GetWeaponDisplayName and TDMRP.GetWeaponDisplayName(class) or class
    local tierNum = math.Clamp(tier or 1, 1, 5)
    local tierColor = C.tier[tierNum]
    local rarityName = RARITY_NAMES[tierNum] or "Common"
    
    -- Get prefix/suffix data
    local prefixData = GetPrefixData(prefixId)
    local suffixData = GetSuffixData(suffixId)
    local prefixName = prefixData and prefixData.name or ""
    local suffixName = suffixData and suffixData.name or ""
    
    -- Colors for each part
    local rarityColor = tierColor
    local prefixColor = Color(80, 220, 120, 255)  -- Green for prefix
    local weaponColor = tierColor
    local suffixColor = Color(80, 160, 255, 255)  -- Blue for suffix
    
    surface.SetFont("TDMRP_Header")
    
    -- Build the complete colored name
    local fullName = ""
    
    -- Build name parts array to calculate proper positioning
    local parts = {}
    
    -- Rarity name (tier)
    table.insert(parts, { text = rarityName, color = rarityColor })
    
    -- Prefix if exists (GREEN)
    if prefixName ~= "" then
        table.insert(parts, { text = prefixName, color = prefixColor })
    end
    
    -- Weapon name (TIER COLOR)
    table.insert(parts, { text = displayName, color = weaponColor })
    
    -- Suffix if exists (BLUE)
    if suffixName ~= "" then
        table.insert(parts, { text = suffixName, color = suffixColor })
    end
    
    -- Draw each part with proper coloring
    local currentX = x
    for _, part in ipairs(parts) do
        local partText = part.text
        draw.SimpleText(partText, "TDMRP_Header", currentX, y, ColorAlpha(part.color, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Calculate width for next part
        currentX = currentX + surface.GetTextSize(partText .. " ")
    end
end

----------------------------------------------------
-- Weapon Model Rendering (Manual 3D)
----------------------------------------------------
-- Weapon Model Rendering (Matching weapons tab pattern)
----------------------------------------------------

local modelPanels = {}  -- Cache of model panels
local modelContainer = nil

local function GetWeaponWorldModel(class)
    -- First try: Get from actual weapon entity in player inventory
    local ply = LocalPlayer()
    if IsValid(ply) then
        for _, wep in ipairs(ply:GetWeapons()) do
            if wep:GetClass() == class then
                -- Found the actual weapon - get its world model
                local model = wep:GetNWString("WorldModel") or wep.WorldModel
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

local function GetOrCreateWeaponModelPanel(class, x, y, size)
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
    
    -- Auto-rotate
    panel.LayoutEntity = function(self, ent)
        if IsValid(ent) then
            ent:SetAngles(Angle(0, RealTime() * 40 % 360, 0))
        end
    end
    
    modelPanels[cacheKey] = panel
    return panel
end

local function Render3DWeaponModel(x, y, w, h, class, suffixId)
    -- Hide all other weapon panels first
    for cacheKey, panel in pairs(modelPanels) do
        if IsValid(panel) then
            panel:SetVisible(false)
        end
    end
    
    -- Draw background
    draw.RoundedBox(6, x, y, w, h, Color(13, 13, 13, 255))
    
    local modelSize = w - 20
    local modelX = x + 10
    local modelY = y + 10
    
    local panel = GetOrCreateWeaponModelPanel(class, modelX, modelY, modelSize)
    if IsValid(panel) then
        panel:SetAlpha(255)
        panel:SetVisible(true)
    end
end

----------------------------------------------------
-- Paint Function
----------------------------------------------------

local function PaintCrafting(x, y, w, h, alpha, mx, my, scroll)
    local C = TDMRP.UI.Colors
    local ply = LocalPlayer()
    
    -- Header
    draw.SimpleText("WEAPON CRAFTING", "TDMRP_Header", x + 20, y + 12, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Gem counts display
    local gemY = y + 12
    local emeraldColor = Color(80, 220, 120, 255)
    local sapphireColor = Color(80, 160, 255, 255)
    local amethystColor = Color(180, 80, 255, 255)
    local rubyColor = Color(220, 50, 50, 255)
    
    -- Ruby count (leftmost)
    draw.RoundedBox(4, x + w - 390, gemY, 85, 24, ColorAlpha(rubyColor, alpha * 0.2))
    draw.SimpleText("◆ " .. (gemCounts.blood_ruby or 0), "TDMRP_SmallBold", x + w - 348, gemY + 12, ColorAlpha(rubyColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Amethyst count
    draw.RoundedBox(4, x + w - 295, gemY, 85, 24, ColorAlpha(amethystColor, alpha * 0.2))
    draw.SimpleText("◆ " .. gemCounts.blood_amethyst, "TDMRP_SmallBold", x + w - 253, gemY + 12, ColorAlpha(amethystColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    draw.RoundedBox(4, x + w - 200, gemY, 85, 24, ColorAlpha(emeraldColor, alpha * 0.2))
    draw.SimpleText("◆ " .. gemCounts.blood_emerald, "TDMRP_SmallBold", x + w - 158, gemY + 12, ColorAlpha(emeraldColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    draw.RoundedBox(4, x + w - 105, gemY, 85, 24, ColorAlpha(sapphireColor, alpha * 0.2))
    draw.SimpleText("◆ " .. gemCounts.blood_sapphire, "TDMRP_SmallBold", x + w - 63, gemY + 12, ColorAlpha(sapphireColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- NEW LAYOUT: Left weapon list | Center LARGE 3D model | Right modifiers + buttons
    local leftW = 220
    local rightW = 280
    local centerW = w - leftW - rightW - 45
    local panelY = y + 50
    local panelH = h - 65
    
    local craftableWeapons = GetCraftableWeapons()
    
    -- Left panel: Weapon list
    draw.RoundedBox(6, x + 15, panelY, leftW, panelH, ColorAlpha(C.bg_dark, alpha))
    draw.SimpleText("YOUR WEAPONS", "TDMRP_SmallBold", x + 25, panelY + 10, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    local listY = panelY + 35
    local itemH = 60
    
    if #craftableWeapons == 0 then
        draw.SimpleText("No TDMRP weapons", "TDMRP_Body", x + 15 + leftW/2, panelY + panelH/2 - 20, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("equipped", "TDMRP_Body", x + 15 + leftW/2, panelY + panelH/2, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        for i, wepData in ipairs(craftableWeapons) do
            local itemY = listY + (i-1) * (itemH + 5)
            if itemY + itemH > panelY + panelH - 10 then break end
            
            local isSelected = (i == selectedWeaponIndex)
            local isHovered = mx >= x + 20 and mx <= x + leftW + 5 and my >= itemY and my <= itemY + itemH
            
            local itemBg = isSelected and C.accent_dark or (isHovered and C.bg_hover or C.bg_light)
            draw.RoundedBox(4, x + 20, itemY, leftW - 10, itemH, ColorAlpha(itemBg, alpha))
            
            if isSelected then
                surface.SetDrawColor(ColorAlpha(C.accent, alpha))
                surface.DrawOutlinedRect(x + 20, itemY, leftW - 10, itemH, 2)
            end
            
            -- Weapon name
            local name = wepData.meta.name or wepData.class
            surface.SetFont("TDMRP_SmallBold")
            local nameW = surface.GetTextSize(name)
            if nameW > leftW - 50 then
                while nameW > leftW - 60 and #name > 5 do
                    name = string.sub(name, 1, -2)
                    nameW = surface.GetTextSize(name .. "..")
                end
                name = name .. ".."
            end
            draw.SimpleText(name, "TDMRP_SmallBold", x + 30, itemY + 8, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            -- Tier badge (with safe fallback)
            local tier = math.Clamp(wepData.tier or 1, 1, 5)
            local tierColor = C.tier and C.tier[tier] or Color(180, 180, 180, 255)
            draw.RoundedBox(4, x + leftW - 35, itemY + 8, 25, 16, ColorAlpha(tierColor, alpha * 0.3))
            draw.SimpleText("T" .. wepData.tier, "TDMRP_Tiny", x + leftW - 22, itemY + 16, ColorAlpha(tierColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Prefix/suffix status
            local statusY = itemY + 28
            if wepData.prefixId ~= "" then
                local prefix = GetPrefixData(wepData.prefixId)
                local prefixName = prefix and prefix.name or wepData.prefixId
                draw.SimpleText("◆ " .. prefixName, "TDMRP_Tiny", x + 30, statusY, ColorAlpha(emeraldColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            else
                draw.SimpleText("◆ No Prefix", "TDMRP_Tiny", x + 30, statusY, ColorAlpha(C.text_muted, alpha * 0.6), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
            
            if wepData.suffixId ~= "" then
                local suffix = GetSuffixData(wepData.suffixId)
                local suffixName = suffix and suffix.name or wepData.suffixId
                draw.SimpleText("◆ " .. suffixName, "TDMRP_Tiny", x + 30, statusY + 12, ColorAlpha(sapphireColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            else
                draw.SimpleText("◆ No Suffix", "TDMRP_Tiny", x + 30, statusY + 12, ColorAlpha(C.text_muted, alpha * 0.6), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end
    end
    
    -- Center panel: LARGE 3D Weapon preview (dominant feature)
    local centerX = x + leftW + 20
    draw.RoundedBox(6, centerX, panelY, centerW, panelH, ColorAlpha(C.bg_dark, alpha))
    
    local selectedWeapon = craftableWeapons[selectedWeaponIndex]
    
    if selectedWeapon then
        -- Display weapon name with colored prefix/suffix/tier ABOVE the model
        local nameY = panelY + 12
        DrawWeaponNameColored(centerX + 15, nameY, selectedWeapon.class, selectedWeapon.tier, selectedWeapon.prefixId, selectedWeapon.suffixId, alpha, C)
        
        -- 3D Weapon preview - LARGE and centered (below the name)
        local modelSize = math.min(centerW - 20, panelH - 90)
        local modelX = centerX + (centerW - modelSize) / 2
        local modelY = panelY + 50  -- Moved down to make room for name
        
        -- Render 3D model
        Render3DWeaponModel(modelX, modelY, modelSize, modelSize, selectedWeapon.class, selectedWeapon.suffixId)
        
        -- Crafting animation flash
        if craftAnim and CurTime() - craftAnim.startTime < 0.5 then
            local flashAlpha = (0.5 - (CurTime() - craftAnim.startTime)) * 400
            local flashColor = emeraldColor
            if craftAnim.type == "suffix" then
                flashColor = sapphireColor
            elseif craftAnim.type == "amethyst" then
                flashColor = amethystColor
            end
            draw.RoundedBox(6, centerX, panelY, centerW, panelH, ColorAlpha(flashColor, flashAlpha))
        end
        -- Craft result banner (shows rolled prefix/suffix name)
        if craftAnim and CurTime() - craftAnim.startTime < 1.6 then
            local dt = CurTime() - craftAnim.startTime
            local fade = math.Clamp(1 - (dt / 1.6), 0, 1)
            local bandAlpha = 220 * fade
            local bannerH = 48
            local bx = centerX + 20
            local by = panelY + 10
            local bw = centerW - 40

            local col = craftAnim.type == "suffix" and sapphireColor or emeraldColor
            if craftAnim.type == "amethyst" then col = amethystColor end

            draw.RoundedBox(6, bx, by, bw, bannerH, ColorAlpha(col, bandAlpha * 0.18))
            draw.SimpleText((craftAnim.success and "SUCCESS: " or "") .. (craftAnim.result or ""), "TDMRP_BodyBold", bx + bw/2, by + 10, ColorAlpha(C.text_primary, bandAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            if craftAnim.result and craftAnim.result ~= "" then
                draw.SimpleText("Result: " .. tostring(craftAnim.result), "TDMRP_Tiny", bx + bw/2, by + 28, ColorAlpha(C.text_secondary, bandAlpha * 0.9), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    else
        -- No weapon selected
        draw.RoundedBox(6, centerX, panelY, centerW, panelH, ColorAlpha(C.bg_dark, alpha))
        
        draw.SimpleText("SELECT A WEAPON", "TDMRP_SubHeader", centerX + centerW/2, panelY + panelH/2 - 30, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Choose from your", "TDMRP_Small", centerX + centerW/2, panelY + panelH/2, ColorAlpha(C.text_muted, alpha * 0.7), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("equipped weapons", "TDMRP_Small", centerX + centerW/2, panelY + panelH/2 + 16, ColorAlpha(C.text_muted, alpha * 0.7), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Right panel: Modifiers info (TOP) + Craft buttons (BOTTOM)
    local rightX = x + leftW + centerW + 30
    draw.RoundedBox(6, rightX, panelY, rightW, panelH, ColorAlpha(C.bg_dark, alpha))
    
    -- Show current prefix info
    local infoY = panelY + 15
    draw.SimpleText("MODIFIERS", "TDMRP_SmallBold", rightX + 15, infoY, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    infoY = infoY + 22
    -- Gem change pop animation
    if gemAnim and CurTime() - gemAnim.startTime < 1.0 then
        local gdt = CurTime() - gemAnim.startTime
        local gfade = math.Clamp(1 - (gdt / 1.0), 0, 1)
        local gx = rightX + rightW - 60
        local gy = infoY - 6
        local yoff = 0
        local iconSpacing = 16
        for k, v in pairs(gemAnim.deltas) do
            if v ~= 0 then
                local text = (v > 0 and "+" .. tostring(v) or tostring(v))
                local col = Color(200,200,200)
                if k == "blood_emerald" then col = emeraldColor end
                if k == "blood_sapphire" then col = sapphireColor end
                if k == "blood_amethyst" then col = amethystColor end
                draw.SimpleText(text, "TDMRP_Tiny", gx, gy + yoff, ColorAlpha(col, 200 * gfade), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                yoff = yoff + iconSpacing
            end
        end
    end
    
    if selectedWeapon then
        -- Prefix section (dynamically sized)
        local prefixBoxX = rightX + 10
        local prefixBoxW = rightW - 20
        local prefixTitleY = infoY + 6

        -- Calculate number of stat lines to determine height
        local prefixLines = 0
        if selectedWeapon.prefixId ~= "" then
            local prefix = GetPrefixData(selectedWeapon.prefixId)
            if prefix and prefix.stats then
                local statOrder = { "damage", "rpm", "accuracy", "recoil", "handling", "magazine" }
                for _, key in ipairs(statOrder) do
                    local v = prefix.stats[key]
                    if v and v ~= 0 then
                        prefixLines = prefixLines + 1
                    end
                end
            end
        end

        local baseHeight = 75
        local lineH = 14
        local contentHeight = 42 + (prefixLines * lineH) -- name area + stat lines
        local boxH = math.max(baseHeight, contentHeight)

        draw.RoundedBox(4, prefixBoxX, infoY, prefixBoxW, boxH, ColorAlpha(emeraldColor, alpha * 0.1))
        draw.SimpleText("PREFIX (Emerald)", "TDMRP_SmallBold", rightX + 20, prefixTitleY, ColorAlpha(emeraldColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if selectedWeapon.prefixId ~= "" then
            local prefix = GetPrefixData(selectedWeapon.prefixId)
            if prefix then
                draw.SimpleText(prefix.name, "TDMRP_Body", rightX + 20, infoY + 24, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                -- Show stat mods as readable deltas
                if prefix.stats then
                    local statOrder = { "damage", "rpm", "accuracy", "recoil", "handling", "magazine" }
                    local sy = infoY + 42
                    for _, key in ipairs(statOrder) do
                        local v = prefix.stats[key]
                        if v and v ~= 0 then
                            local vstr = FormatModifierValue(v)
                            if vstr then
                                draw.SimpleText(string.upper(key) .. ":", "TDMRP_Tiny", rightX + 20, sy, ColorAlpha(C.text_muted, alpha * 0.9), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                                local col = v > 0 and Color(80,220,120) or Color(220,80,80)
                                draw.SimpleText(vstr, "TDMRP_Tiny", rightX + rightW - 30, sy, ColorAlpha(col, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                                sy = sy + lineH
                            end
                        end
                    end
                end
            end
        else
            draw.SimpleText("None", "TDMRP_Body", rightX + 20, infoY + 30, ColorAlpha(C.text_muted, alpha * 0.5), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        infoY = infoY + boxH + 8
        
        -- Suffix section (dynamically sized)
        local suffixBoxX = rightX + 10
        local suffixBoxW = rightW - 20
        local suffixTitleY = infoY + 6

        -- Calculate number of stat lines for suffix
        local suffixLines = 0
        if selectedWeapon.suffixId ~= "" then
            local suffix = GetSuffixData(selectedWeapon.suffixId)
            if suffix and suffix.stats then
                local statOrder = { "damage", "rpm", "accuracy", "recoil", "handling", "magazine" }
                for _, key in ipairs(statOrder) do
                    local v = suffix.stats[key]
                    if v and v ~= 0 then
                        suffixLines = suffixLines + 1
                    end
                end
            end
        end

        local baseHeightS = 75
        local lineHS = 14
        local contentHeightS = 42 + (suffixLines * lineHS)
        local boxHS = math.max(baseHeightS, contentHeightS)

        draw.RoundedBox(4, suffixBoxX, infoY, suffixBoxW, boxHS, ColorAlpha(sapphireColor, alpha * 0.1))
        draw.SimpleText("SUFFIX (Sapphire)", "TDMRP_SmallBold", rightX + 20, suffixTitleY, ColorAlpha(sapphireColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if selectedWeapon.suffixId ~= "" then
            local suffix = GetSuffixData(selectedWeapon.suffixId)
            if suffix then
                draw.SimpleText(suffix.name, "TDMRP_Body", rightX + 20, infoY + 24, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                -- Show suffix stat mods
                if suffix.stats then
                    local statOrder = { "damage", "rpm", "accuracy", "recoil", "handling", "magazine" }
                    local sy = infoY + 42
                    for _, key in ipairs(statOrder) do
                        local v = suffix.stats[key]
                        if v and v ~= 0 then
                            local vstr = FormatModifierValue(v)
                            if vstr then
                                draw.SimpleText(string.upper(key) .. ":", "TDMRP_Tiny", rightX + 20, sy, ColorAlpha(C.text_muted, alpha * 0.9), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                                local col = v > 0 and Color(80,160,255) or Color(220,80,80)
                                draw.SimpleText(vstr, "TDMRP_Tiny", rightX + rightW - 30, sy, ColorAlpha(col, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                                sy = sy + lineHS
                            end
                        end
                    end
                else
                    draw.SimpleText("Tier " .. (suffix.tier or "?") .. " Effect", "TDMRP_Tiny", rightX + 20, infoY + 42, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
            end
        else
            draw.SimpleText("None", "TDMRP_Body", rightX + 20, infoY + 30, ColorAlpha(C.text_muted, alpha * 0.5), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        infoY = infoY + boxHS + 8
        
        -- CRAFT BUTTONS SECTION
        draw.SimpleText("CRAFT ACTIONS", "TDMRP_SmallBold", rightX + 15, infoY, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        infoY = infoY + 22
        
        local btnW = rightW - 30
        local btnH = 38
        local btnX = rightX + 15
        
        -- Roll Prefix button
        local prefixBtnY = infoY
        local prefixHovered = mx >= btnX and mx <= btnX + btnW and my >= prefixBtnY and my <= prefixBtnY + btnH
        local canRollPrefix = gemCounts.blood_emerald >= 1
        
        local prefixBtnColor = canRollPrefix and (prefixHovered and Color(100, 255, 140, 255) or emeraldColor) or C.text_muted
        draw.RoundedBox(6, btnX, prefixBtnY, btnW, btnH, ColorAlpha(prefixBtnColor, alpha * 0.3))
        surface.SetDrawColor(ColorAlpha(prefixBtnColor, alpha))
        surface.DrawOutlinedRect(btnX, prefixBtnY, btnW, btnH, 2)
        
        draw.SimpleText("ROLL PREFIX", "TDMRP_BodyBold", btnX + btnW/2, prefixBtnY + 8, ColorAlpha(canRollPrefix and C.text_primary or C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("◆ 1 Emerald", "TDMRP_Tiny", btnX + btnW/2, prefixBtnY + 22, ColorAlpha(emeraldColor, alpha * 0.8), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        if prefixHovered then hoveredButton = "prefix" end
        infoY = infoY + btnH + 8
        
        -- Roll Suffix button
        local suffixBtnY = infoY
        local suffixHovered = mx >= btnX and mx <= btnX + btnW and my >= suffixBtnY and my <= suffixBtnY + btnH
        local canRollSuffix = gemCounts.blood_sapphire >= 1
        
        local suffixBtnColor = canRollSuffix and (suffixHovered and Color(100, 180, 255, 255) or sapphireColor) or C.text_muted
        draw.RoundedBox(6, btnX, suffixBtnY, btnW, btnH, ColorAlpha(suffixBtnColor, alpha * 0.3))
        surface.SetDrawColor(ColorAlpha(suffixBtnColor, alpha))
        surface.DrawOutlinedRect(btnX, suffixBtnY, btnW, btnH, 2)
        
        draw.SimpleText("ROLL SUFFIX", "TDMRP_BodyBold", btnX + btnW/2, suffixBtnY + 8, ColorAlpha(canRollSuffix and C.text_primary or C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("◆ 1 Sapphire", "TDMRP_Tiny", btnX + btnW/2, suffixBtnY + 22, ColorAlpha(sapphireColor, alpha * 0.8), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        if suffixHovered then hoveredButton = "suffix" end
        infoY = infoY + btnH + 8
        
        -- Apply Amethyst button (Binding)
        local amethystBtnY = infoY
        local amethystHovered = mx >= btnX and mx <= btnX + btnW and my >= amethystBtnY and my <= amethystBtnY + btnH
        local canApplyAmethyst = gemCounts.blood_amethyst >= 1
        
        -- Get current bind status of selected weapon
        -- Check BOTH the NWFloat (if weapon exists) AND the inventory data (if stored)
        local bindExpire = 0
        local bindRemaining = 0
        
        -- First try: Get from weapon entity NWFloat (works if weapon is equipped)
        if selectedWeapon.weapon and IsValid(selectedWeapon.weapon) then
            bindExpire = selectedWeapon.weapon:GetNWFloat("TDMRP_BindExpire", 0)
            bindRemaining = bindExpire > 0 and math.max(0, bindExpire - CurTime()) or 0
        end
        
        -- Second try: If no bind on entity, check if inventory item has bind data
        if bindRemaining <= 0 and selectedWeapon.bound_until and selectedWeapon.bound_until > 0 then
            -- bound_until in inventory is either absolute timestamp or remaining seconds
            local boundUntil = selectedWeapon.bound_until
            if boundUntil > 100000000 then
                -- It's an absolute timestamp (unix)
                bindRemaining = math.max(0, boundUntil - os.time())
            else
                -- It's already remaining seconds
                bindRemaining = boundUntil
            end
        end
        
        local isMaxBound = bindRemaining >= 3599 -- 59:59
        
        local amethystBtnColor = (canApplyAmethyst and not isMaxBound) and (amethystHovered and Color(200, 100, 255, 255) or amethystColor) or C.text_muted
        draw.RoundedBox(6, btnX, amethystBtnY, btnW, btnH, ColorAlpha(amethystBtnColor, alpha * 0.3))
        surface.SetDrawColor(ColorAlpha(amethystBtnColor, alpha))
        surface.DrawOutlinedRect(btnX, amethystBtnY, btnW, btnH, 2)
        
        local amethystText = isMaxBound and "MAX BOUND (59:59)" or "BIND WEAPON"
        local amethystSubText = isMaxBound and "Already maximum" or "◆ 1 Amethyst"
        
        draw.SimpleText(amethystText, "TDMRP_BodyBold", btnX + btnW/2, amethystBtnY + 8, ColorAlpha((canApplyAmethyst and not isMaxBound) and C.text_primary or C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(amethystSubText, "TDMRP_Tiny", btnX + btnW/2, amethystBtnY + 22, ColorAlpha(amethystColor, alpha * 0.8), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        if amethystHovered then hoveredButton = "amethyst" end
        infoY = infoY + btnH + 8
        
        -- Salvage button (Ruby)
        local rubyBtnY = infoY
        local rubyHovered = mx >= btnX and mx <= btnX + btnW and my >= rubyBtnY and my <= rubyBtnY + btnH
        local canSalvage = (gemCounts.blood_ruby or 0) >= 1
        
        local rubyBtnColor = canSalvage and (rubyHovered and Color(255, 100, 100, 255) or rubyColor) or C.text_muted
        draw.RoundedBox(6, btnX, rubyBtnY, btnW, btnH, ColorAlpha(rubyBtnColor, alpha * 0.3))
        surface.SetDrawColor(ColorAlpha(rubyBtnColor, alpha))
        surface.DrawOutlinedRect(btnX, rubyBtnY, btnW, btnH, 2)
        
        draw.SimpleText("SALVAGE", "TDMRP_BodyBold", btnX + btnW/2, rubyBtnY + 8, ColorAlpha(canSalvage and C.text_primary or C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("◆ 1 Ruby  |  Unbind", "TDMRP_Tiny", btnX + btnW/2, rubyBtnY + 22, ColorAlpha(rubyColor, alpha * 0.8), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        if rubyHovered then hoveredButton = "salvage" end
        infoY = infoY + btnH + 8
        
        -- CUSTOMIZE NAME BUTTON
        local customizeNameBtnY = infoY
        local customizeNameHovered = mx >= btnX and mx <= btnX + btnW and my >= customizeNameBtnY and my <= customizeNameBtnY + btnH
        local playerCash = LocalPlayer():getDarkRPVar("money") or 0
        local canAffordNaming = playerCash >= customNamingCost
        
        local customizeBtnColor = canAffordNaming and (customizeNameHovered and Color(100, 200, 255, 255) or Color(150, 150, 200, 255)) or C.text_muted
        draw.RoundedBox(6, btnX, customizeNameBtnY, btnW, btnH, ColorAlpha(customizeBtnColor, alpha * 0.3))
        surface.SetDrawColor(ColorAlpha(customizeBtnColor, alpha))
        surface.DrawOutlinedRect(btnX, customizeNameBtnY, btnW, btnH, 2)
        
        local costStr = "$" .. FormatCurrency(customNamingCost)
        draw.SimpleText("CUSTOMIZE NAME", "TDMRP_BodyBold", btnX + btnW/2, customizeNameBtnY + 8, ColorAlpha(canAffordNaming and C.text_primary or C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(costStr, "TDMRP_Tiny", btnX + btnW/2, customizeNameBtnY + 22, ColorAlpha(Color(200, 200, 100), alpha * 0.8), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        if customizeNameHovered then hoveredButton = "customize_name" end
        
    else
        draw.SimpleText("Select a weapon", "TDMRP_Body", rightX + rightW/2, infoY + 50, ColorAlpha(C.text_muted, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("to see modifiers", "TDMRP_Body", rightX + rightW/2, infoY + 70, ColorAlpha(C.text_muted, alpha * 0.5), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end

----------------------------------------------------
-- Customize Name Input Handler
----------------------------------------------------

local lastKeyCheck = 0
local function UpdateCustomNameInput()
    if not customNameActive or CurTime() - lastKeyCheck < 0.05 then return end  -- Increased throttle to 50ms
    lastKeyCheck = CurTime()
    
    local keysToCheck = {
        {KEY_BACKSPACE, "backspace"},
        {KEY_SPACE, "space"},
    }
    
    -- Check letters (A-Z)
    for i = 0, 25 do
        table.insert(keysToCheck, {KEY_A + i, "letter_" .. i})
    end
    
    -- Check numbers (0-9)
    for i = 0, 9 do
        table.insert(keysToCheck, {KEY_0 + i, "number_" .. i})
    end
    
    for _, keyInfo in ipairs(keysToCheck) do
        local keyCode = keyInfo[1]
        local keyName = keyInfo[2]
        local isPressed = input.IsKeyDown(keyCode)
        local wasPressed = prevKeyStates[keyName] or false
        
        -- Only trigger on transition from unpressed to pressed
        if isPressed and not wasPressed then
            if keyName == "backspace" then
                customNameInput = customNameInput:sub(1, -2)
            elseif keyName == "space" then
                if #customNameInput < 32 then
                    customNameInput = customNameInput .. " "
                end
            elseif keyName:find("letter_") then
                if #customNameInput < 32 then
                    local charIndex = tonumber(keyName:sub(8))
                    local char = string.char(65 + charIndex)
                    if input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT) then
                        customNameInput = customNameInput .. char
                    else
                        customNameInput = customNameInput .. string.lower(char)
                    end
                end
            elseif keyName:find("number_") then
                if #customNameInput < 32 then
                    local numIndex = tonumber(keyName:sub(8))
                    customNameInput = customNameInput .. tostring(numIndex)
                end
            end
        end
        
        -- Update state
        prevKeyStates[keyName] = isPressed
    end
end

local function OpenCustomizeNameWindow(weapon)
    if not IsValid(weapon) then return end
    
    currentWeaponForNaming = weapon
    customNameInput = ""
    customNameActive = true
    prevKeyStates = {}  -- Reset key states
    
    -- Create dark overlay panel
    if IsValid(customNameWindow) then
        customNameWindow:Remove()
    end
    
    customNameWindow = vgui.Create("DPanel")
    customNameWindow:SetSize(600, 300)
    customNameWindow:Center()
    customNameWindow:SetDrawOnTop(true)
    customNameWindow:MakePopup()  -- Make it receive input
    customNameWindow:SetKeyboardInputEnabled(false)  -- Don't intercept keyboard
    
    function customNameWindow:Paint(w, h)
        -- Semi-transparent dark background
        draw.RoundedBox(8, 0, 0, w, h, Color(20, 20, 20, 240))
        surface.SetDrawColor(100, 150, 200, 200)
        surface.DrawOutlinedRect(0, 0, w, h, 3)
        
        -- Title
        draw.SimpleText("CUSTOMIZE WEAPON NAME", "TDMRP_BodyBold", w/2, 20, Color(200, 200, 200), TEXT_ALIGN_CENTER)
        
        -- Input box
        local boxX, boxY = 50, 80
        local boxW, boxH = w - 100, 50
        draw.RoundedBox(4, boxX, boxY, boxW, boxH, Color(40, 40, 40, 255))
        surface.SetDrawColor(100, 150, 200, 255)
        surface.DrawOutlinedRect(boxX, boxY, boxW, boxH, 2)
        
        -- Draw typed text
        draw.SimpleText(customNameInput, "TDMRP_Body", boxX + 15, boxY + 10, Color(200, 255, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Character count
        draw.SimpleText(#customNameInput .. "/32", "TDMRP_Tiny", boxX + boxW - 10, boxY + 35, Color(150, 150, 150), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        
        -- Instructions
        draw.SimpleText("Type your custom weapon name (letters, numbers, spaces only)", "TDMRP_Tiny", w/2, 150, Color(150, 150, 150), TEXT_ALIGN_CENTER)
        
        -- Info text
        draw.SimpleText("Cost: $10,000 | Your name will appear as: *" .. (customNameInput ~= "" and customNameInput or "Custom Name") .. "*", "TDMRP_Tiny", w/2, 180, Color(120, 120, 120), TEXT_ALIGN_CENTER)
        
        -- Buttons
        local btnW, btnH = 120, 35
        local finalizeBtnX = w/2 - 130
        local cancelBtnX = w/2 + 10
        local btnY = 230
        
        -- Finalize button
        local canAfford = (LocalPlayer():getDarkRPVar("money") or 0) >= customNamingCost
        draw.RoundedBox(4, finalizeBtnX, btnY, btnW, btnH, canAfford and Color(100, 200, 100) or Color(100, 100, 100))
        draw.SimpleText("FINALIZE", "TDMRP_BodyBold", finalizeBtnX + btnW/2, btnY + 8, Color(255, 255, 255), TEXT_ALIGN_CENTER)
        
        -- Cancel button
        draw.RoundedBox(4, cancelBtnX, btnY, btnW, btnH, Color(150, 80, 80))
        draw.SimpleText("CANCEL", "TDMRP_BodyBold", cancelBtnX + btnW/2, btnY + 8, Color(255, 255, 255), TEXT_ALIGN_CENTER)
    end
    
    function customNameWindow:OnMousePressed(keyCode)
        if keyCode ~= MOUSE_LEFT then return end
        
        local w, h = self:GetSize()
        local mx, my = gui.MousePos()
        local x, y = self:LocalToScreen(0, 0)
        local relX, relY = mx - x, my - y
        
        -- Finalize button
        local finalizeBtnX = w/2 - 130
        local cancelBtnX = w/2 + 10
        local btnW, btnH = 120, 35
        local btnY = 230
        
        if relX >= finalizeBtnX and relX <= finalizeBtnX + btnW and relY >= btnY and relY <= btnY + btnH then
            -- Finalize
            if customNameInput == "" then
                chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "Please enter a custom name!")
                return
            end
            
            local playerCash = LocalPlayer():getDarkRPVar("money") or 0
            if playerCash < customNamingCost then
                chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "You need $" .. FormatCurrency(customNamingCost) .. " to customize!")
                return
            end
            
            net.Start("TDMRP_SetCustomName")
            net.WriteUInt(currentWeaponForNaming:EntIndex(), 16)
            net.WriteString(customNameInput)
            net.SendToServer()
            
            self:Remove()
            customNameActive = false
            surface.PlaySound("UI/buttonclick.wav")
        elseif relX >= cancelBtnX and relX <= cancelBtnX + btnW and relY >= btnY and relY <= btnY + btnH then
            -- Cancel
            self:Remove()
            customNameActive = false
            surface.PlaySound("buttons/button10.wav")
        end
    end
end

----------------------------------------------------
-- Click Handler
----------------------------------------------------

local function OnCraftingClick(relX, relY, w, h)
    -- Debounce
    if CurTime() - lastClickTime < 0.3 then return end
    lastClickTime = CurTime()
    
    local C = TDMRP.UI.Colors
    local leftW = 220
    local rightW = 280
    local centerW = w - leftW - rightW - 45
    local panelY = 50
    local panelH = h - 65
    local panelY = 50
    local panelH = h - 65
    
    local craftableWeapons = GetCraftableWeapons()
    
    -- Check weapon list clicks
    local listY = panelY + 35
    local itemH = 60
    
    if relX >= 20 and relX <= leftW + 5 then
        for i, wepData in ipairs(craftableWeapons) do
            local itemY = listY + (i-1) * (itemH + 5)
            if relY >= itemY and relY <= itemY + itemH then
                selectedWeaponIndex = i
                surface.PlaySound("UI/buttonclick.wav")
                return
            end
        end
    end
    
    -- Check craft button clicks
    local selectedWeapon = craftableWeapons[selectedWeaponIndex]
    if not selectedWeapon then return end
    
    local rightX = leftW + centerW + 30
    local btnX = rightX + 15
    local btnW = rightW - 30
    local btnH = 38
    
    -- Calculate button positions on right panel using SAME DYNAMIC heights as PaintCrafting
    local infoY = panelY + 15 + 22 -- Header height
    
    -- Calculate PREFIX section height (DYNAMIC based on stat lines)
    local prefixLines = 0
    if selectedWeapon.prefixId ~= "" then
        local prefix = GetPrefixData(selectedWeapon.prefixId)
        if prefix and prefix.stats then
            local statOrder = { "damage", "rpm", "accuracy", "recoil", "handling", "magazine" }
            for _, key in ipairs(statOrder) do
                local v = prefix.stats[key]
                if v and v ~= 0 then
                    prefixLines = prefixLines + 1
                end
            end
        end
    end
    local baseHeight = 75
    local lineH = 14
    local prefixContentHeight = 42 + (prefixLines * lineH)
    local prefixBoxH = math.max(baseHeight, prefixContentHeight)
    infoY = infoY + prefixBoxH + 8
    
    -- Calculate SUFFIX section height (DYNAMIC based on stat lines)
    local suffixLines = 0
    if selectedWeapon.suffixId ~= "" then
        local suffix = GetSuffixData(selectedWeapon.suffixId)
        if suffix and suffix.stats then
            local statOrder = { "damage", "rpm", "accuracy", "recoil", "handling", "magazine" }
            for _, key in ipairs(statOrder) do
                local v = suffix.stats[key]
                if v and v ~= 0 then
                    suffixLines = suffixLines + 1
                end
            end
        end
    end
    local baseHeightS = 75
    local lineHS = 14
    local suffixContentHeight = 42 + (suffixLines * lineHS)
    local suffixBoxH = math.max(baseHeightS, suffixContentHeight)
    infoY = infoY + suffixBoxH + 8
    
    -- Add header for "CRAFT ACTIONS"
    infoY = infoY + 22
    
    -- Roll Prefix button
    local prefixBtnY = infoY
    if relX >= btnX and relX <= btnX + btnW and relY >= prefixBtnY and relY <= prefixBtnY + btnH then
        if gemCounts.blood_emerald >= 1 then
            net.Start("TDMRP_RollPrefix")
            net.WriteUInt(selectedWeapon.weapon:EntIndex(), 16)
            net.SendToServer()
            surface.PlaySound("UI/buttonclick.wav")
        else
            chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "You need 1 Blood Emerald to roll a prefix!")
            surface.PlaySound("buttons/button10.wav")
        end
        return
    end
    
    infoY = infoY + btnH + 8
    
    -- Roll Suffix button
    local suffixBtnY = infoY
    if relX >= btnX and relX <= btnX + btnW and relY >= suffixBtnY and relY <= suffixBtnY + btnH then
        if gemCounts.blood_sapphire >= 1 then
            net.Start("TDMRP_RollSuffix")
            net.WriteUInt(selectedWeapon.weapon:EntIndex(), 16)
            net.SendToServer()
            surface.PlaySound("UI/buttonclick.wav")
        else
            chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "You need 1 Blood Sapphire to roll a suffix!")
            surface.PlaySound("buttons/button10.wav")
        end
        return
    end
    
    
    infoY = infoY + btnH + 8
    
    -- Apply Amethyst (Bind Weapon)
    local amethystBtnY = infoY
    if relX >= btnX and relX <= btnX + btnW and relY >= amethystBtnY and relY <= amethystBtnY + btnH then
        -- Check if already at max
        local bindExpire = 0
        local bindRemaining = 0
        if selectedWeapon.weapon and IsValid(selectedWeapon.weapon) then
            bindExpire = selectedWeapon.weapon:GetNWFloat("TDMRP_BindExpire", 0)
            bindRemaining = bindExpire > 0 and math.max(0, bindExpire - CurTime()) or 0
        end
        
        if bindRemaining >= 3599 then
            chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "Weapon is already at maximum bind time (59:59)!")
            surface.PlaySound("buttons/button10.wav")
            return
        end
        
        if gemCounts.blood_amethyst >= 1 then
            net.Start("TDMRP_ApplyAmethyst")
            net.WriteUInt(selectedWeapon.weapon:EntIndex(), 16)
            net.SendToServer()
            surface.PlaySound("UI/buttonclick.wav")
            
            -- Refresh gem counts after a short delay
            timer.Simple(0.5, function()
                RequestGemCounts()
            end)
        else
            chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "You need 1 Blood Amethyst to bind a weapon!")
            surface.PlaySound("buttons/button10.wav")
        end
        return
    end
    
    infoY = infoY + btnH + 8
    
    -- Salvage button (Ruby)
    local rubyBtnY = infoY
    if relX >= btnX and relX <= btnX + btnW and relY >= rubyBtnY and relY <= rubyBtnY + btnH then
        if (gemCounts.blood_ruby or 0) >= 1 then
            net.Start("TDMRP_RubySalvage")
            net.WriteUInt(selectedWeapon.weapon:EntIndex(), 16)
            net.SendToServer()
            surface.PlaySound("UI/buttonclick.wav")
            
            -- Refresh gem counts after a short delay
            timer.Simple(0.5, function()
                RequestGemCounts()
            end)
        else
            chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "You need 1 Blood Ruby to salvage!")
            surface.PlaySound("buttons/button10.wav")
        end
        return
    end
    
    infoY = infoY + btnH + 8
    
    -- Customize Name Button
    local customizeNameBtnY = infoY
    if relX >= btnX and relX <= btnX + btnW and relY >= customizeNameBtnY and relY <= customizeNameBtnY + btnH then
        local playerCash = LocalPlayer():getDarkRPVar("money") or 0
        if playerCash >= customNamingCost then
            OpenCustomizeNameWindow(selectedWeapon.weapon)
            surface.PlaySound("UI/buttonclick.wav")
        else
            chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "You need $" .. FormatCurrency(customNamingCost) .. " to customize!")
            surface.PlaySound("buttons/button10.wav")
        end
        return
    end
end

----------------------------------------------------
-- Scroll Handler
----------------------------------------------------

local function OnCraftingScroll(delta)
    -- No scrolling in crafting tab
end

----------------------------------------------------
-- Keyboard Input Handler for Custom Name (Direct)
-- Called by the F4 menu panel when keys are pressed
----------------------------------------------------

local function OnCraftingKeyDown(key)
    -- No longer needed - keyboard handled by modal window
    return false
end

----------------------------------------------------
-- Character Input Handler for Custom Name (Direct)
----------------------------------------------------

local function OnCraftingCharInput(char)
    -- No longer needed - keyboard handled by modal window
    return false
end

----------------------------------------------------
-- Input Processing Hook
----------------------------------------------------

hook.Add("Think", "TDMRP_CustomNameInput", function()
    if customNameActive then
        UpdateCustomNameInput()
    end
end)

----------------------------------------------------
-- Cleanup
----------------------------------------------------

hook.Add("TDMRP_F4MenuClosed", "TDMRP_CraftingCleanup", function()
    -- Clean up weapon entity if still valid
    if IsValid(currentWeaponEntity) then
        currentWeaponEntity:Remove()
        currentWeaponEntity = nil
    end
end)

hook.Add("TDMRP_F4TabChanged", "TDMRP_CraftingTabChange", function(newTab, oldTab)
    -- Reset model when switching tabs
    lastModelClass = nil
end)

hook.Add("TDMRP_F4MenuOpened", "TDMRP_CraftingInit", function()
    selectedWeaponIndex = nil
    RequestGemCounts()
end)

----------------------------------------------------
-- Cleanup Hooks
----------------------------------------------------

local function ClearWeaponModelPanels()
    for _, panel in pairs(modelPanels) do
        if IsValid(panel) then
            panel:Remove()
        end
    end
    modelPanels = {}
end

hook.Add("TDMRP_F4MenuClosed", "TDMRP_CraftingCleanup", function()
    -- Completely remove all model panels to prevent persistence
    ClearWeaponModelPanels()
    if IsValid(modelContainer) then
        modelContainer:Remove()
        modelContainer = nil
    end
end)

hook.Add("TDMRP_F4TabChanged", "TDMRP_CraftingTabChange", function(newTab, oldTab)
    -- Hide weapon model panels when switching away from crafting tab
    if oldTab == "crafting" then
        ClearWeaponModelPanels()
        if IsValid(modelContainer) then
            modelContainer:Remove()
            modelContainer = nil
        end
    end
end)

----------------------------------------------------
-- Register Tab
----------------------------------------------------

local function RegisterCraftingTab()
    if TDMRP.F4Menu and TDMRP.F4Menu.RegisterTab then
        TDMRP.F4Menu.RegisterTab("crafting", PaintCrafting, OnCraftingClick, OnCraftingScroll, OnCraftingKeyDown, OnCraftingCharInput)
    end
end

if TDMRP.F4Menu and TDMRP.F4Menu.Ready then
    RegisterCraftingTab()
else
    hook.Add("TDMRP_F4MenuReady", "TDMRP_RegisterCraftingTab", RegisterCraftingTab)
end

print("[TDMRP] cl_tdmrp_f4_crafting.lua loaded - Roll prefix/suffix crafting system")
