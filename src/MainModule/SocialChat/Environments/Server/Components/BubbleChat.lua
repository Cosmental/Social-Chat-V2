--[[

    Name: Mari
    Date: 1/16/2022

    Description: This server component handle's BubbleChat functuality! This is completely self-reliant and serves no real purpose within
    vanilla SocialChat. You can completely disable this component via the "BubbleChat" Settings module.

]]--

--// Module
local BubbleChat = {};
BubbleChat.__index = BubbleChat

--// Imports
local Settings

--// Constants
local Network

--// Initialization

function BubbleChat:Initialize(Setup : table)
    local self = setmetatable(Setup, BubbleChat);
   
    Network = self.Remotes.BubbleChat
    Settings = self.Settings.BubbleChat

    if (not Settings.IsBubbleChatEnabled) then return self; end

    --// Events
    Network.UpdateTypingState.OnServerEvent:Connect(function(Player : Player, State : boolean)
        if (type(State) ~= "boolean") then return; end -- We dont want players sending unwanted data to each other!
        
        for _, Client in pairs(game.Players:GetPlayers()) do
            if (Client == Player) then continue; end
            Network.UpdateTypingState:FireClient(Client, Player, State); -- Fire this event for everyone BUT our remote executor. Client's handle their own chat bubbles!
        end
    end);

    return self
end

function BubbleChat:Chat(Agent : Instance | Player, Message : string)
    for _, Player in pairs(game.Players:GetPlayers()) do
        if ((typeof(Agent) == "Instance" and Agent:IsA("Player")) and (Agent == Player)) then continue; end
        Network.EventRenderBubble:FireClient(Player, Agent, Message);
    end
end

return BubbleChat