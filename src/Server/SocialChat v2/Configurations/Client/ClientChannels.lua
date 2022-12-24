return {
    
    --// BEHAVIOR \\--

    ["DirectMessagesCreateNewChannels"] = true, -- Determines if new chat channels will be created when a private message is sent to someone else

    ["DisplayNamesAreUsed"] = true, -- Determines if display names are used rather than the REAL username for each player

    ["AllowMarkdown"] = true, -- Determines if players can use Markdown syntaxing in their messages. ( this behaves similar to how discord messaging )

    --// DISPLAY \\--

    ["MessageFontSize"] = 18, -- The desired fontSize for our messages

    ["MessageFont"] = Enum.Font.SourceSans, -- The desired font for our messages

    --// MISC \\--

    ["ChannelFocusTweenInfo"] = TweenInfo.new(
        0.5,
        Enum.EasingStyle.Exponential
    ), -- This will be the TweenInfo for the button effect used to switch between channels!

};