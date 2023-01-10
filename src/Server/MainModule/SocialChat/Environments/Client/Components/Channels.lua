--[[

    Name: Mari
    Date: 12/24/2022

    Description: This component module handles system channels and system messaging!

]]--

--// Module
local ChannelMaster = {};
ChannelMaster.__index = ChannelMaster

local Channel = {};
Channel.__index = Channel

--// Services
local TweenService = game:GetService("TweenService");

--// Imports
local RichString
local SmartText
local Settings

local InputBox

--// Constants
local Player = game.Players.LocalPlayer

local ChatFrame
local MessageContainer

local ChannelBar
local ChannelFrame

local Presets
local Network

local ChatCacheContainer : Instance?

--// States
local SystemChannels : table = {};
local TotalChannels = 0

local FocusedChannel : string?

--// Initialization

function ChannelMaster:Initialize(Setup : table)
    local self = setmetatable(Setup, ChannelMaster);

    ChatFrame = self.ChatUI.Chat
    MessageContainer = ChatFrame.Input.MessageContainer

    ChannelBar = ChatFrame.ChannelBar
    ChannelFrame = ChannelBar.Channels

    Settings = self.Settings.LocalChannels
    RichString = self.Library.RichString
    SmartText = self.Library.SmartText
    InputBox = self.Src.InputBox

    Network = self.Remotes.Channels
    Presets = self.Presets

    --// Cache Folder
    ChatCacheContainer = Instance.new("Folder");
    ChatCacheContainer.Name = "CLIENT_CHAT_CACHE"
    ChatCacheContainer.Parent = script

    --// Events
    Network.EventSendMessage.OnClientEvent:Connect(function(Message : string, Destination : Channel | Player, Metadata : table, IsFromUs : boolean?)
        if (typeof(Destination) == "Instance" and Destination:IsA("Player")) then -- Private Message
            if (TotalChannels >= 2) then -- Create the message in a new PRIVATE channel!
                local PrivateChannel = self:Get(Destination.Name);
                
                if (not PrivateChannel) then
                    PrivateChannel = self.new(Destination.Name, {Destination}, nil, true);

                    if (IsFromUs) then
                        PrivateChannel:Focus();
                    end
                end

                PrivateChannel:Render(Message, Metadata.Classic);
            else -- Create the message in our current channel!
                local CurrentChannel = self:GetFocus();
                CurrentChannel:Render(Message, Metadata.Classic, true, IsFromUs);
            end
        else -- Channel Mesage
            local DirectedChannel = self:Get(Destination.Name);

            if (not DirectedChannel) then -- The desired channel for this message does not exist!
                warn("SocialChatClient Channel Manager received a message from the server for a channel that the client has not registed! ( Channel: \""..(Destination).."\" || Message: \""..(Message).."\" )");
                return;
            end

            DirectedChannel:Render(Message, Metadata.Classic);
        end
    end);

    Network.EventLeaveChannel.OnClientEvent:Connect(function(name : string)
        local RequestedChannel = self:Get(name);
        if (not RequestedChannel) then return; end -- This channel isnt registered on our client!

        RequestedChannel:Destroy();
    end);

    Network.EventJoinChannel.OnClientEvent:Connect(function(Name : string, Members : table, History : table)
        self.new(Name, Members, History);
    end);

    return self
end

--// Methods

--- Creates a new channel using the provided parameters
function ChannelMaster.new(name : string, members : table?, chatHistory : table?, isPrivate : boolean?) : Channel
    local SystemChannel = setmetatable({

        --// PROPERTIES \\--

        ["Name"] = name,
        ["History"] = chatHistory,
        ["IsPrivate"] = isPrivate,

        --// PROGRAMMABLE \\--

        ["Members"] = members,
        ["_cache"] = {}
        
    }, Channel);

    --// System Channel Handling
    if (TotalChannels < 1) then -- This is our FIRST channel! Make sure to focus on it o_O
        SystemChannel:Focus();
    else -- Our client has multiple channels registered!
        local function CreateChannelButton(forChannel)
            local ChannelPrefab = Presets.ChannelPrefab:Clone();

            ChannelPrefab.Name = forChannel.Name
            ChannelPrefab.Channel.Text = forChannel.Name

            forChannel.NavButton = ChannelPrefab
            ChannelPrefab.Parent = ChannelFrame

            ChannelPrefab.Channel.MouseButton1Click:Connect(function()
                forChannel:Focus();
            end);
        end

        if (not ChannelBar.Visible) then
            for _, RegisteredChannel in pairs(SystemChannels) do
                CreateChannelButton(RegisteredChannel);
            end

            ChannelBar.Visible = true
        end

        CreateChannelButton(SystemChannel);
        ChannelMaster:GetFocus():Focus(); -- Refocus the currently focused channel in order for us to apply visual changes
    end

    --// Instance registration
    if (SystemChannel.History) then
        for _, Info in ipairs(SystemChannel.History) do
            SystemChannel:Render(Info.Message, SystemChannel.Members[Info.Author].Metadata.Classic);
        end
    end

    SystemChannels[name] = SystemChannel
    TotalChannels += 1

    return SystemChannel
end

-- Returns the requested channel
function ChannelMaster:Get(query : string) : Channel?
    assert(type(query) == "string", "The provided query was not of type \"string\"! ( received \""..(type(query)).."\" instead )");
    return SystemChannels[query];
end

--- Returns the currently focused channel
function ChannelMaster:GetFocus() : Channel
    return FocusedChannel
end

--- Sends a new message to our currently focused channel
function ChannelMaster:SendMessage(text : string, privateRecipient : Player?)
    assert(type(text) == "string", "The provided message content was not of type \"string\"! ( received \""..(type(text)).."\" instead )");
    assert(not privateRecipient or typeof(privateRecipient) == "Instance", "The requested recipient was not of type \"Instance\". ( received \""..(typeof(privateRecipient)).."\" instead )");
    assert(not privateRecipient or privateRecipient:IsA("Player"), "The provided recipient was not of class \"Player\". Only players can recieve private messages!");

    Network.EventSendMessage:FireServer(text, privateRecipient or FocusedChannel.Name);
end

--// Metamethods

--- Renders a message based on the specified parameters
function Channel:Render(Message : string, Metadata : table?, IsPrivateMessage : boolean?, MessageIsFromUs : boolean?) : table
    local MainFrame = Instance.new("Frame");

    MainFrame.BackgroundTransparency = 1
    MainFrame.Name = "MESSAGE_RENDER_FRAME"
    
    local StringRenderer : SmartStringObject = SmartText.new(MessageContainer, {
        MaxFontSize = Settings.MaxFontSize
    });

    local ContentRenderer : StringObject = RichString.new({
        MarkdownEnabled = Settings.AllowMarkdown
    });
    
    local Content = {
        ["Render"] = MainFrame,
        ["SmartStringObject"] = StringRenderer
    };

    --// Dynamic Rendering
    local function Generate(TextGroupName : string, Text : string, Properties : table, ButtonCallback : callback?, IsTag : boolean?)
        local TextObjects = ContentRenderer:Generate(Text, Properties.Font, function(TextObject)
            TextObject.TextColor3 = Properties.Color
        end, ButtonCallback ~= nil, (IsTag or Settings.AllowMarkdown));

        StringRenderer:AddGroup(TextGroupName, TextObjects, Properties.Font);

        for _, TextObject in pairs(TextObjects) do
            if (ButtonCallback) then
                TextObject.MouseButton1Click:Connect(ButtonCallback);
            end

            TextObject.Parent = MainFrame
        end
    end

    if (IsPrivateMessage) then -- Private Message!
        Generate("FromWho",
            "{"
            ..((MessageIsFromUs and "to") or "from").." "
            ..(Metadata.Name).."}: ",
            {Color = Color3.fromRGB(255, 255, 255), Font = Settings.MessageFont},
            nil, true
        );
    else -- Normal Message!
        
        --// Tag Rendering
        if (Metadata and Metadata.Tag) then
            Generate(
                "Tag",
                "**["..(Metadata.Tag.Name).."]** ",
                {
                    ["Color"] = (Metadata.Tag.Color or Color3.fromRGB(255, 255, 255)),
                    ["Font"] = Metadata.Tag.Font or Settings.MessageFont
                },
                nil, true
            );
        end

        --// Name Rendering
        if (Metadata and Metadata.Username) then
            Generate(
                "Name",
                "**["..(Metadata.Username.Name).."]:** ",
                {
                    ["Color"] = Metadata.Username.Color,
                    ["Font"] = Metadata.Username.Font or Settings.MessageFont
                },
                function()
                    if (not Metadata.UserId) then return; end
                    if (Metadata.UserId == Player.UserId) then return; end -- We cant whisper to ourselves!!

                    local Client = game.Players:GetPlayerByUserId(Metadata.UserId);
                    if (not Client) then return; end -- The client either left or isnt in the server anymore :(

                    InputBox:Set("/w "..Client.Name.." ", true);
                end, true
            );
        end

    end

    --// Message Rendering
    Generate(
        "Message",
        Message,
        {
            Color = (Metadata and Metadata.Content and Metadata.Content.Color) or Color3.fromRGB(255, 255, 255),
            Font = (Metadata and Metadata.Content and Metadata.Content.Font) or Settings.MessageFont
        }
    );

    --// Finalization
    StringRenderer.Container = MainFrame
    StringRenderer.BindSizeToContent = true
    StringRenderer:Update(); -- We need to update our renderer for setting updates

    if (FocusedChannel == self) then
        MainFrame.Parent = MessageContainer
    end

    if (#self._cache >= Settings.MaxRenderableMessages) then
        self._cache[1].SmartStringObject:Destroy();
        self._cache[1].Render:Destroy();

        table.remove(self._cache, 1); -- Our oldest rendered content will always be our 1st index!
    end

    table.insert(self._cache, Content);
    StringRenderer:Update(); -- We need to AGAIN update our renderer to match up with its parent container

    return Content
end

--- Sets our client's channel focus on this channel
function Channel:Focus()
    FocusedChannel = self

    for _, ContentFrame in pairs(MessageContainer:GetChildren()) do
        if (not ContentFrame:IsA("Frame")) then continue; end
        ContentFrame.Parent = ChatCacheContainer
    end

    for _, Content in pairs(self._cache) do
        Content.Render.Parent = MessageContainer
    end

    if (self.NavButton) then
        TweenService:Create(self.NavButton, Settings.ChannelFocusTweenInfo, {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.2
        }):Play();

        TweenService:Create(self.NavButton.Channel, Settings.ChannelFocusTweenInfo, {
            TextColor3 = Color3.fromRGB(40, 40, 40)
        }):Play();

        for _, OtherChannel in pairs(SystemChannels) do
            if (OtherChannel.Name == self.Name) then continue; end

            TweenService:Create(OtherChannel.NavButton, Settings.ChannelFocusTweenInfo, {
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.5
            }):Play();
    
            TweenService:Create(OtherChannel.NavButton.Channel, Settings.ChannelFocusTweenInfo, {
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play();
        end
    end
end

--- Removes this channel from our client's channel list and prevents our client from receiving further message events for this channel
function Channel:Destroy()
    for _, ContentFrame in pairs(self._cache) do
        ContentFrame:Destroy();
    end

    self = nil
end

ChannelMaster.Channels = SystemChannels
return ChannelMaster