--[[

    Name: Mari
    Date: 12/9/2022

    Description: This module is an HTML-inspired text utility module that converts basic strings into formatted rich text using unique syntaxes
    similar to Discord!

    v1.00

]]--

--// Module
local Markdown = {};

--// Constants
local syntaxes = {
    [1] = {
        ["syntax"] = "**",
        ["format"] = "<b>%s</b>",
        ["name"] = "bold"
    };

    [2] = {
        ["syntax"] = "*",
        ["format"] = "<i>%s</i>",
        ["name"] = "italic"
    };

    [3] = {
        ["syntax"] = "__",
        ["format"] = "<u>%s</u>",
        ["name"] = "underlined"
    };

    [4] = {
        ["syntax"] = "~~",
        ["format"] = "<s>%s</s>",
        ["name"] = "strikeout"
    };

    -- [5] = {
    --     ["syntax"] = "||",
    --     ["format"] = function()
            
    --     end
    -- };
};

--// Main Methods

--- Converts the provided content string into a new string using Markdown language
function Markdown:Markup(content : string) : string
    local newString = content

    for _, data in ipairs(syntaxes) do
        -- warn("-----------------------------------------------");
        -- warn("--------------------["..(data.syntax).."]--------------------");
        -- warn("-----------------------------------------------");

        local split = string.split(newString, "");
        local syntax = data.syntax
        
        local occurences = {};
        local offset = 0

        --// Register occurences first
        --\\ This way we can see where all of our syntax occurences happen
        
        for i = 1, #split do
            if (split[i] ~= syntax:sub(1, 1)) then continue; end

            --// Syntax Start
            local isStartOfSyntax = true

            for ii = 1, #syntax - 1 do -- Make sure our syntax and our search query is EXACTLY the same as our actual syntax!
                if (split[i + ii] ~= syntax:sub(1 + ii, 1 + ii)) then
                    isStartOfSyntax = false
                    break;
                end
            end

            if (not isStartOfSyntax) then continue; end -- This is a false positive, skip this character

            local isEscaped = (split[i - 1] == "\\");
            if (isEscaped) then continue; end -- If our syntax is escaped by a backslash, we can just leave it alone

            local lastOccurence = occurences[#occurences];
            local wasLastOccurenceFollowed = (lastOccurence and split[lastOccurence - 1] == syntax:sub(1, 1));

            if ((split[i + #syntax] == syntax:sub(1, 1)) and (not wasLastOccurenceFollowed)) then continue; end -- Greedy search method. [ EXCEPTION MADE FOR ENDINGS ]

            table.insert(occurences, i);
        end

        --// Compile Results
        --\\ With our occurences now held accounted for, we can now take a look at the content between these occurences and their formatting!

        for i, startsAt in pairs(occurences) do
            local nextOccurence = occurences[i + 1];
            if (not nextOccurence) then continue; end

            local innerContent = newString:sub(startsAt + offset + #syntax, nextOccurence + offset - 1);
            if (string.gsub(innerContent, " ", "") == "") then continue; end -- If our innerContent is just whitespace, we can blatantly ignore it

            -- warn("-----------------------------------------------");
            -- print("\t\t\t\t\tCONTENT:", innerContent);
            -- print("\t\t\t\t\tSUB:", startsAt + offset - 1, nextOccurence + offset + #syntax);
            -- print("\t\t\t\t\tOFFSET:", offset);

            newString = ( -- Update our string using our new data ^o^
                newString:sub(1, startsAt + offset - 1)
                ..(string.format(
                    data.format,
                    innerContent
                ))
                ..newString:sub(nextOccurence + offset + #syntax)
            );

            occurences[i + 1] = nil
            offset += (#data.format - 2) - (#syntax * 2); -- We need an offset to account for all the new characters we're adding into our string
        end
    end
    
    return newString
end

--- Returns a table of Markdown information and a purified string for programmatic functuality
function Markdown:GetMarkdownData(content : string) : string & table
    local result = {};

    for _, data in ipairs(syntaxes) do
        local split = string.split(content, "");
        local syntax = data.syntax

        result[data.name] = {}; -- We dont just want to dump all of our findings together!
        result[data.name]["occurences"] = {};

        --// Occurence Searching
        --\\ We need to first find where our markdown syntaxes are within our string

        local occurences = {};
        
        for i = 1, #split do
            if (split[i] ~= syntax:sub(1, 1)) then continue; end

            --// Syntax Start
            local isStartOfSyntax = true

            for ii = 1, #syntax - 1 do -- Make sure our syntax and our search query is EXACTLY the same as our actual syntax!
                if (split[i + ii] ~= syntax:sub(1 + ii, 1 + ii)) then
                    isStartOfSyntax = false
                    break;
                end
            end

            if (not isStartOfSyntax) then continue; end -- This is a false positive, skip this character

            local isEscaped = (split[i - 1] == "\\");
            if (isEscaped) then continue; end -- If our syntax is escaped by a backslash, we can just leave it alone

            local lastOccurence = occurences[#occurences];
            local wasLastOccurenceFollowed = (lastOccurence and split[lastOccurence - 1] == syntax:sub(1, 1));

            if ((split[i + #syntax] == syntax:sub(1, 1)) and (not wasLastOccurenceFollowed)) then continue; end -- Greedy search method. [ EXCEPTION MADE FOR ENDINGS ]
            table.insert(occurences, i);
        end

        --// Purification & Data Collection
        --\\ Here we purify our string while collecting our requested string data!

        local offset = 0 -- We need an offset to make up for the loss of characters within our upcomming iteration loop

        for i, startsAt in pairs(occurences) do
            local nextOccurence = occurences[i + 1];
            if (not nextOccurence) then continue; end

            local innerContent = content:sub(startsAt + #syntax - offset, nextOccurence - offset - 1);
            if (string.gsub(innerContent, " ", "") == "") then continue; end

            table.insert(result[data.name]["occurences"], {
                ["starts"] = startsAt + #syntax,
                ["ends"] = nextOccurence - 1
            });

            content = (
                content:sub(1, startsAt - (offset + 1)) -- Removes initial syntax ( eg. [**]bold** )
                ..(innerContent) -- Replaces syntaxes with purified inner content ( eg. **bold** --> bold )
                ..content:sub(nextOccurence - offset + #syntax) -- Removes ending syntax ( eg. bold[**] )
            );

            occurences[i + 1] = nil
            offset += (#syntax * 2); -- Since we're removing 2 sets of our syntax, we should account for this numerically
        end

        if (not next(result[data.name].occurences)) then
            result[data.name] = nil
            continue;
        end

        result[data.name]["mdInfo"] = data
    end
    
    return content, result
end

return Markdown