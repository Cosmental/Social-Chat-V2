--[[

    Name: Mari
    Date: 12/21/2022

    Description: This module handles SocialChat's client-sided environment.

]]--

--// Imports
local TopbarPlus

--// Constants
local Player = game.Players.LocalPlayer
local ChatUI

local Handlers
local UIComponents

local ChatToggleButton
local Library
local Settings

--// States
local isClientReady : boolean?

--// Functions

--- Extracts modules from a container
local function extract(container) : table
    local Modules = {};

    for _, SubModule in pairs(container:GetChildren()) do
        if (not SubModule:IsA("ModuleScript")) then continue; end

        local Success, Response = pcall(function()
            return require(SubModule);
        end);

        if (not Success) then continue; end
        Modules[SubModule.Name] = Response
    end

    return Modules
end

--// Initialization

local function Initialize(Setup : table)
    TopbarPlus = Setup.Library.TopbarPlus
    ChatUI = script.Chat

    Library = Setup.Library
    Settings = Setup.Settings

    --// Cache
    --\\ This serves as our client's cache for any SAVED instances create by the chat system

    local CacheFolder = Instance.new("Folder");
    CacheFolder.Name = "ClientCache"
    CacheFolder.Parent = script.Parent

    --// TopbarPlus Button
    --\\ This is going to be our main chatFrame button (special thanks to TopbarPlus!)

    ChatToggleButton = TopbarPlus.new();
    ChatToggleButton:setImage("rbxasset://textures/ui/TopBar/chatOn.png")
        :setCaption("SocialChat "..(Setup.VERSION))
        :select()
        :bindToggleItem(ChatUI)
        :setProperty("deselectWhenOtherIconSelected", false)
        :setOrder(1)

    ChatToggleButton:bindEvent("selected", function()
        ChatToggleButton:clearNotices();
    end);

    ChatToggleButton:bindEvent("deselected", function()
        
    end);

    --// Component Setup
    --\\ We need to prepare our UI components. This helps with control, readability, and overall cleanlyness!

    UIComponents = extract(script.Components);
    Handlers = extract(script.Handlers);

    for Name, Component in pairs(UIComponents) do
        local Success, Response = pcall(function()
            return Component:Initialize({
                ["Settings"] = Settings,
                ["Library"] = Library,
                ["Cache"] = CacheFolder,

                ["Remotes"] = game.ReplicatedStorage:WaitForChild("SocialChatEvents"),
                ["Presets"] = script.Presets,

                ["Handlers"] = Handlers,
                ["Src"] = UIComponents,

                ["ChatButton"] = ChatToggleButton,
                ["ChatUI"] = ChatUI
            });
        end);

        if (Success) then
            UIComponents[Name] = Response
        elseif (not Success) then
            error("Failed to initialize SocialChat component \""..(Name).."\". ( "..(Response or "No error response indicated!").." )");
        end
    end

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