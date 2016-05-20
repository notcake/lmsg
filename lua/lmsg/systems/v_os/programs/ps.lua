local PROGRAM = SYSTEM:CreateProgram ("ps", "Displays a list of processes.")

function PROGRAM:Main (commandLine, argumentList)
	local processList = self:GetComputer ():GetProcesses ()
	self.StdOut:Write ("  PID  NAME\n")
	for k, v in pairs (processList) do
		local processID = tostring (k)
		processID = string.rep (" ", 5 - processID:len ()) .. processID
		self.StdOut:Write (processID .. "  " .. v:GetProgramName () .. "\n")
	end
	self:Terminate ()
end