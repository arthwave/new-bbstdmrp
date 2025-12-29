ddCSLuaFile()

local CSR = {}

if SERVER then
	util.AddNetworkString("CheckForCSS")
end

function CheckForCSS()
	local EnumNag = 0
	for k,v in pairs(engine.GetGames()) do
		if v.depot == 240 then
			if !v.owned then EnumNag = EnumNag + 1 end
			if !v.mounted then EnumNag = EnumNag + 2 end
			if !v.installed then EnumNag = EnumNag + 4 end
			break
		end
	end
	if EnumNag > 0 then CSSNag(EnumNag) end
end

if SERVER then
	if !ConVarExists("sv_csr_css_nag") then
		CSR.Nag = CreateConVar("sv_csr_css_nag", "1", {FCVAR_ARCHIVE})
	end
	
	function CSSNag(enum)
		if (!CSR.Nag:GetBool()) then return end
		local msg = ""
		if enum == 0 then
			msg = "You own css, it's installed and mounted, you're good."
		end
		if enum == 1 then
			msg = "You do not own CSS!" -- Shouldn't ever get this message?
		end
		if enum == 2 then
			msg = "You do not have CSS mounted!"
		end
		if enum == 3 then
			msg = "You do not own CSS!" -- Shouldn't ever get this message?
		end
		if enum == 4 then
			msg = "You do not have CSS installed!" -- Shouldn't ever get this message?
		end
		if enum == 5 then
			msg = "You do not own CSS!" -- Shouldn't ever get this message?
		end
		if enum == 6 then
			msg = "You do not have CSS installed and mounted!"
		end
		if enum == 7 then
			msg = "You do not own CSS!"
		end
		if string.Trim(msg) == "" then return end
		MsgN("[CSS Realistic] " .. msg .. " CSS realistic weapons may not function properly!")
	end

	hook.Add("Initialize", "CheckForCSSInit", function() if (!CSR.Nag:GetBool()) then return end CheckForCSS() end)
	hook.Add("PlayerInitialSpawn", "CheckForCSSPIS", function(ply)
		if (!CSR.Nag:GetBool()) then return end
		net.Start("CheckForCSS")
			net.WriteTable({})
		net.Send(ply)
	end)
end

if CLIENT then
	if (!ConVarExists("cl_csr_css_nag")) then
		CSR.Nag = CreateConVar("cl_csr_css_nag", "1", {FCVAR_CLIENT, FCVAR_ARCHIVE})
	end

	function CSSNag(enum)
		if (!CSR.Nag:GetBool()) then return end
		local msg = ""
		if enum == 0 then
			msg = "You own css, it's installed and mounted, you're good."
		end
		if enum == 1 then
			msg = "You do not own CSS!" -- Shouldn't ever get this message?
		end
		if enum == 2 then
			msg = "You do not have CSS mounted!"
		end
		if enum == 3 then 
			msg = "You do not own CSS!" -- Shouldn't ever get this message?
		end
		if enum == 4 then
			msg = "You do not have CSS installed!" -- Shouldn't ever get this message?
		end
		if enum == 5 then 
			msg = "You do not own CSS!" -- Shouldn't ever get this message?
		end
		if enum == 6 then
			msg = "You do not have CSS installed and mounted!"
		end
		if enum == 7 then
			msg = "You do not own CSS!"
		end
		if string.Trim(msg) == "" then return end
		MsgN("[CSS Realistic] " .. msg .. " CSS realistic weapons may not function properly!")
		CreateCSSNagScreen(msg)
	end

	function CreateCSSNagScreen(msg)
		if (!CSR.Nag:GetBool()) then return end

		local NagPanel = vgui.Create("DFrame")
		NagPanel:SetSize(300, 100)
		NagPanel:SetPos(ScrW()/2-150, ScrH()/2-50) -- Sets frame position to center of screen.
		NagPanel:SetTitle("CSS ain't working right!")
		NagPanel:ShowCloseButton(false)
		NagPanel:SetDeleteOnClose(true)
		NagPanel:SetDraggable(true)
		NagPanel:SetVisible(true)
		NagPanel:MakePopup()

		local NagLabel = vgui.Create("DLabel")
		NagLabel:SetParent(NagPanel)
		NagLabel:SetPos(5, 26)
		NagLabel:SetText(msg)
		NagLabel:SizeToContents()
		NagLabel:CenterHorizontal()

		local NagLabel2 = vgui.Create("DLabel")
		NagLabel2:SetParent(NagPanel)
		NagLabel2:SetPos(5, 40)
		NagLabel2:SetText("CSS realistic weapons may not function properly!")
		NagLabel2:SizeToContents()
		NagLabel2:CenterHorizontal()

		local ButtonLabel = vgui.Create("DLabel")
		ButtonLabel:SetParent(NagPanel)
		ButtonLabel:SetPos(5, 54)
		ButtonLabel:SetText("Click OK to agree that you're willing to use broken-ish guns!")
		ButtonLabel:SizeToContents()
		ButtonLabel:CenterHorizontal()

		local OKButton = vgui.Create("DButton")
		OKButton:SetParent(NagPanel)
		OKButton:SetText("Ok then.")
		OKButton:SetSize(50, 20)
		//if !game.SinglePlayer() then
		//	OKButton:SetPos(25, 72)
		//	OKButton:CenterHorizontal()
		//else
			OKButton:SetPos(25, 72)
		//end
		OKButton.DoClick = function() NagPanel:Close() end
		
		//if game.SinglePlayer() then
			local OKButton = vgui.Create("DButton")
			OKButton:SetParent(NagPanel)
			OKButton:SetPos(85, 72)
			OKButton:SetSize(193, 20)
			OKButton:SetText("Nope, disconnect me.")
			OKButton.DoClick = function() NagPanel:Close() RunConsoleCommand("disconnect") end //BreakCSSGuns() end
		//end
	end

	CreateClientConVar("cl_csr_css_nag", "1", true, false)

	net.Receive("CheckForCSS", CheckForCSS)
endf