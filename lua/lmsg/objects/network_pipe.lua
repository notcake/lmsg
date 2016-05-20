local OBJ = LMsg.Objects.Register ("Network Pipe")

function OBJ:__init (systemName)
	self.SystemName = systemName or "global"
end

function OBJ:__uninit ()
end

function OBJ:SendMessage (messageType, messageData)
	LMsg.Messages.AddSystemTable (self.SystemName, messageType, messageData)
end