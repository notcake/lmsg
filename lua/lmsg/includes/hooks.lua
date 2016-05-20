LMsg.Hooks = LMsg.Hooks or {}
LMsg.Hooks.Hooks = {}
LMsg.Hooks.SystemHooks = {}

function LMsg.Hooks.Add (hookType, hookName, hookFunc)
	if !LMsg.Hooks.Hooks [hookType] then
		LMsg.Hooks.Hooks [hookType] = {}
	end
	LMsg.Hooks.Hooks [hookType] [hookName] = hookFunc
	hook.Add (hookType, hookName, hookFunc)
end

function LMsg.Hooks.SystemAdd (systemName, hookType, hookName, hookFunc)
	systemName = systemName:lower ()
	if not LMsg.Hooks.SystemHooks [systemName] then
		LMsg.Hooks.SystemHooks [systemName] = {}
	end
	if not LMsg.Hooks.SystemHooks [systemName] [hookType] then
		LMsg.Hooks.SystemHooks [systemName] [hookType] = {}
	end
	LMsg.Hooks.SystemHooks [systemName] [hookType] [hookName] = hookFunc
	hook.Add (hookType, systemName .. "." .. hookName, function (...) hookFunc (LMsg.Systems [systemName], ...) end)
end

function LMsg.Hooks.Call (hookType, ...)
	if LMsg.Hooks.Hooks [hookType] then
		for _, hookFunc in pairs (LMsg.Hooks.Hooks [hookType]) do
			hookFunc (...)
		end
	end
	if hookType == "Initialize" or hookType == "Uninitialize" then
		return
	end
	for systemName, systemHookTable in pairs (LMsg.Hooks.SystemHooks) do
		if LMsg.Systems [systemName] then
			if LMsg.Systems [systemName]:IsRunning () then
				if systemHookTable [hookType] then
					for _, hookFunc in pairs (systemHookTable [hookType]) do
						hookFunc (LMsg.Systems [systemName], ...)
					end
				end
			end
		else
		end
	end
end

function LMsg.Hooks.SystemCall (systemName, hookType, ...)
	systemName = systemName:lower ()
	if not LMsg.Hooks.SystemHooks [systemName] then
		return
	end
	if not LMsg.Hooks.SystemHooks [systemName] [hookType] then
		return
	end
	for _, hookFunc in pairs (LMsg.Hooks.SystemHooks [systemName] [hookType]) do
		hookFunc (LMsg.Systems [systemName], ...)
	end
end

function LMsg.Hooks.Remove (hookType, hookName)
	if not LMsg.Hooks.Hooks [hookType] then
		return
	end
	if LMsg.Hooks.Hooks [hookType] [hookName] then
		LMsg.Hooks.Hooks [hookType] [hookName] = nil
	end
	if #(LMsg.Hooks.Hooks [hookType]) == 0 then
		LMsg.Hooks.Hooks [hookType] = nil
	end
	hook.Remove (hookType, hookName)
end

function LMsg.Hooks.SystemRemove (systemName, hookType, hookName)
	systemName = systemName:lower ()
	if not LMsg.Hooks.SystemHooks [systemName] then
		return
	end
	if not LMsg.Hooks.SystemHooks [systemName] [hookType] then
		return
	end
	LMsg.Hooks.SystemHooks [systemName] [hookType] [hookName] = nil
	if #(LMsg.Hooks.SystemHooks [systemName] [hookType]) == 0 then
		LMsg.Hooks.SystemHooks [systemName] [hookType] = nil
	end
	if #(LMsg.Hooks.SystemHooks [systemName]) == 0 then
		LMsg.Hooks.SystemHooks [systemName] = nil
	end
	hook.Remove (hookType, systemName .. "." .. hookName)
end

LMsg.Hooks.Add ("Initialize", "LMsg.Hooks.Initialize", function ()
	hook.Add ("Think", "LMsg.ThinkHook", function ()
		LMsg.Hooks.Call ("Think")
	end)
	hook.Add ("Tick", "LMsg.TickHook", function ()
		LMsg.Hooks.Call ("Tick")
	end)
end)

LMsg.Hooks.Add ("Uninitialize", "LMsg.Hooks.Uninitialize", function ()
	hook.Remove ("Think", "LMsg.ThinkHook")
	hook.Remove ("Tick", "LMsg.TickHook")

	for hookType, hookTable in pairs (LMsg.Hooks.Hooks) do
		for hookName, _ in pairs (hookTable) do
			hook.Remove (hookType, hookName)
		end
		hookTable = {}
	end
	LMsg.Hooks.Hooks = {}
end)