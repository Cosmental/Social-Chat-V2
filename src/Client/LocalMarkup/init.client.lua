--[[

    Name: Mari
    Date: 12/8/2022

    Description: Just an example API script

]]--

local RichString = require(script.RichString);
local Markdown = require(script.Markdown);

local str = [[
    This text was written by my string **markup** tool!
    
    You can write your **OWN** richText using my *tool* now :)
    This tool is avaliable on *Roblox*, but you can grab it (__here__)[myCoolFunction].
    
    PS: ||whar? \*cool\*||
    ~~This text should be crossed out~~
]]

--// Markdown Example
local MarkupGUI = script.Markup_Example

MarkupGUI.main.Text = Markdown:Markup(str);
MarkupGUI.Parent = game.Players.LocalPlayer.PlayerGui

--// RichString usage
local MarkdownObject = RichString.new({
    Font = Enum.Font.SourceSans
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