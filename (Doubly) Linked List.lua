--[[
	Author: Jeff Xu (cxcharlie)
	Date: June 29th, 2019
	Filename: (Doubly) LinkedList.lua
--]]

local LinkedList = {}

local function newNode( value, nex, bef )
	local node = {};
	node.next = nex;
	node.before = bef;
	node.value = value;
	return node;
end

function LinkedList.new()
	
	local list = {
		length = 0;
		head = newNode( nil, nil, nil );
		tail = nil;
	};

	function list.add( value )
		list.length = list.length + 1;
		if ( not list.tail ) then
			local nextNode = newNode( value, nil, nil );
			list.head.next = nextNode;
			list.tail = nextNode;
		else
			local nextNode = newNode( value, list.head.next, list.tail ); -- Next loops back to first, before goes to tail
			list.tail.next = nextNode;
			list.tail = nextNode;
			list.head.next.before = list.tail; -- loop around once again
		end
	end
	
	list.push = list.add;
	
	function list.remove( value )
		local current = list.head.next;
		local iterations = 0;
		while ( current.value ~= value and iterations < list.length ) do
			current = current.next;
		end
		if ( current.value == value ) then
			list.length = list.length - 1;
			if ( current == list.tail ) then
				list.tail.before.next = list.tail.next;
				list.tail = list.tail.before;
				list.head.next.before = list.tail;
			else
				current.before.next = current.next;
			end
		else
			return false;
		end
	end
	
	function list.pop()
		if ( list.length > 0 ) then
			local node = list.tail;
			node.before.next = list.tail.next;
			list.tail = list.tail.before;
			list.head.next.before = list.tail;
			list.length = list.length - 1;
			return node.value;
		end
	end

	
	return list;
end


return LinkedList;
