local OBJ = LMsg.Objects.Register ("RTS Building", "RTS Combat Entity")

function OBJ:__init (rstEntityID, entity, entityOwnerClient)
	self:SetCombatType ("Protoss Nexus")
	self:SetClassName ("Protoss Nexus")
end

function OBJ:__uninit ()
end

function OBJ:OnBuildQueueDone (name)
	if name == "Protoss Probe" then
		local unit = self.OwnerClient:GetFaction ():SpawnUnit (name, self:GetPosition ())
		local direction = Vector (1, 0, 0)
		direction:Rotate (Angle (0, math.random (0, 360), 0))
		local bboxSize = self:GetBBoxMax () - self:GetBBoxMin ()
		bboxSize = bboxSize * 0.5
		local radius = math.sqrt (bboxSize.x * bboxSize.x + bboxSize.y * bboxSize.y)
		unit:SetTargetPosition (self.OwnerClient, unit:GetPosition () + direction * radius)
		self.OwnerClient:SendHint ("Finished warping in " .. name .. ".")
	else
		self:_GetBaseClass ("RTS Building").OnBuildQueueDone (self, name)
	end
end

function OBJ:ProcessHotkey (client, hotkey)
	if hotkey == "p" then
		self.BuildQueue:Push ("Protoss Probe", CurTime (), 3)
		client:SendHint ("Added probe to queue.")
	end
end

function OBJ:Spawn (networkPipe, client)
	self:_GetBaseClass ("RTS Building").Spawn (self, networkPipe, client)
end