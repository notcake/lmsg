local PROGRAM = SYSTEM:CreateProgram ("dir", "Lists directory contents.")

function PROGRAM:Main (commandLine, argumentList)
	local directoryItem = self:GetComputer ():GetFileSystem ():GetDirectoryItem (self:GetComputer ():GetCurrentDirectory ())
	if directoryItem then
		local directoryItemCount = directoryItem:GetChildCount ()
		self.StdOut:Write (tostring (directoryItemCount) .. " objects in directory.\n")
		local children = directoryItem:GetChildren ()
		for childName, child in pairs (children) do
			childName = childName .. string.rep (" ", 32 - childName:len ())
			if child:IsFolder () then
				childName = childName .. "<dir>"
			end
			self.StdOut:Write (childName .. "\n")
		end
	else
		self.StdOut:Write ("Current directory is invalid.\n")
	end
	self:Terminate ()
end