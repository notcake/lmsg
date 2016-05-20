local SYSTEM = LMsg.CreateSystem ("Chat")
SYSTEM.Autorun = true

SYSTEM.OpenedFile = ""
SYSTEM.StartWord = "_"
SYSTEM.Terminators = {
	["."] = true,
	["?"] = true,
	["!"] = true
}
SYSTEM.TerminatorsRegex = "[.!?]"
SYSTEM.WordCount = 0;
SYSTEM.Words = {}

SYSTEM.FileName = "chat.txt"

-- Buffer
SYSTEM.BufferPanel = nil

_G.SYSTEM = SYSTEM
LMsg.Lua.Include ("systems/chat/buffer.lua")
_G.SYSTEM = nil


--[[
	Sample word entry:
	The {
		Count = 3
		Words = {
			pie = 2
			end = 1
		}
	}
]]

function SYSTEM:Start ()
	self:AddHook ("OnPlayerChat", "ProcessSentence", function (_, ply, text, isTeamChat, isPlayerDead)
		if self.BufferPanel then
			self.BufferPanel:AddToBuffer (ply, text)
		end
	end)
	
	local fileData = file.Read (self:GetSavePath ("chat"))
	if fileData then
		local tblData = util.KeyValuesToTable (fileData)
		self.WordCount = tblData.wordcount
		self.Words = {}
		for k, v in pairs (tblData.words) do
			local currentWord = v.word
			self.Words [currentWord] = {
				Count = v.count,
				Words = {}
			}
			for k, v in pairs (v.words) do
				self.Words [currentWord].Words [v.word] = v.weight
			end
		end
	end
end

function SYSTEM:Stop ()
	if self.BufferPanel then
		self.BufferPanel:Remove ()
		self.BufferPanel = nil
	end
	-- Save to file
	local fileData = "\"Chat\" {\n"
	fileData = fileData .. "\t\"WordCount\"\t\"" .. tostring (self.WordCount) .. "\"\n"
	fileData = fileData .. "\t\"Words\"\t{\n"
	local index = 1
	for k, v in pairs (self.Words) do
		fileData = fileData .. "\t\t\"" .. tostring (index) .. "\" {\n"
		fileData = fileData .. "\t\t\t\"Word\"\t\"" .. k .. "\"\n"
		fileData = fileData .. "\t\t\t\"Count\"\t\"" .. tostring (v.Count) .. "\"\n"
		fileData = fileData .. "\t\t\t\"Words\"\t{\n"
		local windex = 1
		for k, v in pairs (v.Words) do
			fileData = fileData .. "\t\t\t\t\"" .. tostring (windex) .. "\" {\n"
			fileData = fileData .. "\t\t\t\t\t\"Word\"\t\"" .. k .. "\"\n"
			fileData = fileData .. "\t\t\t\t\t\"Weight\"\t\"" .. tostring (v) .. "\"\n"
			fileData = fileData .. "\t\t\t\t}\n"
			windex = windex + 1
		end
		fileData = fileData .. "\t\t\t}\n"
		fileData = fileData .. "\t\t}\n"
		index = index + 1
	end
	fileData = fileData .. "\t}\n"
	fileData = fileData .. "}\n"
	
	file.Write (self:GetSavePath ("chat"), fileData)
end

function SYSTEM:AddWordLink (w1, w2)
	if not self.Words [w1] then
		self.Words [w1] = {
							Count = 0,
							Words = {}
						}
		self.WordCount = self.WordCount + 1
	end
	self.Words [w1].Count = self.Words [w1].Count + 1
	if not self.Words [w1].Words [w2] then
		self.Words [w1].Words [w2] = 0
	end
	self.Words [w1].Words [w2] = self.Words [w1].Words [w2] + 1
end

function SYSTEM:GenerateSentence ()
	if self.WordCount == 0 then
		return "Error: No words in database!"
	end
	local words = {}
	local baseWord = self.StartWord
	while not self.Terminators [baseWord] do
		if baseWord ~= self.StartWord then
			words [#words + 1] = baseWord
		end
		local wordIndex = math.random (1, self.Words [baseWord].Count)
		local i = 1
		for word, num in pairs (self.Words [baseWord].Words) do
			if i + num > wordIndex then
				baseWord = word
				break
			end
			i = i + num
		end
	end
	return table.concat (words, " ") .. baseWord
end

function SYSTEM:SendText (text)
	local tblData = {
		type = "text",
		text = text
	}
	local glonData = glon.encode ({glon.encode (LMsg.Messages.GLONE2Encode (tblData))})
	--[[
	datastream.StreamToServer ("wire_expression2_filedata", {
																filename = "chat.txt",
																filedata = glonData
															})
	]]
	LMsg.E2UploadFile ("chat.txt", glonData)
end

function SYSTEM:ProcessText (text)
	local strPunctuation = string.Right (text, 1)
	if not self.Terminators [strPunctuation] then
		strPunctuation = "."
	else
		text = text:sub (1, text:len () - 1):Trim ()
	end
	local words = string.Explode (" ", text)
	self:AddWordLink (self.StartWord, words [1])
	for i = 1, #words - 1 do
		self:AddWordLink (words [i], words [i + 1])
	end
	self:AddWordLink (words [#words], strPunctuation)
end

SYSTEM:AddCommand ("chat", function (self, ply)
	self:SendText (self:GenerateSentence ())
end)

SYSTEM:AddCommand ("add", function (self, ply, sentence)
	if self.BufferPanel then
		self.BufferPanel:AddToBuffer (ply, sentence)
	end
end)

SYSTEM:AddCommand ("file", function (self, ply, file)
	self.FileName = file
end)