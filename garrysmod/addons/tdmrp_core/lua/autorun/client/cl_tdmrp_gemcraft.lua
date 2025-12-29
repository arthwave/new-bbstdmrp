-- cl_tdmrp_gemcraft.lua
-- Client-side gem crafting UI

if not CLIENT then return end

TDMRP = TDMRP or {}
TDMRP.GemUI = TDMRP.GemUI or {}

-- Receive bind timer updates from server
net.Receive("TDMRP_BindUpdate", function()
    local wep = net.ReadEntity()
    local expireTime = net.ReadFloat()
    local remaining = net.ReadFloat()  -- New: read remaining time
    
    if IsValid(wep) then
        wep:SetNWFloat("TDMRP_BindExpire", expireTime)
        wep:SetNWFloat("TDMRP_BindRemaining", remaining)  -- New: store remaining
        print(string.format("[TDMRP] Client received bind update: %.1f seconds remaining (expire at CurTime %.1f)", remaining, expireTime - CurTime()))
    end
end)

local UI = TDMRP.GemUI

----------------------------------------------------
-- Globals for current crafting session
----------------------------------------------------
UI.CurrentWeapon = nil
UI.SelectedPrefix = nil
UI.SelectedMaterial = nil
UI.CustomName = ""
UI.CraftPanel = nil
UI.CachedInventory = {}  -- Cache of inventory items for gem counts

----------------------------------------------------
-- Helper: get gem inventory counts
----------------------------------------------------
local function GetGemCount(gemID)
    local total = 0
    
    if not UI.CachedInventory then 
        return 0 
    end
    
    -- CachedInventory is the items array directly (from net.ReadTable)
    for idx, item in pairs(UI.CachedInventory) do
        if item and item.kind == "gem" and item.gem == gemID then
            total = total + (item.amount or 1)
        end
    end
    
    return total
end

----------------------------------------------------
-- Get player's money
----------------------------------------------------
local function GetPlayerMoney()
    local ply = LocalPlayer()
    if ply.DarkRPVars and ply.DarkRPVars.money then
        return ply.DarkRPVars.money
    end
    return 0
end

----------------------------------------------------
-- Calculate craft cost based on weapon tier
----------------------------------------------------
local function GetCraftCost(tier)
    tier = tier or 1
    local tierCosts = {
        [1] = 5000,     -- Common
        [2] = 7500,     -- Uncommon
        [3] = 10000,    -- Rare
        [4] = 15000,    -- Epic
        [5] = 25000,    -- Legendary
    }
    return tierCosts[tier] or 5000
end

----------------------------------------------------
-- Get prefix table (all prefixes, not tier-filtered)
----------------------------------------------------
local function GetPrefixesForTier(tier)
    if not TDMRP then 
        print("[TDMRP GemCraft] ERROR: TDMRP table not loaded!")
        return {} 
    end
    if not TDMRP.Gems then 
        print("[TDMRP GemCraft] ERROR: TDMRP.Gems table not loaded!")
        return {} 
    end
    if not TDMRP.Gems.Prefixes then 
        print("[TDMRP GemCraft] ERROR: TDMRP.Gems.Prefixes table not loaded!")
        return {} 
    end
    
    -- All prefixes are shared across tiers now
    local prefixes = {}
    local totalCount = 0
    
    for id, pref in pairs(TDMRP.Gems.Prefixes) do
        totalCount = totalCount + 1
        prefixes[id] = pref
    end
    
    print("[TDMRP GemCraft] GetPrefixesForTier(" .. tier .. "): loaded " .. totalCount .. " prefixes")
    if totalCount == 0 then
        print("[TDMRP GemCraft] WARNING: TDMRP.Gems.Prefixes is empty!")
        print("[TDMRP GemCraft] Keys in Prefixes table:", next(TDMRP.Gems.Prefixes))
    end
    return prefixes
end

----------------------------------------------------
-- Get suffix table for selected tier
----------------------------------------------------
local function GetSuffixesForTier(tier)
    if not TDMRP or not TDMRP.Gems or not TDMRP.Gems.Suffixes then return {} end
    
    -- Return all suffixes (no tier filtering)
    local suffixes = {}
    local totalCount = 0
    
    for id, suf in pairs(TDMRP.Gems.Suffixes) do
        totalCount = totalCount + 1
        suffixes[id] = suf
    end
    
    print("[TDMRP GemCraft] GetSuffixesForTier(" .. tier .. "): returning all " .. totalCount .. " suffixes")
    return suffixes
end

----------------------------------------------------
-- Calculate stat preview with prefix modifiers
----------------------------------------------------
local function CalcPrefixModifiedStats(weapon, prefixID)
    if not TDMRP or not TDMRP.Gems or not TDMRP.Gems.Prefixes then
        return nil
    end
    
    local pref = TDMRP.Gems.Prefixes[prefixID]
    if not pref or not pref.stats then return nil end
    
    local dmg = weapon:GetNWInt("TDMRP_Damage", 0)
    local rpm = weapon:GetNWInt("TDMRP_RPM", 0)
    local acc = weapon:GetNWInt("TDMRP_Accuracy", 0)
    local rec = weapon:GetNWInt("TDMRP_Recoil", 0)
    local han = weapon:GetNWInt("TDMRP_Handling", 0)
    
    local s = pref.stats
    
    if s.damage then dmg = math.floor(dmg * (1 + s.damage)) end
    if s.rpm then rpm = math.floor(rpm * (1 + s.rpm)) end
    if s.accuracy then acc = math.floor(acc * (1 + s.accuracy)) end
    if s.recoil then rec = math.floor(rec * (1 + s.recoil)) end
    if s.handling then han = math.floor(han * (1 + s.handling)) end
    
    acc = math.Clamp(acc, 0, 95)
    rec = math.max(rec, 5)
    han = math.Clamp(han, 0, 250)
    
    return {
        damage = dmg,
        rpm = rpm,
        accuracy = acc,
        recoil = rec,
        handling = han,
    }
end

----------------------------------------------------
-- Main Crafting Panel
----------------------------------------------------
function UI.OpenCraftingMenu(weapon)
    if not IsValid(weapon) or not weapon:IsWeapon() then
        chat.AddText(Color(255, 0, 0), "[TDMRP] No valid weapon selected.")
        return
    end
    
    if TDMRP.IsM9KWeapon and not TDMRP.IsM9KWeapon(weapon) then
        chat.AddText(Color(255, 0, 0), "[TDMRP] This weapon cannot be modified.")
        return
    end
    
    UI.CurrentWeapon = weapon
    UI.SelectedPrefix = nil
    UI.SelectedMaterial = "standard"
    UI.CustomName = ""
    
    if IsValid(UI.CraftPanel) then
        UI.CraftPanel:Remove()
    end
    
    -- Request fresh inventory data FIRST
    print("[TDMRP GemCraft] Requesting inventory from server...")
    UI.InventoryReceived = false  -- Flag to track if we got the data
    net.Start("TDMRP_Inventory_Request")
    net.SendToServer()
    print("[TDMRP GemCraft] Inventory request sent")
    
    -- Wait for inventory to actually arrive, with timeout fallback
    local startTime = CurTime()
    local function WaitForInventory()
        if UI.InventoryReceived then
            print("[TDMRP GemCraft] Inventory received, opening UI")
            OpenCraftingMenuDeferred(weapon)
            return
        end
        
        if CurTime() - startTime > 2 then  -- 2 second timeout
            print("[TDMRP GemCraft] Inventory timeout, opening UI anyway")
            OpenCraftingMenuDeferred(weapon)
            return
        end
        
        -- Try again next frame
        timer.Simple(0.01, WaitForInventory)
    end
    
    WaitForInventory()
end

function OpenCraftingMenuDeferred(weapon)
    if not IsValid(weapon) then return end
    
    if IsValid(UI.CraftPanel) then
        UI.CraftPanel:Remove()
    end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(1100, 850)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    
    -- Custom frame paint
    function frame:Paint(w, h)
        -- Main background - dark with slight blue tint
        draw.RoundedBox(16, 0, 0, w, h, Color(20, 25, 35, 250))
        
        -- Title bar gradient
        draw.RoundedBoxEx(16, 0, 0, w, 50, Color(40, 60, 100, 255), true, true, false, false)
        draw.RoundedBoxEx(16, 0, 0, w, 25, Color(60, 90, 140, 150), true, true, false, false)
        
        -- Outer glow border
        surface.SetDrawColor(100, 150, 255, 80)
        draw.RoundedBox(16, -2, -2, w + 4, h + 4, Color(0, 0, 0, 0))
        surface.DrawOutlinedRect(0, 0, w, h, 2)
        
        -- Title text with shadow
        draw.SimpleText("GEM CRAFTER", "DermaLarge", w / 2 + 2, 27, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("GEM CRAFTER", "DermaLarge", w / 2, 25, Color(150, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Custom close button
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetPos(frame:GetWide() - 45, 10)
    closeBtn:SetSize(35, 35)
    closeBtn:SetText("")
    closeBtn.isHovered = false
    
    function closeBtn:Paint(w, h)
        local col = self.isHovered and Color(255, 80, 80) or Color(180, 50, 50)
        draw.RoundedBox(6, 0, 0, w, h, col)
        
        -- Draw X
        surface.SetDrawColor(255, 255, 255)
        surface.DrawLine(10, 10, w - 10, h - 10)
        surface.DrawLine(w - 10, 10, 10, h - 10)
        
        return false
    end
    
    function closeBtn:OnCursorEntered()
        self.isHovered = true
        surface.PlaySound("buttons/lightswitch2.wav")
    end
    
    function closeBtn:OnCursorExited()
        self.isHovered = false
    end
    
    function closeBtn:DoClick()
        surface.PlaySound("buttons/button15.wav")
        frame:Close()
    end
    
    local weaponTier = weapon:GetNWInt("TDMRP_Tier", 1)
    local weaponClass = weapon:GetClass()
    local isCrafted = weapon:GetNWBool("TDMRP_Crafted", false)
    
    print("[TDMRP GemCraft] OpenCraftingMenu: weaponTier=" .. weaponTier .. ", class=" .. weaponClass .. ", crafted=" .. tostring(isCrafted))
    
    -- Branch based on whether weapon is already crafted
    if isCrafted then
        -- Show upgrade UI (diamond/ruby/amethyst options)
        BuildUpgradeUI(frame, weapon, weaponTier)
    else
        -- Show initial craft UI (prefix/suffix selection)
        BuildCraftUI(frame, weapon, weaponTier)
    end
    
    frame:MakePopup()
    UI.CraftPanel = frame
end

----------------------------------------------------
-- Initial Craft UI (prefix + suffix selection)
----------------------------------------------------
function BuildCraftUI(frame, weapon, weaponTier)
    print("[TDMRP GemCraft] TDMRP.Gems exists:", TDMRP.Gems and "yes" or "no")
    print("[TDMRP GemCraft] TDMRP.Gems.Prefixes count:", TDMRP.Gems and TDMRP.Gems.Prefixes and table.Count(TDMRP.Gems.Prefixes) or "nil")
    
    -------- Top section: weapon preview --------
    local topPanel = vgui.Create("DPanel", frame)
    topPanel:Dock(TOP)
    topPanel:DockMargin(0, 5, 0, 0)
    topPanel:SetHeight(200)
    
    function topPanel:Paint(w, h)
        draw.RoundedBox(8, 5, 5, w - 10, h - 10, Color(30, 35, 45, 200))
        surface.SetDrawColor(80, 120, 180, 100)
        surface.DrawOutlinedRect(5, 5, w - 10, h - 10, 1)
    end
    
    local weaponModel = vgui.Create("DModelPanel", topPanel)
    weaponModel:Dock(LEFT)
    weaponModel:SetWidth(200)
    weaponModel:SetModel(weapon:GetModel())
    
    -- Center the camera on the model
    local mn, mx = weaponModel.Entity:GetRenderBounds()
    local size = 0
    size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
    size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
    size = math.max(size, math.abs(mn.z) + math.abs(mx.z))
    size = size * 0.5  -- Zoom in 200%
    weaponModel:SetCamPos(Vector(size, size, size))
    weaponModel:SetLookAt((mn + mx) * 0.5)
    
    -- Auto-rotate animation
    weaponModel.Entity:SetAngles(Angle(0, CurTime() * 50 % 360, 0))
    function weaponModel:OnCursorEntered()
        self.Rotating = true
    end
    function weaponModel:OnCursorExited()
        self.Rotating = false
    end
    function weaponModel:LayoutEntity(ent)
        if self.Rotating then
            ent:SetAngles(Angle(0, CurTime() * 100 % 360, 0))
        else
            ent:SetAngles(Angle(0, CurTime() * 30 % 360, 0))
        end
    end
    
    local infoPanel = vgui.Create("DPanel", topPanel)
    infoPanel:Dock(FILL)
    infoPanel:DockMargin(5, 0, 5, 5)
    
    -- Custom paint for info panel with embellished styling
    function infoPanel:Paint(w, h)
        -- Dark background with slight transparency
        draw.RoundedBox(8, 0, 0, w, h, Color(15, 20, 30, 240))
        
        -- Inner border with glow
        surface.SetDrawColor(120, 160, 220, 120)
        surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 1)
        
        -- Corner accents
        local accentColor = Color(150, 200, 255, 180)
        surface.SetDrawColor(accentColor.r, accentColor.g, accentColor.b, accentColor.a)
        -- Top left corner
        surface.DrawLine(5, 5, 25, 5)
        surface.DrawLine(5, 5, 5, 25)
        -- Top right corner
        surface.DrawLine(w - 25, 5, w - 5, 5)
        surface.DrawLine(w - 5, 5, w - 5, 25)
        -- Bottom left corner
        surface.DrawLine(5, h - 25, 5, h - 5)
        surface.DrawLine(5, h - 5, 25, h - 5)
        -- Bottom right corner
        surface.DrawLine(w - 5, h - 25, w - 5, h - 5)
        surface.DrawLine(w - 25, h - 5, w - 5, h - 5)
        
        return true
    end
    
    local infoLabel = vgui.Create("DLabel", infoPanel)
    infoLabel:Dock(FILL)
    infoLabel:DockMargin(15, 10, 15, 10)
    infoLabel:SetWrap(true)
    infoLabel:SetFont("DermaDefault")
    infoLabel:SetTextColor(Color(200, 220, 255))
    
    local weaponName = weapon.PrintName or weapon:GetClass() or "Unknown Weapon"
    local tierName = TDMRP.TierNames and TDMRP.TierNames[weaponTier] or ("Tier " .. weaponTier)
    
    -- Custom paint for the label with rich text styling
    function infoLabel:Paint(w, h)
        local yPos = 5
        local lineHeight = 18
        
        -- Weapon name (larger, emphasized)
        draw.SimpleText("WEAPON:", "DermaDefaultBold", 2, yPos + 1, Color(0, 0, 0, 150))
        draw.SimpleText("WEAPON:", "DermaDefaultBold", 1, yPos, Color(120, 180, 255))
        draw.SimpleText(weaponName, "DermaLarge", 90, yPos - 2 + 1, Color(0, 0, 0, 150))
        draw.SimpleText(weaponName, "DermaLarge", 89, yPos - 2, Color(200, 230, 255))
        
        yPos = yPos + lineHeight + 5
        
        -- Tier (highlighted)
        draw.SimpleText("TIER:", "DermaDefaultBold", 2, yPos + 1, Color(0, 0, 0, 150))
        draw.SimpleText("TIER:", "DermaDefaultBold", 1, yPos, Color(120, 180, 255))
        
        local tierColor = Color(100, 200, 100)  -- Default green
        if weaponTier >= 3 then tierColor = Color(255, 200, 100) end  -- Orange for higher tiers
        if weaponTier >= 5 then tierColor = Color(255, 100, 255) end  -- Purple for top tier
        
        draw.SimpleText(tierName, "DermaDefaultBold", 60, yPos + 1, Color(0, 0, 0, 150))
        draw.SimpleText(tierName, "DermaDefaultBold", 59, yPos, tierColor)
        
        yPos = yPos + lineHeight
        
        -- Craft cost
        local cost = GetCraftCost(weaponTier)
        draw.SimpleText("CRAFT COST:", "DermaDefaultBold", 2, yPos + 1, Color(0, 0, 0, 150))
        draw.SimpleText("CRAFT COST:", "DermaDefaultBold", 1, yPos, Color(120, 180, 255))
        draw.SimpleText("$" .. cost, "DermaDefaultBold", 120, yPos + 1, Color(0, 0, 0, 150))
        draw.SimpleText("$" .. cost, "DermaDefaultBold", 119, yPos, Color(255, 215, 0))
        
        yPos = yPos + lineHeight + 8
        
        -- Separator line
        surface.SetDrawColor(80, 120, 180, 100)
        surface.DrawLine(10, yPos, w - 10, yPos)
        
        yPos = yPos + 8
        
        -- Base Stats header
        draw.SimpleText("BASE STATS", "DermaDefaultBold", w / 2 + 1, yPos + 1, Color(0, 0, 0, 200))
        draw.SimpleText("BASE STATS", "DermaDefaultBold", w / 2, yPos, Color(150, 200, 255))
        
        yPos = yPos + lineHeight + 2
        
        -- Stats in styled format
        local stats = {
            {label = "DMG", value = weapon:GetNWInt("TDMRP_Damage", 0), color = Color(255, 100, 100)},
            {label = "RPM", value = weapon:GetNWInt("TDMRP_RPM", 0), color = Color(255, 200, 100)},
            {label = "ACC", value = weapon:GetNWInt("TDMRP_Accuracy", 0), color = Color(100, 255, 200)},
            {label = "REC", value = weapon:GetNWInt("TDMRP_Recoil", 0), color = Color(200, 100, 255)},
            {label = "HAN", value = weapon:GetNWInt("TDMRP_Handling", 0), color = Color(100, 200, 255)}
        }
        
        local xPos = 10
        for i, stat in ipairs(stats) do
            -- Stat label
            draw.SimpleText(stat.label .. ":", "DermaDefault", xPos + 1, yPos + 1, Color(0, 0, 0, 150))
            draw.SimpleText(stat.label .. ":", "DermaDefault", xPos, yPos, Color(180, 200, 220))
            
            -- Stat value
            draw.SimpleText(tostring(stat.value), "DermaDefaultBold", xPos + 42 + 1, yPos + 1, Color(0, 0, 0, 150))
            draw.SimpleText(tostring(stat.value), "DermaDefaultBold", xPos + 42, yPos, stat.color)
            
            xPos = xPos + 90
            
            -- Draw separator between stats
            if i < #stats then
                surface.SetDrawColor(60, 80, 120, 80)
                surface.DrawLine(xPos - 10, yPos - 2, xPos - 10, yPos + 12)
            end
        end
        
        return true
    end
    
    -------- Middle section: prefix selection --------
    local midPanel = vgui.Create("DPanel", frame)
    midPanel:Dock(TOP)
    midPanel:SetHeight(200)
    
    function midPanel:Paint(w, h)
        draw.RoundedBox(8, 5, 5, w - 10, h - 10, Color(30, 35, 45, 200))
        surface.SetDrawColor(80, 180, 120, 100)
        surface.DrawOutlinedRect(5, 5, w - 10, h - 10, 1)
    end
    
    local prefixLabel = vgui.Create("DLabel", midPanel)
    prefixLabel:Dock(TOP)
    prefixLabel:DockMargin(0, 5, 0, 0)
    prefixLabel:SetHeight(35)
    prefixLabel:SetFont("DermaLarge")
    prefixLabel:SetText("")
    prefixLabel:SetContentAlignment(5)
    
    function prefixLabel:Paint(w, h)
        -- Shadow
        draw.SimpleText("SELECT EMERALD PREFIX (STAT MODIFIER)", "DermaLarge", w / 2 + 1, h / 2 + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        -- Main text with green glow
        draw.SimpleText("SELECT EMERALD PREFIX (STAT MODIFIER)", "DermaLarge", w / 2, h / 2, Color(100, 255, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    local prefixScroll = vgui.Create("DScrollPanel", midPanel)
    prefixScroll:Dock(FILL)
    
    local prefixes = GetPrefixesForTier(weaponTier)
    print("[TDMRP GemCraft] Creating prefix buttons, tier=" .. weaponTier .. ", count=" .. table.Count(prefixes))
    
    if table.Count(prefixes) == 0 then
        local emptyLabel = vgui.Create("DLabel", prefixScroll)
        emptyLabel:Dock(TOP)
        emptyLabel:SetHeight(50)
        emptyLabel:SetText("ERROR: No prefixes loaded! Check console for details.")
        emptyLabel:SetTextColor(Color(255, 0, 0))
        return
    end
    
    -- Store all prefix buttons so DoClick can access them
    local prefixButtons = {}
    
    for prefixID, prefixData in SortedPairs(prefixes) do
        print("[TDMRP GemCraft] Creating button for prefix: " .. tostring(prefixID))
        local btn = vgui.Create("DButton", prefixScroll)
        
        if not btn then
            print("[TDMRP GemCraft] ERROR: Failed to create button!")
            continue
        end
        
        print("[TDMRP GemCraft] Button created successfully: " .. tostring(btn))
        
        if not IsValid(btn) then
            print("[TDMRP GemCraft] ERROR: Button is not valid after creation!")
            continue
        end
        
        btn:SetHeight(30)
        btn:Dock(TOP)
        btn:SetText("")
        btn:SetCursor("hand")
        
        local btnLabel = vgui.Create("DLabel", btn)
        if not IsValid(btnLabel) then
            print("[TDMRP GemCraft] ERROR: Failed to create button label!")
            continue
        end
        
        btnLabel:Dock(FILL)
        btnLabel:SetFont("DermaDefault")
        btnLabel:SetWrap(true)
        
        local modDesc = ""
        if prefixData.stats then
            local s = prefixData.stats
            local parts = {}
            if s.damage then table.insert(parts, string.format("DMG: %+d%%", math.floor(s.damage * 100))) end
            if s.rpm then table.insert(parts, string.format("RPM: %+d%%", math.floor(s.rpm * 100))) end
            if s.accuracy then table.insert(parts, string.format("ACC: %+d%%", math.floor(s.accuracy * 100))) end
            if s.recoil then table.insert(parts, string.format("REC: %+d%%", math.floor(s.recoil * 100))) end
            if s.handling then table.insert(parts, string.format("HAN: %+d%%", math.floor(s.handling * 100))) end
            modDesc = table.concat(parts, " | ")
        end
        
        btnLabel:SetText(string.format("%s: %s", prefixData.name or prefixID, modDesc))
        btnLabel:SetTextColor(Color(200, 220, 255))  -- Light blue text by default
        btnLabel:SetContentAlignment(4)  -- Left align
        
        -- Store prefix ID and styling state for click handling
        btn.prefixID = prefixID
        btn.bgColor = Color(40, 50, 70)  -- Dark blue-gray default
        btn.isHovered = false
        
        -- Override Paint to use custom background color with effects
        function btn:Paint(w, h)
            local baseColor = self.bgColor or Color(40, 50, 70)
            
            -- Hover brightness boost
            if self.isHovered then
                baseColor = Color(baseColor.r + 20, baseColor.g + 20, baseColor.b + 20)
            end
            
            -- Draw background with rounded corners
            draw.RoundedBox(6, 2, 1, w - 4, h - 2, baseColor)
            
            -- Shine effect on top half
            draw.RoundedBoxEx(6, 2, 1, w - 4, (h - 2) / 2, Color(255, 255, 255, 15), true, true, false, false)
            
            -- Border
            surface.SetDrawColor(100, 150, 200, 100)
            surface.DrawOutlinedRect(2, 1, w - 4, h - 2, 1)
            
            return false  -- Don't call default paint
        end
        
        function btn:OnCursorEntered()
            self.isHovered = true
            surface.PlaySound("buttons/lightswitch2.wav")
        end
        
        function btn:OnCursorExited()
            self.isHovered = false
        end
        
        -- Add to buttons table
        table.insert(prefixButtons, btn)
        
        function btn:DoClick()
            UI.SelectedPrefix = self.prefixID
            surface.PlaySound("buttons/button14.wav")  -- Click sound
            print("[TDMRP GemCraft] Selected prefix: " .. tostring(self.prefixID))
            
            -- Update all prefix buttons using our stored table
            print("[TDMRP GemCraft] Updating " .. #prefixButtons .. " buttons")
            
            for i, child in pairs(prefixButtons) do
                if IsValid(child) and child.prefixID then
                    if UI.SelectedPrefix == child.prefixID then
                        child.bgColor = Color(80, 180, 120)  -- Bright green when selected
                        local label = child:GetChild(0)
                        if IsValid(label) then
                            label:SetTextColor(Color(255, 255, 255))  -- White text when selected
                        end
                        print("[TDMRP GemCraft] Set " .. child.prefixID .. " to GREEN")
                    else
                        child.bgColor = Color(40, 50, 70)  -- Dark blue-gray when not selected
                        local label = child:GetChild(0)
                        if IsValid(label) then
                            label:SetTextColor(Color(200, 220, 255))  -- Light blue text when not selected
                        end
                    end
                    child:InvalidateLayout(true)  -- Force button to repaint
                end
            end
            
            -- Trigger stat preview update
            midPanel:InvalidateLayout(true)
        end
    end
    
    -------- Bottom section: gem costs & summary --------
    local bottomPanel = vgui.Create("DPanel", frame)
    bottomPanel:Dock(FILL)
    
    function bottomPanel:Paint(w, h)
        draw.RoundedBox(8, 5, 5, w - 10, h - 10, Color(30, 35, 45, 200))
        surface.SetDrawColor(180, 120, 80, 100)
        surface.DrawOutlinedRect(5, 5, w - 10, h - 10, 1)
    end
    
    local gemCostLabel = vgui.Create("DLabel", bottomPanel)
    gemCostLabel:Dock(TOP)
    gemCostLabel:SetHeight(65)
    gemCostLabel:SetFont("DermaDefault")
    gemCostLabel:SetText("")
    
    local function UpdateCostLabel()
        local emeraldCount = GetGemCount("blood_emerald")
        local sapphireCount = GetGemCount("blood_sapphire")
        local playerMoney = GetPlayerMoney()
        local cost = GetCraftCost(weaponTier)
        
        -- Store values for Paint function
        gemCostLabel.emeraldCount = emeraldCount
        gemCostLabel.sapphireCount = sapphireCount
        gemCostLabel.playerMoney = playerMoney
        gemCostLabel.cost = cost
        gemCostLabel:InvalidateLayout()
    end
    
    function gemCostLabel:Paint(w, h)
        local emeraldCount = self.emeraldCount or 0
        local sapphireCount = self.sapphireCount or 0
        local playerMoney = self.playerMoney or 0
        local cost = self.cost or 0
        
        -- Background panel
        draw.RoundedBox(6, 0, 0, w, h, Color(25, 30, 40, 200))
        
        -- Inner border
        surface.SetDrawColor(100, 120, 180, 100)
        surface.DrawOutlinedRect(2, 2, w-4, h-4, 1)
        
        local y = 10
        
        -- Gem requirements header
        draw.SimpleText("GEM REQUIREMENTS:", "DermaDefaultBold", 10, y, Color(200, 200, 220), TEXT_ALIGN_LEFT)
        y = y + 18
        
        -- Emerald
        local emeraldColor = emeraldCount >= 1 and Color(100, 255, 100) or Color(255, 100, 100)
        draw.SimpleText("◆ Emerald: " .. emeraldCount .. "/1", "DermaDefault", 20, y, emeraldColor, TEXT_ALIGN_LEFT)
        
        -- Sapphire
        local sapphireColor = sapphireCount >= 1 and Color(100, 255, 100) or Color(255, 100, 100)
        draw.SimpleText("◆ Sapphire: " .. sapphireCount .. "/1", "DermaDefault", w/2 + 10, y, sapphireColor, TEXT_ALIGN_LEFT)
        
        y = y + 18
        
        -- Money cost
        local moneyColor = playerMoney >= cost and Color(100, 255, 100) or Color(255, 100, 100)
        draw.SimpleText("$ Money Cost: $" .. cost .. " (You have: $" .. playerMoney .. ")", "DermaDefault", 20, y, moneyColor, TEXT_ALIGN_LEFT)
    end
    
    UpdateCostLabel()
    
    -- Update label when inventory updates
    local updateHookName = "TDMRP_GemCraft_UpdateCost_" .. math.random(10000, 99999)
    hook.Add("TDMRP_InventoryUpdated", updateHookName, function()
        if not IsValid(frame) then
            hook.Remove("TDMRP_InventoryUpdated", updateHookName)
            return
        end
        UpdateCostLabel()
    end)
    
    -------- Suffix info panel --------
    local suffixInfoLabel = vgui.Create("DLabel", bottomPanel)
    suffixInfoLabel:Dock(TOP)
    suffixInfoLabel:SetHeight(35)
    suffixInfoLabel:SetFont("DermaLarge")
    suffixInfoLabel:SetText("")
    
    function suffixInfoLabel:Paint(w, h)
        -- Shadow
        draw.SimpleText("SAPPHIRE SUFFIXES (RANDOM ON CRAFT)", "DermaLarge", w/2 + 1, h/2 + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        -- Main text with orange glow
        draw.SimpleText("SAPPHIRE SUFFIXES (RANDOM ON CRAFT)", "DermaLarge", w/2, h/2, Color(255, 180, 80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    local suffixSubtitle = vgui.Create("DLabel", bottomPanel)
    suffixSubtitle:Dock(TOP)
    suffixSubtitle:SetHeight(25)
    suffixSubtitle:SetFont("DermaDefault")
    suffixSubtitle:SetText("")
    
    function suffixSubtitle:Paint(w, h)
        draw.SimpleText("(5 random suffixes available for this weapon tier)", "DermaDefault", w/2, h/2, Color(180, 180, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    local suffixScroll = vgui.Create("DScrollPanel", bottomPanel)
    suffixScroll:Dock(FILL)
    
    local suffixes = GetSuffixesForTier(weaponTier)
    for suffixID, suffixData in SortedPairs(suffixes) do
        local suffixLabel = vgui.Create("DLabel", suffixScroll)
        suffixLabel:Dock(TOP)
        suffixLabel:DockMargin(5, 2, 5, 2)
        suffixLabel:SetHeight(28)
        suffixLabel:SetFont("DermaDefault")
        suffixLabel:SetText("")
        
        local nameText = suffixData.name or suffixID
        local descText = suffixData.description or "Unknown effect"
        
        function suffixLabel:Paint(w, h)
            -- Background with rounded corners
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 35, 45, 180))
            
            -- Left accent bar
            draw.RoundedBox(0, 0, 0, 4, h, Color(100, 150, 255, 120))
            
            -- Name with shadow
            draw.SimpleText("◆ " .. nameText, "DermaDefaultBold", 13, h/2 + 1, Color(0, 0, 0, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("◆ " .. nameText, "DermaDefaultBold", 12, h/2, Color(120, 180, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Description in lighter color
            draw.SimpleText(descText, "DermaDefault", 140, h/2, Color(180, 180, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
    
    -------- Buttons at very bottom --------
    local buttonPanel = vgui.Create("DPanel", frame)
    buttonPanel:Dock(BOTTOM)
    buttonPanel:SetHeight(60)
    
    function buttonPanel:Paint(w, h)
        -- Transparent
        return true
    end
    
    local craftBtn = vgui.Create("DButton", buttonPanel)
    craftBtn:SetPos(frame:GetWide() - 170, 5)
    craftBtn:SetSize(160, 50)
    craftBtn:SetText("")
    craftBtn.isHovered = false
    craftBtn.glow = 0
    
    function craftBtn:Paint(w, h)
        -- Animated glow effect
        self.glow = (self.glow + FrameTime() * 2) % (math.pi * 2)
        local glowAlpha = math.abs(math.sin(self.glow)) * 100
        
        -- Glow
        draw.RoundedBox(10, -2, -2, w + 4, h + 4, Color(255, 215, 0, glowAlpha))
        
        -- Main button
        local col = self.isHovered and Color(255, 215, 0) or Color(218, 165, 32)
        draw.RoundedBox(8, 0, 0, w, h, col)
        
        -- Shine
        draw.RoundedBoxEx(8, 0, 0, w, h / 2, Color(255, 255, 255, 50), true, true, false, false)
        
        -- Border
        surface.SetDrawColor(255, 255, 255, 150)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        
        -- Text
        draw.SimpleText("CRAFT WEAPON", "DermaDefault", w / 2 + 1, h / 2 + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("CRAFT WEAPON", "DermaDefault", w / 2, h / 2, Color(50, 30, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        return false
    end
    
    function craftBtn:OnCursorEntered()
        self.isHovered = true
        surface.PlaySound("buttons/button17.wav")
    end
    
    function craftBtn:OnCursorExited()
        self.isHovered = false
    end
    
    function craftBtn:DoClick()
        surface.PlaySound("buttons/button9.wav")  -- Special craft sound
        
        if not UI.SelectedPrefix then
            chat.AddText(Color(255, 0, 0), "[TDMRP] Please select a prefix first.")
            return
        end
        
        local emeraldCount = GetGemCount("blood_emerald")
        local sapphireCount = GetGemCount("blood_sapphire")
        local playerMoney = GetPlayerMoney()
        local cost = GetCraftCost(weaponTier)
        
        if emeraldCount < 1 or sapphireCount < 1 then
            chat.AddText(Color(255, 0, 0), "[TDMRP] You need 1 Emerald and 1 Sapphire.")
            return
        end
        
        if playerMoney < cost then
            chat.AddText(Color(255, 0, 0), "[TDMRP] You don't have enough money ($" .. cost .. ").")
            return
        end
        
        -- Send craft request to server
        net.Start("TDMRP_CraftWeapon")
        net.WriteString(UI.SelectedPrefix)
        net.SendToServer()
        
        chat.AddText(Color(100, 255, 100), "[TDMRP] Crafting...")
        frame:Close()
    end
    
    local closeBtn = vgui.Create("DButton", buttonPanel)
    closeBtn:SetPos(10, 5)
    closeBtn:SetSize(100, 50)
    closeBtn:SetText("")
    closeBtn.isHovered = false
    
    function closeBtn:Paint(w, h)
        local col = self.isHovered and Color(200, 80, 80) or Color(140, 50, 50)
        draw.RoundedBox(8, 0, 0, w, h, col)
        
        -- Shine
        draw.RoundedBoxEx(8, 0, 0, w, h / 2, Color(255, 255, 255, 30), true, true, false, false)
        
        -- Text
        draw.SimpleText("CLOSE", "DermaDefault", w / 2 + 1, h / 2 + 1, Color(0, 0, 0, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("CLOSE", "DermaDefault", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        return false
    end
    
    function closeBtn:OnCursorEntered()
        self.isHovered = true
        surface.PlaySound("buttons/lightswitch2.wav")
    end
    
    function closeBtn:OnCursorExited()
        self.isHovered = false
    end
    
    function closeBtn:DoClick()
        surface.PlaySound("buttons/button15.wav")
        frame:Close()
    end
end

----------------------------------------------------
-- Upgrade UI (for already-crafted weapons)
----------------------------------------------------
function BuildUpgradeUI(frame, weapon, weaponTier)
    local currentPrefix = weapon:GetNWString("TDMRP_PrefixID", "")
    local currentSuffix = weapon:GetNWString("TDMRP_SuffixID", "")
    
    -------- Top section: weapon preview --------
    local topPanel = vgui.Create("DPanel", frame)
    topPanel:Dock(TOP)
    topPanel:SetHeight(250)
    topPanel:SetBackgroundColor(Color(40, 40, 40))
    
    local weaponModel = vgui.Create("DModelPanel", topPanel)
    weaponModel:Dock(LEFT)
    weaponModel:SetWidth(200)
    weaponModel:SetModel(weapon:GetModel())
    
    -- Center the camera on the model
    local mn, mx = weaponModel.Entity:GetRenderBounds()
    local size = 0
    size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
    size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
    size = math.max(size, math.abs(mn.z) + math.abs(mx.z))
    size = size * 0.5  -- Zoom in 200%
    weaponModel:SetCamPos(Vector(size, size, size))
    weaponModel:SetLookAt((mn + mx) * 0.5)
    
    -- Auto-rotate animation
    weaponModel.Entity:SetAngles(Angle(0, CurTime() * 50 % 360, 0))
    function weaponModel:OnCursorEntered()
        self.Rotating = true
    end
    function weaponModel:OnCursorExited()
        self.Rotating = false
    end
    function weaponModel:LayoutEntity(ent)
        if self.Rotating then
            ent:SetAngles(Angle(0, CurTime() * 100 % 360, 0))
        else
            ent:SetAngles(Angle(0, CurTime() * 30 % 360, 0))
        end
    end
    
    local infoPanel = vgui.Create("DPanel", topPanel)
    infoPanel:Dock(FILL)
    infoPanel:DockMargin(5, 0, 5, 5)
    
    function infoPanel:Paint(w, h)
        -- Dark background with transparency
        draw.RoundedBox(8, 0, 0, w, h, Color(15, 20, 30, 240))
        
        -- Corner accents (L-shaped lines)
        local accentCol = Color(120, 160, 220, 180)
        local accentSize = 12
        -- Top-left
        surface.SetDrawColor(accentCol)
        surface.DrawLine(5, 5, 5 + accentSize, 5)
        surface.DrawLine(5, 5, 5, 5 + accentSize)
        -- Top-right
        surface.DrawLine(w - 5 - accentSize, 5, w - 5, 5)
        surface.DrawLine(w - 5, 5, w - 5, 5 + accentSize)
        -- Bottom-left
        surface.DrawLine(5, h - 5, 5 + accentSize, h - 5)
        surface.DrawLine(5, h - 5 - accentSize, 5, h - 5)
        -- Bottom-right
        surface.DrawLine(w - 5 - accentSize, h - 5, w - 5, h - 5)
        surface.DrawLine(w - 5, h - 5 - accentSize, w - 5, h - 5)
        
        -- Inner glow border
        surface.SetDrawColor(120, 160, 220, 120)
        surface.DrawOutlinedRect(3, 3, w - 6, h - 6, 1)
    end
    
    local infoLabel = vgui.Create("DLabel", infoPanel)
    infoLabel:Dock(FILL)
    infoLabel:DockMargin(15, 10, 15, 10)
    infoLabel:SetText("")
    
    local baseName = weapon.PrintName or weapon:GetClass() or "Weapon"
    local tierName = TDMRP.TierNames and TDMRP.TierNames[weaponTier] or ("Tier " .. weaponTier)
    local currentName = weapon:GetNWString("TDMRP_CustomName", baseName)
    
    -- Get prefix/suffix display names
    local prefixName = "None"
    local suffixName = "None"
    
    if currentPrefix ~= "" and TDMRP.Gems and TDMRP.Gems.Prefixes and TDMRP.Gems.Prefixes[currentPrefix] then
        prefixName = TDMRP.Gems.Prefixes[currentPrefix].name or currentPrefix
    end
    
    if currentSuffix ~= "" and TDMRP.Gems and TDMRP.Gems.Suffixes and TDMRP.Gems.Suffixes[currentSuffix] then
        suffixName = TDMRP.Gems.Suffixes[currentSuffix].name or currentSuffix
    end
    
    function infoLabel:Paint(w, h)
        local y = 5
        
        -- Weapon name
        draw.SimpleText("WEAPON:", "DermaDefaultBold", 6, y + 1, Color(0, 0, 0, 180), TEXT_ALIGN_LEFT)
        draw.SimpleText("WEAPON:", "DermaDefaultBold", 5, y, Color(180, 180, 200), TEXT_ALIGN_LEFT)
        draw.SimpleText(currentName, "DermaLarge", 85, y + 1, Color(0, 0, 0, 180), TEXT_ALIGN_LEFT)
        draw.SimpleText(currentName, "DermaLarge", 84, y, Color(135, 206, 250), TEXT_ALIGN_LEFT)
        y = y + 25
        
        -- Tier
        draw.SimpleText("TIER:", "DermaDefaultBold", 6, y + 1, Color(0, 0, 0, 180), TEXT_ALIGN_LEFT)
        draw.SimpleText("TIER:", "DermaDefaultBold", 5, y, Color(180, 180, 200), TEXT_ALIGN_LEFT)
        local tierColor = Color(100, 255, 100)
        if weaponTier >= 3 then tierColor = Color(255, 180, 80) end
        if weaponTier >= 5 then tierColor = Color(200, 100, 255) end
        draw.SimpleText(tierName, "DermaDefault", 85, y + 1, Color(0, 0, 0, 180), TEXT_ALIGN_LEFT)
        draw.SimpleText(tierName, "DermaDefault", 84, y, tierColor, TEXT_ALIGN_LEFT)
        y = y + 20
        
        -- Separator
        surface.SetDrawColor(80, 120, 180, 100)
        surface.DrawLine(5, y, w - 5, y)
        y = y + 8
        
        -- Current prefix
        draw.SimpleText("PREFIX:", "DermaDefaultBold", 6, y + 1, Color(0, 0, 0, 180), TEXT_ALIGN_LEFT)
        draw.SimpleText("PREFIX:", "DermaDefaultBold", 5, y, Color(100, 255, 150), TEXT_ALIGN_LEFT)
        draw.SimpleText(prefixName, "DermaDefault", 85, y, Color(200, 255, 200), TEXT_ALIGN_LEFT)
        y = y + 18
        
        -- Current suffix
        draw.SimpleText("SUFFIX:", "DermaDefaultBold", 6, y + 1, Color(0, 0, 0, 180), TEXT_ALIGN_LEFT)
        draw.SimpleText("SUFFIX:", "DermaDefaultBold", 5, y, Color(255, 180, 80), TEXT_ALIGN_LEFT)
        draw.SimpleText(suffixName, "DermaDefault", 85, y, Color(255, 200, 120), TEXT_ALIGN_LEFT)
        y = y + 20
        
        -- Separator
        surface.SetDrawColor(80, 120, 180, 100)
        surface.DrawLine(5, y, w - 5, y)
        y = y + 8
        
        -- Stats header
        draw.SimpleText("CRAFTED STATS", "DermaDefaultBold", w/2 + 1, y + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER)
        draw.SimpleText("CRAFTED STATS", "DermaDefaultBold", w/2, y, Color(135, 206, 250), TEXT_ALIGN_CENTER)
        y = y + 20
        
        -- Stats horizontally
        local statsX = 5
        local statSpacing = (w - 10) / 5
        
        local dmg = weapon:GetNWInt("TDMRP_Damage", 0)
        local rpm = weapon:GetNWInt("TDMRP_RPM", 0)
        local acc = weapon:GetNWInt("TDMRP_Accuracy", 0)
        local rec = weapon:GetNWInt("TDMRP_Recoil", 0)
        local han = weapon:GetNWInt("TDMRP_Handling", 0)
        
        draw.SimpleText("DMG", "DermaDefault", statsX, y, Color(180, 180, 200), TEXT_ALIGN_LEFT)
        draw.SimpleText(tostring(dmg), "DermaDefaultBold", statsX, y + 14, Color(255, 100, 100), TEXT_ALIGN_LEFT)
        
        draw.SimpleText("RPM", "DermaDefault", statsX + statSpacing, y, Color(180, 180, 200), TEXT_ALIGN_LEFT)
        draw.SimpleText(tostring(rpm), "DermaDefaultBold", statsX + statSpacing, y + 14, Color(255, 200, 100), TEXT_ALIGN_LEFT)
        
        draw.SimpleText("ACC", "DermaDefault", statsX + statSpacing * 2, y, Color(180, 180, 200), TEXT_ALIGN_LEFT)
        draw.SimpleText(tostring(acc), "DermaDefaultBold", statsX + statSpacing * 2, y + 14, Color(100, 255, 200), TEXT_ALIGN_LEFT)
        
        draw.SimpleText("REC", "DermaDefault", statsX + statSpacing * 3, y, Color(180, 180, 200), TEXT_ALIGN_LEFT)
        draw.SimpleText(tostring(rec), "DermaDefaultBold", statsX + statSpacing * 3, y + 14, Color(200, 100, 255), TEXT_ALIGN_LEFT)
        
        draw.SimpleText("HAN", "DermaDefault", statsX + statSpacing * 4, y, Color(180, 180, 200), TEXT_ALIGN_LEFT)
        draw.SimpleText(tostring(han), "DermaDefaultBold", statsX + statSpacing * 4, y + 14, Color(100, 200, 255), TEXT_ALIGN_LEFT)
        
        return true
    end
    
    -------- Middle section: upgrade gem buttons --------
    local midPanel = vgui.Create("DPanel", frame)
    midPanel:Dock(FILL)
    midPanel:SetBackgroundColor(Color(50, 50, 50))
    
    local upgradeLabel = vgui.Create("DLabel", midPanel)
    upgradeLabel:Dock(TOP)
    upgradeLabel:SetHeight(45)
    upgradeLabel:SetFont("DermaLarge")
    upgradeLabel:SetText("")
    upgradeLabel:SetContentAlignment(5)
    
    function upgradeLabel:Paint(w, h)
        -- Shadow
        draw.SimpleText("APPLY UPGRADE GEMS", "DermaLarge", w/2 + 1, h/2 + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        -- Main text with purple glow
        draw.SimpleText("APPLY UPGRADE GEMS", "DermaLarge", w/2, h/2, Color(200, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Diamond button (stat boost)
    local diamondBtn = vgui.Create("DButton", midPanel)
    diamondBtn:Dock(TOP)
    diamondBtn:SetHeight(60)
    diamondBtn:SetText("Blood Diamond - Boost All Stats\n(Not yet implemented)")
    
    -- Ruby button (reroll suffix)
    local rubyBtn = vgui.Create("DButton", midPanel)
    rubyBtn:Dock(TOP)
    rubyBtn:SetHeight(60)
    rubyBtn:SetText("Blood Ruby - Reroll Suffix\n(Not yet implemented)")
    
    -- Amethyst button (reroll prefix)
    local amethystBtn = vgui.Create("DButton", midPanel)
    amethystBtn:Dock(TOP)
    amethystBtn:SetHeight(60)
    amethystBtn:SetText("Blood Amethyst - Reroll Prefix\n(Not yet implemented)")
    
    -------- Bottom: close button --------
    local buttonPanel = vgui.Create("DPanel", frame)
    buttonPanel:Dock(BOTTOM)
    buttonPanel:SetHeight(40)
    buttonPanel:SetBackgroundColor(Color(40, 40, 40))
    
    local closeBtn = vgui.Create("DButton", buttonPanel)
    closeBtn:Dock(FILL)
    closeBtn:SetText("Close")
    closeBtn:SetFont("DermaDefault")
    
    function closeBtn:DoClick()
        frame:Close()
    end
end

----------------------------------------------------
-- Net messages from server
----------------------------------------------------

-- Receive crafting result confirmation
net.Receive("TDMRP_CraftSuccess", function()
    local prefixID = net.ReadString()
    local suffixID = net.ReadString()
    
    chat.AddText(Color(100, 255, 100), "[TDMRP] Weapon crafted! Prefix: " .. prefixID .. ", Suffix: " .. suffixID)
end)

net.Receive("TDMRP_CraftFailed", function()
    local reason = net.ReadString()
    chat.AddText(Color(255, 100, 100), "[TDMRP] Craft failed: " .. reason)
end)

-- Listen for inventory updates from the main inventory module
hook.Add("TDMRP_InventoryUpdated", "TDMRP_GemCraft_InventoryUpdated", function(items)
    print("[TDMRP GemCraft] Inventory updated via hook")
    UI.CachedInventory = items
    UI.InventoryReceived = true
end)

----------------------------------------------------
-- Hook to open UI from F4 menu (if integrated)
----------------------------------------------------

hook.Add("TDMRP_OpenGemCrafter", "TDMRP_GemCrafterHook", function(weapon)
    UI.OpenCraftingMenu(weapon)
end)

print("[TDMRP] cl_tdmrp_gemcraft.lua loaded (gem crafting UI ready)")
