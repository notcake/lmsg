LMsg.Lua = LMsg.Lua or {}

function LMsg.Lua.Include (file)
	include ("lmsg/" .. file)
end

--[[
	Includes all lua files in a folder.
	folder is the folder to include.
	pre is a function that is run before every file is included.
	post is a function that is run after every file is included.
]]
function LMsg.Lua.IncludeFolder (folder, pre, post)
	local files = file.FindInLua ("lmsg/" .. folder .. "/*.lua")
	for _, v in pairs (files) do
		if pre then
			pre (v)
		end
		include ("lmsg/" .. folder .. "/" .. v)
		if post then
			post (v)
		end
	end
end