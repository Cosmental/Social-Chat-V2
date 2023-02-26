--[[

    Name: Mari
    Date: 2/22/2023

    Description: This handles the Home page in the ControlPanel!

]]--

--// Module
local HomePage = {};
HomePage.__index = HomePage

HomePage.ButtonData = {
    PageName = "Home",
    Priority = 1,
    Area = "Top", -- Top or Bottom

    ImageId = "http://www.roblox.com/asset/?id=12290420075", -- string
    ImageRectOffset = nil, -- Vector2
    ImageRectSize = nil -- Vector2
};

--// Services
local MarketplaceService = game:GetService("MarketplaceService");
local TweenService = game:GetService("TweenService");

--// Imports
local PageAPI

--// Constants
local SocialChat_ASSET = (3607597101 * 3); -- Obfuscated number as a means of preventing changes. This directly links to the actual Model!
local Player = game.Players.LocalPlayer

local Page

--// Initialization

function HomePage:Init(Setup : table)
    local self = setmetatable(Setup, HomePage);

    PageAPI = self.API.PageAPI
    Page = self.PanelUI.MainPanel.Home

    --// Setup
    local UserDetails = Page.UserDetails
    local GetFrame = Page.Installation.Get

    --// Visual Setup

    UserDetails.Message.Text = "Welcome to <font color=\"rgb(85, 170, 255)\">SocialChat</font> "..(Player.Name).."!"
    UserDetails.ClientPortrait.Headshot.Image = game.Players:GetUserThumbnailAsync(
        Player.UserId,
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size420x420
    );

    --// Purchase Functuality
    local function DisablePromptButton()
        GetFrame.UIStroke.Color = Color3.fromRGB(0, 0, 0);
        GetFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70);
        GetFrame.Button.TextColor3 = Color3.fromRGB(126, 126, 126);
        GetFrame.Button.Text = "Owned"
    end

    if (not MarketplaceService:PlayerOwnsAsset(Player, SocialChat_ASSET)) then
        GetFrame.Button.MouseButton1Click:Connect(function()
            MarketplaceService:PromptPurchase(Player, SocialChat_ASSET);
        end);

        MarketplaceService.PromptPurchaseFinished:Connect(function(Client : Player, AssetId : number, WasPurchased : boolean)
            if (Client ~= Player) then return; end
            if (not WasPurchased) then return; end
            if (AssetId ~= SocialChat_ASSET) then return; end

            DisablePromptButton();
        end);
    else
        DisablePromptButton();
    end

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

return HomePage