--// Imports
local SocialChat = require(game.ReplicatedStorage:WaitForChild("SocialChat"));
local SmartText = SocialChat.Library.SmartText

--// Constants
local TestUI = script.TestUI
local InputBox = TestUI.Input

TestUI.Parent = game.Players.LocalPlayer.PlayerGui

--// Display Label Setup
local DisplayLabel = Instance.new("TextLabel");

DisplayLabel.Font = InputBox.Font
DisplayLabel.TextSize = InputBox.TextSize
DisplayLabel.TextColor3 = InputBox.TextColor3
DisplayLabel.TextStrokeColor3 = InputBox.TextStrokeColor3

DisplayLabel.Text = ""
DisplayLabel.RichText = true
DisplayLabel.TextTransparency = InputBox.TextTransparency
DisplayLabel.TextStrokeTransparency = InputBox.TextStrokeTransparency

DisplayLabel.TextXAlignment = InputBox.TextXAlignment
DisplayLabel.TextYAlignment = InputBox.TextYAlignment

DisplayLabel.Size = UDim2.fromScale(1, 1);
DisplayLabel.AnchorPoint = Vector2.new(0, 0.5);
DisplayLabel.Position = UDim2.fromScale(0, 0.5);

DisplayLabel.ZIndex = (InputBox.ZIndex + 1);
DisplayLabel.BackgroundTransparency = 1
DisplayLabel.Parent = InputBox

--// Frame Setup
local CursorFrame = Instance.new("Frame");

CursorFrame.Name = "CursorFrame"
CursorFrame.ZIndex = (DisplayLabel.ZIndex + 1);
CursorFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255);

CursorFrame.Position = UDim2.fromScale(0, 0.5);
CursorFrame.AnchorPoint = Vector2.new(0, 0.5);
CursorFrame.Size = UDim2.new(0, 1, 0.95, 0);

CursorFrame.BorderSizePixel = 0
CursorFrame.Parent = DisplayLabel

local SelectionBox = Instance.new("Frame");

SelectionBox.BackgroundColor3 = Color3.fromRGB(105, 200, 255);
SelectionBox.BorderSizePixel = 0

SelectionBox.Name = "SelectionBox"
SelectionBox.ZIndex = InputBox.ZIndex
SelectionBox.Visible = false
SelectionBox.Parent = DisplayLabel

--[[

    TODO: Try again but do this all on your own. Try working with CursorPositions and actually making this into an API rather
        than just vanilla Lua. Ask for help or look for similar resources online! U got this girl! :)

        ALSO, stop trying to make a general TextBox api! This is a lot simpler than that and only needs to highlight upon
        enabling rich text markdown langue!

]]--

--// Services
local TextService = game:GetService("TextService");

--// Imports
local RichTextUtil = require(script.RichTextUtil);
local Highlighter = SocialChat.Handlers.Highlighter
local Markdown = SocialChat.Library.Markdown

--// States
local LastCursorPosition = InputBox.CursorPosition
local FocusPoint = 0

--// TextBox Functuality

--- Serves as a custom Textbox IDE for display label's text content (eg. "**this**" becomes "<b>**this**</b>")
local function updateDisplayText()
    --[[

        TODO: Add color highlighting for syntaxes like "*", "~", and "_"!
        [FORMAT]: "<font color=\"rgb(190,190,190)\">%s</font>"

    ]]--

    --// Escaping
    --\\ We need to escape any problematic richtext identifiers like "<" to prevent our richtext from breaking!

    local CleanText = InputBox.Text
    local Point = 0

    for _ in InputBox.Text:gmatch(">-<") do
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
    local Position = InputBox.CursorPosition

    if (InputBox:IsFocused()) then
        LastCursorPosition = Position
        CursorFrame.Visible = true
    end

    if (Position ~= -1) then
        local CursorTextSize = GetBoundX(InputBox.Text:sub(0, Position - 1), InputBox.TextSize, InputBox.Font);
        CursorFrame.Position = UDim2.new(0, CursorTextSize, 0.5, 0);
    end
end

--- Updates our display label's position in a way that follows our cursor position
local function updateDisplayPosition()
    local CursorPosition = InputBox.CursorPosition
    local Padding = 5

    local RelativeSizeX = math.floor(InputBox.AbsoluteSize.X);
    if (CursorPosition == -1) then return; end -- Make sure we have a valid cursor position
    
    local TotalWidth = GetBoundX(InputBox.Text, InputBox.TextSize, InputBox.Font);
    local CursorWidth = GetBoundX(InputBox.Text:sub(0, CursorPosition - 1), InputBox.TextSize, InputBox.Font);

    local WidthOffset = (((FocusPoint + RelativeSizeX) + Padding + 2) - CursorWidth);

    local IsOffScreenOnLeft = (((RelativeSizeX + ((#InputBox.Text <= 5 and Padding) or 0)) < WidthOffset));
    local IsOffScreenOnRight = ((CursorWidth + Padding + 1) > FocusPoint + RelativeSizeX);
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
    
    if ((CursorWidth < Padding or #InputBox.Text == 0) and (not IsOffScreen)) then
        DisplayLabel.Position = UDim2.new(0, Padding, 0.5, 0);
        DisplayLabel.Size = UDim2.new(0.98, 0, 1, 0);
        
        FocusPoint = 0
    elseif (IsOffScreen) then
        if (IsOffScreenOnLeft) then
            local CursorStart = math.min(CursorPosition, LastCursorPosition);
            local CursorEnd = math.max(CursorPosition, LastCursorPosition);

            local ChangeWidth = GetBoundX(InputBox.Text:sub(CursorStart, CursorEnd), InputBox.TextSize, InputBox.Font);

            FocusPoint = math.max(FocusPoint - ChangeWidth,  0)
            DisplayLabel.Position = UDim2.new(0, -CursorWidth + Padding, 0.5, 0);
        elseif (IsOffScreenOnRight) then
            FocusPoint = math.max(CursorWidth - RelativeSizeX, 0);

            DisplayLabel.Size = UDim2.new(0, InputBox.AbsoluteSize.X + math.max(TotalWidth - RelativeSizeX, 0), 1, 0); -- We need to constantly grow our DisplayLabel in order to keep the system functional
            DisplayLabel.Position = UDim2.new(0, RelativeSizeX - CursorWidth - Padding - 2, 0.5, 0);
        end
    end
end

--- Updates the selected text content!
local function updateSelectionBox()
    local selectionInfo = GetSelectedContent();
    
    if (selectionInfo) then
        SelectionBox.Size = UDim2.fromOffset(selectionInfo.SelectionSize, DisplayLabel.AbsoluteSize.Y + 4);
        SelectionBox.Position = UDim2.fromOffset(selectionInfo.StartPos, 0);
        SelectionBox.Visible = true
    else
        SelectionBox.Visible = false
    end
end

InputBox:GetPropertyChangedSignal("SelectionStart"):Connect(updateSelectionBox);
InputBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateDisplayText();
    updateCursorFrame();
    updateDisplayPosition();
end);

InputBox:GetPropertyChangedSignal("CursorPosition"):Connect(function()
    updateSelectionBox();
    updateCursorFrame();
    updateDisplayPosition();
end);

DisplayLabel.InputBegan:Connect(function(input)
    if ((input.UserInputType ~= Enum.UserInputType.MouseButton1) and (input.UserInputType ~= Enum.UserInputType.Touch)) then return; end

    InputBox:CaptureFocus();
end);

InputBox.TextStrokeTransparency = 1
InputBox.TextTransparency = 1

--// FontSize Determination
InputBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    local FontSize = SmartText:GetBestFontSize(InputBox.AbsoluteSize, InputBox.Font, 0, 20);

    InputBox.TextSize = FontSize
    DisplayLabel.TextSize = FontSize
end);

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
    if ((InputBox.CursorPosition == -1) or (InputBox.SelectionStart == -1)) then return; end
    
    local selectionStart : number = math.min(InputBox.CursorPosition, InputBox.SelectionStart);
    local selectionEnd : number = math.max(InputBox.CursorPosition, InputBox.SelectionStart) - 1;

    local TotalTextSize = GetBoundX(InputBox.Text, InputBox.TextSize, InputBox.Font);
    local priorTextSize = GetBoundX(InputBox.Text:sub(0, selectionStart - 1), InputBox.TextSize, InputBox.Font);
    local afterTextSize = GetBoundX(InputBox.Text:sub(selectionEnd + 1), InputBox.TextSize, InputBox.Font);

    local absSelectionSize = ((TotalTextSize - afterTextSize) - priorTextSize);
    local selectedText = string.sub(
        InputBox.Text,
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

updateDisplayText();
updateCursorFrame();
updateDisplayPosition();