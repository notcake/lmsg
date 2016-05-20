local OBJ = LMsg.Objects.Register ("RTS Combat Entity", "RTS Entity")


function OBJ:__init (rtsEntityID, entity, entityOwnerClient)
	self.Health = 100
	self.MaxHealth = 100
	
	self.Shield = 0
	self.MaxShield = 0
	
	self.CombatType = "Unknown"
	
	-- Navigation
	self.IsMobile = false
	
	self.MovingToTarget = false
	self.RotatingToTarget = false
	self.TargetEntity = nil
	self.TargetRotation = Angle (0, 0, 0)
	self.TargetPosition = Vector (0, 0, 0)
	self.SubTargetPosition = Vector (0, 0, 0)
	self.Speed = 100
	
	-- Goals
	-- Goals are long run stuff, eg. collecting resources, attack-moving.
	self.GoalName = nil
	self.GoalEntity = nil
	self.GoalPos = Vector (0, 0, 0)
end

function OBJ:__uninit ()
	self.GoalEntity = nil
	self.TargetEntity = nil
end

function OBJ:CanMove ()
	return self.IsMobile
end

function OBJ:GenerateInfo (client, verbose)
	return self.CombatType
end

function OBJ:GetCombatType ()
	return self.CombatType .. ": Health: " .. tostring (self.Health) .. " / " .. tostring (self.MaxHealth)
end

function OBJ:GetHealth ()
	return self.Health
end

function OBJ:GetMaxHealth ()
	return self.MaxHealth
end

function OBJ:GetMaxShield (maxShield)
	return self.MaxShield
end

function OBJ:GetShield ()
	return self.Shield
end

function OBJ:GetSpeed ()
	return self.Speed
end

function OBJ:GetSubTargetPosition ()
	return self.SubTargetPosition
end

function OBJ:GetTargetPosition ()
	return self.TargetPosition
end

function OBJ:InteractWithEnemy (client, rtsEntity, pos)
end

function OBJ:InteractWithFriendly (client, rtsEntity, pos)
	self:SetTargetPosition (client, pos)
end

function OBJ:InteractWith (client, rtsEntity, pos)
	local f1, f2 = self:GetFaction (), rtsEntity:GetFaction ()
	local canAttack = self.GameEnvironment:AreEnemies (f1, f2)
	if not canAttack then
		self:InteractWithFriendly (client, rtsEntity, pos)
	else
		self:InteractWithEnemy (client, rtsEntity, pos)
	end
end

function OBJ:OnReceivedEntityID (entityID)
	self:_GetBaseClass ("RTS Combat Entity").OnReceivedEntityID (self, entityID)
	if self.RotatingToTarget then
	elseif self.MovingToTarget then
		if self:IsHologram () then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("lerp_position", {entity_id = self:GetHologramID (), is_hologram = true, target_position = self:GetSubTargetPosition () + self:GetPositionOffset (), speed = self:GetSpeed ()})
		else
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("lerp_position", {entity_id = self:GetEntityID (), is_hologram = false, target_position = self:GetSubTargetPosition () + self:GetPositionOffset (), speed = self:GetSpeed ()})
		end
	end
	self:SetPosition (self.Position)
end

function OBJ:Renavigate ()
	
end

function OBJ:SetCombatType (combatType)
	self.CombatType = combatType
end

function OBJ:SetGoal (goalName, rtsEntity, pos)
	self.GoalName = goalName
	self.GoalEntity = rtsEntity
	self.GoalPosition = pos
	self:SetTargetPosition (pos)
end

function OBJ:SetHealth (health)
	self.Health = health
end

function OBJ:SetMaxHealth (maxHealth)
	self.MaxHealth = maxHealth
end

function OBJ:SetMaxShield (maxShield)
	self.MaxShield = maxShield
end

function OBJ:SetMobile (mobile)
	self.IsMobile = mobile
end

function OBJ:SetShield (shield)
	self.Shield = shield
end

function OBJ:SetSpeed (speed)
	self.Speed = speed
end

function OBJ:SetSubTargetPosition (pos)
	self.SubTargetPosition = pos
	self.MovingToTarget = true
	if self.Spawned then
		if self:IsHologram () then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("lerp_position", {entity_id = self:GetHologramID (), is_hologram = true, target_position = self.SubTargetPosition + self:GetPositionOffset (), speed = self:GetSpeed ()})
		else
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("lerp_position", {entity_id = self:GetEntityID (), is_hologram = false, target_position = self.SubTargetPosition + self:GetPositionOffset (), speed = self:GetSpeed ()})
		end
	end
end

function OBJ:SetTargetPosition (client, pos)
	if not self:CanMove () or self:GetOwner () ~= client then
		return
	end
	self.TargetPosition = pos
	self.SubTargetPosition = pos
	local trace = self.GameEnvironment:Trace (self.Position, pos)
	local hitEntity, fraction = trace.Entity, trace.Fraction
	if hitEntity then
		self.SubTargetPosition = self.Position + (pos - self.Position) * fraction
	end
	self.MovingToTarget = true

	if self.Spawned then
		if self:IsHologram () then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("lerp_position", {entity_id = self:GetHologramID (), is_hologram = true, target_position = self.SubTargetPosition + self:GetPositionOffset (), speed = self:GetSpeed ()})
		else
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("lerp_position", {entity_id = self:GetEntityID (), is_hologram = false, target_position = self.SubTargetPosition + self:GetPositionOffset (), speed = self:GetSpeed ()})
		end
	end
end

function OBJ:Spawn (networkPipe, client)
	self:_GetBaseClass ("RTS Combat Entity").Spawn (self, networkPipe, client)
end

function OBJ:Think ()
	self:_GetBaseClass ("RTS Combat Entity").Think (self)
	
	local deltaTime = self:GetDeltaThinkTime ()
	if self.RotatingToTarget then
		self.Angles = self.Angles + (self.TargetAngles - self.Angles):Normalize () * 1 * deltaTime
	elseif self.MovingToTarget then
		local deltaPosition = self.SubTargetPosition - self.Position
		local direction = deltaPosition:GetNormalized ()
		local newPosition = self.SubTargetPosition
		if deltaPosition:Length () >= self.Speed * deltaTime then
			newPosition = self.Position + direction * self.Speed * deltaTime
		end
		local trace = self.GameEnvironment:Trace (self.Position, newPosition)
		local hitEntity, fraction = trace.Entity, trace.Fraction
		if hitEntity then
			newPosition = self.Position + (newPosition - self.Position) * fraction
			self:SetSubTargetPosition (newPosition)
			self:Renavigate ()
		else
			if deltaPosition:Length () < self.Speed * deltaTime then
				self.MovingToTarget = false
				self:Renavigate ()
			end
		end
		self.Position = newPosition
	end
end