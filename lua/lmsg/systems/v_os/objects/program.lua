local OBJ = LMsg.Objects.Register ("V OS Program")

function OBJ:__init (programName, programDescription)
	self.ProgramName = programName
	self.ProgramDescription = programDescription
	
	self.Container = {}
end

function OBJ:__uninit ()
	self.Container = nil
end

function OBJ:GetContainer ()
	return self.Container
end

function OBJ:GetProgramDescription ()
	return self.ProgramDescription
end

function OBJ:GetProgramName ()
	return self.ProgramName
end