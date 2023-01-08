--[[

    Name: Mari
    Date: 12/22/2022

    Description: This component module handles SocialChat's input box!

]]--

--// Module
local InputBox = {};
InputBox.__index = InputBox

--// Services
local UserInputService = game:GetService("UserInputService");
local TextService = game:GetService("TextService");
local RunService = game:GetService("RunService");

--// Imports
local Highlighter
local SmartText
local Markdown

local Settings
local Channels

--// Constants
local InputFrame
local InteractionBar

local SubmitButton
local ChatBox

local DisplayLabel = Instance.new("TextLabel");
local CursorFrame = Instance.new("Frame");
local SelectionBox = Instance.new("Frame");
local PlaceholderLabel : Instance?

local IsMobile = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled);
local Player = game.Players.LocalPlayer

local SyntaxFormatting = "<font color=\"rgb(190,190,190)\">%s</font>"
local Syntaxes = {"*", "_", "~"};

local SyntaxEmbeds = {
    [Enum.KeyCode.I] = "*",
    [Enum.KeyCode.B] = "**",
    [Enum.KeyCode.S] = "~~",
    [Enum.KeyCode.U] = "__"
};

--// States
local systemWasTyping : boolean
local IsControlHeld : boolean?

local LastCursorPosition : number
local FocusPoint : number = 0

local CursorTick : number = os.clock();

--// Initialization

function InputBox:Initialize(Info : table) : metatable
    local self = setmetatable(Info, InputBox);

    Highlighter = self.Handlers.Highlighter
    SmartText = self.Library.SmartText
    Markdown = self.Library.Markdown

    Settings = self.Settings.LocalChannels
    Channels = self.Src.Channels

    InputFrame = self.ChatUI.Chat.Input
    InteractionBar = InputFrame.InteractionBar

    SubmitButton = InteractionBar.Submit
    ChatBox = InteractionBar.InputBox

    LastCursorPosition = ChatBox.CursorPosition

    --// Control Functions
    --\\ This is where all of our local control functions exist!

    local function updateDisplayText()
        if (IsMobile) then return; end
    
        --// Escaping
        --\\ We need to escape any problematic richtext identifiers like "<" to prevent our richtext from breaking!
    
        local CleanText = ChatBox.Text
        local Point = 0
    
        for _ in ChatBox.Text:gmatch(">-<") do
            local starts, ends = CleanText:find(">-<", Point);
            
            CleanText = CleanText:sub(0, starts - 1)
                .."&lt;" -- Escape any "<" operators to prevent our richtext from breaking
                ..CleanText:sub(ends + 1)
    
            Point += (ends - Point);
        end

        --// Syntax Coloring & Formatting
        --\\ We need to color our syntaxes for UX purposes!

        local MarkedText = (
            (Settings.AllowMarkdown and Markdown:Markup(Highlighter(CleanText), true)) or
            Highlighter(CleanText)
        );

        local NewText = MarkedText

        local Occurences = Markdown:GetMarkdownData(NewText);
        local Offset = 0
        
        for starts, ends in utf8.graphemes(MarkedText) do
            local Character = MarkedText:sub(starts, ends);
            if (not table.find(Syntaxes, Character)) then continue; end

            local IsFromMarkdown : boolean?

            for syntax, data in pairs(Occurences) do
                if (syntax:sub(1, 1) ~= Character) then continue; end

                for _, scope in ipairs(data.results) do
                    if (starts >= scope.starts and ends <= scope.ends) then
                        IsFromMarkdown = true
                        break;
                    end
                end
            end

            if (not IsFromMarkdown) then continue; end

            local Formatting = SyntaxFormatting:format(Character);

            NewText = NewText:sub(0, starts + Offset - 1)
                ..Formatting
                ..NewText:sub(ends + Offset + 1)

            Offset += (#SyntaxFormatting - 2);
        end
    
        DisplayLabel.Text = NewText
    end
    
    --- Updates our textbox's cursor frame position
    local function updateCursorFrame()
        if (IsMobile) then return; end

        local Position = ChatBox.CursorPosition
    
        if (ChatBox:IsFocused()) then
            CursorFrame.Visible = true
            CursorTick = os.clock();
            
            task.defer(function() -- task.defer is used here because our task needs to update our LastCursorPosition AFTER the preceding calculations are done
                LastCursorPosition = Position
            end, RunService.RenderStepped);
        end
    
        if (Position ~= -1) then
            local RealBounds = DisplayLabel.TextBounds.X
            local TotalBounds = GetBoundX(ChatBox.Text, 0);
            local BoundOffset = (TotalBounds - RealBounds);

            local CursorText = ChatBox.Text:sub(0, Position - 1);
            local CursorTextSize = GetBoundX(CursorText, 0);

            CursorFrame.Position = UDim2.new(0, CursorTextSize - BoundOffset, 0.5, 0);
        end
    end
    
    --- Updates our display label's position in a way that follows our cursor position
    local function updateDisplayPosition()
        local CursorPosition = ChatBox.CursorPosition
        if (CursorPosition == -1) then return; end -- Make sure we have a valid cursor position
    
        local RelativeSizeX = math.floor(ChatBox.AbsoluteSize.X);
        local CursorTextSize = GetBoundX(ChatBox.Text:sub(0, CursorPosition - 1), 0); -- This is the TextSize of the text BEFORE our cursorpos

        local IsOffScreenOnLeft = (CursorFrame.AbsolutePosition.X <= ChatBox.AbsolutePosition.X);
        local IsOffScreenOnRight = (CursorTextSize > FocusPoint + RelativeSizeX);

        --[[
    
            warn("-------------------------------------------------------------");
            print("RIGHT OFF SCRN:", IsOffScreenOnRight);
            print("LEFT OFF SCRN:", IsOffScreenOnLeft);
            print("FOCUS POINT:", FocusPoint);
            print("CURSOR #TXT:", CursorTextSize);
            
        ]]--
        
        if (#ChatBox.Text == 0) then -- No text! (reset everything)
            DisplayLabel.Position = UDim2.new(0, 0, 0.5, 0);
            DisplayLabel.Size = UDim2.new(0.98, 0, 1, 0);

            FocusPoint = 0
        elseif (IsOffScreenOnLeft) then -- We're on the LEFT edge of our TextBox!
            local CursorStart = math.min(CursorPosition, LastCursorPosition);
            local CursorEnd = math.max(CursorPosition, LastCursorPosition);

            local ChangeWidth = GetBoundX(ChatBox.Text:sub(CursorStart, CursorEnd), CursorStart);

            FocusPoint = math.max(FocusPoint - ChangeWidth, 0);
            DisplayLabel.Position = UDim2.new(0, -CursorTextSize + ((FocusPoint > 25 and 5) or 0), 0.5, 0);
        elseif (IsOffScreenOnRight) then -- We're on the RIGHT edge of our TextBox!
            FocusPoint = math.max(CursorTextSize - RelativeSizeX, 0);

            DisplayLabel.Size = UDim2.new(0, RelativeSizeX + math.max(DisplayLabel.TextBounds.X - RelativeSizeX, 0), 1, 0);
            DisplayLabel.Position = UDim2.new(0, RelativeSizeX - CursorTextSize, 0.5, 0);
        end
    end
    
    --- Updates the selected text content!
    local function updateSelectionBox()
        if (IsMobile) then return; end

        local SelectionInfo = GetSelectedContent();
        
        if (SelectionInfo) then
            SelectionBox.Size = UDim2.fromOffset(SelectionInfo.SelectionSize, DisplayLabel.AbsoluteSize.Y + 4);
            SelectionBox.Position = UDim2.fromOffset(SelectionInfo.StartPos, 0);
            SelectionBox.Visible = true
        else
            SelectionBox.Visible = false
        end
    end

    updateDisplayText();
    updateCursorFrame();
    updateDisplayPosition();

    --// Instancing
    --\\ We need to create dynamic instances used to make our IDE function! (NOTE: This ONLY works on mobile devices!)

    if (not IsMobile) then -- Client is NOT on mobile! We need to setup our custom TextBox for special features!

        --// Display Label Setup
        DisplayLabel.Font = ChatBox.Font
        DisplayLabel.TextSize = ChatBox.TextSize
        DisplayLabel.TextColor3 = ChatBox.TextColor3
        DisplayLabel.TextStrokeColor3 = ChatBox.TextStrokeColor3

        DisplayLabel.Text = ""
        DisplayLabel.RichText = true
        DisplayLabel.TextTransparency = ChatBox.TextTransparency
        DisplayLabel.TextStrokeTransparency = ChatBox.TextStrokeTransparency

        DisplayLabel.TextXAlignment = ChatBox.TextXAlignment
        DisplayLabel.TextYAlignment = ChatBox.TextYAlignment

        DisplayLabel.Size = UDim2.fromScale(1, 1);
        DisplayLabel.AnchorPoint = Vector2.new(0, 0.5);
        DisplayLabel.Position = UDim2.fromScale(0, 0.5);

        DisplayLabel.ZIndex = (ChatBox.ZIndex + 1);
        DisplayLabel.BackgroundTransparency = 1
        DisplayLabel.Name = "DisplayLabel"
        DisplayLabel.Parent = ChatBox

        --// Placeholder label setup
        PlaceholderLabel = DisplayLabel:Clone();
        PlaceholderLabel.Text = ChatBox.PlaceholderText
        PlaceholderLabel.TextColor3 = ChatBox.PlaceholderColor3

        PlaceholderLabel.RichText = false
        PlaceholderLabel.Name = "PlaceholderTextLabel"
        PlaceholderLabel.Parent = ChatBox

        --// Cursor Frame Setup
        CursorFrame.Name = "CursorFrame"
        CursorFrame.ZIndex = (DisplayLabel.ZIndex + 1);
        CursorFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
        
        CursorFrame.Position = UDim2.fromScale(0, 0.5);
        CursorFrame.AnchorPoint = Vector2.new(0, 0.5);
        CursorFrame.Size = UDim2.new(0, 1, 0.95, 0);
        
        CursorFrame.BorderSizePixel = 0
        CursorFrame.Visible = false
        CursorFrame.Parent = DisplayLabel
        
        --// SelectionBox Setup
        SelectionBox.BackgroundColor3 = Color3.fromRGB(105, 200, 255);
        SelectionBox.BorderSizePixel = 0

        SelectionBox.Name = "SelectionBox"
        SelectionBox.ZIndex = ChatBox.ZIndex
        SelectionBox.Visible = false
        SelectionBox.Parent = DisplayLabel
        
        ChatBox:GetPropertyChangedSignal("SelectionStart"):Connect(updateSelectionBox);
        ChatBox:GetPropertyChangedSignal("CursorPosition"):Connect(function()
            updateSelectionBox();
            updateCursorFrame();
            updateDisplayPosition();
        end);

        DisplayLabel.InputBegan:Connect(function(input)
            if ((input.UserInputType ~= Enum.UserInputType.MouseButton1) and (input.UserInputType ~= Enum.UserInputType.Touch)) then return; end
            ChatBox:CaptureFocus();
        end);

        ChatBox.TextStrokeTransparency = 1
        ChatBox.TextTransparency = 1

    else -- Client is on mobile! (destroy all un-needed instances)
        DisplayLabel:Destroy();
        SelectionBox:Destroy();
        CursorFrame:Destroy();
    end

    --// Input Detection
    --\\ Here we detect when inputs are made

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        local SyntaxEmbed = SyntaxEmbeds[input.KeyCode];
        local SelectedText = GetSelectedContent();
        
        if ((input.KeyCode == Enum.KeyCode.Slash) and (not gameProcessedEvent and not ChatBox:IsFocused())) then
            if (self.ChatButton:getToggleState() == "deselected") then
                self.ChatButton:select();
            end
    
            task.defer(ChatBox.CaptureFocus, ChatBox);
        elseif (IsControlHeld and SyntaxEmbed and ChatBox:IsFocused() and SelectedText and Settings.AllowMarkdown) then -- Special Markdown syntaxing!
            local SelectionA, SelectionB = SelectedText.Cursor.Starts, SelectedText.Cursor.Ends
            local Text = SelectedText.Text

            --// Markdown determination
            --\\ We dont want to re-mark a syntax twice!

            local IsMarkedDown = (
                (Text:sub(1, #SyntaxEmbed) == SyntaxEmbed) and
                (Text:sub(#Text - #SyntaxEmbed + 1, #Text) == SyntaxEmbed)
            );

            local InnerText = Text:sub(#SyntaxEmbed + 1, #Text - #SyntaxEmbed);

            --// Text replacement
            --\\ We need to update our text with out new embeded text!

            local ReplacementText = (
                ((IsMarkedDown) and (InnerText)) -- This text is already marked down! (remove syntaxes)
                or ((SyntaxEmbed)..(Text)..(SyntaxEmbed)) -- This text is NOT marked down! (add syntaxes)
            );

            RunService.RenderStepped:Wait(); -- For cases such as "CTRL + I" keyboard actions have to process before we continue

            ChatBox.Text = string.format(
                "%s%s%s",
                ChatBox.Text:sub(0, SelectionA - 1),
                ReplacementText,
                ChatBox.Text:sub(SelectionB + 1)
            );

            --// Cursor Position Handling
            --\\ Sometimes our CursorPosition will be ahead of our Selection position and sometimes it wont...so we need to deal with it!
            
            local PositionOffset = (
                (IsMarkedDown) and (-SyntaxEmbed:len())
                or (SyntaxEmbed:len() * 2)
            );

            ChatBox.CursorPosition = SelectionA
            ChatBox.SelectionStart = (SelectionB + 1 + PositionOffset);

            updateSelectionBox(); -- Sometimes our SelectionBox won't update on the same frame that our CursorPosition does!
        elseif (input.KeyCode == Enum.KeyCode.LeftControl) then
            IsControlHeld = true
        end
    end);

    UserInputService.InputEnded:Connect(function(input)
        if (input.KeyCode ~= Enum.KeyCode.LeftControl) then return; end
        IsControlHeld = false
    end);

    ChatBox:GetPropertyChangedSignal("Text"):Connect(function()
        if (systemWasTyping) then return; end

        --// Visual Button avaliability
        SubmitButton.ImageColor3 = (
            (#ChatBox.Text > 0 and Color3.fromRGB(255, 255, 255))
            or Color3.fromRGB(125, 125, 125)
        );

        --// RichText removal
        local PureText, Occurences = ChatBox.Text:gsub("(\\?)<[^<>]->", "");
        
        if (Occurences > 0) then
            self:Set(PureText);
        end

        --// Local Updates
        updateDisplayText();
        updateCursorFrame();
        updateDisplayPosition();
    end);

    ChatBox.Focused:Connect(function()
        PlaceholderLabel.Visible = false
        CursorFrame.Visible = true

        if (#ChatBox.Text > 0) then
            self:Set(self._oldText);
        end
    end);

    --// Chat Submittion
    --\\ Here we finalize our textbox string before sending it out!

    SubmitButton.MouseButton1Click:Connect(function()
        self:Submit();

        task.defer(function()
            PlaceholderLabel.Visible = (#ChatBox.Text == 0);
        end, RunService.RenderStepped);
    end);

    ChatBox.FocusLost:Connect(function(enterPressed : boolean)
        CursorFrame.Visible = false
        FocusPoint = 0

        task.defer(function()
            PlaceholderLabel.Visible = (#ChatBox.Text == 0);
        end, RunService.RenderStepped);

        if (not enterPressed) then -- Message was interrupted. Proceed with visuals
            self._oldText = ChatBox.Text
            self:Set(Highlighter(
                (Settings.AllowMarkdown and Markdown:Markup(ChatBox.Text)) or
                ChatBox.Text
            ));
        else -- Submit our message
            self:Submit();
        end
    end);

    --// Cursor Frame Flicker
    RunService.RenderStepped:Connect(function()
        if (((os.clock() - CursorTick) >= 0.5) and (ChatBox:IsFocused())) then
            CursorTick = os.clock();
            CursorFrame.Visible = not CursorFrame.Visible
        end
    end);

    --// Font Sizing
    local function updateFontSize()
        local FontSize = SmartText:GetBestFontSize(ChatBox.AbsoluteSize, ChatBox.Font, 0, 20);
        
        if (not IsMobile) then
            DisplayLabel.TextSize = FontSize
            PlaceholderLabel.TextSize = FontSize
        end

        ChatBox.TextSize = FontSize
    end

    updateFontSize();

    ChatBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateFontSize);
    ChatBox.Font = Settings.MessageFont

    return self
end

--// Methods

--- Sets the TextBox's text content to the provided string
function InputBox:Set(content : string, captureClient : boolean?)
    if ((type(content) ~= "string") or (#content == 0)) then return; end -- Silent cancelation is required for arbitrary functuality

    if (captureClient) then
        ChatBox:CaptureFocus();

        task.defer(function()
            ChatBox.CursorPosition = #content + 1
        end, ChatBox:GetPropertyChangedSignal("Text"));
    end

    systemWasTyping = not captureClient
    ChatBox.Text = content
    systemWasTyping = false
end

--- Sends the currently typed message to the server (if any)
function InputBox:Submit()
    if ((self._oldText or ChatBox.Text):gsub(" ", ""):len() == 0) then return; end -- Empty strings cant be sent!
    
    local Words = ChatBox.Text:split(" ");
    local Focus = Channels:GetFocus();

    local WhisperClient = (
        ((#Words >= 3) and (Words[1] == "/w") and (FindPlayer(Words[2]))) or -- Whispering using the "/w {player}" command
        (Focus.IsPrivate and Focus.Members[1]) -- Whispering via a private channel
    );

    local IsValidClient = (WhisperClient and WhisperClient ~= Player);

    Channels:SendMessage(
        ((IsValidClient and not Focus.IsPrivate) and table.concat(Words, " ", 3))
        or ChatBox.Text, (IsValidClient and WhisperClient)
    );

    CursorFrame.Visible = false
    self._oldText = nil

    ChatBox.Text = ""
    FocusPoint = 0
end

--// Functions

--- Returns RichText bounds based on the provided content string!
function GetBoundX(content : string, atIndex : number) : number
	local Occurences = Markdown:GetMarkdownData(ChatBox.Text);

	if (not Occurences or not Settings.AllowMarkdown) then
		return TextService:GetTextSize(
            content,
            ChatBox.TextSize,
            ChatBox.Font,
            Vector2.new(math.huge, math.huge)
        ).X -- Default Return
	end

	--// TextBound analysis
	local Params = Instance.new("GetTextBoundsParams");
	Params.Size = ChatBox.TextSize
    
	local ThisFont = Font.fromEnum(ChatBox.Font);
	local BoundX = 0

	for starts, ends in utf8.graphemes(content) do
		local Character = content:sub(starts, ends);

        local IsItalic : boolean?
        local IsBold : boolean?

		for syntax, data in pairs(Occurences) do
            if (syntax ~= "**" and syntax ~= "*") then continue; end

            for _, scope in ipairs(data.results) do
                if (atIndex + starts >= scope.starts and atIndex + starts <= scope.ends) then
                    IsItalic = (syntax == "*");
                    IsBold = (syntax == "**");

                    break;
                end
            end
        end

		if (not IsItalic and not IsBold) then -- RichText unique bounds are NOT active here.
            ThisFont.Bold = false
            ThisFont.Style = Enum.FontStyle.Normal
		else -- RichText bounds are active here!
            ThisFont.Bold = IsBold
            ThisFont.Style = ((IsItalic and Enum.FontStyle.Italic) or Enum.FontStyle.Normal);
		end

        Params.Font = ThisFont
        Params.Text = Character

		BoundX += (TextService:GetTextBoundsAsync(Params).X);
	end

	return BoundX
end

--- Returns an array of data based on the currently selected text within our InputBox (if any)
function GetSelectedContent() : table
    if ((ChatBox.CursorPosition == -1) or (ChatBox.SelectionStart == -1)) then return; end

    local RealBounds = DisplayLabel.TextBounds.X
    local TotalBounds = GetBoundX(ChatBox.Text, 0);
    local BoundOffset = (TotalBounds - RealBounds);

    local Starts : number = math.min(ChatBox.CursorPosition, ChatBox.SelectionStart);
    local Ends : number = math.max(ChatBox.CursorPosition, ChatBox.SelectionStart) - 1;

    local PriorTextSize = GetBoundX(ChatBox.Text:sub(0, Starts - 1), 0);
    local AfterTextSize = GetBoundX(ChatBox.Text:sub(Ends + 1), Ends + 1);

    local SelectedText = ChatBox.Text:sub(Starts, Ends);
    local SelectionSize = GetBoundX(SelectedText, Starts);

    return {
        ["StartPos"] = PriorTextSize - BoundOffset, -- Position < UDim2 >
        ["EndPos"] = RealBounds - AfterTextSize, -- Position < UDim2 >

        ["Cursor"] = { -- Cursor Position data < table :: numbers >
            ["Starts"] = Starts,
            ["Ends"] = Ends
        },

        ["SelectionSize"] = SelectionSize, -- Size < UDim2 >
        ["Text"] = SelectedText -- Selected Text < string >
    };
end

--- Searches for a player using the provided string
function FindPlayer(query : string) : Player
    for _, Player in pairs(game.Players:GetPlayers()) do
        if (Player.Name:lower() == query:lower()) then
            return Player
        end
    end
end

return InputBox