--[[

    Name: Mari
    Date: 12/10/2022

    Description: RichString is a complex module designed to turn normal strings into richText strings! This resource uses Markdown syntaxing
    similar to Discord in order to generate individual TextObjects. This module was only designed to support VISUAL applications and does
    not handle sizing or positioning because it is designed to be paired up with the SmartText utility module.

    v1.01

    ========================================================================================================================================

    TODO:

    [ ] - Fix bug with multi-layered richText. This causes the richtext to malformat when using ":GetMarkdownData" and thus, the markdown
    moves ahead of where it is actually meant to be! This is potentially due to the fact that the desired pure word is wrapped around two or
    more richText formats that confuse the current algorithm.

]]--

--// Module
local RichString = {};
local stringObject = {};
stringObject.__index = stringObject

--// Imports
local Markdown = require(script.Parent.Markdown);

--// Main Methods

--- Creates a new RichString object through OOP
function RichString.new(properties : table?) : stringObject
    return setmetatable({

        --// Properties \\--

        ["Font"] = (properties and properties.Font) or Enum.Font.SourceSans,

        --// Configurations \\--

        ["MarkdownEnabled"] = (properties and properties.MarkdownEnabled) or true, -- Will text automatically be MarkedDown? ( boolean )
        ["ResponsiveSizing"] = (properties and properties.ResponsiveSizing) or true, -- Will text automatically resize when the ancestor does? ( boolean )

        --// Programmable \\--
        
        ["_hyperFunctions"] = {}, -- { key = function }
        ["_replacements"] = {} -- { keyword = function OR string }

    }, stringObject);
end

--// Metamethods

--- Defines a function for programmic string functuality!
function stringObject:Define(key : string, callback : callback)
    assert(type(key) == "string", "A string type was not passed for the \"key\" parameter. Recieved \""..(type(key)).."\"");
    assert(type(callback) == "function", "A callback function type was not passed for the \"callback\" parameter. Recieved \""..(type(callback)).."\"");

    if (self._hyperFunctions[key]) then
        warn("A function with the name \""..(key).."\" has already exists!");
        return
    end

    self._hyperFunctions[key] = callback
end

function stringObject:Replace(keyWord : string, replacement : callback | string)
    assert(type(keyWord) == "string", "A string type was not passed for the \"key\" parameter. Recieved \""..(type(keyWord)).."\"");
    assert(not self._replacements[keyWord], "The provided KeyWord \""..(keyWord).."\" is already in use!");

    self._replacements[keyWord] = replacement
end

--- Creates a new set of TextLabels under the provided parent Instance using previously assigned property metadata. [ THIS WILL NOT FORMAT YOUR LABELS! You must use the SmartText module for further functuality! ]
function stringObject:Generate(Parent : GuiObject, Text : string, callback : callback?) : table
    assert(typeof(Parent) == "Instance", "Unable to use a type other than \"Instance\" for this method. Recieved \""..(typeof(Parent)).."\"");
    assert(Parent:IsA("GuiObject"), "The provided Parent instance was not of classtype \"GuiObject\". Got \""..(Parent.ClassName).."\"");
    assert((not callback) or (type(callback) == "function"), "The provided callback function was not of type \"function\". Recieved \""..(type(callback)).."\"");

    local PureText, MarkdownInfo : string | table? = Markdown:GetMarkdownData(Text);
    local Labels = {};
    
    for Index, Word in ipairs(PureText:split(" ")) do
        local hyperText : boolean, hyperKey : string, allowedIndexes : table = getHyperFormatting(Word);
        local hyperFunction : callback? = (hyperText and self._hyperFunctions[hyperKey]);

        local Formatting = getMarkdown(PureText, Index, MarkdownInfo, hyperText ~= nil);
        local Graphemes : table = {};

        if (hyperText and not hyperFunction) then
            warn([[Requested HyperFunction "]]..(hyperKey)..[[" is undefined. Please define your function using 
                                    RichString:Define("myCoolFunction", function(...)) before using the hyperFunction syntax
                                    for the function.
            ]]);
        end

        --// Replacements
        --\\ Here we can look for phrase replacements (if any)

        local PurifiedText = ((hyperText or Word):gsub("%s+", ""):gsub(" ", "")); -- We need to use gsub to remove whitespace & newline(s)
        local PhraseReplacement : string | callback = self._replacements[PurifiedText];

        if (type(PhraseReplacement) == "function") then
            local ReplacementObject = PhraseReplacement(); -- This function MUST return an instance!

            if ((not ReplacementObject) or (typeof(ReplacementObject) ~= "Instance") or (not ReplacementObject:IsA("GuiObject"))) then
                error("RichString replacement error. The replacement for \""..(PurifiedText).."\" did not return a GuiObject Instance!");
            end

            if (hyperFunction and (ReplacementObject:IsA("ImageButton") or ReplacementObject:IsA("TextButton"))) then
                ReplacementObject.MouseButton1Click:Connect(function()
                    hyperFunction(hyperText, hyperKey);
                end);
            end

            table.insert(Graphemes, ReplacementObject);
            ReplacementObject.Parent = Parent
        else
            for i, utf8Code in utf8.codes(PhraseReplacement or Word) do -- We need to use utf8 for special characters like Japanese symbols, etc.
                if ((hyperText) and ((i < allowedIndexes[1]) or (i > allowedIndexes[2]))) then continue; end
    
                local NewTextObject = CreateTextObject(
                    self.Font,
                    utf8.char(utf8Code),
                    (hyperText and "TextButton") or "TextLabel"
                );
                
                if (self.MarkdownEnabled) then -- We only need to markdown our string IF "MarkdownEnabled" is true
                    for _, format in ipairs(Formatting) do
                        NewTextObject.Text = string.format(format, NewTextObject.Text);
                    end
                    
                    NewTextObject.RichText = true
                end
    
                if (hyperFunction) then
                    NewTextObject.MouseButton1Click:Connect(function()
                        hyperFunction(hyperText, hyperKey);
                    end);
                end
                
                table.insert(Graphemes, NewTextObject);
                NewTextObject.Parent = Parent
    
                if (callback) then
                    callback(NewTextObject);
                end
            end
        end

        if (Index ~= #PureText:split(" ")) then -- No spacing is needed for our last word
            local SpaceLabel = CreateTextObject(self.Font, " ");
            SpaceLabel.Name = "RichString_WHITESPACE"
            table.insert(Graphemes, SpaceLabel); -- We still need to account for actual word spacings!
        end

        table.insert(Labels, {
            ["Graphemes"] = Graphemes,
            ["Content"] = (not PhraseReplacement and (hyperKey or Word)) or nil
        });
    end

    return Labels
end

--// Functions

--- Returns a markdown table based on whether a word from the provided string has markdown information available
function getMarkdown(text : string, wordIndex : number, fromData : table, isFromHyperText : boolean?) : table?
    local words = text:split(" ");
    local characterIndex : number = 0

    --// Index Searching
    --\\ We need to find where our word's EXACT index is in order for us to pinpoint if our word is marked or not

    if (wordIndex > 1) then -- If our word index is ONE, then we already know that our character index is ZERO
        for i, word in pairs(words) do
            if (i == wordIndex) then break; end
            characterIndex += (word:len() + 1);
        end
    
        characterIndex += 1
    end

    --// Markdown determination
    --\\ After finding our exact word index, we can determine if it requires any markdown formatting

    local format = {};

    for _, data in pairs(fromData) do
        local hasThisFormat = false
        local syntax = data.mdInfo.syntax

        for _, occurence in pairs(data.occurences) do
            local isWithinMarkdownSyntax = (
                (((isFromHyperText and characterIndex + 1 + #syntax) or (characterIndex)) >= occurence.starts - #syntax)
                and (((isFromHyperText and characterIndex - 1 - #syntax) or (characterIndex)) <= occurence.ends - #syntax)
            ); -- HyperText formatting requires a special index because it loses an additional set of index characters

            if (isWithinMarkdownSyntax) then -- This word is within a markdown finding!
                hasThisFormat = true
                break;
            end
        end

        if (hasThisFormat) then
            table.insert(format, data.mdInfo.format);
        end
    end

    return format
end

--- Creates a new TextLabel preset! This was made purely for readability purposes.
function CreateTextObject(Font, Grapheme, ObjectType : string?)
    local NewLabel = Instance.new(ObjectType or "TextLabel");

    NewLabel.TextStrokeTransparency = 0.8
    NewLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
    
    NewLabel.TextXAlignment = Enum.TextXAlignment.Left
    NewLabel.Font = Font
    
    NewLabel.Name = ("RichString_")..(Grapheme)
    NewLabel.BackgroundTransparency = 1
    NewLabel.Text = Grapheme

    return NewLabel
end

--- Detects if a string has "(this)[...]" formatting
function getHyperFormatting(phrase : string) : string & string & table
    local Parenthesis = phrase:find("%(.*%)");
    local Brackets = phrase:find("%[.*%]");

    local HasBothSyntaxes = (Parenthesis ~= nil and Brackets ~= nil);
    if (not HasBothSyntaxes) then return; end -- Both Syntaxes were NOT present. ( no need to continue )
    if (not phrase:sub(Brackets - 1, Brackets - 1) == ")") then return; end -- If our syntaxes are NOT linked then this is malformed ( CANCEL )

    local InnerParenthesis = phrase:sub(Parenthesis + 1, Brackets - 2); -- Inner Parenthesis text ( eg. "this" )
    local InnerBrackets = phrase:sub(Brackets + 1, phrase:find("%]") - 1); -- Callback function key

    return InnerParenthesis, InnerBrackets, {Parenthesis + 1, Brackets - 2};
end

return RichString