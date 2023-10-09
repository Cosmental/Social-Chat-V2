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
local ContentProvider = game:GetService("ContentProvider")
local IsServer = game:GetService("RunService"):IsServer();

--// Imports
local VERSION = require(script:WaitForChild("VERSION"));
local Trace = require(script:WaitForChild("Trace"));

--// Constants
local Player = game.Players.LocalPlayer

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
            AddToConfiguration(game.ReplicatedStorage:WaitForChild("ChatSettings"):WaitForChild("Client"), "Client");
        else
            AddToConfiguration(game.ReplicatedStorage:WaitForChild("ChatSettings"):WaitForChild("Client"));
        end

        AddToConfiguration(game.ReplicatedStorage.ChatSettings:WaitForChild("Shared"));

        --// Module Collection
        local Library = {};

        local function AddToLibrary(Container : Folder) : table
            for _, Module in pairs(Container:GetDescendants()) do
                if (not Module:IsA("ModuleScript")) then continue; end
                if (Module.Parent:IsA("ModuleScript")) then continue; end

                --[[
                    TopbarPlus UI Config Controller
                        >> Yes this is very inefficient but its the only method I could think of for this scenario
                ]]--

                local DoesUseModernTBP : boolean? = Configurations.Channels.ModernTopbarPlusEnabled

                if (not DoesUseModernTBP and Module.Name == "ModernTBP") then
                    Module.Parent.LegacyTBP.Name = "TopbarPlus"

                    if (Library.LegacyTBP) then
                        Library.TopbarPlus = Library.LegacyTBP
                        Library.LegacyTBP = nil
                    end

                    continue;
                elseif (DoesUseModernTBP and Module.Name == "LegacyTBP") then
                    Module.Parent.ModernTBP.Name = "TopbarPlus"

                    if (Library.ModernTBP) then
                        Library.TopbarPlus = Library.ModernTBP
                        Library.ModernTBP = nil
                    end

                    continue;
                end

                --// Requiring Protocol
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

        --// TopbarPlus Configuration
        if (not IsServer) then
            if (Library.TopbarPlus) then
                local VoiceChatConfiguration : BoolValue? = game.ReplicatedStorage.ChatSettings.Client:WaitForChild("IsVoiceChatEnabled", 3);
                local VoiceChatEnabled = ((VoiceChatConfiguration and VoiceChatConfiguration.Value) or true); -- true by default

                Library.TopbarPlus.voiceChatEnabled = (
                    (VoiceChatEnabled) -- Please configure this in your own game! Developers cant check this automatically with scripts (yet)
                );
            end
        end

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

            --// Preloading
            --\\ Prevents any race-conditions

            if (not game:IsLoaded()) then
                game.Loaded:Wait(); -- Wait's for the game to load. Some games are HEAVY, hence being why we need to add this callback
            end

            --// Temporary Fixes
            --\\ These are un-needed fixes that are automatically applied to the game which can be fixed through a simple setting (most likely)

            if (game.Chat.LoadDefaultChat) then
                warn("\n\t\t\t\t\t\t\t\t\t\"LoadDefaultChat\" is currently enabled!\n\t\t\t\t\t\t\t\t\tAn automatic ChatSystem patch has been applied to provide stability to SocialChat.\n\n\t\t\t\t\t\t\t\t\tPlease Ensure that this setting is disabled through your Explore via\n\t\t\t\t\t\t\t\t\t\"Chat > Properties > Behavior > LoadDefaultChat (disable the checkmark)\"\n\n");
                game.Players.LocalPlayer.PlayerGui:WaitForChild("Chat"):Destroy();
            end

            --// Game Setup

            game.ReplicatedStorage:WaitForChild("SocialChatEvents"); -- This ensures that our server gets setup before any of our clients do
            
            Client()({
                ["Library"] = Library,
                ["Settings"] = Configurations,

                ["Trace"] = Trace,
                ["VERSION"] = VERSION
            });

            ChatClient = Client(); -- We need to update this value because its state returns a new value

            --// Crediting
            --\\ Please do not remove this section!

            if ((game.Players.LocalPlayer.UserId ~= game.CreatorId) and (not game:GetService("RunService"):IsStudio())) then
                warn("--------------------------------------------------");
                print("💬 This game uses SocialChat v2 💬");
                print("🎆 Developed by @Cosmental 🎆");
                print();
                print("Check us out on the DevForums!");
                print("https://devforum.roblox.com/t/social-chat-v2-robloxs-1-open-sourced-chatting-resource/2290658");
                print();
                print(VERSION);
                warn("--------------------------------------------------");
            end
        end

        wasInitialized = true
    end

    return (
        ((IsServer) and (ChatServer))
            or (ChatClient)
    );
end

return GetSocialChat();