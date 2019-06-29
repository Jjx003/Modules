--[[
	Author: Jeff Xu (cxcharlie)
	Date: June 27th, 2019
	Filename: die_module.lua
]]--

-- Example Usage:
--[[
	
local n = dice.new()
n.addFace(1,1);
n.addFace(2,2);
n.addFace(3,3);

local agg = {0,0,0};

for i = 1,5000 do
	local r = n.rollWeighted();
	agg[r] = agg[r] + 1;
end

local total = (agg[1]+agg[2]+agg[3])
print('expected:', 1/6, 'result:', agg[1]/total)
print('expected:', 2/6, 'result:', agg[2]/total)
print('expected:', 3/6, 'result:', agg[3]/total)

--]]


local dice = {}

local RANDOM = math.random;

-- Returns a new callable die
function dice.new()
	local die = {};
	die.faces = {};
	die.temp = {};
	
	function die.setSeed( seed )
		math.randomseed( seed );
	end
	
	-- Add a face to the die with its probability.
	-- If you only wish to roll the die unweighted (equal prob.) don't worry about weight value,
	--	just call rollUnweighted()
	function die.addFace( name, weight )
		die.faces[ #die.faces + 1 ] = { name, weight };
	end
	
	-- Weighted roll
	function die.rollWeighted()
		local range = 0;
		local endPoints = { }; -- End points are the end of the ranges; each index corr. to faces[i]
		local lowerBound = 0;
		for i, set in pairs( die.faces ) do 
			range = range + set[ 2 ] * 10; -- Accumulate the weights, mult by ten for better range
			endPoints[ i ] = range; -- Add previous range to get to actual end point
			lowerBound = range;
		end
		local n = RANDOM( 0, range - 1 );
		lowerBound = 0;
		local selectedIndex;
		for i, upperBound in pairs( endPoints ) do
			if ( n >= lowerBound and n < upperBound ) then
				selectedIndex = i;
				break;
			end
			lowerBound = upperBound;
		end
		return die.faces[ selectedIndex ][ 1 ]; -- Return the name
	end

	-- Remove some faces for the next roll
	function die.tempFilter( func )
		local t = {};
		for _, face in pairs( die.faces ) do
			if ( func( face[ 1 ] ) ) then
				t[ #t + 1 ] = face;
			end
		end
		die.temp = die.faces;
		die.faces = t;
	end
	
	-- Restore those faces
	function die.restore()
		die.faces = die.temp;
	end
	
	-- Equal probability roll
	function die.rollUnweighted( )
		local i = math.random( 1, #die.faces );
		return die.faces[ i ][ 1 ]; -- Return the name
	end
	
	-- Clear the faces
	function die.reset()
		die.faces = {};
	end
	
	-- Send to g.c.
	function die.destroy()
		die.reset();
		die = nil;
	end
	
	return die;
end




return dice
