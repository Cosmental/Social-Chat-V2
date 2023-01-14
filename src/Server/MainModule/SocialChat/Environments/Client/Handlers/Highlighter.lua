--[[

    Name: Mari
    Date: 12/22/2022
    
    Description: Handles individual text highlighting based on configurations

]]--

--// Imports
local ConfigurationFolder = game.ReplicatedFirst.ClientChatSettings
local Settings = require(ConfigurationFolder.LocalHighlights);

--// Constants
local HighlightFormat = "<font color=\"rgb(%s, %s, %s)\">%s</font>"

--// Functions

--- Returns the precise substring index number where the requested word index resides
local function getWordIndex(Content : string, WordIndex : number)
    local Index = 1

    for i, Word in pairs(Content:split(" ")) do
        if (i == WordIndex) then
            return Index
        end

        Index += (#Word + 1);
    end
end

--- Returns a boolean value based on whether or the queried player is in this server
local function doesPlayerExist(query : string) : boolean
    for _, Player in pairs(game.Players:GetPlayers()) do
        if (Player.Name:lower() == query:lower()) then
            return true;
        end
    end
end

--- Inserts richText formatting
local function InsertColorPhrase(text : string, phrase : string, atIndex : number, Color : Color3, Offset : number) : number
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

--// Module
return function (content : string) : string
    assert(type(content) == "string", "Expected type \"string\" as a highlight content parameter. Received \""..(type(content)).."\"");

    local Words = content:split(" ");

    local NewContent : string = content
    local Offset = 0

    for i, Word in ipairs(Words) do
        
        --// Username Highlighting \\--

        if (Settings.UsernameHighlightsEnabled and doesPlayerExist(Word)) then
            local Index = getWordIndex(content, i);
            local UsernameColor = Settings.UserHighlightColor

            local NewText, Appendence = InsertColorPhrase(NewContent, Word, Index, UsernameColor, Offset);

            NewContent = NewText
            Offset += Appendence;
        end

        --// System Keyword Highlights \\--

        if ((Settings.SystemKeywordHighlightsEnabled) and (i == 1)) then
            for _, SystemPhrase in pairs(Settings.KeyPhrases._SYSTEM.phrases) do
                local PhraseSplit = SystemPhrase:split(" ");

                if (
                    (not ((#PhraseSplit == 2) and (#Words >= 2) and ((Word.." "..Words[2]) == SystemPhrase))) -- For cases with 2 words or more
                    and (not ((#PhraseSplit == 1) and (Word == SystemPhrase))) -- For singular cases
                ) then continue; end

                local NewText, Appendence = InsertColorPhrase(NewContent, SystemPhrase, 0, Settings.KeyPhrases._SYSTEM.color, Offset);

                NewContent = NewText
                Offset += Appendence

                break;
            end
        end

        --// Custom Highlights \\--

        if (Settings.CustomHighlightsEnabled) then
            local Index = getWordIndex(content, i);

            for PhraseGroup, Info in pairs(Settings.KeyPhrases) do
                if (PhraseGroup == "_SYSTEM") then continue; end -- This is a CORE class. We can ignore it if anything
                if (Info.isStartPhrase and i ~= 1) then continue; end -- Highlights for this group only work with the FIRST word!

                for _, CustomPhrase in pairs(Info.phrases) do
                    if (Word ~= CustomPhrase) then continue; end
    
                    local NewText, Appendence = InsertColorPhrase(NewContent, Word, Index, Info.color, Offset);

                    NewContent = NewText
                    Offset += Appendence

                    break;
                end
            end
        end

    end

    return NewContent
end