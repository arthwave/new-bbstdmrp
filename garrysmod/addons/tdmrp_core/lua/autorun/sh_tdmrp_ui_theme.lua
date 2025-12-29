----------------------------------------------------
-- TDMRP UI Theme System
-- Shared color palette, fonts, and drawing utilities
----------------------------------------------------

TDMRP = TDMRP or {}
TDMRP.UI = TDMRP.UI or {}

----------------------------------------------------
-- Color Palette
----------------------------------------------------

TDMRP.UI.Colors = {
    -- Backgrounds
    bg_dark       = Color(13, 13, 13, 250),       -- #0D0D0D - Darkest
    bg_medium     = Color(22, 22, 22, 250),       -- #161616 - Panels
    bg_light      = Color(32, 32, 32, 250),       -- #202020 - Elevated
    bg_hover      = Color(45, 45, 45, 250),       -- #2D2D2D - Hover state
    bg_input      = Color(18, 18, 18, 255),       -- #121212 - Input fields
    
    -- Accents
    accent        = Color(204, 0, 0, 255),        -- #CC0000 - Primary red
    accent_dark   = Color(153, 0, 0, 255),        -- #990000 - Darker red
    accent_hover  = Color(255, 51, 51, 255),      -- #FF3333 - Hover red
    accent_glow   = Color(204, 0, 0, 100),        -- Red glow (transparent)
    
    -- Text
    text_primary   = Color(255, 255, 255, 255),   -- White
    text_secondary = Color(160, 160, 160, 255),   -- Light gray
    text_muted     = Color(100, 100, 100, 255),   -- Muted gray
    text_disabled  = Color(60, 60, 60, 255),      -- Disabled
    text_accent    = Color(255, 80, 80, 255),     -- Red text
    
    -- Status
    success       = Color(0, 204, 102, 255),      -- #00CC66 - Green
    warning       = Color(255, 170, 0, 255),      -- #FFAA00 - Orange
    error         = Color(255, 60, 60, 255),      -- #FF3C3C - Red
    info          = Color(60, 160, 255, 255),     -- #3CA0FF - Blue
    
    -- Borders
    border_dark   = Color(40, 40, 40, 255),       -- Subtle border
    border_light  = Color(60, 60, 60, 255),       -- Visible border
    border_accent = Color(204, 0, 0, 255),        -- Red border
    
    -- Tier Colors (weapon rarity)
    tier = {
        [1] = Color(180, 180, 180, 255),  -- Tier 1: Gray (Common)
        [2] = Color(80, 200, 80, 255),    -- Tier 2: Green (Uncommon)
        [3] = Color(60, 140, 255, 255),   -- Tier 3: Blue (Rare)
        [4] = Color(255, 215, 0, 255),    -- Tier 4: Gold (Legendary)
        [5] = Color(155, 48, 255, 255),   -- Tier 5: Purple (Unique)
    },
    
    -- Job Class Colors
    class = {
        civilian = Color(100, 180, 100, 255),  -- Green
        criminal = Color(255, 100, 100, 255),  -- Red
        police   = Color(100, 150, 255, 255),  -- Blue
    },
    
    -- Gem Colors
    gem = {
        sapphire = Color(60, 120, 255, 255),   -- Blue
        emerald  = Color(60, 255, 120, 255),   -- Green
        ruby     = Color(255, 60, 80, 255),    -- Red
        diamond  = Color(200, 240, 255, 255),  -- White/Cyan
        amethyst = Color(155, 89, 182, 255),   -- Purple
    },
    
    -- Special
    legendary = Color(155, 48, 255, 255),     -- Purple (matches tier 5)
}

----------------------------------------------------
-- Font Definitions
----------------------------------------------------

if CLIENT then
    surface.CreateFont("TDMRP_Title", {
        font = "Roboto",
        size = 32,
        weight = 700,
        antialias = true,
    })
    
    surface.CreateFont("TDMRP_Header", {
        font = "Roboto",
        size = 24,
        weight = 600,
        antialias = true,
    })
    
    surface.CreateFont("TDMRP_SubHeader", {
        font = "Roboto",
        size = 18,
        weight = 600,
        antialias = true,
    })
    
    surface.CreateFont("TDMRP_Body", {
        font = "Roboto",
        size = 16,
        weight = 400,
        antialias = true,
    })
    
    surface.CreateFont("TDMRP_BodyBold", {
        font = "Roboto",
        size = 16,
        weight = 700,
        antialias = true,
    })
    
    surface.CreateFont("TDMRP_Small", {
        font = "Roboto",
        size = 14,
        weight = 400,
        antialias = true,
    })
    
    surface.CreateFont("TDMRP_SmallBold", {
        font = "Roboto",
        size = 14,
        weight = 700,
        antialias = true,
    })
    
    surface.CreateFont("TDMRP_Tiny", {
        font = "Roboto",
        size = 12,
        weight = 400,
        antialias = true,
    })
    
    surface.CreateFont("TDMRP_HUD_Large", {
        font = "Roboto Condensed",
        size = 20,
        weight = 700,
        antialias = true,
    })
    
    surface.CreateFont("TDMRP_HUD_Medium", {
        font = "Roboto Condensed",
        size = 16,
        weight = 600,
        antialias = true,
    })
    
    surface.CreateFont("TDMRP_HUD_Small", {
        font = "Roboto Condensed",
        size = 14,
        weight = 500,
        antialias = true,
    })
    
    surface.CreateFont("TDMRP_Crosshair", {
        font = "Roboto",
        size = 10,
        weight = 700,
        antialias = true,
    })
end

----------------------------------------------------
-- Drawing Utilities
----------------------------------------------------

if CLIENT then
    local C = TDMRP.UI.Colors
    local draw_RoundedBox = draw.RoundedBox
    local surface_SetDrawColor = surface.SetDrawColor
    local surface_DrawRect = surface.DrawRect
    local surface_DrawOutlinedRect = surface.DrawOutlinedRect
    local draw_SimpleText = draw.SimpleText
    local surface_SetTextColor = surface.SetTextColor
    local surface_SetFont = surface.SetFont
    local surface_GetTextSize = surface.GetTextSize
    local surface_DrawLine = surface.DrawLine
    
    -- Draw a panel background with optional border
    function TDMRP.UI.DrawPanel(x, y, w, h, cornerRadius, bgColor, borderColor)
        cornerRadius = cornerRadius or 4
        bgColor = bgColor or C.bg_medium
        
        draw_RoundedBox(cornerRadius, x, y, w, h, bgColor)
        
        if borderColor then
            -- Draw border using lines for rounded effect simulation
            surface_SetDrawColor(borderColor)
            surface_DrawOutlinedRect(x, y, w, h, 1)
        end
    end
    
    -- Draw a button with hover/press states
    function TDMRP.UI.DrawButton(x, y, w, h, text, isHovered, isPressed, isDisabled, cornerRadius)
        cornerRadius = cornerRadius or 4
        local bgColor, textColor, borderColor
        
        if isDisabled then
            bgColor = C.bg_dark
            textColor = C.text_disabled
            borderColor = C.border_dark
        elseif isPressed then
            bgColor = C.accent_dark
            textColor = C.text_primary
            borderColor = C.accent
        elseif isHovered then
            bgColor = C.accent
            textColor = C.text_primary
            borderColor = C.accent_hover
        else
            bgColor = C.bg_light
            textColor = C.text_primary
            borderColor = C.border_light
        end
        
        draw_RoundedBox(cornerRadius, x, y, w, h, bgColor)
        surface_SetDrawColor(borderColor)
        surface_DrawOutlinedRect(x, y, w, h, 1)
        
        draw_SimpleText(text, "TDMRP_BodyBold", x + w/2, y + h/2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Draw a tab button
    function TDMRP.UI.DrawTab(x, y, w, h, text, isActive, isHovered)
        local bgColor, textColor, accentHeight
        
        if isActive then
            bgColor = C.bg_light
            textColor = C.accent
            accentHeight = 3
        elseif isHovered then
            bgColor = C.bg_hover
            textColor = C.text_primary
            accentHeight = 2
        else
            bgColor = C.bg_medium
            textColor = C.text_secondary
            accentHeight = 0
        end
        
        -- Background
        draw_RoundedBox(4, x, y, w, h, bgColor)
        
        -- Bottom accent line
        if accentHeight > 0 then
            surface_SetDrawColor(C.accent)
            surface_DrawRect(x + 4, y + h - accentHeight, w - 8, accentHeight)
        end
        
        -- Text
        draw_SimpleText(text, "TDMRP_BodyBold", x + w/2, y + h/2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Draw a horizontal separator line
    function TDMRP.UI.DrawSeparator(x, y, w, color)
        color = color or C.border_dark
        surface_SetDrawColor(color)
        surface_DrawRect(x, y, w, 1)
    end
    
    -- Draw text with shadow
    function TDMRP.UI.DrawTextShadow(text, font, x, y, color, alignX, alignY, shadowOffset, shadowColor)
        shadowOffset = shadowOffset or 1
        shadowColor = shadowColor or Color(0, 0, 0, 180)
        alignX = alignX or TEXT_ALIGN_LEFT
        alignY = alignY or TEXT_ALIGN_TOP
        
        -- Shadow
        draw_SimpleText(text, font, x + shadowOffset, y + shadowOffset, shadowColor, alignX, alignY)
        -- Main text
        draw_SimpleText(text, font, x, y, color, alignX, alignY)
    end
    
    -- Draw a progress bar
    function TDMRP.UI.DrawProgressBar(x, y, w, h, progress, bgColor, fillColor, cornerRadius)
        progress = math.Clamp(progress, 0, 1)
        cornerRadius = cornerRadius or 2
        bgColor = bgColor or C.bg_dark
        fillColor = fillColor or C.accent
        
        -- Background
        draw_RoundedBox(cornerRadius, x, y, w, h, bgColor)
        
        -- Fill
        if progress > 0 then
            local fillW = math.max(4, (w - 2) * progress)
            draw_RoundedBox(cornerRadius, x + 1, y + 1, fillW, h - 2, fillColor)
        end
    end
    
    -- Draw tier indicator
    function TDMRP.UI.DrawTierBadge(x, y, tier, size)
        size = size or 24
        local tierColor = C.tier[tier] or C.tier[1]
        
        -- Background circle
        draw_RoundedBox(size/2, x, y, size, size, tierColor)
        
        -- Tier number
        draw_SimpleText("T" .. tier, "TDMRP_SmallBold", x + size/2, y + size/2, C.bg_dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Draw crafted star indicator
    function TDMRP.UI.DrawCraftedStar(x, y, size)
        size = size or 16
        draw_SimpleText("★", "TDMRP_Body", x + size/2, y + size/2, C.warning, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Draw a tooltip
    function TDMRP.UI.DrawTooltip(x, y, lines, maxWidth)
        maxWidth = maxWidth or 250
        local padding = 8
        local lineHeight = 18
        local totalHeight = padding * 2 + #lines * lineHeight
        
        -- Calculate width based on text
        local textWidth = 0
        for _, line in ipairs(lines) do
            surface_SetFont("TDMRP_Small")
            local w, _ = surface_GetTextSize(line.text or line)
            textWidth = math.max(textWidth, w)
        end
        local totalWidth = math.min(maxWidth, textWidth + padding * 2)
        
        -- Keep on screen
        x = math.Clamp(x, 5, ScrW() - totalWidth - 5)
        y = math.Clamp(y, 5, ScrH() - totalHeight - 5)
        
        -- Background
        draw_RoundedBox(4, x, y, totalWidth, totalHeight, C.bg_dark)
        surface_SetDrawColor(C.border_light)
        surface_DrawOutlinedRect(x, y, totalWidth, totalHeight, 1)
        
        -- Text lines
        for i, line in ipairs(lines) do
            local text = line.text or line
            local color = line.color or C.text_primary
            draw_SimpleText(text, "TDMRP_Small", x + padding, y + padding + (i-1) * lineHeight, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end
    
    -- Draw a glow effect behind an element
    function TDMRP.UI.DrawGlow(x, y, w, h, color, intensity)
        intensity = intensity or 20
        color = color or C.accent_glow
        
        for i = intensity, 1, -2 do
            local alpha = (intensity - i) * (color.a / intensity)
            surface_SetDrawColor(ColorAlpha(color, alpha))
            surface_DrawRect(x - i, y - i, w + i*2, h + i*2)
        end
    end
    
    -- Draw an icon placeholder (box with letter)
    function TDMRP.UI.DrawIconPlaceholder(x, y, size, letter, bgColor)
        size = size or 48
        bgColor = bgColor or C.bg_light
        
        draw_RoundedBox(4, x, y, size, size, bgColor)
        surface_SetDrawColor(C.border_light)
        surface_DrawOutlinedRect(x, y, size, size, 1)
        
        draw_SimpleText(letter or "?", "TDMRP_Header", x + size/2, y + size/2, C.text_muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Animate a value smoothly
    TDMRP.UI.AnimatedValues = TDMRP.UI.AnimatedValues or {}
    
    function TDMRP.UI.Lerp(id, target, speed)
        speed = speed or 10
        TDMRP.UI.AnimatedValues[id] = TDMRP.UI.AnimatedValues[id] or target
        TDMRP.UI.AnimatedValues[id] = Lerp(FrameTime() * speed, TDMRP.UI.AnimatedValues[id], target)
        return TDMRP.UI.AnimatedValues[id]
    end
    
    -- Check if mouse is in bounds
    function TDMRP.UI.IsMouseInBounds(x, y, w, h)
        local mx, my = gui.MousePos()
        return mx >= x and mx <= x + w and my >= y and my <= y + h
    end
end

----------------------------------------------------
-- Utility Functions (Shared)
----------------------------------------------------

-- Format money with commas
function TDMRP.UI.FormatMoney(amount)
    local formatted = tostring(math.floor(amount))
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return "$" .. formatted
end

-- Format time (seconds to MM:SS)
function TDMRP.UI.FormatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

-- Get tier name
function TDMRP.UI.GetTierName(tier)
    local names = {
        [1] = "Common",
        [2] = "Uncommon",
        [3] = "Rare",
        [4] = "Epic",
        [5] = "Legendary",
    }
    return names[tier] or "Unknown"
end

print("[TDMRP] sh_tdmrp_ui_theme.lua loaded - UI theme system initialized")
