return {
    
    --// BEHAVIOR \\--

    ["DirectMessagesCreateNewChannels"] = true, -- Determines if new chat channels will be created when a private message is sent to someone else

    ["DisplayNamesAreUsed"] = true, -- Determines if display names are used rather than the REAL username for each player

    ["AllowMarkdown"] = true, -- Determines if players can use Markdown syntaxing in their messages. ( this behaves similar to how discord messaging )

    --// DISPLAY \\--

    ["MaxTextboxFontSize"] = 20, -- The desired fontSize for our InputBox. (this does NOT change message fontsize!)

    ["MessageFontSize"] = 18, -- The desired fontSize for our messages

    ["MessageFont"] = Enum.Font.SourceSans, -- The desired default font for our messages

    --// MISC \\--

    ["MaxRenderableMessages"] = 50, -- This determines the maximum amount of displayable messages! This is NOT the same as the Server equivalent setting and should be dependent on what the client wants and what the client can run on their system

    ["ChannelFocusTweenInfo"] = TweenInfo.new(
        0.5,
        Enum.EasingStyle.Exponential
    ), -- This will be the TweenInfo for the button effect used to switch between channels!

};