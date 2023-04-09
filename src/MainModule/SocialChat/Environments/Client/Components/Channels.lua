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

local FunctUI
local Trace : table < TraceAPI >

--// Constants
local OnMessageRendered = Instance.new("BindableEvent");
local Player = game.Players.LocalPlayer

local ChatFrame
local InputFrame

local ChannelBar
local ChannelFrame

local Presets
local Network

--// States
local Registry : table = {}; -- a list of ALL channels
local TotalChannels = 0

local FocusedChannel : string?
local GradientLabels = {};

local RenderHandlers : table < string > = {};

--// Initialization

function ChannelMaster:Initialize(Setup : table)
    local self = setmetatable(Setup, ChannelMaster);

    ChatFrame = self.ChatUI.Chat
    InputFrame = ChatFrame.Input

    ChannelBar = ChatFrame.ChannelBar
    ChannelFrame = ChannelBar.Channels

    Settings = self.Settings.Channels
    RichString = self.Library.RichString
    SmartText = self.Library.SmartText
    FunctUI = self.Library.FunctUI
    InputBox = self.Src.InputBox
    Trace = self.Trace

    ChatUIManager = self.Src.ChatUIManager
    TextStyles = self.Settings.Styles
    Network = self.Remotes.Channels
    Presets = self.Presets

    FunctUI.new("AdjustingCanvas", ChannelFrame, nil, "X");

    --// Gradient Control
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
                Object.TextColor3 = GradientGroup.Style.Color[((Index + GradientGroup.Index) % GradientGroup.Style.Keypoints) + 1];

                local StrokeDifference = math.abs(Object.TextStrokeTransparency - Object.TextTransparency);
                local TransValue = GradientGroup.Style.Transparency[((Index + GradientGroup.Index) % GradientGroup.Style.Keypoints) + 1];

                Object.TextTransparency = TransValue
                Object.TextStrokeTransparency = TransValue + StrokeDifference
            end
        end
    end);

    --// Events
    Network.EventSendMessage.OnClientEvent:Connect(function(Message : string, Destination : Channel | Player, Metadata : table?)
        local SpeakerData = ((Metadata and Metadata.Classic) or {});

        if (typeof(Destination) == "Instance" and Destination:IsA("Player")) then -- Private Message
            if ((TotalChannels >= 2) and (not Settings.HideChatFrame)) then -- Create the message in a new PRIVATE channel!
                local PrivateChannel = self:Get(Destination.Name);
                
                if (not PrivateChannel) then -- Channel doesnt exist yet, so lets make one!
                    PrivateChannel = self:Create(Destination.Name, {Destination}, nil, true);

                    if (SpeakerData.UserId and SpeakerData.UserId == Player.UserId) then
                        PrivateChannel:Focus();
                    end
                end

                PrivateChannel:Message(Message, SpeakerData);
            else -- Create the message in our current channel!
                local CurrentChannel = self:GetFocus();
                CurrentChannel:Message(Message, SpeakerData, true);
            end
        else -- Channel Message
            local DirectedChannel = self:Get(Destination.Name);

            if (not DirectedChannel) then -- The desired channel for this message does not exist!
                warn("SocialChatClient Channel Manager received a message from the server for a channel that the client has not registed! ( Channel: \""..(Destination.Name).."\" || Message: \""..(Message).."\" )");
                return;
            end

            DirectedChannel:Message(Message, SpeakerData);
        end
    end);

    Network.EventLeaveChannel.OnClientEvent:Connect(function(name : string)
        local RequestedChannel = self:Get(name);
        if (not RequestedChannel) then return; end -- This channel isnt registered on our client!

        RequestedChannel:Destroy();
    end);

    Network.EventJoinChannel.OnClientEvent:Connect(function(Name : string, Members : table, History : table)
        self:Create(Name, Members, History);
    end);

    --// Private Channel cleanup
    --\\ Sometimes SocialChat will make Private channels for players. However, when one private-player leaves, the channel must clean itself

    game.Players.PlayerRemoving:Connect(function(Recipient : Player)
        local PrivateChannel = self:Get(Recipient.Name);
        if (not PrivateChannel) then return; end -- We were not privately dm'ing this user!

        PrivateChannel:Destroy();
    end);

    return self
end

--// Methods

--- Creates a new channel using the provided parameters
function ChannelMaster:Create(Name : string, Members : table?, ChatHistory : table?, IsPrivate : boolean?) : Channel
    local Container = self.Presets.MessageContainer:Clone();
    Container.Name = "CHANNE_"..Name.."_CONTAINER"
    Container.Visible = false

    FunctUI.new("AdjustingCanvas", Container);

    local ThisChannel = setmetatable({

        --// PROPERTIES \\--

        ["Name"] = Name, -- string
        ["History"] = ChatHistory, -- table :: {Instances...}
        ["IsPrivate"] = IsPrivate, -- boolean

        --// PROGRAMMABLE \\--

        ["Container"] = Container, -- Prefabs -> MessageContainer

        ["Members"] = Members, -- table :: {Players...}
        ["__unread"] = 0, -- number? :: Unread messages
        ["_cache"] = {} -- table :: {ChatInstances...}
        
    }, Channel);

    --// System Channel Handling
    if (TotalChannels < 1) then -- This is our FIRST channel! Make sure to focus on it o_O
        self.Main = ThisChannel
        ThisChannel.IsMain = true
        ThisChannel:Focus();
    else -- Our client has multiple channels registered!
        local function CreateChannelButton(ForChannel : Channel)
            local Preset = Presets.ChannelPrefab:Clone();
            local RealSize : Vector2 = SmartText:GetTextSize(
                ForChannel.Name,
                Preset.Channel.TextSize,
                Preset.Channel.Font,
                Vector2.new(999999999, ChannelFrame.AbsoluteSize.Y)
            );

            Preset.Name = ForChannel.Name
            Preset.Channel.Text = ForChannel.Name
            Preset.Size = UDim2.new(0, RealSize.X + 45, 1, 0);

            Preset.Channel.MouseButton1Click:Connect(function()
                if (not ChatUIManager:IsEnabled()) then return; end -- Our ChatUI is not currently enabled! Channel switching is temporarily disabled
                ForChannel:Focus();
            end);

            ForChannel.NavButton = Preset
            Preset.Parent = ChannelFrame
        end

        for _, RegisteredChannel in pairs(Registry) do
            if (ChannelFrame:FindFirstChild(RegisteredChannel.Name)) then continue; end -- Button already exists!
            CreateChannelButton(RegisteredChannel);
        end

        CreateChannelButton(ThisChannel);

        ChannelBar.Visible = (Settings.HideChatFrame ~= true);
        ChannelMaster:GetFocus():Focus(); -- Refocus the currently focused channel in order for us to apply visual changes
    end

    --// Instance registration
    if (ThisChannel.History) then
        for _, Info in ipairs(ThisChannel.History) do
            ThisChannel:Render(Info.Message, ThisChannel.Members[Info.Author].Metadata.Classic);
        end
    end

    Registry[Name] = ThisChannel
    TotalChannels += 1

    print("Registered SocialChat Channel: "..TotalChannels.." :: [ "..(Name).." ]");
    Container.Parent = InputFrame
    return ThisChannel
end

-- Returns the requested channel
function ChannelMaster:Get(Query : string) : Channel?
    Trace:Assert(type(Query) == "string", "The provided query was not of type \"string\"! ( received \""..(type(Query)).."\" instead )");
    return Registry[Query];
end

--- Returns the currently focused channel
function ChannelMaster:GetFocus() : Channel
    return FocusedChannel
end

--- Sends a new message to our currently focused channel OR a receiver (if provided) [DOES NOT REQUIRE CHANNEL INPUT]
function ChannelMaster:SendMessage(Text : string, Receiver : Player?)
    Trace:Assert(type(Text) == "string", "The provided message content was not of type \"string\"! ( received \""..(type(Text)).."\" instead )");
    Trace:Assert(not Receiver or typeof(Receiver) == "Instance", "The requested recipient was not of type \"Instance\". ( received \""..(typeof(Receiver)).."\" instead )");
    Trace:Assert(not Receiver or Receiver:IsA("Player"), "The provided recipient was not of class \"Player\". Only players can recieve private messages!");

    Network.EventSendMessage:FireServer(Text, Receiver or FocusedChannel.Name);
end

--- Creates a message to the currently focused channel OR a specified channel (if provided)
function ChannelMaster:CreateSystemMessage(Message : string, Metadata : table?, Channel : Channel?)
    if (not self.Main) then -- Prevents race issues
        repeat
            task.wait();
        until
        self.Main
    end

    local ToChannel = (Channel or self:GetFocus());
    ToChannel:Message(Message, Metadata);
end

--- Adds a new string replacement to Channel StringObject's
function ChannelMaster:HandleRender(Keyword : string, Handler : Function)
    Trace:Assert(type(Keyword) == "string", "A string type was not passed for the \"Keyword\" parameter. (got "..(type(Keyword))..")");
    Trace:Assert(type(Handler) == "function", "The provided 'Handler' callback was not a function! (got "..(type(Handler))..")");
    Trace:Assert(not RenderHandlers[Keyword], "The provided 'Keyword' parameter \""..(Keyword).."\" is already in use!");

    RenderHandlers[Keyword] = Handler
end

--// Metamethods

--- Sets our client's channel focus on this channel
function Channel:Focus()
    if ((Settings.HideChatFrame) and (not self.IsMain)) then
        warn("Attempt to set Channel Focus to \'"..(self.Name).."\', but API request failed because configuration \"HideChatFrame\" is enabled!");
        return;
    end

    FocusedChannel = self
    self.Container.Visible = true

    if (self.NavButton) then
        self.__unread = 0
        self.NavButton.Notification.Visible = false

        TweenService:Create(self.NavButton, Settings.ChannelFocusTweenInfo, {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.2
        }):Play();

        TweenService:Create(self.NavButton.Channel, Settings.ChannelFocusTweenInfo, {
            TextColor3 = Color3.fromRGB(40, 40, 40)
        }):Play();

        for _, OtherChannel in pairs(Registry) do
            if (OtherChannel.Name == self.Name) then continue; end
            OtherChannel.Container.Visible = false

            if (OtherChannel.__removing) then continue; end

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

--- Renders a message based on the specified parameters
function Channel:Message(Message : string, Metadata : table?, IsPrivateMessage : boolean?) : table
    local MainFrame = Instance.new("Frame");

    MainFrame.BackgroundTransparency = 1
    MainFrame.Name = "MESSAGE_RENDER_FRAME"
    
    local StringRenderer : SmartStringObject = SmartText.new(self.Container, {
        MaxFontSize = Settings.MaxFontSize
    });

    local ContentRenderer : StringObject = RichString.new({
        MarkdownEnabled = (Metadata and Metadata.BypassMarkdownSetting) or Settings.AllowMarkdown
    });

    for Keyword : string, Handler : Function in pairs(RenderHandlers) do
        ContentRenderer:Replace(Keyword, Handler);
    end
    
    local Content = {
        ["SmartStringObject"] = StringRenderer,
        ["Render"] = MainFrame,
        ["Gradients"] = {},
    };

    --// Dynamic Rendering
    local function Generate(TextGroupName : string, Text : string, Properties : table, ButtonCallback : callback?, IsTag : boolean?)
        local Objects : table = ContentRenderer:Generate(Text, Properties.Font, function(Object : TextLabel | ImageButton)
            if (not Object:IsA("TextLabel") and not Object:IsA("TextButton")) then return; end
            if (typeof(Properties.Color) ~= "Color3") then return; end

            Object.TextColor3 = Properties.Color
        end, ButtonCallback ~= nil, (IsTag or Settings.AllowMarkdown));

        local GradientData : table?

        if (type(Properties.Color) == "string") then
            GradientData = {
                ["Style"] = TextStyles[Properties.Color],

                ["LastTick"] = 0,
                ["Index"] = 0,

                ["Objects"] = Objects
            };

            table.insert(GradientLabels, GradientData);
            table.insert(Content.Gradients, GradientData);
        end

        StringRenderer:AddGroup(TextGroupName, Objects, Properties.Font);

        for _, Object : (TextLabel | ImageButton) in pairs(Objects) do
            if (ButtonCallback) then
                Object.MouseButton1Click:Connect(ButtonCallback);
            end

            Object.Parent = MainFrame
        end
    end

    if (IsPrivateMessage) then -- Private Message!
        Generate("FromWho",
            "{"
            ..(((Metadata.UserId and Metadata.UserId == Player.UserId) and "to") or "from").." **"
            ..(Metadata.Username.Name).."**}: ",
            {Color = Color3.fromRGB(255, 255, 255), Font = Settings.MessageFont},
            function()
                if (not Metadata.UserId) then return; end
                if (Metadata.UserId == Player.UserId) then return; end

                local Client = game.Players:GetPlayerByUserId(Metadata.UserId);
                if (not Client) then return; end

                InputBox:Set("/w "..Client.Name.." ", true);
            end, true
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

            if (Metadata.Tag.Name) then
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
                    if (Metadata.UserId == Player.UserId) then return; end -- We cant whisper to ourselves!

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

    if ((FocusedChannel ~= self) and (self.NavButton)) then -- Notification Pinging
        self.NavButton.Notification.Visible = true
        self.__unread += 1

        self.NavButton.Notification.Unread.Text = self.__unread
    end

    MainFrame.Parent = self.Container

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

--- Removes this channel from our client's channel list and prevents our client from receiving further message events for this channel
function Channel:Destroy()
    Trace:Assert(TotalChannels > 1, "You may not destroy this channel as it is the last remaining channel on this client! Please create another channel before deleting this one.");

    for _, Content in pairs(self._cache) do
        for _, GradientArray in pairs(Content.Gradients) do
            table.remove(GradientLabels, table.find(GradientLabels, GradientArray));
        end

        Content.SmartStringObject:Destroy();
        Content.Render:Destroy();
    end

    self.__removing = true
    TotalChannels -= 1

    if (ChannelFrame:FindFirstChild(self.Name)) then
        ChannelFrame[self.Name]:Destroy();
        
        if (TotalChannels <= 1) then
            ChannelBar.Visible = false
        end
    end

    if (FocusedChannel == self) then -- This doesn't need to run if this channel is not currently focused on
        for _, Channel in pairs(Registry) do
            if (Channel.__removing) then continue; end
    
            Channel:Focus(); -- Since channels get registered with "string" keys, this is essentially our only way to ensure focus
            break;
        end
    end

    Registry[self.Name] = nil
    self.Container:Destroy();
    self = nil
end

ChannelMaster.Registry = Registry
ChannelMaster.OnMessaged = OnMessageRendered.Event -- function(Message : string, Metadata : table, Channel : Channel, IsPrivate : boolean)

return ChannelMaster