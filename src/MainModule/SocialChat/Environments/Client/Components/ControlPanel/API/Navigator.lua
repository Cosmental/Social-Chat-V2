--[[

    Name: Mari
    Date: 2/21/2023

    Description: This module handles the connection between sidebar buttons and pages! I could have done this manually, but I decided to add
    an API for control panel buttons in case of future additions!

]]--

--// Module
local Navigator = {};
local SideButton = {};
SideButton.__index = SideButton

--// Services
local TweenService = game:GetService("TweenService");

--// Constants
local Presets = script.Parent.Parent:WaitForChild("Presets");
local Reference = script.Parent.Parent.PanelReference

local SELECTION_COLOR = Color3.fromRGB(0, 170, 255);

--// States
local Buttons = {};
local CurrentPage

--// Methods

--- Creates a new SideButton object!
function Navigator.new(Name : string, Page : GuiObject, Priority : number?) : SideButton
    assert(typeof(Page) == "Instance", "The provided page was not an Instance! (Pages must be Instances)");
    assert(Page:IsA("GuiObject"), "The provided page Instance was not of class \"GuiObject\"! (received \""..(Page.ClassName).."\")");

    local Object = Presets.SideButton:Clone();
    
    Object.LayoutOrder = Priority
    Object.Name = Name

    local Button = setmetatable({

        --// PROPERTIES

        ["Priority"] = Priority,
        ["Object"] = Object,
        ["Name"] = Name,
        ["Page"] = Page,

        ["IsEnabled"] = true, -- A state that determines the availability of this button. If false, the button will de-activate and the page will remain in-accessable

        --// CALLBACKS

        ["OnClicked"] = nil, -- callback fired when the Page loads (opt.) [YIELDS]
        ["OnDeselected"] = nil -- callback fired when the Page unloads (opt.) [YIELDS]

    }, SideButton);

    Object.Button.MouseButton1Click:Connect(function()
        Button:Select();
    end);

    Buttons[Name] = Button
    Button:PushTo("Top"); -- Default Placement is the top!

    return Button
end

--- Sends the Navigator to the Home page
function Navigator:Set(Query : string)
    assert(type(Query) == "string", "You must provide a \"string\" query to search for! (received \""..(type(Query)).."\")");
    assert(Buttons[Query], "The requested page \""..(Query).."\" does not exist!");
    if (CurrentPage == Query) then return; end

    local Button = Buttons[Query];
    Button:Select();
end

--// Metamethods

--- Selects this button while deselecting any previously selected buttons
function SideButton:Select()
    if (CurrentPage == self) then return; end
    if (not self.IsEnabled) then return; end

    if (CurrentPage) then
        CurrentPage:Deselect();
    end

    if (self.OnClicked) then
        self.OnClicked();
    end

    CurrentPage = self

    local Outline = Instance.new("UIStroke");

    Outline.Name = "Selection"
    Outline.Color = SELECTION_COLOR
    Outline.Thickness = 0
    Outline.Parent = self.Object

    local Tween = TweenService:Create(self.Object.Button, TweenInfo.new(0.5), {
        ImageColor3 = SELECTION_COLOR
    });

    TweenService:Create(Outline, TweenInfo.new(0.5, Enum.EasingStyle.Elastic), {
        Thickness = 1
    }):Play();

    Tween:Play();

    Reference.Value.MainPanel.Tab.Value.Text = self.Name
    self.Page.Visible = true
end

--- Deselects this button
function SideButton:Deselect()
    if (CurrentPage ~= self) then return; end -- This page is NOT selected!
    CurrentPage = nil

    if (self.OnDeselected) then
        self.OnDeselected();
    end

    local Tween = TweenService:Create(self.Object.Button, TweenInfo.new(0.5), {
        ImageColor3 = Color3.fromRGB(255, 255, 255)
    });

    TweenService:Create(self.Object.Selection, TweenInfo.new(0.5, Enum.EasingStyle.Elastic), {
        Thickness = 0
    }):Play();
    
    Tween.Completed:Connect(function()
        if (self.Object:FindFirstChild("Selection")) then
            self.Object.Selection:Destroy();
        end
    end);

    Tween:Play();
    self.Page.Visible = false
end

--- Sets the clickable state of this button to the provided state boolean
function SideButton:SetState(IsEnabled : boolean)
    self:Deselect();

    self.Object.Button.ImageColor3 = (
        (IsEnabled and Color3.fromRGB(255, 255, 255))
        or (Color3.fromRGB(100, 100, 100))
    );

    self.IsEnabled = IsEnabled
end

--- Sets the image of the button to the requested ImageId
function SideButton:SetImage(ImageId : string, ImageRectOffset : Vector2?, ImageRectSize : Vector2?)
    assert(type(ImageId) == "string", "The provided ImageId was not of type \"string\"! (received \""..(type(ImageId)).."\")");
    assert((not ImageRectOffset) or (typeof(ImageRectOffset) == "Vector2"), "The provided ImageRectOffset was not of type \"Vector2\"! (received \""..(typeof(ImageRectOffset)).."\")");
    assert((not ImageRectOffset) or (typeof(ImageRectSize) == "Vector2"), "The provided ImageRectSize was not of type \"Vector2\"! (received \""..(typeof(ImageRectSize)).."\")");

    self.Object.Button.ImageRectOffset = (ImageRectOffset or Vector2.new(0, 0)); -- Support for Interface Tools :D
    self.Object.Button.ImageRectSize = (ImageRectSize or Vector2.new(0, 0));
    self.Object.Button.Image = ImageId
end

--- Places the SideButton into the requested area of the side-panel! (NOTE: Priority values will remain the same. Make sure to adjust them prior to parenting!)
function SideButton:PushTo(Area : string)
    assert(type(Area) == "string", "The provided 'PushTo' query was not of type \"string\"! (received \""..(type(Area)).."\")");
    assert(Area == "Top" or Area == "Bottom", "The requested area was not found! (please choose between 'Top' or 'Bottom') [THIS IS CASE-SENSITIVE]");

    self.Object.Parent = Reference.Value.SidePanel[Area];
end

return Navigator