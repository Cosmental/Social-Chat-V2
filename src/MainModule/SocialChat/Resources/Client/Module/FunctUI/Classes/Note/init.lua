--[[

    Name: Mari
    Date: 4/1/2023

    Description: This FunctUI API adds a hover-on Text info UI element to the provided instance!

]]--

--// Module
local Note = {};
Note.__index = Note

--// Services
local TweenService = game:GetService("TweenService");
local TextService = game:GetService("TextService");
local RunService = game:GetService("RunService");

--// Constants
local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse();

local Screen = script.NoteAPI
Screen.Parent = Player.PlayerGui

--// Methods

--- Adds a Note to the provided GuiObject when hovered over!
function Note.new(Element : GuiObject, Message : string, Style : string?) : Note
    assert(typeof(Element) == "Instance", "The provided Note GuiObject was not an Instance! (received "..(typeof(Element))..")");
    assert(Element:IsA("GuiObject"), "The provided Instance was not of ClassType \"GuiObject\". (received "..(Element.ClassName)..")");
    assert(type(Message) == "string", "The provided note was not of type \"string\". (got \""..(type(Message)).."\" instead)");
    assert(not Style or type(Style) == "string", "The requested style was not in the form of a string! (got \""..(type(Style)).."\" instead)");
    
    --// Instancing Setup

    local Preset = script.Styles["Note-"..(Style or "Light")];
    local Object = Preset:Clone();

    Object.Name = Element.Name.."_Note"
    Object.Content.Text = Message

    local Params = Instance.new("GetTextBoundsParams");
    Params.Font = Font.fromEnum(Enum.Font.SourceSans);
    Params.Text = Message
    Params.Size = 20
    Params.Width = 200

    local TextSize = TextService:GetTextBoundsAsync(Params);
    Object.Size = UDim2.fromOffset(TextSize.X, TextSize.Y);

    --// Meta Setup

    local self = setmetatable({

        --// PROPERTIES

        ["Object"] = Object, -- GuiObject :: Preset Hover-Instance
        ["Element"] = Element, -- GuiObject :: The linked GuiObject

        --// PROGRAMMING

        ["Hovering"] = false, -- boolean :: Determines when the object is currently hovered on or not
        ["Disabled"] = false -- boolean :: Determines if the element is enabled or not

    }, Note);

    --// Hover Detection

    Element.InputBegan:Connect(function(Input : Enum.UserInputType)
        if (Input.UserInputType ~= Enum.UserInputType.MouseMovement) then return; end

        TweenService:Create(Object, TweenInfo.new(.2), {
            BackgroundTransparency = Preset.BackgroundTransparency
        }):Play();

        TweenService:Create(Object.Content, TweenInfo.new(.2), {
            TextTransparency = Preset.Content.TextTransparency,
            TextStrokeTransparency = Preset.Content.TextStrokeTransparency
        }):Play();

        self.Hovering = true
    end);

    Element.InputEnded:Connect(function(Input : Enum.UserInputType)
        if (Input.UserInputType ~= Enum.UserInputType.MouseMovement) then return; end

        TweenService:Create(Object, TweenInfo.new(.2), {
            BackgroundTransparency = 1
        }):Play();

        TweenService:Create(Object.Content, TweenInfo.new(.2), {
            TextTransparency = 1,
            TextStrokeTransparency = 1
        }):Play();

        self.Hovering = false
    end);

    --// Movement Control
    local ScreenSize = workspace.CurrentCamera.ViewportSize

    RunService.RenderStepped:Connect(function()
        if (not self.Hovering) then return; end

        Object.Position = UDim2.fromOffset(
            ((Mouse.X >= ScreenSize.X / 2) and (Mouse.X - Object.AbsoluteSize.X - 10)) or (Mouse.X + 15),
            ((Mouse.Y <= ScreenSize.Y / 2) and (Mouse.Y)) or (Mouse.Y - Object.AbsoluteSize.Y)
        );
    end);

    Object.BackgroundTransparency = 1
    Object.Content.TextTransparency = 1
    Object.Content.TextStrokeTransparency = 1

    Object.Parent = Screen
    return self
end

--- Determines the current state of this interactable. Disabling your button will lock it from further inputs, but its value will remain the same
function Note:SetEnabled(State : boolean)
    self.Disabled = State
    self.Object.Visible = State
end

return Note