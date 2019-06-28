--[[
Author: Jeff Xu (cxcharlie)
Date: June 27th, 2019
Filename: dice_module.lua
]]--

local module = {}

local RANDOM = math.random;

function module.newDice()
	local dice = {}
	dice.faces = {}
	
	function dice.setSeed( seed )
		math.randomseed( seed );
	end
	
	function dice.addFace( name, weight )
		dice.faces[ #dice.faces + 1 ] = { name, weight };
	end
	
	function dice.rollWeighted()
		local range = 0;
		local endPoints = { }; -- End points are the end of the ranges; each index corr. to faces[i]
		for i, set in pairs( dice.faces ) do 
			range = range + set[2]; -- Accumulate the weights
			if ( i > 1 ) then
				endPoints[ i ] = range + endPoints[ i - 1 ]; -- Add previous range to get to actual end point
			else
				endPoints[ i ] = range + 0; -- First face, lower bound is zero
			end
		end
		local n = RANDOM( 0, range );
		local lowerBound = 0;
		local selectedIndex;
		for i, upperBound in pairs( endPoints ) do
			if ( n >= lowerBound and n < upperBound ) then
				selectedIndex = i;
				break;
			end
			lowerBound = upperBound;
		end
		return dice.faces[ selectedIndex ][ 1 ]; -- Return the name
	end
	
	function dice.rollUnweighted( )
		local i = math.random( 1, #dice.faces );
		return dice.faces[ i ][ 1 ]; -- Return the name
	end
	
	function dice.reset()
		dice.faces = {};
	end
	
	return dice;
end


return module
