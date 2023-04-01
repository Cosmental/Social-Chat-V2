--[[

    Name: Mari
    Date: 3/29/2023

    Description: ...

]]--

--// Module
local Extension = {};

Extension.__index = Extension
Extension.__meta = {
    Name = "Server Secret!",
    CreatorId = 876817222, -- userId
    Description = "This is the silliest extension of all time!",
    IconId = "rbxasset://textures/ui/GuiImagePlaceholder.png",
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