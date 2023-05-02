--[[

    Name: Mari
    Date: 12/23/2022

    Description: This component strictly handles speaker metadata. None of this is functional without the Channel channel!

]]--

--// Module
local SpeakerMaster = {};
SpeakerMaster.__index = SpeakerMaster

local Speaker = {};
Speaker.__index = Speaker

--// Services
local MarketplaceService = game:GetService("MarketplaceService");
local CollectionService = game:GetService("CollectionService");

--// Imports
local Settings
local ChatTags

local TextStyles
local Channels

local Trace : table < TraceAPI >

--// Constants
local SpeakerAdded = Instance.new("BindableEvent");
local Network

local ChatSpeakers = {};

--// Initialization

function SpeakerMaster:Initialize(Setup : table)
    local self = setmetatable(Setup, SpeakerMaster);

    Settings = self.Settings.Channels
    TextStyles = self.Settings.Styles
    ChatTags = self.Settings.ChatTags

    Network = self.Remotes.Speakers
    Channels = self.Src.Channels

    Trace = self.Trace

    --// Setup
    local function onSocialChatReady(Player : Player)
        SpeakerMaster.new(Player, GetTag(Player));

        for Agent, Speaker in pairs(ChatSpeakers) do -- Register all currently active speakers once our client is ready!
            if (Agent == Player) then continue; end
            Network.EventSpeakerAdded:FireClient(Player, Agent, Speaker.Metadata);
        end
    end

    for _, Player in pairs(CollectionService:GetTagged("SocialChatClientReady")) do
        onSocialChatReady(Player);
    end

    CollectionService:GetInstanceAddedSignal("SocialChatClientReady"):Connect(onSocialChatReady);
    SpeakerMaster.new("SERVER", Settings.ServerTagData);

    return self
end

--// Methods

--- Creates a new Chat speaker
function SpeakerMaster.new(Agent : BasePart | Player | string, TagData : table?) : Speaker
    Trace:Assert(type(Agent) == "string" or typeof(Agent) == "Instance", "The provided speaker agent was not of type \"string\" or \"Instance\"! ( received type: \""..(typeof(Agent)).."\" )");
    Trace:Assert(type(Agent) == "string" or Agent:IsA("Player") or Agent:IsA("BasePart"), "The provided agent Instance was not of class \"Player\" or \"BasePart\"!");
    VerifyMetadata(Agent, TagData);

    if (ChatSpeakers[Agent]) then
        warn("Attempt to recreate a pre-existing chat speaker! ( \""..(tostring(Agent)).."\" is already registed. ) ");
        return;
    end

    local IsInstance = (typeof(Agent) == "Instance");
    local IsPlayer = (IsInstance and Agent:IsA("Player"));

    local Default = (Settings.DefaultTagData); -- This is a new configuration. Some places won't have it yet so we must handle it accordingly
    
    if (not Default) then
        warn("Your version of SocialChat is out-dated! Please update to a more recent version to receive the best from SocialChat v2!");
    end

    local NewSpeaker = setmetatable({

        --// METADATA \\--

        ["Metadata"] = {
            ["Classic"] = {
                ["Tag"] = (TagData and TagData.Classic and TagData.Classic.Tag) or (Default and Default.Classic.Tag),
                ["Content"] = (TagData and TagData.Classic and TagData.Classic.Content) or (Default and Default.Classic.Content),

                ["Username"] = { -- We only go in depth with our username data because the username color is a required dataset
                    ["Name"] = (
                        (IsPlayer and ((Settings.UseDisplayNames and Agent.DisplayName) or Agent.Name)) -- "Agent" is a Player!
                        or (TagData and TagData.Classic and TagData.Classic.Username and TagData.Classic.Username.Name) -- Agent isn't a player (use tagdata instead)
                        or ((Default and Default.Classic.Username.Name)) -- Default Username for non-player appliances
                        or tostring(Agent) -- Agent is not a player AND doesn't have a custom name! (default to it's instance name instead)
                    ),

                    ["Font"] = (TagData and TagData.Classic and TagData.Classic.Username and TagData.Classic.Username.Font) or (Default and Default.Classic.Username.Font),
                    ["Color"] = (TagData and TagData.Classic and TagData.Classic.Username and TagData.Classic.Username.Color) or GetRandomSpeakerColor(),
                };

                ["UserId"] = ((IsPlayer and Agent.UserId) or nil), -- UserId is useful for security cases!
            },

            ["Bubble"] = (TagData and TagData.Bubble) or (Default and Default.Bubble)
        };

        --// PROGRAMMABLE \\--

        ["Channels"] = {}, -- a table of channels that this speaker is in
        ["__previousNameColor"] = nil, -- a Color3 value that recalls the speaker's previous TagColor

        ["Agent"] = Agent, -- For reference
        ["IsPlayer"] = (IsPlayer and Agent:IsA("Player")) -- Tells us if this speaker object pertains to a Player : boolean

    }, Speaker);

    ChatSpeakers[Agent] = NewSpeaker
    SpeakerAdded:Fire(NewSpeaker);

    --// Team Color Appliance \\--
    if (Settings.ApplyTeamColors and IsPlayer) then
        local function ApplyTeamColor()
            if ((NewSpeaker.Metadata.Classic.Username.Color) and (not Settings.TeamColorsOverrideRanks)) then return; end

            if (Agent.Team ~= nil) then -- This Player is now in a team
                NewSpeaker.__previousNameColor = NewSpeaker.Metadata.Classic.Username.Color
                NewSpeaker.Metadata.Classic.Username.Color = Agent.Team.TeamColor.Color
            elseif (NewSpeaker.__previousNameColor) then -- This player is no longer in a team
                NewSpeaker.Metadata.Classic.Username.Color = NewSpeaker.__previousNameColor
            end
        end

        ApplyTeamColor();
        Agent:GetPropertyChangedSignal("Team"):Connect(ApplyTeamColor);
    end

    Network.EventSpeakerAdded:FireAllClients(Agent, NewSpeaker.Metadata);
    return NewSpeaker
end

--- Returns the speaker object for the requested agent
function SpeakerMaster:Get(Agent : string | Player) : Speaker
    Trace:Assert(type(Agent) == "string" or typeof(Agent) == "Instance", "The provided speaker agent was not of type \"string\" or \"Instance\"! ( received type: \""..(typeof(Agent)).."\" )");
    Trace:Assert(type(Agent) == "string" or Agent:IsA("Player"), "The provided agent Instance was not of class \"Player\"! ( got \""..tostring(Agent.ClassName).."\" instead )");
    
    return ChatSpeakers[Agent];
end

--// Functions

--- Returns a random Speaker color
function GetRandomSpeakerColor() : Color3
    if (not Settings.ApplyRandomColorAsDefault) then return Color3.fromRGB(255, 255, 255); end

    if (next(Settings.UsernameColors)) then
        return Settings.UsernameColors[math.random(#Settings.UsernameColors)];
    else
        return BrickColor.random().Color
    end
end

--- Returns the requested player's chat tag
function GetTag(Player : Player)
    local OwnedTag, Priority = nil, math.huge

	--// Find our Players tag
	for _, Tag in pairs(ChatTags) do
		if (Tag.PriorityOrder >= Priority) then continue; end --// Skips this tag if its equal to/over our priority
		local Requirements = Tag.Requirements

		--// Requirement checking
		if (not table.find(Requirements.UserIds, Player.UserId)) then
			if ((Requirements.GroupId > 0) and (Player:IsInGroup(Requirements.GroupId))) then
				local Ranks = Requirements.AcceptedRanks

				if ((not Ranks) or (not next(Ranks))) then
					continue;
				else
					local PlayerRank = Player:GetRankInGroup(Requirements.GroupId);
					local IsOfValidRank
					
					for _, Rank in pairs(Ranks) do --// Go through each valid rank allowed for X tag
						if (PlayerRank >= Rank) then
							IsOfValidRank = true
							break; --// Ends our search here
						end
					end
					
					if (not IsOfValidRank) then continue; end
				end
			else
				continue;
			end
		end

		--// Updating our Data
		OwnedTag = Tag.Metadata
		Priority = Tag.PriorityOrder
	end

    return OwnedTag
end

--- Returns the main channel for the specified speaker
function GetMainChannel(FromSpeaker : Speaker) : Channel
    for _, Name in pairs(FromSpeaker.Channels) do
        local Channel = Channels:Get(Name);

        if (not Channel) then continue; end
        if (not Channel.IsMainChannel) then continue; end

        return Channel
    end
end

--- Verifies the provided metadata (this is purely for debugging)
function VerifyMetadata(Agent : string | Player, Metadata : table) : boolean?
    if (not Metadata) then return; end

    Trace:Assert(type(Metadata) == "table", "The provided metadata was not of type \"table\", but as type \""..(type(Metadata)).."\". Metadata can only be read as a table.");
    Trace:Assert(next(Metadata), "The provided metadata is an empty array. Metadata needs to hold at least one value.");
    Trace:Assert(type(Metadata.Classic) == "table" or type(Metadata.Bubble) == "table", "The provided metadata does not hold any readable information! You must provide at least a \"Classic\" array OR a \"Bubble\" array with your data!");
    
    local function AnalyzeStructure(structureSet : string, fromTable : table, isForPlayer : boolean?)
        if (not fromTable) then return; end

        Trace:Assert(not fromTable.Color or (typeof(fromTable.Color) == "Color3" or type(fromTable.Color) == "string")
        , "The provided \"Color\" Value for \""..(structureSet).."\" was not a \"string\" or \"Color3\"! (received "..(typeof(fromTable.Color))..")");
        
        Trace:Assert(not fromTable.Color or typeof(fromTable.Color) == "Color3" or (type(fromTable.Color) == "string" and TextStyles[fromTable.Color])
        , "The requested color TextStyle \""..(tostring(fromTable.Color)).."\" does not exist! (are you sure you typed the name correctly? This is CASE-SENSITIVE!)");

        Trace:Assert(typeof(fromTable.Font) ~= "EnumItem" or table.find(Enum.Font:GetEnumItems(), fromTable.Font)
        , "The provided EnumItem was not a valid item of \"Font\"! Please set this value as a valid \"Enum.Font\" value!");

        if (isForPlayer and fromTable.Name) then
            warn("The provided username metadata for "..(Agent.Name).." will be used, however, it's \"Name\" value will be ignored for all Player's who use the same metadata. (requested name: \""..(fromTable.Name).."\")");
        end
    end

    if (Metadata.Classic) then
        if (Metadata.Classic.Tag and Metadata.Classic.Tag.Icon) then
            local Icon = Metadata.Classic.Tag.Icon
            Trace:Assert(type(tonumber(Icon)) == "number"
            , "The requested Icon ImageId was not a number! Please provide the asset id of your requested Icon image! (received "..(type(Icon))..")");
            
            local ProductInfo = MarketplaceService:GetProductInfo(Icon);

            if (ProductInfo.AssetTypeId ~= Enum.AssetType.Decal.Value) then
                Trace:Error("The provided Icon AssetId ("..(Icon)..") was not a valid Decal asset! Are you sure this Asset was uploaded as an image?");
            end
        end

        AnalyzeStructure("Tag", Metadata.Classic.Tag);
        AnalyzeStructure("Content", Metadata.Classic.Content);
        AnalyzeStructure("Username", Metadata.Classic.Username, type(Agent) ~= "string");
    end

    if (Metadata.Bubble) then
        AnalyzeStructure("Bubble", Metadata.Bubble);
    end
end

SpeakerMaster.OnSpeakerAdded = SpeakerAdded.Event
return SpeakerMaster