----------------------------------------------------
-- TDMRP F4 Menu - Ammo Shop Tab
-- Purchase ammunition with 3D model previews
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.F4Menu = TDMRP.F4Menu or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

local Config = {
    cardWidth = 180,
    cardHeight = 180,
    cardPadding = 15,
    modelSize = 80,
}

----------------------------------------------------
-- State
----------------------------------------------------

local hoveredAmmo = nil
local lastClickTime = 0
local purchaseFlash = {}

----------------------------------------------------
-- Model Panel Pool
----------------------------------------------------

local ammoModelPanels = {}
local ammoModelContainer = nil

local function GetOrCreateAmmoModelPanel(ammoType, model)
    if ammoModelPanels[ammoType] then
        return ammoModelPanels[ammoType]
    end
    
    -- Parent model container to F4 menu so it renders AFTER menu's Paint()
    -- This means scissor rect in Paint() won't affect these panels
    local menuPanel = TDMRP.F4Menu.GetPanel()
    if not IsValid(menuPanel) then return nil end
    
    if not IsValid(ammoModelContainer) then
        ammoModelContainer = vgui.Create("DPanel", menuPanel)
        ammoModelContainer:SetPos(0, 0)
        ammoModelContainer:SetSize(ScrW(), ScrH())
        ammoModelContainer:SetMouseInputEnabled(false)
        ammoModelContainer:SetKeyboardInputEnabled(false)
        ammoModelContainer.Paint = function() end
    end
    
    local panel = vgui.Create("DModelPanel", ammoModelContainer)
    panel:SetSize(Config.modelSize, Config.modelSize)
    panel:SetModel(model)
    panel:SetFOV(45)
    panel:SetVisible(false)
    panel:SetMouseInputEnabled(false)
        
        -- Center and size the model
        local entity = panel.Entity
        if IsValid(entity) then
            local mins, maxs = entity:GetRenderBounds()
            local center = (mins + maxs) * 0.5
            local size = maxs - mins
            local maxDim = math.max(size.x, size.y, size.z)
            
            local dist = maxDim * 1.3
            panel:SetCamPos(Vector(dist, dist * 0.5, dist * 0.5))
            panel:SetLookAt(center)
        end
        
        -- Add rotation
        panel.LayoutEntity = function(self, ent)
            if IsValid(ent) then
                ent:SetAngles(Angle(0, RealTime() * 30, 0))
            end
        end
        
        ammoModelPanels[ammoType] = panel
    
    return ammoModelPanels[ammoType]
end

-- Cleanup on menu close
hook.Add("TDMRP_F4MenuClosed", "TDMRP_CleanupAmmoModels", function()
    -- Completely remove all model panels to prevent persistence
    for ammoType, panel in pairs(ammoModelPanels) do
        if IsValid(panel) then
            panel:Remove()
        end
    end
    ammoModelPanels = {}
    if IsValid(ammoModelContainer) then
        ammoModelContainer:Remove()
        ammoModelContainer = nil
    end
end)

hook.Add("TDMRP_F4TabChanged", "TDMRP_AmmoTabChange", function(newTab, oldTab)
    -- Hide ammo model panels when switching away from ammo tab
    if oldTab == "ammo" then
        for _, panel in pairs(ammoModelPanels) do
            if IsValid(panel) then
                panel:SetVisible(false)
            end
        end
    end
end)

----------------------------------------------------
-- Paint Function
----------------------------------------------------

local function PaintAmmo(x, y, w, h, alpha, mx, my, scroll)
    local C = TDMRP.UI.Colors
    local ply = LocalPlayer()
    local money = IsValid(ply) and (ply:getDarkRPVar("money") or 0) or 0
    
    -- Header
    draw.SimpleText("AMMUNITION", "TDMRP_Header", x + 20, y + 15, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Money display
    local moneyStr = TDMRP.UI.FormatMoney and TDMRP.UI.FormatMoney(money) or ("$" .. money)
    draw.SimpleText("Balance: " .. moneyStr, "TDMRP_Body", x + w - 20, y + 18, ColorAlpha(C.accent, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    
    -- Subtitle
    draw.SimpleText("Stock up on ammunition for your weapons", "TDMRP_Small", x + 20, y + 42, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Separator
    surface.SetDrawColor(ColorAlpha(C.border_dark, alpha))
    surface.DrawRect(x + 20, y + 65, w - 40, 1)
    
    -- Calculate grid layout
    local contentY = y + 80
    local contentH = h - 140  -- Leave room for bottom info
    local cardsPerRow = math.floor((w - 40) / (Config.cardWidth + Config.cardPadding))
    if cardsPerRow < 1 then cardsPerRow = 1 end
    local totalWidth = cardsPerRow * (Config.cardWidth + Config.cardPadding) - Config.cardPadding
    local startX = x + (w - totalWidth) / 2
    
    hoveredAmmo = nil
    local index = 0
    
    -- Hide all panels first
    for _, panel in pairs(ammoModelPanels) do
        if IsValid(panel) then
            panel:SetVisible(false)
        end
    end
    
    for ammoType, ammoData in pairs(TDMRP.AmmoTypes) do
        local row = math.floor(index / cardsPerRow)
        local col = index % cardsPerRow
        
        local cardX = startX + col * (Config.cardWidth + Config.cardPadding)
        local cardY = contentY + row * (Config.cardHeight + Config.cardPadding)
        local cardW = Config.cardWidth
        local cardH = Config.cardHeight
        
        -- Skip if off screen
        if cardY + cardH < contentY or cardY > contentY + contentH then
            index = index + 1
            continue
        end
        
        -- Check hover
        local isHovered = mx >= cardX and mx <= cardX + cardW and my >= cardY and my <= cardY + cardH
        local canAfford = money >= ammoData.price
        
        if isHovered then
            hoveredAmmo = { type = ammoType, data = ammoData }
        end
        
        -- Card background with gradient effect
        local cardBg = isHovered and C.bg_hover or C.bg_light
        draw.RoundedBox(8, cardX, cardY, cardW, cardH, ColorAlpha(cardBg, alpha))
        
        -- Purchase flash effect
        if purchaseFlash[ammoType] and purchaseFlash[ammoType] > CurTime() then
            local flashAlpha = (purchaseFlash[ammoType] - CurTime()) * 400
            draw.RoundedBox(8, cardX, cardY, cardW, cardH, ColorAlpha(C.success, flashAlpha))
        end
        
        -- Accent border on hover
        if isHovered then
            surface.SetDrawColor(ColorAlpha(C.accent, alpha))
            surface.DrawOutlinedRect(cardX, cardY, cardW, cardH, 2)
        end
        
        -- 3D Model preview
        local modelX = cardX + (cardW - Config.modelSize) / 2
        local modelY = cardY + 10
        
        -- Model background circle
        local circleBg = canAfford and C.bg_dark or Color(40, 25, 25)
        draw.RoundedBox(Config.modelSize / 2, modelX, modelY, Config.modelSize, Config.modelSize, ColorAlpha(circleBg, alpha * 0.8))
        
        -- Position and show the model panel
        if ammoData.model then
            local panel = GetOrCreateAmmoModelPanel(ammoType, ammoData.model)
            if IsValid(panel) then
                panel:SetPos(modelX, modelY)
                panel:SetSize(Config.modelSize, Config.modelSize)
                -- Only show if model is FULLY within visible content area
                local isInBounds = modelY >= contentY and modelY + Config.modelSize <= contentY + contentH
                panel:SetVisible(isInBounds)
                if isInBounds then
                    panel:SetAlpha(255 * alpha)
                end
            end
        else
            -- Fallback to letter icon if no model
            local iconColor = canAfford and C.accent or C.error
            draw.SimpleText(ammoData.icon or "?", "TDMRP_Header", modelX + Config.modelSize/2, modelY + Config.modelSize/2, ColorAlpha(iconColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Ammo name
        draw.SimpleText(ammoData.name, "TDMRP_BodyBold", cardX + cardW/2, cardY + Config.modelSize + 18, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        -- Amount badge
        local amountText = "x" .. ammoData.amount .. " rounds"
        draw.SimpleText(amountText, "TDMRP_Small", cardX + cardW/2, cardY + Config.modelSize + 40, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        
        -- Price / Buy button
        local btnY = cardY + cardH - 36
        local btnH = 28
        local btnX = cardX + 12
        local btnW = cardW - 24
        
        if canAfford then
            local btnBg = isHovered and C.accent or C.accent_dark
            draw.RoundedBox(6, btnX, btnY, btnW, btnH, ColorAlpha(btnBg, alpha))
            
            local priceText = TDMRP.UI.FormatMoney and TDMRP.UI.FormatMoney(ammoData.price) or ("$" .. ammoData.price)
            draw.SimpleText(priceText, "TDMRP_SmallBold", cardX + cardW/2, btnY + btnH/2, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        else
            draw.RoundedBox(6, btnX, btnY, btnW, btnH, ColorAlpha(C.bg_dark, alpha))
            
            local priceText = TDMRP.UI.FormatMoney and TDMRP.UI.FormatMoney(ammoData.price) or ("$" .. ammoData.price)
            draw.SimpleText(priceText, "TDMRP_SmallBold", cardX + cardW/2, btnY + btnH/2, ColorAlpha(C.error, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        index = index + 1
    end
    
    -- Current weapon ammo info panel (bottom)
    local wep = IsValid(ply) and ply:GetActiveWeapon() or nil
    local infoY = y + h - 55
    local infoH = 45
    
    draw.RoundedBox(6, x + 20, infoY, w - 40, infoH, ColorAlpha(C.bg_dark, alpha))
    
    if IsValid(wep) and TDMRP.IsM9KWeapon and TDMRP.IsM9KWeapon(wep) then
        local className = wep:GetClass()
        local meta = TDMRP.GetM9KMeta and TDMRP.GetM9KMeta(className)
        
        if meta then
            local currentAmmo = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
            local clipAmmo = wep:Clip1()
            
            -- Left accent bar
            surface.SetDrawColor(ColorAlpha(C.accent, alpha))
            surface.DrawRect(x + 20, infoY, 4, infoH)
            
            -- Weapon name
            draw.SimpleText("Active: " .. (meta.name or className), "TDMRP_BodyBold", x + 35, infoY + 8, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            -- Ammo info
            local ammoText = string.format("Clip: %d | Reserve: %d", clipAmmo, currentAmmo)
            local ammoTypeData = meta.ammoType and TDMRP.AmmoTypes[meta.ammoType]
            if ammoTypeData then
                ammoText = ammoText .. " (" .. ammoTypeData.shortName .. ")"
            end
            draw.SimpleText(ammoText, "TDMRP_Small", x + 35, infoY + 28, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            -- Ammo bar
            local barX = x + w - 170
            local barW = 140
            local barH = 8
            local barY = infoY + infoH/2 - barH/2
            
            -- Background
            draw.RoundedBox(4, barX, barY, barW, barH, ColorAlpha(C.bg_light, alpha))
            
            -- Fill (based on ammo percentage, assume 200 is "full")
            local fillPercent = math.Clamp(currentAmmo / 200, 0, 1)
            local fillColor = fillPercent > 0.3 and C.accent or C.error
            if fillPercent > 0 then
                draw.RoundedBox(4, barX, barY, barW * fillPercent, barH, ColorAlpha(fillColor, alpha))
            end
        else
            DrawNoWeaponInfo(x, infoY, w, infoH, alpha, C)
        end
    else
        DrawNoWeaponInfo(x, infoY, w, infoH, alpha, C)
    end
end

function DrawNoWeaponInfo(x, infoY, w, infoH, alpha, C)
    -- Gray accent
    surface.SetDrawColor(ColorAlpha(C.text_muted, alpha * 0.5))
    surface.DrawRect(x + 20, infoY, 4, infoH)
    
    draw.SimpleText("No TDMRP weapon equipped", "TDMRP_Body", x + 35, infoY + infoH/2, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText("Equip a weapon to see ammo info", "TDMRP_Small", x + w - 30, infoY + infoH/2, ColorAlpha(C.text_muted, alpha * 0.7), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

----------------------------------------------------
-- Click Handler
----------------------------------------------------

local function OnAmmoClick(relX, relY, w, h)
    if not hoveredAmmo then return end
    
    -- Debounce
    if CurTime() - lastClickTime < 0.3 then return end
    lastClickTime = CurTime()
    
    local ammoType = hoveredAmmo.type
    local ammoData = hoveredAmmo.data
    local ply = LocalPlayer()
    
    if not IsValid(ply) then return end
    
    local money = ply:getDarkRPVar("money") or 0
    
    if money < ammoData.price then
        chat.AddText(Color(255, 100, 100), "[TDMRP] ", Color(255, 255, 255), "You can't afford this ammo!")
        surface.PlaySound("buttons/button10.wav")
        return
    end
    
    -- Send purchase request
    net.Start("TDMRP_PurchaseAmmo")
        net.WriteString(ammoType)
    net.SendToServer()
    
    surface.PlaySound("UI/buttonclick.wav")
    
    -- Visual feedback
    purchaseFlash[ammoType] = CurTime() + 0.4
end

----------------------------------------------------
-- Network: Purchase confirmation
----------------------------------------------------

net.Receive("TDMRP_AmmoPurchased", function()
    local ammoType = net.ReadString()
    local amount = net.ReadInt(16)
    
    local ammoData = TDMRP.AmmoTypes[ammoType]
    local name = ammoData and ammoData.name or ammoType
    
    chat.AddText(Color(100, 255, 100), "[TDMRP] ", Color(255, 255, 255), "Purchased " .. amount .. " " .. name .. "!")
    surface.PlaySound("items/ammo_pickup.wav")
end)

----------------------------------------------------
-- Register Tab
----------------------------------------------------

local function RegisterAmmoTab()
    if TDMRP.F4Menu and TDMRP.F4Menu.RegisterTab then
        TDMRP.F4Menu.RegisterTab("ammo", PaintAmmo, OnAmmoClick, nil)
    end
end

if TDMRP.F4Menu and TDMRP.F4Menu.Ready then
    RegisterAmmoTab()
else
    hook.Add("TDMRP_F4MenuReady", "TDMRP_RegisterAmmoTab", RegisterAmmoTab)
end

print("[TDMRP] cl_tdmrp_f4_ammo.lua loaded")
