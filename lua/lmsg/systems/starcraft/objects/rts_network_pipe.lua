local OBJ = LMsg.Objects.Register ("RTS Network Pipe")

function OBJ:__init (systemName, clientID)
	self.SystemName = systemName
	self.ClientID = clientID or 0
end

function OBJ:BroadcastMessage (messageType, messageTable)
	messageTable = messageTable or {}
	messageTable.client_id = 0
	
	LMsg.Messages.AddSystemTable (self.SystemName, messageType, messageTable)
end

function OBJ:SendClientMessage (client, messageType, messageTable)
	messageTable = messageTable or {}
	messageTable.client_id = client:GetClientID ()
	
	LMsg.Messages.AddSystemTable (self.SystemName, messageType, messageTable)
end

function OBJ:SendMessage (messageType, messageTable)
	messageTable = messageTable or {}
	messageTable.client_id = self.ClientID
	
	LMsg.Messages.AddSystemTable (self.SystemName, messageType, messageTable)
end