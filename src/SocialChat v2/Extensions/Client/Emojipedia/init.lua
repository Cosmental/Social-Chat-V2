--[[

    Name: Mari
    Date: 4/6/2023

    Description: Emojipedia is a standalone extension that provides Twemoji support into SocialChat for all devices! This should simulate
                 Discord emoji behavior, and present emojis evenly within your chat system.

]]--

--// Module
local Emojipedia = {};

Emojipedia.__index = Emojipedia
Emojipedia.__meta = {
    Name = "Emojipedia", -- Extesion Name
    CreatorId = 876817222, -- Creator's UserId
    Description = "Welcome to emojipedia! This extension provides additional support for emojis through SocialChat.\n\nPreset Emojis drawn by <font color=\"rgb(0, 85, 255)\"><b>@Keeratisatian</b></font>", -- Extension Description
    IconId = "http://www.roblox.com/asset/?id=13828033478", -- Extension IconId (must be a decal Id such as "rbxassetid://ID-HERE")
    Version = "1.1" -- Extension version (will be displayed)
};

local ConfigurationMeta : table = { -- Visual Metadata for our configurations menu
    Button = {
        ["Active"] = {
            StrokeColor = Color3.fromRGB(255, 255, 255),
            ButtonColor = Color3.fromRGB(255, 245, 120),
            
            StrokeTransparency = 0,
            ButtonTransparency = 0
        };

        ["Inactive"] = {
            StrokeColor = Color3.fromRGB(255, 255, 255),
            ButtonColor = Color3.fromRGB(255, 245, 120),
            
            StrokeTransparency = 0.5,
            ButtonTransparency = 0.5
        };

        ["Tween"] = {
            Speed = 0.5,
            EasingStyle = Enum.EasingStyle.Exponential
        }
    };

    ["Slider"] = {
        SocketColor = Color3.fromRGB(255, 255, 255),
        SliderColor = Color3.fromRGB(210, 210, 210),
    };
};

--// Services
local MarketplaceService = game:GetService("MarketplaceService");
local UserInputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");
local TextService = game:GetService("TextService");
local RunService = game:GetService("RunService");

--// Imports
local Channels : table < ChannelsAPI >
local BubbleChat : table < BubbleChatAPI >
local ControlPanel : table < ControlPanelAPI >

local FunctUI : table < FunctUI >
local SpriteClip : table < SpriteClip >
local Emojis : table < table < Emoji > > = {};

local Trace : table < TraceAPI >

--// Constants
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse();

local Categories : Folder
local Presets : Folder

local ChatUI : ScreenGui
local InputFrame : Frame
local InputBar : Frame
local InputBox : TextBox

local EmotePanel : Frame
local SidePanel : Frame
local EmoteBtn : ImageButton
local EmojiMatch : Frame

local EmojiBubbleCache : ScreenGui?
local ButtonStates : table <string> = {
    Active = {
        "rbxassetid://11534391613", -- Star Struck Eyes
        "rbxassetid://11534390823", -- Shocked
        "rbxassetid://11534390228", -- Innocent
        "rbxassetid://11534389488", -- Heart Eyes
        "rbxassetid://11534388589", -- Blehhh
        "rbxassetid://11534387838" -- Awkward
    };
    
    Inactive = {
        "rbxassetid://11534396890", -- Star Struck Eyes (BW)
        "rbxassetid://11534396199", -- Shocked (BW)
        "rbxassetid://11534395690", -- Innocent (BW)
        "rbxassetid://11534394880", -- Heart Eyes (BW)
        "rbxassetid://11534394020", -- Blehhh (BW)
        "rbxassetid://11534393341" -- Awkward (BW)
    };
};

local EventDataEntry : RemoteEvent
local ExtensionData : table
local Settings : table

--// States
local CurrentSuggestion : table < Emoji >?
local Recent : table < Emojis >

--// Main

--- The initialization method for our Extension. This will setup and initialize this extension indefinitely
function Emojipedia:Deploy(SocialChat : metatable)
    local self = setmetatable(SocialChat, Emojipedia);

    Channels = self.Components.Channels
    BubbleChat = self.Components.BubbleChat
    ControlPanel = self.Components.ControlPanel

    SpriteClip = self.Library.SpriteClip
    FunctUI = self.Library.FunctUI
    Trace = self.Trace

    Categories = script.Categories
    Presets = script.Presets

    ChatUI = self.ChatUI
    InputFrame = ChatUI.Chat.Input
    InputBar = InputFrame.InteractionBar
    InputBox = InputBar.InputBox

    EmotePanel = script.Content.EmojiSearch
    EmojiMatch = script.Content.EmojiMatch
    SidePanel = EmotePanel.Panel.Shortcuts
    EmoteBtn = script.Content.Emote

    EmojiBubbleCache = Instance.new("ScreenGui");
    EmojiBubbleCache.DisplayOrder = 1
    EmojiBubbleCache.Name = "EmojiBubbleCache"
    EmojiBubbleCache.ResetOnSpawn = false
    EmojiBubbleCache.IgnoreGuiInset = true
    EmojiBubbleCache.Parent = Player.PlayerGui

    ExtensionData = (self.Data.Extensions.Emojipedia or require(script.__data));
    EventDataEntry = self.Remotes.DataService.EventDataEntry
    self.LayoutOrder = 0 -- State value that determines the order in which our buttons will move towards

    Settings = (ExtensionData.Settings.Value or ExtensionData.Settings.Default);

    --// UI Setup
    if (not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled) then -- PC Adjustments
        InputBox.Size = UDim2.fromScale(0.78, 0.85);
        InputBox.Position = UDim2.fromScale(0.8, 0.5);

        EmoteBtn.Size = UDim2.fromScale(.11, .545);
        EmoteBtn.Position = UDim2.fromScale(.89, .5);
    else -- Mobile Adjustments
        InputBox.Size = UDim2.fromScale(0.704, 0.85);
        InputBox.Position = UDim2.fromScale(0.724, 0.5);
    end

    EmojiMatch.Parent = InputFrame
    EmotePanel.Parent = InputFrame
    EmoteBtn.Parent = InputBar

    FunctUI.new('AdjustingCanvas', EmotePanel.Search);
    FunctUI.new('AdjustingCanvas', EmotePanel.Categories);
    FunctUI.new('AdjustingCanvas', SidePanel, nil, nil, Vector2.new(1, .2));

    --// Emoji States
    local CurrentState : number = 1 -- NOTE: For every COLORED Active state, there must be a B&W counterpart in the SAME table position!

    EmoteBtn.MouseEnter:Connect(function()
        EmoteBtn.Image = ButtonStates.Active[CurrentState];
        EmoteBtn.ImageColor3 = Color3.fromRGB(255, 255, 255);
    end);

    EmoteBtn.MouseLeave:Connect(function()
        CurrentState = math.random(#ButtonStates.Active);
        EmoteBtn.Image = ButtonStates.Inactive[CurrentState];
        EmoteBtn.ImageColor3 = Color3.fromRGB(182, 182, 182);
    end);

    EmoteBtn.Image = ButtonStates.Inactive[CurrentState];

    --// Panel Visibility
    EmoteBtn.MouseButton1Click:Connect(function()
        EmotePanel.Visible = (Settings.DisableEmojiPanel.Value or (not EmotePanel.Visible));
    end);

    Mouse.Button1Down:Connect(function()
        task.defer(function()
            EmotePanel.Visible = false
        end, RunService.RenderStepped);
    end);

    --// Recent Setup
    local RecentData : table = (ExtensionData.Recent.Value or ExtensionData.Recent.Default);
    local RecentSection : Frame, RecentButton : ImageButton = self:CreateSection({
        Name = "Recent",
        ImageId = "rbxassetid://3926307971",
        ImageRectSize = Vector2.new(36, 36),
        ImageRectOffset = Vector2.new(604, 404)
    }, {});

    Recent = setmetatable({__data = RecentData}, {
        __newindex = function(_, Index : string, Value : any?)
            if (Value == nil) then
                local Item = RecentSection.Emojis:FindFirstChild(Index);

                if (Item) then
                    Item:Destroy();
                end

                rawset(Recent.__data, Index, nil);
            end

            rawset(Recent.__data, Index, Value);

            RecentButton.Visible = false
            RecentSection.Visible = false

            local TotalItems : number = 0

            for _, _ in pairs(Recent.__data) do
                RecentSection.Visible = true
                RecentButton.Visible = true
                TotalItems += 1
                
                if (TotalItems > 20) then
                    local OldestTime : number = math.huge
                    local OldestItem : string?

                    for Name : string, Data : table in pairs(Recent.__data) do
                        if (OldestTime < Data.LastUsed) then continue; end
                        
                        OldestTime = Data.LastUsed
                        OldestItem = Name
                    end

                    Recent[OldestItem] = nil
                    break;
                end
            end

            if (type(Value) ~= "table") then return; end
            if (RecentSection.Emojis:FindFirstChild(Value.Meta.Aliases[1])) then return; end

            local Item : ImageButton | TextButton = RenderEmoji(Value.Meta);

            Item.MouseButton1Click:Connect(function()
                if (not InputBox:IsFocused()) then
                    InputBox:CaptureFocus();
                end

                InputQuery(Value.Meta);
                InputBox.CursorPosition = #InputBox.Text + 1
            end);

            Item.Parent = RecentSection.Emojis
            EventDataEntry:FireServer("Extensions/Emojipedia/Recent", Recent.__data);
        end
    });

    RecentSection.Visible = false
    RecentButton.Visible = false

    for Index : string, Value : table in pairs(RecentData) do
        Recent[Index] = Value
    end

    --// Category Setup
    for _, Category in pairs(Categories:GetDescendants()) do
        if (not Category:IsA("Folder") or not Category:FindFirstChildOfClass("ModuleScript")) then continue; end
        if (not Category:FindFirstChild("Meta") or not Category:FindFirstChild("Emojis")) then
            Trace:Error(Category.Name.." is missing data! Each category must contain a 'Meta' ModuleScript and a 'Emojis' ModuleScript.");
            continue;
        end

        local Meta = require(Category.Meta);
        local Emotes = require(Category.Emojis);

        Emojis[Category.Name] = {
            ["Icon"] = Meta.Icon,
            ["Whitelist"] = Meta.Requirements,

            ["Meta"] = Emotes
        };

        self:CreateSection(Meta.Icon, Emotes, Meta.Requirements);
    end

    self.Components.InputBox.Highlighter:SetHandler(function(Phrase : string)
        for _, Category : table in pairs(Emojis) do
            for _, Emoji : table in pairs(Category.Meta) do
                for _, Alias : string in pairs(Emoji.Aliases) do
                    if ((":"..(Alias)..":") ~= Phrase) then continue; end
                    return true, Color3.fromRGB(235, 255, 55); -- VERY NESTED YUCKY !! (but alas... simplest solution...)
                end
            end
        end
    end);

    --// Query Searching
    local function SetClearState(State : boolean)
        if (State) then
            EmotePanel.Input.Search.ImageColor3 = Color3.fromRGB(255, 255, 255);
            EmotePanel.Input.Search.ImageRectOffset = Vector2.new(924, 724); -- Clear Image
        else
            EmotePanel.Input.Search.ImageColor3 = Color3.fromRGB(150, 150, 150);
            EmotePanel.Input.Search.ImageRectOffset = Vector2.new(964, 324); -- Search Image
        end
    end

    local HackyInput : table < Emoji >? -- Sadly had to resort to this hacky implementation that would beat any race-conditions when dealing with RunService. Have a better solution? Dm me!

    EmotePanel.Input.Search.MouseButton1Click:Connect(function()
        EmotePanel.Input.InputBox.Text = "" -- Clear Text
        EmotePanel.Input.InputBox:CaptureFocus();
    end);

    EmotePanel.Input.InputBox.FocusLost:Connect(function()
        EmotePanel.Input.InputBox.Text = ""

        if (HackyInput) then
            InputQuery(HackyInput);
            HackyInput = nil
        end
    end);

    EmotePanel.Input.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
        local Query : string = EmotePanel.Input.InputBox.Text

        for _, Child in pairs(EmotePanel.Search:GetChildren()) do
            if (Child:IsA("GuiObject")) then
                local Bubble = EmojiBubbleCache:FindFirstChild("__SEARCH:"..Child.Name);

                if (Bubble) then
                    Bubble:Destroy();
                end

                Child:Destroy();
            end
        end

        if (Query:len() < 1) then
            SetClearState(false);
            
            EmotePanel.Search.Visible = false
            EmotePanel.Categories.Visible = true

            return;
        end

        SetClearState(true);
        EmotePanel.Search.Visible = true
        EmotePanel.Categories.Visible = false

        --// Query Searching
        local Matches : table = self:Match(Query);

        for _, Match in ipairs(Matches) do
            local Item, Bubble = RenderEmoji(Match.Meta);
            if (not Item) then continue; end

            Item.MouseEnter:Connect(function()
                HackyInput = Match.Meta
            end);

            Item.MouseLeave:Connect(function()
                HackyInput = nil
            end);
            
            Bubble.Name = ("__SEARCH:"..Item.Name);
            Item.Parent = EmotePanel.Search
        end

        EmotePanel.Search.CanvasPosition = Vector2.new(0, 0); -- Stay at top
    end);

    --// InputBox Query Suggestions
    local SuggestCap : number = ( -- The number of suggested emojis that we can fit in our UI widget. This will dynamically scale based on platforms
        (Camera.ViewportSize.Y <= 400 and 3)
        or 5
    );

    local function ClearSuggestions()
        for _, Child in pairs(EmojiMatch.Suggestions:GetChildren()) do
            if (not Child:IsA("GuiObject")) then continue; end
            Child:Destroy();
        end

        CurrentSuggestion = nil
        EmojiMatch.Visible = false
    end

    local function Suggest()
        local Query = InputBox.Text:gsub("	", ""); -- Remove tabulation utf-8 [9] keys.
        ClearSuggestions();
        
        local Input = Query:split(" ")[#Query:split(" ")];
        if (Input:len() < 3) then return; end -- Not big enough for a suggestion
        if (Input:sub(1, 1) ~= ":") then return; end -- Not an emoji! [END]

        local Matches : table = self:Match(Input:sub(2), SuggestCap);
        if (not next(Matches)) then return; end

        for _, Match in ipairs(Matches) do
            local Emoji = RenderEmoji(Match.Meta, true);
            if (not Emoji) then continue; end -- No Emoji? [Silent-Error]
            
            local Item = Presets.EmojiMatchItem:Clone();
            Emoji.AnchorPoint = Vector2.new(0, 0.5);
            Emoji.Size = UDim2.fromScale(0.05, 0.75);
            Emoji.Position = UDim2.fromScale(0.015, 0.5);
            Emoji.ZIndex = 20
            Emoji.Parent = Item

            Item.InputBegan:Connect(function(Input : InputObject)
                if (Input.UserInputType ~= Enum.UserInputType.MouseButton1) then return; end
                InputQuery(Match);
            end);

            Item.InputBegan:Connect(function(Input : InputObject)
                if (Input.UserInputType ~= Enum.UserInputType.MouseMovement) then return; end

                TweenService:Create(Item, TweenInfo.new(.4), {BackgroundTransparency = 0}):Play();
                CurrentSuggestion = Match
            end);

            Item.InputEnded:Connect(function(Input : InputObject)
                if (Input.UserInputType ~= Enum.UserInputType.MouseMovement) then return; end

                TweenService:Create(Item, TweenInfo.new(.2), {BackgroundTransparency = .5}):Play();
                CurrentSuggestion = nil
            end);

            Item.Content.Text = Match.Meta.Aliases[1];
            Item.Parent = EmojiMatch.Suggestions
        end

        CurrentSuggestion = Matches[1];
        EmojiMatch.Search.Text = Input
        EmojiMatch.Visible = (Settings.DisableSuggestions.Value ~= true and true);
    end

    InputBox:GetPropertyChangedSignal("Text"):Connect(Suggest);
    InputBox.Focused:Connect(Suggest);
    InputBox.FocusLost:Connect(function()
        task.defer(ClearSuggestions, game:GetService("RunService").RenderStepped); -- Function must run on the next-frame operation due to Roblox EventHandler race-conditions with the emoji suggestion elements
    end);

    UserInputService.InputBegan:Connect(function(Input : Enum.KeyCode)
        if (Input.KeyCode ~= Enum.KeyCode.Tab) then return; end
        if (not CurrentSuggestion) then return; end

        InputQuery(CurrentSuggestion.Meta);
    end);

    --// Reactive Emoji-Match UI
    local Canvas = FunctUI.new('AdjustingCanvas', EmojiMatch.Suggestions);
    
    Canvas.OnUpdated:Connect(function(Size : Vector2)
        local AnchorY : number = EmojiMatch.Search.AbsoluteSize.Y

        TweenService:Create(EmojiMatch, TweenInfo.new(.5, Enum.EasingStyle.Exponential), {
            Size = UDim2.new(.98, 0, 0, Size.Y + AnchorY + 15);
        }):Play();

        EmojiMatch.Suggestions.Position = UDim2.new(0.5, 0, 0, AnchorY + 5);
    end);

    Canvas:Update();

    --// Control Panel
    if (self.Settings.Channels.ControlPanelEnabled) then
        local PanelSettings : table < ControlPanelSettings > = (ControlPanel:GetPages().Settings);
        local Category : table < CategoryAPI > = PanelSettings.CategoryAPI

        local ConfigurationData : table = (ExtensionData.Settings.Value or ExtensionData.Settings.Default);
        local ExtensionSettings : table < CategoryPanel > = Category.new(Emojipedia.__meta.Name, {
            ImageId = Emojipedia.__meta.IconId
        });

        for Configuration : string, Data : table in pairs(ConfigurationData) do
            Data.Metadata = ConfigurationMeta[Data.Type];

            local Interactable : GuiObject, API : table < CategoryAPI > = ExtensionSettings:Create(Data);
            local InitVal : any? = (if (Data.Value ~= nil) then Data.Value else Data.Default);
            
            FunctUI.new("Note", Interactable.Configuration, Data.Info);
            Data.Metadata = nil -- Prevent DataStores from saving Metadata [Due to not being UTF-8]

            API.Value = (InitVal);
            API:SetEnabled(Data.Locked);

            API.ValueChanged:Connect(function(Value : any?)
                self:__handleChange(Configuration, Value);
                ConfigurationData[Configuration].Value = Value
                EventDataEntry:FireServer("Extensions/Emojipedia/Settings", ConfigurationData);
            end);

            self:__handleChange(Configuration, InitVal);
        end
    end
    
    return self
end

--// Methods

--- Creates a new Emojipedia section that can hold emojis
function Emojipedia:CreateSection(IconData : table, Emotes : table, WhitelistData : table?) : (Frame & ImageButton)?
    Trace:Assert(type(IconData) == "table", "Parameter type mismatch. Expected 'IconData' to be of type 'table'. (got "..(type(IconData))..")");
    Trace:Assert(type(Emotes) == "table", "Parameter type mismatch. Expected 'Emotes' to be of type 'table'. (got "..(type(IconData))..")");
    Trace:Assert(IconData.Name, "The provided 'IconData' does not supply a 'Name'!");
    Trace:Assert(IconData.ImageId, "The provided 'IconData' does not supply an 'ImageId'!");

    --// Section Setup
    local Section = Presets.Section:Clone();

    Section.Icon.ImageRectOffset = (IconData.ImageRectOffset or Vector2.new(0, 0));
    Section.Icon.ImageRectSize = (IconData.ImageRectSize or Vector2.new(0, 0));
    Section.Icon.Image = IconData.ImageId

    Section.Name = IconData.Name.."_Section"
    Section.Category.Text = IconData.Name

    --// Whitelisting
    local UserHasAccess : boolean = true

    if (WhitelistData and WhitelistData.RequiresWhitelist) then -- Whitelist enabled
        UserHasAccess = HasAccessToEmoji(Player.UserId, WhitelistData);
        
        if (not UserHasAccess) then
            if (WhitelistData.GamepassId > 0) then
                Section.Locked.MouseButton1Click:Connect(function()
                    MarketplaceService:PromptGamePassPurchase(Player, WhitelistData.GamepassId);
                end);

                MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(Client : Player, PassId : number, WasPurchased : boolean?)
                    if (not WasPurchased) then return; end
                    if (not Client == Player) then return; end
                    if (not PassId == WhitelistData.GamepassId) then return; end

                    -- Thank you for your purchase client message?
                    Section.Locked.Visible = false
                    UserHasAccess = true
                end);
            elseif (WhitelistData.GamepassId <= 0 and WhitelistData.GroupId <= 0) then -- Locked, but only accessible to whitelisted users
                Section:Destroy();
                return;
            end

            --// Text Updates
            if (WhitelistData.GroupId > 0 and WhitelistData.RankRequirement > 0) then
                Section.Locked.Paywall.Info.Text = "Join Group"
            end

            if (WhitelistData.GamepassId > 0) then
                Section.Locked.Paywall.Info.Text = "Unlock Now"
            end
        end
    end

    Section.Locked.Visible = (not UserHasAccess);

    --// Emoji Setup
    for _, Emoji in pairs(Emotes) do
        local Item : ImageButton | TextButton = RenderEmoji(Emoji);
        local Emote : string = Emoji.Aliases[1]; -- Each emoji should have at least ONE alias

        if (not Item) then
            warn("Failed to load emoji: "..(Emote)..". (missing visual data [ types: '.Image' <ImageId : string>, '.Character' <UTF8 : string> ])");
            continue;
        end

        Item.MouseButton1Click:Connect(function()
            if (not UserHasAccess) then return; end
            if (not InputBox:IsFocused()) then
                InputBox:CaptureFocus();
            end

            InputQuery(Emoji);
            InputBox.CursorPosition = #InputBox.Text + 1
        end);

        for _, Alias : string in pairs(Emoji.Aliases) do -- All aliases must be formattable!
            Channels:HandleRender(":"..Alias..":", function(UserId : number)
                if (not HasAccessToEmoji(UserId, WhitelistData)) then return; end -- User cant use this emoji (display text)

                local Object = RenderEmoji(Emoji);
    
                Object:SetAttribute("_smImg", true);
                return Object
            end);
    
            BubbleChat:HandleRender(":"..Alias..":", function(Agent : BasePart | Player)
                if (Agent:IsA("Player") and not HasAccessToEmoji(Agent.UserId, WhitelistData)) then return; end -- User cant use this emoji (display text)

                local Object = RenderEmoji(Emoji, true);
    
                Object:SetAttribute("_smImg", true);
                return Object
            end);
        end

        Item.Parent = Section.Emojis
    end

    Section.LayoutOrder = self.LayoutOrder
    Section.Parent = EmotePanel.Categories

    --// Button Setup
    local Button = CreateButton(
        IconData.Name,
        IconData.ImageId,
        IconData.ImageRectSize,
        IconData.ImageRectOffset
    );

    Button.LayoutOrder = self.LayoutOrder
    Button.Icon.MouseButton1Click:Connect(function()
        EmotePanel.Categories.CanvasPosition = Vector2.new(
            0,
            GetSectionPosition(Section)
        );
    end);
    
    --// Canvas Setup
    local Canvas = FunctUI.new('AdjustingCanvas', Section.Emojis);
    
    Canvas.OnUpdated:Connect(function(Size : Vector2)
        local AnchorY : number = Section.Category.AbsoluteSize.Y
        Section.Size = UDim2.new(1, 0, 0, Size.Y + AnchorY);

        EmotePanel.Categories.CanvasPosition = Vector2.new(0, 0);
    end);

    Section.Size = UDim2.fromScale(0, 0); -- Hacky bypass to AdjustingCanvas. Why does it work? I have no idea! It just does...
    Canvas:Update();

    self.LayoutOrder += 1
    return Section, Button
end

--- Determines if the provided content is a UTF8 emoji
function Emojipedia:IsUTF8(Content : string) : boolean
    Trace:Assert(type(Content) == "string", "The provided UTF-8 content was not in the form of a string! Please provide a string to run this process.");
    
    for _, Category in pairs(Emojis) do
        local Emotes = require(Category.Meta);

        for _, Data in pairs(Emotes) do
            if (not Data.Character) then continue; end
            if (Data.Character ~= Content) then continue; end
            
            return true;
        end
    end
end

--- Returns a list of match items based on the provided query parameters [ Best Match --> Worst Match (descending) ]
function Emojipedia:Match(Query : string, MaxItems : number?) : table < string >?
    Trace:Assert(type(Query) == "string", "The supplied 'Query' parameter for the requested Emojipedia match was not of type: 'string'. (got "..(type(Query))..")");
    Trace:Assert(not MaxItems or type(MaxItems) == "number", "The supplied 'MaxItems' parameter was not of type: 'number'. (got "..(type(MaxItems))..")");
    Trace:Assert(not MaxItems or MaxItems > 0, "The supplied 'MaxItems' parameter was not greater than zero! The minimum amount of items must be at least 1 or more.");

    local Matches : table = {};

    for _, Category : table in pairs(Emojis) do
        for _, Emoji in pairs(Category.Meta) do
            local BestWeight : number = 0

            for _, Alias in pairs(Emoji.Aliases) do -- Scan through ALL aliases to find the best one!
                local Likeliness : number = FuzzyMatch(Query, Alias);

                if (Likeliness <= 0) then continue; end -- Does not match
                if (Likeliness < BestWeight) then continue; end

                BestWeight = Likeliness
            end

            if (BestWeight <= 0) then continue; end -- Does not match at all

            table.insert(Matches, {
                ["Weight"] = BestWeight,
                ["Meta"] = Emoji
            });
        end
    end

    table.sort(Matches, function(a, b)
        return a.Weight > b.Weight
    end);

    if (MaxItems and #Matches > MaxItems) then
        for _ = MaxItems + 1, #Matches do
            table.remove(Matches, #Matches); -- Since we order our items in a descending order, we can repeatedly just remove the n'th item
        end
    end

    return Matches
end

--// Private Methods

--- Handles the specified a configuration change [PRIVATE]
function Emojipedia:__handleChange(Query : string, Value : any?)
    if (Query == "DisableEmojiPanel") then -- Do I regret doing nesting like this? Yes, I do...
        EmoteBtn.Visible = (not Value);
    end
end

--// Functions

--- Checks if a user has permission to render an emoji
function HasAccessToEmoji(User : Player, WhitelistData : table) : boolean?
    local UserHasAccess = false

    if (WhitelistData and WhitelistData.RequiresWhitelist) then -- Whitelist enabled
        if ((table.find(WhitelistData.Whitelist, Player.UserId)) or (table.find(WhitelistData.Whitelist, Player.Name))) then -- Requires server update to re-check
            UserHasAccess = true
        elseif ((WhitelistData.GroupId > 0) and (Player:GetRankInGroup(WhitelistData.GroupId) >= WhitelistData.RankRequirement)) then -- Requires rejoin to re-check
            UserHasAccess = true
        elseif (WhitelistData.GamepassId > 0) then -- Gamepass Whitelist
            local Success, PassOwned = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, WhitelistData.GamepassId);
            end);

            if (Success and PassOwned) then
                UserHasAccess = true
            end
        end
    else
        UserHasAccess = true
    end

    return UserHasAccess
end

--- Creates a Button for the emojipedia side panel
function CreateButton(Name : string, ImageId : string, ImageRectSize : Vector2?, ImageRectOffset : Vector2?) : ImageButton
    local Button = Presets.Button:Clone();

    Button.Icon.ImageRectOffset = (ImageRectOffset or Vector2.new(0, 0));
    Button.Icon.ImageRectSize = (ImageRectSize or Vector2.new(0, 0));
    Button.Icon.Image = ImageId

    FunctUI.new('Note', Button, " "..Name);

    Button.Name = Name
    Button.Parent = SidePanel

    return Button
end

--- Renders an emoji-item based on the provided parameters
function RenderEmoji(Emoji : table, NoBubble : boolean?) : ((TextButton | ImageButton) & GuiObject)?
    local Alias : string = Emoji.Aliases[1]; -- Each emoji should have at least ONE alias
    local Item : TextButton | ImageButton

    if (Emoji.Character) then -- This Emoji will be displayed as a UTF8 item!
        Item = Instance.new("TextButton");
        Item.TextScaled = true
        Item.Text = Emoji.Character
    elseif (Emoji.Image) then -- This emoji is NOT a UTF8 emoji
        Item = Instance.new("ImageButton");
        Item.Image = Emoji.Image
    else
        return; -- No data found! :(
    end

    if (Emoji.Animation) then
        local Clip : SpriteClipObject = SpriteClip.new();

        Clip.SpriteSizePixel = Emoji.Animation.SpriteSizePixel
        Clip.SpriteCountX = Emoji.Animation.SpriteCountX
        Clip.SpriteCount = Emoji.Animation.SpriteCount
        Clip.FrameRate = Emoji.Animation.FrameRate

        Clip.InheritSpriteSheet = true
        Clip.Adornee = Item
        Clip:Play();
    end

    Item.ZIndex = 10
    Item.Name = Alias
    Item.BackgroundTransparency = 1

    return Item, (not NoBubble and AddBubble(Item, ":"..(Alias)..":"))
end

--- Adds a bubble over the displayed element
function AddBubble(Element : GuiObject, Content : string) : GuiObject
    local Bubble = Presets.Bubble:Clone();

    Bubble.Size = UDim2.fromOffset(0, 0);
    Bubble.Name = "BUBBLE_"..Content
    Bubble.Content.Text = Content
    Bubble.Parent = EmojiBubbleCache
    
    --// Position Control
    local function UpdatePosition()
        Bubble.Position = UDim2.fromOffset(
            Element.AbsolutePosition.X + (Element.AbsoluteSize.X / 2) + 5,
            Element.AbsolutePosition.Y - 5
        );
    end

    UpdatePosition();
    Element:GetPropertyChangedSignal("AbsolutePosition"):Connect(UpdatePosition);

    --// Size Control
    local ContentSize : Vector2 = TextService:GetTextSize(
        Content,
        32,
        Bubble.Content.Font,
        Camera.ViewportSize
    );

    Element.InputBegan:Connect(function(Input : InputObject)
        if (Input.UserInputType ~= Enum.UserInputType.MouseMovement) then return; end
        if (Settings.DisplayEmojiNameOnHover and Settings.DisplayEmojiNameOnHover.Value == false) then return; end

        TweenService:Create(Bubble, TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
            Size = UDim2.fromOffset(math.max(32, ContentSize.X), 32);
        }):Play();

        TweenService:Create(Bubble.Carrot, TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
            Size = UDim2.fromOffset(24, 24);
        }):Play();
    end);

    Element.InputEnded:Connect(function(Input : InputObject)
        if (Input.UserInputType ~= Enum.UserInputType.MouseMovement) then return; end

        TweenService:Create(Bubble, TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
            Size = UDim2.fromOffset(0, 0);
        }):Play();

        TweenService:Create(Bubble.Carrot, TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
            Size = UDim2.fromOffset(0, 0);
        }):Play();
    end);

    return Bubble
end

--- Returns the CanvasPosition.Y of the provided Section Frame
function GetSectionPosition(Query : Frame) : number
    local Padding : number = EmotePanel.Categories:FindFirstChildOfClass("UIListLayout").Padding.Offset
    local Position = 0

    for _, Section in pairs(EmotePanel.Categories:GetChildren()) do
        if (not Section:IsA("GuiObject")) then continue; end
        if (Section.LayoutOrder >= Query.LayoutOrder) then continue; end

        Position += (Section.AbsoluteSize.Y + Padding);
    end

    return (
        (Position > 0 and (Position - 5))
        or 0
    );
end

--- Returns the likelihood of a string match between string A and string B
function FuzzyMatch(ItemA : string, ItemB : string) : number
    if (ItemA == ItemB) then return 100; end -- If both string match EXACTLY, this is clearly an exact match
    local Likeliness = 0

    for Start, End in utf8.graphemes(ItemA) do
        local Character = ItemA:sub(Start, End);
        if (utf8.codepoint(Character) == 32) then continue; end -- Whitespaces dont count

        if (Character:lower() == ItemB:sub(Start, End):lower()) then -- Matches EXACT letter (eg. 'A' == 'a')
            Likeliness += 3
        else
            break;
        end
    end

    return Likeliness
end

--- Inputs the requested Emoji query into our textbox
function InputQuery(Query : table < Emoji >)
    if (not InputBox:IsFocused()) then
        InputBox:CaptureFocus();
    end

    local EmoteName : string = (
        (Query.Aliases and Query.Aliases[1])
        or Query.Meta.Aliases[1]
    );

    local Input = InputBox.Text
    local Split = Input:split(" ");

    local PriorInput : string = ""

    if (#Split > 1) then
        PriorInput = table.concat(Split, " ", 1, #Split - 1); -- Collect previous text for good UX
    end
    
    InputBox.Text = ((PriorInput) .. " " .. (":".. (EmoteName) .. ":") .. " ");
    InputBox.CursorPosition = #InputBox.Text + 1

    Recent[EmoteName] = {
        ["LastUsed"] = os.time(),
        ["Meta"] = Query
    };

    CurrentSuggestion = nil
end

return Emojipedia