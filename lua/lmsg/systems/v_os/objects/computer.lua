local OBJ = LMsg.Objects.Register ("V OS Computer")

function OBJ:__init (entityID, computerID, networkConnectionPipe)
	-- General data
	self.EntityID = entityID
	self.ComputerID = computerID
	
	self.Processes = {}
	self.GlobalPrograms = nil
	self.Programs = {}
	self.Screens = {}
	self.CurrentScreen = nil
	
	self.KeyboardEnabled = false
	self.BashCommands = {}
	self.CommandBuffer = ""
	
	-- Connection
	self.ConnectionTimeoutLength = 2
	self.LastConnectionPingTime = CurTime ()
	self.NetworkConnectionPipe = networkConnectionPipe

	-- Environment
	self.FileSystem = LMsg.Objects.Create ("V OS FileSystem")
	self.CurrentDirectory = LMsg.Objects.Create ("Path", "/home/")
	self.Username = "!cake"
	self.NetworkName = "workstation"
	
	-- Input
	self.CommandBuffer = ""
	self.KeyboardEnabled = false

	Msg ("Received startup signal from " .. entityID .. ".\n")
	
	-- Now configure the computer.
	self:SendMessage ("alloc_computer_id", {entity_id = self.EntityID})	-- Send the client its computer ID.
	self:AddScreen ("Session 0")

	self.CurrentScreen:Reset ()
	self.CurrentScreen:SetBackgroundColor ()
	self.CurrentScreen:WriteStringCenter ("Booting V OS ...")

	timer.Simple (5, function ()
		if self.CurrentScreen then
			self.CurrentScreen:Clear ()
			self.CurrentScreen:WriteConsoleString ("V OS booted.\n")
			self.CurrentScreen:WriteConsoleString ("Type help for a list of commands.\n")
			self:DisplayCommandPrompt ()
			self:EnableKeyboard (true)
		end
	end)
end

function OBJ:__uninit ()
	Msg ("Destroying computer " .. self.ComputerID .. "\n")
	
	self:RemoveAllScreens ()
	self.GlobalPrograms = nil
	for programName, program in pairs (self.Programs) do
		program:__uninit ()
		self.Programs [programName] = nil
	end
	self.Programs = nil
	
	for processID, process in pairs (self.Processes) do
		process:Terminate (-9)
		process:__uninit ()
		self.Processes [processID] = nil
	end
	self.Processes = nil
	
	self.FileSystem:__uninit ()
	self.FileSystem = nil
	
	self.NetworkConnectionPipe:__uninit ()
	self.NetworkConnectionPipe = nil
end

function OBJ:AddScreen (screenName)
	screenName = screenName:lower ()
	self.Screens [screenName] = LMsg.Objects.Create ("V OS Screen", self, screenName)
	
	if not self.CurrentScreen then
		self.CurrentScreen = self.Screens [screenName]
	end
end

function OBJ:CreateProcess (commandLine, argumentList)
	local processID = math.random (1, 9999)
	while self.Processes [processID] do
		processID = math.random (1, 9999)
	end
	local program = self:FindProgram (argumentList [1])
	local process = LMsg.Objects.Create ("V OS Process", processID, program, commandLine, argumentList)
	process:SetComputer (self)
	process:WaitForObject (function (process, returnValue)
		self.Processes [process:GetProcessID ()] = nil
		process:__uninit ()
	end)
	self.Processes [processID] = process
	return process
end

function OBJ:DisplayCommandPrompt ()
	self.CurrentScreen:WriteConsoleString (self:GeneratePromptString ())
	self:SendCursorPos ()
end

function OBJ:FindProgram (programName)
	if not programName then
		return nil
	end
	programName = programName:lower ()
	if self.Programs [programName] then
		return self.Programs [programName]
	end
	if self.GlobalPrograms [programName] then
		return self.GlobalPrograms [programName]
	end
end

function OBJ:EnableKeyboard (keyboardEnabled)
	self.KeyboardEnabled = keyboardEnabled
	self:SendMessage ("keyboard_state", {keyboard_enabled = keyboardEnabled})
end

function OBJ:GeneratePromptString ()
	local currentDirectory = tostring (self.CurrentDirectory)
	if currentDirectory == "/home/" then
		currentDirectory = "~"
	end
	return self.Username .. "@" .. self.NetworkName .. ":" .. currentDirectory .. "$ "
end

function OBJ:GetComputerID ()
	return self.ComputerID
end

function OBJ:GetConnectionTimeoutLength ()
	return self.ConnectionTimeoutLength
end

function OBJ:GetCurrentDirectory ()
	return LMsg.Objects.Create ("Path", self.CurrentDirectory)
end

function OBJ:GetEntityID ()
	return self.EntityID
end

function OBJ:GetFileSystem ()
	return self.FileSystem
end

function OBJ:GetGlobalProgramList ()
	return self.GlobalPrograms
end

function OBJ:GetLocalProgramList ()
	return self.Programs
end

function OBJ:GetProcesses ()
	return self.Processes
end

function OBJ:IsConnectionActive ()
	local timeSinceLastPing = CurTime () - self.LastConnectionPingTime
	if timeSinceLastPing > self:GetConnectionTimeoutLength () then
		return false
	end
	return true
end

function OBJ:IsKeyboardEnabled ()
	return self.KeyboardEnabled
end

function OBJ:ParseTerminalCommand (command, partCount)
	partCount = partCount or 65536
	local commandParts = {}
	local str = nil
	local quotationMark = nil
	local escaped = false
	local enoughParts = false
	for char in string.gmatch (command, "(.)") do
		local append = false
		local push = false
		if escaped then
			append = true
			escaped = false
		else
			if char == " " or char == "\t" then
				if quotationMark then
					append = true
				else
					push = true
				end
			elseif char == "\"" or char == "'" then
				if quotationMark then
					if quotationMark == char then
						quotationMark = nil
						push = true
					else
						process = true
					end
				else
					push = true
					quotationMark = char
				end
			elseif char == "\\" then
				escaped = true
			else
				append = true
			end
		end
		if #commandParts >= partCount - 1 then
			if push then
				push = false
				append = true
			end
		end
		if append then
			if !str then
				str = ""
			end
			str = str .. char
		elseif push then
			if str then
				table.insert (commandParts, str)
				str = nil
			end
		end
	end
	if str then
		table.insert (commandParts, str)
	end
	return commandParts
end

function OBJ:ProcessConnectionPing ()
	self.LastConnectionPingTime = CurTime ()
end

function OBJ:ProcessKeyboardInput (keyCode)
	if not self:IsKeyboardEnabled () then
		return
	end
	if keyCode == 127 then
		if self.CommandBuffer:len () > 0 then
			local lastChar = self.CommandBuffer:sub (self.CommandBuffer:len ())
			local deltaLength = -1
			if lastChar == "\t" then
				deltaLength = -4
			end
			self.CommandBuffer = self.CommandBuffer:sub (1, self.CommandBuffer:len () - 1)
			self.CurrentScreen:OffsetCursor (deltaLength)
			self.CurrentScreen:WriteConsoleString (" ")
			self.CurrentScreen:OffsetCursor (-1)
		end
	elseif keyCode == 9 then
		self.CurrentScreen:WriteConsoleString ("    ")
		self.CommandBuffer = self.CommandBuffer .. "\t"
	elseif keyCode == 10 or keyCode == 13 then
		self.CurrentScreen:WriteConsoleString ("\n")
		self:EnableKeyboard (false)
		self:RunBashCommand (self.CommandBuffer)
		self.CommandBuffer = ""
		self:SendCursorPos ()
	elseif keyCode >= 32 and keyCode <= 126 then
		self.CommandBuffer = self.CommandBuffer .. string.char (keyCode)
		self.CurrentScreen:WriteConsoleString (string.char (keyCode))
	end
end

function OBJ:RemoveAllScreens ()
	for screenName, screen in pairs (self.Screens) do
		screen:__uninit ()
	end
	self.Screens = {}
	self.CurrentScreen = nil
end

function OBJ:RunBashCommand (command)
	if not command:len () then
		return
	end
	Msg ("Ran command \"" .. command .. "\".\n")
	local commandParts = self:ParseTerminalCommand (command)
	if not commandParts [1] or commandParts [1]:len () == 0 then
		self:DisplayCommandPrompt ()
		self:EnableKeyboard (true)
		return
	end
	if self:FindProgram (commandParts [1]) then
		local process = self:CreateProcess (command, commandParts)
		if process then
			process:GetOutputStream ():AddPipe (self.CurrentScreen:GetOutputStream ())
			process:WaitForObject (function (process, returnValue)
				self:DisplayCommandPrompt ()
				self:EnableKeyboard (true)
			end)
			process:Start (command, commandParts)
			return
		end
	end
	self.CurrentScreen:WriteConsoleString ("Program \"" .. commandParts [1] .. "\" not found.\n")
	self:DisplayCommandPrompt ()
	self:EnableKeyboard (true)
end

function OBJ:SendCursorPos ()
	self.CurrentScreen:SendCursorPos ()
end

function OBJ:SendMessage (messageType, messageData)
	messageData = messageData or {}
	messageData ["computer_id"] = self:GetComputerID ()
	self.NetworkConnectionPipe:SendMessage (messageType, messageData)
end

function OBJ:SetConnectionTimeoutLength (timeoutLength)
	self.ConnectionTimeoutLength = timeoutLength
end

function OBJ:SetCurrentDirectory (currentDirectory)
	if self.FileSystem:FileExists (currentDirectory) then
		self.CurrentDirectory:Set (currentDirectory)
	end
end

function OBJ:SetGlobalProgramList (globalProgramList)
	self.GlobalPrograms = globalProgramList
end

--[[

local SYSTEM = SYSTEM
local OBJ = SYSTEM:RegisterObject ("Computer")
OBJ.System = SYSTEM

function OBJ:__init (sysname, id)
	self.SystemName = sysname
	self.LastPing = CurTime ()

	self.Path = "/home/"
	self.Username = "!cake"
	self.ID = id
	Computers [id] = self
	self.NetworkName = "workstation"
	self.Screens = {}
	self.CurrentScreen = nil

	self.Programs = {}
	self.Processes = {}

	self.KeyboardEnabled = false
	self.BashCommands = {}
	self.CommandBuffer = ""

	self:AddScreen ("Session 0")

	Msg ("Received startup signal from " .. id .. ".\n")
	self.CurrentScreen:Reset ()
	self.CurrentScreen:SetBackgroundColor ()
	self.CurrentScreen:WriteStringCenter ("Booting V OS ...")

	timer.Simple (5, function ()
		if self.CurrentScreen then
			self.CurrentScreen:Clear ()
			self.CurrentScreen:WriteConsoleString ("V OS booted.\n")
			self.CurrentScreen:WriteConsoleString ("Type help for a list of commands.\n")
			self:DisplayCommandPrompt ()
			self:EnableKeyboard (true)
		end
	end)
end

function OBJ:__uninit ()
	Msg ("Destroying computer " .. self.ID .. "\n")
	Computers [self.ID] = nil
	self:RemoveScreens ()
	for k, v in pairs (self.Programs) do
		v:Delete ()
		self.Programs [k] = nil
	end
	self.Programs = nil
	for k, v in pairs (self.Processes) do
		v:Terminate (-9)
		v:Delete ()
		self.Processes [k] = nil
	end
	self.Processes = nil
end

function OBJ:AddScreen (name)
	if !name then
		Msg ("Attempted to add a screen without a name. Aborting.\n")
		return
	end
	name = name:lower ()
	local scr = self.System:CreateObject ("Screen", name, self.ID)
	self.Screens [name] = scr
	if !self.CurrentScreen then
		self.CurrentScreen = self.Screens [name]
	end
end

function OBJ:GetBashCommands ()
	local cmds = table.Copy (self:GetGlobalBashCommands ())
	for k, v in pairs (self:GetLocalBashCommands ()) do
		cmds [k] = v
	end
	for k, v in pairs (self:GetGlobalPrograms ()) do
		cmds [k] = v
	end
	local newcmds = {}
	for k, v in pairs (cmds) do
		table.insert (newcmds, v)
	end
	cmds = nil
	PrintTable (newcmds)
	table.sort (newcmds, function (a, b)
		return a.Name < b.Name
	end)
	return newcmds
end

function OBJ:GetLocalBashCommand (cmd)
	return self.BashCommands [cmd]
end

function OBJ:GetLocalBashCommands ()
	return self.BashCommands
end

function OBJ:GetProcesses ()
	return self.Processes
end

function OBJ:IsActive ()
	local delta = CurTime () - self.LastPing
	if delta > self.System:GetTimeoutLength () * 2 then
		return false
	end
	return true
end

function OBJ:IsKeyboardEnabled ()
	return self.KeyboardEnabled
end

function OBJ:MarkActive ()
	self.LastPing = CurTime ()
end

function OBJ:OnKeyPressed (char)
	if !self:IsKeyboardEnabled () then
		return
	end
	if char == 127 then
		if self.CommandBuffer:len () > 0 then
			local dumpchar = self.CommandBuffer:sub (self.CommandBuffer:len ())
			local width = -1
			if dumpchar == "\t" then
				width = -4
			end
			self.CommandBuffer = self.CommandBuffer:sub (1, self.CommandBuffer:len () - 1)
			self.CurrentScreen:OffsetCursor (width)
			self.CurrentScreen:WriteConsoleString (" ")
			self.CurrentScreen:OffsetCursor (-1)
		end
	elseif char == 9 then
		self.CurrentScreen:WriteConsoleString ("    ")
		self.CommandBuffer = self.CommandBuffer .. "\t"
	elseif char == 10 or char == 13 then
		self.CurrentScreen:WriteConsoleString ("\n")
		self:EnableKeyboard (false)
		Msg ("Bash command \"" .. self.CommandBuffer .. "\".\n")
		self:RunBashCommand (self.CommandBuffer)
		self.CommandBuffer = ""
		self:SendCursorPos ()
	elseif char >= 32 and char <= 126 then
		self.CommandBuffer = self.CommandBuffer .. string.char (char)
		self.CurrentScreen:WriteConsoleString (string.char (char))
	end
end

function OBJ:RegisterBashCommand (cmd, desc, func)
	if self.BashCommands [cmd] then
		Msg ("Warning: Tried to register a previous registered command (\"" .. cmd .. "\").\n")
	end
	self.BashCommands [cmd] = {Name = cmd, Description = desc, Function = func}
end

function OBJ:RunBashCommand (command)
	if !command:len () then
		return
	end
	Msg ("Ran command \"" .. command .. "\".\n")
	local found = false
	local parts = self:ParseCommand (command)
	local cmd = nil
	if !parts [1] or parts [1]:len () == 0 then
		self:DisplayCommandPrompt ()
		self:EnableKeyboard (true)
		return
	end
	if self:FindProgram (parts [1]) then
		local proc = self:CreateProcess (command, parts)
		if proc then
			proc:GetOutputStream ():AddPipe (self.CurrentScreen:GetOutputStream ())
			proc:WaitForObject (function (proc, ret)
				self:DisplayCommandPrompt ()
				self:EnableKeyboard (true)
			end)
			proc:Start (command, parts)
			return
		end
	end
	if !cmd then
		cmd = self:GetGlobalBashCommand (parts [1])
	end
	if !cmd then
		cmd = self:GetLocalBashCommand (parts [1])
	end
	if cmd then
		cmd.Function (self, command, parts)
	end
	if !cmd then
		self.CurrentScreen:WriteConsoleString ("Command \"" .. parts [1] .. "\" not found.\n")
	end
	self:DisplayCommandPrompt ()
	self:EnableKeyboard (true)
end

function OBJ:SendTable (name, tbl)
	tbl.id = self.ID
	PrintTable (SYSTEM)
	SYSTEM:AddTable (name, tbl)
end

SYSTEM:AddCommand ("keyboard", function (self, ply, _, id, char)
	char = tonumber (char)
	if self:GetComputer (id) then
		Computers [id]:OnKeyPressed (char)
	else
		Msg ("Warning: Unhandled keyboard input from " .. id .. "\n")
	end
end)

SYSTEM:AddCommand ("ping", function (self, ply, _, id)
	if id:len () > 0 then
		self:MarkReceiverActive ()
		if self:GetComputer (id) then
			self:GetComputer (id):MarkActive ()
		else
			Msg ("No computer called " .. id .. " found. Creating one.\n")
			self:CreateObject ("Computer", id)
		end
	end
end)

SYSTEM:AddCommand ("startup", function (self, ply, id)
	if id:len () > 0 then
		Msg ("Received startup signal from " .. id .. ".\n")
		self:CreateObject ("Computer", id)
	end
end)
]]