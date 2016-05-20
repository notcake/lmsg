local PANEL = {}
local SYSTEM = SYSTEM

function PANEL:Init ()
	self:SetTitle ("Chat Buffer")

	self:SetSize (ScrW () * 0.75, ScrH () * 0.75)
	self:SetPos ((ScrW () - self:GetWide ()) / 2, (ScrH () - self:GetTall ()) / 2)
	self:SetDeleteOnClose (false)
	self:SetSizable (true)
	self:MakePopup ()

	self.btnAdd = vgui.Create ("DButton", self)
	self.btnAdd:SetText ("Add")
	self.btnAdd.DoClick = function (button)
		local selection = self.lvwSentences:GetSelected ()
		for _, line in pairs (selection) do
			local sentence = line:GetValue (1)
			SYSTEM:ProcessText (sentence)
		end
		for _, line in pairs (selection) do
			self.lvwSentences:RemoveLine (line:GetID ())
		end
	end

	self.btnExit = vgui.Create ("DButton", self)
	self.btnExit:SetText ("Close")
	self.btnExit.DoClick = function (button)
		self:SetVisible (false)
	end

	self.lvwSentences = vgui.Create ("DListView", self)
	self.lvwSentences:AddColumn ("Sentence")

	self:SetVisible (false)
end

function PANEL:PerformLayout ()
	local margins = 5
	self.btnAdd:SetPos (0 + margins, self:GetTall () - self.btnAdd:GetTall () - margins)
	self.btnExit:SetPos (self:GetWide () - self.btnExit:GetWide () - margins, self:GetTall () - self.btnExit:GetTall () - margins)
	self.lvwSentences:SetPos (0 + margins, 24 + margins)
	self.lvwSentences:SetSize (self:GetWide () - 2 * margins, self:GetTall () - 24 - 3 * margins - self.btnExit:GetTall ())
	DFrame.PerformLayout (self)
end

function PANEL:AddToBuffer (ply, text)
	self.lvwSentences:AddLine (text)
end

SYSTEM:AddCommand ("buffer", function (self, ply)
	self.BufferPanel:SetVisible (true)
end)

timer.Simple (0.1, function ()
	vgui.Register ("LMsgChatBuffer", PANEL, "DFrame")
	SYSTEM.BufferPanel = vgui.Create ("LMsgChatBuffer")
end)