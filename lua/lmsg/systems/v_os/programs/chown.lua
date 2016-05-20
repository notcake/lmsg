local PROGRAM = SYSTEM:CreateProgram ("chown", "Not implemented.")

function PROGRAM:Main (commandLine, argumentList)
	self.StdOut:Write ("Command not implemented.\n")
	self:Terminate ()
end