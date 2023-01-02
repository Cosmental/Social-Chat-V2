--[[

    Name: Mari
    Date: 12/21/2022

    Description: SmartText is an API-based utility module that is designed to be paired up with the RichString module! SmartText provides
    position and sizing-based TextLabel functuality by using responsive coding as a form of self-maintenance.

    v1.00

]]--

--// Module
local SmartText = {};
local SmartStringObject = {};
SmartStringObject.__index = SmartStringObject

--// Services
local TextService = game:GetService("TextService");

--// Container
local Camera = workspace.CurrentCamera

local SizeCheckUI = Instance.new("ScreenGui");
local API_LABEL : Instance? -- This label can be used for arbitrary API calls

--// Main Methods

function SmartText.new(Container : GuiObject, properties : table?) : SmartStringObject
    assert(typeof(Container) == "Instance", "The provided Container was not of type \"Instance\". Received \""..(typeof(Container)).."\"");
    assert(Container:IsA("GuiObject"), "Expected Instance of class \"GuiObject\". Got \""..(Container.ClassName).."\"");
    assert(type(properties) == "table", "Failed to read from \"properties\" parameter. Expected typeof \"table\", but received \""..(type(properties)).."\"!");

    local StringObject = setmetatable({

        --// Constants \\--

        ["Container"] = Container,

        --// Properties \\--

        ["MinFontSize"] = (properties and properties.MinFontSize) or 0,
        ["MaxFontSize"] = (properties and properties.MaxFontSize) or 100,

        ["BindSizeToContent"] = (properties and properties.BindSizeToContent) or false, -- if true, our container will receive automatic sizing updates

        --// Programmable \\--

        ["TotalTextGroups"] = 0,
        ["TextGroups"] = {}

    }, SmartStringObject);

    --// Automatic container resizing
    local OnSizingChanged : RBXScriptSignal

    if (StringObject.BindSizeToContent) then
        OnSizingChanged = (
            (StringObject.Parent:IsA("GuiBase2d") and StringObject.Parent:GetPropertyChangedSignal("AbsoluteSize"))
            or (Camera:GetPropertyChangedSignal("ViewportSize"))
        )
    else
        OnSizingChanged = Container:GetPropertyChangedSignal("AbsoluteSize");
    end

    OnSizingChanged:Connect(function()
        StringObject:Update();
    end);

    return StringObject
end

--- Returns the absolute Vector2 spacing required to fit the provided text string using the specified Font and FontSize
function SmartText:GetTextSize(text : string, fontSize : number, font : Enum.Font, absoluteSize : Vector2, byGrapheme : boolean?) : Vector2
    assert(type(text) == "string", "The provided text content was not of type \"string\". (received \""..(type(text)).."\" )");
    assert(type(fontSize) == "number", "The provided font size was not of type \"number\"! (received \""..(type(fontSize)).."\")");
    assert(typeof(font) == "EnumItem", "The provided font was not of type \"EnumItem\"! (received \""..(typeof(font)).."\")");
    assert(table.find(Enum.Font:GetEnumItems(), font), "The provided font EnumItem was not a valid Font EnumItem!");
    assert(typeof(absoluteSize) == "Vector2", "The provided AbsoluteSize was not a \"Vector2\" type! (received \""..(typeof(absoluteSize)).."\")");

    local SpaceSize = TextService:GetTextSize(text, fontSize, font, absoluteSize);

    if (byGrapheme) then
        local doesWordOverflow = false
        
        local GraphemeX = 0
        local GraphemeY = SpaceSize.Y

        for _, Grapheme in pairs(text:split("")) do
            local GraphemeSize = TextService:GetTextSize(
                Grapheme,
                fontSize,
                font,
                absoluteSize
            );

            GraphemeX += GraphemeSize.X

            if (GraphemeX >= absoluteSize.X) then
                GraphemeX = 0
                GraphemeY += SpaceSize.Y

                doesWordOverflow = true
            end
        end

        return Vector2.new(
            (((doesWordOverflow) and (absoluteSize.X)) or (GraphemeX)),
            GraphemeY
        ), doesWordOverflow
    else
        return TextService:GetTextSize(
            text,
            fontSize,
            font,
            absoluteSize
        );
    end
end

--- Returns the best fontsize for the requested GuiObject
function SmartText:GetBestFontSize(AbsoluteSize : Vector2, font : Enum.Font, minFontSize : number, maxFontSize : number)
    assert(typeof(AbsoluteSize) == "Vector2", "The provided AbsoluteSize was not of type \"Vector2\"! (received \""..(typeof(AbsoluteSize)).."\")");
    assert(typeof(font) == "EnumItem", "The provided font was not of type \"EnumItem\"! (received \""..(typeof(font)).."\")");
    assert(table.find(Enum.Font:GetEnumItems(), font), "The provided font EnumItem was not a valid Font EnumItem!");
    assert(type(maxFontSize) == "number", "The provided maximum font size was not a number! (FontSize can only be calculated with numbers.)");
    assert(type(minFontSize) == "number", "The provided minimum font size was not a number! (FontSize can only be calculated with numbers.)");
    assert(maxFontSize <= 100 and minFontSize >= 0, "The provided font sizes exceed legitimate font size ranges! (FontSize can only range from 0 - 100)");

    local BestFontSize : number = maxFontSize

    API_LABEL.Size = UDim2.fromOffset(AbsoluteSize.X, self.MaxFontSize);
    API_LABEL.Font = font

    for _ = 1, (maxFontSize - minFontSize) do
        API_LABEL.TextSize = BestFontSize

        local TextFitsX = (API_LABEL.TextFits == true);
        local TextFitsY = (API_LABEL.TextBounds.Y <= AbsoluteSize.Y);

        if (not TextFitsX or not TextFitsY) then
            BestFontSize -= 1
        else
            break;
        end
    end

    return BestFontSize
end

--// Metamethods

--- Adds a new TextGroup using the provided TextObjects that originate from the RichString module
function SmartStringObject:AddGroup(key : string, TextObjects : table, TextFont : Enum.Font)
    assert(type(key) == "string", "Expected \"string\" as an identifier key. Got \""..(type(key)).."\" instead!");
    assert(type(TextObjects) == "table", "Expected an array as a TextObject group. Got "..(type(TextObjects)).." instead!");
    assert(typeof(TextFont) == "EnumItem", "The provided Font Enum was not an EnumItem type! Got \""..(typeof(TextFont)).."\"");
    assert(table.find(Enum.Font:GetEnumItems(), TextFont), "The provided Font \""..(tostring(TextFont)).."\" was not a real Font EnumItem!");
    assert(not self.TextGroups[key], "The provided identifier key has already been used! ( \""..(key).."\" is unavaliable. ) ");

    local GroupTextContent : string = ""

    for i, WordGroup in pairs(TextObjects) do
        if (not WordGroup.Content) then continue; end
        GroupTextContent = (GroupTextContent..WordGroup.Content..((i ~= #TextObjects and " ") or ""));
    end

    self.TotalTextGroups += 1
    self.TextGroups[key] = {
        ["Metadata"] = {
            ["Font"] = TextFont,
            ["Content"] = GroupTextContent
        };

        ["WordGroups"] = TextObjects,
        ["Index"] = self.TotalTextGroups
    };

    self:Update();
end

--- Removes a TextGroup using it's string identifier key ( NOTE: This does NOT destroy the Text group itself )
function SmartStringObject:RemoveGroup(key : string)
    assert(type(key) == "string", "Expected \"string\" as an identifier key. Got \""..(type(key)).."\" instead!");
    assert(self.TextGroups[key], "The provided key \""..(key).."\" was not registered under this SmartStringObject!");

    self.TextGroups[key] = nil
end

--- Updates positioning and sizing of our TextObjects within our Container
function SmartStringObject:Update()

    --// TextGroup Organization
    --\\ We need to organize our TextGroups by their proper index orders!

    local OrderedGroups = {};

    for _, TextGroup in pairs(self.TextGroups) do
        table.insert(OrderedGroups, TextGroup);
    end

    table.sort(OrderedGroups, function(a, b)
        return a.Index < b.Index
    end);

    --// TextGroup Control
    --\\ We need to iterate between all of our TextGroup's in order to scale and position them based on their Font needs!
    
    local FillerYSpace : number?
    local MaxBounds = (
        (self.BindSizeToContent and ((self.Container.Parent and self.Container.Parent.AbsoluteSize) or (Camera.ViewportSize)))
        or self.Container.AbsoluteSize
    );

    local TotalSizeY = 0
    local TotalSizeX = 0

    for _, TextGroup in ipairs(OrderedGroups) do

        --// Calculate Best FontSize
        --\\ We can calculate our Best FontSize by using a "dummy" TextLabel that uses it's "TextFits" property to return feedback in terms of FontSize

        local GroupFontSize : number = SmartText:GetBestFontSize(
            MaxBounds,
            TextGroup.Metadata.Font,
            self.MinFontSize,
            self.MaxFontSize
        );

        TextGroup.Metadata.FontSize = GroupFontSize

        --// Line spacing initialization
        --\\ We need something to base our sentence lining calculations with

        local LineYSpacing = (SmartText:GetTextSize(
            " ",
            GroupFontSize,
            Enum.Font.SourceSans, -- SourceSans is our best benchmark font ^^
            self.Container.AbsoluteSize
        ).Y);

        if (TextGroup.Index == 1) then -- We only need to do this at the start of our calculations
            FillerYSpace = LineYSpacing
        end

        --// Word Group Calculations
        --\\ We need to calculate the best size and position for our Grapheme word groups!

        for _, WordGroup in pairs(TextGroup.WordGroups) do
            
            --// Content Sizing Check
            --\\ This is where we check to see if we need to create a newline or not!

            local ContentSize : number

            if (WordGroup.Content) then
                local WordSize = SmartText:GetTextSize(
                    WordGroup.Content,
                    GroupFontSize,
                    TextGroup.Metadata.Font,
                    self.Container.AbsoluteSize,
                    true
                );

                ContentSize = WordSize.X
            else
                ContentSize = GroupFontSize
            end

            if ((TotalSizeX + ContentSize) > MaxBounds.X) then
                TotalSizeY += LineYSpacing -- New Line indentation for cases where our WordGroup becomes too big
                TotalSizeX = 0
            end

            --// Individual Grapheme Sizing & Positioning
            --\\ Since our WordGroup's have different Font needs, we can scale things according to their desired inputs!

            for _, GraphemeObject in pairs(WordGroup.Graphemes) do
                if ((not GraphemeObject:IsA("TextLabel")) and (not GraphemeObject:IsA("TextButton")) and (not GraphemeObject:IsA("TextBox"))) then
                    GraphemeObject.Size = UDim2.fromOffset(GroupFontSize, GroupFontSize);
                    GraphemeObject.Position = UDim2.fromOffset(TotalSizeX, TotalSizeY);
                    TotalSizeX += GroupFontSize

                    continue;
                end

                local GraphemeSize = SmartText:GetTextSize(
                    GraphemeObject.Text:gsub("(\\?)<[^<>]->", ""), -- Gets rid of any richText formatting that may interfere with calculations
                    GroupFontSize,
                    GraphemeObject.Font,
                    self.Container.AbsoluteSize
                );
                
                GraphemeObject.Size = UDim2.fromOffset(GraphemeSize.X, GraphemeSize.Y);
                GraphemeObject.Position = UDim2.fromOffset(TotalSizeX, TotalSizeY);

                GraphemeObject.TextSize = GroupFontSize
                TotalSizeX += GraphemeSize.X
            end
        end
    end

    self.FullSize = UDim2.fromOffset(
        (TotalSizeY > 0 and MaxBounds.X) or TotalSizeX,
        TotalSizeY + FillerYSpace
    );

    if (self.BindSizeToContent) then
        self.Container.Size = self.FullSize
    end
    
end

--- Destroys all inherited Instances and terminates the OOP process
function SmartStringObject:Destroy(callback : Callback?)
    for _, TextGroup in pairs(self.TextGroups) do
        for _, WordGroup in pairs(TextGroup.WordGroups) do
            for _, Grapheme in pairs(WordGroup.Graphemes) do
                if (callback and (Grapheme:IsA("TextLabel") or Grapheme:IsA("TextButton"))) then
                    callback(Grapheme); -- Can be used as a standalone garbage collection function
                end
    
                Grapheme:Destroy();
            end
        end
    end

    self = nil
end

--// Functions

--- Creates a new programmatic sizing label that can be used to perform arbitrary methods
function NewSizeCheckLabel()
    local Label = Instance.new("TextLabel");

    Label.Text = "This is one standard sentence."
    Label.Name = "SIZE_CHECK_LABEL_DO_NOT_DELETE"

    Label.BackgroundTransparency = 1
    Label.TextStrokeTransparency = 1
    Label.TextTransparency = 1

    -- Label.Size = UDim2.new(1, 0, 0, StringObject.MaxFontSize);
    Label.Parent = SizeCheckUI -- NOTE: Parenting this object to our container can lead to UIListLayout issues that we dont want!
    return Label
end

--// Instance Setup

API_LABEL = NewSizeCheckLabel();
API_LABEL.Name = "API_LABEL"

SizeCheckUI.Enabled = false
SizeCheckUI.Name = "SMRTXT_VISUAL_UI"
SizeCheckUI.Parent = game.Players.LocalPlayer.PlayerGui

return SmartText