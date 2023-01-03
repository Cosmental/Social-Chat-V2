--[[

    Name: Mari
    Date: 12/9/2022

    Description: This module is an HTML-inspired text utility module that converts basic strings into formatted rich text using unique syntaxes
    similar to Discord! This currently supports bold, italics, underlining, and strikeouts!

    ===========================================================================================================================================

    [Update Log] - v1.2

    + Added support for non-standard utf8 characters!

]]--

--// Module
local Markdown = {};

--// Constants
local syntaxes = { -- These are valid syntaxes that we can use to determine markdown information! (the order of these matters)
    [1] = {
        ["syntax"] = "**",
        ["format"] = "<b>%s</b>",
        ["name"] = "bold"
    };

    [2] = {
        ["syntax"] = "~~",
        ["format"] = "<s>%s</s>",
        ["name"] = "strikeout"
    };

    [3] = {
        ["syntax"] = "__",
        ["format"] = "<u>%s</u>",
        ["name"] = "underlined"
    };

    [4] = {
        ["syntax"] = "*",
        ["format"] = "<i>%s</i>",
        ["name"] = "italic"
    };
};

--// Main Methods

--- Returns an array of markdown occurences found within the provided string!
function Markdown:GetMarkdownData(content : string, order : boolean?) : table
    local Result = {}; -- The occurence result array
    local Closed = {}; -- A list of closed character subpositions that are already in use!

    local utf8Codes = {};

    for starts, ends in utf8.graphemes(content) do
        table.insert(utf8Codes, {
            ["starts"] = starts,
            ["ends"] = ends
        });
    end

    for _, data in ipairs(syntaxes) do
        local syntax = data.syntax
        local occurences = {};

        --// Register occurences first
        --\\ This way we can see where all of our syntax occurences happen
        
        for i, utf8Group in ipairs(utf8Codes) do
            local ThisChar = GetUTF8Character(content, utf8Group);

            if (table.find(Closed, i)) then continue; end -- This character is within the CLOSED array and is not available for re-evaluation
            if (ThisChar ~= syntax:sub(1, 1)) then continue; end -- This character is not our syntax (SKIP)

            local PreviousChar = GetUTF8Character(content, utf8Codes[i - 1]);
            local isEscaped = (PreviousChar == "\\");
            if (isEscaped) then continue; end -- If our syntax is escaped by a backslash, we can just leave it alone

            --// Syntax Matching
            --\\ We need to make sure our syntax occurence matches our actual syntax character by character!

            if (#syntax >= 2) then -- This syntax requires more in-depth searching!
                local isStartOfSyntax = true

                for ii = 1, #syntax - 1 do -- Make sure our syntax and our search query is EXACTLY the same as our actual syntax!
                    if (GetUTF8Character(content, utf8Codes[i + ii]) ~= syntax:sub(1 + ii, 1 + ii)) then
                        isStartOfSyntax = false
                        break;
                    end
                end

                if (not isStartOfSyntax) then continue; end -- This is a false positive, skip this character
            end

            --// Occurence Matching
            --\\ Make sure our occurences meet our greedy search expectations!

            local PrecedingChar = GetUTF8Character(content, utf8Codes[i + #syntax]);

            local IsFollowedBySyntax = (PreviousChar == syntax:sub(1, 1));
            local IsPrecededBySyntax = (PrecedingChar == syntax:sub(1, 1));

            local IsInvalidMatch : boolean

            if (#syntax >= 2) then
                local LastOccurence = (occurences[#occurences]);
                local WasLastOccurencePreceded = (LastOccurence and GetUTF8Character(utf8Codes[LastOccurence + #syntax]) == syntax:sub(1, 1));

                IsInvalidMatch = (
                    (IsFollowedBySyntax and IsPrecededBySyntax) or
                    (WasLastOccurencePreceded and IsPrecededBySyntax)
                );
            else
                IsInvalidMatch = (IsFollowedBySyntax and IsPrecededBySyntax);
            end

            if (IsInvalidMatch) then continue; end -- Provides greedy logic that captures the inner-most case [ex: *(**this**)*]

            for ii = 1, #syntax do
                table.insert(Closed, i + ii - 1); -- We need to make sure this occurence sequence doesn't happen again for another syntax!
            end

            table.insert(occurences, utf8Group.starts);
        end

        --// Compile Results
        --\\ With our occurences now held accounted for, we can now take a look at the content between these occurences and their formatting!

        Result[syntax] = {
            ["results"] = {},
            ["format"] = data.format
        };

        for i, startsAt in pairs(occurences) do
            local nextOccurence = occurences[i + 1];
            if (not nextOccurence) then continue; end

            table.insert(Result[syntax]["results"], {
                ["starts"] = startsAt,
                ["ends"] = nextOccurence + #syntax - 1
            });

            occurences[i + 1] = nil
        end
    end

    --// Ordering our data (opt.)
    --\\ Sometimes, we will need to make operations that require our data to be in order from left to right

    if (order) then -- The API call requested our data in order from left to right!
        local Dump = {};

        for syntax, data in pairs(Result) do
            for _, scope in pairs(data.results) do
                table.insert(Dump, {
                    ["syntax"] = syntax,
                    ["format"] = data.format,
                    ["starts"] = scope.starts,
                    ["ends"] = scope.ends
                });
            end
        end

        table.sort(Dump, function(a, b)
            return a.starts < b.starts
        end);

        Result = Dump
    end

    return Result
end

--- Converts the provided content string into a new string using markdown langauge and syntaxing!
function Markdown:Markup(content : string, keepSyntaxes : boolean?) : string & table
    local OrderedMarkdown = GetOrderedMarkdown(Markdown:GetMarkdownData(content));
    local offset = 0

    for _, result in pairs(OrderedMarkdown) do
        local syntaxOffset = ((not keepSyntaxes and #result.syntax) or 0);

        if (result.atStart) then
            local after = content:sub(result.at + offset + syntaxOffset);
            
            content = content:sub(1, result.at + offset - 1)
                ..result.rich
                ..after
        else
            local before = content:sub(1, result.at + offset - syntaxOffset);

            content = before
                ..result.rich
                ..content:sub(result.at + offset + 1)
        end

        offset += (result.rich:len() - syntaxOffset); -- We need an offset to account for all the new characters we're adding into our string
    end
    
    return content, OrderedMarkdown
end

--// Function

--- Returns a list of markdown info that can be used to markdown our original string
function GetOrderedMarkdown(data : table)
    local OrderedMarkdown = {};

    --// Info Dumping
    --\\ We need to dump all of our markdown data into a singular table for in depth analysis!

    for syntax, info in pairs(data) do
        local FormatSplit = info.format:split("%s"); -- 1 = Start, 2 = End

        for _, occurence in pairs(info.results) do
            table.insert(OrderedMarkdown, {
                ["rich"] = FormatSplit[1],
                ["at"] = occurence.starts,
                ["syntax"] = syntax,
                ["atStart"] = true,
            });

            table.insert(OrderedMarkdown, {
                ["rich"] = FormatSplit[2],
                ["at"] = occurence.ends,
                ["syntax"] = syntax,
                ["atStart"] = false
            });
        end
    end

    --// Order Sorting
    --\\ We need to sort our info so that we can mark it down later!

    table.sort(OrderedMarkdown, function(a, b)
        return a.at < b.at
    end);

    return OrderedMarkdown
end

--// Function

--- Returns a singular utf8 character based on the provided data! (this is purely for readability)
function GetUTF8Character(content : string, fromUTF8Group : table) : string
    if (not fromUTF8Group) then return "" end
    return content:sub(fromUTF8Group.starts, fromUTF8Group.ends);
end

return Markdown