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
local PlaceholderLabel : Instance?
local CursorFrame = Instance.new("Frame");
local SelectionBox = Instance.new("Frame");

local IsMobile = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled);
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

    Settings = self.Settings.ClientChannels
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

        --[[
    
            TODO: Add color highlighting for syntaxes like "*", "~", and "_"!
            [FORMAT]: "<font color=\"rgb(190,190,190)\">%s</font>"
    
        ]]--
    
        --// Escaping
        --\\ We need to escape any problematic richtext identifiers like "<" to prevent our richtext from breaking!
    
        local CleanText = ChatBox.Text:gsub("%s+", "");
        local Point = 0
    
        for _ in ChatBox.Text:gmatch(">-<") do
            local starts, ends = CleanText:find(">-<", Point);
            
            CleanText = CleanText:sub(0, starts - 1)
                .."&lt;" -- Escape any "<" operators to prevent our richtext from breaking
                ..CleanText:sub(ends + 1)
    
            Point += (ends - Point);
        end
    
        DisplayLabel.Text = Markdown:Markup(Highlighter(CleanText), true);
    end
    
    --- Updates our textbox's cursor frame position
    local function updateCursorFrame()
        if (IsMobile) then return; end

        local Position = ChatBox.CursorPosition
    
        if (ChatBox:IsFocused()) then
            CursorFrame.Visible = true
            CursorTick = os.clock();
            LastCursorPosition = Position
        end
    
        if (Position ~= -1) then
            local CursorTextSize = GetBoundX(ChatBox.Text:sub(0, Position - 1), ChatBox.TextSize, ChatBox.Font);
            CursorFrame.Position = UDim2.new(0, CursorTextSize, 0.5, 0);
        end
    end
    
    --- Updates our display label's position in a way that follows our cursor position
    local function updateDisplayPosition()
        local CursorPosition = ChatBox.CursorPosition
    
        local RelativeSizeX = math.floor(ChatBox.AbsoluteSize.X);
        if (CursorPosition == -1) then return; end -- Make sure we have a valid cursor position
        
        local TotalWidth = GetBoundX(ChatBox.Text, ChatBox.TextSize, ChatBox.Font);
        local CursorWidth = GetBoundX(ChatBox.Text:sub(0, CursorPosition - 1), ChatBox.TextSize, ChatBox.Font);
    
        local WidthOffset = (((FocusPoint + RelativeSizeX) + 2) - CursorWidth);
    
        local IsOffScreenOnLeft = (RelativeSizeX < WidthOffset);
        local IsOffScreenOnRight = ((CursorWidth + 1) > FocusPoint + RelativeSizeX);
        local IsOffScreen = (IsOffScreenOnLeft or IsOffScreenOnRight);
    
        --[[
    
            warn("-------------------------------------------------------------");
            print("IS OFFSCREEN:", IsOffScreen);
            print("OFFSCREEN ON RIGHT:", IsOffScreenOnRight);
            print("OFFSCREEN ON LEFT:", IsOffScreenOnLeft);
            print("WIDTH OFFSET:", WidthOffset);
            print("FOCUS POINT:", FocusPoint);
            print("CURSOR WIDTH:", CursorWidth);
            
        ]]--
        
        if ((CursorWidth < #ChatBox.Text == 0) and (not IsOffScreen)) then
            DisplayLabel.Position = UDim2.new(0, 0, 0.5, 0);
            DisplayLabel.Size = UDim2.new(0.98, 0, 1, 0);
            
            FocusPoint = 0
        elseif (IsOffScreen) then
            if (IsOffScreenOnLeft) then
                local CursorStart = math.min(CursorPosition, LastCursorPosition);
                local CursorEnd = math.max(CursorPosition, LastCursorPosition);
    
                local ChangeWidth = GetBoundX(ChatBox.Text:sub(CursorStart, CursorEnd), ChatBox.TextSize, ChatBox.Font);
    
                FocusPoint = math.max(FocusPoint - ChangeWidth,  0)
                DisplayLabel.Position = UDim2.new(0, -CursorWidth, 0.5, 0);
            elseif (IsOffScreenOnRight) then
                FocusPoint = math.max(CursorWidth - RelativeSizeX, 0);
    
                DisplayLabel.Size = UDim2.new(0, ChatBox.AbsoluteSize.X + math.max(TotalWidth - RelativeSizeX, 0), 1, 0); -- We need to constantly grow our DisplayLabel in order to keep the system functional
                DisplayLabel.Position = UDim2.new(0, RelativeSizeX - CursorWidth - 2, 0.5, 0);
            end
        end
    end
    
    --- Updates the selected text content!
    local function updateSelectionBox()
        if (IsMobile) then return; end

        local selectionInfo = GetSelectedContent();
        
        if (selectionInfo) then
            SelectionBox.Size = UDim2.fromOffset(selectionInfo.SelectionSize, DisplayLabel.AbsoluteSize.Y + 4);
            SelectionBox.Position = UDim2.fromOffset(selectionInfo.StartPos, 0);
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
        elseif (IsControlHeld and SyntaxEmbed and ChatBox:IsFocused() and SelectedText) then -- Special Markdown syntaxing!
            local SelectionA, SelectionB = ChatBox.CursorPosition, ChatBox.SelectionStart
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

            if (SelectionA > SelectionB) then
                ChatBox.Text = string.format(
                    "%s%s%s",
                    ChatBox.Text:sub(1, SelectionB - 1),
                    ReplacementText,
                    ChatBox.Text:sub(SelectionA)
                );
            else
                ChatBox.Text = string.format(
                    "%s%s%s",
                    ChatBox.Text:sub(1, SelectionA - 1),
                    ReplacementText,
                    ChatBox.Text:sub(SelectionB)
                );
            end

            --// Cursor Position Handling
            --\\ Sometimes our CursorPosition will be ahead of our Selection position and sometimes it wont...so we need to deal with it!
            
            local PositionOffset = (
                (IsMarkedDown) and (-SyntaxEmbed:len() * 2)
                or (SyntaxEmbed:len() * 2)
            );

            if (SelectedText.StartPos > SelectedText.EndPos) then -- Backwards selection (left <-- right)
                ChatBox.CursorPosition = (SelectedText.StartPos + PositionOffset);
                ChatBox.SelectionStart = SelectedText.EndPos
            else -- Normal selection (left --> right)
                ChatBox.CursorPosition = SelectedText.StartPos
                ChatBox.SelectionStart = (SelectedText.EndPos + PositionOffset);
            end
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
        if ((self._oldText or ChatBox.Text):gsub(" ", ""):len() == 0) then return; end -- Empty strings cant be sent!
        Channels:SendMessage(self._oldText or ChatBox.Text);

        self._oldText = nil
        ChatBox.Text = ""
    end);

    ChatBox.FocusLost:Connect(function(enterPressed : boolean)
        PlaceholderLabel.Visible = (#ChatBox.Text == 0);
        CursorFrame.Visible = false

        if (not enterPressed) then -- Message was interrupted. Proceed with visuals
            self._oldText = ChatBox.Text
            self:Set(Highlighter(Markdown:Markup(ChatBox.Text)));
        else -- Submit our message
            if (ChatBox.Text:gsub(" ", ""):len() == 0) then return; end -- Empty string cancelation
            Channels:SendMessage(ChatBox.Text);
            
            self._oldText = nil
            ChatBox.Text = ""
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
function InputBox:Set(content : string)
    if ((type(content) ~= "string") or (#content == 0)) then return; end -- Silent cancelation is required for arbitrary functuality

    systemWasTyping = true
    ChatBox.Text = content
    systemWasTyping = false
end

--// Functions

--- Returns RichText bounds based on the provided content string!
function GetBoundX(content : string, TextSize : number, TextFont : Enum.Font) : number
	local Occurences = Markdown:GetMarkdownData(content);

	if (not Occurences) then
		return TextService:GetTextSize(content, TextSize, TextFont, Vector2.new(math.huge, math.huge)).X -- Default Return
	end

	--// Font Setup
	local NormalFont = Font.fromEnum(TextFont);
	local BoldFont = Font.fromEnum(TextFont);
	local ItalicFont = Font.fromEnum(TextFont);

	BoldFont.Bold = true
	ItalicFont.Style = Enum.FontStyle.Italic

	--// TextParams Setup
	local NormalParams = Instance.new("GetTextBoundsParams");
	NormalParams.Font = NormalFont
	NormalParams.Size = TextSize

	local BoldParams = Instance.new("GetTextBoundsParams");
	BoldParams.Font = BoldFont
	BoldParams.Size = TextSize

	local ItalicParams = Instance.new("GetTextBoundsParams");
	ItalicParams.Font = ItalicFont
	ItalicParams.Size = TextSize

	--// TextBound analysis
	local BoundX = 0

	for starts, ends in utf8.graphemes(content) do
		local Character = content:sub(starts, ends);
		local ThisMarkdown : string?

		for syntax, data in pairs(Occurences) do
            if (ThisMarkdown) then break; end

            for _, scope in ipairs(data.results) do
                if (starts >= scope.starts and ends <= scope.ends) then
                    ThisMarkdown = syntax
                    break; -- No need to continue our iteration!
                end
            end
        end

		local Bounds

		if (ThisMarkdown ~= "**" and ThisMarkdown ~= "*") then -- RichText unique bounds are NOT active here.
			NormalParams.Text = Character
			Bounds = TextService:GetTextBoundsAsync(NormalParams);
		else -- RichText bounds are active here!
			local Params = ((ThisMarkdown == "**" and BoldParams) or (ItalicParams));
			Params.Text = Character
			
			Bounds = TextService:GetTextBoundsAsync(Params);
		end

		BoundX += Bounds.X
	end

	return BoundX
end

--- Returns an array of data based on the currently selected text within our InputBox (if any)
function GetSelectedContent() : table
    if ((ChatBox.CursorPosition == -1) or (ChatBox.SelectionStart == -1)) then return; end
    
    local selectionStart : number = math.min(ChatBox.CursorPosition, ChatBox.SelectionStart);
    local selectionEnd : number = math.max(ChatBox.CursorPosition, ChatBox.SelectionStart) - 1;

    local TotalTextSize = GetBoundX(ChatBox.Text, ChatBox.TextSize, ChatBox.Font);
    local priorTextSize = GetBoundX(ChatBox.Text:sub(0, selectionStart - 1), ChatBox.TextSize, ChatBox.Font);
    local afterTextSize = GetBoundX(ChatBox.Text:sub(selectionEnd + 1), ChatBox.TextSize, ChatBox.Font);

    local absSelectionSize = ((TotalTextSize - afterTextSize) - priorTextSize);
    local selectedText = string.sub(
        ChatBox.Text,
        selectionStart,
        selectionEnd
    );

    return {
        ["StartPos"] = priorTextSize,
        ["EndPos"] = TotalTextSize - afterTextSize,

        ["SelectionSize"] = absSelectionSize,
        ["Text"] = selectedText
    };
end

return InputBox