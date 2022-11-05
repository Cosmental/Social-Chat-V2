--[[

	Name: Cosmental
	Date: 3/16/2022
	
	Description: The Maid module is designed for easy and simply task handling and sweeping!

]]--

--// Cleaning Methods
local Sweeper = {
	["RBXScriptConnection"] = function(Signal)
		Signal:Disconnect();
	end,

    ["table"] = function(Array : table)
        for k, _ in pairs(Array) do
            Array[k] = nil
        end
    end,

	["Instance"] = function(Object)
		Object:Destroy();
	end,

	["function"] = function(Func)
		Func();
	end
};

--// Module
local Maid = {};
local Methods = {};
Methods.__index = Methods

--// Constructor

function Maid.new() -- Constructs a new Maid object
	return setmetatable({
		["Tasks"] = {}
	}, Methods);
end

--// Methods

function Methods:Task(Object : Instance, Tag : string?) -- Assigns a given object into our Maid (Identification tag is opt.)
	assert(Sweeper[typeof(Object)], "Maid currently doesnt support "..typeof(Object));
	self.Tasks[table.getn(self.Tasks) + 1] = {
       ["Object"] = Object,
       ["Tag"] = Tag
    };
end

function Methods:Unmark(Query : Instance | string?) -- Unassigns a given object in our Maid through its Instance or Tag (if any)
	for Index, Value in pairs(self.Tasks) do
		if ((Query == Value.Object) or ((Value.Tag) and (Query == Value.Tag))) then
			table.remove(self.Tasks, Index);
		end
	end
end

function Methods:Sweep() -- Destroys every assigned "task" object in our Maid
	for _, Task in pairs(self.Tasks) do
		local success, response = pcall(function()
			Sweeper[typeof(Task.Object)](Task.Object); --// Sweeps our object
		end);
		
		if (not success) then
			warn("Maid failed to sweep item, response:", response);
		end
	end
end

function Maid:Destroy() -- Destroys our Maid
    self:Sweep();
    self = nil
end

return Maid