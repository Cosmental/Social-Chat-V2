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

local UIComponents
local Extensions = {};

local ChatToggleButton
local CacheFolder
local ChatUI

local Library
local Settings

--// States
local IsClientReady : boolean?

local DidDataLoadSuccessfully : boolean?
local SocialChatData : table?

--// Initialization
local function Initialize(Setup : table)
    TopbarPlus = Setup.Library.TopbarPlus
    ChatUI = script.Chat

    Library = Setup.Library
    Settings = Setup.Settings

    ChatToggleButton = TopbarPlus.new();

    --// Data Initiation
    --\\ This will request Data from the server whenever it is called!

    local Success, Response = pcall(function()
        local Data : table, WasSuccessful : boolean? = Network.DataService.EventReplicateData:InvokeServer();

        DidDataLoadSuccessfully = WasSuccessful
        SocialChatData = Data
    end);

    if (not Success) then
        warn("SocialChat Client Failed to retrieve data from the server! (Response: "..(Response)..")");
    end

    --// Cache
    --\\ This serves as our client's cache for any SAVED instances create by the chat system

    CacheFolder = Instance.new("Folder");
    CacheFolder.Name = "ClientCache"
    CacheFolder.Parent = script.Parent

    --// Data configuration with Settings
    --\\ Changes values for certain configurations

    for Category : string, Data : table in pairs(Settings) do
        --local Objects = {};

        for Entry : string, _ in pairs(Data) do
            local Configuration = SocialChatData.Settings[Entry];
            if (not Configuration) then continue; end

            Settings[Category][Entry] = (if (Configuration.Value ~= nil) then (Configuration.Value) else (Configuration.Default));
        end
    end

    --// Component Setup
    --\\ We need to prepare our UI components. This helps with control, readability, and overall cleanlyness!

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

    UIComponents = Extract(script.Components);
    
    local ClientExtensions = Extract(game.ReplicatedFirst:WaitForChild("ClientChatExtensions"));
    local SharedExtensions = Extract(game.ReplicatedStorage:WaitForChild("SharedChatExtensions"));

    for Name, Module in pairs(ClientExtensions) do
        Extensions[Name] = Module
    end

    for Name, Module in pairs(SharedExtensions) do
        Extensions[Name] = Module
    end

    --[[

        IMPORTANT NOTICE:

        As of 2/25/2023, while working on the Control Panel's Settings page; I ran into the issue in which components such as the
        'ChatUIManager' and the 'Channels' module were unable to communicate values from one another. However, the UIManager can
        access variables of the 'Channels' module easily?

        After a deeper look, I discovered that this was due to a constent change caused by a RemoteEvent which apparently reaches
        the scope of all other modules. While intruiging, I was unable to find out why this happens and how I can fix it if at all.

        Whatever the result may be, please do not edit the way these modules preload each other! They are structured this way for a reason,
        albeit looks ugly.

    ]]--

    for Name, Module in pairs(UIComponents) do
        local StartTick = os.clock();
        local ContentReady : boolean?

        --// Infinite Yield Warning
        --\\ A warning for truly strange cases that fetch no errors

        coroutine.wrap(function()
            local WarningFired : boolean? -- We only want to send an infinite yield warning ONCE!

            repeat
                if ((not WarningFired) and ((os.clock() - StartTick) >= 5)) then
                    WarningFired = true
                    warn("Infinite Yield Possible on SocialChat Client Component \""..(Name).."\". (this process has exceeded the intended initialization time)");
                end
                
                task.wait();
            until
            (ContentReady or WarningFired);
        end)();

        --// Pcall Handling
        --\\ Implemented for proper error catching

        local Success, Response = pcall(function()
            return Module:Initialize({
                ["Settings"] = Settings,
                ["Library"] = Library,
                ["Cache"] = CacheFolder,
                
                ["Presets"] = script.Presets,
                ["Remotes"] = Network,
                ["Src"] = UIComponents,
                ["Extensions"] = Extensions,

                ["ChatButton"] = ChatToggleButton,
                ["ChatUI"] = ChatUI,
                
                ["Data"] = SocialChatData,
                ["FFLAG_DataFailure"] = DidDataLoadSuccessfully
            });
        end);

        ContentReady = true

        if (Success) then
            UIComponents[Name] = Response
        elseif (not Success) then
            error("Failed to initialize SocialChat component: \""..(Name).."\". ("..(Response).." )");
        end
    end

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

    UIComponents.Channels.OnMessaged:Connect(function()
        if (ChatToggleButton.isSelected) then return; end
        ChatToggleButton:notify();
    end);

    --// Extension Setup
    --\\ This is where we setup all of our extensions!

    for Name, API in pairs(Extensions) do
        local Success, Response = pcall(function()
            return API:Deploy({
                ["Settings"] = Settings,
                ["Library"] = Library,
                
                ["Presets"] = script.Presets,
                ["Remotes"] = Network,
                ["Src"] = Extensions,
                ["Components"] = UIComponents,
    
                ["ChatButton"] = ChatToggleButton,
                ["ChatUI"] = ChatUI,
                
                ["Data"] = SocialChatData,
                ["FFLAG_DataFailure"] = DidDataLoadSuccessfully
            });
        end);

        if (not Success) then
            error("Failed to start extension \""..(Name).."\"! ("..(Response or "No response indicated")..")");
        end
    end

    --// Client Setup
    --\\ These are extra tweaks used for SocialChat!

    game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false);
    ChatUI.Parent = Player.PlayerGui -- Our ChatGUI needs to be parented BEFORE we initialize our Service!

    game.ReplicatedStorage.SocialChatEvents.EventClientReady:FireServer(); -- This tells our server that our client is ready to recieve networking calls!
    IsClientReady = true
end

--// Module Request Handling
local function OnRequest()
    if (not IsClientReady) then
        return Initialize
    else
        return {
            ["Settings"] = Settings,
            ["Library"] = Library,
    
            ["Src"] = UIComponents,
            ["Data"] = SocialChatData,
            ["Extensions"] = Extensions,
    
            ["ChatButton"] = ChatToggleButton,
            ["ChatUI"] = ChatUI,
        };
    end
end

return OnRequest