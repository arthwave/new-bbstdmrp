----------------------------------------------------
-- TDMRP F4 Menu - Jobs Tab
-- Job selection grid with 3D playermodel previews
-- Order: Civilian -> Police -> Criminal -> Special
----------------------------------------------------

if SERVER then return end

TDMRP = TDMRP or {}
TDMRP.F4Menu = TDMRP.F4Menu or {}

----------------------------------------------------
-- Jobs Tab Configuration
----------------------------------------------------

local Config = {
    cardWidth = 120,
    cardHeight = 160,
    cardPadding = 8,
    gridCols = 6,
    infoPanelWidth = 280,
    scrollSpeed = 40,
}

----------------------------------------------------
-- State
----------------------------------------------------

local scrollOffset = 0
local maxScroll = 0
local hoveredJob = nil
local selectedJob = nil
local modelPanels = {}
local modelContainer = nil

----------------------------------------------------
-- Helper: Categorize and order jobs
----------------------------------------------------

local function GetOrderedJobs()
    local categories = {
        { id = "civilian", name = "CIVILIANS", color = TDMRP.UI.Colors.class.civilian, jobs = {} },
        { id = "police",   name = "POLICE",    color = TDMRP.UI.Colors.class.police,   jobs = {} },
        { id = "criminal", name = "CRIMINALS", color = TDMRP.UI.Colors.class.criminal, jobs = {} },
        { id = "special",  name = "SPECIAL",   color = Color(255, 200, 100, 255),      jobs = {} },
    }
    
    local categoryMap = {}
    for _, cat in ipairs(categories) do
        categoryMap[cat.id] = cat
    end
    
    -- Alias: "cop" maps to "police" category
    categoryMap["cop"] = categoryMap["police"]
    
    if not RPExtraTeams then return categories end
    
    for teamID, job in pairs(RPExtraTeams) do
        -- Determine category based on job properties
        local catId = "civilian"
        
        -- Check for police/cop jobs
        local nameLower = string.lower(job.name or "")
        local cmdLower = string.lower(job.command or "")
        local catLower = string.lower(job.category or "")
        
        -- Priority 1: Explicit TDMRP class override
        if job.tdmrp_class then
            catId = job.tdmrp_class
        -- Priority 2: DarkRP's built-in police flag (most reliable)
        elseif job.police or job.chief or job.mayor then
            catId = "police"
        -- Priority 3: Category name detection
        elseif catLower ~= "" then
            if string.find(catLower, "police") or string.find(catLower, "cop") or string.find(catLower, "law") or string.find(catLower, "government") or string.find(catLower, "civil protection") then
                catId = "police"
            elseif string.find(catLower, "crim") or string.find(catLower, "gang") or string.find(catLower, "illegal") then
                catId = "criminal"
            elseif string.find(catLower, "special") or string.find(catLower, "vip") or string.find(catLower, "donator") then
                catId = "special"
            end
        end
        
        -- Priority 4: Job name heuristics (if category didn't match)
        if catId == "civilian" then
            if string.find(nameLower, "police") or string.find(nameLower, "cop") or string.find(nameLower, "officer") or string.find(nameLower, "swat") or string.find(nameLower, "chief") or string.find(nameLower, "mayor") or string.find(nameLower, "sheriff") or string.find(nameLower, "deputy") or string.find(nameLower, "fbi") or string.find(nameLower, "secret service") then
                catId = "police"
            elseif string.find(nameLower, "thief") or string.find(nameLower, "gang") or string.find(nameLower, "mob") or string.find(nameLower, "hitman") or string.find(nameLower, "terrorist") or string.find(nameLower, "criminal") or string.find(nameLower, "dealer") or string.find(nameLower, "kidnapper") or string.find(nameLower, "raider") then
                catId = "criminal"
            elseif string.find(nameLower, "zombie") or string.find(nameLower, "special") then
                catId = "special"
            end
        end
        
        -- Ensure category exists
        if not categoryMap[catId] then
            catId = "civilian"
        end
        
        local model = job.model
        if istable(model) then
            model = model[1]
        end
        
        table.insert(categoryMap[catId].jobs, {
            teamID = teamID,
            name = job.name or "Unknown",
            model = model or "models/player/kleiner.mdl",
            salary = job.salary or 0,
            max = job.max or 0,
            description = job.description or "No description available.",
            command = job.command or "",
            category = catId,
            vote = job.vote or false,
            admin = job.admin or 0,
        })
    end
    
    -- Sort jobs within each category by name
    for _, cat in ipairs(categories) do
        table.sort(cat.jobs, function(a, b)
            return a.name < b.name
        end)
    end
    
    return categories
end

----------------------------------------------------
-- Model Panel Management
----------------------------------------------------

local function ClearModelPanels()
    for _, panel in pairs(modelPanels) do
        if IsValid(panel) then
            panel:Remove()
        end
    end
    modelPanels = {}
end

local function GetOrCreateModelPanel(job, x, y, size)
    local key = job.teamID
    
    if modelPanels[key] and IsValid(modelPanels[key]) then
        local panel = modelPanels[key]
        panel:SetPos(x, y)
        panel:SetSize(size, size)
        panel:SetVisible(true)
        return panel
    end
    
    -- Parent model container to F4 menu so it renders AFTER menu's Paint()
    local menuPanel = TDMRP.F4Menu.GetPanel()
    if not IsValid(menuPanel) then return nil end
    
    if not IsValid(modelContainer) then
        modelContainer = vgui.Create("DPanel", menuPanel)
        modelContainer:SetPos(0, 0)
        modelContainer:SetSize(ScrW(), ScrH())
        modelContainer:SetMouseInputEnabled(false)
        modelContainer:SetKeyboardInputEnabled(false)
        modelContainer.Paint = function() end
    end
    
    local panel = vgui.Create("DModelPanel", modelContainer)
    panel:SetPos(x, y)
    panel:SetSize(size, size)
    panel:SetModel(job.model or "models/player/kleiner.mdl")
    panel:SetFOV(25)
    panel:SetCamPos(Vector(45, 0, 64))
    panel:SetLookAt(Vector(0, 0, 64))
    panel:SetAnimated(false)
    panel:SetMouseInputEnabled(false)
    
    -- Static facing angle - no animation, fixed pose
    panel.LayoutEntity = function(self, ent)
        if IsValid(ent) then
            ent:SetAngles(Angle(0, 45, 0))
        end
    end
    
    modelPanels[key] = panel
    return panel
end

local function HideAllModelPanels()
    for _, panel in pairs(modelPanels) do
        if IsValid(panel) then
            panel:SetVisible(false)
        end
    end
end

----------------------------------------------------
-- Paint Function
----------------------------------------------------

local function PaintJobs(x, y, w, h, alpha, mx, my, scroll)
    local C = TDMRP.UI.Colors
    local ply = LocalPlayer()
    local currentTeam = IsValid(ply) and ply:Team() or 0
    
    -- Hide all model panels first, then show only visible ones
    HideAllModelPanels()
    
    local categories = GetOrderedJobs()
    
    -- Layout: Main grid area + right info panel
    local infoPanelW = Config.infoPanelWidth
    local gridW = w - infoPanelW - 30
    local gridX = x + 15
    local gridY = y + 10
    
    -- Calculate dynamic columns based on available width
    local cols = math.floor(gridW / (Config.cardWidth + Config.cardPadding))
    cols = math.max(cols, 3)
    
    local cardW = math.floor((gridW - (cols - 1) * Config.cardPadding) / cols)
    local cardH = Config.cardHeight
    
    local drawY = gridY - scrollOffset
    local contentHeight = 0
    hoveredJob = nil
    
    -- Draw categories and job cards
    for _, category in ipairs(categories) do
        if #category.jobs > 0 then
            -- Category header
            local headerH = 28
            if drawY + headerH > y and drawY < y + h then
                draw.RoundedBox(4, gridX, drawY, gridW, headerH, ColorAlpha(category.color, alpha * 0.12))
                surface.SetDrawColor(ColorAlpha(category.color, alpha))
                surface.DrawRect(gridX, drawY, 3, headerH)
                draw.SimpleText(category.name, "TDMRP_SubHeader", gridX + 12, drawY + headerH/2, ColorAlpha(category.color, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(#category.jobs .. " jobs", "TDMRP_Small", gridX + gridW - 10, drawY + headerH/2, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
            drawY = drawY + headerH + 8
            
            -- Job cards in grid
            local col = 0
            for _, job in ipairs(category.jobs) do
                local cardX = gridX + col * (cardW + Config.cardPadding)
                local cardY = drawY
                
                -- Only render visible cards
                if cardY + cardH > y and cardY < y + h then
                    local isHovered = mx >= cardX and mx <= cardX + cardW and my >= cardY and my <= cardY + cardH
                    local isCurrentJob = (job.teamID == currentTeam)
                    local isSelected = (selectedJob and selectedJob.teamID == job.teamID)
                    
                    if isHovered then
                        hoveredJob = job
                    end
                    
                    -- Card background
                    local cardBg = C.bg_light
                    if isSelected then
                        cardBg = Color(category.color.r, category.color.g, category.color.b, 50)
                    elseif isCurrentJob then
                        cardBg = Color(category.color.r, category.color.g, category.color.b, 30)
                    elseif isHovered then
                        cardBg = C.bg_hover
                    end
                    
                    draw.RoundedBox(6, cardX, cardY, cardW, cardH, ColorAlpha(cardBg, alpha))
                    
                    -- Border
                    if isCurrentJob then
                        surface.SetDrawColor(ColorAlpha(C.success, alpha))
                        surface.DrawOutlinedRect(cardX, cardY, cardW, cardH, 2)
                    elseif isSelected then
                        surface.SetDrawColor(ColorAlpha(category.color, alpha))
                        surface.DrawOutlinedRect(cardX, cardY, cardW, cardH, 2)
                    elseif isHovered then
                        surface.SetDrawColor(ColorAlpha(C.accent, alpha * 0.6))
                        surface.DrawOutlinedRect(cardX, cardY, cardW, cardH, 1)
                    end
                    
                    -- 3D Model panel (static - no animation)
                    local modelSize = math.min(cardW - 16, 80)
                    local modelX = cardX + (cardW - modelSize) / 2
                    local modelY = cardY + 8
                    
                    -- Only show if FULLY within visible content area
                    local isInBounds = modelY >= y and modelY + modelSize <= y + h
                    
                    if isInBounds then
                        local modelPanel = GetOrCreateModelPanel(job, modelX, modelY, modelSize)
                        if IsValid(modelPanel) then
                            modelPanel:SetVisible(true)
                            modelPanel:SetAlpha(alpha)
                        end
                    end
                    
                    -- Current job checkmark
                    if isCurrentJob then
                        draw.SimpleText("✓", "TDMRP_Body", cardX + cardW - 12, cardY + 8, ColorAlpha(C.success, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                    end
                    
                    -- Job name (below model)
                    local nameY = cardY + modelSize + 14
                    surface.SetFont("TDMRP_SmallBold")
                    local nameText = job.name
                    local nameW = surface.GetTextSize(nameText)
                    if nameW > cardW - 10 then
                        while nameW > cardW - 16 and #nameText > 5 do
                            nameText = string.sub(nameText, 1, -2)
                            nameW = surface.GetTextSize(nameText .. "..")
                        end
                        nameText = nameText .. ".."
                    end
                    draw.SimpleText(nameText, "TDMRP_SmallBold", cardX + cardW/2, nameY, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                    
                    -- Salary
                    local salaryY = nameY + 16
                    draw.SimpleText(TDMRP.UI.FormatMoney(job.salary), "TDMRP_Tiny", cardX + cardW/2, salaryY, ColorAlpha(C.success, alpha * 0.8), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                    
                    -- Slots
                    if job.max > 0 then
                        local currentCount = team.NumPlayers(job.teamID)
                        local full = currentCount >= job.max
                        local slotsColor = full and C.error or C.text_muted
                        draw.SimpleText(currentCount .. "/" .. job.max, "TDMRP_Tiny", cardX + cardW/2, cardY + cardH - 12, ColorAlpha(slotsColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                    end
                end
                
                col = col + 1
                if col >= cols then
                    col = 0
                    drawY = drawY + cardH + Config.cardPadding
                end
            end
            
            -- Move to next row if we ended mid-row
            if col > 0 then
                drawY = drawY + cardH + Config.cardPadding
            end
            
            drawY = drawY + 10 -- Space between categories
        end
    end
    
    contentHeight = drawY + scrollOffset - gridY
    maxScroll = math.max(0, contentHeight - h + 30)
    
    -- Right info panel
    local infoPanelX = x + w - infoPanelW - 10
    local infoPanelY = y + 10
    local infoPanelH = h - 20
    
    draw.RoundedBox(6, infoPanelX, infoPanelY, infoPanelW, infoPanelH, ColorAlpha(C.bg_dark, alpha))
    
    -- Show info for hovered or selected job
    local displayJob = hoveredJob or selectedJob
    
    if displayJob then
        local padX = infoPanelX + 15
        local padY = infoPanelY + 15
        
        -- Job name header
        draw.SimpleText(displayJob.name, "TDMRP_SubHeader", padX, padY, ColorAlpha(C.text_primary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        padY = padY + 28
        
        -- Divider
        surface.SetDrawColor(ColorAlpha(C.border_dark, alpha))
        surface.DrawRect(padX, padY, infoPanelW - 30, 1)
        padY = padY + 10
        
        -- Salary
        draw.SimpleText("Salary", "TDMRP_SmallBold", padX, padY, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(TDMRP.UI.FormatMoney(displayJob.salary) .. " / paycheck", "TDMRP_Body", padX, padY + 16, ColorAlpha(C.success, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        padY = padY + 45
        
        -- Slots
        if displayJob.max > 0 then
            local current = team.NumPlayers(displayJob.teamID)
            draw.SimpleText("Slots", "TDMRP_SmallBold", padX, padY, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local slotsColor = current >= displayJob.max and C.error or C.text_primary
            draw.SimpleText(current .. " / " .. displayJob.max, "TDMRP_Body", padX, padY + 16, ColorAlpha(slotsColor, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            padY = padY + 45
        end
        
        -- Vote requirement
        if displayJob.vote then
            draw.SimpleText("⚡ Requires Vote", "TDMRP_Small", padX, padY, ColorAlpha(C.warning, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            padY = padY + 25
        end
        
        -- Description
        draw.SimpleText("Description", "TDMRP_SmallBold", padX, padY, ColorAlpha(C.text_secondary, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        padY = padY + 18
        
        -- Word wrap description
        local desc = displayJob.description or "No description available."
        local maxLineW = infoPanelW - 35
        surface.SetFont("TDMRP_Small")
        
        local words = string.Explode(" ", desc)
        local lines = {}
        local currentLine = ""
        
        for _, word in ipairs(words) do
            local testLine = currentLine == "" and word or (currentLine .. " " .. word)
            local testW = surface.GetTextSize(testLine)
            
            if testW > maxLineW then
                if currentLine ~= "" then
                    table.insert(lines, currentLine)
                end
                currentLine = word
            else
                currentLine = testLine
            end
        end
        if currentLine ~= "" then
            table.insert(lines, currentLine)
        end
        
        for i, line in ipairs(lines) do
            if i <= 6 then -- Max 6 lines
                draw.SimpleText(line, "TDMRP_Small", padX, padY, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                padY = padY + 14
            end
        end
        
        -- Status indicator (no button - click card directly to become job)
        local statusY = infoPanelY + infoPanelH - 40
        local isCurrentJob = (displayJob.teamID == (IsValid(ply) and ply:Team() or 0))
        local isFull = displayJob.max > 0 and team.NumPlayers(displayJob.teamID) >= displayJob.max
        
        if isCurrentJob then
            draw.SimpleText("✓ CURRENT JOB", "TDMRP_SmallBold", infoPanelX + infoPanelW/2, statusY, ColorAlpha(C.success, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        elseif isFull then
            draw.SimpleText("✗ SLOTS FULL", "TDMRP_SmallBold", infoPanelX + infoPanelW/2, statusY, ColorAlpha(C.error, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        elseif displayJob.vote then
            draw.SimpleText("Click to vote", "TDMRP_Small", infoPanelX + infoPanelW/2, statusY, ColorAlpha(C.warning, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        else
            draw.SimpleText("Click card to become", "TDMRP_Small", infoPanelX + infoPanelW/2, statusY, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end
    else
        -- No job hovered - show prompt
        draw.SimpleText("HOVER A JOB", "TDMRP_SubHeader", infoPanelX + infoPanelW/2, infoPanelY + 30, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Hover over a job card", "TDMRP_Small", infoPanelX + infoPanelW/2, infoPanelY + 60, ColorAlpha(C.text_muted, alpha * 0.7), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("to see details", "TDMRP_Small", infoPanelX + infoPanelW/2, infoPanelY + 76, ColorAlpha(C.text_muted, alpha * 0.7), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Click to become that job", "TDMRP_Small", infoPanelX + infoPanelW/2, infoPanelY + 100, ColorAlpha(C.accent, alpha * 0.7), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    -- Scroll indicators
    if scrollOffset > 0 then
        draw.RoundedBox(0, gridX, y, gridW, 15, ColorAlpha(C.bg_medium, alpha))
        draw.SimpleText("▲", "TDMRP_Tiny", gridX + gridW/2, y + 2, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
    
    if scrollOffset < maxScroll then
        draw.RoundedBox(0, gridX, y + h - 15, gridW, 15, ColorAlpha(C.bg_medium, alpha))
        draw.SimpleText("▼", "TDMRP_Tiny", gridX + gridW/2, y + h - 13, ColorAlpha(C.text_muted, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end
end

----------------------------------------------------
-- Click Handler
----------------------------------------------------

local function HandleJobClick(relX, relY, w, h)
    local C = TDMRP.UI.Colors
    local ply = LocalPlayer()
    
    local categories = GetOrderedJobs()
    local infoPanelW = Config.infoPanelWidth
    local gridW = w - infoPanelW - 30
    local gridX = 15
    local gridY = 10
    
    local cols = math.floor(gridW / (Config.cardWidth + Config.cardPadding))
    cols = math.max(cols, 3)
    local cardW = math.floor((gridW - (cols - 1) * Config.cardPadding) / cols)
    local cardH = Config.cardHeight
    
    -- Check job card clicks - directly become the job on click
    local drawY = gridY - scrollOffset
    
    for _, category in ipairs(categories) do
        if #category.jobs > 0 then
            drawY = drawY + 28 + 8 -- header + padding
            
            local col = 0
            for _, job in ipairs(category.jobs) do
                local cardX = gridX + col * (cardW + Config.cardPadding)
                local cardY = drawY
                
                if relX >= cardX and relX <= cardX + cardW and relY >= cardY and relY <= cardY + cardH then
                    local isCurrentJob = (job.teamID == ply:Team())
                    local isFull = job.max > 0 and team.NumPlayers(job.teamID) >= job.max
                    
                    if not isCurrentJob and not isFull and job.command then
                        local cmd = job.command
                        if not string.StartWith(cmd, "/") then
                            cmd = "/" .. cmd
                        end
                        RunConsoleCommand("say", cmd)
                        surface.PlaySound("UI/buttonclick.wav")
                        
                        -- Close menu after delay
                        timer.Simple(0.5, function()
                            if TDMRP.F4Menu and TDMRP.F4Menu.Close then
                                TDMRP.F4Menu.Close()
                            end
                        end)
                    elseif isCurrentJob then
                        -- Already this job - just play sound
                        surface.PlaySound("buttons/button10.wav")
                    elseif isFull then
                        -- Slots full - error sound
                        surface.PlaySound("buttons/button10.wav")
                    end
                    return
                end
                
                col = col + 1
                if col >= cols then
                    col = 0
                    drawY = drawY + cardH + Config.cardPadding
                end
            end
            
            if col > 0 then
                drawY = drawY + cardH + Config.cardPadding
            end
            drawY = drawY + 10
        end
    end
end

----------------------------------------------------
-- Scroll Handler
----------------------------------------------------

local function HandleJobScroll(delta)
    scrollOffset = math.Clamp(scrollOffset - delta * Config.scrollSpeed, 0, maxScroll)
end

----------------------------------------------------
-- Cleanup on menu close
----------------------------------------------------

----------------------------------------------------
-- Cleanup on menu close
----------------------------------------------------

hook.Add("TDMRP_F4MenuClosed", "TDMRP_JobsCleanup", function()
    -- Completely remove all model panels to prevent persistence
    ClearModelPanels()
    if IsValid(modelContainer) then
        modelContainer:Remove()
        modelContainer = nil
    end
end)

hook.Add("TDMRP_F4TabChanged", "TDMRP_JobsTabChange", function(newTab, oldTab)
    -- Hide job model panels when switching away from jobs tab
    if oldTab == "jobs" then
        HideAllModelPanels()
    end
end)

hook.Add("TDMRP_F4MenuOpened", "TDMRP_JobsInit", function()
    scrollOffset = 0
    selectedJob = nil
end)

----------------------------------------------------
-- Register Tab (Deferred)
----------------------------------------------------

local function RegisterJobsTab()
    if TDMRP.F4Menu and TDMRP.F4Menu.RegisterTab then
        TDMRP.F4Menu.RegisterTab("jobs", PaintJobs, HandleJobClick, HandleJobScroll)
    end
end

if TDMRP.F4Menu and TDMRP.F4Menu.Ready then
    RegisterJobsTab()
else
    hook.Add("TDMRP_F4MenuReady", "TDMRP_RegisterJobsTab", RegisterJobsTab)
end

print("[TDMRP] cl_tdmrp_f4_jobs.lua loaded - Jobs tab with 3D playermodels")
