LMsg.RequireInclude ("hooks")
LMsg.RequireInclude ("timer")
LMsg.Systems = {}

local SYSTEM = {}
SYSTEM.__index = SYSTEM

function SYSTEM:__init (systemName)
	self.SystemName = systemName
	self.Running = false
	self.Timers = {}
	self.Commands = {}
	self.Players = {}
	self.ActivePlayers = {}
	self.Autorun = false
	self.LastPing = 0
	self.Timeout = 1

	self:AddHook ("Uninitialize", "RemoveTimers", function (self)
		for k, v in pairs (self.Timers) do
			LMsg.Timers.Remove (self.SystemName .. "." .. k)
		end
		self.Timers = {}
	end)

	self:AddHook ("RunCommand", "RunSystemCommand", function (self, ply, cmd, args)
		if self:PlayerCanRunCommand (ply, cmd, args) then
			self:RunCommand (ply, cmd, args)
		end
	end)

	self:AddHook ("PlayerDisconnect", "SystemPlayerDisconnect", function (_, steamid)
		if self.ActivePlayers [steamid] then
			self:RemovePlayer (steamid)
		end
	end)

	self:AddCommand ("ping", function (self, ply)
		self:MarkReceiverActive ()
	end)
end

function SYSTEM:Initialize ()
	if self.Running then
		return
	end
	PCallError (self.Start, self)
	LMsg.Hooks.SystemCall (self.SystemName, "Initialize")
	PCallError (self.Load, self)
	self.Running = true
end

function SYSTEM:Uninitialize ()
	if not self.Running then
		return
	end
	PCallError (self.Save, self)
	LMsg.Hooks.SystemCall (self.SystemName, "Uninitialize")
	PCallError (self.Stop, self)
	self.Running = false
end

function SYSTEM:AddCommand (command, commandFunc)
	self.Commands [string.lower (command)] = commandFunc
end

function SYSTEM:AddHook (hookType, hookName, hookFunc)
	LMsg.Hooks.SystemAdd (self.SystemName, hookType, hookName, hookFunc)
end

function SYSTEM:AddPlayer (ply)
	if not self:GetPlayer (ply) then
		self.Players [ply:SteamID ()] = {}
	end
	self.Players [ply:SteamID ()].Name = ply:Name ()

	if !self:GetActivePlayer (ply) then
		self.ActivePlayers [ply:SteamID ()] = ply
		self:CallHook ("PlayerJoined", ply:SteamID (), ply)
	end
end

function SYSTEM:AddTable (name, tbl)
	LMsg.Messages.AddSystemTable (self.SystemName, name, tbl)
end

function SYSTEM:AddTimer (name, delay, times, func, ...)
	self.Timers [name] = {Name = name, Delay = delay, Times = times}
	LMsg.Timers.Add (self.SystemName .. "." .. name, delay, times, func, self, ...)
end

function SYSTEM:CallHook (type, ...)
	LMsg.Hooks.SystemCall (self.SystemName, type, ...)
end

function SYSTEM:ForwardCommand (commandName, ply, arguments, ...)
	commandName = commandName:lower ()
	if not self.Commands [commandName] then
		return
	end
	self.Commands [commandName] (self, ply, arguments, ...)
end

function SYSTEM:GetActivePlayer (ply)
	if type (ply) == "Player" then
		ply = ply:SteamID ()
	end
	return self.ActivePlayers [ply]
end

function SYSTEM:GetActivePlayers ()
	return self.ActivePlayers
end

function SYSTEM:GetPlayer (ply)
	if type (ply) == "Player" then
		ply = ply:SteamID ()
	end
	return self.Players [ply]
end

function SYSTEM:GetPlayers ()
	return self.Players
end

function SYSTEM:GetSaveFolder ()
	return "LMsg/" .. self.SystemName .. "/"
end

function SYSTEM:GetSavePath (file)
	file = file or self.SystemName
	return self:GetSaveFolder () .. file .. ".txt"
end

function SYSTEM:GetSystemName ()
	return self.SystemName
end

function SYSTEM:GetTimeoutLength ()
	return self.Timeout
end

function SYSTEM:GetTimerInfo (name)
	return self.Timers [name]
end

function SYSTEM:GetTimers ()
	return self.Timers
end

function SYSTEM:IsReceiverActive ()
	if CurTime () - self.LastPing < self:GetTimeoutLength () then
		return true
	end
	return false
end

function SYSTEM:IsRunning ()
	return self.Running
end

function SYSTEM:Load ()
end

function SYSTEM:MarkReceiverActive ()
	self.LastPing = CurTime ()
end

function SYSTEM:PlayerCanRunCommand (ply, cmd, args)
	return true
end

function SYSTEM:RemoveCommand (cmd)
	self.Commands [string.lower (cmd)] = nil
end

function SYSTEM:RemoveHook (type, name)
	LMsg.Hooks.SystemRemove (self.SystemName, type, name)
end

function SYSTEM:RemovePlayer (ply)
	local steamid = ply
	if type (ply) != "string" then
		steamid = ply:SteamID ()
	end
	if self.ActivePlayers [steamid] then
		self:CallHook ("PlayerLeft", steamid)
		self.ActivePlayers [steamid] = nil
	end
end

function SYSTEM:RemoveTimer (name)
	if self:GetTimerInfo (name) then
		self.Timers [name] = nil
		LMsg.Timers.Remove (self.SystemName .. "." .. name)
	end
end

function SYSTEM:RunCommand (ply, cmd, args)
	cmd = cmd:lower ()
	local bits = string.Explode (" ", args)
	if self.Commands [cmd] then
		self.Commands [cmd] (self, ply, args, unpack (bits))
	end
end
	
function SYSTEM:Save ()
end

function SYSTEM:SetupPlayer (steamid, plytbl)
end

function SYSTEM:Start ()
end

function SYSTEM:Stop ()
end

-- Functions
function LMsg.CreateSystem (systemName)
	systemName = systemName:lower ()
	local system = {}
	setmetatable (system, SYSTEM)
	system:__init (systemName)

	LMsg.Systems [systemName] = system
	return system
end

function LMsg.StartSystem (systemName)
	systemName = systemName:lower ()
	if not LMsg.Systems [systemName] then
		return
	end
	if LMsg.Systems [systemName]:IsRunning () then
		return
	end
	LMsg.Systems [systemName]:Initialize ()
end

function LMsg.StopSystem (systemName)
	systemName = systemName:lower ()
	if not LMsg.Systems [systemName] then
		return
	end
	if not LMsg.Systems [systemName]:IsRunning () then
		return
	end
	LMsg.Systems [systemName]:Uninitialize ()
end

LMsg.Hooks.Add ("PlayerChat", "LMsg.OnPlayerSay", function (ply, msg)
	msg = msg:gsub ("  +", " ")
	local bits = string.Explode (" ", msg)
	local p = bits [1]:sub (1, 1)
	local cmd = false
	if p == "/" or p == "!" or p == "-" then
		bits [1] = bits [1]:sub (2)
		cmd = true
	end
	if cmd then
		if msg:find (" ") then
			local args = msg:sub (msg:find (" ") + 1)
			LMsg.Hooks.Call ("RunCommand", ply, bits [1], args)
		else
			LMsg.Hooks.Call ("RunCommand", ply, bits [1], "")
		end
	end
end)

LMsg.Hooks.Add ("PlayerCommand", "LMsg.OnPlayerCommand", function (ply, args)
	local newargs = nil
	for i = 2, #args do
		if newargs then
			newargs = newargs .. " " .. args [i]
		else
 			newargs = args [i]
		end
	end
	newargs = newargs or ""
	LMsg.Hooks.Call ("RunCommand", ply, args [1], newargs)
end)

concommand.Add ("lmsg_start", function (_, _, args)
	LMsg.StartSystem (args [1])
end)

concommand.Add ("lmsg_stop", function (_, _, args)
	LMsg.StopSystem (args [1])
end)

local systems = file.FindDir ("../lua/lmsg/systems/*")
for _, v in pairs (systems) do
	include ("lmsg/systems/" .. v .. "/init.lua")
end

for k, v in pairs (LMsg.Systems) do
	if v.Autorun then
		LMsg.StartSystem (k)
	end
end