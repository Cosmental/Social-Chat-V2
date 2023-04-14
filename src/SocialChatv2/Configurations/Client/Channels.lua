return {
    
    --// BEHAVIOR \\--

    ["HideChatFrame"] = false, -- If set to true, the chat frame will be hidden and players will only be able to communicate through bubble chat.
    ["AllowMarkdown"] = true, -- If set to true, players can use Markdown syntaxing in their messages (similar to Discord messaging).
    
    ["IdleTime"] = 10, -- Determines how long the chat UI can remain idle before it automatically hides itself.

    --// HIGHLIGHTING \\--
    
    ["UsernameHighlightsEnabled"] = true, -- If set to true, usernames will be highlighted when typed in chat.
    ["UserHighlightColor"] = Color3.fromRGB(83, 173, 224), -- Determines the highlight color for usernames in chat.

    ["SystemKeywordHighlightsEnabled"] = true, -- If set to true, certain keywords like "/e dance" will be highlighted.
    ["SystemHighlights"] = { --The highlighting data passed to the highlighter. This only works if "SystemKeywordHighlights" are enabled.
        ["Phrases"] = {
            "/e dance", "/e dance1", "/e dance2", "/e dance3",
            "/e point", "/e cheer", "/e wave", "/e laugh",
            "/help", "/w", "/console", "/newconsole"
        },

        ["Color"] = Color3.fromRGB(233, 75, 75),
        ["OnlyAtStart"] = true
    };

    --// DANCE EMOTES \\--

    ["EmotesAllowed"] = true, -- Determines if players are allowed to use ROBLOX dance emotes in-game.
    ["DanceEmotes"] = { -- The URLs for various dance emotes. These are used to run the '/e {emote}' commands.
        [Enum.HumanoidRigType.R15] = {
            ["dance"] = {
                [1] = "http://www.roblox.com/asset/?id=507771019",
                [2] = "http://www.roblox.com/asset/?id=507776043",
                [3] = "http://www.roblox.com/asset/?id=507777268"
            },

            ["point"] = "http://www.roblox.com/asset/?id=507770453",
            ["cheer"] = "http://www.roblox.com/asset/?id=507770677",
            ["wave"] = "http://www.roblox.com/asset/?id=507770239",
            ["laugh"] = "http://www.roblox.com/asset/?id=507770818"
        },

        [Enum.HumanoidRigType.R6] = {
            ["dance"] = {
                [1] = "http://www.roblox.com/asset/?id=182435998",
                [2] = "http://www.roblox.com/asset/?id=182436842",
                [3] = "http://www.roblox.com/asset/?id=182436935"
            },

            ["point"] = "http://www.roblox.com/asset/?id=128853357",
            ["cheer"] = "http://www.roblox.com/asset/?id=129423030",
            ["wave"] = "http://www.roblox.com/asset/?id=128777973",
            ["laugh"] = "http://www.roblox.com/asset/?id=129423131",
        }
    },

    --// DISPLAY \\--

    ["MaxFontSize"] = 18, -- The default desired font size for chat messages.
    ["MessageFont"] = Enum.Font.SourceSans, -- The desired default font for our messages

    --// MISC \\--

    ["MaxRenderableMessages"] = 50, -- The maximum amount of displayable messages.

    ["ChannelFocusTweenInfo"] = TweenInfo.new( -- The TweenInfo for the button effect used to switch between channels.
        0.5,
        Enum.EasingStyle.Exponential
    ),

    ["OnLabelRendered"] = function(Label : TextLabel) -- A function used to render a unique message animation.
        Label.Position -= UDim2.fromOffset(25, -25);
        Label.Size -= UDim2.fromOffset(2, 2);

        Label.TextStrokeTransparency = 1
        Label.TextTransparency = 1
    end

};