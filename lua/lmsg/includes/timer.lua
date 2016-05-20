LMsg.Timers = LMsg.Timers or {}
LMsg.Timers.Timers = {}

function LMsg.Timers.Add (name, delay, times, func, ...)
	if !LMsg.Timers.Timers [name] then
		LMsg.Timers.Timers [name] = {}
	end
	LMsg.Timers.Timers [name].Delay = delay
	LMsg.Timers.Timers [name].Times = times
	LMsg.Timers.Timers [name].Func = func
	timer.Create ("LMsgTimers." .. name, delay, times, func, ...)
end

function LMsg.Timers.Remove (name)
	if !LMsg.Timers.Timers [name] then
		return
	end
	if LMsg.Timers.Timers [name] then
		LMsg.Timers.Timers [name] = nil
		timer.Destroy ("LMsgTimers." .. name)
	end
end

LMsg.Hooks.Add ("Uninitialize", "LMsg.Timers.Uninitialize", function ()
	for k, _ in pairs (LMsg.Timers.Timers) do
		timer.Destroy ("LMsgTimers." .. k)
	end
	LMsg.Timers.Timers = {}
end)