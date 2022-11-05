--[[

	Name: Cosmental
	Date: 9/1/2021
	
	Description: This Utility module converts numbers up to math.huge into abreviated strings

]]--

--// Constants
local Suffixes = {
	"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud",
	"Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Od", "Nd", "V", "Uv", "Dv"
};

--// Module
local NumberUtil = {};

function NumberUtil:Suffix(Number)
	if (Number < 1000) then 
		return Number -- If our number is less than 1000 then it doesnt really need any abreviation
	end

	--// Get a logged numeral
	local Logged = math.floor(math.log10(Number))
	local Floored = math.floor(Logged / 3);

	--// Get short
	local Short = math.floor((Number / 1000 ^ Floored) * 100) / 100

	--// Return a purged version that removes extra 0's
	return string.format("%s%s", Short, Suffixes[Floored]);
end

function NumberUtil:CommaValue(Query) --// Returns a comma value || EX: 10000 --> 10,000
	if (#Query % 3 == 0) then
		return Query:reverse():gsub("(%d%d%d)", "%1,"):reverse():sub(2);
	else
		return Query:reverse():gsub("(%d%d%d)", "%1,"):reverse();
	end
end

return NumberUtil