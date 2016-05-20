local PROGRAM = SYSTEM:CreateProgram ("cd", "Change directory.")

function PROGRAM:Main (commandLine, argumentList)
	local newDirectory = self:GetComputer ():GetCurrentDirectory ():AppendPart (argumentList [2])
	if self:GetComputer ():GetFileSystem ():FileExists (newDirectory) then
		self:GetComputer ():SetCurrentDirectory (newDirectory)
	else
		self.StdOut:Write ("\"" .. argumentList [2] .. "\" is not a directory or does not exist.\n")
	end
	self:Terminate ()
end