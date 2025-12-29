----------------------------------------------------
-- TDMRP Kill Log HUD
-- Client-side kill log display at top-right
-- Shows custom weapon names with icons
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.KillLog = TDMRP.KillLog or {}

----------------------------------------------------
-- Kill Log Configuration
----------------------------------------------------

local Config = {
    posX = ScrW() - 400,
    posY = 50,
    displayTime = 5,  -- Seconds
    maxKills = 8,  -- Max kills shown at once
    iconSize = 32,
    spacing = 35,
}

----------------------------------------------------
-- Kill Log Storage
----------------------------------------------------

local killLog = {}  -- { { attacker, victim, weaponName, time, isHeadshot, killStreak, streakCount }, ... }

----------------------------------------------------
-- Network Receiver
----------------------------------------------------

net.Receive("TDMRP_KillLog", function()
    local attacker = net.ReadEntity()
    local victim = net.ReadEntity()
    local weaponName = net.ReadString()
    local isHeadshot = net.ReadBool()
    local killStreak = net.ReadUInt(8)
    local streakCount = net.ReadUInt(8)
    local isNPC = net.ReadBool()
    
    -- Add to kill log
    table.insert(killLog, 1, {
        attacker = attacker,
        victim = victim,
        weaponName = weaponName,
        time = CurTime(),
        isHeadshot = isHeadshot,
        killStreak = killStreak,  -- 0=normal, 1=double, 2=triple, 3=quad+
        streakCount = streakCount,
        isNPC = isNPC,  -- Flag for NPC kills
    })
    
    -- Keep log size manageable
    if #killLog > Config.maxKills then
        table.remove(killLog)
    end
    
    print(string.format("[TDMRP KillLog HUD] Added kill: %s killed %s with %s", 
        IsValid(attacker) and (isNPC and attacker:GetClass() or attacker:Nick()) or "Unknown",
        IsValid(victim) and (victim:IsPlayer() and victim:Nick() or victim:GetClass()) or "Unknown",
        weaponName))
end)

----------------------------------------------------
-- Kill Streak Messages
----------------------------------------------------

local function GetKillStreakText(killStreak, streakCount)
    if killStreak == 0 then return "" end
    
    local streaks = {
        [1] = "DOUBLE KILL!",
        [2] = "TRIPLE KILL!",
        [3] = "QUAD KILL!",
    }
    
    if killStreak == 3 and streakCount > 4 then
        return string.format("%d-KILL STREAK!", streakCount)
    end
    
    return streaks[killStreak] or ""
end

----------------------------------------------------
-- Helper: Get weapon abbreviation
----------------------------------------------------

local function GetWeaponAbbreviation(weaponName)
    -- Remove "Custom *" wrapper if present
    local cleanName = weaponName:gsub("Custom %*(.*)%*", "%1")
    
    -- Remove prefixes like "Heavy ", "Light ", etc.
    cleanName = cleanName:gsub("^%w+ ", "")
    
    -- Remove suffixes like " of Shrapnel" at the end
    cleanName = cleanName:gsub(" of %w+$", "")
    
    -- Remove all spaces and take last 3 characters
    cleanName = cleanName:gsub(" ", ""):upper()
    
    if cleanName:len() >= 3 then
        return cleanName:sub(-3)  -- Last 3 chars
    else
        return cleanName  -- Use what we have
    end
end

----------------------------------------------------
-- Helper: Get tier-based icon color
----------------------------------------------------

local TierColors = {
    common = Color(160, 160, 160, 255),      -- Gray
    uncommon = Color(100, 200, 100, 255),    -- Green
    rare = Color(100, 150, 255, 255),        -- Blue
    legendary = Color(255, 165, 0, 255),     -- Orange/Gold
    unique = Color(200, 100, 255, 255),      -- Purple
}

local function GetTierColor(weaponName, isCustom)
    -- Custom weapons are legendary tier
    if isCustom then
        return TierColors.legendary
    end
    
    -- Check for tier indicators in weapon name
    if weaponName:find("Legendary") then
        return TierColors.legendary
    elseif weaponName:find("Rare") then
        return TierColors.rare
    elseif weaponName:find("Uncommon") then
        return TierColors.uncommon
    else
        -- Default to common (gray)
        return TierColors.common
    end
end

----------------------------------------------------
-- Helper: Draw gradient rectangle
----------------------------------------------------

local function DrawGradientBox(x, y, w, h, colorTop, colorBottom, alpha)
    local topColor = Color(colorTop.r, colorTop.g, colorTop.b, colorTop.a * alpha)
    local bottomColor = Color(colorBottom.r, colorBottom.g, colorBottom.b, colorBottom.a * alpha)
    
    -- Draw line by line for gradient effect
    for i = 0, h do
        local progress = i / h
        local r = Lerp(progress, topColor.r, bottomColor.r)
        local g = Lerp(progress, topColor.g, bottomColor.g)
        local b = Lerp(progress, topColor.b, bottomColor.b)
        local a = Lerp(progress, topColor.a, bottomColor.a)
        
        surface.SetDrawColor(r, g, b, a)
        surface.DrawLine(x, y + i, x + w, y + i)
    end
end

----------------------------------------------------
-- Helper: Draw glow effect
----------------------------------------------------

local function DrawGlowBox(x, y, w, h, glowColor, glowSize, alpha)
    local glowAlpha = glowSize * 10 * alpha
    
    surface.SetDrawColor(glowColor.r, glowColor.g, glowColor.b, glowAlpha)
    surface.DrawOutlinedRect(x - glowSize, y - glowSize, w + glowSize * 2, h + glowSize * 2, 1)
end

----------------------------------------------------
-- HUD Paint
----------------------------------------------------

hook.Add("HUDPaint", "TDMRP_KillLogDisplay", function()
    local currentTime = CurTime()
    local y = Config.posY
    local textColor = Color(255, 255, 255, 255)
    local customWeaponColor = Color(255, 215, 0, 255)  -- Gold
    local streakColor = Color(255, 100, 0, 255)  -- Orange
    local npcKillColor = Color(220, 50, 50, 255)  -- Red for NPC kills
    
    -- Remove expired kills
    for i = #killLog, 1, -1 do
        local kill = killLog[i]
        local age = currentTime - kill.time
        if age > Config.displayTime then
            table.remove(killLog, i)
        end
    end
    
    -- Render kills from newest to oldest
    for i, kill in ipairs(killLog) do
        local age = currentTime - kill.time
        local alpha = math.Clamp(1 - (age / Config.displayTime), 0, 1)  -- Fade out
        
        if alpha > 0 then
            -- Determine attacker and victim names
            local attackerName = IsValid(kill.attacker) and (kill.isNPC and kill.attacker:GetClass() or kill.attacker:Nick()) or "Unknown"
            local victimName = IsValid(kill.victim) and (kill.victim:IsPlayer() and kill.victim:Nick() or kill.victim:GetClass()) or "Unknown"
            
            -- Check if weapon name is custom (has custom marker)
            local isCustom = kill.weaponName and not kill.weaponName:find("Custom %*")
            
            -- Render kill entry
            surface.SetFont("TDMRP_Body")
            local textX = Config.posX
            local textY = y + (i - 1) * Config.spacing
            
            -- Attacker name
            local attackerColor = kill.isNPC and npcKillColor or Color(255, 255, 255, 255 * alpha)
            draw.SimpleText(attackerName, "TDMRP_Body", textX, textY, attackerColor, TEXT_ALIGN_RIGHT)
            
            if kill.isNPC then
                -- NPC Kill: Show NPC type instead of weapon icon
                local iconX = textX + 50
                local iconY = textY
                
                -- Draw NPC indicator box (red)
                draw.RoundedBox(3, iconX, iconY, Config.iconSize, Config.iconSize, 
                    Color(0, 0, 0, 100 * alpha))
                surface.SetDrawColor(npcKillColor)
                surface.DrawOutlinedRect(iconX, iconY, Config.iconSize, Config.iconSize, 2)
                
                -- NPC label
                draw.SimpleText("NPC", "TDMRP_Small", iconX + 16, iconY + 10, 
                    npcKillColor, TEXT_ALIGN_CENTER)
                
                -- Victim name
                local victimX = iconX + Config.iconSize + 150
                draw.SimpleText(victimName, "TDMRP_Body", victimX, textY, 
                    Color(255, 100, 100, 255 * alpha), TEXT_ALIGN_LEFT)
            else
                -- Player Kill: Show weapon icon and name
                local iconX = textX + 50
                local iconY = textY
                
                -- Get weapon tier color
                local tierColor = GetTierColor(kill.weaponName, isCustom)
                local darkerTierColor = Color(math.max(0, tierColor.r - 40), math.max(0, tierColor.g - 40), math.max(0, tierColor.b - 40), tierColor.a)
                
                -- Draw dark background
                draw.RoundedBox(3, iconX, iconY, Config.iconSize, Config.iconSize, 
                    Color(0, 0, 0, 100 * alpha))
                
                -- Draw gradient background
                DrawGradientBox(iconX + 1, iconY + 1, Config.iconSize - 2, Config.iconSize - 2, tierColor, darkerTierColor, alpha)
                
                -- Draw glow for custom weapons
                if isCustom then
                    DrawGlowBox(iconX, iconY, Config.iconSize, Config.iconSize, customWeaponColor, 2, alpha)
                end
                
                -- Draw border
                surface.SetDrawColor(tierColor.r, tierColor.g, tierColor.b, 255 * alpha)
                surface.DrawOutlinedRect(iconX, iconY, Config.iconSize, Config.iconSize, 2)
                
                -- Draw weapon abbreviation in center
                local abbrev = GetWeaponAbbreviation(kill.weaponName)
                draw.SimpleText(abbrev, "TDMRP_BodyBold", iconX + Config.iconSize / 2, iconY + Config.iconSize / 2 - 6,
                    Color(255, 255, 255, 255 * alpha), TEXT_ALIGN_CENTER)
                
                -- Weapon name (remove 'Custom *' wrapper for non-crafted weapons)
                local displayWeaponName = kill.weaponName
                if displayWeaponName:find("Custom %*") then
                    -- Non-crafted weapon: remove the "Custom *" and just show the gun name
                    displayWeaponName = displayWeaponName:gsub("Custom %*(.*)%*", "%1")
                end
                draw.SimpleText(displayWeaponName, "TDMRP_Small", iconX + Config.iconSize + 8, 
                    iconY + 8, tierColor, TEXT_ALIGN_LEFT)
                
                -- Victim name
                local victimX = iconX + Config.iconSize + 150
                draw.SimpleText(victimName, "TDMRP_Body", victimX, textY, 
                    Color(255, 100, 100, 255 * alpha), TEXT_ALIGN_LEFT)
                
                -- Headshot indicator
                if kill.isHeadshot then
                    draw.SimpleText("HEADSHOT", "TDMRP_Tiny", victimX + 120, textY, 
                        Color(255, 0, 0, 255 * alpha), TEXT_ALIGN_LEFT)
                end
            end
            
            -- Kill streak indicator (only for player kills)
            if not kill.isNPC then
                local streakText = GetKillStreakText(kill.killStreak, kill.streakCount)
                if streakText ~= "" then
                    draw.SimpleText(streakText, "TDMRP_BodyBold", Config.posX + 50, 
                        textY - 25, streakColor, TEXT_ALIGN_CENTER)
                end
            end
        end
    end
end)

print("[TDMRP] Kill log HUD system loaded")
