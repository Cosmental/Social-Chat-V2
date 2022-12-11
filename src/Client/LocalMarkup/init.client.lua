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

MarkdownObject:Generate(MarkupGUI.yeah, str);