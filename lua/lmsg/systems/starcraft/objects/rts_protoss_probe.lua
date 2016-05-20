local OBJ = LMsg.Objects.Register ("RTS Protoss Probe", "RTS Combat Entity")

function OBJ:__init (rtsEntityID, entity, entityOwnerClient)
	self:SetCombatType ("Protoss Probe")
	self:SetClassName ("Protoss Probe")
	
	self:SetMobile (true)
end

function OBJ:__uninit ()
end

function OBJ:InteractWithFriendly (client, rtsEntity, pos)
	if rtsEntity:GetClassName () == "Resources" then
		self:SetGoal ("Harvest Resources", rtsEntity, pos)
	else
		self:_GetBaseClass ("RTS Protoss Probe").InteractWithFriendly (self, client, rtsEntity, pos)
	end
end