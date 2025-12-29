-- cl_tdmrp_inventory.lua
-- Client-side inventory UI

if not CLIENT then return end

TDMRP = TDMRP or {}
local InvFrame
local InvItems = {}
local F4InvPanel = nil  -- Reference to the F4 inventory panel when created

----------------------------------------
-- Fonts
----------------------------------------
surface.CreateFont("TDMRP_Inv_Title", {
    font = "Trebuchet24",
    size = 24,
    weight = 700
})

surface.CreateFont("TDMRP_Inv_Row", {
    font = "Trebuchet18",
    size = 18,
    weight = 500
})

----------------------------------------
-- Net helpers
----------------------------------------
local function TDMRP_RequestInventory()
    net.Start("TDMRP_Inventory_Request")
    net.SendToServer()
end

local function TDMRP_SendUseItem(id)
    if not id then return end
    net.Start("TDMRP_Inventory_UseItem")
    net.WriteUInt(id, 16)
    net.SendToServer()
end

local function TDMRP_SendDropItem(id)
    if not id then return end
    net.Start("TDMRP_Inventory_DropItem")
    net.WriteUInt(id, 16)
    net.SendToServer()
end

----------------------------------------
-- Helpers for display
----------------------------------------
local GemNames = {
    blood_ruby     = "Blood Ruby",
    blood_sapphire = "Blood Sapphire",
    blood_emerald  = "Blood Emerald",
    blood_amethyst = "Blood Amethyst",
    blood_diamond  = "Blood Diamond",
}

local function GetWeaponModelFromClass(class)
    if not class or class == "" then
        return "models/weapons/w_pistol.mdl"
    end

    local swep = weapons.GetStored(class)
    if swep and swep.WorldModel and swep.WorldModel ~= "" then
        return swep.WorldModel
    end

    return "models/weapons/w_pistol.mdl"
end

local function MakeModelIcon(parent, modelPath)
    local icon = vgui.Create("SpawnIcon", parent)
    icon:SetModel(modelPath or "models/props_junk/PopCan01a.mdl")
    icon:SetSize(64, 64)
    icon:SetMouseInputEnabled(false)  -- so clicks go to the row/use/drop buttons
    return icon
end

----------------------------------------
-- UI building
----------------------------------------
local function ClearInventoryList()
    if not IsValid(InvFrame) then return end
    if IsValid(InvFrame.Scroll) then
        InvFrame.Scroll:Clear()
    end
end

local function AddSectionHeader(scroll, text)
    local lbl = scroll:Add("DLabel")
    lbl:SetFont("TDMRP_Inv_Title")
    lbl:SetText(text)
    lbl:SetTextColor(Color(200, 200, 200))
    lbl:Dock(TOP)
    lbl:DockMargin(0, 10, 0, 5)
    lbl:SetTall(28)
end

local function AddItemRow(scroll, item, section)
    local row = scroll:Add("DPanel")
    row:SetTall(90)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, 4)
    row.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 180))
    end

    -- Icon
    local icon = nil
    if item.kind == "weapon" then
        icon = MakeModelIcon(row, GetWeaponModelFromClass(item.class))
    elseif item.kind == "gem" then
        icon = MakeModelIcon(row, "models/props_junk/GlassBottle01a.mdl")
    elseif item.kind == "scrap" then
        icon = MakeModelIcon(row, "models/props_debris/metal_panel02a.mdl")
    else
        icon = MakeModelIcon(row, "models/props_junk/PopCan01a.mdl")
    end
    icon:SetSize(64, 64)
    icon:SetPos(4, 4)

    -- Create a custom panel for colored text display
    local textPanel = vgui.Create("DPanel", row)
    textPanel:SetPos(80, 8)
    textPanel:SetSize(400, 82)
    textPanel.Paint = function(self, w, h)
        -- Nothing - we'll draw in the row instead
    end

    local descLines = {}
    local descColors = {}

    if item.kind == "weapon" then
        -- Prefer crafted / custom display name if present
        local wepName = item.class or "Unknown"
        if item.cosmetic and item.cosmetic.name and item.cosmetic.name ~= "" then
            wepName = item.cosmetic.name
        end

        -- Tier label (Common / Uncommon / Rare / Legendary)
        local tierNum  = item.tier or 1
        local tierDef  = TDMRP_Tiers and TDMRP_Tiers[tierNum]
        local tierName = tierDef and tierDef.name or ("Tier " .. tierNum)
        local tierColor = tierDef and tierDef.color or Color(200, 200, 200)

        -- Weapon name (gold)
        table.insert(descLines, string.format("Weapon: %s", wepName))
        table.insert(descColors, Color(255, 215, 0))
        
        -- Tier with tier color
        table.insert(descLines, string.format("Tier: %s", tierName))
        table.insert(descColors, tierColor)

        if item.stats then
            local dmg      = item.stats.damage   or 0
            local rpm      = item.stats.rpm      or 0
            local acc      = item.stats.accuracy or 0
            local recoil   = item.stats.recoil   or 0
            local handling = item.stats.handling or 0
            
            -- Stats line 1 (light cyan)
            table.insert(descLines, string.format("DMG: %d | RPM: %d", dmg, rpm))
            table.insert(descColors, Color(100, 200, 255))
            
            -- Stats line 2 (light cyan)
            table.insert(descLines, string.format(
                "ACC: %d | REC: %d | HND: %d",
                acc, recoil, handling
            ))
            table.insert(descColors, Color(100, 200, 255))
        end
    elseif item.kind == "gem" then
        local gemName = GemNames[item.gem or ""] or (item.gem or "Unknown Gem")
        table.insert(descLines, string.format("%s", gemName))
        table.insert(descColors, Color(255, 180, 100))  -- Orange for gems
        
        table.insert(descLines, string.format("Amount: %d", item.amount or 1))
        table.insert(descColors, Color(200, 200, 200))
    elseif item.kind == "scrap" then
        table.insert(descLines, "Metal Scrap")
        table.insert(descColors, Color(180, 180, 180))  -- Gray for scrap
        
        table.insert(descLines, string.format("Amount: %d", item.amount or 1))
        table.insert(descColors, Color(200, 200, 200))
    else
        table.insert(descLines, string.format("Item: %s", item.kind or "Unknown"))
        table.insert(descColors, Color(200, 200, 200))
    end

    -- Override row's paint to draw colored text
    local origRowPaint = row.Paint
    row.Paint = function(self, w, h)
        -- Draw background
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, 180))
        
        -- Draw colored text lines
        local y = 8
        for i, line in ipairs(descLines) do
            local col = descColors[i] or Color(200, 200, 200)
            draw.SimpleText(line, "TDMRP_Inv_Row", 80, y, col, TEXT_ALIGN_LEFT)
            y = y + 18  -- Line height
        end
    end

    -- Buttons (Use / Drop)
    local btnUse  -- may be nil for weapons
    local btnDrop

    -- Only non-weapons get a Use button for now
    if item.kind ~= "weapon" then
        btnUse = vgui.Create("DButton", row)
        btnUse:SetText("Use")
        btnUse:SetFont("TDMRP_Inv_Row")
        btnUse:SetSize(80, 28)
        btnUse:SetPos(row:GetWide() - 180, row:GetTall() / 2 - 14)
        btnUse:SetTextColor(Color(0, 0, 0))
        btnUse.Paint = function(self, w, h)
            local col = Color(100, 200, 100, 255)
            if self:IsHovered() then
                col = Color(120, 220, 120, 255)
            end
            draw.RoundedBox(4, 0, 0, w, h, col)
        end
        btnUse.DoClick = function()
            if item.id then
                TDMRP_SendUseItem(item.id)
            end
        end
    end

    -- Everyone gets a Drop button
    btnDrop = vgui.Create("DButton", row)
    btnDrop:SetText("Drop")
    btnDrop:SetFont("TDMRP_Inv_Row")
    btnDrop:SetSize(80, 28)
    btnDrop:SetPos(row:GetWide() - 90, row:GetTall() / 2 - 14)
    btnDrop:SetTextColor(Color(0, 0, 0))
    btnDrop.Paint = function(self, w, h)
        local col = Color(200, 100, 100, 255)
        if self:IsHovered() then
            col = Color(220, 120, 120, 255)
        end
        draw.RoundedBox(4, 0, 0, w, h, col)
    end
    btnDrop.DoClick = function()
        if item.id then
            TDMRP_SendDropItem(item.id)
        end
    end

    -- Fix button positions when panel resizes
    row.PerformLayout = function(self, w, h)
        if IsValid(btnUse) then
            -- Use + Drop
            btnUse:SetPos(w - 180, h / 2 - 14)
            btnDrop:SetPos(w - 90,  h / 2 - 14)
        else
            -- Only Drop (weapons)
            btnDrop:SetPos(w - 90, h / 2 - 14)
        end
    end
end

-- Populate the F4 inventory panel
local function PopulateF4InventoryPanel(scroll, items)
    scroll:Clear()
    
    InvItems = items or {}

    -- Group items by kind
    local weapons = {}
    local gems    = {}
    local misc    = {}

    for _, itm in ipairs(InvItems) do
        if itm.kind == "weapon" then
            table.insert(weapons, itm)
        elseif itm.kind == "gem" or itm.kind == "scrap" then
            table.insert(gems, itm)
        else
            table.insert(misc, itm)
        end
    end

    if #weapons > 0 then
        AddSectionHeader(scroll, "Weapons")
        for _, itm in ipairs(weapons) do
            AddItemRow(scroll, itm, "weapon")
        end
    end

    if #gems > 0 then
        AddSectionHeader(scroll, "Gems & Materials")
        for _, itm in ipairs(gems) do
            AddItemRow(scroll, itm, "gem")
        end
    end

    if #misc > 0 then
        AddSectionHeader(scroll, "Miscellaneous")
        for _, itm in ipairs(misc) do
            AddItemRow(scroll, itm, "misc")
        end
    end

    if #weapons == 0 and #gems == 0 and #misc == 0 then
        local lbl = scroll:Add("DLabel")
        lbl:SetFont("TDMRP_Inv_Row")
        lbl:SetText("Your inventory is empty.")
        lbl:SetTextColor(Color(200, 200, 200))
        lbl:Dock(TOP)
        lbl:DockMargin(0, 10, 0, 0)
        lbl:SetTall(24)
    end
end

local function PopulateInventoryUI(items)
    -- Try to populate F4 inventory panel first if it exists
    if F4InvPanel and IsValid(F4InvPanel.ScrollPanel) then
        PopulateF4InventoryPanel(F4InvPanel.ScrollPanel, items)
        return
    end
    
    -- Fall back to standalone frame
    if not IsValid(InvFrame) or not IsValid(InvFrame.Scroll) then return end

    InvFrame.Scroll:Clear()

    InvItems = items or {}

    -- Group items by kind
    local weapons = {}
    local gems    = {}
    local misc    = {}

    for _, itm in ipairs(InvItems) do
        if itm.kind == "weapon" then
            table.insert(weapons, itm)
        elseif itm.kind == "gem" or itm.kind == "scrap" then
            table.insert(gems, itm)
        else
            table.insert(misc, itm)
        end
    end

    if #weapons > 0 then
        AddSectionHeader(InvFrame.Scroll, "Weapons")
        for _, itm in ipairs(weapons) do
            AddItemRow(InvFrame.Scroll, itm, "weapon")
        end
    end

    if #gems > 0 then
        AddSectionHeader(InvFrame.Scroll, "Gems & Materials")
        for _, itm in ipairs(gems) do
            AddItemRow(InvFrame.Scroll, itm, "gem")
        end
    end

    if #misc > 0 then
        AddSectionHeader(InvFrame.Scroll, "Miscellaneous")
        for _, itm in ipairs(misc) do
            AddItemRow(InvFrame.Scroll, itm, "misc")
        end
    end

    if #weapons == 0 and #gems == 0 and #misc == 0 then
        local lbl = InvFrame.Scroll:Add("DLabel")
        lbl:SetFont("TDMRP_Inv_Row")
        lbl:SetText("Your inventory is empty.")
        lbl:SetTextColor(Color(200, 200, 200))
        lbl:Dock(TOP)
        lbl:DockMargin(0, 10, 0, 0)
        lbl:SetTall(24)
    end
end

----------------------------------------
-- Frame creation / open
----------------------------------------
function TDMRP_OpenInventory()
    if IsValid(InvFrame) then
        InvFrame:Close()
        InvFrame = nil
        return
    end

    InvFrame = vgui.Create("DFrame")
    InvFrame:SetSize(ScrW() * 0.5, ScrH() * 0.6)
    InvFrame:Center()
    InvFrame:SetTitle("TDMRP Inventory")
    InvFrame:MakePopup()
    InvFrame:SetDeleteOnClose(true)

    function InvFrame:Paint(w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(10, 10, 10, 230))
    end

    local scroll = vgui.Create("DScrollPanel", InvFrame)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 8, 8, 8)
    InvFrame.Scroll = scroll

    -- First populate with "loading"
    scroll:Clear()
    local lbl = scroll:Add("DLabel")
    lbl:SetFont("TDMRP_Inv_Row")
    lbl:SetText("Loading inventory...")
    lbl:SetTextColor(Color(200, 200, 200))
    lbl:Dock(TOP)
    lbl:DockMargin(0, 10, 0, 0)
    lbl:SetTall(24)

    -- Request actual data from server
    TDMRP_RequestInventory()
end

concommand.Add("tdmrp_inventory", function()
    TDMRP_OpenInventory()
end)

----------------------------------------
-- Net: receive inventory data
----------------------------------------
net.Receive("TDMRP_Inventory_Data", function()
    local items = net.ReadTable() or {}
    PopulateInventoryUI(items)
    
    -- Cache for gemcraft module (use proper namespace)
    TDMRP = TDMRP or {}
    TDMRP.GemUI = TDMRP.GemUI or {}
    TDMRP.GemUI.CachedInventory = items
    TDMRP.GemUI.InventoryReceived = true
    
    -- Fire hook so other modules know inventory was updated
    hook.Call("TDMRP_InventoryUpdated", nil, items)
end)

-- Register F4 inventory panel so it can be updated
function TDMRP_RegisterF4InventoryPanel(panel)
    F4InvPanel = panel
end

print("[TDMRP] cl_tdmrp_inventory.lua loaded (F4 tab + console: tdmrp_inventory)")
