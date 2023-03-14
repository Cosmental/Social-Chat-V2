--[[

    Name: Mari
    Date: 2/22/2022

    Description: This component stores ServerData from SocialChat. The API is strict with types which makes it easier to debug issues.
    ONLY use this for SocialChat related data! It is not recommended to use this API for other non-SocialChat related data as the terminal
    may be able to access your data which can be sensitive/crucial to individuals!

]]--

--// Module
local DataService = {};
DataService.__index = DataService

--// Services
local DataStoreService = game:GetService("DataStoreService");
local DataStore = DataStoreService:GetDataStore("SocialChatData", "_test-4");

--// Constants
local MAX_CLIENT_YIELD_TIME = 3
local Network

--// States
local UserData = {};

--// Initialization
function DataService:Initialize(Setup : table)
    local self = setmetatable(Setup, DataService);

    Network = self.Remotes.DataService
    
    --// Data Setup
    local Structure = GetStructure(self.Settings);

    local function Setup(Player : Player)
        local Success, Response = pcall(function()
            return DataStore:GetAsync(Player.UserId);
        end);

        local Data = Structure

        if (Success) then -- NOTE: If Data fails to load, the System will NOT store the user's data. This is to prevent changes in case of Roblox Servers being down and potentially losing data due to corruption
            Data = (Response or Structure);
            UserData[Player] = Data
        else
            warn("SocialChat DataService Failed to preload data for user \""..(Player.Name).."\"! (Server Response: "..(Response)..")");
        end
    end

    for _, Player in pairs(game.Players:GetPlayers()) do
        Setup(Player);
    end

    game.Players.PlayerAdded:Connect(Setup);

    --// Data Saving
    local function OnPlayerRemoved(Player : Player)
        if (not self:GetData(Player)) then return; end

        local Success, Response = pcall(function()
            DataStore:UpdateAsync(Player.UserId, function()
                return UserData[Player];
            end);
        end);

        if (not Success) then
            warn("SocialChat DataService Failed to save data for \""..(Player.Name).."\"! (Response: "..(Response)..")");
        end
    end

    game:BindToClose(function()
        for _, Player in pairs(game.Players:GetPlayers()) do
            OnPlayerRemoved(Player);
        end
    end);

    game.Players.PlayerRemoving:Connect(OnPlayerRemoved);

    --// Events
    Network.EventDataEntry.OnServerEvent:Connect(function(Player : Player, Category : string, Entry : string, Data : any?)
        if (not self:GetData(Player)) then return; end
        
        assert(type(Category) == "string", Player.Name.." attempted to request a data category that wasn't via of type 'string'. (received \""..(type(Category)).."\")");
        assert(type(Entry) == "string", Player.Name.." requested an entry key that wasn't of type 'string'. (received \""..(type(Entry)).."\")");

        assert(UserData[Player][Category], Player.Name.." requested non-existant category \""..(Category).."\".");
        assert(UserData[Player][Category][Entry], Player.Name.." submitted data to a non-existing entry \""..(Entry).."\" for category \""..(Category).."\".");
        
        local ValidEntryType = (typeof((UserData[Player][Category][Entry].Default) or (UserData[Player][Category][Entry].StrictType)));
        assert(typeof(Data) == ValidEntryType, Player.Name.." submitted a type mismatch for entry \""..(Entry).."\" in category \""..(Category).."\"! (this entry requires a value type of '"..(ValidEntryType).."')");

        UserData[Player][Category][Entry]["Value"] = Data
    end);

    Network.EventReplicateData.OnServerInvoke = function(Player : Player)
        local Start = os.clock();
        local TimedOut : boolean?

        repeat
            TimedOut = ((os.clock() - Start) >= MAX_CLIENT_YIELD_TIME);
            task.wait();
        until
        ((self:GetData(Player)) or (TimedOut));

        return (self:GetData(Player) or Structure), TimedOut -- In case of data loading failure, SocialChat will resort to it's default data!
    end

    return self
end

--// Methods

--- Returns the requested data for the specified player (if any)
function DataService:GetData(Player : Player) : table?
    assert(typeof(Player) == "Instance", "The provided 'Player' was not of type \"Instance\". (received \""..(typeof(Player)).."\")");
    assert(Player:IsA("Player"), "The provided Instance was not of class 'Player'! (received \""..(Player.ClassName).."\")");

    return UserData[Player]; -- NOTE: This can be nil if the server didn't properly load the players data!
end

--// Functions

--- This is a function simply because I don't want to read all of this within the 'Initialization' Method
function GetStructure(Settings : table)
    local BubbleChatDefaults = Settings.BubbleChat
    local ClientChannels = Settings.Client.Channels

    return {

        ["Settings"] = {

            --// BUBBLE CHAT

            ["IsBubbleChatEnabled"] = {
                Default = BubbleChatDefaults.IsBubbleChatEnabled, -- This is the DEFAULT value for this dataset
                Locked = false -- If true, the server will not allow players to configure this setting themselves!
            },

            ["MaxDisplayableBubbles"] = {
                Default = BubbleChatDefaults.MaxDisplayableBubbles,
                Locked = false
            },

            ["ChatBubbleLifespan"] = {
                Default = BubbleChatDefaults.ChatBubbleLifespan,
                Locked = false
            },

            --// CHANNELS
            ["MaxRenderableMessages"] = {
                Default = ClientChannels.MaxRenderableMessages,
                Locked = false
            },

            ["IdleTime"] = { -- WARNING: ChannelSettings MUST be named according to their Index values! This is because our client literally applies the setting within its module in REAL time!
                Default = ClientChannels.IdleTime,
                Locked = false
            },

            ["MaxFontSize"] = {
                Default = ClientChannels.MaxFontSize,
                Locked = false
            },

            ["HideChatFrame"] = {
                StrictType = ClientChannels.HideChatFrame,
                Locked = true
            },

        };

    };
end

return DataService