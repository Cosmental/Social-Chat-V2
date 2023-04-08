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

--// States
local Pages : table < Page > = {};
local API : table < table > = {};

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
            Pages[Page.Name] = Response
        else
            error("SocialChat Control-Panel Error: Failed to require page \""..(Page.Name).."\"! (response: "..(Response)..")");
        end
    end

    for Name, Page in pairs(Pages) do
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
                ["Extensions"] = self.Extensions,
                ["Src"] = self.Src,

                ["Button"] = Button,
                ["API"] = API,

                ["Data"] = self.Data,
                ["FFLAG_DataFailure"] = self.FFLAG_DataFailure
            });
        end);

        if (Success) then
            Pages[Name] = Response
        else
            error("SocialChat Control-Panel Error: Failed to initialize page \""..(Name).."\"! (response: "..(Response)..")");
        end
    end

    return self
end

--// Methods

--- Sets the visibility of the ControlPanel to the provided boolean state
function ControlPanel:SetEnabled(IsEnabled : boolean?)
    if (self.Enabled == IsEnabled) then return; end -- We're already at this state! Cancel API request.
	self.Enabled = IsEnabled

	if (IsEnabled) then
		PanelFrame.Visible = true
        Pages.Home.Button:Select();
	end

	if (IsEnabled) then return; end

    Pages.Home.Button:Deselect();
	PanelFrame.Visible = false
end

--- Returns a list of registered ControlPanel Sub-API modules
function ControlPanel:GetAPI() : table?
    return API
end

--- Returns a list of registered ControlPanel pages
function ControlPanel:GetPages() : table?
    return Pages
end

return ControlPanel