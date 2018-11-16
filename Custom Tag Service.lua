local tags = {}
local events = {}
local minimum_comparison = 1.5

local random = math.random
local max = math.max
local ton = tonumber
local tos = tostring
local match = string.match
local concat = table.concat
local sort = table.sort
local gsub = string.gsub
local module = {}

setmetatable(module, {__index = module})
--now need a table of players, telling me whether they alive or dead
local players = {}

local default = {
	__eq = function(a,b)
		return (a.main == b.main and a.sub == b.sub) or false
	end,
	__add = function(a, b)
		if a == b then --goes to the __eq operator
			a.data = a.data + b.data
			a.times[#a.times+1] = b.last_time --im not sure if we need the individual times at this point. Oh well. DATA OVERLOAD. jk
			a.last_time = b.last_time
			return a
		end
	end,
	__tostring = function(self)
		return concat({self.main, self.sub, self.data, self.last_time},'/')
	end,
--	__metatable = 'cannot modify',
}


function NewEvent(main_name, sub_name, value, time)
	return setmetatable({
		main = main_name,
		sub = sub_name,
		last_time = time,
		times = {time},
		data = value,
		}, default)
end


local player_service = game:GetService'Players'
player_service.PlayerRemoving:connect(function(p)--cause somereason PlayerRemoving doesn't work in testplaysolo
	if p.ClassName == 'Player' then
		tags[p.Name] = nil
	else

	end
end)


--should rewrite this for table storage, not userdata storage
--tag format
local template = {
['Start'] = tick(),
--['Damage'] = {["1"]=50,["30"]=25}--[time after start (template.Start-tick())] = damage done, (assume last damage to be death tick())
['Events'] = {["1"]="Damaged 50 with smash attack"},
['Creator'] = 'Damager guy name',
['Active'] = true, --whether or not its the alst person to tag
}

--so all I need to add is the damage values
--**NOTE: need to tag player before applying event/damage!
--event format (string) example: 'damage/20'

--things to do:
--make start (time) universal based on the game starting time
--basically make a function that re-defines a new start time

local Enabled
local Starting_Time


function module:Enable(p)
	Enabled = true
	Starting_Time = tick()
	--players = {['Dummy']=true}
	for i = 1, #p do
		players[p[i].Name] = true --set them to alive=true
	end

end

function module:Disable() --just in case wonky stuff happnes?
	tags = {} --reset the table
	players = {}
	Enabled = false
end

--tags>{person that was tagged =
--			{index# =
--				{ table =
--					{Creator = tagger.Name,
--					Events = {	{time occure, event name}	}
--					Active = true/false ~ whether or not is last tag


--time is still tick() here, it will fix after calculatiions
function module:NewTag(tagger, player, main_name, sub_name, value, time) --probably need to fix the event argument
	if not Enabled or not players[player.Name] then print'o fk' return end --prevent tagging while disabled or while player already dead

	local event = NewEvent(main_name, sub_name, value, time) --*note sub_name should be designated to the attack of main_name weapon

	local name = player.Name
	local search = tags[name] -- all the tags associated with [player]
	local my_tag --my specific tag


	if not search then
		tags[name] = {}
		search = tags[name]
	end

	for i = 1, #search do
		local v = search[i]
		if v.Creator == tagger.Name then
			my_tag = search[i]
			my_tag.Active = true
		else
			v.Active = false --no longer the recent one (not sure if this is efficient, o well)
		end
	end
		--either there is, or there isnt a "my_tag"
	if my_tag then
		--add to existing one!
		--local time_passed =  --rounds to thousandths (o well if it replaces an existing value somehow)
		print'There is an existing tag, adding on to the event list'
		local short = my_tag.Events
		local combined = false
		for i = 1, #short do
			local other_event = short[i]
			if event == other_event and (event.last_time - other_event.last_time) <= minimum_comparison then ---stack same event occurences if they are in the interval
				short[i] = other_event + event --inserts into [times] and adds to [value]
--				print'within same time, adding'
				combined = true
				break
			end
		end
		if not combined then
			short[#short+1] = event --just insert it
		end
	else
		--create one!
--		print'Tag does not exist for this tagger, creating a new one'
		my_tag = {
			Events = {event},
			Creator = tagger.Name,
			Active = true,
		} --dont' need a metatable anymore


		search[#search+1] = my_tag --tadah, we made 1
--		print'Tag inserted'
	end
--	print'------------------'
end

local function FilterTime(table, last_time, max_time)
	local valid = {}
	for i = 1, #table do
		local v = table[i]
		local name = v[1]
		local event = v[2]
		if (last_time - event.last_time) <= max_time then
			valid[#valid+1] = {name, event}
		end
	end
	return valid
end

local function Last10(tag, last)
	--get events in last 10 seconds
	--this might be expensive actually..
	local all_events = {}
	local kill_tag --assume kill_tag to be last tag
	for i = 1, #tag do --i'm using this because it's faster than pairs
		local v = tag[i]
		local list = v.Events
		local name = v.Name
		for ii = 1, #list do
			all_events[#all_events+1] = {name, list[ii]}
		end
	end
	if #all_events <= 0 then print'wot' return false end
	local killer_tag = last --or module:GetLastTag(tag)
	return FilterTime(all_events, killer_tag.last_time, 10) --probably need something to convert to a string output
end

local function CompareEventTime(a,b) return a[5] < b[5] end --switch for most recent to least recent (higher time = more recent)

local function Last10Events(contributors, expire_time)
	local s = tick()
	local expire_time = expire_time or 60
	local all_events = {}
	for i = 1, #contributors do 
		local packet = contributors[i]
		local events = packet.Events

		for ii = 1, #events do --contents of individual tag packet
			local event = events[ii]
			local seconds_after_start = event.last_time - Starting_Time
			if seconds_after_start < expire_time then
				all_events[#all_events+1] = {packet.Creator, event.main, event.sub, event.data, seconds_after_start}
			end
		end
	end
	sort(all_events, CompareEventTime)
	local new_table = {}
	local accurate = {}
	for i = 1, max(#all_events, 10) do
		local tab = all_events[i]
		if tab then
			new_table[#new_table+1] = tab
			accurate[#accurate+1] = {Creator = tab[1], main = tab[2], sub = tab[3], data = tab[4], time = tab[5]}
		end
	end
--	print(tick()-s,' seconds passed')
	return new_table, accurate
end
	

function module.FetchLast10(name)
	local contributors = tags[name]
	if not contributors then return nil end
	return Last10Events(contributors)
end

function module.GetActiveTag(name)--get killer
	local contriubtors = tags[name]
	local last 
	for i = 1, #contriubtors do 
		local a = contriubtors[i]
		if a.Active then 
			last = a
			break
		end
	end
	return last
end




return module
