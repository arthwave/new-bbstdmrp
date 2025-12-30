----------------------------------------------------
-- TDMRP Loadout Selection UI
-- Shows on spawn for combat classes (cop/criminal)
-- 3-column layout: Primary, Secondary, Gear
-- 15-second timeout with auto-spawn
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.LoadoutUI = TDMRP.LoadoutUI or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

local CONFIG = {
    TIMEOUT = 15,               -- Seconds before auto-spawn
    SCREEN_ALPHA = 200,         -- Black overlay alpha
    COLUMN_WIDTH = 350,         -- Width of each weapon column
    COLUMN_HEIGHT = 500,        -- Height of weapon columns
    WEAPON_SLOT_HEIGHT = 80,    -- Height of each weapon option
    PADDING = 20,               -- General padding
}

----------------------------------------------------
-- CSS Kill Icon Font Characters
-- These correspond to CSKillIcons font glyphs
----------------------------------------------------

local CSS_ICON_LETTERS = {
    ["weapon_tdmrp_cs_glock18"] = "c",
    ["weapon_tdmrp_cs_usp"] = "a",
    ["weapon_tdmrp_cs_p228"] = "y",
    ["weapon_tdmrp_cs_five_seven"] = "u",
    ["weapon_tdmrp_cs_elites"] = "s",
    ["weapon_tdmrp_cs_desert_eagle"] = "f",
    ["weapon_tdmrp_cs_mp5a5"] = "x",
    ["weapon_tdmrp_cs_p90"] = "m",
    ["weapon_tdmrp_cs_mac10"] = "k",
    ["weapon_tdmrp_cs_tmp"] = "d",
    ["weapon_tdmrp_cs_ump_45"] = "q",
    ["weapon_tdmrp_cs_ak47"] = "b",
    ["weapon_tdmrp_cs_m4a1"] = "w",
    ["weapon_tdmrp_cs_aug"] = "e",
    ["weapon_tdmrp_cs_famas"] = "t",
    ["weapon_tdmrp_cs_sg552"] = "A",
    ["weapon_tdmrp_cs_galil"] = "v",
    ["weapon_tdmrp_cs_pumpshotgun"] = "k",
    ["weapon_tdmrp_cs_awp"] = "r",
    ["weapon_tdmrp_cs_scout"] = "n",
    ["weapon_tdmrp_cs_knife"] = "j",
}

-- Create CSS Kill Icon font if not exists
surface.CreateFont("TDMRP_CSKillIcon", {
    font = "csd",  -- CS:S weapon icons
    size = 48,
    weight = 500,
    antialias = true,
    additive = false,
})

----------------------------------------------------
-- Weapon Icon Cache (for M9K model renders)
----------------------------------------------------

local weaponIconCache = {}

local function GetWeaponIcon(weaponClass)
    -- Check if already cached
    if weaponIconCache[weaponClass] then
        return weaponIconCache[weaponClass]
    end
    
    -- Try to get weapon's SelectIcon material
    local wepTable = weapons.Get(weaponClass)
    if wepTable then
        -- Check for WepSelectIcon (common M9K field) - must be a string
        if wepTable.WepSelectIcon and type(wepTable.WepSelectIcon) == "string" then
            local success, mat = pcall(Material, wepTable.WepSelectIcon)
            if success and mat and not mat:IsError() then
                weaponIconCache[weaponClass] = { type = "material", mat = mat }
                return weaponIconCache[weaponClass]
            end
        end
    end
    
    -- No icon found
    weaponIconCache[weaponClass] = nil
    return nil
end

----------------------------------------------------
-- UI State
----------------------------------------------------

local loadoutPanel = nil
local selectedWeapons = {
    Primary = nil,
    Secondary = nil,
    Gear = nil,
}
local availableLoadout = nil
local boundWeapons = {}       -- Bound weapons data from server
local boundWeaponClasses = {} -- Quick lookup table for bound weapon classes
local spawnTime = 0
local hoveredWeapon = {
    slot = nil,
    index = nil,
}

----------------------------------------------------
-- Helper: Weapon Display Name
----------------------------------------------------

local function GetWeaponDisplayName(class)
    if not class then return "Unknown" end
    
    -- Try to get from M9K registry first
    if TDMRP and TDMRP.M9KRegistry then
        local baseClass = string.Replace(class, "tdmrp_m9k_", "m9k_")
        local regEntry = TDMRP.M9KRegistry[baseClass]
        if regEntry and regEntry.name then
            return regEntry.name
        end
    end
    
    -- Fallback: try weapon entity
    local wepTable = weapons.Get(class)
    if wepTable and wepTable.PrintName then
        return wepTable.PrintName
    end
    
    -- Last resort: format class name
    local formatted = string.Replace(class, "tdmrp_m9k_", "")
    formatted = string.Replace(formatted, "weapon_tdmrp_cs_", "")
    formatted = string.Replace(formatted, "_", " ")
    return string.upper(formatted)
end

----------------------------------------------------
-- Helper: Draw Weapon Icon
----------------------------------------------------

local function DrawWeaponIcon(x, y, size, weaponClass, alpha)
    alpha = alpha or 255
    local C = TDMRP.UI.Colors
    
    -- Check for CSS weapon killicon
    local cssLetter = CSS_ICON_LETTERS[weaponClass]
    if cssLetter then
        -- Draw CSS killicon using the font
        draw.SimpleText(cssLetter, "TDMRP_CSKillIcon", x + size/2, y + size/2, 
            ColorAlpha(Color(255, 180, 0), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end
    
    -- Try M9K weapon icon material
    local iconData = GetWeaponIcon(weaponClass)
    if iconData and iconData.type == "material" then
        surface.SetMaterial(iconData.mat)
        surface.SetDrawColor(255, 255, 255, alpha)
        surface.DrawTexturedRect(x, y, size, size)
        return
    end
    
    -- Fallback: Draw placeholder with first letter
    local displayName = GetWeaponDisplayName(weaponClass)
    local letter = string.upper(string.sub(displayName, 1, 1))
    
    draw.RoundedBox(4, x, y, size, size, ColorAlpha(C.bg_dark, alpha))
    surface.SetDrawColor(ColorAlpha(C.border_light, alpha))
    surface.DrawOutlinedRect(x, y, size, size, 1)
    draw.SimpleText(letter, "TDMRP_Header", x + size/2, y + size/2, 
        ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

----------------------------------------------------
-- Helper: Draw weapon slot button
----------------------------------------------------

local function DrawWeaponSlot(x, y, w, h, weaponClass, isSelected, isHovered, alpha, isDisabled)
    local C = TDMRP.UI.Colors
    
    -- Background
    local bgColor = C.bg_light
    if isDisabled then
        bgColor = Color(60, 60, 60, 180) -- Grey disabled
    elseif isSelected then
        bgColor = Color(0, 150, 0, 220) -- Green selection
    elseif isHovered then
        bgColor = C.bg_hover
    end
    
    draw.RoundedBox(6, x, y, w, h, ColorAlpha(bgColor, alpha))
    
    -- Border outline (not filled box)
    local borderColor = C.border_dark
    if isDisabled then
        borderColor = Color(100, 100, 100, 150)
    elseif isSelected then
        borderColor = Color(0, 255, 0, 255) -- Bright green border
    end
    surface.SetDrawColor(borderColor)
    surface.DrawOutlinedRect(x, y, w, h, 2)
    
    -- Weapon icon (using new icon system)
    local iconSize = 50
    local iconX = x + 15
    local iconY = y + (h - iconSize) / 2
    local textAlpha = isDisabled and (alpha * 0.5) or alpha
    
    DrawWeaponIcon(iconX, iconY, iconSize, weaponClass, textAlpha)
    
    -- Weapon name
    local nameX = iconX + iconSize + 15
    local nameY = y + h / 2 - 10
    local textColor = isDisabled and C.text_muted or C.text_primary
    draw.SimpleText(GetWeaponDisplayName(weaponClass), "TDMRP_Body", nameX, nameY, ColorAlpha(textColor, textAlpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Class name (small text below) or "BOUND WEAPON" indicator
    if isDisabled then
        draw.SimpleText("(You have a bound weapon)", "TDMRP_Small", nameX, nameY + 20, ColorAlpha(Color(255, 180, 0), textAlpha * 0.8), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        -- Show shortened class name
        local shortClass = string.Replace(weaponClass, "tdmrp_m9k_", "")
        shortClass = string.Replace(shortClass, "weapon_tdmrp_cs_", "css:")
        draw.SimpleText(shortClass, "TDMRP_Small", nameX, nameY + 20, ColorAlpha(C.text_muted, textAlpha * 0.8), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
end

----------------------------------------------------
-- Helper: Draw column
----------------------------------------------------

local function DrawColumn(x, y, w, h, slotName, weaponList, selectedIndex, alpha, mx, my)
    local C = TDMRP.UI.Colors
    
    -- Column background
    draw.RoundedBox(8, x, y, w, h, ColorAlpha(C.bg_medium, alpha * 0.9))
    
    -- Header
    local headerHeight = 50
    draw.RoundedBox(8, x, y, w, headerHeight, ColorAlpha(C.bg_dark, alpha))
    draw.SimpleText(slotName, "TDMRP_Header", x + w/2, y + headerHeight/2, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Weapon slots
    local slotY = y + headerHeight + CONFIG.PADDING
    for i, weaponClass in ipairs(weaponList) do
        local slotH = CONFIG.WEAPON_SLOT_HEIGHT
        local isSelected = (i == selectedIndex)
        local isDisabled = boundWeaponClasses[weaponClass] == true  -- Check if player has bound weapon of this class
        local isHovered = not isDisabled and (mx >= x and mx <= x + w and my >= slotY and my <= slotY + slotH)
        
        if isHovered then
            hoveredWeapon.slot = slotName
            hoveredWeapon.index = i
        end
        
        DrawWeaponSlot(x + 10, slotY, w - 20, slotH, weaponClass, isSelected, isHovered, alpha, isDisabled)
        
        slotY = slotY + slotH + 10
    end
end

----------------------------------------------------
-- Helper: Auto-select defaults
----------------------------------------------------

local function AutoSelectDefaults()
    if not availableLoadout then return end
    
    selectedWeapons.Primary = 1
    selectedWeapons.Secondary = 1
    selectedWeapons.Gear = 1
    
    print("[TDMRP Loadout] Auto-selected defaults (timeout)")
end

----------------------------------------------------
-- Helper: Confirm selection and send to server
----------------------------------------------------

local function ConfirmLoadout()
    if not selectedWeapons.Primary or not selectedWeapons.Secondary or not selectedWeapons.Gear then
        print("[TDMRP Loadout] Cannot confirm: not all slots selected")
        return
    end
    
    if not availableLoadout then
        print("[TDMRP Loadout] Cannot confirm: no loadout data")
        return
    end
    
    -- Build weapon class list
    local chosenWeapons = {
        Primary = availableLoadout.Primary[selectedWeapons.Primary],
        Secondary = availableLoadout.Secondary[selectedWeapons.Secondary],
        Gear = availableLoadout.Gear[selectedWeapons.Gear],
    }
    
    print("[TDMRP Loadout] Confirming: " .. chosenWeapons.Primary .. ", " .. chosenWeapons.Secondary .. ", " .. chosenWeapons.Gear)
    
    -- Send to server
    net.Start("TDMRP_LoadoutConfirmed")
        net.WriteString(chosenWeapons.Primary)
        net.WriteString(chosenWeapons.Secondary)
        net.WriteString(chosenWeapons.Gear)
    net.SendToServer()
    
    -- Close UI
    if IsValid(loadoutPanel) then
        loadoutPanel:Remove()
        loadoutPanel = nil
    end
    
    -- Reset state
    selectedWeapons = { Primary = nil, Secondary = nil, Gear = nil }
    availableLoadout = nil
end

----------------------------------------------------
-- Network Receiver: Show Loadout Menu
----------------------------------------------------

net.Receive("TDMRP_ShowLoadoutMenu", function()
    local primaryList = net.ReadTable()
    local secondaryList = net.ReadTable()
    local gearList = net.ReadTable()
    local savedPrimary = net.ReadUInt(8)
    local savedSecondary = net.ReadUInt(8)
    local savedGear = net.ReadUInt(8)
    local boundWeaponData = net.ReadTable()  -- Bound weapons from server
    
    print("[TDMRP Loadout] Received loadout menu with " .. #primaryList .. " primaries, " .. #secondaryList .. " secondaries, " .. #gearList .. " gear, " .. #boundWeaponData .. " bound weapons")
    
    -- Store bound weapons data
    boundWeapons = boundWeaponData or {}
    boundWeaponClasses = {}
    for _, bw in ipairs(boundWeapons) do
        boundWeaponClasses[bw.class] = true
        print("[TDMRP Loadout] Bound weapon: " .. bw.class .. " (" .. string.format("%.0f", bw.remaining) .. "s remaining)")
    end
    
    -- Store loadout data
    availableLoadout = {
        Primary = primaryList,
        Secondary = secondaryList,
        Gear = gearList,
    }
    
    -- Restore saved selections (0 means no saved choice)
    -- But skip if selection is disabled due to bound weapon
    selectedWeapons = {
        Primary = nil,
        Secondary = nil,
        Gear = nil,
    }
    
    -- Only restore saved choice if it's not disabled
    if savedPrimary > 0 and primaryList[savedPrimary] and not boundWeaponClasses[primaryList[savedPrimary]] then
        selectedWeapons.Primary = savedPrimary
    end
    if savedSecondary > 0 and secondaryList[savedSecondary] and not boundWeaponClasses[secondaryList[savedSecondary]] then
        selectedWeapons.Secondary = savedSecondary
    end
    if savedGear > 0 then
        selectedWeapons.Gear = savedGear
    end
    
    if savedPrimary > 0 or savedSecondary > 0 or savedGear > 0 then
        print(string.format("[TDMRP Loadout] Restored saved choices: P=%d S=%d G=%d", savedPrimary, savedSecondary, savedGear))
    end
    
    -- Start spawn timer
    spawnTime = CurTime()
    
    -- Create UI panel if not exists
    if IsValid(loadoutPanel) then
        loadoutPanel:Remove()
    end
    
    loadoutPanel = vgui.Create("DPanel")
    loadoutPanel:SetPos(0, 0)
    loadoutPanel:SetSize(ScrW(), ScrH())
    loadoutPanel:MakePopup()
    loadoutPanel:SetKeyboardInputEnabled(true)
    loadoutPanel:SetMouseInputEnabled(true)
    
    -- Custom paint
    loadoutPanel.Paint = function(self, w, h)
        local C = TDMRP.UI.Colors
        
        -- Reset hover state at start of frame
        hoveredWeapon = { slot = nil, index = nil }
        
        -- Black overlay
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, CONFIG.SCREEN_ALPHA))
        
        -- Title
        local titleAlpha = 255
        draw.SimpleText("SELECT YOUR LOADOUT", "TDMRP_Title", w/2, 50, ColorAlpha(C.text_primary, titleAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        -- Timeout timer
        local timeLeft = math.max(0, CONFIG.TIMEOUT - (CurTime() - spawnTime))
        local timerText = string.format("Auto-spawn in %.1f seconds", timeLeft)
        local timerColor = C.text_secondary
        if timeLeft < 5 then
            timerColor = C.warning
        end
        draw.SimpleText(timerText, "TDMRP_SubHeader", w/2, 90, ColorAlpha(timerColor, titleAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        -- Check timeout
        if timeLeft <= 0 and (not selectedWeapons.Primary or not selectedWeapons.Secondary or not selectedWeapons.Gear) then
            AutoSelectDefaults()
            ConfirmLoadout()
            return
        end
        
        -- Get mouse position
        local mx, my = self:LocalCursorPos()
        
        -- Calculate column positions
        local totalWidth = (CONFIG.COLUMN_WIDTH * 3) + (CONFIG.PADDING * 2)
        local startX = (w - totalWidth) / 2
        local startY = 150
        
        -- Draw bound weapons section if player has any
        if #boundWeapons > 0 then
            local boundY = 115
            draw.SimpleText("BOUND WEAPONS (will be restored with -30s penalty):", "TDMRP_Body", w/2, boundY, ColorAlpha(Color(255, 200, 50), titleAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            
            local boundListY = boundY + 20
            local boundList = {}
            for _, bw in ipairs(boundWeapons) do
                local mins = math.floor(bw.remaining / 60)
                local secs = math.floor(bw.remaining % 60)
                table.insert(boundList, string.format("%s (%02d:%02d)", bw.displayName or bw.class, mins, secs))
            end
            draw.SimpleText(table.concat(boundList, " | "), "TDMRP_Small", w/2, boundListY, ColorAlpha(Color(200, 200, 200), titleAlpha * 0.9), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            
            startY = 165  -- Push columns down to make room
        end
        
        -- Draw columns
        if availableLoadout then
            DrawColumn(startX, startY, CONFIG.COLUMN_WIDTH, CONFIG.COLUMN_HEIGHT, "PRIMARY", availableLoadout.Primary, selectedWeapons.Primary, 255, mx, my)
            DrawColumn(startX + CONFIG.COLUMN_WIDTH + CONFIG.PADDING, startY, CONFIG.COLUMN_WIDTH, CONFIG.COLUMN_HEIGHT, "SECONDARY", availableLoadout.Secondary, selectedWeapons.Secondary, 255, mx, my)
            DrawColumn(startX + (CONFIG.COLUMN_WIDTH + CONFIG.PADDING) * 2, startY, CONFIG.COLUMN_WIDTH, CONFIG.COLUMN_HEIGHT, "GEAR", availableLoadout.Gear, selectedWeapons.Gear, 255, mx, my)
        end
        
        -- Button row Y position
        local btnRowY = startY + CONFIG.COLUMN_HEIGHT + 30
        
        -- Confirm button
        local allSelected = selectedWeapons.Primary and selectedWeapons.Secondary and selectedWeapons.Gear
        local btnW = 250
        local btnH = 50
        local btnX = (w - btnW) / 2
        local btnY = btnRowY
        
        local btnText = allSelected and "CONFIRM LOADOUT" or "SELECT ALL SLOTS"
        local btnHovered = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH
        
        -- Only allow hover effect if all selected
        local btnCanHover = allSelected and btnHovered
        TDMRP.UI.DrawButton(btnX, btnY, btnW, btnH, btnText, btnCanHover, false, not allSelected, 6)
        
        -- Bypass button (always show as fallback, but disabled if no bound weapons)
        local bypassBtnW = 280
        local bypassBtnH = 40
        local bypassBtnX = (w - bypassBtnW) / 2
        local bypassBtnY = btnY + btnH + 15
        
        local bypassCanUse = #boundWeapons > 0
        local bypassHovered = bypassCanUse and (mx >= bypassBtnX and mx <= bypassBtnX + bypassBtnW and my >= bypassBtnY and my <= bypassBtnY + bypassBtnH)
        
        -- Draw bypass button with different style
        local bypassBgColor = bypassHovered and Color(100, 80, 20, 220) or Color(60, 50, 20, 200)
        if not bypassCanUse then
            bypassBgColor = Color(40, 40, 40, 120)
        end
        draw.RoundedBox(6, bypassBtnX, bypassBtnY, bypassBtnW, bypassBtnH, bypassBgColor)
        surface.SetDrawColor(Color(200, 150, 50, bypassCanUse and 200 or 100))
        surface.DrawOutlinedRect(bypassBtnX, bypassBtnY, bypassBtnW, bypassBtnH, 2)
        local bypassText = bypassCanUse and "BYPASS LOADOUT (Spawn with only gear)" or "BYPASS LOADOUT (no bound weapons)"
        local bypassTextColor = bypassCanUse and Color(255, 200, 100, 255) or Color(150, 150, 150, 150)
        draw.SimpleText(bypassText, "TDMRP_Body", bypassBtnX + bypassBtnW/2, bypassBtnY + bypassBtnH/2, bypassTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Instructions
        local instructY = h - 50
        local instructText = "Click to select weapons | All slots required to continue"
        if #boundWeapons > 0 then
            instructText = "Click to select weapons | Greyed weapons conflict with your bound weapons"
        end
        draw.SimpleText(instructText, "TDMRP_Small", w/2, instructY, ColorAlpha(C.text_muted, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    -- Mouse click handler
    loadoutPanel.OnMousePressed = function(self, keyCode)
        if keyCode ~= MOUSE_LEFT then return end
        
        local mx, my = self:LocalCursorPos()
        local w, h = self:GetSize()
        
        -- Recalculate column positions (account for bound weapons header)
        local totalWidth = (CONFIG.COLUMN_WIDTH * 3) + (CONFIG.PADDING * 2)
        local startX = (w - totalWidth) / 2
        local startY = #boundWeapons > 0 and 165 or 150  -- Push down if bound weapons shown
        
        -- Helper to check if click is in a column and return slot name + index
        local function GetClickedSlot(colX, colW, slotName, weaponList)
            if mx >= colX and mx <= colX + colW then
                -- Click is in this column, find which weapon slot
                local slotY = startY + 50 + CONFIG.PADDING  -- 50 = header height
                for i, weaponClass in ipairs(weaponList) do
                    local slotH = CONFIG.WEAPON_SLOT_HEIGHT
                    if my >= slotY and my <= slotY + slotH then
                        -- Check if this weapon is disabled (bound conflict)
                        if boundWeaponClasses[weaponClass] then
                            return nil, nil, true  -- Return disabled flag
                        end
                        return slotName, i, false
                    end
                    slotY = slotY + slotH + 10
                end
            end
            return nil, nil, false
        end
        
        -- Check which column was clicked
        if availableLoadout then
            local slot, index, isDisabled = GetClickedSlot(startX, CONFIG.COLUMN_WIDTH, "Primary", availableLoadout.Primary)
            if isDisabled then
                surface.PlaySound("buttons/button10.wav") -- Error sound
                return
            end
            if slot then
                selectedWeapons[slot] = index
                print("[TDMRP Loadout] Selected " .. slot .. " slot " .. index)
                surface.PlaySound("buttons/button14.wav")
                return
            end
            
            slot, index, isDisabled = GetClickedSlot(startX + CONFIG.COLUMN_WIDTH + CONFIG.PADDING, CONFIG.COLUMN_WIDTH, "Secondary", availableLoadout.Secondary)
            if isDisabled then
                surface.PlaySound("buttons/button10.wav")
                return
            end
            if slot then
                selectedWeapons[slot] = index
                print("[TDMRP Loadout] Selected " .. slot .. " slot " .. index)
                surface.PlaySound("buttons/button14.wav")
                return
            end
            
            slot, index, isDisabled = GetClickedSlot(startX + (CONFIG.COLUMN_WIDTH + CONFIG.PADDING) * 2, CONFIG.COLUMN_WIDTH, "Gear", availableLoadout.Gear)
            if isDisabled then
                surface.PlaySound("buttons/button10.wav")
                return
            end
            if slot then
                selectedWeapons[slot] = index
                print("[TDMRP Loadout] Selected " .. slot .. " slot " .. index)
                surface.PlaySound("buttons/button14.wav")
                return
            end
        end
        
        -- Check if clicked confirm button (only allow if all selected)
        local allSelected = selectedWeapons.Primary and selectedWeapons.Secondary and selectedWeapons.Gear
        local btnW = 250
        local btnH = 50
        local btnX = (w - btnW) / 2
        local btnY = startY + CONFIG.COLUMN_HEIGHT + 30
        
        if mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH then
            if allSelected then
                print("[TDMRP Loadout] Confirm button clicked with all slots selected")
                surface.PlaySound("buttons/button15.wav")
                ConfirmLoadout()
            else
                print(string.format("[TDMRP Loadout] Confirm button clicked but not all selected: P=%s S=%s G=%s",
                    tostring(selectedWeapons.Primary),
                    tostring(selectedWeapons.Secondary),
                    tostring(selectedWeapons.Gear)))
                surface.PlaySound("buttons/button10.wav") -- Error sound
            end
            return
        end
        
        -- Check if clicked bypass button (only functional if player has bound weapons)
        local bypassBtnW = 280
        local bypassBtnH = 40
        local bypassBtnX = (w - bypassBtnW) / 2
        local bypassBtnY = btnY + btnH + 15
        
        if mx >= bypassBtnX and mx <= bypassBtnX + bypassBtnW and my >= bypassBtnY and my <= bypassBtnY + bypassBtnH then
            if #boundWeapons > 0 then
                print("[TDMRP Loadout] Bypass button clicked - spawning with bound weapons only")
                surface.PlaySound("buttons/button15.wav")
                
                -- Send bypass request to server
                net.Start("TDMRP_LoadoutBypass")
                net.SendToServer()
                
                -- Close UI
                if IsValid(loadoutPanel) then
                    loadoutPanel:Remove()
                    loadoutPanel = nil
                end
                
                -- Reset state
                selectedWeapons = { Primary = nil, Secondary = nil, Gear = nil }
                availableLoadout = nil
                boundWeapons = {}
                boundWeaponClasses = {}
            else
                -- No bound weapons
                print("[TDMRP Loadout] Bypass button disabled - no bound weapons")
                surface.PlaySound("buttons/button10.wav")
            end
            return
        end
    end
    
    -- Keyboard handler (ESC blocked - must confirm)
    loadoutPanel.OnKeyCodePressed = function(self, keyCode)
        if keyCode == KEY_ESCAPE then
            -- Block ESC - player must select and confirm
            return true
        end
    end
end)

----------------------------------------------------
-- Network Receiver: Timeout (server forced spawn)
----------------------------------------------------

net.Receive("TDMRP_LoadoutTimeout", function()
    print("[TDMRP Loadout] Server timeout - forced spawn")
    
    -- Close UI
    if IsValid(loadoutPanel) then
        loadoutPanel:Remove()
        loadoutPanel = nil
    end
    
    -- Reset state
    selectedWeapons = { Primary = nil, Secondary = nil, Gear = nil }
    availableLoadout = nil
    boundWeapons = {}
    boundWeaponClasses = {}
end)

----------------------------------------------------
-- Cleanup on disconnect
----------------------------------------------------

hook.Add("ShutDown", "TDMRP_LoadoutUI_Cleanup", function()
    if IsValid(loadoutPanel) then
        loadoutPanel:Remove()
    end
end)

print("[TDMRP] Loadout UI loaded")
