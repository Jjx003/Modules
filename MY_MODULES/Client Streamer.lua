--by cxcharlie
--made it. then realized i didnt need it. :P
local stream = {}

local replicated_storage = game:GetService('ReplicatedStorage');
local http_service = game:GetService('HttpService')
local debris = game:GetService('Debris');
local remotes = replicated_storage:WaitForChild('Remotes');
local stream_folder = remotes:WaitForChild('Streams');

local FIRE_CLIENT = remotes.Stream.FireClient;
local STRING_SUB = string.sub;
local STRING_LEN = string.len;
local MATH_CEIL = math.ceil;
local COROUTINE_WRAP = coroutine.wrap;
local TABLE_REMOVE = table.remove;




local settings = {
	split = 1000;
	expire = 10;
};

local data = {};



function start_stream(remote, player, str, id, Clean)	
	local str_len = STRING_LEN(str);

	if str_len < settings.split then
		FIRE_CLIENT(remote, player, str);
		COROUTINE_WRAP(function()
			wait()
			FIRE_CLIENT(remote, player, 'x'..id); -- tells client data stream finished
		end)
		return
	end
	
	local split_len = MATH_CEIL(str_len/settings.split);
	local ss = settings.split;
	FIRE_CLIENT(remote, player, STRING_SUB(str, 1, ss - 1));
	COROUTINE_WRAP(function()
		wait()
		for i = 2, MATH_CEIL(STRING_LEN(str)/settings.split) do 
			FIRE_CLIENT(remote, player, STRING_SUB(str,(i-1) * ss, (ss * (i)) - 1))
			wait()
		end
		FIRE_CLIENT(remote, player, 'x'..id); -- done
		wait()
		Clean();
	end)()
end


function stream.new(str)
	local str = str;
	local remote = Instance.new('RemoteEvent');
	remote.Parent = stream_folder;
	local id = tostring(http_service:GenerateGUID());
	remote.Name = id;
	
	local stamp = tick();
	local connection = nil;
	
	local function Clean(player)
		str = nil;
		stamp = nil;
		
		if player then
			FIRE_CLIENT(remote, player, false) -- timed out
		end
		
		connection:Disconnect()
		COROUTINE_WRAP(function()
			wait(1);
			remote:Destroy();
		end)()
		return
	end
	
	connection = remote.OnServerEvent:connect(function(player, key)
		if key ~= id then return end -- hacker alert
		if tick() - stamp >= settings.expire then -- death
			Clean(player);
		end
		start_stream(remote, player, str, id, Clean);
	end)

	return remote,id
end




return stream
