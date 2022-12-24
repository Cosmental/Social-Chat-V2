--[[

    Name: Mari
    Date: 12/21/2022

    Description: Social Chat is an open sourced Chat System made by @CosRBX on Twitter! This module serves as the main initializer for
    the Chat System. This module should only be initialized ONCE, afterwards you may require it for additional API resourcing.

    ------------------------------------------------------------------------------------------------------------------------------------

    GitHub Resource: https://github.com/Cosmental/Social-Chat

]]--

--// Services
local CollectionService = game:GetService("CollectionService");
local IsServer = game:GetService("RunService"):IsServer();

--// Imports
local Environments = script.Environments
local Resources = script.Resources

local ChatServer = ((IsServer) and (require(Environments.Server)));
local ChatClient = ((not IsServer) and (require(Environments.Client)));

--// States
local wasInitialized : boolean

--// Initializer
function getSocialChat()
    if (not wasInitialized) then

        --// Module Collection
        local Library = {};

        local function GatherModules(container : Folder) : table
            for _, Module in pairs(container:GetDescendants()) do
                if (not Module:IsA("ModuleScript")) then continue; end
                if (Module.Parent:IsA("ModuleScript")) then continue; end

                local Success, Response = pcall(function()
                    return require(Module);
                end);

                if (Success) then
                    Library[Module.Name] = Response
                end
            end
        end

        GatherModules((IsServer and Resources.Server) or Resources.Client);
        GatherModules(Resources.Shared);

        --// Configurations
        local Directory = game.ReplicatedStorage:WaitForChild("SocialChatConfigurations");
        local EnvironmentConfiguration = ((IsServer and Directory.Server) or Directory.Client);

        local Configurations = {};

        for _, Module in pairs(EnvironmentConfiguration:GetDescendants()) do
            if (Module:IsA("ModuleScript") and not Module.Parent:IsA("ModuleScript")) then
                Configurations[Module.Name] = require(Module);
            end
        end

        --// Initialization
        if (IsServer) then
            local Remotes = script.Remotes

            ChatServer:Init({
                ["Library"] = Library,
                ["Settings"] = Configurations
            });

            Remotes.Name = "SocialChatEvents"
            Remotes.Parent = game.ReplicatedStorage

            Remotes.EventClientReady.OnServerEvent:Connect(function(Player : Player)
                if (CollectionService:HasTag(Player, "SocialChatClientReady")) then return; end
                CollectionService:AddTag(Player, "SocialChatClientReady");
            end)
        else

            --// Temporary Fixes
            --\\ These are un-needed fixes that are automatically applied to the game which can be fixed through a simple setting (most likely)

            if (game.Chat.LoadDefaultChat) then
                warn("\n\t\t\t\t\t\t\t\t\t\"LoadDefaultChat\" is currently enabled!\n\t\t\t\t\t\t\t\t\tAn automatic ChatSystem patch has been applied to provide stability to SocialChat.\n\n\t\t\t\t\t\t\t\t\tPlease Ensure that this setting is disabled through your Explore via\n\t\t\t\t\t\t\t\t\t\"Chat > Properties > Behavior > LoadDefaultChat (disable the checkmark)\"\n\n");
                game.Players.LocalPlayer.PlayerGui:WaitForChild("Chat"):Destroy();
            end

            --// Game Setup

            game.ReplicatedStorage:WaitForChild("SocialChatEvents"); -- This ensures that our server gets setup before any of our clients do

            if (not game:IsLoaded()) then
                game.Loaded:Wait(); -- Wait for our game to load on our client
            end
            
            ChatClient:Init({
                ["Library"] = Library,
                ["Settings"] = Configurations
            });

        end

        wasInitialized = true
    end

    return (
        ((IsServer) and (ChatServer))
            or (ChatClient)
    );
end

return getSocialChat();