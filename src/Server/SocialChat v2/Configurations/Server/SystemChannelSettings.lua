return {

    --// CHAT SYSTEM SETTINGS \\--
    
    ["MaxMessagesPerChannel"] = 50, -- Determines the max amount of messages that can be cached in each channel
    ["MaxMessageLength"] = 200, -- Determines the maximum string length for a single message
    
    ["UseDisplayNames"] = false, -- Determines if player usernames OR display-names will be displayed in chat when sending messages
    ["MessageRate"] = 10, -- Determines the maximum amount of messages a player can send every 10 seconds

    --// META \\--

    ["UserTeamColorsAsUsernameColor"] = true, -- Determines if a player recieve's their current team (if any) color as their username color

    ["AssignRandomUsernameColorOnJoin"] = true, -- If true, a random username color will be given to players upon joining

    ["UsernameColors"] = { -- These colors will be used and given out to players who join the server randomly (opt.) [Must be a Color3]
        Color3.fromRGB(255, 80, 80),
        Color3.fromRGB(100, 100, 255),
        Color3.fromRGB(70, 255, 100),
        Color3.fromRGB(255, 120, 255),
        Color3.fromRGB(105, 225, 255),
        Color3.fromRGB(240, 240, 125),
        Color3.fromRGB(255, 180, 15),
        Color3.fromRGB(255, 65, 160),
        Color3.fromRGB(255, 150, 210)
    };

    ["ServerTagData"] = { -- This will be the TagData used for our Server whenever we need to make a server message!
        ["Classic"] = {
            ["Username"] = {
                ["Color"] = Color3.fromRGB(255, 100, 100)
            },

            ["Content"] = {
                ["Color"] = Color3.fromRGB(200, 200, 200)
            }
        };
    };

    ["ServerErrorColor"] = Color3.fromRGB(255, 80, 80), -- This will be the color used to send server error messages to clients

    --// MISC \\--

    ["TeamJoinMessage"] = "{Team} You are now in the \'%s\' team." -- This message will be sent to our client whenever they join/change teams!

};