LMsg.RequireInclude ("hooks")
LMsg.RequireInclude ("games")

local SYSTEMSPANEL = {}

function SYSTEMSPANEL:Init ()
	self:SetTitle ("Lua Systems")

	self:SetSize (ScrW () * 0.75, ScrH () * 0.75)
	self:SetPos ((ScrW () - self:GetWide ()) / 2, (ScrH () - self:GetTall ()) / 2)
	self:SetDeleteOnClose (false)
	self:SetSizable (true)
	self:MakePopup ()

	self.btnStart = vgui.Create ("DButton", self)
	self.btnStart:SetText ("Start")
	self.btnStart.DoClick = function (button)
		local line = self.lvwSystems:GetLine (self.lvwSystems:GetSelectedLine ())
		if line then
			LMsg.StartSystem (line:GetValue (1))
			local running = ""
			if LMsg.Systems [line:GetValue (1)]:IsRunning () then
				running = "Yes"
			end
			line:SetValue (2, running)
		end
	end

	self.btnStop = vgui.Create ("DButton", self)
	self.btnStop:SetText ("Stop")
	self.btnStop.DoClick = function (button)
		local line = self.lvwSystems:GetLine (self.lvwSystems:GetSelectedLine ())
		if line then
			LMsg.StopSystem (line:GetValue (1))
			local running = ""
			if LMsg.Systems [line:GetValue (1)]:IsRunning () then
				running = "Yes"
			end
			line:SetValue (2, running)
		end
	end

	self.btnExit = vgui.Create ("DButton", self)
	self.btnExit:SetText ("Close")
	self.btnExit.DoClick = function (button)
		self:SetVisible (false)
	end

	self.lvwSystems = vgui.Create ("DListView", self)
	self.lvwSystems:AddColumn ("System Name")
	self.lvwSystems:AddColumn ("Running")
	self.lvwSystems:SetMultiSelect (false)

	self:SetVisible (false)
	self:Populate ()
end

function SYSTEMSPANEL:PerformLayout ()
	local margins = 5
	self.btnStart:SetPos (0 + margins, self:GetTall () - self.btnStart:GetTall () - margins)
	self.btnStop:SetPos (0 + 2 * margins + self.btnStart:GetWide (), self:GetTall () - self.btnStop:GetTall () - margins)
	self.btnExit:SetPos (self:GetWide () - self.btnExit:GetWide () - margins, self:GetTall () - self.btnExit:GetTall () - margins)
	self.lvwSystems:SetPos (0 + margins, 24 + margins)
	self.lvwSystems:SetSize (self:GetWide () - 2 * margins, self:GetTall () - 24 - 3 * margins - self.btnExit:GetTall ())
	DFrame.PerformLayout (self)
end

function SYSTEMSPANEL:Populate ()
	self.lvwSystems:Clear ()
	for k, v in pairs (LMsg.Systems) do
		local running = ""
		if v:IsRunning () then
			running = "Yes"
		end
		self.lvwSystems:AddLine (k, running)
	end
end

LMsg.Hooks.Add ("Initialize", "LMsg.SystemMenuInitialize", function ()
	vgui.Register ("LMsgSystemsList", SYSTEMSPANEL, "DFrame")
	LMsg.SystemMenuPanel = vgui.Create ("LMsgSystemsList")
end)

LMsg.Hooks.Add ("Uninitialize", "Vgame.SystemMenuUninitialize", function ()
	if LMsg.SystemMenuPanel then
		LMsg.SystemMenuPanel:Remove ()
		LMsg.SystemMenuPanel = nil
	end
end)

concommand.Add ("lmsg_opensystemsmenu", function ()
	LMsg.SystemMenuPanel:SetVisible (true)
end)

LMsg.Hooks.Add ("PopulateLMsgMenu", "LMsg.SystemMenu", function (Panel)
	Panel:AddControl ("Button", {Label = "Systems List", Command = "lmsg_opensystemsmenu"})
end)