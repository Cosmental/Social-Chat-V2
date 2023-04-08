--[[

    Name: Mari
    Date: 2/22/2023

    Description: This handles the Settings page in the ControlPanel!

    =====================================================================================================================

    NOTE: Hey you! Either you're a developer or just a curious individual who decided to dig into SocialChat's internal code...
          well... LUCKY YOU!! Let me tell you about this module in detail!

          Initialy this was going to be another "easy to make" panel within the Control Panel, but then I got the idea of adding
          extensions to SocialChat! Extensions would be a great way to enable developers to contribute to the magic that is
          Social Chat, hence being my reason towards why I turned this panel into its own standalone API!

          "But Mari... why would you do this to yourself? Why is this relevant to your idea with extensions?"
          GOOD QUESTION! With this API, extensions can add custom settings that toggle certain behaviors easily!

          "Was this worth adding?"
          Maybe.

          "Was this hard to make?"
          Not really, but it was very annoying.

          "Will you ever get compensated for your hard work?"
          Maybe. But thats not the goal with open sourced resources now is it? :)

]]--

--// Module
local SettingsPage = {};
SettingsPage.__index = SettingsPage

SettingsPage.ButtonData = {
    PageName = "Settings",
    Priority = 1,
    Area = "Bottom", -- Top or Bottom

    ImageId = "rbxassetid://3926307971", -- string
    ImageRectOffset = Vector2.new(324, 124), -- Vector2
    ImageRectSize = Vector2.new(36, 36) -- Vector2
};

local Category = {};
Category.__index = Category

--// Services
local TweenService = game:GetService("TweenService");

--// Imports
local Structure = require(script.Structure);

local PageAPI
local FunctUI

--// Constants
local Network
local Presets
local Page

--// Initialization

function SettingsPage:Init(Setup : table)
    local self = setmetatable(Setup, SettingsPage);
    Structure = Structure(self);

    PageAPI = self.API.PageAPI
    FunctUI = self.Library.FunctUI
    Page = self.PanelUI.MainPanel.Settings

    Presets = self.Presets
    Network = self.Remotes.DataService

    Page.DataFailureProtocol.Visible = true -- Only for data collection
    FunctUI.new("AdjustingCanvas", Page.Categories);

    --// Data Management
    for Entry : string, Data : table in pairs(Structure) do
        local Element = Category.new(Entry, Data.Icon);

        for DataSet : string, Option : table in pairs(Data.Options) do
            local Data = self.Data.Settings[DataSet];

            if (not Data) then
                warn("DataEntry '"..(DataSet).. "' does not exist! (are you sure your Structure Index matches the setting you're trying to link it to?)");
                continue;
            end

            local Interactable, API = Element:Create(Option);
            FunctUI.new("Note", Interactable.Configuration, Option.Info);

            API.Value = (if (Data.Value ~= nil) then Data.Value else Data.Default);
            API:SetEnabled(Data.Locked);

            API.ValueChanged:Connect(function(Value : any?)
                Option.OnUpdated(Value);
                Network.EventDataEntry:FireServer("Settings/"..(DataSet), Value);
            end);
        end
    end

    --// Visual Appearance
    local Elements = PageAPI:GetVisibleElements(Page, {Page.DataFailureProtocol, Page.Categories});
    local ProtocolInfo = Elements[Page.DataFailureProtocol];

    Page.DataFailureProtocol.Visible = false
    self.Button.OnClicked = function()
        local Order = PageAPI:GetOrderedElements(Page);

        for _, Objects in pairs(Order) do
            -- local Highest = Objects[1];

            for _, Object in pairs(Objects) do
                if (not Elements[Object]) then continue; end

                if (Object:IsA("Frame")) then
                    Object.BackgroundTransparency = 1
                elseif (Object:IsA("TextLabel") or Object:IsA("TextBox") or Object:IsA("TextButton")) then
                    Object.TextTransparency = 1
                    Object.TextStrokeTransparency = 1
                    Object.Position += UDim2.fromOffset(20, 0);
                elseif (Object:IsA("ImageLabel") or Object:IsA("ImageButton")) then
                    Object.ImageTransparency = 1
                    Object.Position -= UDim2.fromOffset(5, 15);
                end

                TweenService:Create(Object, TweenInfo.new(1, Enum.EasingStyle.Exponential), Elements[Object]):Play();
            end

            --// DATA FAILURE VISUAL
            coroutine.wrap(function()
                if (self.FFLAG_DataFailure) then
                    Page.DataFailureProtocol.BackgroundColor3 = Color3.fromRGB(255, 200, 200);
                    Page.DataFailureProtocol.Position += UDim2.fromOffset(0, 20);

                    Page.DataFailureProtocol.Message.TextTransparency = 1
                    Page.DataFailureProtocol.Message.TextStrokeTransparency = 1

                    task.wait(.5);

                    TweenService:Create(Page.DataFailureProtocol, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), ProtocolInfo):Play();
                    TweenService:Create(Page.DataFailureProtocol.Message, TweenInfo.new(0.5), {
                        TextStrokeTransparency = 0.5,
                        TextTransparency = 0
                    }):Play();
                    
                    Page.DataFailureProtocol.Visible = true
                end
            end)();
        end
    end

    self.Button.OnDeselected = function()
        Page.DataFailureProtocol.Visible = false
    end

    return self
end

--// CategoryAPI

--- Creates a new settings Category
function Category.new(Name : string, IconSettings : table) : Category
    assert(type(Name) == "string", "Failed to create new category because 'Name' was not a string! (received: "..(type(Name))..")");
    assert(type(IconSettings) == "table", "Failed to create category '"..(Name).."' because 'IconSettings' was not a table! (received: "..(type(IconSettings))..")");
    
    --// Canvas Instancing
    local Canvas = Presets.Settings.Category:Clone();
    local CanvasPadding = 25

    Canvas.Icon.Image = IconSettings.ImageId
    Canvas.Icon.ImageRectSize = (IconSettings.ImageRectSize or Vector2.new(0, 0));
    Canvas.Icon.ImageRectOffset = (IconSettings.ImageRectOffset or Vector2.new(0, 0));

    Canvas.Category.Text = Name
    Canvas.Name = Name
    Canvas.Parent = Page.Categories

    --// Automatic Updates
    local RealSize = Canvas.Size

    Canvas.Configurations:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        Canvas.Size = UDim2.new(
            RealSize.X.Scale,
            (RealSize.X.Scale == 0 and RealSize.X.Offset),
            0,
            Canvas.Configurations.AbsoluteSize.Y + Canvas.Icon.AbsoluteSize.Y + CanvasPadding
        );
    end);

    --// Object Oriented Category Setup
    local NewCategory = setmetatable({

        --// PROPERTIES
        ["Object"] = Canvas,
        ["Name"] = Name,

        --// DATA
        ["AdjustingCanvas"] = FunctUI.new("AdjustingCanvas", Canvas.Configurations, Page.Categories),
        ["Options"] = {}, -- table : of? => FunctUI ClassTypes

    }, Category);
    
    NewCategory.AdjustingCanvas:Update();
    return NewCategory
end

--- Adds a new interactable configuration based on the queried request
function Category:Create(Details : table) : Instance & table
    assert(type(Details) == "table", "The provided 'Details' parameter was not a table! (received: "..(type(Details))..")");
    
    local Preset = Presets.Settings[Details.Type]:Clone();
    Preset.Configuration.Text = Details.Name

    local Interactable = Preset.Controller.Value
    local API = FunctUI.new(Details.Type, Interactable);

    Preset.LayoutOrder = Details.Order
    API:Apply(Details.Metadata);

    self.Options[Preset] = API
    Preset.Parent = self.Object.Configurations

    return Preset, API
end

--// Functions

SettingsPage.CategoryAPI = Category
return SettingsPage