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
local VERSION = require(script:WaitForChild("VERSION"));
local Trace = require(script:WaitForChild("Trace"));

--// States
local ChatServer : table?
local ChatClient : table?

local wasInitialized : boolean

--// Initializer
function GetSocialChat()
    if (not wasInitialized) then

        --// Sub-Imports
        local Environments = script.Environments
        local Resources = script.Resources

        local Server = ((IsServer) and (require(Environments.Server)));
        local Client = ((not IsServer) and (require(Environments.Client)));

        --// Module Collection
        local Library = {};

        local function AddToLibrary(Container : Folder) : table
            for _, Module in pairs(Container:GetDescendants()) do
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

        AddToLibrary((IsServer and Resources.Server) or Resources.Client);
        AddToLibrary(Resources.Shared);

        --// Configurations
        local Configurations = {};

        local function AddToConfiguration(Container : Folder, CustomEntryType : string?)
            if (CustomEntryType) then
                Configurations[CustomEntryType] = {};
            end

            for _, Module in pairs(Container:GetDescendants()) do
                if (not Module:IsA("ModuleScript")) then continue; end
                if (Module.Parent:IsA("ModuleScript")) then continue; end

                local Success, Response = pcall(function()
                    return require(Module);
                end);

                if (not Success) then continue; end

                if (CustomEntryType) then
                    Configurations[CustomEntryType][Module.Name] = Response
                else
                    Configurations[Module.Name] = Response
                end
            end
        end

        if (IsServer) then
            AddToConfiguration(game.ServerStorage:WaitForChild("ServerChatSettings"));
            AddToConfiguration(game.ReplicatedFirst:WaitForChild("ClientChatSettings"), "Client");
        else
            AddToConfiguration(game.ReplicatedFirst:WaitForChild("ClientChatSettings"));
        end

        AddToConfiguration(game.ReplicatedStorage:WaitForChild("SharedChatSettings"));

        --// Initialization
        if (IsServer) then
            local Remotes = script.Remotes

            Server()({
                ["Library"] = Library,
                ["Settings"] = Configurations,

                ["Trace"] = Trace,
                ["VERSION"] = VERSION
            });

            Remotes.Name = "SocialChatEvents"
            Remotes.Parent = game.ReplicatedStorage

            Remotes.EventClientReady.OnServerEvent:Connect(function(Player : Player)
                if (CollectionService:HasTag(Player, "SocialChatClientReady")) then return; end
                CollectionService:AddTag(Player, "SocialChatClientReady");
            end);

            ChatServer = Server();
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
            
            Client()({
                ["Library"] = Library,
                ["Settings"] = Configurations,

                ["Trace"] = Trace,
                ["VERSION"] = VERSION
            });

            ChatClient = Client(); -- We need to update this value because its state returns a new value
        end

        wasInitialized = true
    end

    return (
        ((IsServer) and (ChatServer))
            or (ChatClient)
    );
end

return GetSocialChat();