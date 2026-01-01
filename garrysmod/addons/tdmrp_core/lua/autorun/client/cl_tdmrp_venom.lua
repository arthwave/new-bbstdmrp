-- cl_tdmrp_venom.lua
-- Client-side venom effects: poison vignette and cloud particles

if not CLIENT then return end

print("[TDMRP] cl_tdmrp_venom.lua LOADING...")

TDMRP = TDMRP or {}
TDMRP.Venom = TDMRP.Venom or {}

-- Local player poison state
local poisonStacks = 0
local poisonExpire = 0

-- Vignette material
local vignetteMatPath = "effects/combine_binocoverlay"
local vignetteMat = Material(vignetteMatPath)

-- Receive poison status from server
net.Receive("TDMRP_VenomStatus", function()
    poisonStacks = net.ReadUInt(4)
    poisonExpire = net.ReadFloat()
    
    print("[TDMRP Venom] Poison status - Stacks: " .. poisonStacks .. ", Expire: " .. poisonExpire)
end)

-- Receive poison cloud effect (visible on other players)
net.Receive("TDMRP_VenomCloud", function()
    local pos = net.ReadVector()
    local stacks = net.ReadUInt(4)
    
    -- Spawn poison cloud particles
    local emitter = ParticleEmitter(pos)
    if emitter then
        local particleCount = 4 + stacks * 2
        
        for i = 1, particleCount do
            local particle = emitter:Add("particles/smokey", pos + VectorRand() * 10)
            if particle then
                particle:SetVelocity(Vector(math.Rand(-20, 20), math.Rand(-20, 20), math.Rand(10, 40)))
                particle:SetLifeTime(0)
                particle:SetDieTime(0.8 + math.Rand(0, 0.4))
                particle:SetStartAlpha(150 + stacks * 20)
                particle:SetEndAlpha(0)
                particle:SetStartSize(10 + stacks * 3)
                particle:SetEndSize(20 + stacks * 5)
                particle:SetColor(40, 180 + math.random(0, 40), 40)
                particle:SetGravity(Vector(0, 0, 30))
                particle:SetRoll(math.Rand(0, 360))
                particle:SetRollDelta(math.Rand(-2, 2))
            end
        end
        
        -- Add some toxic drips
        for i = 1, 3 do
            local particle = emitter:Add("effects/spark", pos + VectorRand() * 5)
            if particle then
                particle:SetVelocity(Vector(math.Rand(-30, 30), math.Rand(-30, 30), math.Rand(-50, -20)))
                particle:SetLifeTime(0)
                particle:SetDieTime(0.4)
                particle:SetStartAlpha(255)
                particle:SetEndAlpha(0)
                particle:SetStartSize(2)
                particle:SetEndSize(1)
                particle:SetColor(80, 255, 80)
                particle:SetGravity(Vector(0, 0, -400))
            end
        end
        
        emitter:Finish()
    end
end)

-- Draw poison vignette
hook.Add("RenderScreenspaceEffects", "TDMRP_VenomVignette", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    -- Check if poisoned
    if poisonStacks <= 0 or CurTime() > poisonExpire then
        poisonStacks = 0
        return
    end
    
    -- Calculate intensity based on stacks (1-3)
    local baseIntensity = poisonStacks / TDMRP.Venom.MaxStacks or (poisonStacks / 3)
    
    -- Pulse effect synced to tick timing
    local pulseSpeed = 2 + poisonStacks
    local pulse = math.sin(CurTime() * pulseSpeed) * 0.15
    local intensity = math.Clamp(baseIntensity * 0.6 + pulse, 0.1, 0.8)
    
    local scrW, scrH = ScrW(), ScrH()
    
    -- Green vignette overlay
    surface.SetDrawColor(30, 120, 30, 80 * intensity)
    surface.DrawRect(0, 0, scrW, scrH)
    
    -- Vignette edges (darker green at edges)
    local vignetteSize = 0.3 + (1 - intensity) * 0.2
    
    -- Top edge
    surface.SetDrawColor(20, 80, 20, 150 * intensity)
    for i = 1, 5 do
        local alpha = (150 * intensity) * (1 - i / 5)
        surface.SetDrawColor(20, 80, 20, alpha)
        surface.DrawRect(0, (i - 1) * scrH * 0.04, scrW, scrH * 0.04)
    end
    
    -- Bottom edge
    for i = 1, 5 do
        local alpha = (150 * intensity) * (1 - i / 5)
        surface.SetDrawColor(20, 80, 20, alpha)
        surface.DrawRect(0, scrH - i * scrH * 0.04, scrW, scrH * 0.04)
    end
    
    -- Left edge
    for i = 1, 5 do
        local alpha = (150 * intensity) * (1 - i / 5)
        surface.SetDrawColor(20, 80, 20, alpha)
        surface.DrawRect((i - 1) * scrW * 0.03, 0, scrW * 0.03, scrH)
    end
    
    -- Right edge
    for i = 1, 5 do
        local alpha = (150 * intensity) * (1 - i / 5)
        surface.SetDrawColor(20, 80, 20, alpha)
        surface.DrawRect(scrW - i * scrW * 0.03, 0, scrW * 0.03, scrH)
    end
    
    -- Corner darkening for true vignette feel
    local cornerSize = scrW * 0.25 * intensity
    
    -- Draw radial gradient approximation with circles at corners
    for corner = 1, 4 do
        local cx, cy
        if corner == 1 then cx, cy = 0, 0
        elseif corner == 2 then cx, cy = scrW, 0
        elseif corner == 3 then cx, cy = 0, scrH
        else cx, cy = scrW, scrH end
        
        for i = 1, 8 do
            local size = cornerSize * (1 - i / 10)
            local alpha = (100 * intensity) * (1 - i / 8)
            surface.SetDrawColor(15, 60, 15, alpha)
            
            local halfSize = size / 2
            surface.DrawRect(cx - halfSize, cy - halfSize, size, size)
        end
    end
    
    -- Poison indicator text
    local stackText = string.rep("☠", poisonStacks)
    local timeLeft = math.max(0, poisonExpire - CurTime())
    
    surface.SetFont("DermaLarge")
    local tw, th = surface.GetTextSize(stackText)
    
    -- Pulsing glow behind text
    local glowAlpha = 100 + math.sin(CurTime() * 8) * 50
    draw.SimpleText(stackText, "DermaLarge", scrW / 2 + 2, scrH * 0.15 + 2, Color(0, 50, 0, glowAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(stackText, "DermaLarge", scrW / 2, scrH * 0.15, Color(100, 255, 100, 200 + pulse * 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Time remaining
    local timeText = string.format("%.1fs", timeLeft)
    draw.SimpleText(timeText, "DermaDefault", scrW / 2, scrH * 0.15 + 25, Color(150, 255, 150, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

-- Set max stacks for intensity calculation
TDMRP.Venom.MaxStacks = 3

print("[TDMRP] cl_tdmrp_venom.lua loaded - Venom vignette and effects ready")
