----------------------------------------------------
-- TDMRP F4 Menu Framework
-- Main menu system with tabbed interface
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.F4Menu = TDMRP.F4Menu or {}

----------------------------------------------------
-- Menu Configuration
----------------------------------------------------

-- Calculate dimensions based on 60% of screen area
local function CalculateMenuSize()
    local scrW, scrH = ScrW(), ScrH()
    -- Target 60% of screen area
    -- Area = W * H, so we want newW * newH = 0.6 * scrW * scrH
    -- Maintain roughly 3:2 aspect ratio (width:height)
    local targetArea = scrW * scrH * 0.6
    local aspectRatio = 3 / 2
    -- h * (h * aspect) = targetArea
    -- h^2 * aspect = targetArea
    -- h = sqrt(targetArea / aspect)
    local h = math.sqrt(targetArea / aspectRatio)
    local w = h * aspectRatio
    -- Clamp to reasonable bounds
    w = math.Clamp(w, 800, scrW - 100)
    h = math.Clamp(h, 500, scrH - 100)
    return math.floor(w), math.floor(h)
end

local menuW, menuH = CalculateMenuSize()

local Config = {
    -- Dimensions (dynamically calculated for 60% screen area)
    width = menuW,
    height = menuH,
    headerHeight = 50,
    tabHeight = 40,
    cornerRadius = 6,
    
    -- Animation
    openSpeed = 12,
    fadeSpeed = 10,
}

-- Recalculate on resolution change
hook.Add("OnScreenSizeChanged", "TDMRP_F4MenuResize", function()
    local w, h = CalculateMenuSize()
    Config.width = w
    Config.height = h
    menuX, menuY = nil, nil -- Reset position to recenter
end)

----------------------------------------------------
-- State
----------------------------------------------------

local menuOpen = false
local menuAlpha = 0
local menuScale = 0.9
local activeTab = "jobs"
local dragging = false
local dragOffsetX, dragOffsetY = 0, 0
local menuX, menuY = nil, nil

-- Tab definitions
local tabs = {
    { id = "jobs",      name = "JOBS",      icon = "J" },
    { id = "ammo",      name = "AMMO",      icon = "A" },
    { id = "weapons",   name = "WEAPONS",   icon = "W" },
    { id = "crafting",  name = "CRAFTING",  icon = "C" },
    { id = "inventory", name = "INVENTORY", icon = "I" },
}

----------------------------------------------------
-- Menu Panel (VGUI wrapper for paint-based drawing)
----------------------------------------------------

local menuPanel = nil

local function CreateMenuPanel()
    if IsValid(menuPanel) then
        menuPanel:Remove()
    end
    
    menuPanel = vgui.Create("DPanel")
    menuPanel:SetSize(ScrW(), ScrH())
    menuPanel:SetPos(0, 0)
    menuPanel:MakePopup()
    menuPanel:SetKeyboardInputEnabled(true)
    menuPanel:SetMouseInputEnabled(true)
    
    -- Center menu position
    if not menuX then
        menuX = (ScrW() - Config.width) / 2
        menuY = (ScrH() - Config.height) / 2
    end
    
    local C = TDMRP.UI.Colors
    
    -- Hover states
    local hoveredTab = nil
    local hoveredClose = false
    local lastClickTime = 0
    
    -- Tab content scroll
    local scrollOffset = 0
    local maxScroll = 0
    
    ----------------------------------------------------
    -- Paint Function
    ----------------------------------------------------
    
    menuPanel.Paint = function(self, w, h)
        local frameTime = FrameTime()
        
        -- Animate
        if menuOpen then
            menuAlpha = Lerp(frameTime * Config.fadeSpeed, menuAlpha, 255)
            menuScale = Lerp(frameTime * Config.openSpeed, menuScale, 1)
        else
            menuAlpha = Lerp(frameTime * Config.fadeSpeed, menuAlpha, 0)
            menuScale = Lerp(frameTime * Config.openSpeed, menuScale, 0.9)
            
            if menuAlpha < 1 then
                self:Remove()
                menuPanel = nil
                return
            end
        end
        
        local alpha = math.floor(menuAlpha)
        local mx, my = self:CursorPos()
        
        -- Apply scale transform
        local menuW = Config.width * menuScale
        local menuH = Config.height * menuScale
        local drawX = menuX + (Config.width - menuW) / 2
        local drawY = menuY + (Config.height - menuH) / 2
        
        -- Background overlay
        surface.SetDrawColor(0, 0, 0, alpha * 0.6)
        surface.DrawRect(0, 0, w, h)
        
        -- Main container shadow
        for i = 1, 8 do
            draw.RoundedBox(Config.cornerRadius + i, drawX - i, drawY - i, menuW + i*2, menuH + i*2, ColorAlpha(Color(0, 0, 0), alpha * 0.1))
        end
        
        -- Main container
        draw.RoundedBox(Config.cornerRadius, drawX, drawY, menuW, menuH, ColorAlpha(C.bg_dark, alpha))
        
        -- Header
        draw.RoundedBoxEx(Config.cornerRadius, drawX, drawY, menuW, Config.headerHeight * menuScale, ColorAlpha(C.bg_medium, alpha), true, true, false, false)
        
        -- Header accent line
        surface.SetDrawColor(ColorAlpha(C.accent, alpha))
        surface.DrawRect(drawX, drawY + Config.headerHeight * menuScale - 2, menuW, 2)
        
        -- Title
        draw.SimpleText("T D M R P", "TDMRP_Title", drawX + 20 * menuScale, drawY + Config.headerHeight * menuScale / 2, ColorAlpha(C.accent, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        
        -- Close button
        local closeX = drawX + menuW - 40 * menuScale
        local closeY = drawY + 10 * menuScale
        local closeW = 30 * menuScale
        local closeH = 30 * menuScale
        
        hoveredClose = mx >= closeX and mx <= closeX + closeW and my >= closeY and my <= closeY + closeH
        
        local closeBg = hoveredClose and C.accent or C.bg_light
        draw.RoundedBox(4, closeX, closeY, closeW, closeH, ColorAlpha(closeBg, alpha))
        draw.SimpleText("×", "TDMRP_Header", closeX + closeW/2, closeY + closeH/2 - 2, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        -- Tab bar
        local tabY = drawY + Config.headerHeight * menuScale
        local tabW = menuW / #tabs
        
        hoveredTab = nil
        
        for i, tab in ipairs(tabs) do
            local tabX = drawX + (i-1) * tabW
            local isActive = (tab.id == activeTab)
            local isHovered = mx >= tabX and mx <= tabX + tabW and my >= tabY and my <= tabY + Config.tabHeight * menuScale
            
            if isHovered then
                hoveredTab = tab.id
            end
            
            -- Tab background
            local tabBg = C.bg_dark
            if isActive then
                tabBg = C.bg_light
            elseif isHovered then
                tabBg = C.bg_hover
            end
            draw.RoundedBox(0, tabX, tabY, tabW, Config.tabHeight * menuScale, ColorAlpha(tabBg, alpha))
            
            -- Active indicator
            if isActive then
                surface.SetDrawColor(ColorAlpha(C.accent, alpha))
                surface.DrawRect(tabX, tabY + Config.tabHeight * menuScale - 3, tabW, 3)
            end
            
            -- Tab text
            local tabTextColor = isActive and C.accent or (isHovered and C.text_primary or C.text_secondary)
            draw.SimpleText(tab.name, "TDMRP_BodyBold", tabX + tabW/2, tabY + Config.tabHeight * menuScale / 2, ColorAlpha(tabTextColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            -- Tab separator
            if i < #tabs then
                surface.SetDrawColor(ColorAlpha(C.border_dark, alpha))
                surface.DrawRect(tabX + tabW - 1, tabY + 8, 1, Config.tabHeight * menuScale - 16)
            end
        end
        
        -- Content area
        local contentX = drawX
        local contentY = tabY + Config.tabHeight * menuScale
        local contentW = menuW
        local contentH = menuH - Config.headerHeight * menuScale - Config.tabHeight * menuScale
        
        -- Content background
        draw.RoundedBoxEx(Config.cornerRadius, contentX, contentY, contentW, contentH, ColorAlpha(C.bg_medium, alpha), false, false, true, true)
        
        -- Render active tab content
        if TDMRP.F4Menu.Tabs and TDMRP.F4Menu.Tabs[activeTab] then
            -- Scissor rect clips 2D content; DModelPanel children render AFTER Paint() ends
            -- so they won't be affected by this scissor rect
            render.SetScissorRect(contentX, contentY, contentX + contentW, contentY + contentH, true)
            
            TDMRP.F4Menu.Tabs[activeTab](contentX, contentY, contentW, contentH, alpha, mx, my, scrollOffset)
            
            render.SetScissorRect(0, 0, 0, 0, false)
        else
            -- Placeholder
            draw.SimpleText("Content for " .. activeTab, "TDMRP_Header", contentX + contentW/2, contentY + contentH/2, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        -- Player info footer
        local ply = LocalPlayer()
        if IsValid(ply) then
            local footerY = drawY + menuH - 25 * menuScale
            local money = ply:getDarkRPVar("money") or 0
            draw.SimpleText("Balance: " .. TDMRP.UI.FormatMoney(money), "TDMRP_Small", drawX + menuW - 15, footerY, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
    end
    
    ----------------------------------------------------
    -- Mouse Handling
    ----------------------------------------------------
    
    menuPanel.OnMousePressed = function(self, keyCode)
        if keyCode ~= MOUSE_LEFT then return end
        
        local mx, my = self:CursorPos()
        local drawX, drawY = menuX, menuY
        
        -- Check close button
        local closeX = drawX + Config.width - 40
        local closeY = drawY + 10
        if mx >= closeX and mx <= closeX + 30 and my >= closeY and my <= closeY + 30 then
            TDMRP.F4Menu.Close()
            return
        end
        
        -- Check tab clicks
        local tabY = drawY + Config.headerHeight
        local tabW = Config.width / #tabs
        
        if my >= tabY and my <= tabY + Config.tabHeight then
            for i, tab in ipairs(tabs) do
                local tabX = drawX + (i-1) * tabW
                if mx >= tabX and mx <= tabX + tabW then
                    if activeTab ~= tab.id then
                        hook.Run("TDMRP_F4TabChanged", tab.id, activeTab)
                        activeTab = tab.id
                    end
                    surface.PlaySound("UI/buttonclick.wav")
                    return
                end
            end
        end
        
        -- Check header drag
        if my >= drawY and my <= drawY + Config.headerHeight then
            dragging = true
            dragOffsetX = mx - drawX
            dragOffsetY = my - drawY
            return
        end
        
        -- Pass to tab content handler
        local contentY = drawY + Config.headerHeight + Config.tabHeight
        local contentH = Config.height - Config.headerHeight - Config.tabHeight
        
        if my >= contentY and my <= contentY + contentH then
            if TDMRP.F4Menu.TabClick and TDMRP.F4Menu.TabClick[activeTab] then
                local relX = mx - drawX
                local relY = my - contentY
                TDMRP.F4Menu.TabClick[activeTab](relX, relY, Config.width, contentH)
            end
        end
    end
    
    menuPanel.OnMouseReleased = function(self, keyCode)
        if keyCode == MOUSE_LEFT then
            dragging = false
        end
    end
    
    menuPanel.Think = function(self)
        if dragging then
            local mx, my = self:CursorPos()
            menuX = math.Clamp(mx - dragOffsetX, 0, ScrW() - Config.width)
            menuY = math.Clamp(my - dragOffsetY, 0, ScrH() - Config.height)
        end
    end
    
    menuPanel.OnKeyCodePressed = function(self, key)
        if key == KEY_ESCAPE or key == KEY_F4 then
            TDMRP.F4Menu.Close()
            return
        end
        
        -- Pass keyboard input to active tab if they have a handler
        if TDMRP.F4Menu.TabKeyDown and TDMRP.F4Menu.TabKeyDown[activeTab] then
            local handled = TDMRP.F4Menu.TabKeyDown[activeTab](key)
            if handled then return true end
        end
    end
    
    menuPanel.OnMouseWheeled = function(self, delta)
        -- Pass scroll to active tab
        if TDMRP.F4Menu.TabScroll and TDMRP.F4Menu.TabScroll[activeTab] then
            TDMRP.F4Menu.TabScroll[activeTab](delta)
        end
    end
end

----------------------------------------------------
-- Public API
----------------------------------------------------

function TDMRP.F4Menu.Open()
    if menuOpen then return end
    
    menuOpen = true
    menuAlpha = 0
    menuScale = 0.9
    
    CreateMenuPanel()
    surface.PlaySound("UI/buttonrollover.wav")
    
    -- Notify tabs that menu opened
    hook.Run("TDMRP_F4MenuOpened")
end

function TDMRP.F4Menu.Close()
    if not menuOpen then return end
    
    menuOpen = false
    surface.PlaySound("UI/buttonclickrelease.wav")
    
    -- Notify tabs to clean up (IMPORTANT for model panels)
    hook.Run("TDMRP_F4MenuClosed")
    
    -- Remove the menu panel
    if IsValid(menuPanel) then
        menuPanel:Remove()
        menuPanel = nil
    end
end

function TDMRP.F4Menu.Toggle()
    if menuOpen then
        TDMRP.F4Menu.Close()
    else
        TDMRP.F4Menu.Open()
    end
end

function TDMRP.F4Menu.IsOpen()
    return menuOpen
end

function TDMRP.F4Menu.GetPanel()
    return menuPanel
end

function TDMRP.F4Menu.SetTab(tabId)
    for _, tab in ipairs(tabs) do
        if tab.id == tabId then
            activeTab = tabId
            return true
        end
    end
    return false
end

function TDMRP.F4Menu.GetActiveTab()
    return activeTab
end

----------------------------------------------------
-- Tab Registration
----------------------------------------------------

TDMRP.F4Menu.Tabs = TDMRP.F4Menu.Tabs or {}
TDMRP.F4Menu.TabClick = TDMRP.F4Menu.TabClick or {}
TDMRP.F4Menu.TabScroll = TDMRP.F4Menu.TabScroll or {}
TDMRP.F4Menu.TabKeyDown = TDMRP.F4Menu.TabKeyDown or {}
TDMRP.F4Menu.TabCharInput = TDMRP.F4Menu.TabCharInput or {}

function TDMRP.F4Menu.RegisterTab(tabId, paintFunc, clickFunc, scrollFunc, keydownFunc, charinputFunc)
    TDMRP.F4Menu.Tabs[tabId] = paintFunc
    TDMRP.F4Menu.TabClick[tabId] = clickFunc
    TDMRP.F4Menu.TabScroll[tabId] = scrollFunc
    if keydownFunc then
        TDMRP.F4Menu.TabKeyDown[tabId] = keydownFunc
    end
    if charinputFunc then
        TDMRP.F4Menu.TabCharInput[tabId] = charinputFunc
    end
    print("[TDMRP] Registered F4 tab: " .. tabId)
end

-- Signal that the F4 menu is ready for tab registration
TDMRP.F4Menu.Ready = true
hook.Run("TDMRP_F4MenuReady")

----------------------------------------------------
-- Hook: DarkRP F4 Override (F4 = ShowSpare2)
----------------------------------------------------

hook.Add("ShowSpare2", "TDMRP_F4Menu", function()
    TDMRP.F4Menu.Toggle()
    return true -- Block default DarkRP F4 menu
end)

-- Also override the DarkRP toggle function directly
hook.Add("InitPostEntity", "TDMRP_OverrideDarkRPF4", function()
    if DarkRP and DarkRP.toggleF4Menu then
        DarkRP.toggleF4Menu = function()
            TDMRP.F4Menu.Toggle()
        end
        DarkRP.openF4Menu = function()
            TDMRP.F4Menu.Open()
        end
        DarkRP.closeF4Menu = function()
            TDMRP.F4Menu.Close()
        end
    end
end)

-- Alternative hook for /f4 chat command
hook.Add("OnPlayerChat", "TDMRP_F4MenuCmd", function(ply, text)
    if ply == LocalPlayer() and string.lower(text) == "/f4" then
        TDMRP.F4Menu.Toggle()
        return true
    end
end)

print("[TDMRP] cl_tdmrp_f4_00_core.lua loaded - F4 menu framework initialized")
