--[[

    Name: Mari
	Date: 12/23/2021
	
	Description: This module holds data for in game chat tags and ranks. (This data will be passed to our client(s) for individual rendering)

]]--

return {
	["Cos"] = {
		["Requirements"] = {
			["UserIds"] = {},

			["GroupId"] = 4635482,
			["AcceptedRanks"] = {255},
		};

		["Metadata"] = {
			["Classic"] = {
				["Tag"] = {
					["Name"] = "Creator",
					["Color"] = Color3.fromRGB(255, 35, 35)
				}
			};

			["ChatBubble"] = {
				["Color"] = "Example",
				["Font"] = Enum.Font.SourceSans
			},
		};

		["PriorityOrder"] = 0,
	};
};