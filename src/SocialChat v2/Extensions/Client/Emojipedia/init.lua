--[[

    Name: Mari
    Date: 4/1/2023

    Description: ...

]]--

--// Module
local Extension = {};

Extension.__index = Extension
Extension.__meta = {
    Name = "Example-Extension", -- Extesion Name
    CreatorId = 876817222, -- Creator's UserId
    Description = "This is the silliest extension of all time!", -- Extension Description
    IconId = "http://www.roblox.com/asset/?id=12293400310", -- Extension IconId (must be a decal Id such as "rbxassetid://ID-HERE")
    Version = "1.0" -- Extension version (will be displayed)
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