return {

    --// GENERAL \\--

    ["IsBubbleChatEnabled"] = true, -- Determines if bubble chat is enabled or not
    
    ["MaxDisplayableBubbles"] = 3, -- Determines the maximum amount of Chat Bubbles that appear over a player's head

    ["ChatBubbleLifespan"] = 10, -- Determines how long a chat bubble will appear over a player's head for

    --// BEHAVIOR \\--

    ["DisplayThinkingBubble"] = true, -- Displays a thinking bubble whenever a player is typing in chat!

    ["IsMarkdownEnabled"] = true, -- Determines if Markdown is enabled on ChatBubbles

    --// DEFAULTS \\--

    ["Default"] = {

        ["Font"] = Enum.Font.SourceSans, -- The DEFAULT displayed bubble chat font

        ["TextSize"] = 30, -- The DEFAULT TextSize for chat bubbles (this should USUALLY be bigger than your Classic Chat TextSize!)

        ["TextColor"] = Color3.fromRGB(40, 40, 40), -- The DEFAULT TextColor3 value fed into text bubbles!

        ["BubbleColor"] = Color3.fromRGB(255, 255, 255), -- The DEFAULT bubble chat background color!

        ["BubbleTransparency"] = 0, -- The DEFAULT BackgroundTransparency for chat bubbles

    };

    --// MISC \\--

    ["ThinkingSpeed"] = 1.25, -- Determines how long it takes our thinking animation to full play out!

    ["BubblePadding"] = Vector2.new(15, 45), -- This will be used as UI padding for our bubble messages! [DO NOT CHANGE THIS UNLESS YOU KNOW WHAT THIS DOES]

    ["VisibilityTweenInfo"] = TweenInfo.new(.5, Enum.EasingStyle.Exponential) -- This is the TweenInfo used to toggle Chat-Bubble visibility!

};