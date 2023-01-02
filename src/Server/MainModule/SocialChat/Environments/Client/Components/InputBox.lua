--[[

    Name: Mari
    Date: 12/22/2022

    Description: This component module handles SocialChat's input box!

]]--

--// Module
local InputBox = {};
InputBox.__index = InputBox

--// Services
local UserInputService = game:GetService("UserInputService");

--// Imports
local Highlighter
local SmartText
local Markdown

local Settings
local Channels

--// Constants
local InputFrame
local InteractionBar

local SubmitButton
local ChatBox

--// States
local systemWasTyping : boolean

--// Initialization

function InputBox:Initialize(Info : table) : metatable
    local self = setmetatable(Info, InputBox);

    Highlighter = self.Handlers.Highlighter
    SmartText = self.Library.SmartText
    Markdown = self.Library.Markdown

    Settings = self.Settings.ClientChannels
    Channels = self.Src.Channels

    InputFrame = self.ChatUI.Chat.Input
    InteractionBar = InputFrame.InteractionBar

    SubmitButton = InteractionBar.Submit
    ChatBox = InteractionBar.InputBox

    --// Input Detection
    --\\ Here we detect when inputs are made

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if (gameProcessedEvent) then return; end
        if (input.KeyCode ~= Enum.KeyCode.Slash) then return; end

        if (self.ChatButton:getToggleState() == "deselected") then
            self.ChatButton:select();
        end

        task.defer(ChatBox.CaptureFocus, ChatBox);
    end);

    ChatBox:GetPropertyChangedSignal("Text"):Connect(function()
        if (systemWasTyping) then return; end

        --// Visual Button avaliability
        SubmitButton.ImageColor3 = (
            (#ChatBox.Text > 0 and Color3.fromRGB(255, 255, 255))
            or Color3.fromRGB(125, 125, 125)
        );

        --// RichText removal
        local PureText, Occurences = ChatBox.Text:gsub("(\\?)<[^<>]->", "");
        
        if (Occurences > 0) then
            self:Set(PureText);
        end
    end);

    ChatBox.Focused:Connect(function()
        ChatBox.PlaceholderText = ""

        if (#ChatBox.Text > 0) then
            self:Set(self._oldText);
        end
    end);

    --// Chat Submittion
    --\\ Here we finalize our textbox string before sending it out!

    SubmitButton.MouseButton1Click:Connect(function()
        if ((self._oldText or ChatBox.Text):gsub(" ", ""):len() == 0) then return; end -- Empty strings cant be sent!
        Channels:SendMessage(self._oldText or ChatBox.Text);

        self._oldText = nil
        ChatBox.Text = ""
    end);

    ChatBox.FocusLost:Connect(function(enterPressed : boolean)
        ChatBox.PlaceholderText = "Type '/' to begin chatting"

        if (not enterPressed) then -- Message was interrupted. Proceed with visuals
            self._oldText = ChatBox.Text
            self:Set(Highlighter(Markdown:Markup(ChatBox.Text)));
        else -- Submit our message
            if (ChatBox.Text:gsub(" ", ""):len() == 0) then return; end -- Empty string cancelation
            Channels:SendMessage(ChatBox.Text);
            
            self._oldText = nil
            ChatBox.Text = ""
        end
    end);

    --// Textbox Control
    ChatBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        ChatBox.TextSize = SmartText:GetBestFontSize(ChatBox.AbsoluteSize, Settings.MessageFont, 0, Settings.MaxTextboxFontSize);
    end);

    ChatBox.Font = Settings.MessageFont
    return self
end

--// Methods

--- Sets the TextBox's text content to the provided string
function InputBox:Set(content : string)
    if ((type(content) ~= "string") or (#content == 0)) then return; end -- Silent cancelation is required for arbitrary functuality

    systemWasTyping = true
    ChatBox.Text = content
    systemWasTyping = false
end

return InputBox