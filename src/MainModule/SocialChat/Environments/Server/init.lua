--[[

    Name: Mari
    Date: 12/21/2022

    Description: This module handles SocialChat's server-sided environment.

]]--

--// Imports
local Library
local Settings

--// Constants
local ServerComponents = {};

--// States
local isServerReady : boolean?

--// Initialization

local function Initialize(Setup : table)
    Library = Setup.Library
    Settings = Setup.Settings

    --// Component Setup
    --\\ We need to prepare our server components for networking

    for _, SubModule in pairs(script.Components:GetChildren()) do
        if (not SubModule:IsA("ModuleScript")) then continue; end

        local Success, Response = pcall(function()
            return require(SubModule);
        end);

        if (not Success) then continue; end
        ServerComponents[SubModule.Name] = Response
    end

    for Name, Component in pairs(ServerComponents) do
        coroutine.wrap(function()
            local Success, Response = pcall(function()
                return Component:Initialize({
                    ["Settings"] = Settings,
                    ["Library"] = Library,
    
                    ["Remotes"] = game.ReplicatedStorage:WaitForChild("SocialChatEvents"),
                    ["Src"] = ServerComponents
                });
            end);
    
            if (Success) then
                ServerComponents[Name] = Response
            elseif (not Success) then
                error("Failed to initialize SocialChat Server component \""..(Name).."\". ( "..(Response or "No error response indicated!").." )");
            end
        end)();
    end

    isServerReady = true
end

--// Module Request Handling

local function OnRequest()
    if (not isServerReady) then
        return Initialize
    else
        return {
            ["Settings"] = Settings,
            ["Library"] = Library,
            ["Src"] = ServerComponents
        };
    end
end

return OnRequest