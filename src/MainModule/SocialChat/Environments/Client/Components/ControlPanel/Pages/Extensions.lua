--[[

    Name: Mari
    Date: 3/28/2023

    Description: This page will display information related to any currently installed extensions on this game's installation of SocialChat!

]]--

--// Module
local Extensions = {};
Extensions.__index = Extensions

Extensions.ButtonData = {
    PageName = "Extensions",
    Priority = 3,
    Area = "Top", -- Top or Bottom

    ImageId = "rbxassetid://3926305904", -- string
    ImageRectOffset = Vector2.new(924, 244), -- Vector2
    ImageRectSize = Vector2.new(36, 36) -- Vector2
};

--// Services
local TweenService = game:GetService("TweenService");

--// Imports
local PageAPI
local FunctUI

--// Constants
local Page

local WidgetWindow

--// Initialization

function Extensions:Init(Setup : table)
    local self = setmetatable(Setup, Extensions);

    PageAPI = self.API.PageAPI
    FunctUI = self.Library.FunctUI

    Page = self.PanelUI.MainPanel.Extensions
    WidgetWindow = Page.Center.Installations

    FunctUI.new("AdjustingCanvas", WidgetWindow);

    --// Extension Gateway
    --\\ We still need to know what extensions the SERVER has installed for crediting!

    local Extensions = self.Extensions

    local Success, Response = pcall(function()
        return self.Remotes.ExtensionGateway:InvokeServer();
    end);

    if (Success) then
        for Name, Data in pairs(Response) do
            Extensions[Name] = Data
        end
    else
        warn("Failed to register Server Extensions due to network failure! ("..(Response or "No response available")..")")
    end

    --// Visual Instancing
    --\\ For each extension we want to create a visual tab for! Otherwise, crediting wouldn't be present :(

    if (next(Extensions)) then -- Extensions installed and found! (yay!)
        for Name, Data in pairs(Extensions) do
            local Widget = self.Presets.Extension:Clone();
            local CreatorName = game.Players:GetNameFromUserIdAsync(Data.CreatorId);

            Widget.Icon.Image = Data.IconId
            Widget.ExtensionName.Text = Data.Name
            Widget.Author.Text = "By: <font color=\"rgb(85, 170, 255)\"><b>"..(CreatorName).."</b></font>"
            Widget.Description.Text = Data.Description
            Widget.Version.Text = "v"..Data.Version

            local Badges = Widget.Badges

            Badges.DevAccess.Visible = (Data.CreatorId == 876817222); -- UserId == Cosmental's UserId
            Badges.Official.Visible = (Data.CreatorId == 876817222); -- TEMPORARY! [TODO: Make an official SocialChat website OR use a group!]
            -- Badges.Trending.Visible = HttpService:GetAsync("https://socialchat.com/trending")[Name]; -- TEMPORARY UNTIL WEBSITE GETS DONE
            Badges.Verified.Visible = (Data.CreatorId == 876817222); -- TEMPORARY UNTIL WEBSITE FINISHES

            Widget.Name = Name.."_WIDGET"
            Widget.Parent = WidgetWindow
        end
    else -- No extensions found! (vanilla-instance case)
        Page.NoExtensionsCase.Visible = true
    end

    --// Page Setup
    local Elements = PageAPI:GetVisibleElements(Page);
    
    self.Button.OnClicked = function()
        local Order = PageAPI:GetOrderedElements(Page);

        for _, Objects in pairs(Order) do
            -- local Highest = Objects[1];

            for _, Object in pairs(Objects) do
                if (Object:IsA("Frame")) then
                    Object.BackgroundTransparency = 1
                elseif (Object:IsA("TextLabel") or Object:IsA("TextBox") or Object:IsA("TextButton")) then
                    Object.TextTransparency = 1
                    Object.TextStrokeTransparency = 1
                    Object.Position -= UDim2.fromOffset(0, 20);
                elseif (Object:IsA("ImageLabel") or Object:IsA("ImageButton")) then
                    Object.ImageTransparency = 1
                end

                TweenService:Create(Object, TweenInfo.new(1, Enum.EasingStyle.Exponential), Elements[Object]):Play();
            end
        end
    end

    return self
end

return Extensions