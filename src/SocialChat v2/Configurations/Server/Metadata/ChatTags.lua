--[[

    Name: Mari
	Date: 12/23/2021
	
	Description: This module holds data for in game chat tags and ranks. (This data will be passed to our client(s) for individual rendering)

]]--

return {

	--// SERVER TAG DATA
	--\\ This is tag data used for Server messages! DO NOT DELETE IT (it will cause errors)

	["SERVER"] = {
        ["Classic"] = {
            ["Username"] = {
				["Name"] = "SERVER",
                ["Color"] = Color3.fromRGB(255, 100, 100)
            },

            ["Content"] = {
                ["Color"] = Color3.fromRGB(200, 200, 200)
            }
        };

		["PriorityOrder"] = 0
    };

	--// EXAMPLE:
	--\\ I made my own tag data for my own tag, but feel free to use it as a reference! I commented it out for your convenience :D

	-- ["Mari"] = {
	-- 	["Requirements"] = {
	-- 		["UserIds"] = {},

	-- 		["GroupId"] = 4635482,
	-- 		["AcceptedRanks"] = {255},
	-- 	};

	-- 	["Metadata"] = {
	-- 		["Classic"] = {
	-- 			["Tag"] = {
	-- 				["Name"] = "Creator",
	-- 				["Color"] = Color3.fromRGB(255, 91, 206)
	-- 			},

	-- 			["Username"] = {
	-- 				["Color"] = Color3.fromRGB(168, 91, 255)
	-- 			}
	-- 		};
	-- 	};

	-- 	["PriorityOrder"] = 0,
	-- };
};