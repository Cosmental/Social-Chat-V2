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
local RunService = game:GetService("RunService");

--// Imports
local RichString
local SmartText
local Settings

local ChatUIManager
local TextStyles
local InputBox

--// Constants
local Player = game.Players.LocalPlayer
local OnMessageRendered = Instance.new("BindableEvent");

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
local GradientLabels = {};

--// Initialization

function ChannelMaster:Initialize(Setup : table)
    local self = setmetatable(Setup, ChannelMaster);

    ChatFrame = self.ChatUI.Chat
    MessageContainer = ChatFrame.Input.MessageContainer

    ChannelBar = ChatFrame.ChannelBar
    ChannelFrame = ChannelBar.Channels

    Settings = self.Settings.Channels
    RichString = self.Library.RichString
    SmartText = self.Library.SmartText
    InputBox = self.Src.InputBox

    ChatUIManager = self.Src.ChatUIManager
    TextStyles = self.Settings.Styles
    Network = self.Remotes.Channels
    Presets = self.Presets

    --// Cache Folder
    ChatCacheContainer = Instance.new("Folder");
    ChatCacheContainer.Name = "CLIENT_CHAT_CACHE"
    ChatCacheContainer.Parent = script

    --// Gradient Control
    for _, Info in pairs(TextStyles) do
        Info.Color = ExtractKeypointData(Info.Gradient, math.abs(Info.Keypoints));
        Info.Duration = math.max(Info.Duration, 0.01); -- Durations are limited to 0.1 seconds! (anything less would be weird/un-needed)
    end

    local LastTick = os.clock(); -- We need to use operating UNIX timestamps to rate-limit our gradient stepper!

    RunService.Heartbeat:Connect(function()
        if (not next(GradientLabels)) then return; end
        if ((os.clock() - LastTick) <= 1 / 60) then return; end -- 60 FPS Limit

        LastTick = os.clock();

        for _, GradientGroup in pairs(GradientLabels) do
            local FrameBuffer = (os.clock() - GradientGroup.LastTick);
            if (FrameBuffer < GradientGroup.Style.Duration / GradientGroup.Style.Keypoints) then continue; end

            GradientGroup.LastTick = os.clock();
            GradientGroup.Index += 1

            for Index, Object in pairs(GradientGroup.Objects) do
                Object.TextColor3 = GradientGroup.Style.Color[((Index + GradientGroup.Index) % GradientGroup.Style.Keypoints) + 1]
            end
        end
    end);

    --// Events
    Network.EventSendMessage.OnClientEvent:Connect(function(Message : string, Destination : Channel | Player, Metadata : table?, IsFromUs : boolean?)
        local SpeakerData = ((Metadata and Metadata.Classic) or {});
        
        if (typeof(Destination) == "Instance" and Destination:IsA("Player")) then -- Private Message
            if (TotalChannels >= 2) then -- Create the message in a new PRIVATE channel!
                local PrivateChannel = self:Get(Destination.Name);
                
                if (not PrivateChannel) then
                    PrivateChannel = self.new(Destination.Name, {Destination}, nil, true);

                    if (IsFromUs) then
                        PrivateChannel:Focus();
                    end
                end

                PrivateChannel:Render(Message, SpeakerData);
            else -- Create the message in our current channel!
                local CurrentChannel = self:GetFocus();
                CurrentChannel:Render(Message, SpeakerData, true, IsFromUs);
            end
        else -- Channel Mesage
            local DirectedChannel = self:Get(Destination.Name);

            if (not DirectedChannel) then -- The desired channel for this message does not exist!
                warn("SocialChatClient Channel Manager received a message from the server for a channel that the client has not registed! ( Channel: \""..(Destination).."\" || Message: \""..(Message).."\" )");
                return;
            end

            DirectedChannel:Render(Message, SpeakerData);
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
                if (not ChatUIManager.Enabled) then return; end -- Our ChatUI is not currently enabled! Channel switching is temporarily disabled
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
        MarkdownEnabled = (Metadata and Metadata.BypassMarkdownSetting) or Settings.AllowMarkdown
    });
    
    local Content = {
        ["SmartStringObject"] = StringRenderer,
        ["Render"] = MainFrame,
        ["Gradients"] = {},
    };

    --// Dynamic Rendering
    local function Generate(TextGroupName : string, Text : string, Properties : table, ButtonCallback : callback?, IsTag : boolean?)
        local TextObjects : table = ContentRenderer:Generate(Text, Properties.Font, function(TextObject)
            if (typeof(Properties.Color) ~= "Color3") then return; end
            TextObject.TextColor3 = Properties.Color
        end, ButtonCallback ~= nil, (IsTag or Settings.AllowMarkdown));

        local GradientData : table?

        if (type(Properties.Color) == "string") then
            GradientData = {
                ["Style"] = TextStyles[Properties.Color],

                ["LastTick"] = 0,
                ["Index"] = 0,

                ["Objects"] = TextObjects
            };

            table.insert(GradientLabels, GradientData);
            table.insert(Content.Gradients, GradientData);
        end

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
            if (Metadata.Tag.Icon) then
                local ImageLabel = Instance.new("ImageLabel");

                ImageLabel.BackgroundTransparency = 1
                ImageLabel.Image = "rbxthumb://type=Asset&id="..(Metadata.Tag.Icon).."&w=420&h=420"
                ImageLabel.Name = "TAG_ICON"
                
                StringRenderer:AddGroup("TagIcon", {ImageLabel}, Settings.MessageFont);
                ImageLabel.Parent = MainFrame
            end

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
                    if (Metadata.UserId == Player.UserId) then return; end -- We cant whisper to ourselves! (and... we're also using name strings because Metadata doesn't pass UserIds) [TEMP]

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

    --// Handling
    StringRenderer.Container = MainFrame
    StringRenderer.BindSizeToContent = true
    StringRenderer:Update(); -- We need to update our renderer for setting updates

    if (FocusedChannel == self) then
        MainFrame.Parent = MessageContainer
    end

    --// Trash Collection & Finalization
    if (#self._cache >= Settings.MaxRenderableMessages) then
        self._cache[1].SmartStringObject:Destroy();
        self._cache[1].Render:Destroy();

        for _, GradientArray in pairs(self._cache[1].Gradients) do
            table.remove(GradientLabels, table.find(GradientLabels, GradientArray));
        end

        table.remove(self._cache, 1); -- Our oldest rendered content will always be our 1st index!
    end

    table.insert(self._cache, Content);
    StringRenderer:Update(); -- We need to AGAIN update our renderer to match up with its parent container

    --// Visual Tweening
    --\\ This has to occur after our LAST manual StringRenderer update! (otherwise the rendered will just deny certain tweens!)
    for _, Label in pairs(MainFrame:GetChildren()) do
        if (not Label:IsA("TextLabel") and not Label:IsA("TextButton")) then continue; end -- Just in case...

        local RelativePosition = Label.Position
        local RelativeSize = Label.Size

        local BaseStrokeTransparency = Label.TextStrokeTransparency
        local BaseStrokeColor = Label.TextStrokeColor3
        local BaseColor = Label.TextColor3

        Settings.OnLabelRendered(Label); -- This should adjust our label visually

        TweenService:Create(Label, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {
            Position = RelativePosition,
            Size = RelativeSize,

            TextStrokeColor3 = BaseStrokeColor,
            TextColor3 = BaseColor,

            TextStrokeTransparency = BaseStrokeTransparency,
            TextTransparency = 0
        }):Play();
    end

    OnMessageRendered:Fire(Message, Metadata, self, IsPrivateMessage);
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
    for _, Content in pairs(self._cache) do
        for _, GradientArray in pairs(Content.Gradients) do
            table.remove(GradientLabels, table.find(GradientLabels, GradientArray));
        end

        Content.SmartStringObject:Destroy();
        Content.Render:Destroy();
    end

    self = nil
end

--// Functions

--- Returns a set of color keypoints related to the provided ColorGraident!
function ExtractKeypointData(Gradient : UIGradient, Numerations : number) : table
    local Points = Gradient.Color.Keypoints
    local Data = {};

    for i = 1, Numerations do
        local Alpha = i / Numerations
        
        local ClosestKeypoint, Index : ColorSequenceKeypoint?, number
        local BestOffset : number?
        
        for i, Keypoint in pairs(Points) do
            local Offset = math.abs(Alpha - Keypoint.Time);
            if (BestOffset and Offset > BestOffset) then continue; end
            
            ClosestKeypoint = Keypoint
            Index = i
            
            BestOffset = Offset
        end
        
        local LerpedColor : Color3?
        
        if ((i == 1 or i == #Points) or (BestOffset == 0)) then
            LerpedColor = ClosestKeypoint.Value
        else
            if (Index >= #Points) then
                LerpedColor = Points[Index - 1].Value:Lerp(ClosestKeypoint.Value, Alpha);
            else
                LerpedColor = ClosestKeypoint.Value:Lerp(Points[Index + 1].Value, Alpha);
            end
        end

        table.insert(Data, LerpedColor);
    end

    return Data
end

ChannelMaster.Registry = SystemChannels
ChannelMaster.MessageRendered = OnMessageRendered.Event -- function(Message : string, Metadata : table, Channel : Channel, IsPrivate : boolean)

return ChannelMaster