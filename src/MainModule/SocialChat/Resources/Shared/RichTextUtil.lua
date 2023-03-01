--[[

    Name: Mari
    Date: 12/29/2022

    Description: This utility module is designed to make work with RichText easier! :D

]]--

--// Module
local RichTextUtil = {};

--// Constants
local RichKeywords = {"font", "b", "u", "i", "s", "br", "uc", "uppercase", "smallcaps", "sc"};

--- Returns a table containing all valid richtext occurences in the provided text string
function RichTextUtil:GetOccurences(Text : string) : table?
    local RichTextOccurences = {};
	local OccurenceSkipIndex = 0
	
    --// Occurence Finding
    --\\ We need to collect data about our string for further calculations! This gmatch iteration looks for any potential richtext in our string

	for queryMatch in Text:gmatch("<.->") do
		local MatchStart, MatchEnd = Text:find("<.->", OccurenceSkipIndex);
		local InnerMatches = queryMatch:split("<");
		
		OccurenceSkipIndex += (MatchEnd - OccurenceSkipIndex + 1);
		local wordIndex = 0
		
		if (next(InnerMatches)) then -- No inner matches? Then, we can skip this part!
			local canMatchContext : boolean?
			
			for _, deepFind in pairs(InnerMatches) do -- We need to dive deeper into our string to make sure it really is richtext formatting!
				if (deepFind:sub(#deepFind, #deepFind) ~= ">") then wordIndex += (deepFind:len() + 1); continue; end
				
				canMatchContext = true -- Our formatting was real!
				queryMatch = "<"..deepFind
			end
			
			if (not canMatchContext) then continue; end -- This occurence was not valid! We can just skip it and move on
		end
		
		table.insert(RichTextOccurences, {
			["match"] = queryMatch,
			["starts"] = MatchStart + wordIndex - 1,
			["ends"] = MatchEnd
		});
	end

    if (#RichTextOccurences <= 1) then return; end -- This string does not have enough valid information to be evaluated!
	
    --// RichText Searching
    --\\ This part of our algorithm will individually search for WORKING richtext in our string through our occurence data!

	local SkipNextOccurence : boolean
	local Results = {};
	
	for i = 1, #RichTextOccurences do
		if (SkipNextOccurence) then SkipNextOccurence = false continue; end
		
		local ThisOccurence = RichTextOccurences[i];
		local NextOccurence = RichTextOccurences[i + 1];
		
		if (not NextOccurence) then break; end -- The next occurence does not exist! We can end our iteration here
		
		local ThisContent = ThisOccurence.match
		local NextContent = NextOccurence.match
		
		local ThisKeyword = ThisContent:split(" ")[1]:sub(2, #ThisContent - 1);
		local NextKeyword = NextContent:split(" ")[1]:sub(3, #NextContent - 1);
		
		local StartsWithSlash = (NextContent:sub(2, 2) == "/"); -- Does our RichText format have "</...>"?
		local UsesRichKeyword = (ThisKeyword == NextKeyword); -- Do our RichText occurences have the same keyword? ( eg. "b == b" )
        local isKeywordValid = table.find(RichKeywords, ThisKeyword); -- Determines if this is a valid RichText keyword or not!
		
		if (StartsWithSlash and UsesRichKeyword and isKeywordValid) then
			SkipNextOccurence = true -- Since we found an actual occurence, we can skip the next iteration because it's a part of this match!
			
			table.insert(Results, {
				["starts"] = ThisOccurence.starts, -- sub <number>
				["ends"] = NextOccurence.ends, -- sub <number>
                
                ["format"] = {
                    ["starts"] = ThisContent, -- ex: "<b>"
                    ["ends"] = NextContent, -- ex: "</b>"
					["keyword"] = ThisKeyword
                }
			});
		end
	end

    return Results
end

--- Algorithmically removes any FUNCTIONAL richtext from the provided text!
function RichTextUtil:WipeRichText(Text : string, KeepInnerContent : boolean?)
	local Results = RichTextUtil:GetOccurences(Text);
    if (not Results) then return Text; end -- There was not enough data to retrieve results from!
	
    --// Formatting
    --\\ After collecting our occurence data, we can start removing our richText!

	local Appendence = 0 -- We need to append our formatting index because we're actively removing string characters during our iteration!
	
	for _, occurence in ipairs(Results) do
		local contentSize
		
		if (KeepInnerContent) then
            contentSize = (occurence.format.starts:len() + occurence.format.ends:len());

            Text = Text:sub(1, occurence.starts - Appendence - 1)
                ..Text:sub(
                    (occurence.starts - Appendence) + (occurence.format.starts:len()),
                    (occurence.ends - Appendence) - (occurence.format.ends:len())
                )
                ..Text:sub(occurence.ends - Appendence + 1)
        else
            contentSize = ((occurence.ends - occurence.starts) + 1);

            Text = Text:sub(1, occurence.starts - Appendence - 1)
                ..Text:sub(occurence.ends - Appendence + 1)
        end
		
		Appendence += contentSize
	end
	
	return Text
end

return RichTextUtil