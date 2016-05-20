local SYSTEM = LMsg.CreateSystem ("Console")
SYSTEM.Autorun = true

SYSTEM.FileName = "chat.txt"

function SYSTEM:Start ()
end

function SYSTEM:Stop ()
end

function SYSTEM:ClearConsole ()
	local tblData = {
		type = "clear"
	}
	local glonData = glon.encode ({glon.encode (LMsg.Messages.GLONE2Encode (tblData))})
	--[[
	datastream.StreamToServer ("wire_expression2_filedata", {
																filename = "console.txt",
																filedata = glonData
															})
	]]
	LMsg.E2UploadFile ("console.txt", glonData)
end

function SYSTEM:SendText (text)
	local tblData = {
		type = "text",
		text = text
	}
	local glonData = glon.encode ({glon.encode (LMsg.Messages.GLONE2Encode (tblData))})
	--[[
	datastream.StreamToServer ("wire_expression2_filedata", {
																filename = "console.txt",
																filedata = glonData
															})
	]]
	LMsg.E2UploadFile ("console.txt", glonData)
end

concommand.Add ("lmsg_console", function (ply, _, args)
	SYSTEM:SendText (args [1])
end)

function LMsgConsole (text)
	SYSTEM:SendText (text)
end

function LMsgConsoleClear ()
	SYSTEM:ClearConsole ()
end