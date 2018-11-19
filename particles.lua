--hello, cxcharlie here
--I used some modules (cframe/vector3) made by axisangles lol
--scroll down to read how to use

--module.FreeBody(...)
--module.FreeBody2(...)
--module.Start() -- starts it
--module.Stop() -- stops and deletes all particles

local module = {};
local asset = script:WaitForChild'Part';
local vector = {};
local cframe = {};
local v3 = Vector3.new;
local cf = CFrame.new;
local RUNSERVICE = game:GetService('RunService');

local time_scale = 1; -- real time; make less than 1 to slow down and higher to speed up.
local BOI = tick

local function tick()
	return BOI() * time_scale;
end

do

	local pi		= math.pi
	local cos		= math.cos
	local sin		= math.sin
	local acos		= math.acos
	local asin		= math.asin
	local atan2		= math.atan2
	local random	= math.random
	local v3		= Vector3.new
	local nv		= Vector3.new()

	vector.identity = nv
	vector.new = v3
	vector.lerp = nv.lerp
	vector.cross = nv.Cross
	vector.dot = nv.Dot

	function vector.random(a, b)
		local p		= acos(1 - 2 * random()) / 3
		local z		= 3 ^ 0.5 * sin(p) - cos(p)
		local r		= ((1 - z * z) * random()) ^ 0.5
		local t		= 6.28318 * random()
		local x		= r * cos(t)
		local y		= r * sin(t)
		if b then
			local m	= (a + (b - a) * random()) / (x * x + y * y + z * z) ^ 0.5
			return	v3(m * x, m * y, m * z)
		elseif a then
			return	v3(a * x, a * y, a * z)
		else
			return	v3(x, y, z)
		end
	end
end

do
	local pi			= math.pi
	local halfpi		= pi / 2
	local cos			= math.cos
	local sin			= math.sin
	local acos			= math.acos
	local v3			= Vector3.new
	local nv			= v3()
	local cf			= CFrame.new
	local nc			= cf()
	local components	= nc.components
	local tos			= nc.toObjectSpace
	local vtos			= nc.vectorToObjectSpace
	local ptos			= nc.pointToObjectSpace
	local backcf		= cf(0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1)
	local lerp			= nc.lerp

	cframe.identity		= nc
	cframe.new			= cf
	cframe.vtws			= nc.vectorToWorldSpace
	cframe.tos			= nc.toObjectSpace
	cframe.ptos			= nc.pointToObjectSpace
	cframe.vtos			= nc.vectorToObjectSpace


	function cframe.fromaxisangle(x, y, z)
		if not y then
			x, y, z = x.x, x.y, x.z
		end
		local m = (x * x + y * y + z * z) ^ 0.5
		if m > 1e-5 then
			local si = sin(m / 2) / m
			return cf(0, 0, 0, si * x, si * y, si * z, cos(m / 2))
		else
			return nc
		end
	end

	function cframe.toaxisangle(c)
		local _, _, _,
			xx, yx, zx,
			xy, yy, zy,
			xz, yz, zz = components(c)
		local co = (xx + yy + zz - 1) / 2
		if co < -0.99999 then
			local x = xx + yx + zx + 1
			local y = xy + yy + zy + 1
			local z = xz + yz + zz + 1
			local m = pi * (x * x + y * y + z * z) ^ -0.5
			return v3(m * x, m * y, m * z)
		elseif co < 0.99999 then
			local x = yz - zy
			local y = zx - xz
			local z = xy - yx
			local m = acos(co) * (x * x + y * y + z * z) ^ -0.5
			return v3(m * x, m * y, m * z)
		else
			return nv
		end
	end

	function cframe.direct(c, look, newdir, t)
		local lx, ly, lz		= look.x, look.y, look.z
		local rv			= vtos(c, newdir)
		local rx, ry, rz		= rv.x, rv.y, rv.z
		local rl			= ((rx * rx + ry * ry + rz * rz) * (lx * lx + ly * ly + lz * lz)) ^ 0.5
		local d				= (lx * rx + ly * ry + lz * rz) / rl
		if d < -0.99999 then
			return c * backcf
		elseif d < 0.99999 then
			if t then
				local th	= t * acos(d) / 2
				local qw	= cos(th)
				local m		= rl * ((1 - d * d) / (1 - qw * qw)) ^ 0.5
				return		c * cf(
							0, 0, 0,
							(ly * rz - lz * ry) / m,
							(lz * rx - lx * rz) / m,
							(lx * ry - ly * rx) / m,
							qw
							)
			else
				local qw	= ((d + 1) / 2) ^ 0.5
				local m		= 2 * qw * rl
				return		c * cf(
							0, 0, 0,
							(ly * rz - lz * ry) / m,
							(lz * rx - lx * rz) / m,
							(lx * ry - ly * rx) / m,
							qw
							)
			end
		else
			return			c
		end
	end

	function cframe.toquaternion(c)
		local x, y, z,
			xx, yx, zx,
			xy, yy, zy,
			xz, yz, zz	= components(c)
		local tr		= xx + yy + zz
		if tr > 2.99999 then
			return		x, y, z, 0, 0, 0, 1
		elseif tr > -0.99999 then
			local m		= 2 * (tr + 1) ^ 0.5
			return		x, y, z,
						(yz - zy) / m,
						(zx - xz) / m,
						(xy - yx) / m,
						m / 4
		else
			local qx	= xx + yx + zx + 1
			local qy	= xy + yy + zy + 1
			local qz	= xz + yz + zz + 1
			local m		= (qx * qx + qy * qy + qz * qz) ^ 0.5
			return		x, y, z, qx / m, qy / m, qz / m, 0
		end
	end

	function cframe.power(c, t)
		return lerp(nc, c, t)
	end


	cframe.interpolate = lerp

	--local toquaternion=cframe.toquaternion
	function cframe.interpolator(c0, c1, c2)
		if c2 then
			return function(t)
				return lerp(lerp(c0, c1, t), lerp(c1, c2, t), t)
			end
		elseif c1 then
			return function(t)
				return lerp(c0, c1, t)
			end
		else
			return function(t)
				return lerp(nc, c0, t)
			end
		end
	end
end

local fbodies = {};
local fbodies2 = {};
local count = 0;
local dampening =  1;

--this freebody has constant linear/rotational acceleration
--position the part's cframe before running this function

--part: the part (USERDATA/PART)
--t: the life time of the part (NUMBER)
--v0: the initial velocity of part (VECTOR)
--a: acceleration of part (VECTOR)
--rv0: initial rotational velocity (VECTOR)
--ra: initial rotational acceleration (VECTOR)

function module.FreeBody(part, t, v0, a, rv0, ra)
	count = count + 1;
	local name = tostring(count)..'_render'
	local t0 = tick();


	local pos0 = part.CFrame.p;
	local matrix0 = part.CFrame - pos0;

	local v = v0 / time_scale;
	local rv = rv0 / time_scale;


	local n = {
		part = part;
		t = t;
		t0 = t0;
		v0 = v0;
		a = a;
		rv0 = rv0;
		ra = ra;
		pos0 = pos0;
		matrix0 = matrix0;
	}

	fbodies[part] = n;
end



--this function is similar to FreeBody() except that it can take account of
--variable linear/rotational acceleration, where the acceleration arguments can be functions
--see example usages

--part: the part (USERDATA/PART)
--t: the life time of the part (NUMBER)
--v0: the initial velocity of part (VECTOR)
--a: acceleration of part (VECTOR/FUNCTION)
--rv0: initial rotational velocity (VECTOR)
--ra: initial rotational acceleration (VECTOR/FUNCTION)
function module.FreeBody2(part, t, v0, a, rv0, ra)
	count = count + 1;
	local name = tostring(count)..'_render'
	local t0 = tick();


	local pos0 = part.CFrame.p;
	local matrix0 = part.CFrame - pos0;

	local v = v0 / time_scale;
	local rv = rv0 / time_scale;

	local n = {
		part = part;
		t = t;
		t0 = t0;
		v = v0;
		lv = v0;
		a = a;
		rv = rv0;
		ra = ra;
		pos0 = pos0;
		matrix0 = matrix0;
	}

	if type(a) == 'function' or type(ra) == 'function' then
		local house = {};
		for i, v in pairs({
			'a',
			'ra'
		}) do
			if type(n[v]) == 'function' then
				house[v] = n[v];
				n[v] = nil;
			end
		end
		setmetatable(n, {
			__index = function(s, i)
				return house[i](s)
			end
		})
	end

	fbodies2[part] = n;
end


local max_v = math.huge -- may cause a lot of bugs. if your particles go flying then set a max_v

local last = tick();
local from_aa = cframe.fromaxisangle;
local to_aa = cframe.toaxisangle;

function module.Start()
	pcall(function()
		RUNSERVICE:UnbindFromRenderStep('FREE')
	end)
	RUNSERVICE:BindToRenderStep('FREE', Enum.RenderPriority.Camera.Value + 1, function() -- the render function

		local now = tick();
		local dt = now - last;

		for part, body in pairs(fbodies) do
			if body and now - body.t0 < body.t then
				local t = now - body.t0;
				local t_2 = t * t;
				part.CFrame = from_aa(body.rv0 * t + 0.5 * body.ra * t_2) * body.matrix0 + body.pos0 + body.v0 * t + 0.5 * body.a * t_2
			else
				part:Destroy()
				fbodies[part] = nil;
			end
		end
		for part, body in pairs(fbodies2) do
			if body and now - body.t0 < body.t then
				local t = now - body.t0;
				local calculated = body.v + (body.a * dt) * dampening;
				if calculated.magnitude > max_v then
					calculated = calculated.unit * max_v
				end
				body.v = calculated;
				body.rv = body.rv + (body.ra * dt) * dampening;
				part.CFrame = part.CFrame * from_aa(body.rv * dt) + body.v * dt
			else
				part:Destroy()
				fbodies[part] = nil;
			end
		end
		last = tick()
	end)
end

function module.Stop()
	pcall(function()
		RUNSERVICE:UnbindFromRenderStep('FREE')
		for part, body in pairs(fbodies) do
			part:Destroy();
		end
		for part, body in pairs(fbodies2) do
			part:Destroy();
		end
		fbodies = {};
		fbodies2 = {};
	end)
end

return module
