local OBJ = LMsg.Objects.Register ("Path")

--[[
	Note: Forward slashes are used throughout.
]]

function OBJ:__init (path)
	self:Set (path)
end

function OBJ:__uninit ()
	self.FullPath = nil
	self.PathParts = nil
end

function OBJ:AppendPart (part)
	if not part then
		return
	end
	
	part = part:gsub ("\\", "/")
	local appendSlash = false
	if part:sub (1, 1) == "/" then
		part = part:sub (2)
	end
	if string.Right (part, 1) == "/" then
		part = part:sub (1, part:len () - 1)
		appendSlash = true
	end
	if string.Right (self.FullPath, 1) == "/" then
		self.FullPath = self.FullPath:sub (1, self.FullPath:len () - 1)
		appendSlash = true
	end
	
	if part == "" then
		return self
	end
	if part == "." then
		return self
	end
	if part == ".." then
		self.FullPath = self.FullPath:sub (1, self.FullPath:len () - self.PathParts [#self.PathParts]:len ())
		self.PathParts [#self.PathParts] = nil
		return self
	end
	self.PathParts [#self.PathParts + 1] = part
	self.FullPath = self.FullPath .. "/" .. part
	if appendSlash then
		self.FullPath = self.FullPath .. "/"
	end
	
	return self
end

function OBJ:GetPart (partIndex)
	return self.PathParts [partIndex]
end

function OBJ:GetPartCount ()
	return #self.PathParts
end

function OBJ:Set (path)
	local failed = false
	if type (path) == "string" then
		path = path:gsub ("\\", "/")
		
		self.PathParts = string.Explode ("/", path)
		if self.PathParts [#self.PathParts] == "" then
			self.PathParts [#self.PathParts] = nil
		end
		self.FullPath = path
	elseif type (path) == "table" then
		if path.PathParts and path.FullPath then
			self.PathParts = table.Copy (path.PathParts)
			self.FullPath = path.FullPath
		else
			failed = true
		end
	else
		failed = true
	end
	if failed then
		CAdmin.Debug.PrintStackTrace ()
	end
end

function OBJ:__tostring ()
	return self.FullPath
end