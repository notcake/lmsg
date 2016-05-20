local PROGRAM = SYSTEM:CreateProgram ("chmod", "Not implemented.")

function PROGRAM:Main (commandLine, argumentList)
	self.StdOut:Write ("Command not implemented.\n")
	self:Terminate ()
end