local OBJ = LMsg.Objects.Register ("RTS Entity")
OBJ.TYPE_NONE = 0
OBJ.TYPE_ENTITY = 1
OBJ.TYPE_HOLOGRAM = 2

function OBJ:__init (rtsEntityID, entity, entityOwnerClient)
	if entity and not entity:IsValid () then
		entity = nil
	end
	
	-- General
	self.RTSEntityID = rtsEntityID
	self.Entity = entity
	self.EntityID = 0
	self.EntityOwnerClient = entityOwnerClient	-- Hosting the entity
	self.HologramID = 0
	self.OwnEntity = false
	
	self.WaitingForSpawn = false
	self.Spawned = false
	
	self.EntityType = self.TYPE_ENTITY
	
	if self.Entity then
		self.Position = entity:GetPos ()
		self.Angles = entity:GetAngles ()
		
		self.EntityID = entity:EntIndex ()
		self.Spawned = true
	else
		self.Position = Vector (0, 0, 0)
		self.Angles = Angle (0, 0, 0)
	end
	self.PositionOffset = Vector (0, 0, 0)
	
	-- Thinking
	self.LastThinkTime = CurTime ()
	self.DeltaThinkTime = 0
	
	-- Model
	self.Model = ""
	
	-- Other properties
	self.Material = ""
	self.Color = Color (255, 255, 255, 255)
	self.Scale = Vector (1, 1, 1)	-- Hologram only
	
	-- Game
	self.Faction = nil
	self.OwnerClient = nil			-- Constructed the entity
	self.ClassName = "RTS Entity"
	
	-- Events
	self.GameEnvironment = nil
	self.SelectingClients = {}
	
	-- Building queue
	self.BuildQueue = LMsg.Objects.Create ("RTS Build Queue", self)
end

function OBJ:__uninit ()
	self.GameEnvironment = nil
	
	self.BuildQueue:__uninit ()
	self.BuildQueue = nil

	if not self.EntityOwnerClient then
		CAdmin.Debug.PrintStackTrace ()
	end
	if self.OwnEntity then
		self:RemoveEntity ()
	end

	if self.OwnerClient then
		self.OwnerClient = nil
	end
	
	self.EntityOwnerClient = nil
	self.OwnerClient = nil
	self.Faction = nil
	
	self.SelectingClients = {}
end

function OBJ:ApplyTemplate (template, pos)
	if not template then
		return
	end
	if template.Model then
		self:SetModel (template.Model)
	elseif template.Models then
		if type (template.Models) == "string" then
			self:SetModel (template.Models)
		else
			for model, size in pairs (template.Models) do
				self:SetModel (model)
				break
			end
		end
	end
	if template.Type then
		self:SetEntityType (template.Type)
	end
	if template.SpawnAngles then
		self:SetAngles (template.SpawnAngles)
	end
	if pos then
		self:SetPosition (pos)
	end
	if template.SpawnOffset then
		local spawnOffset = Vector (template.SpawnOffset.x, template.SpawnOffset.y, template.SpawnOffset.z)
		if template.Scale then
			spawnOffset.x = spawnOffset.x * template.Scale.x
			spawnOffset.y = spawnOffset.y * template.Scale.y
			spawnOffset.z = spawnOffset.z * template.Scale.z
		end
		self:SetPositionOffset (spawnOffset)
	end
	if template.Scale then
		self:SetScale (template.Scale)
	end
	if template.Color then
		self:SetColor (template.Color)
	end
	if template.Material and template.Material ~= "" then
		self:SetMaterial (template.Material)
	end
end

function OBJ:GenerateInfo (client, verbose)
	return nil
end

function OBJ:GetAngles ()
	return self.Angles
end

function OBJ:GetBBoxMax ()
	if self.EntityType == self.TYPE_HOLOGRAM then
		return Vector (8 * self.Scale.x, 8 * self.Scale.y, 8 * self.Scale.z)
	end
	local _, bboxMax = self.Entity:GetRenderBounds ()
	return bboxMax
end

function OBJ:GetBBoxMin ()
	if self.EntityType == self.TYPE_HOLOGRAM then
		return Vector (-8 * self.Scale.x, -8 * self.Scale.y, -8 * self.Scale.z)
	end
	local bboxMin, _ = self.Entity:GetRenderBounds ()
	return bboxMin
end

function OBJ:GetClassName ()
	return self.ClassName
end

function OBJ:GetDeltaThinkTime ()
	return self.DeltaThinkTime
end

function OBJ:GetEntityID ()
	if not self.Spawned then
		return 0
	end
	return self.EntityID
end

function OBJ:GetEntityType ()
	return self.EntityType
end

function OBJ:GetFaction ()
	return self.Faction
end

function OBJ:GetHologramID ()
	return self.HologramID
end

function OBJ:GetModel ()
	return self.Model
end

function OBJ:GetOwner ()
	return self.OwnerClient
end

function OBJ:GetPosition ()
	return self.Position
end

function OBJ:GetPositionOffset ()
	return self.PositionOffset
end

function OBJ:GetRTSEntityID ()
	return self.RTSEntityID
end

function OBJ:IsHologram ()
	return self.EntityType == self.TYPE_HOLOGRAM
end

function OBJ:IsSpawned ()
	return self.Spawned or self.WaitingForSpawn
end

function OBJ:IsWorldEntity ()
	return self.EntityType == self.TYPE_ENTITY
end

function OBJ:IsWorldSpawned ()
	return self.Spawned
end

function OBJ:OnAddedToSelection (client)
	self.SelectingClients [client] = true
end

function OBJ:OnBuildQueueDone (name)	
end

function OBJ:OnReceivedEntityID (entityID)
end

function OBJ:OnRemovedFromSelection (client)
	self.SelectingClients [client] = false
end

function OBJ:ProcessHotkey (client, hotkey)
end

function OBJ:ProcessHotkeys (client, hotkeys)
	if client == self.OwnerClient then
		local length = hotkeys:len ()
		for i = 1, length do
			self:ProcessHotkey (client, hotkeys:sub (i, i))
		end
	end
end

function OBJ:RemoveEntity ()
	if not self.Spawned then
		return
	end
	self.OwnEntity = false
	if self.EntityOwnerClient:GetNetworkPipe () then
		if self.EntityType == self.TYPE_ENTITY then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("object_delete", {entity_id = self.EntityID})
		elseif self.EntityType == self.TYPE_HOLOGRAM then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("holo_delete", {entity_id = self.HologramID})
		end
	end
	
	if self.OwnerClient then
		self.OwnerClient:OnEntityRemoved (self)
	end
	for client, _ in pairs (self.SelectingClients) do
		client:OnSelectedEntityDestroyed (self)
	end
	self.SelectingClients = {}
	
	self.Entity = nil
	self.EntityID = 0
	self.Spawned = false
end

function OBJ:SetAngles (angles)
	self.Angles = angles
	if self.Spawned then
		if self.EntityType == self.TYPE_ENTITY then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("object_angles", {entity_id = self.EntityID, angles = angles})
		elseif self.EntityType == self.TYPE_HOLOGRAM then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("holo_angles", {entity_id = self.HologramID, angles = angles})
		end
	end
end

function OBJ:SetClassName (className)
	self.ClassName = className
end

function OBJ:SetColor (color)
	self.Color.r = color.r or self.Color.r
	self.Color.g = color.g or self.Color.g
	self.Color.b = color.b or self.Color.b
	self.Color.a = color.a or self.Color.a
	if self.Spawned then
		if self.EntityType == self.TYPE_ENTITY then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("object_color", {entity_id = self.EntityID, r = self.Color.r, g = self.Color.g, g = self.Color.b, a = self.Color.a})
		elseif self.EntityType == self.TYPE_HOLOGRAM then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("holo_color", {entity_id = self.HologramID, r = self.Color.r, g = self.Color.g, g = self.Color.b, a = self.Color.a})		
		end
	end
end

function OBJ:SetEntityID (entityID)
	self.WaitingForSpawn = false
	self.Spawned = true
	self.Entity = ents.GetByIndex (entityID)
	self.EntityID = entityID
	if self.Spawned then
		if self.EntityType == self.TYPE_ENTITY then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("object_color", {entity_id = self.EntityID, r = self.Color.r, g = self.Color.g, b = self.Color.b, a = self.Color.a})
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("object_material", {entity_id = self.EntityID, material = self.Material})
		elseif self.EntityType == self.TYPE_HOLOGRAM then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("holo_color", {entity_id = self.HologramID, r = self.Color.r, g = self.Color.g, b = self.Color.b, a = self.Color.a})
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("holo_material", {entity_id = self.HologramID, material = self.Material})
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("holo_scale", {entity_id = self.HologramID, scale = self.Scale})
		end
	end
	self:OnReceivedEntityID (entityID)
end

function OBJ:SetEntityType (entityType)
	if not entityType then
		return
	end
	if not self.Spawned then
		if type (entityType) == "string" then
			entityType = entityType:lower ()
			if entityType == "hologram" then
				entityType = self.TYPE_HOLOGRAM
			elseif entityType == "entity" then
				entityType = self.TYPE_ENTITY
			else
				return
			end
		end
		self.EntityType = entityType
	end
end

function OBJ:SetFaction (faction)
	self.Faction = faction
end

function OBJ:SetGameEnvironment (gameEnvironment)
	self.GameEnvironment = gameEnvironment
end

function OBJ:SetHologramID (hologramID)
	self.WaitingForSpawn = false
	self.Spawned = true
	self.HologramID = hologramID
end

function OBJ:SetMaterial (material)
	self.Material = material
	if self.Spawned then
		if self.EntityType == self.TYPE_ENTITY then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("object_material", {entity_id = self.EntityID, material = self.Material})
		elseif self.EntityType == self.TYPE_HOLOGRAM then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("holo_material", {entity_id = self.HologramID, material = self.Material})
		end
	end
end

function OBJ:SetModel (model)
	self.Model = model
end

function OBJ:SetOwner (client)
	self.OwnerClient = client
	self.Faction = client:GetFaction ()
end

function OBJ:SetPosition (pos)
	self.Position = pos
	if self.Spawned then
		if self.EntityType == self.TYPE_ENTITY then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("object_pos", {entity_id = self.EntityID, position = pos + self.PositionOffset})
		elseif self.EntityType == self.TYPE_HOLOGRAM then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("holo_pos", {entity_id = self.HologramID, position = pos + self.PositionOffset})
		end
	end
end

function OBJ:SetPositionOffset (offset)
	self.PositionOffset = offset
	if self.Spawned then
		self:SetPosition (self.Position)
	end
end

function OBJ:SetScale (scale)
	self.Scale = scale
	if self.Spawned then
		if self.EntityType == self.TYPE_HOLOGRAM then
			self.EntityOwnerClient:GetNetworkPipe ():SendMessage ("holo_scale", {entity_id = self.HologramID, scale = self.Scale})
		end
	end
end

function OBJ:SetTargetPosition (client, pos)
end

function OBJ:Spawn (networkPipe, client)
	if self.Spawned or self.WaitingForSpawn then
		return
	end
	if client:IsConsole () then
		CAdmin.Debug.PrintStackTrace ()
	end
	self.WaitingForSpawn = true
	self.EntityOwnerClient = client
	client:RegisterEntity (self)
	self.OwnEntity = true
	if self.EntityType == self.TYPE_ENTITY then
		networkPipe:SendClientMessage (client, "object_create", {rts_entity_id = self:GetRTSEntityID (),
																	model = self.Model,
																	angles = self.Angles,
																	position = self.Position + self.PositionOffset
																})
	elseif self.EntityType == self.TYPE_HOLOGRAM then
		networkPipe:SendClientMessage (client, "holo_create", {rts_entity_id = self:GetRTSEntityID (),
																	model = self.Model,
																	angles = self.Angles,
																	position = self.Position + self.PositionOffset
																})
	end
end

function OBJ:Think ()
	self.BuildQueue:Update ()
	self.DeltaThinkTime = CurTime () - self.LastThinkTime
	self.LastThinkTime = CurTime ()
end

function OBJ:TraceRay (startPos, direction)
	local bboxMin = self:GetBBoxMin () + self:GetPosition ()
	local bboxMax = self:GetBBoxMax () + self:GetPosition ()
	
	local tStart = (bboxMin.x - startPos.x) / direction.x
	local tEnd = (bboxMax.x - startPos.x) / direction.x
	if tStart > tEnd then
		local temp = tStart
		tStart = tEnd
		tEnd = temp
	end
	
	local newTStart = (bboxMin.y - startPos.y) / direction.y
	local newTEnd = (bboxMax.y - startPos.y) / direction.y
	if newTStart > newTEnd then
		local temp = newTStart
		newTStart = newTEnd
		newTEnd = temp
	end
	if newTStart > tStart then
		tStart = newTStart
	end
	if newTEnd < tEnd then
		tEnd = newTEnd
	end
	if tStart > tEnd then
		return nil, nil
	end
	newTStart = (bboxMin.z - startPos.z) / direction.z
	newTEnd = (bboxMax.z - startPos.z) / direction.z
	if newTStart > newTEnd then
		local temp = newTStart
		newTStart = newTEnd
		newTEnd = temp
	end
	if newTStart > tStart then
		tStart = newTStart
	end
	if newTEnd < tEnd then
		tEnd = newTEnd
	end
	if tStart > tEnd then
		return nil, nil
	end
	
	return tStart, tEnd
end