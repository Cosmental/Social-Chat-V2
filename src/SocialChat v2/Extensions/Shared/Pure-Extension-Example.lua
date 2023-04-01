--[[

    Name: Mari
    Date: 3/29/2023

    Description: ...

]]--

--// Module
local Extension = {};

Extension.__index = Extension
Extension.__meta = {
    Name = "Example-Extension",
    CreatorId = 80677808, -- userId
    Description = "This is the silliest extension of all time!",
    IconId = "http://www.roblox.com/asset/?id=12293400310",
    Version = "1.0"
};

--// Main

--- The initialization method for our Extension. This will setup and initialize this extension indefinitely
function Extension:Deploy(SocialChat : metatable)
    local self = setmetatable(SocialChat, Extension);

    return self
end

--// Methods

--- Example Method
function Extension:Foo()
    
end

--// Functions

--- Example Function
function Bar()
    
end

return Extension