local PROGRAM = SYSTEM:CreateProgram ("help", "Displays a list of commands.")

function PROGRAM:Main (commandLine, argumentList)
	for _, program in pairs (self:GetComputer ():GetGlobalProgramList ()) do
		self.StdOut:Write (program:GetProgramName () .. " - " .. program:GetProgramDescription () .. "\n")
	end
	self:Terminate ()
end