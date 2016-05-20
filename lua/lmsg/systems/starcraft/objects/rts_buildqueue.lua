local OBJ = LMsg.Objects.Register ("RTS Build Queue")

function OBJ:__init (callbackEntity)
	self.Queue = {}
	self.QueueCount = 0
	self.QueueFrontIndex = 1	-- Front is here
	self.QueueBackIndex = 1		-- Place more here
	
	self.CallbackEntity = callbackEntity
end

function OBJ:__uninit ()
	self.Queue = nil
end

function OBJ:Count ()
	return self.QueueCount
end

function OBJ:Front ()
	return self.Queue [self.QueueFrontIndex]
end

function OBJ:Pop ()
	if self.QueueFrontIndex >= self.QueueBackIndex then
		return
	end
	self.Queue [self.QueueFrontIndex] = nil
	self.QueueFrontIndex = self.QueueFrontIndex + 1
	
	self.QueueCount = self.QueueCount - 1
end

function OBJ:Push (name, startTime, duration)
	self.Queue [self.QueueBackIndex] = {
		Name = name,
		StartTime = nil,
		Duration = duration
	}
	if self:Count () == 0 then
		self.Queue [self.QueueBackIndex].StartTime = CurTime ()
	end
	self.QueueBackIndex = self.QueueBackIndex + 1
	
	self.QueueCount = self.QueueCount + 1
end

function OBJ:Update ()
	if self.QueueCount == 0 then
		return
	end
	local front = self:Front ()
	local curTime = CurTime ()
	while front and front.StartTime + front.Duration < curTime do
		-- While there are done entries, remove them.
		local overdue = curTime - front.StartTime - front.Duration
		self.CallbackEntity:OnBuildQueueDone (front.Name)
		self:Pop ()
		front = self:Front ()
		if front then
			front.StartTime = curTime - overdue
		end
	end
end