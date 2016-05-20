local SYSTEM = LMsg.CreateSystem ("Server_Log")
SYSTEM.Autorun = true

function SYSTEM:Start ()
	LMsg.Messages.AddSystemTable (self.SystemName, "text", {text = "Server log started"})
end

function SYSTEM:Stop ()
end