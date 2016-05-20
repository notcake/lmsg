local SYSTEM = LMsg.CreateSystem ("Roleplay")

function SYSTEM:PlayerCanRunCommand (ply, cmd, args)
	if self.ActivePlayers [ply:SteamID ()] or cmd == "join" then
		return true
	else
		return false
	end
end

SYSTEM:AddHook ("Initialize", "Roleplay.Initialize", function (_)
	LMsg.Messages.AddChatAll ("Roleplay initialized. Type /join to join.")
end)

SYSTEM:AddCommand ("join", function (self, ply)
	self:AddPlayer (ply)
end)

SYSTEM:AddCommand ("quit", function (self, ply)
	self:RemovePlayer (ply)
end)

SYSTEM:AddCommand ("players", function (self, ply)
	local list = nil
	for k, v in pairs (self.ActivePlayers) do
		local name = v:Name ()
		if v:EntIndex () == ply:EntIndex () then
			name = "you"
		end
		if list then
			list = list .. ", " .. name
		else
			list = name
		end
	end
	list = list or "none"
	LMsg.Messages.AddChat (ply, "Players in the game: " .. list .. ".")
end)

function SYSTEM:SetupPlayer (steamid)
	self.Players [steamid].Money = 800
	self.Players [steamid].BankMoney = 0
	self.Players [steamid].Job = "Unemployed"
	self.Players [steamid].Inventory = {}
end

SYSTEM:AddHook ("PlayerJoined", "RP.PlayerJoined", function (self, steamid, ply)
	for k, v in pairs (self.ActivePlayers) do
		if k == steamid then
			LMsg.Messages.AddChat (v, "You joined the game.")
			LMsg.Messages.AddChat (v, "/help lists commands.")
		else
			LMsg.Messages.AddChat (v, self.Players [steamid].Name .. " has joined the game.")
		end
	end
end)

SYSTEM:AddHook ("PlayerLeft", "RP.PlayerLeft", function (self, steamid)
	for k, v in pairs (self.ActivePlayers) do
		if k == steamid then
			LMsg.Messages.AddChat (v, "You left the game.")
		else
			LMsg.Messages.AddChat (v, self.Players [steamid].Name .. " has left the game.")
		end
	end
end)