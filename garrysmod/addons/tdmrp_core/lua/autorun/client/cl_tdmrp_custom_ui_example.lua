-- cl_tdmrp_custom_ui_example.lua
-- Example of a fully custom-styled UI panel
-- Open with console command: tdmrp_customui_demo

if not CLIENT then return end

local function CreateCustomStyledDemo()
    -- Main frame with custom styling
    local frame = vgui.Create("DFrame")
    frame:SetSize(600, 400)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    
    -- Custom paint for frame (light blue rounded rectangle)
    function frame:Paint(w, h)
        -- Main background - light blue rounded rectangle
        draw.RoundedBox(12, 0, 0, w, h, Color(135, 206, 250, 240))
        
        -- Title bar - darker blue
        draw.RoundedBoxEx(12, 0, 0, w, 40, Color(70, 130, 180, 255), true, true, false, false)
        
        -- Border/outline
        surface.SetDrawColor(255, 255, 255, 150)
        draw.RoundedBox(12, 0, 0, w, h, Color(0, 0, 0, 0))
        surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 2)
        
        -- Title text
        draw.SimpleText("Custom UI Demo", "DermaLarge", w / 2, 20, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    -- Custom close button
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetPos(frame:GetWide() - 35, 5)
    closeBtn:SetSize(30, 30)
    closeBtn:SetText("")
    closeBtn.isHovered = false
    
    function closeBtn:Paint(w, h)
        local col = self.isHovered and Color(255, 100, 100) or Color(200, 50, 50)
        draw.RoundedBox(4, 0, 0, w, h, col)
        
        -- Draw X
        surface.SetDrawColor(255, 255, 255)
        surface.DrawLine(8, 8, w - 8, h - 8)
        surface.DrawLine(w - 8, 8, 8, h - 8)
        
        return false
    end
    
    function closeBtn:OnCursorEntered()
        self.isHovered = true
        surface.PlaySound("buttons/lightswitch2.wav")  -- Beep on hover
    end
    
    function closeBtn:OnCursorExited()
        self.isHovered = false
    end
    
    function closeBtn:DoClick()
        surface.PlaySound("buttons/button15.wav")  -- Click sound
        frame:Close()
    end
    
    -- Content panel
    local content = vgui.Create("DPanel", frame)
    content:SetPos(20, 60)
    content:SetSize(frame:GetWide() - 40, frame:GetTall() - 80)
    
    function content:Paint(w, h)
        -- Transparent dark background
        draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 80))
    end
    
    -- Example label
    local label = vgui.Create("DLabel", content)
    label:SetPos(20, 20)
    label:SetSize(content:GetWide() - 40, 30)
    label:SetText("Select an option:")
    label:SetFont("DermaLarge")
    label:SetTextColor(Color(255, 255, 255))
    
    -- Custom styled dropdown
    local dropdown = vgui.Create("DComboBox", content)
    dropdown:SetPos(20, 60)
    dropdown:SetSize(200, 35)
    dropdown:SetValue("Choose...")
    dropdown:AddChoice("Option 1")
    dropdown:AddChoice("Option 2")
    dropdown:AddChoice("Option 3")
    
    function dropdown:Paint(w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(100, 149, 237))
        return false
    end
    
    function dropdown:OnSelect(index, value, data)
        surface.PlaySound("buttons/blip1.wav")  -- Selection sound
        chat.AddText(Color(100, 255, 100), "[Demo] You selected: " .. value)
    end
    
    -- Custom styled buttons
    local yPos = 110
    
    for i = 1, 3 do
        local btn = vgui.Create("DButton", content)
        btn:SetPos(20, yPos)
        btn:SetSize(250, 50)
        btn:SetText("")
        btn.label = "Custom Button " .. i
        btn.isHovered = false
        btn.pressAnim = 0
        
        function btn:Paint(w, h)
            -- Animate press effect
            self.pressAnim = Lerp(FrameTime() * 10, self.pressAnim, 0)
            
            local col
            if self.isHovered then
                col = Color(100, 200, 255)
            else
                col = Color(70, 150, 220)
            end
            
            -- Draw button with slight press offset
            local offset = self.pressAnim
            draw.RoundedBox(8, offset, offset, w - offset, h - offset, col)
            
            -- Shine effect on top half
            draw.RoundedBoxEx(8, offset, offset, w - offset, (h - offset) / 2, Color(255, 255, 255, 30), true, true, false, false)
            
            -- Border
            surface.SetDrawColor(255, 255, 255, 100)
            surface.DrawOutlinedRect(offset, offset, w - offset, h - offset, 1)
            
            -- Text with shadow
            draw.SimpleText(self.label, "DermaDefault", w / 2 + 1, h / 2 + 1, Color(0, 0, 0, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(self.label, "DermaDefault", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            return false
        end
        
        function btn:OnCursorEntered()
            self.isHovered = true
            surface.PlaySound("buttons/lightswitch2.wav")  -- Beep on hover
        end
        
        function btn:OnCursorExited()
            self.isHovered = false
        end
        
        function btn:DoClick()
            self.pressAnim = 3  -- Press animation
            surface.PlaySound("buttons/button14.wav")  -- Click sound
            chat.AddText(Color(100, 255, 100), "[Demo] Clicked: " .. self.label)
        end
        
        yPos = yPos + 60
    end
    
    -- "Craft" button example (special styling)
    local craftBtn = vgui.Create("DButton", content)
    craftBtn:SetPos(content:GetWide() - 170, content:GetTall() - 60)
    craftBtn:SetSize(150, 50)
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
        
        -- Text
        draw.SimpleText("CRAFT!", "DermaLarge", w / 2 + 1, h / 2 + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("CRAFT!", "DermaLarge", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
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
        chat.AddText(Color(255, 215, 0), "[Demo] ✦ Crafting initiated! ✦")
    end
end

-- Console command to open demo
concommand.Add("tdmrp_customui_demo", function()
    CreateCustomStyledDemo()
end)

print("[TDMRP] Custom UI Demo loaded. Use console command: tdmrp_customui_demo")
