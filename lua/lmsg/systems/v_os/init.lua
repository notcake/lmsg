local SYSTEM = LMsg.CreateSystem ("V_OS")
SYSTEM.Autorun = true

-- Computers
SYSTEM.NextComputerID = 1
SYSTEM.Computers = {}		-- Computer IDs to Computers
SYSTEM.EntityComputers = {}	-- Entity IDs to computer IDs

-- Programs
SYSTEM.GlobalPrograms = {}

-- Initialization and uninitialization
function SYSTEM:Start ()
	local OLD_SYSTEM = _G.SYSTEM
	_G.SYSTEM = SYSTEM
	LMsg.Lua.IncludeFolder ("systems/v_os/programs")
	_G.SYSTEM = OLD_SYSTEM
	
	self:AddTimer ("CheckComputers", 1, 0, function (self)
		if self.CheckComputers then
			self:CheckComputers ()
		end
	end)
end

function SYSTEM:Stop ()
	self:RemoveTimer ("CheckComputers")
end

function SYSTEM:CheckComputers ()
	for computerID, computer in pairs (self.Computers) do
		if not computer:IsConnectionActive () then
			LocalPlayer ():PrintMessage (HUD_PRINTTALK, "Computer " .. computer:GetComputerID () .. " has timed out.")
			computer:__uninit ()
			self.EntityComputers [computer:GetEntityID ()] = nil
			self.Computers [computerID] = nil
		end
	end
end

function SYSTEM:CreateComputer (entityID, computerID)
	computerID = computerID or self:GenerateComputerID ()
	self.EntityComputers [entityID] = computerID
	local computer = LMsg.Objects.Create ("V OS Computer", entityID, computerID, LMsg.Objects.Create ("Network Pipe", self:GetSystemName ()))
	self.Computers [computerID] = computer
	computer:SetGlobalProgramList (self.GlobalPrograms)
end

function SYSTEM:CreateProgram (programName, programDescription)
	local program = LMsg.Objects.Create ("V OS Program", programName, programDescription)
	self.GlobalPrograms [programName] = program
	return program:GetContainer ()
end

function SYSTEM:DestroyAllComputers ()
	Msg ("V OS System shutting down; all computers destroyed.\n")
	for computerID, computer in pairs (self:GetComputers ()) do
		computer:ShutDown ()
		computer:__uninit ()
	end
	self.Computers = {}
	self.EntityComputers = {}
	self.GlobalPrograms {}
end

function SYSTEM:GenerateComputerID ()
	local computerID = self.NextComputerID
	self.NextComputerID = self.NextComputerID + 1
	return computerID
end

function SYSTEM:GetComputer (computerID)
	return self.Computers [computerID]
end

function SYSTEM:GetComputers ()
	return self.Computers
end

SYSTEM:AddCommand ("keyboard", function (self, ply, arguments, computerID, keyCode)
	computerID = tonumber (computerID)
	keyCode = tonumber (keyCode)
	
	local computer = self:GetComputer (computerID)
	if computer then
		computer:ProcessKeyboardInput (keyCode)
	end
end)

SYSTEM:AddCommand ("ping", function (self, ply, arguments, computerID, entityID)
	if not computerID or not entityID then
		return
	end
	computerID = tonumber (computerID)
	entityID = tonumber (entityID)
	if computerID == 0 or computerID == nil or entityID == 0 or entityID == nil then
		return
	end
	local computer = self:GetComputer (computerID)
	if computer then
		computer:ProcessConnectionPing ()
	else
		if not self.EntityComputers [entityID] then
			self:CreateComputer (entityID)
		end
	end
end)

SYSTEM:AddCommand ("startup", function (self, ply, arguments, entityID)
	self:CreateComputer (tonumber(entityID))
end)

LMsg.Lua.IncludeFolder ("systems/v_os/objects")