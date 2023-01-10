--[[

    Name: Mari
    Date: 12/22/2022

    Description: This component module handles system channels and system messaging!

]]--

--// Module
local ChannelManager = {};
ChannelManager.__index = ChannelManager

local Channel = {};
Channel.__index = Channel

--// Services
local TextService = game:GetService("TextService");

--// Imports
local Speakers
local Settings

--// Constants
local ClientCooldowns = {};
local SystemChannels = {};

local Network
local General

local MessageEvent = Instance.new("BindableEvent");

--// Initialization

function ChannelManager:Initialize(Setup : table)
    local self = setmetatable(Setup, ChannelManager);

    Speakers = self.Src.Speakers
    Settings = self.Settings.SystemChannelSettings
    Network = self.Remotes.Channels

    --// Setup

    local ChannelTest = ChannelManager:Create("TestChannel");

    General = ChannelManager:Create("General"); -- We need at least ONE system channel for our main messages to go through
    General.IsMainChannel = true -- You can't leave the main channel

    local function onSpeakerReady(Player : Player)
        ClientCooldowns[Player] = Settings.MessageRate

        General:Subscribe(Player);
        ChannelTest:Subscribe(Player);
    end

    for _, Player in pairs(game.Players:GetPlayers()) do
        local Speaker = Speakers:GetSpeaker(Player);
        if (not Speaker) then continue; end -- The player is NOT ready yet

        onSpeakerReady(Player);
    end

    Speakers.OnSpeakerAdded:Connect(function(Agent : string | Player, Speaker : Speaker)
        if (typeof(Agent) ~= "Instance") then return; end
        onSpeakerReady(Agent);
    end)

    --// Event Handling

    Network.EventSendMessage.OnServerEvent:Connect(function(Player : Player, Message : string, Recipient : string | Player)
        if (type(Recipient) ~= "string" and typeof(Recipient) ~= "Instance") then return; end -- The provided recipient is not an acceptable type of parameter
        if ((type(Recipient) == "string") and (not ChannelManager:Get(Recipient))) then return; end -- The client requested a Channel recipient that doesnt exist!
        if ((typeof(Recipient) == "Instance") and (not Player:IsA("Player"))) then return; end -- The client requested a non-player object

        local RecievingChannel = ((type(Recipient) == "string") and (ChannelManager:Get(Recipient)));
        ChannelManager:Message(Player, Message, RecievingChannel or Recipient);
    end);

    return self
end

--// Methods

--- Creates a new Channel
function ChannelManager:Create(name : string) : Channel
    assert(type(name) == "string", "Expected a \"string\" to use as a channel name. Received \""..(type(name)).."\" instead!");
    assert(not SystemChannels[name], "A channel with the name \""..(name).."\" already exists!");

    local NewSystemChannel = setmetatable({

        --// PROPERTIES \\--

        ["Members"] = {},
        ["Name"] = name,

        --// PROGRAMMABLE \\--

        ["_cache"] = {}

    }, Channel);

    SystemChannels[name] = NewSystemChannel
    return NewSystemChannel
end

--- Returns the requested channel based on it's name ( NOTE: THIS IS CASE SENSITIVE )
function ChannelManager:Get(query : string) : Channel
    assert(type(query) == "string", "Expected a \"string\" to use as a channel query. Received \""..(type(query)).."\" instead!");
    return SystemChannels[query];
end

--- Sends a new message to the specified recipient using the provided parameters
function ChannelManager:Message(Author : Player, Message : string, Recipient : Player | Channel)
    local Speaker = Speakers:GetSpeaker(Author);
    if (not Speaker) then return; end

    if (utf8.len(Message) > Settings.MaxMessageLength) then -- This message is ABOVE our message string limit!
        Network.EventSendMessage:FireClient(
            Author,
            "Messages are not allowed to be over "..(Settings.MaxMessageLength).." characters long!",
            Recipient, -- Usually a channel but sometimes this will be a player. Either way, our client can handle the backend work for this
            {
                ["MessageColor"] = Settings.ServerErrorColor
            }
        );

        return;
    end

    if (ClientCooldowns[Author] <= 0) then -- This author is currently rate limited ( CANCEL )
        Network.EventSendMessage:FireClient(
            Author,
            "You're sending messages too quickly!",
            Recipient,
            {
                ["MessageColor"] = Settings.ServerErrorColor
            }
        );

        return;
    end

    --// Cooldown Management
    --\\ We need to handle cooldowns here in order to prevent the client from spam messaging our channels!

    ClientCooldowns[Author] -= 1

    coroutine.wrap(function()
        task.wait(10);
        ClientCooldowns[Author] += 1
    end)();

    --// Message Filtering
    --\\ We need to filter our message to abide by Roblox's TOS

    local Success, Response = pcall(function()
        return TextService:FilterStringAsync(Message, Author.UserId);
    end);

    if (Success) then -- We successfully filtered our message!
        if (typeof(Recipient) == "Instance") then -- This message is for a PRIVATE client
            Network.EventSendMessage:FireClient(Recipient, GetFilteredMessageForClient(Response, Recipient), Author, Speaker.Metadata);
            Network.EventSendMessage:FireClient(Author, GetFilteredMessageForClient(Response, Author), Recipient, Speaker.Metadata, true);
        else -- This message is for a specific channel
            for Member, _ in pairs(Recipient.Members) do
                local FilterSuccess, FilterResponse = pcall(function()
                    return GetFilteredMessageForClient(Response, Member);
                end); -- Sometimes filtering can error in some cases. Due to this fact, we want to stop errors from breaking the loop

                if (not FilterSuccess) then continue; end
                Network.EventSendMessage:FireClient(Member, FilterResponse, Recipient, Speaker.Metadata);
            end
    
            if (#Recipient._cache >= Settings.MaxMessagesPerChannel) then
                table.remove(Recipient._cache, 1); -- The oldest message will always be our 1st Index
            end

            table.insert(Recipient._cache, {
                ["Author"] = Author, -- string | Player
                ["Message"] = Message, -- string
                ["AtTime"] = os.clock() -- number
            });
        end
    else -- Oh no! Filtering failed :(
        Network.EventSendMessage:FireClient(
            Author,
            {
                ["MessageColor"] = Settings.ServerErrorColor
            },
            "Your message failed to send due to a server error! ( ERROR: \""..(Response or "No feedback was given").."\" )"
        );

        error("Failed to filter message for \""..(Author.Name).."\"! ( Response: \""..(Response or "No response provided.").."\" )");
    end

    MessageEvent:Fire(Author, Message, Recipient); -- API Event callback
end

--// Metamethods

--- Adds the specified member into the channel
function Channel:Subscribe(Player : Player)
    assert(typeof(Player) == "Instance", "Expected an \"Instance\" as a valid member! ( received \""..(typeof(Player)).."\" )");
    assert(Player:IsA("Player"), "The provided Instance was not of class \"Player\". Got \""..(Player.ClassName).."\" instead");

    local Speaker = Speakers:GetSpeaker(Player);
    if (self.Members[Player]) then return; end -- This client is already in this channel

    self.Members[Player] = Speaker
    table.insert(Speaker.Channels, self.Name);

    Network.EventJoinChannel:FireClient(Player, self.Name, self.Members, self._cache);
end

--- Removes the specified member from the channel
function Channel:Unsubscribe(Player : Player)
    assert(typeof(Player) == "Instance", "Expected an \"Instance\" as a valid member! ( received \""..(typeof(Player)).."\" )");
    assert(Player:IsA("Player"), "The provided Instance was not of class \"Player\". Got \""..(Player.ClassName).."\" instead");

    local Speaker = Speakers:GetSpeaker(Player);
    if (not self.Members[Player]) then return; end -- This client isnt even in this channel! (we can just cancel the request here)

    self.Members[Player] = nil
    table.remove(Speaker.Channels, table.find(Speaker.Channels, self.Name));

    Network.EventLeaveChannel:FireClient(Player, self.Name);
end

--- Destroys the requested Channel
function Channel:Destroy()
    assert(not self.IsMainChannel, "Failed to destroy Channel \""..(self.Name).."\". Destroying the game's main chat channel would result in bugs!");

    for _, Member in pairs(self.Members) do
        self:Unsubscribe(Member);
    end

    self = nil
end

--// Functions

--- Returns the filtered message for the specified client
function GetFilteredMessageForClient(FilterObject : Instance, Client : Player) : string
    local FilterSuccess, FilterResponse = pcall(function()
        return FilterObject:GetChatForUserAsync(Client.UserId);
    end);

    if (FilterSuccess) then
        return FilterResponse
    else
        error("Failed to process filter for \""..(Client.Name).."\"! ( Response: \""..(FilterResponse or "No response was given").."\" )");
    end
end

ChannelManager.OnMessageSent = MessageEvent.Event -- function( Author : string | Player, Message : string, Recipient : Player | Channel ) [ NOTE: MESSAGE IS NOT FILTERED ]
return ChannelManager