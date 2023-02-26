--// Imports
local self : table?

local BubbleChatSettings : table?
local ChatFrameSettings : table?

--// Constants
local InteractionTypes = {
    Button = "Button",
    Slider = "Slider"
};

local Metadata = {
    Button = {
        ["Active"] = {
            StrokeColor = Color3.fromRGB(255, 255, 255),
            ButtonColor = Color3.fromRGB(0, 170, 255),
            
            StrokeTransparency = 0,
            ButtonTransparency = 0
        };

        ["Inactive"] = {
            StrokeColor = Color3.fromRGB(255, 255, 255),
            ButtonColor = Color3.fromRGB(0, 170, 255),
            
            StrokeTransparency = 0.5,
            ButtonTransparency = 0.5
        };

        ["Tween"] = {
            Speed = 0.5,
            EasingStyle = Enum.EasingStyle.Exponential
        }
    };

    ["Slider"] = {
        SocketColor = Color3.fromRGB(255, 255, 255),
        SliderColor = Color3.fromRGB(210, 210, 210),
    };
};

--// Module
local Structure = {
    ["Chat Frame"] = {
        ["Icon"] = {
            ImageId = "rbxassetid://3926305904",
            ImageRectSize = Vector2.new(36, 36),
            ImageRectOffset = Vector2.new(404, 124),
        };

        ["Options"] = {
            ["HideChatFrame"] = {
                Name = "Hide Chat Frame",
                Info = "This will hide the ChatFrame leaving only the InputBox available! If the ChatFrame becomes hidden then you may only communicate through ChatBubbles!",
                Type = InteractionTypes.Button,
                
                Order = 1,
                Metadata = Metadata.Button,

                OnUpdated = function(Value : boolean)
                    ChatFrameSettings.HideChatFrame = Value
                    self.Src.ChatUIManager:SetMode(Value);
                end
            };

            ["IdleTime"] = {
                Name = "Chat Fade Time",
                Info = "This will determine the amount of time that can pass before the ChatFrame fades away until its interacted with again!",
                Type = InteractionTypes.Slider,
                
                Order = 2,
                Metadata = {
                    Appearance = Metadata.Slider,
                    Range = NumberRange.new(0, 30)
                };

                OnUpdated = function(Value : number)
                    ChatFrameSettings.IdleTime = Value
                end
            };

            ["MaxFontSize"] = {
                Name = "Max Font Size",
                Info = "This will determine the default FontSize of messages that get rendered! This configuration will get bypassed if a user with custom SpeakerData uses the chat system!",
                Type = InteractionTypes.Slider,
                
                Order = 3,
                Metadata = {
                    Appearance = Metadata.Slider,
                    Range = NumberRange.new(4, 35) -- Realistically, '35' is essentially the biggest FontSize a player will ever need to use
                };

                OnUpdated = function(Value : number)
                    ChatFrameSettings.MaxFontSize = Value
                end
            };

            ["MaxRenderableMessages"] = {
                Name = "Max Renderable Messages",
                Info = "This will determine how many messages can be rendered within the ChatFrame. Lower amounts usually provide better performance!",
                Type = InteractionTypes.Slider,
                
                Order = 4,
                Metadata = {
                    Appearance = Metadata.Slider,
                    Range = NumberRange.new(10, 250)
                };

                OnUpdated = function(Value : number)
                    ChatFrameSettings.MaxRenderableMessages = Value
                end
            };
        };
    };

    ["Bubble Chat"] = {
        ["Icon"] = {
            ImageId = "rbxassetid://3926305904",
            ImageRectSize = Vector2.new(36, 36),
            ImageRectOffset = Vector2.new(644, 324),
        };

        ["Options"] = {
            ["IsBubbleChatEnabled"] = {
                Name = "Bubble Chat Enabled",
                Info = "This will determine whether or not BubbleChat will be used.",
                Type = InteractionTypes.Button,
                
                Order = 1,
                Metadata = Metadata.Button,

                OnUpdated = function(Value : boolean)
                    BubbleChatSettings.IsBubbleChatEnabled = Value

                    local Controllers = self.Src.BubbleChat:GetControllers();

                    for _, Player in pairs(game.Players:GetPlayers()) do
                        local API = Controllers[Player];
                        if (not API) then continue; end

                        for _, Bubble in pairs(API.RenderedBubbles) do
                            Bubble.Render.Visible = Value
                        end

                        API:SetActive(API.IsActive and Value);
                        API:SetThinking(API.IsThinking and Value);
                    end
                end
            };

            ["ChatBubbleLifespan"] = {
                Name = "Chat Bubble Lifespan",
                Info = "This will determine how long a Chat Bubble can last before it vanishes. (in seconds)",
                Type = InteractionTypes.Slider,
                
                Order = 2,
                Metadata = {
                    Appearance = Metadata.Slider,
                    Range = NumberRange.new(1, 30)
                };

                OnUpdated = function(Value : number)
                    ChatFrameSettings.ChatBubbleLifespan = Value
                    self.Src.BubbleChat:Adjust("ChatBubbleLifespan", Value);
                end
            };

            ["MaxDisplayableBubbles"] = {
                Name = "Maximum Bubbles Per Individual",
                Info = "This will determine how many ChatBubbles can be rendered over a given individual. (recommended: 3)",
                Type = InteractionTypes.Slider,
                
                Order = 3,
                Metadata = {
                    Appearance = Metadata.Slider,
                    Range = NumberRange.new(1, 10)
                };

                OnUpdated = function(Value : number)
                    ChatFrameSettings.MaxDisplayableBubbles = Value
                    self.Src.BubbleChat:Adjust("MaxDisplayableBubbles", Value);
                end
            };
        };
    };
};

--// Initialization
local function Init(Controller : table)
    self = Controller

    BubbleChatSettings = self.Settings.BubbleChat
    ChatFrameSettings = self.Settings.Channels

    return Structure
end

return Init