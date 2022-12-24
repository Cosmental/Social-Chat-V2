--[[

    Name: Mari
    Date: 12/22/2022
    
    Description: Handles individual text highlighting based on configurations

]]--

--// Imports
local SocialChat = require(script.Parent.Parent):Get();
local Settings = SocialChat.Settings.ClientHighlights

--// Functions

--- Returns the precise substring index number where the requested word index resides
local function getWordIndex(text : string, wordIndex : number)
    local words = text:split(" ");
    local characterIndex : number = 0

    if (wordIndex > 1) then
        for i, word in pairs(words) do
            if (i == wordIndex) then break; end
            characterIndex += (word:len() + 1);
        end
    
        characterIndex += 1
    end

    return characterIndex
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
local function InsertColorPhrase(text : string, phrase : string, atIndex : number, Color : Color3)
    return (
        text:sub(0, math.max(0, atIndex - 1))
        ..string.format(
            "<font color=\"rgb(%s, %s, %s)\">%s</font>",
            math.floor(Color.R * 255),
            math.floor(Color.G * 255),
            math.floor(Color.B * 255),
            phrase
        )
        ..text:sub(atIndex + #phrase + ((atIndex == 0 and 1) or 0))
    );
end

--// Module
return function (content : string) : string
    assert(type(content) == "string", "Expected type \"string\" as a highlight content parameter. Received \""..(type(content)).."\"");

    local Words = content:split(" ");

    for i, Word in pairs(Words) do
        
        --// Username Highlighting \\--

        if (Settings.UsernameHighlightsEnabled and doesPlayerExist(Word)) then
            local Index = getWordIndex(content, i);
            local UsernameColor = Settings.UserHighlightColor

            content = InsertColorPhrase(content, Word, Index, UsernameColor);
        end

        --// System Keyword Highlights \\--

        if ((Settings.SystemKeywordHighlightsEnabled) and (i == 1)) then
            for _, SystemPhrase in pairs(Settings.KeyPhrases._SYSTEM.phrases) do
                local PhraseSplit = SystemPhrase:split(" ");

                if (
                    (not ((#PhraseSplit == 2) and (#Words >= 2) and ((Word.." "..Words[2]) == SystemPhrase))) -- For cases with 2 words or more
                    and (not ((#PhraseSplit == 1) and (Word == SystemPhrase))) -- For singular cases
                ) then continue; end

                content = InsertColorPhrase(content, SystemPhrase, 0, Settings.KeyPhrases._SYSTEM.color);
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
    
                    content = InsertColorPhrase(content, Word, Index, Info.color);
                    break;
                end
            end
        end

    end

    return content
end