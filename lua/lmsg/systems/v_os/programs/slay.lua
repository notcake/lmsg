local PROG = SYSTEM:CreateProgram ("slay", "Slays a player.")

function PROG:Main (commandline, args)
	RunConsoleCommand ("cadmin", "slay", args [2])
	self:Terminate ()
end