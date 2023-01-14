return {
    
    --// BEHAVIOR \\--
    
    ["AllowMarkdown"] = true, -- Determines if players can use Markdown syntaxing in their messages. ( this behaves similar to how discord messaging )

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