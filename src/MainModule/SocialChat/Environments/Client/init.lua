--[[

    Name: Mari
    Date: 12/21/2022

    Description: This module handles SocialChat's client-sided environment.

]]--

--// Imports
local TopbarPlus

--// Constants
local Network = game.ReplicatedStorage:WaitForChild("SocialChatEvents");
local Player = game.Players.LocalPlayer

local Handlers
local UIComponents

local ChatToggleButton
local CacheFolder
local ChatUI

local Library
local Settings

--// States
local isClientReady : boolean?

--// Functions

--- Extracts modules from a container
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

--- Initializes Modular APIs within the specified array
local function Init(Components : table) : table
    for Name, Component in pairs(Components) do
        local Success, Response = pcall(function()
            return Component:Initialize({
                ["Settings"] = Settings,
                ["Library"] = Library,
                ["Cache"] = CacheFolder,

                ["Presets"] = script.Presets,
                ["Remotes"] = Network,

                ["Handlers"] = Handlers,
                ["Src"] = Components,

                ["ChatButton"] = ChatToggleButton,
                ["ChatUI"] = ChatUI
            });
        end);

        if (Success) then
            Components[Name] = Response
        elseif (not Success) then
            error("Failed to initialize SocialChat component \""..(Name).."\". ("..(Response or "No error response indicated!").." )");
        end
    end

    return Components
end

--// Initialization

local function Initialize(Setup : table)
    TopbarPlus = Setup.Library.TopbarPlus
    ChatUI = script.Chat

    Library = Setup.Library
    Settings = Setup.Settings

    ChatToggleButton = TopbarPlus.new();

    --// Cache
    --\\ This serves as our client's cache for any SAVED instances create by the chat system

    CacheFolder = Instance.new("Folder");
    CacheFolder.Name = "ClientCache"
    CacheFolder.Parent = script.Parent

    --// Component Setup
    --\\ We need to prepare our UI components. This helps with control, readability, and overall cleanlyness!

    Handlers = Init(Extract(script.Handlers));
    UIComponents = Init(Extract(script.Components));

    --// TopbarPlus Control
    --\\ This is going to be our main chatFrame button (special thanks to TopbarPlus!)

    ChatToggleButton:setImage("rbxasset://textures/ui/TopBar/chatOn.png")
        :setCaption("SocialChat "..(Setup.VERSION))
        :select()
        :setProperty("deselectWhenOtherIconSelected", false)
        :setOrder(1)
        -- :bindToggleItem(ChatUI) [Disabled because we can handle this ourselves]

    ChatToggleButton:bindEvent("selected", function()
        ChatToggleButton:clearNotices();
        UIComponents.ChatUIManager:Interact();
    end);

    ChatToggleButton:bindEvent("deselected", function()
        UIComponents.ChatUIManager:SetEnabled(false);
    end);

    UIComponents.Channels.MessageRendered:Connect(function()
        if (ChatToggleButton.isSelected) then return; end
        ChatToggleButton:notify();
    end);

    --// Client Setup
    --\\ These are extra tweaks used for SocialChat!

    game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false);
    ChatUI.Parent = Player.PlayerGui -- Our ChatGUI needs to be parented BEFORE we initialize our Service!

    game.ReplicatedStorage.SocialChatEvents.EventClientReady:FireServer(); -- This tells our server that our client is ready to recieve networking calls!
    isClientReady = true
end

--// Module Request Handling

local function OnRequest()
    if (not isClientReady) then
        return Initialize
    else
        return {
            ["Settings"] = Settings,
            ["Library"] = Library,
    
            ["Handlers"] = Handlers,
            ["Src"] = UIComponents,
    
            ["ChatButton"] = ChatToggleButton,
            ["ChatUI"] = ChatUI
        };
    end
end

return OnRequest