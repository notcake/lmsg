local PROG = SYSTEM:CreateProgram ("players", "Displays a list of players.")

function PROG:Main (commandline, args)
	local players = player.GetAll ()
	self.StdOut:Write ("NAME                  STEAMID\n")
	for k, v in pairs (players) do
		local name = tostring (v:Name ())
		name = name .. string.rep (" ", 20 - name:len ())
		self.StdOut:Write (name .. "  " .. v:SteamID () .. "\n")
	end
	self:Terminate ()
end