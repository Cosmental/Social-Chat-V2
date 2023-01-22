return {

    --// BEHAVIOR \\--

    ["UsernameHighlightsEnabled"] = true, -- Highlight usernames when typing in chat! [ Example: "Cosmental" would be highlighted ]
    ["UserHighlightColor"] = Color3.fromRGB(83, 173, 224),

    ["SystemKeywordHighlightsEnabled"] = true, -- Highlight keywords like "/e dance"

    ["CustomHighlightsEnabled"] = true, -- Highlight custom keywords!

    --// COLOR CODING \\--

    ["KeyPhrases"] = {

        ["_SYSTEM"] = {
            ["phrases"] = {
                "/e dance", "/e dance1", "/e dance2", "/e dance3",
                "/e point", "/e cheer", "/e wave", "/e laugh",
                "/help", "/w"
            },

            ["color"] = Color3.fromRGB(233, 75, 75),
            ["isStartPhrase"] = true
        };

    };

};