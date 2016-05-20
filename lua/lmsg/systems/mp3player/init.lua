local SYSTEM = LMsg.CreateSystem ("MP3 Player")
SYSTEM.Autorun = true
SYSTEM.SoundList = {}
SYSTEM.FoldersToAdd = {}

function SYSTEM:PushMP3 (mp3)
	if self:IsReceiverActive () then
		LMsg.Messages.AddSystemString (self.Name, mp3)
	end
end

function SYSTEM:StartPopulatingMP3s ()
	if !self.FoldersToAdd or table.GetFirstKey (self.FoldersToAdd) then
		return
	end
	self.FoldersToAdd [""] = true
	self:AddTimer ("PopulateMP3s", 2, 0, function (self)
		local Folder = table.GetFirstKey (self.FoldersToAdd)
		if Folder then
			self.FoldersToAdd [Folder] = nil
			local files = file.Find ("../sound/" .. Folder .. "*")
			for k, v in pairs (files) do
				local ext = string.GetExtensionFromFilename (v)
				if string.lower (ext) == "mp3" or
				   string.lower (ext) == "wav" then
					table.insert (self.SoundList, Folder .. v)
				elseif !ext or string.len (ext) == 0 then
					self.FoldersToAdd [Folder .. v .. "/"] = true
				end
			end
		else
			self.FoldersToAdd = nil
			self:RemoveTimer ("PopulateMP3s")
		end
	end)
end

function SYSTEM:StartSendingMP3s ()
	self.NextToSend = 1
	self:AddTimer ("SendMP3s", 0.01, 0, function (self)
		local send = self.SoundList [self.NextToSend]
		if send then
			self:PushMP3 (send)
			self.NextToSend = self.NextToSend + 1
		else
			if !self.FoldersToAdd then
				self:RemoveTimer ("SendMP3s")
			end
		end
	end)
end

SYSTEM:AddCommand ("getmp3list", function (self, ply)
	self:StartPopulatingMP3s ()
	self:StartSendingMP3s ()
end)