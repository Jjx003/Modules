local Buffs = {
	ID = tostring( tick() )..'BUFFS';
	ENABLED = false;
	STATS = {}; -- set 
	Current = {};
};

local Network;
local TagService;

local SLOW_SPEED = 0;
local FAST_SPEED = 0;
local HEALTH_REGEN = 0;
local LAST_DMG = tick();

local Templates = {};



local assets = script:WaitForChild( 'assets' );
local player, character, humanoid



-------------------------------------------------------------------
-------------------------------------------------------------------
local RunService = game:GetService( 'RunService' );
local tableRemove = table.remove;
local clamp = math.clamp;

local function connectNetworkListeners()
	Network:add('buff', function( source, name, timer, rate, ... )
		Buffs.addBuff( source, name, timer, rate, ... )
	end)
	player = game:GetService( 'Players' ).LocalPlayer;
	character = player.Character;
	wait(.1);
	humanoid = character:WaitForChild( 'Humanoid' );	
end

function Buffs:hook( network, tagservice )

	
	Network = network;
	TagService = tagservice;
	connectNetworkListeners();
end

function Buffs:sendBuff( target , name, timer, rate, ... )
	Network:send( 'buff', target , name, timer, rate, ... )
end



function Buffs.addBuff( source, name, timer, rate, ... )
	local capture = { ... };
	if Buffs.ENABLED then
		if Templates[ name ] then
			local buffObject = Templates[ name ]( source, timer, rate, unpack( capture ) );
			if buffObject then
				local concurrent = Buffs.Current[ name ];
				if concurrent then
					concurrent.update( timer, rate, unpack( capture ) );
				else
					Buffs.Current[ name ] = buffObject;
				end
			end
		else
			warn( name..' is not a buff!' );
		end
	else
		warn( 'Buffs are currently disabled!' );
	end
end

local connections = {};

local function startBuffsThread()
	
	local last_tick = tick();
	
	--[[
		Event is important in calculating the last time player was hurt
		This is then used to determine whether or not player can heal
	--]]
	local last_health = humanoid.Health;
	connections[ #connections + 1 ] = humanoid.HealthChanged:connect( function( new_health )
		if new_health - last_health < 0 then
			LAST_DMG = tick();
			last_health = new_health;
		end
	end )
	
	RunService:BindToRenderStep( Buffs.ID, Enum.RenderPriority.Last.Value + 1, function()
		
		local now = tick();
		local dt = now - last_tick;
		last_tick = now;
		
		humanoid.WalkSpeed = Buffs.STATS.BASE_SPEED * 
			clamp( ( 1 - SLOW_SPEED + Buffs.STATS.BUFF_RESISTS.SLOW ), 0, 1) * ( 1 + FAST_SPEED );
		
		if now - LAST_DMG >= Buffs.STATS.HEALTH_REGEN.BUFFER then
			print'can regin'
			humanoid.Health = clamp( humanoid.Health + Buffs.STATS.HEALTH_REGEN.RATE * dt * 25,
			 0, humanoid.MaxHealth );
		else 
			print'aa'
		end
		
		for index, buff in pairs( Buffs.Current ) do 
			buff.timer = buff.timer - dt; -- 'remaining' represents time remaning
			if buff.timer <= 0 then
				if buff.stop() then -- doesn't necessarily stop if 
					tableRemove( Buffs.Current, index );
				end
			else
				if now - buff.last_callback >= buff.rate then
					pcall( buff.callback() ); -- runs the call back; can be used for stuff like poison over time.
					buff.last_callback = now;
				end
			end
		end
		
	end )
end

local function tryDisconnect(f)
	f:disconnect();
end

local function stopBuffsThread()
	for i = 1, #connections do
		pcall( tryDisconnect, connections[i] );
		connections[ i ] = nil;
	end
	RunService:UnbindFromRenderStep( Buffs.ID );
end

function Buffs.initStats( stats )
	Buffs.STATS = stats; -- would use metatables but its just ugly;
end

function Buffs.changeStats( index, value )
	Buffs.STATS[ index ] = value;
end

function Buffs.toggle( state )
	if Buffs.ENABLED == state then 
		warn('Buffs already '..( state and 'enabled' or 'disabled')..'!' );
	elseif state then
		-- enable
		startBuffsThread();
	elseif not state then
		-- disable
		pcall( stopBuffsThread )
	end
end
	
function Buffs:disconnect()
	pcall( stopBuffsThread );
end

-------------------------------------------------------------------
-------------------------------------------------------------------


local function doNothing()
end

local function newBuffObject( timer, callback, update, stop, rate, offset )
	local b         = {};
	b.timer         = timer;
	b.callback      = callback or doNothing;
	b.update        = update or doNothing;
	b.stop          = stop or doNothing;
	b.rate          = rate or math.huge;
	b.last_callback = tick() - ( offset or 0 );
	b.que           = {}; -- buff called more than once is put in que 
	return b
end

function Templates.slow( source, timer, rate, percent )
	

	local timer = timer;
	local rate = rate or 0;
	local percent = percent or .25;
	
	local myBuff = newBuffObject( timer, nil, nil, nil, 0, 0 )
	
	local function slow() -- /frame
		--humanoid.WalkSpeed = Buffs.STATS.BASE_SPEED * clamp(( 1 - percent + Buffs.STATS.BUFF_RESISTS.SLOW ), 0, 1);
		SLOW_SPEED = percent;
		if myBuff.timer < 1 then
			SLOW_SPEED = percent * ( myBuff.timer );
		end
	end
	
	--[[
		Called when a new buff with the same name is added; Used to 
		  overwrite current slow percents/timers
	--]]
	local function update(_timer, _rate, _percent) -- single
		if _percent > percent then -- if greater, then overwrite 
			myBuff.timer = _timer;
			myBuff.rate  = _rate or 0;			
			percent      = _percent or .25;
		else
			myBuff.que[ #myBuff.que + 1 ] = { tick(), _timer, _rate, _percent };
		end
	end
	
	--[[
		Called when buff timer ends; Handles ques in the following way:
			1) Orders que from Highest to Lowest -- This is done in
	 			order to make sure that speed doesn't fluctuate;
				highest slow percent overwrites other slows
			2) Sets the new slow percent to this next highest slow
				value, timer, and rate
			
			Every time stop() is called it will move onto next que
			until empty, before finally bringing walkspeed to normal;
	--]]
	local function stop()
		if #myBuff.que > 0 then
			table.sort( myBuff.que, function( a, b )
				return a[ 3 ] > b[ 3 ];
			end )
			for i = 1, #myBuff.que do
				local set, _timer, _rate, _percent = myBuff.que[ i ];
				if tick() - set <= _timer then
					timer   = _timer;
					rate    = _rate;
					percent = _percent;
					
					tableRemove( myBuff.que, i );
					return false
				end
			end
		end
		SLOW_SPEED = 0; -- fix walkspeed
		return true -- remove from concurrent buffs
	end
	
	myBuff.callback = slow;
	myBuff.update = update;
	myBuff.stop = stop;

	return myBuff
end


return Buffs;
