local OBJ = LMsg.Objects.Register ("RTS Resources", "RTS Entity")

OBJ.TYPE_MINERALS	= 1
OBJ.TYPE_VESPENE	= 2

function OBJ:__init (rstEntityID, entity, entityOwnerClient)
	self:SetClassName ("Resources")

	self.ResourceType = self.TYPE_MINERALS
	self.ResourceCount = 2000
end

function OBJ:__uninit ()
end

function OBJ:GenerateInfo (client, verbose)
	if self.ResourceType == self.TYPE_MINERALS then
		return "Minerals: " .. tostring (self.ResourceCount)
	elseif self.ResourceType == self.TYPE_VESPENE then
		return "Gas: " .. tostring (self.ResourceCount)
	end
end

function OBJ:IsGas ()
	return self.ResourceType == self.TYPE_VESPENE
end

function OBJ:IsMinerals ()
	return self.ResourceType == self.TYPE_MINERALS
end

function OBJ:SetType (resourceType)
	self.ResourceType = resourceType
end

function OBJ:Spawn (networkPipe, client)
	self:_GetBaseClass ("RTS Resources").Spawn (self, networkPipe, client)
end