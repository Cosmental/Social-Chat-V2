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
local RunService = game:GetService("RunService");

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

    --// Info Frame Setup
    local InfoFrame : Frame = Instance.new("Frame");
    
    InfoFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
    InfoFrame.BackgroundTransparency = 0.1

    InfoFrame.Position = UDim2.fromScale(.035, .57);
    InfoFrame.Size = UDim2.fromScale(.589, .39);

    InfoFrame.Name = "Info"
    InfoFrame.Visible = false
    InfoFrame.Parent = Page

    local Content : TextLabel = Instance.new("TextLabel");

    Content.Position = UDim2.fromScale(.028, .276);
    Content.Size = UDim2.fromScale(.94, .449);
    Content.Font = Enum.Font.SourceSans
    Content.BackgroundTransparency = 1

    Content.TextColor3 = Color3.fromRGB(255, 255, 255);
    Content.TextScaled = true
    Content.RichText = true

    Content.Name = "Content"
    Content.Parent = InfoFrame

    --// Product setup
    local DonationIds = { -- Please do not change these! SocialChat heavily relies on the support gained from these products. Changing these Ids will harm the resource and myself :(
		["Charity"] = 162922985,
		["Donator"] = 162923445,
		["Supporter"] = 162923771,
		["Generous"] = 162924110,
		["Selfless"] = 162924806,
		["Respected"] = 162925110,
		["Investor"] = 162925392,
		["Developer"] = 162925642,
		["Entrepreneur"] = 162925918,
		["Philanthropist"] = 162926154
    };

    if (RunService:IsStudio()) then -- Purchases dont work in studio!
        Content.Text = "<font color=\"rgb(0, 125, 255)\"><b>MarketPlaceService</b></font> does not work in <b>Studio</b>. If you would like to <font color=\"rgb(0,255,185)\"><b>donate</b></font>, please go in game!"
        InfoFrame.Visible = true
    else
        for _, Button : TextButton in pairs(Page.Options.Products:GetChildren()) do
            if (not Button:IsA("TextButton")) then continue; end
    
            local AssetId : number = DonationIds[Button.Name];
            local Success : boolean, Response : (boolean | string)? = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(Player.UserId, AssetId);
            end);
            
            if (Success and Response) then
                Button.Amount.TextColor3 = Color3.fromRGB(10, 58, 22);
                Button.Role.TextColor3 = Color3.fromRGB(65, 65, 65);
    
                Button.Amount.RichText = true
                Button.Amount.Text = "<s>"..Button.Amount.Text.."</s>"
            else
                Button.MouseButton1Click:Connect(function()
                    MarketplaceService:PromptGamePassPurchase(Player, DonationIds[Button.Name]);
                end);
    
                Button.MouseEnter:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(.25), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0
                    }):Play();
        
                    TweenService:Create(Button.Amount, TweenInfo.new(.3), {
                        TextColor3 = Color3.fromRGB(239, 255, 92),
                    }):Play();
        
                    TweenService:Create(Button.Role, TweenInfo.new(.3), {
                        TextColor3 = Color3.fromRGB(0, 0, 0),
                    }):Play();
                end);
        
                Button.MouseLeave:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(.25), {
                        BackgroundColor3 = Color3.fromRGB(17, 17, 17),
                        BackgroundTransparency = 0.5
                    }):Play();
        
                    TweenService:Create(Button.Amount, TweenInfo.new(.3), {
                        TextColor3 = Color3.fromRGB(85, 255, 127),
                    }):Play();
        
                    TweenService:Create(Button.Role, TweenInfo.new(.3), {
                        TextColor3 = Color3.fromRGB(255, 255, 255),
                    }):Play();
                end);
            end
        end
    end

    local Elements = PageAPI:GetVisibleElements(Page);
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