----------------------------------------------------
-- TDMRP Weapon HUD
-- Sleek dark mode weapon information display
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}

----------------------------------------------------
-- Network Receiver for Bind Updates
-- Ensures bind timer data is captured immediately
----------------------------------------------------

net.Receive("TDMRP_BindUpdate", function()
    local wep = net.ReadEntity()
    local expireTime = net.ReadFloat()
    local remaining = net.ReadFloat()
    
    if IsValid(wep) then
        wep:SetNWFloat("TDMRP_BindExpire", expireTime)
        wep:SetNWFloat("TDMRP_BindRemaining", remaining)
        print(string.format("[TDMRP HUD] Received bind update for %s: %.1f sec remaining", wep:GetClass(), remaining))
    end
end)

----------------------------------------------------
-- Network Receiver for Custom Name Sync
-- Ensures custom name data is captured immediately without waiting for NWString sync
----------------------------------------------------

net.Receive("TDMRP_SyncCustomName", function()
    local wep = net.ReadEntity()
    local customName = net.ReadString()
    
    if IsValid(wep) then
        wep:SetNWString("TDMRP_CustomName", customName)
        print(string.format("[TDMRP HUD] Received custom name sync for %s: '%s'", wep:GetClass(), customName))
    end
end)

----------------------------------------------------
-- Build Full Weapon Name with Crafting/Custom
-- Returns: customName, craftedName (separately for HUD formatting)
----------------------------------------------------

local function BuildFullWeaponName(wep)
    if not IsValid(wep) then return "", "Unknown" end
    
    -- Get base weapon name
    local className = wep:GetClass()
    local baseDisplayName = className
    
    -- Try helper function first
    if TDMRP and TDMRP.GetWeaponDisplayName then
        local helperName = TDMRP.GetWeaponDisplayName(className)
        if helperName and helperName ~= "" then
            baseDisplayName = helperName
        end
    end
    
    -- Fallback to meta
    if baseDisplayName == className then
        local meta = TDMRP.GetM9KMeta and TDMRP.GetM9KMeta(className)
        if meta then
            baseDisplayName = meta.name or meta.shortName or className
        end
    end
    
    -- Get prefix/suffix IDs
    local prefixId = wep:GetNWString("TDMRP_PrefixID", "")
    local suffixId = wep:GetNWString("TDMRP_SuffixID", "")
    
    -- Build crafted name
    local craftedName = baseDisplayName
    
    if prefixId ~= "" or suffixId ~= "" then
        local prefixName = ""
        local suffixName = ""
        
        if prefixId ~= "" and TDMRP and TDMRP.Gems and TDMRP.Gems.Prefixes then
            local prefix = TDMRP.Gems.Prefixes[prefixId]
            if prefix then
                prefixName = prefix.name or prefixId
            end
        end
        
        if suffixId ~= "" and TDMRP and TDMRP.Gems and TDMRP.Gems.Suffixes then
            local suffix = TDMRP.Gems.Suffixes[suffixId]
            if suffix then
                suffixName = suffix.name or suffixId
            end
        end
        
        -- Build: "Prefix Weapon of Suffix"
        craftedName = baseDisplayName
        if prefixName ~= "" then
            craftedName = prefixName .. " " .. craftedName
        end
        if suffixName ~= "" then
            craftedName = craftedName .. " " .. suffixName
        end
    end
    
    -- Check for custom name
    -- CRITICAL: Try NWString first (normal sync), then fallback to entity property (if NWString hasn't synced yet)
    local customName = wep:GetNWString("TDMRP_CustomName", "")
    if customName == "" and wep.TDMRP_CustomName and wep.TDMRP_CustomName ~= "" then
        customName = wep.TDMRP_CustomName
    end
    
    -- DEBUG: Log when custom name is read
    if customName ~= "" then
        print(string.format("[TDMRP HUD DEBUG] BuildFullWeaponName: Found custom name '%s' (NWString='%s', Entity='%s')", 
            customName, wep:GetNWString("TDMRP_CustomName", ""), wep.TDMRP_CustomName or ""))
    end
    
    -- Return both names separately for HUD to render with different sizes
    return customName, craftedName
end

----------------------------------------------------
-- HUD Configuration
----------------------------------------------------

local Config = {
    -- Position (bottom-right)
    marginRight = 20,
    marginBottom = 20,
    
    -- Dimensions (50% larger than original)
    width = 420,
    height = 135,
    cornerRadius = 6,
    
    -- Animation
    slideSpeed = 12,
    fadeSpeed = 8,
}

----------------------------------------------------
-- State
----------------------------------------------------

local hudAlpha = 0
local hudY = 0
local lastWeapon = nil

----------------------------------------------------
-- Main HUD Drawing
----------------------------------------------------

hook.Add("HUDPaint", "TDMRP_WeaponHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then 
        hudAlpha = Lerp(FrameTime() * Config.fadeSpeed, hudAlpha, 0)
        return 
    end
    
    local wep = ply:GetActiveWeapon()
    local isValidM9K = IsValid(wep) and TDMRP.IsM9KWeapon(wep)
    
    if not isValidM9K then
        hudAlpha = Lerp(FrameTime() * Config.fadeSpeed, hudAlpha, 0)
        if hudAlpha < 1 then return end
        -- Still fading out but no valid weapon, skip drawing
        return
    else
        hudAlpha = Lerp(FrameTime() * Config.fadeSpeed, hudAlpha, 255)
    end
    
    if hudAlpha < 1 then return end
    
    -- Safety check for UI colors
    if not TDMRP.UI or not TDMRP.UI.Colors then return end
    
    local C = TDMRP.UI.Colors
    local frameTime = FrameTime()
    
    -- Get weapon data
    local className = wep:GetClass()
    local meta = TDMRP.GetM9KMeta and TDMRP.GetM9KMeta(className)
    
    -- Don't require meta for TDMRP weapons - they work without registry
    -- Allow both tdmrp_m9k_* and weapon_tdmrp_cs_* class prefixes
    if not meta and not string.StartWith(className, "tdmrp_m9k_") and not string.StartWith(className, "weapon_tdmrp_cs_") then 
        return 
    end
    
    -- Get instance data from NW vars
    local tier = wep:GetNWInt("TDMRP_Tier", 1)
    local damage = wep:GetNWInt("TDMRP_Damage", 0)
    local rpm = wep:GetNWInt("TDMRP_RPM", 0)
    local accuracy = wep:GetNWInt("TDMRP_Accuracy", 0)
    local recoil = wep:GetNWInt("TDMRP_Recoil", 0)
    local crafted = wep:GetNWBool("TDMRP_Crafted", false)
    local bindExpire = wep:GetNWFloat("TDMRP_BindExpire", 0)
    
    -- Fallback validation: if bind timer is 0, check multiple sources
    -- Priority 1: Check NWFloat "TDMRP_BindRemaining" (set by our network message)
    if bindExpire == 0 then
        local bindRemaining = wep:GetNWFloat("TDMRP_BindRemaining", 0)
        if bindRemaining > 0 then
            bindExpire = CurTime() + bindRemaining
            print(string.format("[TDMRP HUD] Fallback: Using TDMRP_BindRemaining (%.1f sec)", bindRemaining))
        end
    end
    
    -- Priority 2: If still 0 and weapon is crafted, double-check BindRemaining
    if bindExpire == 0 and crafted then
        local bindRemaining = wep:GetNWFloat("TDMRP_BindRemaining", 0)
        if bindRemaining > 0 then
            bindExpire = CurTime() + bindRemaining
            print(string.format("[TDMRP HUD] Crafted weapon fallback: %.1f sec remaining", bindRemaining))
        end
    end
    
    -- Get gem counts from NWInts
    local gemSapphire = wep:GetNWInt("TDMRP_Gem_Sapphire", 0)
    local gemEmerald = wep:GetNWInt("TDMRP_Gem_Emerald", 0)
    local gemRuby = wep:GetNWInt("TDMRP_Gem_Ruby", 0)
    local gemDiamond = wep:GetNWInt("TDMRP_Gem_Diamond", 0)
    
    -- If no NW data yet, use base stats
    if damage == 0 then
        if meta and meta.baseDamage then
            damage = meta.baseDamage
            rpm = meta.baseRPM or 600
        else
            damage = 25
            rpm = 600
        end
        if accuracy == 0 then
            accuracy = 70
        end
    end
    
    -- Ammo info
    local clip = wep:Clip1()
    local maxClip = wep:GetMaxClip1()
    local reserve = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
    
    -- Position
    local w = Config.width
    local h = Config.height
    local x = ScrW() - w - Config.marginRight
    local targetY = ScrH() - h - Config.marginBottom
    
    -- Slide animation
    local startY = ScrH() + 20
    hudY = Lerp(frameTime * Config.slideSpeed, hudY, targetY)
    local y = hudY
    
    -- Alpha for all drawing
    local alpha = math.floor(hudAlpha)
    
    -- Slug mode indicator (top-left corner)
    local isSlugEnabled = wep.IsSlugEnabled and wep:IsSlugEnabled() or TDMRP_WeaponMixin.IsSlugEnabled(wep)
    if isSlugEnabled then
        local mode = wep:GetNWInt("TDMRP_ShotgunMode", 0)
        local modeText = mode == 1 and "SLUG MODE" or "BUCKSHOT MODE"
        local modeColor = mode == 1 and Color(255, 140, 0, alpha) or Color(150, 150, 150, alpha)  -- Orange for slug, gray for buckshot
        
        -- Position floating above the HUD's top-left corner (just outside the border)
        surface.SetFont("TDMRP_HUD_Small")
        local textW, textH = surface.GetTextSize(modeText)

        -- Place the pill roughly where the user indicated (right of the left accent bar)
        -- Use HUD-relative offsets so it stays aligned across resolutions
        local modeX = x + 10 + 3  -- 10px inside the HUD plus small gap from the accent bar
        local modeY = y - (textH + 12)

        -- Clamp to screen bounds so it can't go off-screen
        modeX = math.max(8, modeX)
        modeY = math.max(8, modeY)

        -- Background pill
        draw.RoundedBox(6, modeX - 10, modeY - 4, textW + 20, textH + 8, ColorAlpha(C.bg_dark, alpha * 0.8))

        -- Text
        draw.SimpleText(modeText, "TDMRP_HUD_Small", modeX, modeY, modeColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Main background
    draw.RoundedBox(Config.cornerRadius, x, y, w, h, ColorAlpha(C.bg_dark, alpha))
    
    -- Left accent bar
    surface.SetDrawColor(ColorAlpha(C.accent, alpha))
    surface.DrawRect(x, y + 4, 3, h - 8)
    
    -- Top section: Weapon name and tier
    local nameY = y + 12
    local tierColor = C.tier[tier] or C.tier[1]
    
    -- Build full weapon name (prefix + base + suffix + custom)
    local customName, craftedName = BuildFullWeaponName(wep)
    
    -- DEBUG: Log every time we build the name
    if isValidM9K and wep ~= lastWeapon then
        print(string.format("[TDMRP HUD DEBUG] PaintHUD weapon changed: customName='%s', craftedName='%s'", customName, craftedName))
    end
    
    -- Draw weapon name with smart sizing
    if customName ~= "" then
        -- Custom name: smaller, brighter color
        local customColor = Color(200, 255, 100)  -- Yellow-green for custom names
        draw.SimpleText("*" .. customName .. "*", "TDMRP_HUD_Large", x + 20, nameY, ColorAlpha(customColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        -- Crafted name below: much smaller, muted
        if craftedName ~= "" then
            surface.SetFont("TDMRP_HUD_Small")
            local customW = surface.GetTextSize("*" .. customName .. "*")
            draw.SimpleText("(" .. craftedName .. ")", "TDMRP_HUD_Small", x + 20, nameY + 18, ColorAlpha(C.text_muted, alpha * 0.6), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    else
        -- Just crafted name: normal size
        draw.SimpleText(craftedName, "TDMRP_HUD_Large", x + 20, nameY, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Bind status (right of weapon name)
    surface.SetFont("TDMRP_HUD_Large")
    local displayNameForWidth = customName ~= "" and ("*" .. customName .. "*") or craftedName
    local nameW, _ = surface.GetTextSize(displayNameForWidth)
    local bindX = x + 20 + nameW + 10
    
    local bindRemaining = bindExpire > 0 and (bindExpire - CurTime()) or 0
    
    -- DEBUG: Log bind values on weapon change
    if isValidM9K and wep ~= lastWeapon then
        print(string.format("[TDMRP HUD DEBUG] Weapon changed to %s: bindExpire=%.1f, bindRemaining=%.1f, crafted=%s", 
            wep:GetClass(), bindExpire, bindRemaining, tostring(crafted)))
        lastWeapon = wep
    end
    
    if bindRemaining > 0 then
        -- Bound with timer - purple "Bound" + yellow timer
        local amethystColor = Color(180, 80, 255)  -- Purple/Amethyst
        local timerColor = Color(255, 220, 100)    -- Yellow
        
        local mins = math.floor(bindRemaining / 60)
        local secs = math.floor(bindRemaining % 60)
        local timeStr = string.format("%02d:%02d", mins, secs)
        
        draw.SimpleText("Bound", "TDMRP_HUD_Small", bindX, nameY + 2, ColorAlpha(amethystColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        surface.SetFont("TDMRP_HUD_Small")
        local boundW, _ = surface.GetTextSize("Bound")
        draw.SimpleText(timeStr, "TDMRP_HUD_Small", bindX + boundW + 5, nameY + 2, ColorAlpha(timerColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        -- Unbound - gray text
        draw.SimpleText("Unbound", "TDMRP_HUD_Small", bindX, nameY + 2, ColorAlpha(C.text_muted, alpha * 0.7), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Tier badge with rarity name
    local tierNames = {
        [1] = "COMMON",
        [2] = "UNCOMMON", 
        [3] = "RARE",
        [4] = "LEGENDARY",
        [5] = "UNIQUE"
    }
    local tierText = tierNames[tier] or "COMMON"
    
    -- For unique tier (5), create rainbow effect
    local displayColor = tierColor
    if tier == 5 then
        local hue = (CurTime() * 100) % 360
        displayColor = HSVToColor(hue, 0.8, 1)
    end
    
    surface.SetFont("TDMRP_HUD_Small")
    local tierW, tierH = surface.GetTextSize(tierText)
    local tierBadgeX = x + w - tierW - 20
    local tierBadgeY = nameY
    
    -- Tier background pill
    draw.RoundedBox(8, tierBadgeX - 8, tierBadgeY - 2, tierW + 16, 20, ColorAlpha(displayColor, alpha * 0.25))
    draw.SimpleText(tierText, "TDMRP_HUD_Small", tierBadgeX, tierBadgeY, ColorAlpha(displayColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Crafted star
    if crafted then
        draw.SimpleText("★", "TDMRP_HUD_Medium", tierBadgeX - 20, tierBadgeY - 2, ColorAlpha(C.warning, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    
    -- Separator
    surface.SetDrawColor(ColorAlpha(C.border_dark, alpha))
    surface.DrawRect(x + 15, y + 48, w - 30, 1)
    
    -- Stats row
    local statsY = y + 60
    local statSpacing = (w - 30) / 3
    
    -- Damage (special handling for shotguns to show pellet count)
    local dmgX = x + 20
    draw.SimpleText("DMG", "TDMRP_Tiny", dmgX, statsY, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Check if shotgun
    local isShotgun = TDMRP.Accuracy and TDMRP.Accuracy.GetWeaponType and TDMRP.Accuracy.GetWeaponType(wep) == "shotgun"
    local damageDisplay = tostring(damage)
    
    -- Check for Chrome suffix - displays % HP instead of flat damage
    local suffixId = wep:GetNWString("TDMRP_SuffixID", "")
    local isChrome = suffixId == "of_Chrome"
    
    if isChrome then
        -- Chrome damage display: damage / 2 = % HP with tier scaling
        local chromePercent = damage / 2
        
        -- Apply tier scaling
        local chromeTierScaling = {
            [1] = 0.90, [2] = 0.95, [3] = 1.00, [4] = 1.10, [5] = 1.15
        }
        local tierMult = chromeTierScaling[tier] or 1.0
        chromePercent = chromePercent * tierMult
        
        if isShotgun and wep.Primary and wep.Primary.NumShots then
            local numPellets = wep.Primary.NumShots
            local mode = wep:GetNWInt("TDMRP_ShotgunMode", 0)
            if mode == 1 then
                -- Slug mode: single projectile, show total % HP
                local slugDamage = damage * numPellets  -- Slug uses combined damage
                local slugPercent = math.Round((slugDamage / 2) * tierMult)
                damageDisplay = slugPercent .. "% HP"
            else
                -- Buckshot: show per-pellet % and total
                local perPelletPercent = math.Round(chromePercent)
                local totalPercent = math.Round(chromePercent * numPellets)
                damageDisplay = perPelletPercent .. "%x" .. numPellets .. "=" .. totalPercent .. "% HP"
            end
        else
            -- Non-shotgun: simple % HP display
            damageDisplay = math.Round(chromePercent) .. "% HP"
        end
    elseif isShotgun and wep.Primary and wep.Primary.NumShots then
        local numPellets = wep.Primary.NumShots
        local totalDamage = damage * numPellets
        local mode = wep:GetNWInt("TDMRP_ShotgunMode", 0)
        if mode == 1 then
            -- Slug mode: show only total damage
            damageDisplay = tostring(totalDamage)
        else
            -- Buckshot: show per-pellet and total
            damageDisplay = damage .. "x" .. numPellets .. "=" .. totalDamage
        end
    end
    
    -- Add doubleshot indicator if applicable (not for Chrome)
    if suffixId == "of_Doubleshot" and not isChrome then
        damageDisplay = damageDisplay .. " ×2"  -- Show 2x indicator for doubleshot
    end
    
    draw.SimpleText(damageDisplay, "TDMRP_HUD_Medium", dmgX, statsY + 14, ColorAlpha(C.accent, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- RPM
    local rpmX = x + 20 + statSpacing
    draw.SimpleText("RPM", "TDMRP_Tiny", rpmX, statsY, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(tostring(rpm), "TDMRP_HUD_Medium", rpmX, statsY + 14, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Accuracy
    local accX = x + 20 + statSpacing * 2
    draw.SimpleText("ACC", "TDMRP_Tiny", accX, statsY, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(math.floor(accuracy) .. "%", "TDMRP_HUD_Medium", accX, statsY + 14, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    
    -- Gem indicators (below stats)
    local gemY = statsY + 40
    local gemX = x + 20
    local hasGems = false
    
    if gemSapphire > 0 then
        draw.RoundedBox(2, gemX, gemY, 10, 10, ColorAlpha(Color(100, 150, 255), alpha))
        draw.SimpleText("x" .. gemSapphire, "TDMRP_Tiny", gemX + 14, gemY, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        gemX = gemX + 35
        hasGems = true
    end
    if gemEmerald > 0 then
        draw.RoundedBox(2, gemX, gemY, 10, 10, ColorAlpha(Color(80, 255, 120), alpha))
        draw.SimpleText("x" .. gemEmerald, "TDMRP_Tiny", gemX + 14, gemY, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        gemX = gemX + 35
        hasGems = true
    end
    if gemRuby > 0 then
        draw.RoundedBox(2, gemX, gemY, 10, 10, ColorAlpha(Color(255, 80, 80), alpha))
        draw.SimpleText("x" .. gemRuby, "TDMRP_Tiny", gemX + 14, gemY, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        gemX = gemX + 35
        hasGems = true
    end
    if gemDiamond > 0 then
        draw.RoundedBox(2, gemX, gemY, 10, 10, ColorAlpha(Color(200, 230, 255), alpha))
        draw.SimpleText("x" .. gemDiamond, "TDMRP_Tiny", gemX + 14, gemY, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        hasGems = true
    end
    
    -- Ammo bar section
    local ammoY = y + h - 28
    local ammoBarX = x + 20
    local ammoBarW = w - 120
    local ammoBarH = 8
    
    -- Ammo bar background
    draw.RoundedBox(2, ammoBarX, ammoY, ammoBarW, ammoBarH, ColorAlpha(C.bg_input, alpha))
    
    -- Ammo bar fill
    if maxClip > 0 then
        local ammoPercent = clip / maxClip
        local fillW = math.max(2, ammoBarW * ammoPercent)
        
        -- Color based on ammo level
        local ammoColor = C.accent
        if ammoPercent <= 0.2 then
            ammoColor = C.error
        elseif ammoPercent <= 0.4 then
            ammoColor = C.warning
        end
        
        draw.RoundedBox(2, ammoBarX, ammoY, fillW, ammoBarH, ColorAlpha(ammoColor, alpha))
    end
    
    -- Ammo text
    local ammoText = clip .. "/" .. reserve
    draw.SimpleText(ammoText, "TDMRP_HUD_Small", x + w - 14, ammoY + 3, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    
    -- Note: Gem indicators already shown above, this old code removed
end)

----------------------------------------------------
-- Hide default HL2 ammo display for M9K weapons
----------------------------------------------------

hook.Add("HUDShouldDraw", "TDMRP_HideAmmo", function(name)
    if name == "CHudAmmo" or name == "CHudSecondaryAmmo" then
        local ply = LocalPlayer()
        if IsValid(ply) then
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and TDMRP.IsM9KWeapon(wep) then
                return false
            end
        end
    end
end)

print("[TDMRP] cl_tdmrp_weaponhud.lua loaded - Weapon HUD initialized")
