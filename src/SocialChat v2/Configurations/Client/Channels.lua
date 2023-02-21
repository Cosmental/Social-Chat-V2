return {
    
    --// BEHAVIOR \\--

    ["HideChatFrame"] = true, -- Determines if the ChatFrame will be hidden. If true, the only form of communication will be through BubbleChat!
    
    ["AllowMarkdown"] = true, -- Determines if players can use Markdown syntaxing in their messages. ( this behaves similar to how discord messaging )

    ["IdleTime"] = 10, -- Determines how long the ChatUI can remain idle before automatically hiding itself

    --// DANCE EMOTES \\--

    ["EmotesAllowed"] = true, -- Determines if players are allowed to use ROBLOX dance emotes in game

    ["DanceEmotes"] = {
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

    ["MaxFontSize"] = 18, -- The default desired fontSize for our messages

    ["MessageFont"] = Enum.Font.SourceSans, -- The desired default font for our messages

    --// MISC \\--

    ["MaxRenderableMessages"] = 50, -- This determines the maximum amount of displayable messages! This is NOT the same as the Server equivalent setting and should be dependent on what the client wants and what the client can run on their system

    ["ChannelFocusTweenInfo"] = TweenInfo.new(
        0.5,
        Enum.EasingStyle.Exponential
    ), -- This will be the TweenInfo for the button effect used to switch between channels!

    ["OnLabelRendered"] = function(Label : TextLabel)
        Label.Position -= UDim2.fromOffset(25, -25);
        Label.Size -= UDim2.fromOffset(2, 2);

        Label.TextStrokeTransparency = 1
        Label.TextTransparency = 1
    end -- This function will be used to render a unique message animation! (Tweening to it's original state is handled by the "Channels" module)

};