return {

    --// DATA

    ["Recent"] = {
        ["Default"] = {};
    };

    --// SETTINGS
    ["Settings"] = {
        ["Default"] = {
            ["DisableSuggestions"] = {
                Name = "Disable Suggestions",
                Info = "If true, this will hide any suggestions that show up when typing emojis within the Chat's InputBox.",
                Type = "Button",
                Order = 1
            };

            ["DisableEmojiPanel"] = {
                Name = "Disable Emoji Panel",
                Info = "If true, this will hide the emoji panel.",
                Type = "Button",
                Order = 2
            };

            ["EmoticonsToEmoji"] = {
                Name = "Convert Emoticons to Emojis",
                Info = "If true, this will automatically convert your emojitcons into emojis.\n\n<b>Example:</b>\n:D -> 😀",
                Type = "Button",
                Order = 3
            };
        };
    };

};