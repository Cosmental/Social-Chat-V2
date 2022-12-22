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

--// Main Methods

function SmartText.new(Container : GuiObject, properties : table?) : SmartStringObject
    assert(typeof(Container) == "Instance", "The provided Container was not of type \"Instance\". Recieved \""..(typeof(Container)).."\"");
    assert(Container:IsA("GuiObject"), "Expected Instance of class \"GuiObject\". Got \""..(Container.ClassName).."\"");
    assert(type(properties) == "table", "Failed to read from \"properties\" parameter. Expected typeof \"table\", but recieved \""..(type(properties)).."\"!");

    local SIZE_CHECK_LABEL = Instance.new("TextLabel"); -- We need this for our maxFontSize method
    local StringObject = setmetatable({

        --// Constants \\--

        ["Container"] = Container,
        ["__sizeObj"] = SIZE_CHECK_LABEL,

        --// Properties \\--

        ["MinFontSize"] = (properties and properties.MinFontSize) or 0,
        ["MaxFontSize"] = (properties and properties.MaxFontSize) or 16,

        --// Programmable \\--

        ["_registeredTextGroups"] = {}

    }, SmartStringObject);

    SIZE_CHECK_LABEL.Size = UDim2.new(1, 0, 0, StringObject.MaxFontSize);
    SIZE_CHECK_LABEL.Text = "This is one standard sentence."
    SIZE_CHECK_LABEL.Name = "SIZE_CHECK_LABEL_DO_NOT_DELETE"

    SIZE_CHECK_LABEL.BackgroundTransparency = 1
    SIZE_CHECK_LABEL.TextStrokeTransparency = 1
    SIZE_CHECK_LABEL.TextTransparency = 1
    SIZE_CHECK_LABEL.Parent = Container

    --// Automatic container resizing
    Container:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        StringObject:Update();
    end);

    return StringObject
end

--// Metamethods

--- Adds a new TextGroup using the provided TextObjects that originate from the RichString module
function SmartStringObject:AddGroup(key : string, TextObjects : table, TextFont : Enum.Font)
    assert(type(key) == "string", "Expected \"string\" as an identifier key. Got \""..(type(key)).."\" instead!");
    assert(type(TextObjects) == "table", "Expected an array as a TextObject group. Got "..(type(TextObjects)).." instead!");
    assert(typeof(TextFont) == "EnumItem", "The provided Font Enum was not an EnumItem type! Got \""..(typeof(TextFont)).."\"");
    assert(table.find(Enum.Font:GetEnumItems(), TextFont), "The provided Font \""..(tostring(TextFont)).."\" was not a real Font EnumItem!");
    assert(not self._registeredTextGroups[key], "The provided identifier key has already been used! ( \""..(key).."\" is unavaliable. ) ");

    local GroupTextContent : string = ""

    for i, WordGroup in pairs(TextObjects) do
        if (not WordGroup.Content) then continue; end
        GroupTextContent = (GroupTextContent..WordGroup.Content..((i ~= #TextObjects and " ") or ""));
    end

    self._registeredTextGroups[key] = {
        ["Metadata"] = {
            ["Font"] = TextFont,
            ["Content"] = GroupTextContent
        };

        ["WordGroups"] = TextObjects
    };

    self:Update();
end

--- Removes a TextGroup using it's string identifier key ( NOTE: This does NOT destroy the Text group itself )
function SmartStringObject:RemoveGroup(key : string)
    assert(type(key) == "string", "Expected \"string\" as an identifier key. Got \""..(type(key)).."\" instead!");
    assert(self._registeredTextGroups[key], "The provided key \""..(key).."\" was not registered under this SmartStringObject!");

    self._registeredTextGroups[key] = nil
end

--- Updates positioning and sizing of our TextObjects within our Container
function SmartStringObject:Update()

    --// TextGroup Control
    --\\ We need to iterate between all of our TextGroup's in order to scale and position them based on their Font needs!
    
    local MaxBounds = self.Container.AbsoluteSize

    local TotalSizeY = 0
    local TotalSizeX = 0

    for i, TextGroup in pairs(self._registeredTextGroups) do

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

        --// Line spacing initialization
        --\\ We need something to base our sentence lining calculations with

        local LineYSpacing = (GetTextSize(
            " ",
            self.Container,
            GroupFontSize,
            Enum.Font.SourceSans
        ).Y); -- SourceSans is our best benchmark font ^^

        if (i == 1) then -- We only need to do this at the start of our calculations
            TotalSizeY += LineYSpacing
        end

        --// Word Group Calculations
        --\\ We need to calculate the best size and position for our Grapheme word groups!

        for _, WordGroup in pairs(TextGroup.WordGroups) do
            
            --// Content Sizing Check
            --\\ This is where we check to see if we need to create a newline or not!

            local ContentSize : number

            if (WordGroup.Content) then
                local WordSize = GetTextSize(WordGroup.Content, self.Container, GroupFontSize, TextGroup.Metadata.Font, true);
                ContentSize = WordSize.X
            else
                ContentSize = GroupFontSize
            end

            if (TotalSizeX + ContentSize >= MaxBounds.X) then
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

                local GraphemeSize = GetTextSize(
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
        TotalSizeY
    );
    
end

--- Destroys all inherited Instances and terminates the OOP process
function SmartStringObject:Destroy(callback : Callback?)
    for _, TextGroup in pairs(self._registeredTextGroups) do
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

--- Returns the Vector2 TextSize of the requested string via it's sub-parameters
function GetTextSize(text : string, container : GuiObject, FontSize : number, Font : Enum.Font, byGrapheme : boolean?)
    local Abs = container.AbsoluteSize
    local SpaceSize = TextService:GetTextSize(text, FontSize, Font, Abs);

    if (byGrapheme) then
        local doesWordOverflow = false
        
        local GraphemeX = 0
        local GraphemeY = SpaceSize.Y

        for _, Grapheme in pairs(text:split("")) do
            local GraphemeSize = TextService:GetTextSize(
                Grapheme,
                FontSize,
                Font,
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
            FontSize,
            Font,
            Abs
        );
    end
end

return SmartText