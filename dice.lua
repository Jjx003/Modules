--[[
	Author: Jeff Xu (cxcharlie)
	Date: June 27th, 2019
	Filename: die_module.lua
]]--

-- Example Usage:
--[[
	
	local a = dice.new();
	a.addFace('bob',1);
	a.addFace('alice',5);
	a.addFace(123,3);
	a.addFace(2,3);
	a.tempFilter( function(a) return type(a)=='string' end)
	
	for i = 1, 20 do 
		print( a.rollWeighted())
	end
	a.restore();
	for i = 1, 20 do 
		print( a.rollWeighted())
	end


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
			range = range + set[ 2 ]; -- Accumulate the weights
			local e = range + lowerBound;
			endPoints[ i ] = e; -- Add previous range to get to actual end point
			lowerBound = e;
		end
		local n = RANDOM( 0, range );
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
