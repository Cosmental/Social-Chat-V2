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
local SizeCheckUI = Instance.new("ScreenGui");

SizeCheckUI.Enabled = false
SizeCheckUI.Name = "SMRTXT_VISUAL_UI"
SizeCheckUI.Parent = game.Players.LocalPlayer.PlayerGui

local Camera = workspace.CurrentCamera

--// Main Methods

function SmartText.new(Container : GuiObject, properties : table?) : SmartStringObject
    assert(typeof(Container) == "Instance", "The provided Container was not of type \"Instance\". Received \""..(typeof(Container)).."\"");
    assert(Container:IsA("GuiObject"), "Expected Instance of class \"GuiObject\". Got \""..(Container.ClassName).."\"");
    assert(type(properties) == "table", "Failed to read from \"properties\" parameter. Expected typeof \"table\", but received \""..(type(properties)).."\"!");

    local SIZE_CHECK_LABEL = Instance.new("TextLabel"); -- We need this for our maxFontSize method
    local StringObject = setmetatable({

        --// Constants \\--

        ["Container"] = Container,
        ["__sizeObj"] = SIZE_CHECK_LABEL,

        --// Properties \\--

        ["MinFontSize"] = (properties and properties.MinFontSize) or 0,
        ["MaxFontSize"] = (properties and properties.MaxFontSize) or 100,

        ["BindSizeToContent"] = (properties and properties.BindSizeToContent) or false, -- if true, our container will receive automatic sizing updates

        --// Programmable \\--

        ["TotalTextGroups"] = 0,
        ["TextGroups"] = {}

    }, SmartStringObject);

    SIZE_CHECK_LABEL.Parent = SizeCheckUI -- NOTE: Parenting this object to our container can lead to UIListLayout issues that we dont want!
    -- SIZE_CHECK_LABEL.Size = UDim2.new(1, 0, 0, StringObject.MaxFontSize);

    SIZE_CHECK_LABEL.Text = "This is one standard sentence."
    SIZE_CHECK_LABEL.Name = "SIZE_CHECK_LABEL_DO_NOT_DELETE"

    SIZE_CHECK_LABEL.BackgroundTransparency = 1
    SIZE_CHECK_LABEL.TextStrokeTransparency = 1
    SIZE_CHECK_LABEL.TextTransparency = 1

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
function SmartText:GetTextSize(text : string, container : GuiObject, fontSize : number, font : Enum.Font, byGrapheme : boolean?) : Vector2
    local Abs = container.AbsoluteSize
    local SpaceSize = TextService:GetTextSize(text, fontSize, font, Abs);

    if (byGrapheme) then
        local doesWordOverflow = false
        
        local GraphemeX = 0
        local GraphemeY = SpaceSize.Y

        for _, Grapheme in pairs(text:split("")) do
            local GraphemeSize = TextService:GetTextSize(
                Grapheme,
                fontSize,
                font,
                Abs
            );

            GraphemeX += GraphemeSize.X

            if (GraphemeX >= Abs.X) then
                GraphemeX = 0
                GraphemeY += SpaceSize.Y

                doesWordOverflow = true
            end
        end

        return Vector2.new(
            (((doesWordOverflow) and (Abs.X)) or (GraphemeX)),
            GraphemeY
        ), doesWordOverflow
    else
        return TextService:GetTextSize(
            text,
            fontSize,
            font,
            Abs
        );
    end
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

    self.__sizeObj.Size = UDim2.fromOffset(MaxBounds.X, self.MaxFontSize);

    for _, TextGroup in ipairs(OrderedGroups) do

        --// Calculate Best FontSize
        --\\ We can calculate our Best FontSize by using a "dummy" TextLabel that uses it's "TextFits" property to return feedback in terms of FontSize

        local GroupFontSize : number = self.MaxFontSize
        self.__sizeObj.Font = TextGroup.Metadata.Font

        for _ = 1, (self.MaxFontSize - self.MinFontSize) do
            self.__sizeObj.TextSize = GroupFontSize
            local isBestSize = (self.__sizeObj.TextFits == true);

            if (not isBestSize) then
                GroupFontSize -= 1
            else
                break;
            end
        end

        TextGroup.Metadata.FontSize = GroupFontSize

        --// Line spacing initialization
        --\\ We need something to base our sentence lining calculations with

        local LineYSpacing = (SmartText:GetTextSize(
            " ",
            self.Container,
            GroupFontSize,
            Enum.Font.SourceSans -- SourceSans is our best benchmark font ^^
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
                local WordSize = SmartText:GetTextSize(WordGroup.Content, self.Container, GroupFontSize, TextGroup.Metadata.Font, true);
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
                    self.Container,
                    GroupFontSize,
                    GraphemeObject.Font
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

    self.__sizeObj:Destroy();
    self = nil
end

return SmartText