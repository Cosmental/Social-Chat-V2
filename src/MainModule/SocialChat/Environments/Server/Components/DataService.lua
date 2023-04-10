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
local DataStore = DataStoreService:GetDataStore("SocialChatData");

--// Constants
local MAX_CLIENT_YIELD_TIME = 3
local Network

--// Imports
local Trace : table < TraceAPI >

--// States
local UserData = {};

--// Initialization
function DataService:Initialize(Setup : table)
    local self = setmetatable(Setup, DataService);

    Network = self.Remotes.DataService
    Trace = self.Trace

    --// API-Access Enabled verification
    --\\ Roblox disables this by default, hence why we have to pass a value onto the developer in-case if they forget
    
    local DataStoresEnabled : boolean? = IsAPIEnabled();

    if (not DataStoresEnabled) then
        warn("DataStores are not currently enabled! This will not allow any data to be stored, and users must configure SocialChat upon joining everytime.\n\t\t\t\t\t\t\t\t\tYou can enable this feature in 'Game Settings -> Security -> Enable Studio Access to API Services'.")
    end
    
    --// Data Setup
    local Structure : table = GetDefaultStructure(self.Settings, self.__extensionData);

    local function Setup(Player : Player)
        local Success, Response = pcall(function()
            return DataStore:GetAsync(Player.UserId);
        end);

        local Data = Structure

        if (Success) then -- NOTE: If Data fails to load, the System will NOT store the user's data. This is to prevent changes in case of Roblox Servers being down and potentially losing data due to corruption
            Data = (Response or Structure);
            UserData[Player] = Data
        elseif (DataStoresEnabled) then
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
    Network.EventDataEntry.OnServerEvent:Connect(function(Player : Player, Path : string, Data : any?)
        if (not self:GetData(Player)) then return; end
        
        local TreeItem : any = UserData[Player];

        for _, Trace in pairs(Path:split("/")) do
            TreeItem = TreeItem[Trace]; -- Keep digging for our value! If it doesnt exist, this will error
        end

        local ValidEntryType = typeof((TreeItem.Default) or (TreeItem.StrictType));
        if (ValidEntryType == 'nil') then return; end -- This isnt an existing entry type and/or doesn't follow the proper structure!
        Trace:Assert(typeof(Data) == ValidEntryType, Player.Name.." submitted a type mismatch for path: '"..(Path).."'! (this TreeItem requires a value type of '"..(ValidEntryType).."')");
        
        TreeItem["Value"] = Data
    end);

    Network.EventReplicateData.OnServerInvoke = function(Player : Player)
        local Start = os.clock();
        local TimedOut : boolean?

        repeat
            TimedOut = ((os.clock() - Start) >= MAX_CLIENT_YIELD_TIME);
            task.wait();
        until
        ((self:GetData(Player)) or (TimedOut));

        return (self:GetData(Player) or Structure), (TimedOut or not DataStoresEnabled) -- In case of data loading failure, SocialChat will resort to it's default data!
    end

    return self
end

--// Methods

--- Returns the requested data for the specified player (if any)
function DataService:GetData(Player : Player) : table?
    Trace:Assert(typeof(Player) == "Instance", "The provided 'Player' was not of type \"Instance\". (received \""..(typeof(Player)).."\")");
    Trace:Assert(Player:IsA("Player"), "The provided Instance was not of class 'Player'! (received \""..(Player.ClassName).."\")");

    return UserData[Player]; -- NOTE: This can be nil if the server didn't properly load the players data!
end

--// Functions

--- This tells us if API-Access is enabled or not
function IsAPIEnabled() : boolean?
	local Success, Response = pcall(function()
		return DataStoreService:GetDataStore("__API-ENABLED-TEST"):SetAsync("__API-TEST", true);
	end);
	
	if (not Success and Response:find("403")) then
		return false
	else
		return true;
	end
end

--- This is a function simply because I don't want to read all of this within the 'Initialization' Method
function GetDefaultStructure(Settings : table, ExtensionData : table?)
    local BubbleChatDefaults = Settings.BubbleChat
    local ClientChannels = Settings.Client.Channels

    local Structure = {

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

        ["Extensions"] = {}; -- SOLELY FOR EXTENSIONS! DO NOT USE OTHERWISE

    };

    for Extension : string, Data : table in pairs(ExtensionData) do
        Structure.Extensions[Extension] = Data
    end

    return Structure
end

return DataService