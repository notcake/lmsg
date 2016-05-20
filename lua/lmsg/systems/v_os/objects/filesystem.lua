local OBJ = LMsg.Objects.Register ("V OS FileSystem")

function OBJ:__init ()
	self.Root = LMsg.Objects.Create ("V OS Directory Item", "")
	local dev = self.Root:AddChild ("dev")
	local home = self.Root:AddChild ("home")
		home:AddChild ("file1")
		home:AddChild ("file2")
		home:AddChild ("file3")
	local usr = self.Root:AddChild ("usr")
end

function OBJ:__uninit ()
	self.Root:__uninit ()
	self.Root = nil
end

function OBJ:FileExists (path)
	if self:GetDirectoryItem (path) then
		return true
	end
	return false
end

function OBJ:PathExists (path)
	if self:GetDirectoryItem (path) then
		return true
	end
	return false
end

function OBJ:GetDirectoryItem (path)
	local path = LMsg.Objects.Create ("Path", path)
	local partCount = path:GetPartCount ()
	local directoryItem = self.Root
	for i = 2, partCount do
		directoryItem = directoryItem:GetChild (path:GetPart (i))
		if not directoryItem then
			return nil
		end
	end
	return directoryItem
end