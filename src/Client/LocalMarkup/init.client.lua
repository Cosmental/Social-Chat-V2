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

    /shrug
]]

local str2 = [[
    This is a second **TextGroup!**
    Make sure (:test:)[thisIsCool] you dont *mess up* the __sizing__ and the ~~positioning~~.
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
    MarkupGUI.two.Visible = not MarkupGUI.two.Visible
end);

MarkdownObject:Replace("/shrug", "¯\\_(ツ)_/¯");

local MarkdownLabels = MarkdownObject:Generate(MarkupGUI.yeah, str);

local MD2 = RichString.new({
    Font = Enum.Font.Antique
});

MD2:Replace(":test:", function()
    local test = Instance.new("ImageButton");
    return test
end);

MD2:Define("thisIsCool", function(connectedText : string)
    print("CONNECTED:", connectedText);
end);

local MDLs = MD2:Generate(MarkupGUI.yeah, str2);

--// Formatting

local SmartText = require(script.SmartText);
local TextObject = SmartText.new(MarkupGUI.yeah, {
    MinFontSize = 0,
    MaxFontSize = 100,
});

TextObject:AddGroup("Test", MarkdownLabels, MarkdownObject.Font);
TextObject:AddGroup("Test2", MDLs, MD2.Font);

TextObject:Update();