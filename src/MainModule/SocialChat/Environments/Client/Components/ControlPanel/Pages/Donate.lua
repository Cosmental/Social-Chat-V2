--[[

    Name: Mari
    Date: 2/22/2023

    Description: This handles the Home page in the ControlPanel!

]]--

--// Module
local DonatePage = {};
DonatePage.__index = DonatePage

DonatePage.ButtonData = {
    PageName = "Donate",
    Priority = 2,
    Area = "Top", -- Top or Bottom

    ImageId = "rbxassetid://3926307971", -- string
    ImageRectOffset = Vector2.new(124, 84), -- Vector2
    ImageRectSize = Vector2.new(36, 36) -- Vector2
};

--// Services
local MarketplaceService = game:GetService("MarketplaceService");
local TweenService = game:GetService("TweenService");

--// Imports
local PageAPI
local FunctUI

--// Constants
local Player = game.Players.LocalPlayer
local Page

--// Initialization
function DonatePage:Init(Setup : table)
    local self = setmetatable(Setup, DonatePage);

    PageAPI = self.API.PageAPI
    FunctUI = self.Library.FunctUI
    Page = self.PanelUI.MainPanel.Donate

    --// Product setup
    local Elements = PageAPI:GetVisibleElements(Page);
    local DonationIds = { -- Please do not change these! SocialChat heavily relies on the support gained from these products. Changing these Ids will harm the resource and myself :(
		["Charity"] = 1518618208,
		["Donator"] = 1518618843,
		["Supporter"] = 1518618991,
		["Generous"] = 1518619148,
		["Selfless"] = 1518619277,
		["Respected"] = 1518619425,
		["Investor"] = 1518619578,
		["Developer"] = 1518619686,
		["Entrepreneur"] = 1518619832,
		["Philanthropist"] = 1518620075
    };

    for _, Button in pairs(Page.Options.Products:GetChildren()) do
        if (not Button:IsA("TextButton")) then continue; end

        Button.MouseButton1Click:Connect(function()
            MarketplaceService:PromptProductPurchase(Player, DonationIds[Button.Name]);
        end);
    end

    FunctUI.new("AdjustingCanvas", Page.Options.Products);
    
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
                    Object.Position += UDim2.fromOffset(15, 0);
                end

                TweenService:Create(Object, TweenInfo.new(1, Enum.EasingStyle.Exponential), Elements[Object]):Play();
            end
        end
    end

    return self;
end

return DonatePage