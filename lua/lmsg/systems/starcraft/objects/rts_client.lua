local OBJ = LMsg.Objects.Register ("RTS Client")

function OBJ:__init (entityID, clientID, networkPipe)
	self.EntityID = entityID
	self.ClientID = clientID
	
	-- Networking
	self.PingTimeout = 5
	self.LastPingTime = CurTime ()
	self.NetworkPipe = networkPipe
	
	-- Player
	self.Player = nil

	self.GameEnvironment = nil
	
	-- Selection
	self.InfoPeriod = 5
	self.LastInfoTime = CurTime ()
	self.HoverEntityDistance = 0
	self.HoverEntity = nil
	self.LastHoverEntity = nil
	
	self.InSelection = false
	self.SelectionStart = Vector (0, 0, 0)
	self.SelectionEnd = Vector (0, 0, 0)
	
	self.SelectionCount = 0
	self.SelectedEntities = {}
	
	-- Faction
	self.Faction = LMsg.Objects.Create ("RTS Faction", self)
	
	-- Setup
	if not self:IsConsole () then
		self.NetworkPipe:SendMessage ("alloc_client_id", {entity_id = self.EntityID})
		self.NetworkPipe:SendMessage ("request_player_id")
	end
	
	-- Holo entity tracking
	self.PropEntities = {}
	self.HologramEntities = {}
end

function OBJ:__uninit ()
	self:ClearSelection ()
	
	for _, rtsEntity in pairs (self.HologramEntities) do
		self.GameEnvironment:RemoveRTSEntity (rtsEntity)
	end
	self.HologramEntities = nil

	self.GameEnvironment = nil
	
	self.Faction:__uninit ()
	self.Faction = nil
	
	self.HoverEntity = nil
	self.LastHoverEntity = nil
	
	if self.NetworkPipe then
		self.NetworkPipe:__uninit ()
		self.NetworkPipe = nil
	end
end

function OBJ:AddToSelection (rtsEntity)
	if self.SelectionCount >= 12 then
		return
	end
	for _, entity in pairs (self.SelectedEntities) do
		if entity == rtsEntity then
			return
		end
	end
	rtsEntity:OnAddedToSelection (self)
	self.SelectedEntities [#self.SelectedEntities + 1] = rtsEntity
	if rtsEntity:IsHologram () then
		self.NetworkPipe:SendMessage ("selection_add", {entity_id = rtsEntity:GetEntityID (), is_hologram = true, bbox_min = rtsEntity:GetBBoxMin (), bbox_max = rtsEntity:GetBBoxMax ()})
	else
		self.NetworkPipe:SendMessage ("selection_add", {entity_id = rtsEntity:GetEntityID (), is_hologram = false, bbox_min = Vector (0, 0, 0), bbox_max = Vector (0, 0, 0)})
	end
	self.SelectionCount = self.SelectionCount + 1
end

function OBJ:ClearSelection ()
	if #self.SelectedEntities then
		self.SelectedEntities = {}
		self.SelectionCount = 0
		self.NetworkPipe:SendMessage ("selection_clear")
	end
end

function OBJ:DoClientTrace (gameEnvironment)
	local trace = self.Player:GetEyeTrace ()
	local startPos = trace.StartPos
	local direction = (trace.HitPos - trace.StartPos):Normalize ()
	local traceDistance = (trace.HitPos - trace.StartPos):Length ()
	local start = 32768	-- Huge number
	local hitEntity = nil
	if self:IsInSelection () then
		self:MoveSelectionEnd (trace.HitPos)
	end
	for hologramID, rtsEntity in pairs (gameEnvironment:GetHologramEntities ()) do
		local tStart, tEnd = rtsEntity:TraceRay (startPos, direction)
		if tStart and tStart > 0 and tStart < start then
			start = tStart
			hitEntity = rtsEntity
		end
	end
	if start < traceDistance and start > 0 then
		self:SetHoverEntity (hitEntity, start)
	else
		self:SetHoverEntity (gameEnvironment:GetEntity (trace.Entity), traceDistance)
	end
end

function OBJ:EndSelection (pos)
	self:MoveSelectionEnd (pos)
	self.InSelection = false
end

function OBJ:GetClientID ()
	return self.ClientID
end

function OBJ:GetEntityID ()
	return self.EntityID
end

function OBJ:GetFaction ()
	return self.Faction
end

function OBJ:GetNetworkPipe ()
	return self.NetworkPipe
end

function OBJ:GetPlayer ()
	return self.Player
end

function OBJ:GetPlayerName ()
	if not self.Player then
		return "Player"
	end
	return self.Player:Name ()
end

function OBJ:GetSelectedEntities ()
	return self.SelectedEntities
end

function OBJ:IsConnectionActive ()
	if self.EntityID == -1 then
		-- Console client
		return true
	end
	if CurTime () - self.LastPingTime > self.PingTimeout then
		return false
	end
	return true
end

function OBJ:IsConsole ()
	return self.EntityID == -1 and self.ClientID == 0
end

function OBJ:IsInfoHintDue ()
	return CurTime () - self.LastInfoTime > self.InfoPeriod
end

function OBJ:IsInGame ()
	return self.Faction:IsInGame ()
end

function OBJ:IsInSelection ()
	return self.InSelection
end

function OBJ:JoinGame ()
	if not self.Faction:IsInGame () then
		self.Faction:JoinGame ()
		self.NetworkPipe:BroadcastMessage ("player_joined", {player_client_id = self.ClientID, player_name = self:GetPlayerName ()})
	end
end

function OBJ:MoveSelectionEnd (pos)
	local rtsEntities = self.GameEnvironment:GetEntitiesInBox (self.SelectionStart, pos)
	for _, rtsEntity in ipairs (rtsEntities) do
		self:AddToSelection (rtsEntity)
	end
	
	self.SelectionEnd = pos
end

function OBJ:OnEntityRemoved (rtsEntity)
	if self.Faction then
		self.Faction:OnEntityRemoved (rtsEntity)
	end
end

function OBJ:OnSelectedEntityDestroyed (rtsEntity)
	self:RemoveFromSelection (rtsEntity)
end

function OBJ:ProcessConnectionPing ()
	self.LastPingTime = CurTime ()
end

function OBJ:ProcessHotkeys (hotkeys)
	for _, rtsEntity in pairs (self.SelectedEntities) do
		rtsEntity:ProcessHotkeys (self, hotkeys)
	end
end

function OBJ:ProcessKeyPress (key, keyState, trace)
	if key == "attack1" then
		if keyState == 1 then
			self:StartSelection (trace.HitPos)
		else
			self:EndSelection (trace.HitPos)
		end
	elseif key == "attack2" then
		if keyState == 1 then
			if trace.Hit then
				if trace.HitNonWorld then
					for _, rtsEntity in pairs (self:GetSelectedEntities ()) do
						rtsEntity:InteractWith (self, trace.Entity, trace.HitPos)
					end
				else
					for _, rtsEntity in pairs (self:GetSelectedEntities ()) do
						rtsEntity:SetTargetPosition (self, trace.HitPos)
					end
				end
			end
		end
	end
end

function OBJ:RegisterEntity (rtsEntity)
	if rtsEntity:IsHologram () then
		self.HologramEntities [rtsEntity:GetEntityID ()] = rtsEntity
	else
		self.PropEntities [rtsEntity:GetEntityID ()] = rtsEntity
	end
end

function OBJ:RemoveFromSelection (rtsEntity)
	for k, entity in pairs (self.SelectedEntities) do
		if entity == rtsEntity then
			self.SelectedEntities [k] = nil
			rtsEntity:OnRemovedFromSelection (self)
			self.NetworkPipe:SendMessage ("selection_remove", {entity_id = rtsEntity:GetEntityID ()})
			self.SelectionCount = self.SelectionCount - 1
			return
		end
	end
end

function OBJ:ResetInfoTime ()
	self.LastInfoTime = CurTime ()
end

function OBJ:SendHint (hintMessage)
	if not hintMessage or hintMessage == "" then
		return
	end
	self.NetworkPipe:SendMessage ("hint", {message = hintMessage})
end

function OBJ:SetGameEnvironment (gameEnvironment)
	self.GameEnvironment = gameEnvironment
	self.GameEnvironment:AddFaction (self)
end

function OBJ:SetHoverEntity (entity, distance)
	local entityID = 0
	local bboxMin = Vector (0, 0, 0)
	local bboxMax = Vector (0, 0, 0)
	if entity then
		entityID = entity:GetEntityID ()
		if entityID == 0 then
			return
		end
		bboxMin = entity:GetBBoxMin ()
		bboxMax = entity:GetBBoxMax ()
	else
		distance = 32768
	end
	local shouldNetwork = false
	if entity then
		if math.abs (self.HoverEntityDistance - distance) > 4 then
			self.HoverEntityDistance = distance
			shouldNetwork = true
		end
		if self.LastHoverEntity ~= entity then
			self.LastHoverEntity = entity
			shouldNetwork = true
			if entity then
				if self:IsInfoHintDue () then
					self.LastInfoTime = CurTime ()
					self:SendHint (entity:GenerateInfo (self, true))
				end
			end
		end
	end
	if self.HoverEntity ~= entity then
		shouldNetwork = true
		self.HoverEntity = entity
	end
	if self:IsInfoHintDue () and entity then
		self.LastInfoTime = CurTime ()
		self:SendHint (entity:GenerateInfo (self, true))
	end
	
	if shouldNetwork and (not entity or entity:IsHologram ()) then
		self.NetworkPipe:SendMessage ("hover_entity", {entity_id = entityID, bbox_max = bboxMax, bbox_min = bboxMin, distance = distance})
	end
end

function OBJ:SetPlayerID (playerID)
	self.Player = player.GetByID (playerID)
end

function OBJ:StartSelection (pos)
	self:ClearSelection ()
	self.InSelection = true
	self.SelectionStart = pos
	
end