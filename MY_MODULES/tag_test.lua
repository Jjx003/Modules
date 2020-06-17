local ReplicatedStorage = game:GetService("ReplicatedStorage");
local tags = require(ReplicatedStorage:WaitForChild('Tags'))

local p1={UserId=100}
local p2={UserId=200}

local info = {
    creator = p1;
    damage = 30;
    timeout = 3;
    type = 'sin',
    type2 = 'wack',
    hitPart = 'Left Arm'
}
local info2 = {
    creator = p1;
    damage = 30;
    timeout = 3;
    type = 'sin',
    type2 = 'wack2',
    hitPart = 'Left Arm'
}

tags:addTag(p2, info);
print(tags:addTag(p2, info));
tags:addTag(p2, info2);
wait(2)
print(tags:addTag(p2, info))
local t = tags:getTags(p2);
for i,v in pairs(t) do
    table.foreach(v, print)
end

