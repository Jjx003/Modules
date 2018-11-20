--not mine, some cool stuff though

math.randomseed(os.time())

Worm = {
	stepDistMin = 5, stepDistMax = 15, 
	stepNumMin = 500, stepNumMax = 2000,
	rotSpeed = 0.2,
	rotSpeedX = .1,
	rotSpeedY = .4,
	rotSpeedZ = 0,
	startCFrame = CFrame.new(), nodes = {}
}

function Worm:new(startCFrame)
  local object = {}
  setmetatable(object, self)
  self.__index = self
	
	object.startCFrame = startCFrame or CFrame.new()
	object:generate()

  return object
end

function Worm:setStepNum(stepNumMin, stepNumMax)
	self.stepNumMin = stepNumMin
	self.stepNumMax = stepNumMax
end

function Worm:setStepDist(stepDistMin, stepDistMax)
	self.stepDistMin = stepDistMin
	self.stepDistMax = stepDistMax
end

function Worm:setRotSpeed(r, x, y, z)
	self.rotSpeed = r
	self.rotSpeedX = x or self.rotSpeedX
	self.rotSpeedY = y or self.rotSpeedY
	self.rotSpeedZ = z or self.rotSpeedZ
end

function Worm:generate()
	local seedX, seedY, seedZ = math.random()*10e5, math.random()*10e5, math.random()*10e5
	local stepNum = math.random(self.stepNumMin, self.stepNumMax)
	
	self.nodes = {self.startCFrame}
	local lastPoint = self.nodes[1]
	local rotX, rotY, rotZ = 0, 0, 0
	
	for i = 1, stepNum do
		rotX = rotX + math.noise(i * self.rotSpeed, seedX) * self.rotSpeedX
		rotY = rotY + math.noise(i * self.rotSpeed, seedY) * self.rotSpeedY
		rotZ = rotZ + math.noise(i * self.rotSpeed, seedZ) * self.rotSpeedZ
		
		rotX = math.min(math.max(rotX, -.1), .1)
		rotY = math.min(math.max(rotY, -.1), .1)
		rotZ = math.min(math.max(rotZ, -.1), .1)
		
		local nextPoint = lastPoint * CFrame.Angles(rotX, rotY, rotZ)
		nextPoint = nextPoint * CFrame.new(0, 0, 10)
		
		table.insert(self.nodes, nextPoint)
		lastPoint = nextPoint
	end
end

function Worm:visualize()
	if self.nodes then
		for i = 1, #self.nodes - 1 do
			local node1 = self.nodes[i]
			local node2 = self.nodes[i + 1]
			
			local dist = (node1.p - node2.p).magnitude
			local dir = (node1.p - node2.p).Unit
			
			local beam = Instance.new("Part", game.Workspace)
			beam.Anchored = true
			beam.Material = "Neon"
			beam.Size = Vector3.new(1, 1, dist)
			beam.CFrame = CFrame.new(node1.p, node2.p) - (dir * dist * 0.5)
		end
	end
end

function Worm:getPoints()
	return self.points
end

local w = Worm:new(CFrame.new())
w:setRotSpeed(0.05, 0.001, 0.1, 0)
w:visualize()
