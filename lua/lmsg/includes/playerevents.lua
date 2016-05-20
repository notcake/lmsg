LMsg.RequireInclude ("hooks")

LMsg.PlayerEvents = {}
LMsg.PlayerEvents.ConnectedPlayers = {}

for k, v in pairs (player.GetAll ()) do
	LMsg.PlayerEvents.ConnectedPlayers [v:SteamID ()] = v
end

LMsg.Hooks.Add ("Think", "LMsg.PlayerEventsThink", function ()
	for k, v in pairs (player.GetAll ()) do
		if !LMsg.PlayerEvents.ConnectedPlayers [v:SteamID ()] then
			LMsg.PlayerEvents.ConnectedPlayers [v:SteamID ()] = v
			LMsg.Hooks.Call ("PlayerConnected", v:SteamID (), v)
		end
	end
	for k, v in pairs (LMsg.PlayerEvents.ConnectedPlayers) do
		if !v or !v:IsValid () then
			LMsg.PlayerEvents.ConnectedPlayers [k] = nil
			LMsg.Hooks.Call ("PlayerDisconnected", k)
		end
	end
end)