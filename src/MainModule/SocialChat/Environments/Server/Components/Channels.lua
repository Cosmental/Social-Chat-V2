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
local CollectionService = game:GetService("CollectionService");
local TextService = game:GetService("TextService");

--// Imports
local BubbleChatSettings
local Settings

local ChatTags
local Speakers

--// Constants
local ClientCooldowns = {};
local SystemChannels = {};

local BubbleChatEvent
local DefaultChannel

local MessageEvent = Instance.new("BindableEvent");
local Network

local ServerErrorMetadata : table?
local LastServerDownError = 0

--// Initialization

function ChannelManager:Initialize(Setup : table)
    local self = setmetatable(Setup, ChannelManager);

    Speakers = self.Src.Speakers
    ChatTags = self.Settings.ChatTags

    Settings = self.Settings.Channels
    BubbleChatSettings = self.Settings.BubbleChat

    BubbleChatEvent = self.Remotes.BubbleChat.EventRenderBubble
    Network = self.Remotes.Channels

    --// Setup

    ServerErrorMetadata = {
        ["Classic"] = {
            ["Content"] = {
                ["Color"] = Settings.ServerErrorColor
            };
        };
    };

    DefaultChannel = ChannelManager:Create(Settings.DefaultChannel); -- We need at least ONE system channel for our main messages to go through
    DefaultChannel.IsMainChannel = true -- You can't leave the main channel

    local function OnSpeakerReady(Player : Player)
        ClientCooldowns[Player] = Settings.MessageRate
        DefaultChannel:Subscribe(Player);
    end

    for _, Player in pairs(game.Players:GetPlayers()) do
        local Speaker = Speakers:GetSpeaker(Player);
        if (not Speaker) then continue; end -- The player is NOT ready yet

        OnSpeakerReady(Player);
    end

    Speakers.OnSpeakerAdded:Connect(function(Agent : string | Player)
        if (typeof(Agent) ~= "Instance") then return; end
        OnSpeakerReady(Agent);
    end)

    --// Event Handling

    Network.EventSendMessage.OnServerEvent:Connect(function(Player : Player, Message : string, Recipient : string | Player)
        if (type(Recipient) ~= "string" and typeof(Recipient) ~= "Instance") then return; end -- The provided recipient is not an acceptable type of parameter
        if ((type(Recipient) == "string") and (not ChannelManager:Get(Recipient))) then return; end -- The client requested a Channel recipient that doesnt exist!
        if ((typeof(Recipient) == "Instance") and (not Player:IsA("Player"))) then return; end -- The client requested a non-player object

        local RecievingChannel = ((type(Recipient) == "string") and (ChannelManager:Get(Recipient)));
        ChannelManager:Message(Player, Message, RecievingChannel or Recipient);
    end);

    --// Hooking onto SystemAlert RBXScriptSignals

    local AlertEvents = Settings.AlertEvents

    for AlertType, Info in pairs(Settings.SystemAlerts) do
        if (AlertType == "__example") then continue; end -- This event is the example event! (skip)
        if (not Info.Enabled) then continue; end -- This event is not active! (skip)

        assert(Info.Event, "SocialChat Channel Settings Misconfiguration: \'"..(AlertType).."\' is not connected to any Events! This message will never submit itself without an event!");

        local Signal : callback? = ((Info.Event.Signal) or (AlertEvents[Info.Event.HookTo].Signal));
        local TagData : table? = (ChatTags[Info.Tag] or {["Classic"] = {}});
        TagData.BypassMarkdownSetting = true

        assert(Signal, "SocialChat Channel Settings Misconfiguration: \'"..(AlertType).."\' does not have a signal to connect to!");
        assert(Info.Event.Trigger, "SocialChat Channel Settings Misconfiguration: \'"..(AlertType).."\' does not have a 'trigger' to fire from!");
        
        local function SendMessage(Recipients : table, Parameters : table)
            local Message = Info.Message

            for _, Param in pairs(Parameters) do
                local Starts, Ends = Message:find("%%s");
                if (not Starts) then continue; end -- No more '%s' occurences!

                Message = (
                    Message:sub(0, Starts - 1)..
                    tostring(Param)..
                    Message:sub(Ends + 1)
                );
            end

            for _, Player in pairs(Recipients) do
                coroutine.wrap(function()
                    if (not CollectionService:HasTag(Player, "SocialChatClientReady")) then
                        repeat -- I heavily dislike this method of yielding, but due to its functuality in this case, I'll let it slide
                            task.wait();
                        until
                        (CollectionService:HasTag(Player, "SocialChatClientReady")); -- Sometimes our client won't be loaded yet, so we should yield until then!
                    end
                
                    Network.EventSendMessage:FireClient(
                        Player,
                        Message,
                        DefaultChannel,
                        TagData
                    );
                end)();
            end
        end

        Signal(Info.Event.Trigger, SendMessage);
    end

    return self
end

--// Methods

--- Creates a new Channel
function ChannelManager:Create(Name : string) : Channel
    assert(type(Name) == "string", "Expected a \"string\" to use as a channel name. Received \""..(type(Name)).."\" instead!");
    assert(not SystemChannels[Name], "A channel with the name \""..(Name).."\" already exists!");

    local NewSystemChannel = setmetatable({

        --// PROPERTIES \\--

        ["Members"] = {},
        ["Name"] = Name,

        --// PROGRAMMABLE \\--

        ["_cache"] = {}

    }, Channel);

    SystemChannels[Name] = NewSystemChannel
    return NewSystemChannel
end

--- Returns the requested channel based on it's name ( NOTE: THIS IS CASE SENSITIVE )
function ChannelManager:Get(Query : string) : Channel
    assert(type(Query) == "string", "Expected a \"string\" to use as a channel query. Received \""..(type(Query)).."\" instead!");
    return SystemChannels[Query];
end

--- Sends a new message to the specified recipient using the provided parameters
function ChannelManager:Message(Author : Player, Message : string, Recipient : Player | Channel)
    local Speaker = Speakers:GetSpeaker(Author);

    if (not Speaker) then return; end
    if (ChannelManager.ProcessMessage and not ChannelManager.ProcessMessage(Author, Message, Speaker)) then return; end

    if (utf8.len(Message) > Settings.MaxMessageLength) then -- This message is ABOVE our message string limit!
        Network.EventSendMessage:FireClient(
            Author,
            "Messages are not allowed to be over "..(Settings.MaxMessageLength).." characters long!",
            Recipient, -- Usually a channel but sometimes this will be a player. Either way, our client can handle the backend work for this
            ServerErrorMetadata
        );

        return;
    end

    if (ClientCooldowns[Author] <= 0) then -- This author is currently rate limited ( CANCEL )
        Network.EventSendMessage:FireClient(
            Author,
            "You're sending messages too quickly!",
            Recipient,
            ServerErrorMetadata
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
            local RecipientFilter = GetFilteredMessageForClient(Response, Recipient);
            local AuthorFilter = GetFilteredMessageForClient(Response, Author);

            Network.EventSendMessage:FireClient(Recipient, RecipientFilter, Author, Speaker.Metadata);
            Network.EventSendMessage:FireClient(Author, AuthorFilter, Recipient, Speaker.Metadata);
            
            if (BubbleChatSettings.IsBubbleChatEnabled) then
                BubbleChatEvent:FireClient(Author, Author, AuthorFilter, Speaker.Metadata);
                BubbleChatEvent:FireClient(Recipient, Author, RecipientFilter, Speaker.Metadata);
            end
        else -- This message is for a specific channel
            for Member, _ in pairs(Recipient.Members) do
                local FilterSuccess, FilterResponse = pcall(function()
                    return GetFilteredMessageForClient(Response, Member);
                end); -- Sometimes filtering can error in some cases. Due to this fact, we want to stop errors from breaking the loop

                if (not FilterSuccess) then continue; end

                Network.EventSendMessage:FireClient(Member, FilterResponse, Recipient, Speaker.Metadata);
                BubbleChatEvent:FireClient(Member, Author, FilterResponse, Speaker.Metadata);
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
            Recipient,
            "Your message failed to send due to a server error! (ERROR: \""..(Response or "No feedback was given").."\")",
            ServerErrorMetadata
        );

        error("Failed to filter message for \""..(Author.Name).."\"! (Response: \""..(Response or "No response provided.").."\")");
    end

    MessageEvent:Fire(Author, Message, Recipient); -- API Event callback
end

--// Metamethods

--- Adds the specified member into the channel
function Channel:Subscribe(Player : Player)
    assert(typeof(Player) == "Instance", "Expected an \"Instance\" as a valid member! (received \""..(typeof(Player)).."\")");
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
    local StartTick = os.clock();
    local FilterSuccess, FilterResponse = pcall(function()
        return FilterObject:GetChatForUserAsync(Client.UserId);
    end);

    local ProcessingTime = (os.clock() - StartTick);

    if ((ProcessingTime >= 5) and (os.clock() - LastServerDownError) >= 60) then -- It should NOT take our server 5 seconds to filter a singular message!
        Network.EventSendMessage:FireAllClients(
            "Roblox servers are currently experiencing issues when filtering messages.",
            DefaultChannel,
            ServerErrorMetadata
        );

        LastServerDownError = os.clock();
    end

    if (FilterSuccess) then
        return FilterResponse
    else
        error("Failed to process filter for \""..(Client.Name).."\"! ( Response: \""..(FilterResponse or "No response was given").."\" )");
    end
end

ChannelManager.OnMessageSent = MessageEvent.Event -- function( Author : string | Player, Message : string, Recipient : Player | Channel ) [ NOTE: MESSAGE IS NOT FILTERED ]
ChannelManager.ProcessMessage = nil -- This can be set as a function that handles message processing! (can only be used by one thread)

return ChannelManager