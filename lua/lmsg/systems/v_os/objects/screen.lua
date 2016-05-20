local OBJ = LMsg.Objects.Register ("V OS Screen")

function OBJ:__init (computer, screenName)
	self.Computer = computer
	self.ScreenName = screenName
	
	self.CursorX = 0
	self.CursorY = 0
	self.Width = 60
	self.Height = 36
	self.TextColor = 999

	self.StdOut = LMsg.Objects.Create ("V OS Stream")
	self.StdOut:AddWriteHook (function (stream, data)
		self:WriteConsoleString (data)
	end)
end

function OBJ:__uninit ()
	self.Computer = nil
	self.StdOut:__uninit ()
	self.StdOut = nil
end

function OBJ:Clear ()
	self.Computer:SendMessage ("clrscr")
end

function OBJ:GetOutputStream ()
	return self.StdOut
end

function OBJ:OffsetCursor (x, y)
	if !y then
		y = 0
	end
	self.CursorX = self.CursorX + x
	self.CursorY = self.CursorY + y
end

function OBJ:Reset ()
	self.CursorX = 0
	self.CursorY = 0
	self:Clear ()
end

function OBJ:SendCursorPos ()
	self.Computer:SendMessage ("cursorpos", {x = self.CursorX, y = self.CursorY})
end

function OBJ:SetBackgroundColor (color)
	self.BackgroundColor = color
	self.Computer:SendMessage ("bgcolor", {value = color})
end

function OBJ:WriteStringCenter (str)
	self:WriteString (math.floor ((self.Width - str:len ()) / 2), math.floor ((self.Height - 1) / 2), str)
end

function OBJ:WriteConsoleString (str)
	if type (str) != "string" then
		Msg ("FAIL: Screen::WriteConsoleString called with a non-string!\n")
		return
	end
	str = str:gsub ("\t", "    ")
	local exploded = string.Explode ("\n", str)
	local newexploded = {}
	local x = self.CursorX
	for k, v in pairs (exploded) do
		if k > 1 then
			x = 0
		end
		if x + v:len () > 60 then
			table.insert (newexploded, v:sub (1, 60 - x))
			v = v:sub (59 - x)
			while v:len () > 60 do
				table.insert (newexploded, v:sub (1, 60))
				v = v:sub (61)
			end
			table.insert (newexploded, v)
			x = 0
		else
			table.insert (newexploded, v)
		end
	end
	for i = 1, #newexploded do
		if i > 1 then
			self.CursorY = self.CursorY + 1
			self.CursorX = 0
		end
		if newexploded [i]:len () > 0 then
			self:WriteString (self.CursorX, self.CursorY, newexploded [i])
		end
		self.CursorX = self.CursorX + newexploded [i]:len ()
	end
end

function OBJ:WriteString (x, y, str)
	self.Computer:SendMessage ("text", {x = x, y = y, value = self.TextColor, msg = str})
end