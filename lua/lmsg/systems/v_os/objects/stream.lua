local OBJ = LMsg.Objects.Register ("V OS Stream")

function OBJ:__init ()
	self.Offset = 0
	self.Length = 0
	self.Data = ""

	-- Hooks called when new data is written / available.
	self.WriteHooks = {}
	self.PipedStreams = {}
end

function OBJ:__uninit ()
	self.Data = nil
	self.WriteHooks = {}
end

function OBJ:AddPipe (stream)
	table.insert (self.PipedStreams, stream)
end

function OBJ:AddWriteHook (hookFunc, hookName)
	if not hookName then
		table.insert (self.WriteHooks, hookFunc)
	else
		self.WriteHooks [hookName] = hookFunc
	end
end

function OBJ:Write (data)
	self.Data = self.Data .. data
	for _, hookFunc in pairs (self.WriteHooks) do
		hookFunc (self, data)
	end
	for k, v in pairs (self.PipedStreams) do
		v:Write (data)
	end
end