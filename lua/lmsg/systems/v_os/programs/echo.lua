local PROG = SYSTEM:CreateProgram ("echo", "Displays a message on the screen.")

function PROG:Main (commandLine, argumentList)
	argumentList = self:GetComputer ():ParseTerminalCommand (commandLine, 2)
	self.StdOut:Write (argumentList [2] .. "\n")
	self:Terminate ()
end