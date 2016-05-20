local OBJ = LMsg.Objects.Register ("V OS Directory Item")
OBJ.ITEM_FOLDER = 1
OBJ.ITEM_FILE = 2

function OBJ:__init (fileName)
	self.Type = self.ITEM_FOLDER
	self.Children = {}
	self.ChildCount = 0
	
	self.FileName = fileName
end

function OBJ:__uninit ()
	for fileName, childDirectoryItem in pairs (self.Children) do
		childDirectoryItem:__uninit ()
		self.Children [fileName] = nil
	end
	self.Children = nil
end

function OBJ:AddChild (fileName)
	if not self.Children [fileName] then
		self.Children [fileName] = LMsg.Objects.Create ("V OS Directory Item", fileName)
		self.ChildCount = self.ChildCount + 1
	end
	return self.Children [fileName]
end

function OBJ:GetChild (childName)
	return self.Children [childName]
end

function OBJ:GetChildCount ()
	return self.ChildCount
end

function OBJ:GetChildren ()
	return self.Children
end

function OBJ:GetName ()
	return self.FileName
end

function OBJ:IsFile ()
	return (self.Type & self.ITEM_FILE) ~= 0
end

function OBJ:IsFolder ()
	return (self.Type & self.ITEM_FOLDER) ~= 0
end