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
local Extensions = {};

--// States
local IsRequestable : boolean?

--// Initialization

local function Initialize(Setup : table)
    Library = Setup.Library
    Settings = Setup.Settings

    --// General Setup
    --\\ We need to prepare our server components for networking

    local Network = script.Parent.Parent.Remotes

    --- Extracts modules from the requested container Instance!
    local function Extract(Container : Instance) : table
        local Modules = {};
    
        for _, SubModule in pairs(Container:GetChildren()) do
            if (not SubModule:IsA("ModuleScript")) then continue; end
    
            local Success, Response = pcall(function()
                return require(SubModule);
            end);
    
            if (not Success) then continue; end
            Modules[SubModule.Name] = Response
        end
    
        return Modules
    end

    local ServerExtensions = Extract(game.ServerStorage:WaitForChild("ServerChatExtensions"));
    local SharedExtensions = Extract(game.ReplicatedStorage:WaitForChild("SharedChatExtensions"));

    for Name, Module in pairs(ServerExtensions) do
        Extensions[Name] = Module
    end

    for Name, Module in pairs(SharedExtensions) do
        Extensions[Name] = Module
    end

    ServerComponents = Extract(script.Components);

    --// Extension Data Support
    --\\ We must provide support from DataService to Extensions. Extensions with a "__data" module will be used as their structure

    local ExtensionStructures = {};

    local function GetDataStructures(Container : Instance)
        for _, SubModule in pairs(Container:GetChildren()) do
            if (not SubModule:IsA("ModuleScript")) then continue; end
            if (not SubModule:FindFirstChild("__data")) then continue; end

            ExtensionStructures[SubModule.Name] = require(SubModule.__data);
        end
    end

    GetDataStructures(game.ServerStorage.ServerChatExtensions);
    GetDataStructures(game.ReplicatedStorage.SharedChatExtensions);
    GetDataStructures(game.ReplicatedFirst:WaitForChild("ClientChatExtensions"));

    --// Secure Initialization
    --\\ We must securely initialize ALL of our components using programming standards that assist us in debugging.

    for Name, Component in pairs(ServerComponents) do
        local StartTick = os.clock();
        local ProcessFinished : boolean?

        --// Initialization of our module
        --\\ Wrapped in a seperate thread function for simultaneous startup

        coroutine.wrap(function()

            --// Infinite Yield Warning
            --\\ A warning for truly strange cases that fetch no errors

            coroutine.wrap(function()
                local WarningFired : boolean? -- We only want to send an infinite yield warning ONCE!

                repeat
                    if ((not WarningFired) and ((os.clock() - StartTick) >= 5)) then
                        WarningFired = true
                        warn("Infinite Yield Possible on SocialChat Server Component \""..(Name).."\". (this process has exceeded the intended initialization time)");
                    end
                    
                    task.wait();
                until
                (ProcessFinished or WarningFired);
            end)();

            --// Pcall Handling
            --\\ Implemented for proper error catching

            local Success, Response = pcall(function()
                return Component:Initialize({
                    ["Settings"] = Settings,
                    ["Library"] = Library,
    
                    ["Remotes"] = Network,
                    ["Src"] = ServerComponents,

                    ["__extensionData"] = ExtensionStructures
                });
            end);

            ProcessFinished = true -- This should only run when our pcall finishes
    
            if (Success) then
                ServerComponents[Name] = Response
            elseif (not Success) then
                error("Failed to initialize SocialChat Server component \""..(Name).."\". ( "..(Response or "No error response indicated!").." )");
            end

        end)();
    end

    --// Extension Setup
    --\\ This will initialize and return a list of registered extensions on our server!
    
    for Name, API in pairs(Extensions) do
        local Success, Response = pcall(function()
            return API:Deploy({
                ["Settings"] = Settings,
                ["Library"] = Library,
                ["Remotes"] = Network,

                ["Src"] = Extensions,
                ["Components"] = ServerComponents
            });
        end);

        if (not Success) then
            error("Failed to start extension \""..(Name).."\"! ("..(Response or "No response indicated")..")");
        end
    end

    Network.ExtensionGateway.OnServerInvoke = function()
        local Data = {};

        for Name, API in pairs(Extensions) do
            Data[Name] = API.__meta
        end
        
        return Data
    end

    IsRequestable = true -- You may now request SocialChat's API!
end

--// Module Request Handling

local function OnRequest()
    if (not IsRequestable) then
        return Initialize
    else
        return {
            ["Settings"] = Settings,
            ["Library"] = Library,

            ["Src"] = ServerComponents,
            ["Extensions"] = Extensions
        };
    end
end

return OnRequest