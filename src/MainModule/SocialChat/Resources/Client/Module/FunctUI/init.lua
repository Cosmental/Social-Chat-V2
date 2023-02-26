--[[

    Name: Mari
    Date: 2/22/2023

    Description: FunctUI is a resource module that applies custom UI behavior and feedback via preset modules!

]]--

--// Module
local FunctUI = {};

--// Constants
local Classes = {};

--// Methods

--- Creates the requested FunctUI class! (this is solely a middle-man for the rest of the API(s))
function FunctUI.new(Class : string, ... : any?)
    assert(type(Class) == "string", "FunctUI Failure: Attempt to create class with a type other than a string! (received"..(type(Class))..")");
    assert(Classes[Class], "FunctUI Failure: Requested ClassType \""..(Class).."\" does not exist! (ClassTypes are 'CaseSensitive'!)");

    return Classes[Class].new(...);
end

--// Functions

--// Initialization
local function Initialize()
    for _, Class in pairs(script.Classes:GetChildren()) do
        Classes[Class.Name] = require(Class);
    end

    return setmetatable(FunctUI, {
        __index = function(_, Index : string)
            return Classes[Index];
        end
    });
end

return Initialize();