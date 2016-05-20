local OBJ = LMsg.Objects.Register ("RTS Faction")

function OBJ:__init (client)
	self.Client = client
	self.GameEnvironment = nil
	
	self.InGame = false
	
	self.Bases = {}
	self.BaseCount = 0
end

function OBJ:__uninit ()
	self.Bases = nil

	self.GameEnvironment = nil
	self.Client = nil
end

function OBJ:CreateBase (pos)
	local base = self.GameEnvironment:CreateBase (self.Client, pos)
	base:SetOwner (self.Client)
	self.Bases [base:GetRTSEntityID ()] = base
	self.BaseCount = self.BaseCount + 1
	return base
end

function OBJ:GetBaseCount ()
	return self.BaseCount
end

function OBJ:GetClient ()
	return self.Client
end

function OBJ:IsInGame ()
	return self.InGame
end

function OBJ:JoinGame ()
	if self.InGame then
		return
	end
	self.InGame = true
end

function OBJ:OnEntityRemoved (rtsEntity)
	local rtsEntityID = rtsEntity:GetRTSEntityID ()
	if self.Bases [rtsEntityID] then
		self.Bases [rtsEntityID] = nil
		self.BaseCount = self.BaseCount - 1
	end
end

function OBJ:SetEnvironment (gameEnvironment)
	self.GameEnvironment = gameEnvironment
end

function OBJ:SpawnUnit (name, pos)
	local unit = self.GameEnvironment:CreateUnit (self.Client, name, pos)
	unit:SetOwner (self.Client)
	return unit
end