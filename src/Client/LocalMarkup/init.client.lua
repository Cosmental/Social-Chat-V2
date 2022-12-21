--[[

    Name: Mari
    Date: 12/8/2022

    Description: Just an example API script

]]--

local RichString = require(script.RichString);
local Markdown = require(script.RichString.Markdown);

local str = [[
    This text was written by my string **markup** tool!
    
    You can write your **OWN** richText using my *tool* now :)
    This tool is avaliable on *Roblox*, but you can grab it (__here__)[myCoolFunction].

    ***test***
    
    PS: ||whar? \*cool\*||
    ~~This text should be crossed out~~
]]

--// Markdown Example
local MarkupGUI = script.Markup_Example

MarkupGUI.main.Text = Markdown:Markup(str);
MarkupGUI.Parent = game.Players.LocalPlayer.PlayerGui

--// RichString usage
local MarkdownObject = RichString.new({
    Font = Enum.Font.Arial
});

MarkdownObject:Define("myCoolFunction", function(connectedText : string)
    print("Connected:", connectedText);
end);

local MarkdownLabels = MarkdownObject:Generate(MarkupGUI.yeah, str, function(TextObject)
    TextObject.TextSize = 16
end);

--// Formatting

local SmartText = require(script.SmartText);
local TextObject = SmartText.new(MarkupGUI.yeah, {
    MinFontSize = 0,
    MaxFontSize = 100,
});

TextObject:AddGroup("Test", MarkdownLabels, MarkdownObject.Font);
TextObject:Update();

-- local TextService = game:GetService("TextService");

-- local FontSize = 16
-- local SpaceSize = (TextService:GetTextSize(" ", FontSize, Enum.Font.SourceSans, MarkupGUI.yeah.AbsoluteSize).X);

-- local XOffset = 0
-- local YOffset = 0

-- local BoundX = MarkupGUI.yeah.AbsoluteSize.X

-- for _, Word in pairs(MarkdownLabels) do
--     local WordSize = TextService:GetTextSize(Word.Content.." ", FontSize, Enum.Font.SourceSans, MarkupGUI.yeah.AbsoluteSize);

--     if (XOffset + WordSize.X >= BoundX) then
--         YOffset += FontSize
--         XOffset = 0
--     end

--     for _, TextObject in pairs(Word.Graphemes) do
--         local Content : string = TextObject.Text:gsub("(\\?)<[^<>]->", "");
--         if (Content == " ") then TextObject:Destroy(); XOffset += SpaceSize continue; end

--         local TextSize = TextService:GetTextSize(Content, FontSize, Enum.Font.SourceSans, MarkupGUI.yeah.AbsoluteSize);
    
--         TextObject.Size = UDim2.fromOffset(TextSize.X, TextSize.Y);
--         TextObject.Position = UDim2.fromOffset(XOffset, YOffset);
    
--         XOffset += (TextSize.X + 1);
--     end
-- end