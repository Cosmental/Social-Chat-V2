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
local richFormatting = {
    [1] = {
        ["syntax"] = "**",
        ["format"] = "<b>%s</b>"
    };

    [2] = {
        ["syntax"] = "*",
        ["format"] = "<i>%s</i>"
    };

    [3] = {
        ["syntax"] = "__",
        ["format"] = "<u>%s</u>"
    };

    [4] = {
        ["syntax"] = "~~",
        ["format"] = "<s>%s</s>"
    };

    -- [5] = {
    --     ["syntax"] = "||",
    --     ["format"] = function()
            
    --     end
    -- };
};

--// Main Methods

--- Creates a set of strings while marking them up
function Markdown:Markup(content : string) : string & table
    local newString = content

    for _, data in ipairs(richFormatting) do
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

            if (not isStartOfSyntax) then continue; end

            local isEscaped = (split[i - 1] == "\\");
            if (isEscaped) then continue; end

            local lastOccurence = occurences[#occurences];
            local wasLastOccurenceFollowed = (lastOccurence and split[lastOccurence - 1] == syntax:sub(1, 1));

            if ((split[i + #syntax] == syntax:sub(1, 1)) and (not wasLastOccurenceFollowed)) then continue; end

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

            newString = (
                newString:sub(1, startsAt + offset - 1)
                ..(string.format(
                    data.format,
                    innerContent
                ))
                ..newString:sub(nextOccurence + offset + #syntax)
            );

            occurences[i + 1] = nil
            offset += ((#data.format - 2) - (#syntax * 2));
        end
    end

    return newString
end

return Markdown