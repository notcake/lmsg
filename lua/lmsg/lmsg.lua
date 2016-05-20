--[[
	Made by !cake
]]
if not CLIENT then
	return
end

if not LMsg then
	LMsg = {
		Debug = true
	}
end

-- Before plugins are registered, unload previous copies.
if LMsg.Initialized then
	LMsg.Uninitialize (true)
end

local includes = file.FindInLua( "lmsg/includes/*.lua" )

function LMsg.RequireInclude (file)
	for k, fileName in pairs (includes) do
		if fileName == file .. ".lua" then
			include ("lmsg/includes/" .. file .. ".lua")
			includes [k] = nil
		end
	end
end

for _, fileName in pairs (includes) do
	include ("LMsg/includes/" .. fileName)
end

function LMsg.Initialize ()
	if LMsg.Initialized then
		Msg ("LMsg already loaded.\n")
		return
	end
	LMsg.Hooks.Call ("Initialize")
	Msg ("LMsg loaded.\n")
	LMsg.Initialized = true
end

function LMsg.Uninitialize (reloading)
	if not LMsg.Initialized then
		Msg ("LMsg already unloaded.\n")
		return
	end
	for systemName, system in pairs (LMsg.Systems) do
		if system:IsRunning () then
			LMsg.StopSystem (systemName)
		end
	end
	LMsg.Hooks.Call ("Uninitialize", reloading)
	Msg ("LMsg unloaded.\n")
	LMsg.Initialized = false
end

LMsg.Hooks.Add ("ShutDown", "LMsg.ShutDownHook", function ()
	LMsg.Uninitialize ()
end)

timer.Create ("LMsgInitTimer", 0.1, 1, function ()
	LMsg.Initialize ()
end)

function LMsg.LMsgPanel (Panel)
	Panel:ClearControls ()
	Panel:AddControl ("Label", {Text = "Lua Systems - !cake"})
	LMsg.Hooks.Call ("PopulateLMsgMenu", Panel)
end

function LMsg.SpawnMenuOpen ()
	LMsg.LMsgPanel (GetControlPanel ("LMsgCommands"))
end
hook.Add ("SpawnMenuOpen", "LMsg.SpawnMenuOpen", LMsg.SpawnMenuOpen)

function LMsg.PopulateToolMenu ()
	spawnmenu.AddToolMenuOption ("Utilities", "Lua Systems", "Lua Systems", "Lua Systems", "", "", LMsg.LMsgPanel)
end
hook.Add ("PopulateToolMenu", "LMsg.PopulateToolMenu", LMsg.PopulateToolMenu)

concommand.Add ("lmsg_reload", function ()
	include ("autorun/lmsg.lua")
end)