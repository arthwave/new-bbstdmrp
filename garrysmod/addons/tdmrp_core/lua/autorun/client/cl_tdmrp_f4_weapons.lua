----------------------------------------------------
-- TDMRP F4 Menu - Weapons Shop Tab
-- Purchase weapons with 3D model previews
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.F4Menu = TDMRP.F4Menu or {}

----------------------------------------------------
-- Weapons Tab Configuration
----------------------------------------------------

local Config = {
    cardWidth = 140,
    cardHeight = 180,
    cardPadding = 10,
    filterHeight = 45,
    infoPanelWidth = 300,
    scrollSpeed = 40,
}

----------------------------------------------------
-- State
----------------------------------------------------

local scrollOffset = 0
local maxScroll = 0
local hoveredWeapon = nil
local selectedWeapon = nil
local selectedType = "all"
local lastClickTime = 0
local purchaseFlash = {}
local weaponModelPanels = {}
local weaponModelContainer = nil

-- Tier 1 = Common is the only purchasable tier
local SHOP_TIER = 1

----------------------------------------------------
-- Weapon Types
----------------------------------------------------

local typeFilters = {
    { id = "all", name = "ALL" },
    { id = "pistol", name = "PISTOLS" },
    { id = "revolver", name = "REVOLVERS" },
    { id = "smg", name = "SMGS" },
    { id = "pdw", name = "PDWS" },
    { id = "rifle", name = "RIFLES" },
    { id = "shotgun", name = "SHOTGUNS" },
    { id = "sniper", name = "SNIPERS" },
    { id = "lmg", name = "LMGS" },
}

----------------------------------------------------
-- Helper: Get filtered weapons
----------------------------------------------------

local function GetFilteredWeapons()
    local weapons = {}
    
    -- Use the M9K weapon registry
    if not TDMRP.M9KRegistry then return weapons end
    
    for class, meta in pairs(TDMRP.M9KRegistry) do
        local wepType = meta.type or "pistol"
        if selectedType == "all" or wepType == selectedType then
            table.insert(weapons, {
                class = class,
                meta = meta,
            })
        end
    end
    
    -- Sort by type then name
    table.sort(weapons, function(a, b)
        if a.meta.type ~= b.meta.type then
            return (a.meta.type or "") < (b.meta.type or "")
        end
        return (a.meta.name or "") < (b.meta.name or "")
    end)
    
    return weapons
end

----------------------------------------------------
-- Weapon Model Panel Management
----------------------------------------------------

local function ClearWeaponModelPanels()
    for _, panel in pairs(weaponModelPanels) do
        if IsValid(panel) then
            panel:Remove()
        end
    end
    weaponModelPanels = {}
end

local function HideAllWeaponPanels()
    for _, panel in pairs(weaponModelPanels) do
        if IsValid(panel) then
            panel:SetVisible(false)
        end
    end
end

local function GetOrCreateWeaponModelPanel(class, worldModel, x, y, size)
    local key = class .. "_" .. size
    
    if weaponModelPanels[key] and IsValid(weaponModelPanels[key]) then
        local panel = weaponModelPanels[key]
        panel:SetPos(x, y)
        panel:SetVisible(true)
        return panel
    end
    
    -- Parent model container to F4 menu so it renders AFTER menu's Paint()
    -- This means scissor rect in Paint() won't affect these panels
    local menuPanel = TDMRP.F4Menu.GetPanel()
    if not IsValid(menuPanel) then return nil end
    
    if not IsValid(weaponModelContainer) then
        weaponModelContainer = vgui.Create("DPanel", menuPanel)
        weaponModelContainer:SetPos(0, 0)
        weaponModelContainer:SetSize(ScrW(), ScrH())
        weaponModelContainer:SetMouseInputEnabled(false)
        weaponModelContainer:SetKeyboardInputEnabled(false)
        weaponModelContainer.Paint = function() end
    end
    
    local panel = vgui.Create("DModelPanel", weaponModelContainer)
    panel:SetPos(x, y)
    panel:SetSize(size, size)
    
    if worldModel and worldModel ~= "" then
        panel:SetModel(worldModel)
    else
        -- Try to get model from weapon info
        local wepInfo = weapons.GetStored(class)
        if wepInfo and wepInfo.WorldModel then
            panel:SetModel(wepInfo.WorldModel)
        else
            panel:SetModel("models/weapons/w_pist_p228.mdl")
        end
    end
    
    panel:SetFOV(50)
    panel:SetCamPos(Vector(30, 20, 10))
    panel:SetLookAt(Vector(0, 0, 0))
    panel:SetMouseInputEnabled(false)
    
    -- Rotate animation
    panel.LayoutEntity = function(self, ent)
        if IsValid(ent) then
            ent:SetAngles(Angle(0, RealTime() * 40 % 360, 0))
        end
    end
    
    weaponModelPanels[key] = panel
    return panel
end

----------------------------------------------------
-- Helper: Get weapon price from registry
----------------------------------------------------

local function GetWeaponPrice(class)
    if not TDMRP.M9KRegistry then return 5000 end
    local meta = TDMRP.M9KRegistry[class]
    if not meta then return 5000 end
    return meta.price or 5000
end

----------------------------------------------------
-- Helper: Get tier stats (always Tier 1 for shop)
----------------------------------------------------

local function GetTierStats(meta)
    -- Shop only sells Tier 1 (Common) - no stat scaling
    local baseDamage = meta.baseDamage or 25
    local baseRPM = meta.baseRPM or 600
    
    return {
        damage = math.floor(baseDamage),
        rpm = math.floor(baseRPM),
    }
end

----------------------------------------------------
-- Paint Function
----------------------------------------------------

local function PaintWeapons(x, y, w, h, alpha, mx, my, scroll)
    local C = TDMRP.UI.Colors
    local ply = LocalPlayer()
    local money = IsValid(ply) and (ply:getDarkRPVar("money") or 0) or 0
    
    -- Hide all weapon panels first
    HideAllWeaponPanels()
    
    -- Header
    draw.SimpleText("WEAPON SHOP", "TDMRP_Header", x + 20, y + 12, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(TDMRP.UI.FormatMoney(money), "TDMRP_Body", x + w - 25, y + 15, ColorAlpha(C.accent, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    
    -- Layout: Grid + info panel
    local infoPanelW = Config.infoPanelWidth
    local gridW = w - infoPanelW - 35
    local gridX = x + 15
    
    -- Filter bar
    local filterY = y + 45
    draw.RoundedBox(4, gridX, filterY, gridW, Config.filterHeight, ColorAlpha(C.bg_dark, alpha))
    
    -- Type filter buttons
    local filterBtnW = math.floor((gridW - 20 - (#typeFilters - 1) * 5) / #typeFilters)
    filterBtnW = math.min(filterBtnW, 80)
    
    for i, filter in ipairs(typeFilters) do
        local btnX = gridX + 10 + (i-1) * (filterBtnW + 5)
        local btnY = filterY + 8
        local btnH = 28
        
        local isActive = (filter.id == selectedType)
        local isHovered = mx >= btnX and mx <= btnX + filterBtnW and my >= btnY and my <= btnY + btnH
        
        local btnBg = isActive and C.accent or (isHovered and C.bg_hover or C.bg_light)
        draw.RoundedBox(4, btnX, btnY, filterBtnW, btnH, ColorAlpha(btnBg, alpha))
        
        local textColor = isActive and C.text_primary or (isHovered and C.text_primary or C.text_secondary)
        draw.SimpleText(filter.name, "TDMRP_Tiny", btnX + filterBtnW/2, btnY + btnH/2, ColorAlpha(textColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Show "COMMON TIER" label on right side (no tier selector - shop only sells Tier 1)
    local tierColor = C.tier and C.tier[SHOP_TIER] or Color(180, 180, 180, 255)
    draw.SimpleText("COMMON TIER", "TDMRP_SmallBold", gridX + gridW - 15, filterY + 20, ColorAlpha(tierColor, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    
    -- Weapon grid area
    local contentY = filterY + Config.filterHeight + 10
    local contentH = h - (contentY - y) - 10
    
    local weapons = GetFilteredWeapons()
    local cols = math.floor(gridW / (Config.cardWidth + Config.cardPadding))
    cols = math.max(cols, 2)
    local cardW = math.floor((gridW - (cols - 1) * Config.cardPadding) / cols)
    local cardH = Config.cardHeight
    
    local drawY = contentY - scrollOffset
    hoveredWeapon = nil
    
    -- Scissor rect for grid area to clip cards at top/bottom boundaries
    render.SetScissorRect(gridX, contentY, gridX + gridW, contentY + contentH, true)
    
    local col = 0
    for i, weaponData in ipairs(weapons) do
        local cardX = gridX + col * (cardW + Config.cardPadding)
        local cardY = drawY
        
        if cardY + cardH > contentY and cardY < contentY + contentH then
            local meta = weaponData.meta
            local class = weaponData.class
            local price = GetWeaponPrice(class)
            local canAfford = money >= price
            
            local isHovered = mx >= cardX and mx <= cardX + cardW and my >= cardY and my <= cardY + cardH and my >= contentY
            local isSelected = selectedWeapon and selectedWeapon.class == class
            
            if isHovered then
                hoveredWeapon = { class = class, meta = meta, tier = SHOP_TIER, price = price }
            end
            
            -- Card background
            local selTierColor = C.tier and C.tier[SHOP_TIER] or Color(180, 180, 180, 255)
            local cardBg = isSelected and Color(selTierColor.r, selTierColor.g, selTierColor.b, 40) or (isHovered and C.bg_hover or C.bg_light)
            draw.RoundedBox(6, cardX, cardY, cardW, cardH, ColorAlpha(cardBg, alpha))
            
            -- Purchase flash
            if purchaseFlash[class] and purchaseFlash[class] > CurTime() then
                local flashAlpha = (purchaseFlash[class] - CurTime()) * 400
                draw.RoundedBox(6, cardX, cardY, cardW, cardH, ColorAlpha(C.success, flashAlpha))
            end
            
            -- Border
            local tierColor = C.tier and C.tier[SHOP_TIER] or Color(180, 180, 180, 255)
            if isSelected then
                surface.SetDrawColor(ColorAlpha(tierColor, alpha))
                surface.DrawOutlinedRect(cardX, cardY, cardW, cardH, 2)
            elseif isHovered then
                surface.SetDrawColor(ColorAlpha(C.accent, alpha * 0.6))
                surface.DrawOutlinedRect(cardX, cardY, cardW, cardH, 1)
            end
            
            -- Tier badge (always Common)
            draw.RoundedBox(4, cardX + cardW - 28, cardY + 5, 23, 16, ColorAlpha(tierColor, alpha * 0.3))
            draw.SimpleText("C", "TDMRP_Tiny", cardX + cardW - 16, cardY + 13, ColorAlpha(tierColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- 3D Weapon model
            local modelSize = math.min(cardW - 16, 70)
            local modelX = cardX + (cardW - modelSize) / 2
            local modelY = cardY + 20
            
            -- Get world model from meta or fallback
            local worldModel = meta.worldModel or nil
            if not worldModel then
                -- Try weapons.GetStored as backup (may be nil on client for some addons)
                local wepInfo = weapons and weapons.GetStored and weapons.GetStored(class)
                worldModel = wepInfo and wepInfo.WorldModel or nil
            end
            
            local modelPanel = GetOrCreateWeaponModelPanel(class, worldModel, modelX, modelY, modelSize)
            if IsValid(modelPanel) then
                -- Only show if model is FULLY within visible content area
                local isInBounds = modelY >= contentY and modelY + modelSize <= contentY + contentH
                modelPanel:SetVisible(isInBounds)
                if isInBounds then
                    modelPanel:SetAlpha(alpha)
                end
            end
            
            -- Weapon name
            local nameY = cardY + modelSize + 28
            surface.SetFont("TDMRP_SmallBold")
            local nameText = meta.name or class
            local nameW = surface.GetTextSize(nameText)
            if nameW > cardW - 10 then
                while nameW > cardW - 16 and #nameText > 5 do
                    nameText = string.sub(nameText, 1, -2)
                    nameW = surface.GetTextSize(nameText .. "..")
                end
                nameText = nameText .. ".."
            end
            draw.SimpleText(nameText, "TDMRP_SmallBold", cardX + cardW/2, nameY, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            
            -- Type
            local typeText = string.upper(meta.type or "WEAPON")
            draw.SimpleText(typeText, "TDMRP_Tiny", cardX + cardW/2, nameY + 16, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            
            -- Price
            local priceY = cardY + cardH - 28
            local priceColor = canAfford and C.success or C.error
            draw.RoundedBox(4, cardX + 8, priceY, cardW - 16, 22, ColorAlpha(C.bg_dark, alpha))
            draw.SimpleText(TDMRP.UI.FormatMoney(price), "TDMRP_SmallBold", cardX + cardW/2, priceY + 11, ColorAlpha(priceColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        col = col + 1
        if col >= cols then
            col = 0
            drawY = drawY + cardH + Config.cardPadding
        end
    end
    
    -- End scissor rect for grid area
    render.SetScissorRect(0, 0, 0, 0, false)
    
    -- Calculate scroll
    local totalRows = math.ceil(#weapons / cols)
    local contentHeight = totalRows * (cardH + Config.cardPadding)
    maxScroll = math.max(0, contentHeight - contentH + 20)
    
    -- Info panel on right
    local infoPanelX = x + w - infoPanelW - 10
    local infoPanelY = y + 10
    local infoPanelH = h - 20
    
    draw.RoundedBox(6, infoPanelX, infoPanelY, infoPanelW, infoPanelH, ColorAlpha(C.bg_dark, alpha))
    
    local displayWeapon = hoveredWeapon or selectedWeapon
    
    if displayWeapon then
        local padX = infoPanelX + 15
        local padY = infoPanelY + 15
        local tier = SHOP_TIER
        local tierColor = C.tier and C.tier[tier] or Color(180, 180, 180, 255)
        local meta = displayWeapon.meta
        
        -- Weapon name
        draw.SimpleText(meta.name or displayWeapon.class, "TDMRP_SubHeader", padX, padY, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        padY = padY + 24
        
        -- Tier label (always Common)
        local tierName = TDMRP.TierNames and TDMRP.TierNames[tier] or "Common"
        draw.SimpleText(tierName, "TDMRP_Body", padX, padY, ColorAlpha(tierColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        padY = padY + 30
        
        -- Divider
        surface.SetDrawColor(ColorAlpha(C.border_dark, alpha))
        surface.DrawRect(padX, padY, infoPanelW - 30, 1)
        padY = padY + 15
        
        -- Stats
        local stats = GetTierStats(meta)
        
        draw.SimpleText("DAMAGE", "TDMRP_SmallBold", padX, padY, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(tostring(stats.damage), "TDMRP_Body", padX + infoPanelW - 50, padY, ColorAlpha(C.accent, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        padY = padY + 25
        
        draw.SimpleText("FIRE RATE", "TDMRP_SmallBold", padX, padY, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(tostring(stats.rpm) .. " RPM", "TDMRP_Body", padX + infoPanelW - 50, padY, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        padY = padY + 25
        
        draw.SimpleText("TYPE", "TDMRP_SmallBold", padX, padY, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(string.upper(meta.type or "WEAPON"), "TDMRP_Body", padX + infoPanelW - 50, padY, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        padY = padY + 40
        
        -- Price
        local price = displayWeapon.price or GetWeaponPrice(displayWeapon.class)
        local canAfford = money >= price
        
        draw.SimpleText("PRICE", "TDMRP_SmallBold", padX, padY, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        padY = padY + 20
        draw.SimpleText(TDMRP.UI.FormatMoney(price), "TDMRP_Header", padX, padY, ColorAlpha(canAfford and C.success or C.error, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Buy button
        local btnY = infoPanelY + infoPanelH - 55
        local btnW = infoPanelW - 30
        local btnH = 42
        local btnX = infoPanelX + 15
        
        local btnHovered = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH
        
        local btnColor = canAfford and (btnHovered and C.accent_hover or C.accent) or C.text_muted
        draw.RoundedBox(6, btnX, btnY, btnW, btnH, ColorAlpha(btnColor, alpha))
        
        local btnText = canAfford and "PURCHASE" or "CAN'T AFFORD"
        draw.SimpleText(btnText, "TDMRP_BodyBold", btnX + btnW/2, btnY + btnH/2, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        -- No weapon selected
        draw.SimpleText("SELECT A WEAPON", "TDMRP_SubHeader", infoPanelX + infoPanelW/2, infoPanelY + 30, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Click on a weapon to", "TDMRP_Small", infoPanelX + infoPanelW/2, infoPanelY + 60, ColorAlpha(C.text_muted, alpha * 0.7), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("view details and purchase", "TDMRP_Small", infoPanelX + infoPanelW/2, infoPanelY + 76, ColorAlpha(C.text_muted, alpha * 0.7), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    -- Scroll indicators
    if scrollOffset > 0 then
        draw.RoundedBox(0, gridX, contentY, gridW, 15, ColorAlpha(C.bg_medium, alpha))
        draw.SimpleText("▲", "TDMRP_Tiny", gridX + gridW/2, contentY + 2, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    if scrollOffset < maxScroll then
        draw.RoundedBox(0, gridX, contentY + contentH - 15, gridW, 15, ColorAlpha(C.bg_medium, alpha))
        draw.SimpleText("▼", "TDMRP_Tiny", gridX + gridW/2, contentY + contentH - 13, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end

----------------------------------------------------
-- Click Handler
----------------------------------------------------

local function OnWeaponsClick(relX, relY, w, h)
    local C = TDMRP.UI.Colors
    local ply = LocalPlayer()
    local money = IsValid(ply) and (ply:getDarkRPVar("money") or 0) or 0
    
    local infoPanelW = Config.infoPanelWidth
    local gridW = w - infoPanelW - 35
    
    -- Check type filter clicks
    local filterY = 45
    local filterBtnW = math.floor((gridW - 20 - (#typeFilters - 1) * 5) / #typeFilters)
    filterBtnW = math.min(filterBtnW, 80)
    
    if relY >= filterY + 8 and relY <= filterY + 36 then
        for i, filter in ipairs(typeFilters) do
            local btnX = 15 + 10 + (i-1) * (filterBtnW + 5)
            if relX >= btnX and relX <= btnX + filterBtnW then
                selectedType = filter.id
                scrollOffset = 0
                surface.PlaySound("UI/buttonclick.wav")
                return
            end
        end
        -- No tier buttons to check anymore (shop only sells Tier 1)
    end
    
    -- Check buy button in info panel
    local displayWeapon = hoveredWeapon or selectedWeapon
    if displayWeapon then
        local infoPanelX = w - infoPanelW - 10
        local infoPanelY = 10
        local infoPanelH = h - 20
        local btnY = infoPanelY + infoPanelH - 55
        local btnW = infoPanelW - 30
        local btnH = 42
        local btnX = infoPanelX + 15
        
        if relX >= btnX and relX <= btnX + btnW and relY >= btnY and relY <= btnY + btnH then
            local price = displayWeapon.price or GetWeaponPrice(displayWeapon.class)
            
            if money < price then
                chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "You can't afford this weapon!")
                surface.PlaySound("buttons/button10.wav")
                return
            end
            
            -- Check if already has weapon (check both tdmrp and base m9k versions)
            local tdmrpClass = "tdmrp_" .. displayWeapon.class
            for _, wep in ipairs(ply:GetWeapons()) do
                local wepClass = wep:GetClass()
                if wepClass == displayWeapon.class or wepClass == tdmrpClass then
                    chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "You already have this weapon!")
                    surface.PlaySound("buttons/button10.wav")
                    return
                end
            end
            
            -- Send purchase - server expects m9k class name (e.g., "m9k_glock")
            net.Start("TDMRP_BuyWeapon")
                net.WriteString(displayWeapon.class)
            net.SendToServer()
            
            surface.PlaySound("UI/buttonclick.wav")
            purchaseFlash[displayWeapon.class] = CurTime() + 0.3
            return
        end
    end
    
    -- Check weapon card clicks
    if hoveredWeapon then
        selectedWeapon = hoveredWeapon
        surface.PlaySound("UI/buttonclick.wav")
    end
end

----------------------------------------------------
-- Scroll Handler
----------------------------------------------------

local function OnWeaponsScroll(delta)
    scrollOffset = math.Clamp(scrollOffset - delta * Config.scrollSpeed, 0, maxScroll)
end

----------------------------------------------------
-- Cleanup
----------------------------------------------------

----------------------------------------------------
-- Cleanup
----------------------------------------------------

hook.Add("TDMRP_F4MenuClosed", "TDMRP_WeaponsCleanup", function()
    -- Completely remove all model panels to prevent persistence
    ClearWeaponModelPanels()
    if IsValid(weaponModelContainer) then
        weaponModelContainer:Remove()
        weaponModelContainer = nil
    end
end)

hook.Add("TDMRP_F4TabChanged", "TDMRP_WeaponsTabChange", function(newTab, oldTab)
    -- Hide weapon model panels when switching away from weapons tab
    if oldTab == "weapons" then
        HideAllWeaponPanels()
    end
end)

hook.Add("TDMRP_F4MenuOpened", "TDMRP_WeaponsInit", function()
    scrollOffset = 0
end)

----------------------------------------------------
-- Network: Purchase confirmation (optional - server uses ChatPrint)
----------------------------------------------------

net.Receive("TDMRP_WeaponPurchased", function()
    local weaponClass = net.ReadString()
    
    local meta = TDMRP.M9KRegistry and TDMRP.M9KRegistry[weaponClass]
    local name = meta and meta.name or weaponClass
    
    chat.AddText(Color(100, 255, 100), "[TDMRP] ", Color(255, 255, 255), "Purchased Common " .. name .. "!")
    surface.PlaySound("items/gunpickup2.wav")
end)

----------------------------------------------------
-- Register Tab
----------------------------------------------------

local function RegisterWeaponsTab()
    if TDMRP.F4Menu and TDMRP.F4Menu.RegisterTab then
        TDMRP.F4Menu.RegisterTab("weapons", PaintWeapons, OnWeaponsClick, OnWeaponsScroll)
    end
end

if TDMRP.F4Menu and TDMRP.F4Menu.Ready then
    RegisterWeaponsTab()
else
    hook.Add("TDMRP_F4MenuReady", "TDMRP_RegisterWeaponsTab", RegisterWeaponsTab)
end

print("[TDMRP] cl_tdmrp_f4_weapons.lua loaded - Weapons tab with 3D models")
