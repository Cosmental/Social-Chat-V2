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
local IsRequestable : boolean?

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
    
                    ["Remotes"] = game.ReplicatedStorage:WaitForChild("SocialChatEvents"),
                    ["Src"] = ServerComponents
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
            ["Src"] = ServerComponents
        };
    end
end

return OnRequest