----------------------------------------------------
-- TDMRP Dynamic Crosshair
-- Responsive crosshair for M9K weapons with accuracy integration
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.Crosshair = TDMRP.Crosshair or {}

----------------------------------------------------
-- Crosshair Configuration
----------------------------------------------------

local Config = {
    -- Base dimensions
    baseGap = 6,           -- Gap between crosshair lines
    lineLength = 10,       -- Length of each line
    lineThickness = 2,     -- Thickness of lines
    dotSize = 2,           -- Center dot size (0 to disable)
    
    -- Dynamic scaling (visual feedback only, actual spread from accuracy system)
    fireExpansion = 8,     -- Visual gap increase when firing
    fireDecay = 10,        -- How fast fire expansion decays
    jumpExpansion = 10,    -- Visual gap increase when airborne
    
    -- Spread to gap conversion
    spreadToGap = 800,     -- Multiplier: spread value * this = gap pixels
    
    -- Modifiers
    crouchReduction = 0.7, -- Gap multiplier when crouching
    adsHide = true,        -- Hide crosshair when ADS
    
    -- Shotgun circle config
    shotgunCircleSegments = 32,    -- Segments for circle
    shotgunDotSize = 1,            -- Tiny center dot for shotguns
    
    -- Colors
    colorNormal = Color(204, 0, 0, 220),      -- Red
    colorSniper = Color(0, 180, 255, 220),    -- Cyan for snipers
    colorShotgun = Color(255, 160, 0, 220),   -- Orange for shotguns
    colorOutline = Color(0, 0, 0, 180),       -- Black outline
    colorHit = Color(255, 60, 60, 255),       -- Hit indicator
}

----------------------------------------------------
-- State Variables
----------------------------------------------------

local currentGap = Config.baseGap
local fireExpansion = 0
local currentSpread = 0.01
local lastShotTime = 0
local hitMarkerAlpha = 0
local hitMarkerTime = 0
local recoilBloomMultiplier = 1.0  -- Temporary spread multiplier from recoil
local recoilBloomDecay = 2.0       -- Seconds to decay recoil bloom
local lastSniperShotTime = 0       -- Track sniper shots for bloom effect
local crosshairAlpha = 255         -- Crosshair fade alpha

----------------------------------------------------
-- Hit Marker System
----------------------------------------------------

-- Network message for server-confirmed hits
if not net.Receivers["TDMRP_HitMarker"] then
    net.Receive("TDMRP_HitMarker", function()
        hitMarkerAlpha = 255
        hitMarkerTime = CurTime()
    end)
end

----------------------------------------------------
-- Crosshair Logic
----------------------------------------------------

hook.Add("HUDPaint", "TDMRP_DynamicCrosshair", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    
    -- Only draw for M9K weapons
    if not TDMRP.IsM9KWeapon(wep) then return end
    
    -- Check for ADS (ironsights)
    if Config.adsHide then
        local bIron = wep:GetNWBool("Ironsights", false)
        if bIron then return end
    end
    
    local frameTime = FrameTime()
    
    -- Get player velocity early (used for multiple checks)
    local playerVelocity = ply:GetVelocity():Length2D()
    
    -- Get weapon type from accuracy system
    local weaponType = "normal"
    if TDMRP.Accuracy and TDMRP.Accuracy.GetWeaponType then
        weaponType = TDMRP.Accuracy.GetWeaponType(wep)
    end
    
    -- Get actual spread from accuracy system
    local targetSpread = 0.01
    if TDMRP.Accuracy and TDMRP.Accuracy.GetCurrentSpread then
        targetSpread = TDMRP.Accuracy.GetCurrentSpread(ply, wep)
    else
        targetSpread = wep.Primary and wep.Primary.Spread or 0.01
    end
    
    -- Apply recoil bloom (post-shot spread increase)
    -- Bloom only applies when standing still - movement penalty takes precedence
    local timeSinceSniperShot = CurTime() - lastSniperShotTime
    
    if weaponType == "sniper" and timeSinceSniperShot < recoilBloomDecay and playerVelocity < 50 then
        -- Only bloom if sniper, within decay window, AND standing still
        local bloomAmount = math.Clamp(1.0 - (timeSinceSniperShot / recoilBloomDecay), 0, 1)
        recoilBloomMultiplier = 1.0 + (bloomAmount * 2.0)  -- Up to 3x spread after shot
    else
        -- Always decay when not in bloom state
        recoilBloomMultiplier = Lerp(frameTime * 1, recoilBloomMultiplier, 1.0)
    end

    targetSpread = targetSpread * recoilBloomMultiplier
    
    -- Smooth spread changes
    currentSpread = Lerp(frameTime * 12, currentSpread, targetSpread)
    
    -- Get base spread for fade threshold
    local baseSpread = 0.01
    if TDMRP.Accuracy and TDMRP.Accuracy.GetBaseSpread then
        baseSpread = TDMRP.Accuracy.GetBaseSpread(wep)
    elseif wep.TDMRP_BaseSpread then
        baseSpread = wep.TDMRP_BaseSpread
    end
    
    -- Convert spread to gap
    local targetGap = currentSpread * Config.spreadToGap
    
    -- Fire expansion (visual feedback for shooting)
    local lastAttack = wep:GetNextPrimaryFire()
    if lastAttack and lastAttack > lastShotTime then
        fireExpansion = Config.fireExpansion
        lastShotTime = lastAttack
        
        -- Track sniper shots for recoil bloom
        if weaponType == "sniper" then
            lastSniperShotTime = CurTime()
        end
    end
    
    -- Decay fire expansion
    fireExpansion = math.Approach(fireExpansion, 0, frameTime * Config.fireDecay * 60)
    targetGap = targetGap + fireExpansion
    
    -- Jump expansion (additional penalty while airborne)
    if not ply:OnGround() then
        targetGap = targetGap + Config.jumpExpansion
    end
    
    -- Crouch reduction
    if ply:Crouching() then
        targetGap = targetGap * Config.crouchReduction
    end
    
    -- Minimum gap
    targetGap = math.max(targetGap, 2)
    
    -- Smooth the gap
    currentGap = Lerp(frameTime * 15, currentGap, targetGap)
    
    -- Calculate fade threshold - only fade when gap gets extremely large (5x base spread)
    -- This allows sniper movement penalty to be fully visible
    local fadeThreshold = baseSpread * Config.spreadToGap * 5.0
    
    -- Fade out when spread exceeds threshold, fade in when player slows down
    local velocityThreshold = 50  -- Velocity units
    
    if currentGap > fadeThreshold then
        -- Spread is wide - start fading out
        if playerVelocity > velocityThreshold then
            -- Still moving - full fade out
            crosshairAlpha = math.Approach(crosshairAlpha, 50, frameTime * 300)
        else
            -- Slowing down - fade back in
            crosshairAlpha = math.Approach(crosshairAlpha, 255, frameTime * 200)
        end
    else
        -- Back to normal spread - ensure full alpha
        crosshairAlpha = math.Approach(crosshairAlpha, 255, frameTime * 150)
    end
    
    -- Hit marker fade
    if hitMarkerAlpha > 0 then
        hitMarkerAlpha = math.Approach(hitMarkerAlpha, 0, frameTime * 600)
    end
    
    -- Choose color based on weapon type
    local color = Config.colorNormal
    if weaponType == "sniper" then
        color = Config.colorSniper
    elseif weaponType == "shotgun" then
        color = Config.colorShotgun
    end
    
    -- Apply alpha to color
    color = ColorAlpha(color, crosshairAlpha)
    
    -- Draw functions
    local outlineColor = ColorAlpha(Config.colorOutline, crosshairAlpha * 0.7)
    
    local function DrawCrosshairLine(x1, y1, x2, y2, lineColor)
        -- Outline
        surface.SetDrawColor(outlineColor)
        for ox = -1, 1 do
            for oy = -1, 1 do
                if ox ~= 0 or oy ~= 0 then
                    surface.DrawLine(x1 + ox, y1 + oy, x2 + ox, y2 + oy)
                end
            end
        end
        -- Main line
        surface.SetDrawColor(lineColor)
        surface.DrawLine(x1, y1, x2, y2)
    end
    
    local function DrawThickLine(x1, y1, x2, y2, thickness, lineColor)
        local isVertical = (x1 == x2)
        
        for i = 0, thickness - 1 do
            local offset = i - math.floor(thickness / 2)
            if isVertical then
                DrawCrosshairLine(x1 + offset, y1, x2 + offset, y2, lineColor)
            else
                DrawCrosshairLine(x1, y1 + offset, x2, y2 + offset, lineColor)
            end
        end
    end
    
    -- Screen center
    local cx, cy = ScrW() / 2, ScrH() / 2
    local gap = math.floor(currentGap)
    local len = Config.lineLength
    local thick = Config.lineThickness
    
    -- Shotgun: Draw circle with tiny center dot
    if weaponType == "shotgun" then
        local radius = gap + len  -- Circle radius represents spread
        local segments = Config.shotgunCircleSegments
        
        -- Draw circle outline
        for i = 0, segments - 1 do
            local angle1 = (i / segments) * math.pi * 2
            local angle2 = ((i + 1) / segments) * math.pi * 2
            
            local x1 = cx + math.cos(angle1) * radius
            local y1 = cy + math.sin(angle1) * radius
            local x2 = cx + math.cos(angle2) * radius
            local y2 = cy + math.sin(angle2) * radius
            
            -- Outline
            surface.SetDrawColor(outlineColor)
            for ox = -1, 1 do
                for oy = -1, 1 do
                    if ox ~= 0 or oy ~= 0 then
                        surface.DrawLine(x1 + ox, y1 + oy, x2 + ox, y2 + oy)
                    end
                end
            end
            -- Main line
            surface.SetDrawColor(color)
            surface.DrawLine(x1, y1, x2, y2)
        end
        
        -- Tiny center dot for shotguns
        if Config.shotgunDotSize > 0 then
            local dotHalf = math.floor(Config.shotgunDotSize / 2)
            -- Outline
            surface.SetDrawColor(Config.colorOutline)
            surface.DrawRect(cx - dotHalf - 1, cy - dotHalf - 1, Config.shotgunDotSize + 2, Config.shotgunDotSize + 2)
            -- Dot
            surface.SetDrawColor(color)
            surface.DrawRect(cx - dotHalf, cy - dotHalf, Config.shotgunDotSize, Config.shotgunDotSize)
        end
    else
        -- Normal/Sniper: Draw cross with gap
        
        -- Top line
        DrawThickLine(cx, cy - gap - len, cx, cy - gap, thick, color)
        
        -- Bottom line
        DrawThickLine(cx, cy + gap, cx, cy + gap + len, thick, color)
        
        -- Left line
        DrawThickLine(cx - gap - len, cy, cx - gap, cy, thick, color)
        
        -- Right line
        DrawThickLine(cx + gap, cy, cx + gap + len, cy, thick, color)
        
        -- Center dot
        if Config.dotSize > 0 then
            local dotHalf = math.floor(Config.dotSize / 2)
            -- Outline
            surface.SetDrawColor(Config.colorOutline)
            surface.DrawRect(cx - dotHalf - 1, cy - dotHalf - 1, Config.dotSize + 2, Config.dotSize + 2)
            -- Dot
            surface.SetDrawColor(color)
            surface.DrawRect(cx - dotHalf, cy - dotHalf, Config.dotSize, Config.dotSize)
        end
    end
    
    -- Hit marker (X shape)
    if hitMarkerAlpha > 0 then
        local hitColor = ColorAlpha(Config.colorHit, hitMarkerAlpha)
        local hitSize = 8
        local hitGap = 4
        
        -- Draw X with outline
        local function DrawHitLine(x1, y1, x2, y2)
            -- Outline
            surface.SetDrawColor(0, 0, 0, hitMarkerAlpha * 0.6)
            for ox = -1, 1 do
                for oy = -1, 1 do
                    if ox ~= 0 or oy ~= 0 then
                        surface.DrawLine(x1 + ox, y1 + oy, x2 + ox, y2 + oy)
                    end
                end
            end
            surface.SetDrawColor(hitColor)
            surface.DrawLine(x1, y1, x2, y2)
        end
        
        -- Top-left to center
        DrawHitLine(cx - hitGap - hitSize, cy - hitGap - hitSize, cx - hitGap, cy - hitGap)
        -- Top-right to center
        DrawHitLine(cx + hitGap + hitSize, cy - hitGap - hitSize, cx + hitGap, cy - hitGap)
        -- Bottom-left to center
        DrawHitLine(cx - hitGap - hitSize, cy + hitGap + hitSize, cx - hitGap, cy + hitGap)
        -- Bottom-right to center
        DrawHitLine(cx + hitGap + hitSize, cy + hitGap + hitSize, cx + hitGap, cy + hitGap)
    end
end)

----------------------------------------------------
-- Hide default crosshair for M9K weapons
----------------------------------------------------

hook.Add("HUDShouldDraw", "TDMRP_HideCrosshair", function(name)
    if name == "CHudCrosshair" then
        local ply = LocalPlayer()
        if IsValid(ply) then
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and TDMRP.IsM9KWeapon(wep) then
                return false
            end
        end
    end
end)

print("[TDMRP] cl_tdmrp_crosshair.lua loaded - Dynamic crosshair with accuracy integration")
