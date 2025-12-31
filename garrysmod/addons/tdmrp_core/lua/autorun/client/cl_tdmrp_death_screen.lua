----------------------------------------------------
-- TDMRP Death Screen
-- Minimalist death UI for combat classes
-- Features:
--   - Timer bar countdown
--   - Spawn location selection (WASD keys)
--   - Control point availability display
----------------------------------------------------

if not CLIENT then return end

TDMRP = TDMRP or {}

----------------------------------------------------
-- Death Screen State
----------------------------------------------------

local DeathScreen = {
    active = false,
    canRespawn = false,
    deathTime = 0,
    respawnDelay = 5,
    class = "civilian",
    spawnPoints = {},  -- Available spawn points from server
    selectedSpawn = 0, -- 0 = default, 1-4 = WASD
    keyHoldStart = {},  -- Track when keys started being held
}

-- Key hold threshold for spawn selection (seconds)
local KEY_HOLD_TIME = 0.3

----------------------------------------------------
-- Theme Colors (Minimalist)
----------------------------------------------------

local Colors = {
    overlay = Color(0, 0, 0, 180),
    timerBarBg = Color(40, 40, 40, 220),
    timerBarFill = Color(200, 60, 60, 255),
    timerBarReady = Color(60, 200, 60, 255),
    text = Color(220, 220, 220, 255),
    textDim = Color(120, 120, 120, 255),
    spawnAvailable = Color(80, 200, 80, 255),
    spawnUnavailable = Color(80, 80, 80, 180),
    spawnSelected = Color(255, 220, 60, 255),
    keyLabel = Color(255, 255, 255, 255),
    keyLabelDim = Color(100, 100, 100, 180),
}

----------------------------------------------------
-- Fonts
----------------------------------------------------

surface.CreateFont("TDMRP_DeathTimer", {
    font = "Roboto",
    size = 32,
    weight = 700,
})

surface.CreateFont("TDMRP_DeathTitle", {
    font = "Roboto",
    size = 24,
    weight = 600,
})

surface.CreateFont("TDMRP_SpawnKey", {
    font = "Roboto Bold",
    size = 28,
    weight = 800,
})

surface.CreateFont("TDMRP_SpawnName", {
    font = "Roboto",
    size = 14,
    weight = 400,
})

----------------------------------------------------
-- Spawn Point Mapping (WASD)
----------------------------------------------------

local SpawnKeys = {
    { key = KEY_W, label = "W", name = "FORWARD" },
    { key = KEY_A, label = "A", name = "LEFT" },
    { key = KEY_S, label = "S", name = "BACK" },
    { key = KEY_D, label = "D", name = "RIGHT" },
}

----------------------------------------------------
-- Network: Receive death screen
----------------------------------------------------

net.Receive("TDMRP_DeathScreen", function()
    local delay = net.ReadFloat()
    local class = net.ReadString()
    
    DeathScreen.active = true
    DeathScreen.canRespawn = false
    DeathScreen.deathTime = CurTime()
    DeathScreen.respawnDelay = delay
    DeathScreen.class = class
    DeathScreen.selectedSpawn = 0
    DeathScreen.keyHoldStart = {}
    
    -- Request spawn point info from server
    if util.NetworkStringToID("TDMRP_RequestSpawnInfo") ~= 0 then
        net.Start("TDMRP_RequestSpawnInfo")
        net.SendToServer()
    end
end)

----------------------------------------------------
-- Network: Receive spawn point availability
----------------------------------------------------

net.Receive("TDMRP_SpawnPointInfo", function()
    local numPoints = net.ReadUInt(4)
    DeathScreen.spawnPoints = {}
    
    for i = 1, numPoints do
        local pointData = {
            name = net.ReadString(),
            available = net.ReadBool(),
            keyIndex = i,  -- 1=W, 2=A, 3=S, 4=D
        }
        table.insert(DeathScreen.spawnPoints, pointData)
    end
end)

----------------------------------------------------
-- Network: Respawn ready notification
----------------------------------------------------

net.Receive("TDMRP_RespawnReady", function()
    DeathScreen.canRespawn = true
    surface.PlaySound("buttons/button14.wav")
end)

----------------------------------------------------
-- Network: Spawn complete - close death screen
----------------------------------------------------

net.Receive("TDMRP_SpawnComplete", function()
    DeathScreen.active = false
    DeathScreen.canRespawn = false
end)

----------------------------------------------------
-- Request Respawn
----------------------------------------------------

local function RequestRespawn(spawnSelection)
    if not DeathScreen.active or not DeathScreen.canRespawn then return end
    
    spawnSelection = spawnSelection or 0
    
    net.Start("TDMRP_RequestRespawn")
        net.WriteUInt(spawnSelection, 3)
    net.SendToServer()
    
    DeathScreen.canRespawn = false
end

----------------------------------------------------
-- Input Hook: Track key holds for spawn selection
----------------------------------------------------

hook.Add("Think", "TDMRP_DeathScreenInput", function()
    if not DeathScreen.active then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:Alive() then
        DeathScreen.active = false
        return
    end
    
    if not DeathScreen.canRespawn then return end
    
    local now = CurTime()
    
    -- Check SPACE for default spawn
    if input.IsKeyDown(KEY_SPACE) then
        RequestRespawn(0)
        return
    end
    
    -- Check WASD keys for control point spawns
    for i, keyData in ipairs(SpawnKeys) do
        if input.IsKeyDown(keyData.key) then
            -- Check if spawn point is available
            local spawnPoint = DeathScreen.spawnPoints[i]
            if spawnPoint and spawnPoint.available then
                -- Track hold start time
                if not DeathScreen.keyHoldStart[i] then
                    DeathScreen.keyHoldStart[i] = now
                end
                
                -- Check if held long enough
                if now - DeathScreen.keyHoldStart[i] >= KEY_HOLD_TIME then
                    RequestRespawn(i)
                    return
                end
            end
        else
            DeathScreen.keyHoldStart[i] = nil
        end
    end
end)

----------------------------------------------------
-- Draw Helper: Rounded progress bar
----------------------------------------------------

local function DrawProgressBar(x, y, w, h, progress, bgColor, fillColor, radius)
    radius = radius or 4
    
    -- Background
    draw.RoundedBox(radius, x, y, w, h, bgColor)
    
    -- Fill
    local fillW = math.max(0, w * progress)
    if fillW > 0 then
        -- Clip the fill to the progress width
        render.SetScissorRect(x, y, x + fillW, y + h, true)
        draw.RoundedBox(radius, x, y, w, h, fillColor)
        render.SetScissorRect(0, 0, 0, 0, false)
    end
end

----------------------------------------------------
-- Draw Spawn Point Box
----------------------------------------------------

local function DrawSpawnBox(x, y, size, keyLabel, pointName, available, holdProgress)
    local bgColor = available and Colors.spawnAvailable or Colors.spawnUnavailable
    local keyColor = available and Colors.keyLabel or Colors.keyLabelDim
    local nameColor = available and Colors.text or Colors.textDim
    
    -- If being held, show progress
    if holdProgress and holdProgress > 0 then
        bgColor = Colors.spawnSelected
    end
    
    -- Box background
    draw.RoundedBox(6, x, y, size, size, bgColor)
    
    -- Hold progress overlay
    if holdProgress and holdProgress > 0 and available then
        local progressH = size * holdProgress
        render.SetScissorRect(x, y + size - progressH, x + size, y + size, true)
        draw.RoundedBox(6, x, y, size, size, Color(255, 255, 255, 100))
        render.SetScissorRect(0, 0, 0, 0, false)
    end
    
    -- Key label
    draw.SimpleText(keyLabel, "TDMRP_SpawnKey", x + size/2, y + size/2 - 6, keyColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Point name (below key)
    if pointName and pointName ~= "" then
        draw.SimpleText(pointName, "TDMRP_SpawnName", x + size/2, y + size - 10, nameColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

----------------------------------------------------
-- HUD Paint: Death Screen
----------------------------------------------------

hook.Add("HUDPaint", "TDMRP_DeathScreenPaint", function()
    if not DeathScreen.active then return end
    
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    if ply:Alive() then
        DeathScreen.active = false
        return
    end
    
    local scrW, scrH = ScrW(), ScrH()
    local centerX = scrW / 2
    
    -- Dark overlay
    draw.RoundedBox(0, 0, 0, scrW, scrH, Colors.overlay)
    
    -- Calculate time remaining
    local elapsed = CurTime() - DeathScreen.deathTime
    local remaining = math.max(0, DeathScreen.respawnDelay - elapsed)
    local progress = remaining / DeathScreen.respawnDelay
    
    -- UI positioning (centered, upper third of screen)
    local uiY = scrH * 0.3
    local barWidth = 300
    local barHeight = 8
    local boxSize = 60
    local boxSpacing = 20
    
    -- Death title
    local titleText = DeathScreen.canRespawn and "RESPAWN READY" or "RESPAWNING..."
    draw.SimpleText(titleText, "TDMRP_DeathTitle", centerX, uiY - 40, Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Timer bar
    local barX = centerX - barWidth/2
    local barColor = DeathScreen.canRespawn and Colors.timerBarReady or Colors.timerBarFill
    DrawProgressBar(barX, uiY, barWidth, barHeight, DeathScreen.canRespawn and 1 or progress, Colors.timerBarBg, barColor)
    
    -- Timer text (only show countdown when not ready)
    if not DeathScreen.canRespawn then
        local timerText = string.format("%.1f", remaining)
        draw.SimpleText(timerText, "TDMRP_DeathTimer", centerX, uiY + 30, Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Spawn points section
    local spawnY = uiY + 80
    local numPoints = #DeathScreen.spawnPoints
    
    if numPoints > 0 or DeathScreen.canRespawn then
        -- Calculate total width for centering
        local totalWidth = (numPoints > 0) and (numPoints * boxSize + (numPoints - 1) * boxSpacing) or 0
        local startX = centerX - totalWidth/2
        
        -- Draw spawn point boxes
        for i, keyData in ipairs(SpawnKeys) do
            local spawnPoint = DeathScreen.spawnPoints[i]
            local available = spawnPoint and spawnPoint.available or false
            local pointName = spawnPoint and spawnPoint.name or ""
            
            -- Calculate hold progress
            local holdProgress = 0
            if DeathScreen.canRespawn and DeathScreen.keyHoldStart[i] then
                holdProgress = math.Clamp((CurTime() - DeathScreen.keyHoldStart[i]) / KEY_HOLD_TIME, 0, 1)
            end
            
            local boxX = startX + (i - 1) * (boxSize + boxSpacing)
            
            -- Only draw if we have spawn point data
            if spawnPoint then
                DrawSpawnBox(boxX, spawnY, boxSize, keyData.label, pointName, available, holdProgress)
            end
        end
        
        -- Help text
        if DeathScreen.canRespawn then
            local helpText = numPoints > 0 and "HOLD KEY to spawn at control point  |  SPACE for base spawn" or "Press SPACE to respawn"
            draw.SimpleText(helpText, "TDMRP_SpawnName", centerX, spawnY + boxSize + 20, Colors.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    else
        -- No control points available, show simple respawn prompt
        if DeathScreen.canRespawn then
            draw.SimpleText("Press SPACE to respawn", "TDMRP_DeathTitle", centerX, spawnY, Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end)

----------------------------------------------------
-- Hide default HUD elements while death screen is active
----------------------------------------------------

hook.Add("HUDShouldDraw", "TDMRP_HideDefaultDeathUI", function(name)
    if not DeathScreen.active then return end
    
    if name == "CHudDeathNotice" or name == "CHudHealth" or name == "CHudBattery" or name == "CHudAmmo" then
        return false
    end
end)

----------------------------------------------------
-- Reset on spawn
----------------------------------------------------

hook.Add("OnSpawnMenuOpen", "TDMRP_CloseDeathScreen", function()
    if DeathScreen.active and LocalPlayer():Alive() then
        DeathScreen.active = false
    end
end)

print("[TDMRP] cl_tdmrp_death_screen.lua loaded - Minimalist death UI")
