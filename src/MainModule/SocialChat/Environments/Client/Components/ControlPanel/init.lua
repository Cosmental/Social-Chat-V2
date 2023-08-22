--[[

    Name: Mari
    Date: 2/21/2023

    Description: The ControlPanel is designed to provide additional UX options to players via configurations with SocialChat! Developers
    may also use the ControlPanel as a way to debug their games using the Terminal.

]]--

--// Module
local ControlPanel = {};
ControlPanel.__index = ControlPanel

--// Services
local UserInputService = game:GetService("UserInputService");

--// Imports
local Navigator = require(script.API.Navigator);
local TopbarPlus

local Trace : table < TraceAPI >

--// Constants
local TopbarButton
local PanelFrame
local MainPanel

local IsMobile = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled);
local IsDisabled : boolean? -- Determines if the ControlPanel is disabled based on Configurations by developers

--// States
local Pages : table = {};
local API : table = {};

--// Initialization
function ControlPanel:Initialize(Setup : table)
    local self = setmetatable(Setup, ControlPanel);

    IsDisabled = (not self.Settings.Channels.ControlPanelEnabled);
    if (IsDisabled) then return; end

    TopbarPlus = self.Library.TopbarPlus
    TopbarButton = TopbarPlus.new();
    
    Trace = self.Trace

    PanelFrame = self.ChatUI.ControlPanel
    MainPanel = PanelFrame.MainPanel
    script.PanelReference.Value = PanelFrame

    if (PanelFrame:FindFirstChild("DeviceConstraints")) then
        PanelFrame.DeviceConstraints[(IsMobile and "MobileConstraint") or "ComputerConstraint"].Parent = PanelFrame
        PanelFrame.DeviceConstraints:Destroy();
    else
        warn("This version of SocialChat may be outdated! DeviceConstraints not found within ControlPanel! This may lead to issues with Mobile devices that have been patched in a more recent version of SocialChat!");
    end

    
    --// TopbarPlus Setup
    TopbarButton:setImage("rbxassetid://12290420075")
        :setCaption("SocialChat Panel")
        :setOrder(1)
        :setRight()

    TopbarButton:bindEvent("selected", function()
        self:SetEnabled(true);
        
        if (IsMobile) then
            self.ChatButton:deselect();
            self.ChatButton:lock();
        end
    end);

    TopbarButton:bindEvent("deselected", function()
        self:SetEnabled(false);
        
        if (IsMobile) then
            self.ChatButton:select();
            self.ChatButton:unlock();
        end
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
            Trace:Error("Failed to setup page \""..(Page.Name).."\"! (response: "..(Response)..")");
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
            Trace:Error("Failed to initialize page \""..(Name).."\"! (response: "..(Response)..")");
        end
    end

    return self
end

--// Methods

--- Sets the visibility of the ControlPanel to the provided boolean state
function ControlPanel:SetEnabled(IsEnabled : boolean?)
    if (IsDisabled) then return; end -- Control Panel is disabled
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