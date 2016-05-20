local SYSTEM = LMsg.CreateSystem ("Youtube Control")
SYSTEM.Autorun = true
SYSTEM.Mode = 1

function SYSTEM:GenerateYoutubePlayerURL (url)
	url = "http://" .. url
	string.gsub (url, "http://http://", "http://")
	return "'//--></script><iframe src=\"" .. url .. "\" style=\"width: 100%; height: 100%; position: absolute; top: 0px; left: 0px\" /><!--"
end

function SYSTEM:GenerateYoutubePlayerVideo (id)
	return "http://www.youtube.com/watch?v=" .. id
end

function SYSTEM:GenerateYoutubePlayerMessage (message)
	return "'//--></script><span style=\"width: 100%; height: 100%; position: absolute; top: 0px; left: 0px; color: white; text-align: center; font-size: 32\">" .. message .. "</span><!--"
end

function SYSTEM:SendYoutubeURL (url, mode)
	if mode == 0 then
		datastream.StreamToServer ("youtube_url_message", {["url"] = url})
	else
		RunConsoleCommand ("youtube_player_url", url)
	end
end

SYSTEM:AddCommand ("yt_video", function (self, ply, id)
	self:SendYoutubeURL (self:GenerateYoutubePlayerVideo (id), self.Mode)
end)

SYSTEM:AddCommand ("yt_url", function (self, ply, url)
	self:SendYoutubeURL (self:GenerateYoutubePlayerURL (url), self.Mode)
end)

SYSTEM:AddCommand ("yt_message", function (self, ply, message)
	self:SendYoutubeURL (self:GenerateYoutubePlayerMessage ("<br /><br />" .. message), self.Mode)
end)