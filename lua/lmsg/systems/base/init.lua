local SYSTEM = LMsg.CreateSystem ("Base")
SYSTEM.Autorun = true

function LMsg.Messages.CanSendMessage ()
	return SYSTEM:IsReceiverActive ()
end