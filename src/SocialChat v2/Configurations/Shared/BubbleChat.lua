return {

    --// GENERAL \\--

    ["IsBubbleChatEnabled"] = true, -- A boolean that determines if the chat bubble system is enabled or not.
    ["MaxDisplayableBubbles"] = 3, -- The maximum number of chat bubbles that can appear over a player's head at once.
    ["ChatBubbleLifespan"] = 10, -- How long a chat bubble will appear over a player's head before disappearing.

    --// BEHAVIOR \\--

    ["DisplayThinkingBubble"] = true, -- A boolean that determines if a "thinking" bubble will appear over a player's head when they are typing in chat.
    ["IsMarkdownEnabled"] = true, -- A boolean that determines if Markdown formatting is enabled on chat bubbles.

    --// DEFAULTS \\--

    ["Default"] = { -- Default values for the chat bubbles' font, text size, text color, bubble color, and transparency.

        ["Font"] = Enum.Font.SourceSans,
        ["TextSize"] = 30,
        ["TextColor"] = Color3.fromRGB(40, 40, 40),
        ["BubbleColor"] = Color3.fromRGB(255, 255, 255),
        ["BubbleTransparency"] = 0

    };

    --// MISC \\--

    ["ThinkingSpeed"] = 1.25, -- The movement-speed of the thinking animation displayed within BubbleChat's "thinking" bubble.
    ["BubblePadding"] = Vector2.new(15, 45), -- This is the default UI-Padding for BubbleChat. Changing this will drastically change the way your BubbleChat messages appear.
    ["VisibilityTweenInfo"] = TweenInfo.new(.5, Enum.EasingStyle.Exponential) -- The TweenInfo used to play BubbleChat tweens.

};