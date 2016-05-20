local OBJ = LMsg.Objects.Register ("V OS Process")

function OBJ:__init (processID, program, commandLine, argumentList)
	self.ProcessID = processID
	self.Program = program
	self.CommandLine = commandLine
	self.ArgumentList = argumentList
	
	self.ExitCode = 0
	self.Computer = nil	

	self.Terminated = false
	self.TerminateHooks = {}

	self.StdIn = LMsg.Objects.Create ("V OS Stream")
	self.StdOut = LMsg.Objects.Create ("V OS Stream")
	self.StdErr = LMsg.Objects.Create ("V OS Stream")
	self.StdErr:AddPipe (self.StdOut)
end

function OBJ:__uninit ()
	if not self.Terminated then
		for _, hookFunc in pairs (self.TerminateHooks) do
			hookFunc (self, self.ExitCode)
		end	
	end
	self.TerminateHooks = nil
	
	self.Program = nil
	self.ArgumentList = nil

	self.Computer = nil
	self.StdIn:__uninit ()
	self.StdIn = nil
	self.StdOut:__uninit ()
	self.StdOut = nil
	self.StdErr:__uninit ()
	self.StdErr = nil
	self.Program = nil
end

function OBJ:GetComputer ()
	return self.Computer
end

function OBJ:GetErrorStream ()
	return self.StdErr
end

function OBJ:GetInputStream ()
	return self.StdIn
end

function OBJ:GetOutputStream ()
	return self.StdOut
end

function OBJ:GetProcessID ()
	return self.ProcessID
end

function OBJ:GetProgramName ()
	return self.ArgumentList [1]
end

function OBJ:SetComputer (computer)
	self.Computer = computer
end

function OBJ:Start (commandline, args)
	for k, v in pairs (self.Program:GetContainer ()) do
		if self [k] then
			Msg (k .. " not copied.\n")
		else
			Msg (k .. " = " .. tostring (v) .. "\n")
			self [k] = v
		end
	end
	if self.Main then
		self:Main (commandline, args)
	else
		Msg ("FAIL: Process had no main function.\n")
		self:Terminate (-1)
	end
end

function OBJ:Terminate (returnValue)
	self.Terminated = true
	self.ExitCode = self.ExitCode or returnValue
	for k, hookFunc in pairs (self.TerminateHooks) do
		hookFunc (self, self.ExitCode)
	end
end

function OBJ:WaitForObject (func)
	table.insert (self.TerminateHooks, func)
end