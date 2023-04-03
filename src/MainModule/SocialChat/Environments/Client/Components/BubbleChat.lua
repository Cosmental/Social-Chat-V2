--[[

    Name: Mari
    Date: 1/15/2023

    Description: This component module handles SocialChat's BubbleChat system!

]]--

--// Module
local BubbleChat = {};
BubbleChat.__index = BubbleChat

local BubbleController = {};
BubbleController.__index = BubbleController

--// Services
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

--// Imports
local TextStyles
local Channels
local Settings

local SmartText
local RichString

--// Constants
local Player = game.Players.LocalPlayer
local SpeakerEvents
local Network

local BubbleChatContainer
local ChatInputBox
local Presets

--// States
local OverheadControllers = {};
local GradientLabels = {};

local IsActivelyTyping : boolean?
local LastInput = os.clock();

--// Initialization
function BubbleChat:Initialize(Info : table) : metatable
    local self = setmetatable(Info, BubbleChat);

    Settings = self.Settings.BubbleChat
    TextStyles = self.Settings.Styles
    Channels = self.Src.Channels

    SpeakerEvents = self.Remotes.Speakers
    Network = self.Remotes.BubbleChat

    RichString = self.Library.RichString
    SmartText = self.Library.SmartText

    ChatInputBox = self.ChatUI.Chat.Input.InteractionBar.InputBox
    Presets = self.Presets.BubbleChat

    --// Setup
    BubbleChatContainer = Instance.new("ScreenGui");
    BubbleChatContainer.Name = "BubbleChat"
    BubbleChatContainer.ResetOnSpawn = false -- This MUST be false, otherwise the controller would break on respawn!
    BubbleChatContainer.Parent = Player.PlayerGui

    --// Client Setup
    local function ManageCharacter(Character : Model, Controller : BubbleController)
        local function UpdateBubbleHeight()
            Controller.Object.StudsOffsetWorldSpace = Vector3.new(0, GetBubbleHeight(Character), 0);
        end

        Controller.Object.Adornee = Character:WaitForChild("Head");
        UpdateBubbleHeight();

        Character.ChildAdded:Connect(function(Child : Instance)
            if (not Child:IsA("Accessory")) then return; end
            UpdateBubbleHeight();
        end);

        Character.ChildRemoved:Connect(function(Child : Instance)
            if (not Child:IsA("Accessory")) then return; end
            UpdateBubbleHeight();
        end);
    end

    local function SetupClient(Player : Player, Metadata : table)
        local Controller = BubbleChat.new(Player, Metadata.Bubble);

        ManageCharacter(Player.Character or Player.CharacterAdded:Wait(), Controller);

        Player.CharacterAdded:Connect(function(Character : Model)
            ManageCharacter(Character, Controller);
        end);
    end

    SpeakerEvents.EventSpeakerAdded.OnClientEvent:Connect(function(Agent : Instance, Metadata : table)
        if ((typeof(Agent) ~= "Instance") or (not Agent:IsA("Player"))) then return; end
        SetupClient(Agent, Metadata);
    end);

    --// Gradient Rendering
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
    Network.UpdateTypingState.OnClientEvent:Connect(function(AffectedPlayer : Player, NewState : boolean?)
        local Character = AffectedPlayer.Character
        if (not Character) then return; end -- Our player either lost their character or doesnt exist anymore!

        local Controller = OverheadControllers[AffectedPlayer];
        if (not Controller) then return; end -- This player isn't registered by our system!

        Controller.Thinking = NewState
    end);

    Network.EventRenderBubble.OnClientEvent:Connect(function(Agent : Player | BasePart | string, Message : string, Metadata : table?)
        local IsInstance = (typeof(Agent) == "Instance");
        if (not IsInstance) then return; end -- Non-Instance Speakers *can* exist, but in such cases they may NOT have BubbleChat access

        local Controller = (OverheadControllers[Agent] or BubbleChat.new(Agent, (Metadata and Metadata.Bubble)));

        if (not Controller) then print("no controller") return; end
        Controller:Chat(Message);
    end);

    --// Typing Checks
    if (Settings.DisplayThinkingBubble) then
        local function UpdateTypingState(IsTyping : boolean?)
            if (IsTyping ~= IsActivelyTyping) then -- Our state has changed! (we should update our server)
                Network.UpdateTypingState:FireServer(IsTyping);

                local Controller = OverheadControllers[Player];
                if (not Controller) then return; end
                
                Controller.Thinking = IsTyping
            end

            IsActivelyTyping = IsTyping
            if (not IsTyping) then return; end

            LastInput = os.clock();
        end
    
        ChatInputBox.Focused:Connect(function()
            if (Channels:GetFocus().IsPrivate) then return; end
            UpdateTypingState(true);
        end);
    
        ChatInputBox.FocusLost:Connect(function()
            UpdateTypingState(false);
        end);
    
        ChatInputBox:GetPropertyChangedSignal("Text"):Connect(function()
            task.defer(function()
                if (ChatInputBox.Text:len() <= 0 or Channels:GetFocus().IsPrivate) then return; end
                UpdateTypingState(true);
            end, RunService.Heartbeat);
        end);

        RunService.Heartbeat:Connect(function()
            if (not IsActivelyTyping) then return; end
            if (not ChatInputBox:IsFocused()) then return; end
            if ((os.clock() - LastInput) <= 10) then return; end

            Network.UpdateTypingState:FireServer(false);
            IsActivelyTyping = false
        end);
    end

    return self
end

--- Returns a list of registered BubbleChat Controller's
function BubbleChat:GetControllers() : table
    return OverheadControllers
end

--// Methods

--- Creates a new BubbleController that can be handled via it's various API methods
function BubbleChat.new(Agent : BasePart | Player, Metadata : table?) : BubbleController
    assert(typeof(Agent) == "Instance", "Expected \"Instance\" as a valid OverheadContainer Agent. (got \""..(typeof(Agent)).."\")");
    assert(Agent:IsA("BasePart") or Agent:IsA("Player"), "The provided Instance was not of class \"BasePart\" or \"Player\"! (got \""..(Agent.ClassName).."\")");
    assert(not Metadata or type(Metadata) == "table", "The provided BubbleChat metadata was not of type \"table\"! (got \""..(type(Metadata)).."\")");

    local OverheadUI = Presets.BubbleChatContainer:Clone();

    OverheadUI.Name = "OverheadBubbleChat_"..((Agent:IsA("Player") and Player.UserId) or Agent.Name);
    OverheadUI.Parent = BubbleChatContainer

    local Color = ((Metadata and Metadata.BubbleColor) or Settings.Default.BubbleColor);
    local Transparency = ((Metadata and  Metadata.BubbleTransparency) or Settings.Default.BubbleTransparency);

    OverheadUI.Main.ThinkBubble.Background.BackgroundColor3 = Color
    OverheadUI.Main.Carrot.ImageColor3 = Color

    OverheadUI.Main.ThinkBubble.Background.BackgroundTransparency = Transparency
    OverheadUI.Main.Carrot.ImageTransparency = Transparency

    --// Metadata Handling \\--
    local Controller
    Controller = setmetatable({

        --// PROPERTIES \\--

        ["Object"] = OverheadUI, -- The Controller's User Interface Instance.
        ["Agent"] = Agent, -- The Controller's current owner. This is not often subject to change, but it should still be supported

        ["Metadata"] = Metadata, -- The Controller's applied Metadata!
        
        --// PROGRAMMABLE \\--

        ["RenderedBubbles"] = {}, -- A table containing data based on our currently rendered chat bubbles (if any) [CAN BE EMPTY]
        ["__states"] = {
            -- ["Thinking"] = nil, -- Determines if the controller is currently thinking or not.
            -- ["Enabled"] = nil -- Tells us when our BubbleController is active or not. This helps control our carrot's visibility
        },

    }, {
        __newindex = function(_, Index : string, Value : any?)
            if (Controller[Index]) then
                rawset(Controller, Index, Value);
            elseif (Index == "Thinking") then
                assert(type(Value) == "boolean" or Value == nil, "BubbleChat Error: Attempt to set thinking state to a non-boolean value! (got "..(type(Value))..")");
                Controller:__setThinking(Value);
            elseif (Index == "Enabled") then
                assert(type(Value) == "boolean" or Value == nil, "BubbleChat Error: Attempt to set enabled state to a non-boolean value! (got "..(type(Value))..")");
                Controller:__setActive(Value);
            end
        end,

        __index = BubbleController
    });

    OverheadControllers[Agent] = Controller

    if (not Agent:IsA("Player")) then
        OverheadUI.Adornee = Agent
    end

    --// Thinking Animation \\--

    if (Settings.DisplayThinkingBubble) then
        local Background = OverheadUI.Main.ThinkBubble.Background
        local Circles = {};

        for _, Circle in pairs(Background:GetChildren()) do
            if (not Circle:IsA("Frame")) then continue; end
            table.insert(Circles, Circle);
        end

        local function LoopAnimation()
            for _, Circle in pairs(Circles) do
                if (not Circle:IsA("Frame")) then continue; end
    
                local CircleTween = TweenService:Create(Circle, TweenInfo.new(Settings.ThinkingSpeed / #Circles), {
                    BackgroundColor3 = Color3.fromRGB(130, 130, 130)
                });
    
                CircleTween:Play();
                CircleTween.Completed:Wait();
    
                TweenService:Create(Circle, TweenInfo.new(Settings.ThinkingSpeed / #Circles), {
                    BackgroundColor3 = Color3.fromRGB(170, 170, 170)
                }):Play();
            end

            if (not OverheadUI:IsDescendantOf(BubbleChatContainer)) then return; end
            LoopAnimation();
        end

        coroutine.wrap(LoopAnimation)();
    end

    task.wait(.1); -- Give roblox some rendering time
    return Controller
end

--- Adjusts major configurable settings (not intended for API usage) [SCOPE-BYPASSER]
function BubbleChat:Configure(Configuration : string, Value : any?)
    assert(type(Configuration) == "string", "Attempt to query replacement value with internal BubbleChat settings with a non-string type. (received "..(type(Configuration))..")");
    assert(Settings[Configuration], "Requested BubbleChat configurable adjustment \""..(Configuration).."\" does not exist!");
    
    Settings[Configuration] = Value
end

--// Metamethods

--- Renders a new chat bubble for the provided content
function BubbleController:Chat(Message : string) : table
    local Bubble = Presets.BubbleChatMessage:Clone();
    local Metadata = (self.Metadata);

    local BubbleColor = ((Metadata and Metadata.BubbleColor) or Settings.Default.BubbleColor); -- Why did we repeat variables? Because if we set this to the default preset, then ALL client's will have the same BubbleColor which is NOT what we want!

    Bubble.BackgroundBubble.BackgroundColor3 = BubbleColor
    Bubble.Name = ("BUBBLE_MESSAGE_"..(self.Agent.Name));
    Bubble.BackgroundBubble.BackgroundTransparency = 1

    Bubble.Visible = Settings.IsBubbleChatEnabled
    Bubble.Parent = self.Object.Main.Bubbles -- We need to parent this early because our responsive text relies on our Chat-Bubble's parental status

    local TextColor = ((Metadata and Metadata.TextColor) or Settings.Default.TextColor);
    local TextFont = ((Metadata and Metadata.Font) or Settings.Default.Font);

    local FontSize = SmartText:GetBestFontSize(self.Object.AbsoluteSize, TextFont, 0, Settings.Default.TextSize);
    local TextRenderer = RichString.new({
        MarkdownEnabled = Settings.IsMarkdownEnabled
    });

    local Content = {
        ["Render"] = Bubble,
        ["Gradients"] = {}
    };

    --// Dynamic Rendering
    local Bounds = self.Object.AbsoluteSize
    local MovementX, MovementY = 0, 0
    local TextLines = {};

    local function RenderLine() : Frame
        local NewLine = Presets.BubbleMessageLine:Clone();

        NewLine.Size = UDim2.new(1, 0, 0, FontSize);
        NewLine.Parent = Bubble.BackgroundBubble

        table.insert(TextLines, NewLine);
        return NewLine
    end

    local CurrentLine = RenderLine();

    local TextObjects : table = TextRenderer:Generate(
        Message, TextFont,
        function(TextObject)
            TextObject.Parent = CurrentLine -- We need to parent our UI element before-hand in order for calculations to work!

            local TextBounds, MultiLine = SmartText:GetTextSize(
                TextObject.Text:gsub("<.->", ""),
                FontSize,
                TextFont,
                self.Object.AbsoluteSize
            );

            TextObject.Size = UDim2.fromOffset(TextBounds.X, TextBounds.Y);

            if ((TextBounds.X + MovementX > (Bounds.X - Settings.BubblePadding.X)) or (MultiLine)) then
                CurrentLine.Size = UDim2.new(1, 0, 0, TextBounds.Y);
                CurrentLine = RenderLine();

                MovementY += TextBounds.Y
                MovementX = 0
            end
            
            TextObject.Position = UDim2.fromOffset(MovementX, 0);
            TextObject.TextSize = FontSize

            TextObject.TextStrokeTransparency = 1
            TextObject.TextTransparency = 1

            TweenService:Create(TextObject, Settings.VisibilityTweenInfo, {
                TextStrokeTransparency = 0.8,
                TextTransparency = 0
            }):Play();

            MovementX += TextBounds.X

            if (typeof(TextColor) ~= "Color3") then return; end
            TextObject.TextColor3 = TextColor
        end,
        false, Settings.IsMarkdownEnabled
    );

    local GradientData : table?

    if (type(TextColor) == "string") then
        GradientData = {
            ["Style"] = TextStyles[TextColor],

            ["LastTick"] = 0,
            ["Index"] = 0,

            ["Objects"] = TextObjects
        };

        table.insert(GradientLabels, GradientData);
        table.insert(Content.Gradients, GradientData);
    end

    --// Handling
    local BubbleSizeX = (
        if (MovementY > 0) then Bounds.X - Settings.BubblePadding.X -- Bubble is clearly multi-lined. Thus, we can maximize the X-axis
        elseif (MovementX + Settings.BubblePadding.X >= Bounds.X) then MovementX -- Bubble is one line AND fits the container (no changes)
        else MovementX + Settings.BubblePadding.X -- Bubble is small, hence requiring some extra padding (eg: "Hi!");
    );

    Bubble.BackgroundBubble.Size = UDim2.fromOffset(
        BubbleSizeX + Settings.BubblePadding.X,
        MovementY + Settings.BubblePadding.Y
    );

    Bubble.Size = UDim2.new(1, 0, 0, Bubble.BackgroundBubble.Size.Y.Offset);

    --// Trash Collection & Finalization
    local function DestroyBubble(Index : number)
        local MessageBubble = self.RenderedBubbles[Index];
        if (not MessageBubble) then return; end -- Bubble was either already destroyed or index is invalid

        local Fade = TweenService:Create(MessageBubble.Render, Settings.VisibilityTweenInfo, {
            Size = UDim2.fromOffset(0, 0)
        });

        for _, Line in pairs(MessageBubble.Render.BackgroundBubble:GetChildren()) do
            if (not Line:IsA("Frame")) then continue; end

            for _, Object in pairs(Line:GetChildren()) do
                if (not Object:IsA("TextLabel") and not Object:IsA("ImageLabel") and not Object:IsA("ImageButton")) then continue; end
            
                if (Object:IsA("TextLabel")) then
                    TweenService:Create(Object, Settings.VisibilityTweenInfo, {
                        TextTransparency = 1,
                        TextStrokeTransparency = 1
                    }):Play();
                else
                    TweenService:Create(Object, Settings.VisibilityTweenInfo, {
                        ImageTransparency = 1
                    }):Play();
                end
            end
        end

        TweenService:Create(MessageBubble.Render.BackgroundBubble, Settings.VisibilityTweenInfo, {
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(0, 0)
        }):Play();

        Fade.Completed:Connect(function(PlaybackState)
            if (PlaybackState ~= Enum.PlaybackState.Completed) then return; end
            MessageBubble.Render:Destroy();

            for _, GradientArray in pairs(MessageBubble.Gradients) do
                table.remove(GradientLabels, table.find(GradientLabels, GradientArray));
            end
        end);

        Fade:Play();
        table.remove(self.RenderedBubbles, Index);
            
        if (#self.RenderedBubbles <= 0 and not self.Thinking) then
            self.Enabled = false
        end
    end

    if (#self.RenderedBubbles >= Settings.MaxDisplayableBubbles) then
        DestroyBubble(1); -- Our oldest rendered content will always be our 1st index! (thus being why we can just remove index #1)
    end

    TweenService:Create(Bubble.BackgroundBubble, Settings.VisibilityTweenInfo, {
        BackgroundTransparency = ((Metadata and Metadata.BubbleTransparency) or (Settings.Default.BubbleTransparency))
    }):Play();

    table.insert(self.RenderedBubbles, Content);
    self.Enabled = true

    task.delay(Settings.ChatBubbleLifespan, function()
        DestroyBubble(table.find(self.RenderedBubbles, Content));
    end);

    return Content
end

--- Destroys the current BubbleController
function BubbleController:Destroy()
    for _, MessageBubble in pairs(self.RenderedBubbles) do
        MessageBubble.Render:Destroy();
        
        for _, Gradient in pairs(MessageBubble.Gradients) do
            table.remove(GradientLabels, table.find(GradientLabels, Gradient));
        end
    end

    self.Object:Destroy();
    self = nil
end

--// Sub-metamethods
--\\ These methods are only designed for __index calls

--- Sets the controller's current thinking state to the provided boolean value
function BubbleController:__setThinking(State: boolean?)
    if (self.Thinking == State) then return; end -- The API requested a repeat state! End the thread here.
    if (not Settings.DisplayThinkingBubble) then return; end -- This API function is currently denied by a configuration in our system!

    rawset(self.__states, "Thinking", State);

    --// State Handling
    --\\ We need to handle our states here for special conditions such as no chat messages being rendered, etc.

    if (not self.__states.Enabled and State) then
        self.Enabled = true
    elseif (not State and not next(self.RenderedBubbles)) then
        self.Enabled = false
    end

    --// Visibility Tweening
    --\\ After handling out Controller state, we can tween our visibile state for our Thinking bubble!

    State = (State and Settings.IsBubbleChatEnabled); -- Only allows for hiding based on settings!

    local MainFrame = self.Object.Main
    local ThinkingFrame = MainFrame.ThinkBubble
    local Background = ThinkingFrame.Background

    local Transparency = ((self.Metadata and  self.Metadata.BubbleTransparency) or Settings.Default.BubbleTransparency);
    local TransGoal = ((State and Transparency) or 1); -- Silly little variable name :3
    ThinkingFrame.Visible = true

    local BackgroundTween = TweenService:Create(Background, Settings.VisibilityTweenInfo, {
        BackgroundTransparency = TransGoal
    });

    TweenService:Create(MainFrame.Bubbles, Settings.VisibilityTweenInfo, {
        Position = UDim2.fromScale(0.5, (State and 0.83) or .96)
    }):Play();

    for _, Circle in pairs(Background:GetChildren()) do
        if (not Circle:IsA("Frame")) then continue; end
        
        TweenService:Create(Circle, Settings.VisibilityTweenInfo, {
            BackgroundTransparency = ((TransGoal ~= 1 and 0) or 1)
        }):Play();
    end

    BackgroundTween.Completed:Connect(function(PlaybackState)
        if (PlaybackState ~= Enum.PlaybackState.Completed) then return; end
        if (State) then return; end

        ThinkingFrame.Visible = false
    end);

    BackgroundTween:Play();
end

--- Sets the controller's current state of activity to the provided boolean value
function BubbleController:__setActive(State : boolean?)
    rawset(self.__states, "Enabled", State);

    local MainFrame = self.Object.Main
    State = (State and Settings.IsBubbleChatEnabled);

    if (State) then
        MainFrame.Carrot.Visible = true
    end

    TweenService:Create(MainFrame.ThinkBubble.Background, Settings.VisibilityTweenInfo, {
        Size = ((State and UDim2.fromScale(.25, 1)) or (UDim2.fromScale(0, 0)))
    }):Play();

    TweenService:Create(MainFrame.Bubbles, Settings.VisibilityTweenInfo, {
        Size = ((State and UDim2.new(1, 0, 0.97, 0)) or (UDim2.new(0, 0, 0, 0)))
    }):Play();

    local CarrotTween = TweenService:Create(MainFrame.Carrot, Settings.VisibilityTweenInfo, {
        Size = ((State and UDim2.fromOffset(20, 9)) or (UDim2.fromOffset(0, 0)))
    });
    
    CarrotTween.Completed:Connect(function(PlaybackState)
        if (PlaybackState ~= Enum.PlaybackState.Completed or State) then return; end
        MainFrame.Carrot.Visible = false
    end);

    CarrotTween:Play();
end

--// Functions

--- Returns a usable Chat Bubble height for the provided character
function GetBubbleHeight(Character : Model) : number
    if ((not Character) or (not Character:FindFirstChild("Head"))) then return 0; end

    local BestHeight = 0
    
    for _, Child in pairs(Character:GetChildren()) do
        if (not Child:IsA("Accessory")) then continue; end -- Accessories are the only thing we really care about...
        if (not Child:WaitForChild("Handle"):FindFirstChild("HatAttachment")) then continue; end -- We ONLY want to account for hat accessories!
        
        local HeadOffset = (math.abs(((Child.Handle.Position - Child.Parent.Head.Position).Y * 1000)) / 1000); -- We round our value to the 1000'th
        
        if (HeadOffset > BestHeight) then -- We ONLY want the offset of our biggest height!
            BestHeight = HeadOffset
        end
    end
    
    return (1 + BestHeight);
end

return BubbleChat