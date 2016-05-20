local SYSTEM = LMsg.CreateSystem ("Starcraft")
SYSTEM.Autorun = true

-- Clients
SYSTEM.NextClientID = 1
SYSTEM.Clients = {}			-- Client IDs to Clients
SYSTEM.EntityClients = {}	-- Entity IDs to Client IDs

-- Initialization and uninitialization
function SYSTEM:Start ()
	-- Networking
	self.NetworkPipe = LMsg.Objects.Create ("RTS Network Pipe", self:GetSystemName ())
	
	-- The system holds the game state, etc.
	self.RoundStarted = false
	
	self.GameEnvironment = LMsg.Objects.Create ("RTS Environment", self:GetSystemName ())
	
	self.ConsoleClient = self:CreateClient (-1, 0)

	self:AddTimer ("CheckClients", 1, 0, function (self)
		self:CheckClients ()
	end)
	
	self:AddTimer ("ClientHints", 0.2, 0, function (self)
		self:ProcessClientTraces ()
	end)
	
	self:AddTimer ("GameFrame", 0.5, 0, function (self)
		self.GameEnvironment:Think ()
	end)
end

function SYSTEM:Stop ()
	self:RemoveTimer ("CheckClients")
	self:RemoveTimer ("ClientHints")
	self:RemoveTimer ("GameFrame")
	
	if self.GameEnvironment then
		self.GameEnvironment:__uninit ()
		self.GameEnvironment = nil
	end

	self:DestroyClient (self.ConsoleClient)
	self.ConsoleClient = nil
	
	for clientID, client in pairs (self.Clients) do
		self.EntityClients [client:GetEntityID ()] = nil
		self.Clients [clientID] = nil
			
		client:__uninit ()
	end
	self.Clients = nil
	self.EntityClients = nil
	
	self.NetworkPipe:__uninit ()
	self.NetworkPipe = nil
end

function SYSTEM:CheckClients ()
	for clientID, client in pairs (self.Clients) do
		if not client:IsConnectionActive () then
			Msg ("Client " .. clientID .. " has timed out.\n")
			self.EntityClients [client:GetEntityID ()] = nil
			self.Clients [clientID] = nil
			
			client:__uninit ()
		end
	end
end

function SYSTEM:CreateClient (entityID, clientID)
	clientID = clientID or self:GenerateClientID ()
	self.EntityClients [entityID] = clientID
	local client = LMsg.Objects.Create ("RTS Client", entityID, clientID, LMsg.Objects.Create ("RTS Network Pipe", self:GetSystemName (), clientID))
	self.Clients [clientID] = client
	
	client:SetGameEnvironment (self.GameEnvironment)
	return client
end

function SYSTEM:DestroyAllClients ()
	Msg ("Starcraft system shutting down; all Clients destroyed.\n")
	for clientID, client in pairs (self:GetClients ()) do
		client:__uninit ()
	end
	self.Clients = {}
	self.EntityClients = {}
end

function SYSTEM:DestroyClient (client)
	self.EntityClients [client:GetEntityID ()] = nil
	self.Clients [client:GetClientID ()] = nil

	client:__uninit ()
end

function SYSTEM:EndRound ()
	if not self:IsInRound () then
		return
	end
	self.NetworkPipe:BroadcastMessage ("system_message", {message = "Round ended."})
	self.RoundStarted = false
end

function SYSTEM:GenerateClientID ()
	local clientID = self.NextClientID
	self.NextClientID = self.NextClientID + 1
	return clientID
end

function SYSTEM:GetClient (clientID)
	return self.Clients [clientID or 0]
end

function SYSTEM:GetClients ()
	return self.Clients
end

function SYSTEM:IsClientAdmin (client)
	if client:IsConsole () then
		return true
	end
	local clientPlayer = client:GetPlayer ()
	if not clientPlayer then
		return false
	end
	if clientPlayer == LocalPlayer () then
		return true
	end
	return false
end

function SYSTEM:IsInRound ()
	return self.RoundStarted
end

function SYSTEM:ProcessClientTraces ()
	for clientID, client in pairs (self.Clients) do
		local player = client:GetPlayer ()
		if player then
			client:DoClientTrace (self.GameEnvironment)
		end
	end
end

function SYSTEM:StartRound ()
	if self:IsInRound () then
		return
	end
	self.RoundStarted = true
	self.NetworkPipe:BroadcastMessage ("system_message", {message = "Gathering world data..."})
	self.GameEnvironment:GatherWorldData (self:GetClients ())
end

SYSTEM:AddCommand ("ping", function (self, ply, arguments, clientID, entityID)
	if not clientID or not entityID then
		return
	end
	clientID = tonumber (clientID)
	entityID = tonumber (entityID)
	local client = self:GetClient (clientID)
	if client and client:GetEntityID () == entityID then
		client:ProcessConnectionPing ()
	else
		if not self.EntityClients [entityID] then
			self:CreateClient (entityID)
		end
	end
end)

SYSTEM:AddCommand ("rts", function (self, ply, arguments, clientID, command, ...)
	if command ~= "ping" then
		Msg ("RTS received command " .. arguments .. "\n")
	end
	self:ForwardCommand (command, ply, arguments, clientID, ...)
end)

SYSTEM:AddCommand ("rts_add_base", function (self, ply, arguments, clientID, x, y, z)
	clientID = tonumber (clientID)
	x = tonumber (x)
	y = tonumber (y)
	z = tonumber (z)
	local client = self:GetClient (clientID)
	if client:IsConsole () then
		return
	end
	if not client:IsInGame () then
		client:JoinGame ()
	end
	local faction = client:GetFaction ()
	if faction:GetBaseCount () == 0 then
		faction:CreateBase (Vector (x, y, z))
	else
		client:SendHint ("You already have a base!")
	end
end)

SYSTEM:AddCommand ("rts_add_gas", function (self, ply, arguments, clientID, x, y, z)
	clientID = tonumber (clientID)
	x = tonumber (x)
	y = tonumber (y)
	z = tonumber (z)
	local client = self:GetClient (clientID)
	if client:IsConsole () then
		return
	end
	if self:IsClientAdmin (client) then
		self.GameEnvironment:CreateGas (client, Vector (x, y, z))
	end
end)

SYSTEM:AddCommand ("rts_add_minerals", function (self, ply, arguments, clientID, x, y, z)
	clientID = tonumber (clientID)
	x = tonumber (x)
	y = tonumber (y)
	z = tonumber (z)
	local client = self:GetClient (clientID)
	if client:IsConsole () then
		return
	end
	Msg (tostring (clientID) .. "\n")
	if self:IsClientAdmin (client) then
		self.GameEnvironment:CreateMinerals (client, Vector (x, y, z))
	end
end)

SYSTEM:AddCommand ("rts_entity_created", function (self, ply, arguments, clientID, rtsEntityID, entityID)
	clientID = tonumber (clientID)
	rtsEntityID = tonumber (rtsEntityID)
	entityID = tonumber (entityID)
	self.GameEnvironment:SetEntityID (rtsEntityID, entityID)
end)

SYSTEM:AddCommand ("rts_hologram_created", function (self, ply, arguments, clientID, rtsEntityID, hologramID, entityID)
	clientID = tonumber (clientID)
	rtsEntityID = tonumber (rtsEntityID)
	hologramID = tonumber (hologramID)
	entityID = tonumber (entityID)
	self.GameEnvironment:SetHologramID (rtsEntityID, hologramID)
	self.GameEnvironment:SetEntityID (rtsEntityID, entityID)
end)

SYSTEM:AddCommand ("rts_hotkeys", function (self, ply, arguments, clientID, hotkeys)
	clientID = tonumber (clientID)
	self:GetClient (clientID):ProcessHotkeys (hotkeys)
end)

SYSTEM:AddCommand ("rts_join", function (self, ply, arguments, clientID)
	clientID = tonumber (clientID)
	self:GetClient (clientID):JoinGame ()
end)

SYSTEM:AddCommand ("rts_key_state", function (self, ply, arguments, clientID, key, keyDown, eyeX, eyeY, eyeZ, dirX, dirY, dirZ)
	clientID = tonumber (clientID)
	keyDown = tonumber(keyDown)
	eyeX = tonumber (eyeX)
	eyeY = tonumber (eyeY)
	eyeZ = tonumber (eyeZ)
	dirX = tonumber (dirX)
	dirY = tonumber (dirY)
	dirZ = tonumber (dirZ)
	local startPos = Vector (eyeX, eyeY, eyeZ)
	local endPos = startPos + 16384 * Vector (dirX, dirY, dirZ)
	local trace = self.GameEnvironment:Trace (startPos, endPos, self:GetClient (clientID):GetPlayer ())
	self:GetClient (clientID):ProcessKeyPress (key, keyDown, trace)
end)

SYSTEM:AddCommand ("rts_object_info", function (self, ply, arguments, clientID, entityID)
	clientID = tonumber (clientID)
	entityID = tonumber (entityID)
	self:GetClient (clientID):SendHint (self.GameEnvironment:GenerateEntityInfo (entityID, self:GetClient (clientID), true))
end)

SYSTEM:AddCommand ("rts_player_id", function (self, ply, arguments, clientID, playerID)
	clientID = tonumber (clientID)
	local client = self:GetClient (clientID)
	if client then
		client:SetPlayerID (playerID)
	end
end)

SYSTEM:AddCommand ("rts_register", function (self, ply, arguments, clientID, entityID)
	clientID = nil	-- Dummy argument
	entityID = tonumber (entityID)
	self:CreateClient (entityID)
end)

SYSTEM:AddCommand ("rts_remove", function (self, ply, arguments, clientID, entityID)
	clientID = tonumber (clientID)
	entityID = tonumber (entityID)
	local client = self:GetClient (clientID)
	if self:IsClientAdmin (client) then
		if entityID ~= 0 then
			self.GameEnvironment:RemoveEntity (entityID)
		elseif not client:IsConsole () then
			local player = client:GetPlayer ()
			local trace = player:GetEyeTrace ()
			local startPos = trace.StartPos
			local direction = (trace.HitPos - trace.StartPos):Normalize ()
			local traceDistance = (trace.HitPos - trace.StartPos):Length ()
			local start = 32768	-- Huge number
			local hitEntity = nil
			for hologramID, rtsEntity in pairs (self.GameEnvironment:GetHologramEntities ()) do
				local tStart, tEnd = rtsEntity:TraceRay (startPos, direction)
				if tStart and tStart > 0 and tStart < start then
					start = tStart
					hitEntity = rtsEntity
				end
			end
			if hitEntity then
				self.GameEnvironment:RemoveEntity (hitEntity:GetEntityID ())
			end
		end
	end
end)

SYSTEM:AddCommand ("rts_round_end", function (self, ply, arguments, clientID)
	clientID = tonumber (clientID)
	if self:IsInRound () and self:IsClientAdmin (self:GetClient (clientID)) then
		self:EndRound ()
	end
end)

SYSTEM:AddCommand ("rts_round_start", function (self, ply, arguments, clientID)
	clientID = tonumber (clientID)
	if not self:IsInRound () and self:IsClientAdmin (self:GetClient (clientID)) then
		self:StartRound ()
	end
end)

LMsg.Lua.IncludeFolder ("systems/starcraft/objects")