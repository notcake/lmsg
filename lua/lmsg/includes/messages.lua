LMsg.RequireInclude ("hooks")

if not LMsg.Messages then
	LMsg.Messages = {
		DataNextAdd = 1,
		DataNextSend = 1,
		DataTable = {},
		LastACKED = -1,
		LastSent = 0,
		NextTick = 0,
	}
else
	LMsg.Messages.DataNextAdd = 1
	LMsg.Messages.DataNextSend = 1
	LMsg.Messages.DataTable = {}
	LMsg.Messages.LastACKED = -1
	LMsg.Messages.LastSent = 0
	LMsg.Messages.NextTick = 0
end

--[[
	E2 File Functions
]]
local E2FileUploadChunkSize = 229
local E2FileQueue = {}
E2FileQueueNextIndex = 1
E2FileQueueInsertionIndex = 1
E2FileUploading = false
LMsg.Hooks.Add ("Tick", "LMsg.E2FileUpload", function ()
	-- Clear the queue if it is empty
	if E2FileQueueNextIndex == E2FileQueueInsertionIndex and
	   E2FileQueueNextIndex > 1 then
		E2FileQueue = {}
		E2FileQueueNextIndex = 1
		E2FileQueueInsertionIndex = 1
	end
end)

function LMsg.E2BeginNextFileUpload ()
	E2FileUploading = true
	local queueEntry = E2FileQueue [E2FileQueueNextIndex]
	local fileName = queueEntry.fileName
	local fileData = queueEntry.fileData
	local uploadBuffer = queueEntry.uploadBuffer
	-- MsgN ("Beginning upload of " .. fileName .. " with " .. tostring (uploadBuffer.chunks) .. " chunks.")
	-- RunConsoleCommand ("wire_expression2_file_begin", string.len (fileData))
	timer.Remove ("wire_expression2_file_upload_")
	timer.Create ("wire_expression2_file_upload_", 1 / 60, uploadBuffer.chunks + 1, function ()
		local chunkSize = math.Clamp (string.len (uploadBuffer.data), 0, E2FileUploadChunkSize)
		-- RunConsoleCommand ("wire_expression2_file_chunk", string.Left (uploadBuffer.data, chunkSize))
		-- MsgN (string.Left (uploadBuffer.data, chunkSize))
		uploadBuffer.data = string.sub (uploadBuffer.data, chunkSize + 1, string.len (uploadBuffer.data))
		
		if uploadBuffer.chunk >= uploadBuffer.chunks then
			-- RunConsoleCommand ("wire_expression2_file_finish")
			timer.Remove ("wire_expression2_file_upload_")
			E2FileQueueNextIndex = E2FileQueueNextIndex + 1
			E2FileUploading = false
			-- MsgN ("Finished upload of " .. fileName)
			if E2FileQueueNextIndex < E2FileQueueInsertionIndex then
				LMsg.E2BeginNextFileUpload ()
			end
			return
		end
		uploadBuffer.chunk = uploadBuffer.chunk + 1
	end)
end

function LMsg.E2UploadFile (fileName, fileData)
	if not fileName or not fileData then
		return
	end
	
	local encoded = E2Lib.encode (fileData)
	local queueEntry = {
		fileName = fileName,
		fileData = fileData,
		uploadBuffer = {
			chunk = 1,
			chunks = math.ceil (string.len (encoded) / E2FileUploadChunkSize), 
			data = encoded
		}
	}
	E2FileQueue [E2FileQueueInsertionIndex] = queueEntry
	E2FileQueueInsertionIndex = E2FileQueueInsertionIndex + 1
	
	if not E2FileUploading then
		LMsg.E2BeginNextFileUpload ()
	end
end
	
local Messages = LMsg.Messages
Messages.SystemFiles = Messages.SystemFiles or {
													["global"] = "global.txt"
												}
Messages.FileSystems = Messages.FileSystems or {
													["global.txt"] = "global"
												}
Messages.Systems = Messages.Systems or {}	
--[[
	Each system in Messages.Systems contains a table:
	{
		NextToAdd = 1,		-- Next item to write in Buffer
		NextToSend = 1,		-- Next item in Buffer to send
		Buffer = {			-- Array of glon encoded messages
		}
	}
]]

local chatDelay = 1
local cvarCount = 10
local cvarSize = 100
local cvarCapacity = cvarCount * cvarSize

CreateClientConVar ("lmsg_message_proxy_data_count", cvarCount, false, true)
for i = 1, cvarCount do
	CreateClientConVar ("lmsg_message_proxy_data" .. tostring (i), "", false, true)
end
CreateClientConVar ("lmsg_message_proxy_data_id", "-1", false, true)
timer.Simple (0.1, function ()
	RunConsoleCommand ("lmsg_message_proxy_data_count", tostring (cvarCount))
	for i = 1, cvarCount do
		RunConsoleCommand ("lmsg_message_proxy_data" .. tostring (i), "")
	end
	RunConsoleCommand ("lmsg_message_proxy_data_id", "-1")
end)

--========= E2 GLON Encoding ========
function Messages.GLONClean (str)
	if !str then
		return ""
	end
	str = string.gsub (str, ".", function (c)
		if c:byte () <= 15 or c == "%" then
			return string.format ("%%%02X", c:byte ())
		end
		return c
	end)
	return str
end

function Messages.GLONE2Decode (messageTable)
	local newMessageTable = {}
	for k, v in pairs (messageTable) do
		local typePrefix = k:sub (1, 1)
		newMessageTable [k:sub (2)] = v
	end
	return newMessageTable
end

function Messages.GLONE2Encode (messageTable)
	local newMessageTable = {}
	local typePrefixes = {
		Angle = "a",
		Player = "e",
		Entity = "e",
		string = "s",
		boolean = "_b",	-- Needs converting
		number = "n",
		Vector = "v",
	}
	for key, value in pairs (messageTable) do
		local valueType = type (value)
		local typePrefix = typePrefixes [valueType] or "s"
		if typePrefix == "s" then
			value = tostring (value)
		end
		if typePrefix == "_b" then
			typePrefix = "n"
			if value then
				value = 1
			else
				value = 0
			end
		end
		if typePrefix == "a" then
			value = Vector (value.p, value.y, value.r)
		end
		newMessageTable [typePrefix .. key] = value
	end
	return newMessageTable
end

function Messages.URLDecode (str)
	if !str then
		return ""
	end
	str = string.gsub (str, "#(%x%x)", function (h)
		return string.char (tonumber ("0x" .. h, 16))
	end)
	return str
end

--========= Raw tables ==============
function Messages.AddSystemTable (systemName, messageType, messageTable)
	messageTable.type = messageType
	systemName = systemName:lower ()
	if not Messages.Systems [systemName] then
		Messages.Systems [systemName] = {
			NextToAdd = 1,
			NextToSend = 1,
			Buffer = {}
		}
	end
	local bSend = false
	if Messages.Systems [systemName].NextToAdd == Messages.Systems [systemName].NextToSend then
		bSend = true
	end
	Messages.Systems [systemName].Buffer [Messages.Systems [systemName].NextToAdd] = {
																						GLONData = glon.encode (Messages.GLONE2Encode (messageTable)),
																						Type = messageType
																					}
	Messages.Systems [systemName].NextToAdd = Messages.Systems [systemName].NextToAdd + 1
	
	--[[
	Messages.DataTable [Messages.DataNextAdd] = {
													system = systemName,
													data = glon.encode (Messages.GLONE2Encode (messageTable)),
													type = type
												}
	Messages.DataNextAdd = Messages.DataNextAdd + 1	
	]]
end

function Messages.AddTable (messageType, messageTable)
	Messages.AddSystemTable ("global", messageType, messageTable)	
end

--========= Chat messages ===========
function Messages.AddDebugChat (message)
	Messages.AddChat (LocalPlayer (), message)
end

function Messages.AddChat (ply, message)
	Messages.AddTable ("chat", {ply = ply:EntIndex (), msg = message})
end

function Messages.AddChatAll (message)
	for _, ply in pairs (player.GetAll ()) do
		Messages.AddChat (ply, message)
	end
end

--========= Strings ==============
function Messages.AddSystemString (systemName, strData)
	Messages.AddSystemTable (systemName, "string", {msg = strData})
end

function Messages.AddString (strData)
	Messages.AddSystemTable ("global", "string", {msg = strData})
end

--========= Message Sending =======
function Messages.SendNextMessage (systemName)
	local systemEntry = Messages.Systems [systemName]
	if not systemName or not systemEntry then
		return
	end
	local messageArray = {}
	
	while systemEntry.NextToSend < systemEntry.NextToAdd do
		messageArray [#messageArray + 1] = systemEntry.Buffer [systemEntry.NextToSend].GLONData
		systemEntry.Buffer [systemEntry.NextToSend] = ""
		systemEntry.NextToSend = systemEntry.NextToSend + 1
	end
	
	if #messageArray == 0 then
		return
	end
	
	if not Messages.SystemFiles [systemName] then
		Messages.SystemFiles [systemName] = systemName .. ".txt"
	end
	
	--[[
	datastream.StreamToServer ("wire_expression2_filedata", {
																filename = Messages.SystemFiles [systemName],
																filedata = glon.encode (messageArray)
															})
	]]
	LMsg.E2UploadFile (Messages.SystemFiles [systemName], glon.encode (messageArray))
end

-- Old stuff.
LMsg.Hooks.Add ("Tick", "LMsg.GameTick", function ()
	for systemName, _ in pairs (Messages.Systems) do
		LMsg.Messages.SendNextMessage (systemName)
	end
	if true then
		return
	end
	if Messages.NextTick - CurTime () > 0 then
		return
	end
	if Messages.DataTable [Messages.DataNextSend] then
		local tbl = {}
		local data = ""
		local exit = false
		while not exit do
			data = glon.encode (tbl)
			Messages.DataTable [Messages.DataNextSend - 1] = nil
			if not Messages.DataTable [Messages.DataNextSend] then
				exit = true
				break
			end
			local ignore = false
			local system = Messages.DataTable [Messages.DataNextSend].system
			if Messages.DataTable [Messages.DataNextSend].ignore then
				ignore = true
			end
			if system ~= "global" then
				if not LMsg.Systems [system] then
					-- Msg ("System " .. system .. " not found.\n")
				end
				if not LMsg.Systems [system]:IsReceiverActive () then
					-- Msg ("Discarding message from " .. system .. " of type " .. Messages.DataTable [Messages.DataNextSend].type .. ".\n")
					ignore = true
				end
			else
				if !Messages.CanSendMessage () then
					ignore = true
				end
			end
			if ignore then
				Messages.DataNextSend = Messages.DataNextSend + 1
			else
				table.insert (tbl, Messages.DataTable [Messages.DataNextSend].data)
				Messages.DataNextSend = Messages.DataNextSend + 1
				if string.len (glon.encode (tbl)) > cvarCapacity then
					Messages.DataNextSend = Messages.DataNextSend - 1
					exit = true
				else
					Msg ("Added message #" .. tostring (Messages.DataNextSend - 1) .. " to buffer.\n")
				end
			end
		end
		Msg ("Message #" .. tostring (Messages.DataNextSend) .. " is to be sent next.\n")

		Msg ("Buffer length: " .. tostring (string.len (data)) .. "\n")
		for i = 1, cvarCount do
			RunConsoleCommand ("lmsg_message_proxy_data" .. tostring (i), data:sub ((i - 1) * cvarSize + 1, i * cvarSize))
		end
		Msg ("Sent message with ID " .. tostring (Messages.LastSent) .. ".\n")
		Messages.LastSent = Messages.LastSent + 1
		RunConsoleCommand ("lmsg_message_proxy_data_id", tostring (Messages.LastSent))
		timer.Simple (0.06 * cvarCount, function ()
			--[[
			datastream.StreamToServer ("wire_expression2_filedata", {
																		filename = "v_os.txt",
																		filedata = data
																	})
			]]
			-- RunConsoleCommand ("say", "#tick")
		end)
		Messages.NextTick = CurTime () + math.max (0.06 * cvarCount + 0.01, chatDelay)
	end
end)

LMsg.Hooks.Add ("Uninitialize", "LMsg.Messages.Uninitialize", function (reloading)
	if not reloading then
		for systemName, _ in pairs (Messages.Systems) do
			LMsg.Messages.SendNextMessage (systemName)
		end
	end
	timer.Remove ("wire_expression2_file_upload_")
	if E2FileUploading then
		RunConsoleCommand ("wire_expression2_file_finish")
	end
end)

concommand.Add ("lmsg_player_spoke", function (_, _, args)
	local tbl = Messages.GLONE2Decode (glon.decode (Messages.URLDecode (args [1])))
	if tbl.ply == LocalPlayer ():EntIndex () then
		Messages.NextTick = math.max (Messages.NextTick, CurTime () + chatDelay)
	end
	LMsg.Hooks.Call ("PlayerChat", player.GetByID (tbl.ply), tbl.msg)
end)

concommand.Add ("lmsg", function (ply, _, args)
	LMsg.Hooks.Call ("PlayerCommand", ply, args)
end)

LMsg.Hooks.Add ("PlayerCommand", "Messages.Commands", function (ply, args)
	if args [1] == "ack" then
		local ackID = args [2]
		local fileName = args [2]
		if args [2] then
			Messages.LastACKED = tonumber (args [2])
		end
		local systemName = Messages.FileSystems [fileName]
	elseif args [1] == "file" then
		local fileName = args [2]:lower ()
		local systemName = "global"
		if args [3] then
			systemName = args [3]:lower ()
		end
		Messages.SystemFiles [systemName] = fileName
		Messages.FileSystems [fileName] = systemName
		if not Messages.Systems [systemName] then
			Messages.Systems [systemName] = {
				NextToAdd = 1,
				NextToSend = 1,
				Buffer = nil
			}
		end
		Messages.Systems [systemName].Buffer = {}
	end
end)