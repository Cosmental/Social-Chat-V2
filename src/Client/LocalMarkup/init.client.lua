--[[

    Name: Mari
    Date: 12/8/2022

    Description: Just an example API script

]]--

local Markdown = require(script.Markdown);
local MarkupGUI = script.Markup_Example

MarkupGUI.main.Text = Markdown:Markup([[
    This text was written by my string **markup** tool!
    
    You can write your **OWN** richText using my *tool* now :)
    This tool is avaliable on *Roblox*, but you can grab it (__here__)[myCoolFunction].

    ***test***
    
    PS: ||whar? \*cool\*||
    ~~This text should be crossed out~~
]]);

MarkupGUI.Parent = game.Players.LocalPlayer.PlayerGui