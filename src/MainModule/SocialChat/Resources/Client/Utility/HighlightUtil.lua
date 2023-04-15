--[[

    Name: Mari
    Date: 12/22/2022
    
    Description: Handles individual text highlighting based on configurations

]]--

--// Module
local HighlightAPI = {};
HighlightAPI.__index = HighlightAPI

local Highlighter = {};
Highlighter.__index = Highlighter

--// Constants
local HighlightFormat = "<font color=\"rgb(%s, %s, %s)\">%s</font>"

--// Methods

--- Creates a new highlighter
function HighlightAPI.new(Color : Color3, Phrases : table, StartingCaseMode : boolean?) : Highlighter
    return setmetatable({
       ["Color"] = Color, -- Color3
       ["Phrases"] = Phrases, -- table < string >
       
       ["PhraseHandlers"] = {}, -- table < Function >
       ["OnlyAtStart"] = StartingCaseMode, -- TRUE :: Phrase must be at start of string || FALSE :: any find
    }, Highlighter);
end

--// Metamethods

--- Adds a custom highlighter handler function that can be used to handle special conditions. [Fires before highlighter finishes]
function Highlighter:SetHandler(Callback : callback)
    assert(type(Callback) == "function", "The provided highlighter handler callback was not a function! (received '"..(type(Callback)).."')");
    table.insert(self.PhraseHandlers, Callback);
end

--- Returns a RichText embedded string based on the Highlighter's current highlighting protocols!
function Highlighter:Highlight(Content : string) : string
    assert(type(Content) == "string", "Expected type \"string\" as a highlight content parameter. Received \""..(type(Content)).."\"");

    local Words = Content:split(" ");

    local NewContent : string = Content
    local Offset = 0

    for i, Word in ipairs(Words) do
        local CanHighlight, GColor : (boolean & Color3)?

        for _, Callback : Function in pairs(self.PhraseHandlers) do
            CanHighlight, GColor = Callback(Word);
            if (CanHighlight) then break; end -- A function already returned true! [STOP]
        end

        if ((self.OnlyAtStart and i ~= 1) and (not CanHighlight)) then continue; end -- Highlights for this group only work with the FIRST word!

        for _, Phrase in pairs(self.Phrases) do
            local PhraseCuts = Phrase:split(" ");

            if (#PhraseCuts > 1) then -- This phrase is made up of more than one word!
                local IsFaultyMatch : boolean? -- Determines if this multi-word phrase DOES NOT match our current word index
                local TotalMatches = 0 -- Ensures that ALL phrase words were found

                for Index = 1, #PhraseCuts do -- Match phrase by each split case [eg: "/e dance" => "/e" == this && "dance" == that]
                    local Section = PhraseCuts[Index];
                    local ThisCut = Words[i + (Index - 1)];

                    if (not ThisCut) then continue; end -- The current content string ran out of words to use! (end of string case)

                    if (Section:lower() ~= ThisCut:lower()) then
                        IsFaultyMatch = true
                        break;
                    end

                    TotalMatches += 1
                end

                if ((IsFaultyMatch) or (TotalMatches ~= #PhraseCuts)) then continue; end -- Phrase does not match word (move onto next condition)

                --// Insert Coloring
                for Index = 1, #PhraseCuts do
                    local RealIndex = (i + (Index - 1));
                    local WordIndex = GetWordIndex(Content, RealIndex);

                    local ColoredText, Appendence = InsertColorPhrase(NewContent, Words[RealIndex], WordIndex, self.Color, Offset);

                    NewContent = ColoredText
                    Offset += Appendence
                end

                break;
            elseif ((Phrase == Word) or (CanHighlight)) then -- This phrase is one word
                local WordIndex = GetWordIndex(Content, i);
                local ColoredText, Appendence = InsertColorPhrase(NewContent, Word, WordIndex, GColor or self.Color, Offset);

                NewContent = ColoredText
                Offset += Appendence

                break;
            end
        end
    end

    return NewContent
end

--// Functions

--- Returns the precise substring index number where the requested word index resides
function GetWordIndex(Content : string, WordIndex : number)
    local Index = 1

    for i, Word in pairs(Content:split(" ")) do
        if (i == WordIndex) then
            return Index
        end

        Index += (#Word + 1);
    end
end

--- Inserts richText formatting
function InsertColorPhrase(text : string, phrase : string, atIndex : number, Color : Color3, Offset : number) : number
    local R, G, B = math.floor(Color.R * 255), math.floor(Color.G * 255), math.floor(Color.B * 255);
    local NewText = (
        text:sub(0, math.max(0, atIndex + Offset - 1))
        ..string.format(
            HighlightFormat,
            R,
            G,
            B,
            phrase
        )
        ..text:sub(atIndex + Offset + #phrase + ((atIndex == 0 and 1) or 0))
    );

    return NewText, (#HighlightFormat - 2 + (#tostring(R..G..B) - 6));
end

return HighlightAPI