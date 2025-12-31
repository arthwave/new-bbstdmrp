----------------------------------------------------
-- TDMRP Center Screen Messages (Client-Side)
-- Displays important effect notifications to players
-- Handles damage notifications with cooldown
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.CenterMessages = TDMRP.CenterMessages or {}

----------------------------------------------------
-- Configuration
----------------------------------------------------

local CONFIG = {
    -- Center message settings
    MESSAGE_DURATION = 2.0,       -- How long center messages display
    MESSAGE_FADE_TIME = 0.5,      -- Fade out time
    
    -- Damage notification settings
    DAMAGE_COOLDOWN = 1.0,        -- Cooldown between damage messages per attacker
    DAMAGE_DURATION = 2.5,        -- How long damage messages display
    DAMAGE_FADE_TIME = 0.3,       -- Fade out time for damage messages
    
    -- Vignette settings
    VIGNETTE_PULSE_SPEED = 3,     -- How fast vignettes pulse
}

----------------------------------------------------
-- State Tracking
----------------------------------------------------

-- Center messages queue
local ActiveCenterMessage = nil

-- Damage notifications
local DamageMessages = {}  -- { [attackerName] = { lastTime, totalDamage, displayUntil } }

-- Active effect vignettes (for suffix effects like frost)
local ActiveEffectVignette = nil

----------------------------------------------------
-- Center Message System
----------------------------------------------------

-- Display a center screen message (like "Blink blocked by obstacle!")
function TDMRP.ShowCenterMessage(text, color, duration)
    color = color or Color(255, 255, 255, 255)
    duration = duration or CONFIG.MESSAGE_DURATION
    
    ActiveCenterMessage = {
        text = text,
        color = color,
        startTime = CurTime(),
        duration = duration,
        fadeTime = CONFIG.MESSAGE_FADE_TIME
    }
end

-- Network receiver for server-triggered center messages
net.Receive("TDMRP_CenterMessage", function()
    local text = net.ReadString()
    local r = net.ReadUInt(8)
    local g = net.ReadUInt(8)
    local b = net.ReadUInt(8)
    local duration = net.ReadFloat()
    
    TDMRP.ShowCenterMessage(text, Color(r, g, b, 255), duration)
end)

----------------------------------------------------
-- Damage Notification System
----------------------------------------------------

-- Add/update damage notification from an attacker
function TDMRP.ShowDamageNotification(attackerName, damage)
    local now = CurTime()
    local existing = DamageMessages[attackerName]
    
    -- Check cooldown per attacker
    if existing and (now - existing.lastTime) < CONFIG.DAMAGE_COOLDOWN then
        -- Update existing damage amount (stack damage during cooldown)
        existing.totalDamage = existing.totalDamage + damage
        existing.displayUntil = now + CONFIG.DAMAGE_DURATION
        return
    end
    
    -- Create new damage message
    DamageMessages[attackerName] = {
        lastTime = now,
        totalDamage = damage,
        displayUntil = now + CONFIG.DAMAGE_DURATION,
        fadeTime = CONFIG.DAMAGE_FADE_TIME
    }
end

-- Network receiver for damage notifications
net.Receive("TDMRP_DamageNotification", function()
    local attackerName = net.ReadString()
    local damage = net.ReadFloat()
    
    TDMRP.ShowDamageNotification(attackerName, damage)
end)

----------------------------------------------------
-- Effect Vignette System (for suffix effects)
----------------------------------------------------

-- Show a vignette effect (e.g., frost slow, burning, etc.)
function TDMRP.ShowEffectVignette(color, duration, pulseSpeed)
    ActiveEffectVignette = {
        color = color,
        startTime = CurTime(),
        duration = duration,
        pulseSpeed = pulseSpeed or CONFIG.VIGNETTE_PULSE_SPEED
    }
end

-- Clear effect vignette
function TDMRP.ClearEffectVignette()
    ActiveEffectVignette = nil
end

-- Network receiver for effect vignettes
net.Receive("TDMRP_EffectVignette", function()
    local r = net.ReadUInt(8)
    local g = net.ReadUInt(8)
    local b = net.ReadUInt(8)
    local a = net.ReadUInt(8)
    local duration = net.ReadFloat()
    
    if duration <= 0 then
        TDMRP.ClearEffectVignette()
    else
        TDMRP.ShowEffectVignette(Color(r, g, b, a), duration)
    end
end)

----------------------------------------------------
-- HUD Drawing
----------------------------------------------------

hook.Add("HUDPaint", "TDMRP_CenterMessages", function()
    local scrW, scrH = ScrW(), ScrH()
    local now = CurTime()
    
    -- Draw center message
    if ActiveCenterMessage then
        local msg = ActiveCenterMessage
        local elapsed = now - msg.startTime
        local totalDuration = msg.duration + msg.fadeTime
        
        if elapsed >= totalDuration then
            ActiveCenterMessage = nil
        else
            local alpha = 255
            if elapsed > msg.duration then
                -- Fade out
                local fadeProgress = (elapsed - msg.duration) / msg.fadeTime
                alpha = 255 * (1 - fadeProgress)
            end
            
            -- Draw background box
            local textW, textH = surface.GetTextSize(msg.text)
            surface.SetFont("DermaLarge")
            textW, textH = surface.GetTextSize(msg.text)
            
            local boxW = textW + 40
            local boxH = textH + 20
            local boxX = (scrW - boxW) / 2
            local boxY = scrH * 0.35
            
            -- Background
            surface.SetDrawColor(0, 0, 0, alpha * 0.7)
            surface.DrawRect(boxX, boxY, boxW, boxH)
            
            -- Border
            surface.SetDrawColor(msg.color.r, msg.color.g, msg.color.b, alpha)
            surface.DrawOutlinedRect(boxX, boxY, boxW, boxH, 2)
            
            -- Text
            draw.SimpleText(msg.text, "DermaLarge", scrW / 2, boxY + boxH / 2, 
                Color(msg.color.r, msg.color.g, msg.color.b, alpha), 
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
    
    -- Draw damage notifications (stacked on right side)
    local damageY = scrH * 0.3
    local toRemove = {}
    
    for attackerName, data in pairs(DamageMessages) do
        if now >= data.displayUntil then
            table.insert(toRemove, attackerName)
        else
            local alpha = 255
            local timeLeft = data.displayUntil - now
            if timeLeft < data.fadeTime then
                alpha = 255 * (timeLeft / data.fadeTime)
            end
            
            -- Format damage with one decimal
            local damageText = string.format("%s dealt %.1f damage to you!", attackerName, data.totalDamage)
            
            -- Background
            surface.SetFont("DermaDefault")
            local textW, textH = surface.GetTextSize(damageText)
            local boxW = textW + 20
            local boxH = textH + 10
            local boxX = scrW - boxW - 20
            
            surface.SetDrawColor(80, 0, 0, alpha * 0.8)
            surface.DrawRect(boxX, damageY, boxW, boxH)
            
            -- Border
            surface.SetDrawColor(255, 100, 100, alpha)
            surface.DrawOutlinedRect(boxX, damageY, boxW, boxH, 1)
            
            -- Text
            draw.SimpleText(damageText, "DermaDefault", boxX + boxW / 2, damageY + boxH / 2,
                Color(255, 150, 150, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            damageY = damageY + boxH + 5
        end
    end
    
    -- Clean up expired damage messages
    for _, name in ipairs(toRemove) do
        DamageMessages[name] = nil
    end
    
    -- Draw effect vignette
    if ActiveEffectVignette then
        local vig = ActiveEffectVignette
        local elapsed = now - vig.startTime
        
        if elapsed >= vig.duration then
            ActiveEffectVignette = nil
        else
            -- Pulsing effect
            local pulse = math.sin(elapsed * vig.pulseSpeed) * 0.3 + 0.7
            local alpha = vig.color.a * pulse
            
            -- Fade in/out at start/end
            if elapsed < 0.3 then
                alpha = alpha * (elapsed / 0.3)
            elseif (vig.duration - elapsed) < 0.5 then
                alpha = alpha * ((vig.duration - elapsed) / 0.5)
            end
            
            -- Draw vignette gradient from edges
            local vignetteSize = 150
            local col = Color(vig.color.r, vig.color.g, vig.color.b, alpha)
            
            -- Top edge
            surface.SetDrawColor(col)
            for i = 0, vignetteSize do
                local lineAlpha = alpha * (1 - i / vignetteSize) * 0.5
                surface.SetDrawColor(vig.color.r, vig.color.g, vig.color.b, lineAlpha)
                surface.DrawRect(0, i, scrW, 1)
            end
            
            -- Bottom edge
            for i = 0, vignetteSize do
                local lineAlpha = alpha * (1 - i / vignetteSize) * 0.5
                surface.SetDrawColor(vig.color.r, vig.color.g, vig.color.b, lineAlpha)
                surface.DrawRect(0, scrH - i, scrW, 1)
            end
            
            -- Left edge
            for i = 0, vignetteSize do
                local lineAlpha = alpha * (1 - i / vignetteSize) * 0.3
                surface.SetDrawColor(vig.color.r, vig.color.g, vig.color.b, lineAlpha)
                surface.DrawRect(i, 0, 1, scrH)
            end
            
            -- Right edge
            for i = 0, vignetteSize do
                local lineAlpha = alpha * (1 - i / vignetteSize) * 0.3
                surface.SetDrawColor(vig.color.r, vig.color.g, vig.color.b, lineAlpha)
                surface.DrawRect(scrW - i, 0, 1, scrH)
            end
        end
    end
end)

print("[TDMRP] cl_tdmrp_center_messages.lua loaded")
