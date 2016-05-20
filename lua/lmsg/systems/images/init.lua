local SYSTEM = LMsg.CreateSystem ("Images")
SYSTEM.Autorun = true

SYSTEM.OpenedFile = ""

SYSTEM.Data = ""
SYSTEM.DataSize = 0
SYSTEM.DoneExploding = true
SYSTEM.ExplodeCount = 0
SYSTEM.ExplodeCounter = 0
SYSTEM.ExplodeBit = ""
SYSTEM.ExplodeOffset = 1

SYSTEM.Offset = 0
SYSTEM.Offsets = {}
SYSTEM.Count = 0
SYSTEM.Width = 0
SYSTEM.Height = 0

SYSTEM.BatchSize = 250

SYSTEM.Percentage = 0

SYSTEM.SentData = {}

function SYSTEM:Start ()
end

function SYSTEM:Stop ()
	self.StartupHooks = {}
	self:RemoveTimer ("Explode")
end

function SYSTEM:StartExploding ()
	self.ExplodeBit = ""
	self.DoneExploding = false
	self:AddTimer ("Explode", 1, 0, self.ExplodeSomeMore)

	local str = ""
	local offset = 1
	local i = 0
	while i < 2 do
		local c = self.Data:sub (offset, offset)
		if c == " " or c == "" then
			if i == 0 then
				self.Width = tonumber (str)
			else
				self.Height = tonumber (str)
			end
			i = i + 1
			str = ""
		else
			str = str .. c
		end
		offset = offset + 1
	end

	table.Empty (self.Offsets)
	table.Empty (self.SentData)

	self.Offsets [1] = {
		FileOffset = offset,
		DataOffset = 0
	}
	while self.Data:sub (offset, offset) == " " do
		offset = offset + 1
		self.ExplodeOffset = offset
		self.Offsets [1].FileOffset = offset
	end
	self.Offsets [1].FileOffset = self.Offsets [1].FileOffset - 1
	self.Count = 1
	self.ExplodeOffset = offset + 1
	self.ExplodeCount = 0
	self.ExplodeCounter = 0
end

function SYSTEM:ExplodeSomeMore ()
	for i = 1, 50000 do
		local c = self.Data:sub (self.ExplodeOffset, self.ExplodeOffset)
		if c == " " or c == "" then
			self.ExplodeCount = self.ExplodeCount + 1
			self.ExplodeCounter = self.ExplodeCounter + 1
			if self.ExplodeCounter >= self.BatchSize or c == "" then
				self.ExplodeCounter = 0
				table.insert (self.Offsets, {FileOffset = self.ExplodeOffset, DataOffset = self.ExplodeCount})
				self.Count = self.Count + 1
			end
		end

		if self.ExplodeOffset > self.DataSize then
			self.DoneExploding = true
			self:RemoveTimer ("Explode")
			return
		end
		self.ExplodeOffset = self.ExplodeOffset + 1
	end
end

function SYSTEM:DoAck ()
	self:RemoveTimer ("DelayedAck")
	if self.Offset + 1 > self.Count then
		if not self.DoneExploding then
			self:AddTimer ("DelayedAck", 1, 0, self.DoAck)
		end
		return
	end
	local first = self.Offsets [self.Offset]
	local second = self.Offsets [self.Offset + 1]
	local data = tostring (first.DataOffset) .. " " .. self.Data:sub (first.FileOffset + 1, second.FileOffset - 1)
	self.Offset = self.Offset + 1

	--[[
	datastream.StreamToServer ("wire_expression2_filedata", {
		filename = "image.txt", filedata = data
	})
	]]
	LMsg.E2UploadFile ("image.txt", data)
	table.insert (self.SentData, "\"" .. data .. "\"")
	local pixelCount = second.DataOffset - first.DataOffset
	local startOffset = first.DataOffset
	Msg ("Sent " .. pixelCount .. " values starting at offset " .. tostring (startOffset) .. " (size " .. tostring (data:len ()) .. ")\n")
	self.Percentage = self.Offset / self.Count
	
	timer.Simple (0.5, function ()
		self:DoAck ()
	end)
end

SYSTEM:AddCommand ("ack", function (self, ply)
	self:DoAck ()
end)

SYSTEM:AddCommand ("open", function (self, ply, img)
	Msg ("Opening " .. img .. ".txt.\n")
	self.OpenedFile = img
	self.Data = file.Read (self:GetSavePath (img))
	self.DataSize = self.Data:len ()
	self:StartExploding ()
end)

SYSTEM:AddCommand ("progress", function (self, ply)
	Msg ("Image send progress: " .. tostring (self.Percentage * 100) .. "%.\n")
end)

SYSTEM:AddCommand ("recv", function (self, ply)
	Msg ("Received image request.\n")

	self.Offset = 1

	LMsg.Messages.AddSystemTable (self:GetSystemName (), "size", {w = self.Width, h = self.Height})
end)