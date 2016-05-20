local PROG = SYSTEM:CreateProgram ("date", "Displays the time and date.")

function PROG:Main (commandline, args)
	self.StdOut:Write (os.date ("%H:%M:%S %d/%m/20%y") .. "\n")
	self:Terminate ()
end