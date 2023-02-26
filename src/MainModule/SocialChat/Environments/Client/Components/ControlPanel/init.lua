local TweenService = game:GetService("TweenService")
--[[

    Name: Mari
    Date: 2/21/2023

    Description: The ControlPanel is designed to provide additional UX options to players via configurations with SocialChat! Developers
    may also use the ControlPanel as a way to debug their games using the Terminal.

]]--

--// Module
local ControlPanel = {};
ControlPanel.__index = ControlPanel

--// Imports
local Navigator = require(script.API.Navigator);
local TopbarPlus

--// Constants
local TopbarButton
local PanelFrame
local MainPanel

--// Initialization
function ControlPanel:Initialize(Setup : table)
    local self = setmetatable(Setup, ControlPanel);

    TopbarPlus = self.Library.TopbarPlus
    TopbarButton = TopbarPlus.new();

    PanelFrame = self.ChatUI.ControlPanel
    MainPanel = PanelFrame.MainPanel
    script.PanelReference.Value = PanelFrame
    
    --// TopbarPlus Setup
    TopbarButton:setImage("rbxassetid://12290420075")
        :setCaption("SocialChat Panel")
        :setOrder(1)
        :setRight()

    TopbarButton:bindEvent("selected", function()
        self:SetEnabled(true);
    end);

    TopbarButton:bindEvent("deselected", function()
        self:SetEnabled(false);
    end);

    --// SidePanel Setup
    local API = {};
    self.Pages = {};

    for _, Module in pairs(script.API:GetChildren()) do
        if (not Module:IsA("ModuleScript")) then continue; end
        API[Module.Name] = require(Module);
    end

    for _, Page in pairs(script.Pages:GetChildren()) do
        if (not Page:IsA("ModuleScript")) then continue; end

        local Success, Response = pcall(function()
            return require(Page);
        end);

        if (Success) then
            self.Pages[Page.Name] = Response
        else
            error("SocialChat Control-Panel Error: Failed to require page \""..(Page.Name).."\"! (response: "..(Response)..")");
        end
    end

    for Name, Page in pairs(self.Pages) do
        local Success, Response = pcall(function()
            local Button = Navigator.new(Page.ButtonData.PageName, MainPanel[Page.ButtonData.PageName], Page.ButtonData.Priority);

            Button:SetImage(Page.ButtonData.ImageId, Page.ButtonData.ImageRectOffset, Page.ButtonData.ImageRectSize);
            Button:PushTo(Page.ButtonData.Area);

            return Page:Init({
                ["OnReadyEvent"] = self.OnReadyEvent,

                ["PanelUI"] = PanelFrame,
                ["ChatUI"] = self.ChatUI,
                ["Remotes"] = self.Remotes,

                ["Presets"] = script.Presets,
                ["Library"] = self.Library,
                ["Settings"] = self.Settings,
                ["Src"] = self.Src,

                ["Button"] = Button,
                ["API"] = API,

                ["Data"] = self.Data,
                ["FFLAG_DataFailure"] = self.FFLAG_DataFailure
            });
        end);

        if (Success) then
            self.Pages[Name] = Response
        else
            error("SocialChat Control-Panel Error: Failed to initialize page \""..(Name).."\"! (response: "..(Response)..")");
        end
    end

    --// Terminal Page Setup
    local Terminal = Navigator.new("Terminal", MainPanel.Terminal, 3);
    Terminal:SetImage("rbxassetid://3926305904", Vector2.new(404, 844), Vector2.new(36, 36));
    Terminal:SetState(false);

    return self
end

--// Methods

--- Sets the visibility of the ControlPanel to the provided boolean state
function ControlPanel:SetEnabled(IsEnabled : boolean?)
    if (self.Enabled == IsEnabled) then return; end -- We're already at this state! Cancel API request.
	self.Enabled = IsEnabled

	if (IsEnabled) then
		PanelFrame.Visible = true
        self.Pages.Home.Button:Select();
	end

	if (IsEnabled) then return; end

    self.Pages.Home.Button:Deselect();
	PanelFrame.Visible = false
end

return ControlPanel