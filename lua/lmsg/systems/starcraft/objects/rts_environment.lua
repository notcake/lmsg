local OBJ = LMsg.Objects.Register ("RTS Environment")

local GameConfig = {
	Templates = {
		-- Resources
		Gas = {
			Models = {
				["models/props_borealis/mooring_cleat01.mdl"] = 4000
			},
			SpawnAngles = Angle (0, 0, 0),
			Color = {
				r = 0,
				g = 72,
				b = 0,
				a = 255
			}
		},
		GasCarry = {
			Type = "hologram",
			Model = "cube",
			SpawnAngles = Angle (0, 0, 0),
			Color = {
				r = 0,
				g = 128,
				b = 0,
				a = 255
			}
		},
		Minerals = {
			Models = {
				["models/props_junk/watermelon01.mdl"] = 2000,
				["models/props_junk/watermelon01_chunk01a.mdl"] = 1500,
				["models/props_junk/watermelon01_chunk01b.mdl"] = 1000,
				["models/props_junk/watermelon01_chunk01c.mdl"] = 750
			},
			SpawnAngles = Angle (0, 0, 45),
			SpawnOffset = Vector (0, 0, 4),
			Color = {
				r = 128,
				g = 128,
				b = 255,
				a = 255
			},
			Material = "models/props_debris/plasterwall034a"
		},
		MineralCarry = {
			Type = "entity",
			Model = "models/props_junk/watermelon01_chunk02a.mdl",
			SpawnAngles = Angle (0, 0, 0),
			SpawnPosition = Vector (0, 0, 0),
			Color = {
				r = 128,
				g = 128,
				b = 255,
				a = 255
			}
		},
		
		-- Teams
		ProtossNexus = {
			Type = "hologram",
			Model = "pyramid",
			Scale = Vector (4, 4, 4),
			SpawnAngles = Angle (0, 0, 0),
			SpawnOffset = Vector (0, 0, 6),
			Color = {
				r = 255,
				g = 255,
				b = 0,
				a = 255
			}
		},
		["Protoss Probe"] = {
			Type = "hologram",
			Model = "cube",
			SpawnOffset = Vector (0, 0, 6),
			Color = {
				r = 255,
				g = 255,
				b = 0,
				a = 255
			}
		}
	}
}

function OBJ:__init (systemName)
	self.SystemName = systemName
	self.NetworkPipe = LMsg.Objects.Create ("RTS Network Pipe", self.SystemName)
	
	-- Gameplay
	self.RTSEntities = {}
	self.EntitiesToRTSEntities = {}
	self.HologramsToRTSEntities = {}
	self.NextEntityID = 1
	
	self.FactionClients = {}
	self.Minerals = {}
end

function OBJ:__uninit ()
	for rtsEntityID, entity in pairs (self.RTSEntities) do
		entity:__uninit ()
		self.RTSEntities [rtsEntityID] = nil
	end
	self.RTSEntities = nil
	self.EntitiesToRTSEntities = nil
	self.HologramsToRTSEntities = nil

	self.NetworkPipe:__uninit ()
	self.NetworkPipe = nil
	
	self.FactionClients = nil
end

function OBJ:AddFaction (client)
	self.FactionClients [client:GetClientID ()] = client
	client:GetFaction ():SetEnvironment (self)
end

function OBJ:AreEnemies (f1, f2)
	if not f1 or not f2 then
		return false
	end
	if f1 == f2 then
		return false
	end
	return true
end

function OBJ:CreateBase (client, pos)
	local base = self:CreateEntity ("RTS Building")
	if not base then
		return nil
	end
	base:ApplyTemplate (self:GetTemplate ("ProtossNexus"), pos)
	base:Spawn (self.NetworkPipe, client)
	
	return base
end

function OBJ:CreateEntity (className, entity, entityOwnerClient)
	local rtsEntityID = self:GenerateEntityID ()
	local entity = LMsg.Objects.Create (className, rtsEntityID, entity, entityOwnerClient)
	entity:SetGameEnvironment (self)
	self.RTSEntities [rtsEntityID] = entity
	
	return entity
end

function OBJ:CreateGas (client, pos)
	local gas = self:CreateEntity ("RTS Resources")
	if not gas then
		return nil
	end
	gas:ApplyTemplate (self:GetTemplate ("Gas"), pos)
	gas:SetType (gas.TYPE_VESPENE)
	gas:Spawn (self.NetworkPipe, client)
	
	return gas
end

function OBJ:CreateMinerals (client, pos)
	local minerals = self:CreateEntity ("RTS Resources")
	if not minerals then
		return nil
	end
	minerals:ApplyTemplate (self:GetTemplate ("Minerals"), pos)
	minerals:SetType (minerals.TYPE_MINERALS)
	minerals:Spawn (self.NetworkPipe, client)
	
	return minerals
end

function OBJ:CreateUnit (client, className, pos)
	local unit = self:CreateEntity ("RTS " .. className)
	if not unit then
		return nil
	end
	unit:ApplyTemplate (self:GetTemplate (className), pos)
	unit:Spawn (self.NetworkPipe, client)
	
	return unit
end

function OBJ:GatherWorldData (clients)
	local clientPlayers = {}
	for _, client in pairs (clients) do
		local player = client:GetPlayer ()
		if player then
			clientPlayers [player] = true
		end
	end
	local props = ents.FindByClass ("prop_physics")
	local validProps = {}
	for _, ent in ipairs (props) do
		local owner = CAdmin.PropProtection.GetOwner (ent)
		if owner and clientPlayers [owner] then
			validProps [#validProps + 1] = ent
		end
	end
	props = {}
	
	for _, ent in ipairs (validProps) do
		local model = ent:GetModel ()
		if GameConfig.Minerals.Models [model] then
			
		end
	end
end

function OBJ:GenerateEntityID ()
	local rtsEntityID = self.NextEntityID
	self.NextEntityID = self.NextEntityID + 1
	return rtsEntityID
end

function OBJ:GenerateEntityInfo (entityID, client, verbose)
	local entity = self.EntitiesToRTSEntities [entityID]
	if not entity then
		return nil
	end
	return entity:GenerateInfo (client, verbose)
end

-- Maths heavy stuff
local function getAABBVertices (v1, v2)
	return Vector (v1.x, v1.y, v1.z),
			Vector (v1.x, v1.y, v2.z),
			Vector (v1.x, v2.y, v1.z),
			Vector (v1.x, v2.y, v2.z),
			Vector (v2.x, v1.y, v1.z),
			Vector (v2.x, v1.y, v2.z),
			Vector (v2.x, v2.y, v1.z),
			Vector (v2.x, v2.y, v2.z)
end

local function generateAABBFromVertices (vertices)
	if #vertices == 0 then
		return Vector (0, 0, 0), Vector (0, 0, 0)
	end
	local bboxMin = Vector (16384, 16384, 16384)
	local bboxMax = Vector (-16384, -16384, -16384)
	for _, v in ipairs (vertices) do
		if v.x < bboxMin.x then
			bboxMin.x = v.x
		end
		if v.y < bboxMin.y then
			bboxMin.y = v.y
		end
		if v.z < bboxMin.z then
			bboxMin.z = v.z
		end
		if v.x > bboxMax.x then
			bboxMax.x = v.x
		end
		if v.y > bboxMax.y then
			bboxMax.y = v.y
		end
		if v.z > bboxMax.z then
			bboxMax.z = v.z
		end
	end
	return bboxMin, bboxMax
end

local function intersectIntervals (t1, t2, s1, s2)
	if s1 < t1 then
		s1 = t1
	end
	if s2 > t2 then
		s2 = t2
	end
	if s1 > s2 then
		return nil, nil
	end
	return s1, s2
end

local function intersectAABBs (bboxMin1, bboxMax1, bboxMin2, bboxMax2)
	if not intersectIntervals (bboxMin1.x, bboxMax1.x, bboxMin2.x, bboxMax2.x) then
		return false
	end
	if not intersectIntervals (bboxMin1.y, bboxMax1.y, bboxMin2.y, bboxMax2.y) then
		return false
	end
	if not intersectIntervals (bboxMin1.z, bboxMax1.z, bboxMin2.z, bboxMax2.z) then
		return false
	end
	return true
end

-- Rotate all the vertices in the table by angle
local function rotateVertices (vertices, angle)
	for k, v in ipairs (vertices) do
		v:Rotate (angle)
	end
	return vertices
end

-- Fixup AABB - sorts values
local function fixAABB (bboxMin, bboxMax)
	local t = nil
	if bboxMin.x > bboxMax.x then
		t = bboxMin.x
		bboxMin.x = bboxMax.x
		bboxMax.x = t
	end
	if bboxMin.y > bboxMax.y then
		t = bboxMin.y
		bboxMin.y = bboxMax.y
		bboxMax.y = t
	end
	if bboxMin.z > bboxMax.z then
		t = bboxMin.z
		bboxMin.z = bboxMax.z
		bboxMax.z = t
	end
	return bboxMin, bboxMax
end

-- End of maths heavy stuff

function OBJ:GetEntitiesInBox (startPos, endPos)
	local rtsEntities = {}
	
	local startPos = Vector (startPos.x, startPos.y, startPos.z)
	local endPos = Vector (endPos.x, endPos.y, endPos.z)
	startPos.x = math.Clamp (startPos.x, -16000, 16000)
	startPos.y = math.Clamp (startPos.y, -16000, 16000)
	startPos.z = math.Clamp (startPos.z, -16000, 16000)
	endPos.x = math.Clamp (endPos.x, -16000, 16000)
	endPos.y = math.Clamp (endPos.y, -16000, 16000)
	endPos.z = math.Clamp (endPos.z, -16000, 16000)
	
	local entities = ents.FindInBox (startPos, endPos)
	for _, entity in ipairs (entities) do
		local rtsEntity = self.EntitiesToRTSEntities [entity:EntIndex ()]
		if rtsEntity then
			rtsEntities [#rtsEntities + 1] = rtsEntity
		end
	end
	
	startPos, endPos = fixAABB (startPos, endPos)
	for _, rtsEntity in pairs (self.HologramsToRTSEntities) do
		local bboxMin, bboxMax = rtsEntity:GetBBoxMin (), rtsEntity:GetBBoxMax ()
		bboxMin, bboxMax = generateAABBFromVertices (rotateVertices ({getAABBVertices (bboxMin, bboxMax)}, rtsEntity:GetAngles ()))
		bboxMin = bboxMin + rtsEntity:GetPosition ()
		bboxMax = bboxMax + rtsEntity:GetPosition ()
		if intersectAABBs (bboxMin, bboxMax, startPos, endPos) then
			Msg ("Added " .. rtsEntity:GetClassName () .. "\n")
			rtsEntities [#rtsEntities + 1] = rtsEntity
		end
	end
	
	return rtsEntities
end

function OBJ:GetEntity (entity)
	if not entity then
		return nil
	end
	if type (entity) == "number" then
		return self.EntitiesToRTSEntities [entity]
	elseif entity.EntIndex then
		return self.EntitiesToRTSEntities [entity:EntIndex ()]
	end
	return nil
end

function OBJ:GetHologramEntities ()
	return self.HologramsToRTSEntities
end

function OBJ:GetTemplate (templateName)
	return GameConfig.Templates [templateName]
end

function OBJ:RemoveEntity (entityID)
	if not self.RTSEntities then
		return
	end
	local entity = self.EntitiesToRTSEntities [entityID]
	if not entity then
		return
	end
	self.EntitiesToRTSEntities [entityID] = nil
	self.HologramsToRTSEntities [entity:GetHologramID ()] = nil
	self.RTSEntities [entity:GetRTSEntityID ()] = nil
	entity:__uninit ()
	entity = nil
end

function OBJ:RemoveRTSEntity (rtsEntity)
	if not rtsEntity or not self.RTSEntities then
		return
	end
	self.EntitiesToRTSEntities [rtsEntity:GetEntityID ()] = nil
	self.HologramsToRTSEntities [rtsEntity:GetHologramID ()] = nil
	self.RTSEntities [rtsEntity:GetRTSEntityID ()] = nil
	rtsEntity:__uninit ()
	rtsEntity = nil
end

function OBJ:SetEntityID (rtsEntityID, entityID)
	local entity = self.RTSEntities [rtsEntityID]
	if not entity then
		return
	end
	entity:SetEntityID (entityID)
	self.EntitiesToRTSEntities [entityID] = entity
end

function OBJ:SetHologramID (rtsEntityID, hologramID)
	local entity = self.RTSEntities [rtsEntityID]
	if not entity then
		return
	end
	entity:SetHologramID (hologramID)
	self.HologramsToRTSEntities [hologramID] = entity
end

function OBJ:Think ()
	for _, rtsEntity in pairs (self.RTSEntities) do
		rtsEntity:Think ()
	end
end

function OBJ:Trace (startPos, endPos, filter)
	startPos = startPos + Vector (0, 0, 0.5)
	endPos = endPos + Vector (0, 0, 0.5)
	local trace = {
		start = startPos,
		endpos = endPos,
		filter = filter
	}
	local trace = util.TraceLine (trace)
	if trace.HitNonWorld then
		trace.Entity = self:GetEntity (trace.Entity)
		if not trace.Entity then
			trace.Fraction = 1
			trace.Hit = false
		end
	else
		trace.Entity = nil
	end
	
	local direction = endPos - startPos
	for hologramID, rtsEntity in pairs (self:GetHologramEntities ()) do
		local tStart, tEnd = rtsEntity:TraceRay (startPos, direction)
		if tStart and tStart >= 0 and tStart < trace.Fraction then
			trace.Fraction = tStart
			trace.HitPos = startPos + tStart * direction
			trace.HitNonWorld = true
			trace.Entity = rtsEntity
			trace.Hit = true
		end
	end
	
	return trace
end