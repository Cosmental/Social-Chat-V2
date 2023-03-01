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
function SpeakerMaster.new(Agent : string | Player, TagData : table?) : Speaker
    assert(type(Agent) == "string" or typeof(Agent) == "Instance", "The provided speaker agent was not of type \"string\" or \"Instance\"! ( received type: \""..(typeof(Agent)).."\" )");
    assert(type(Agent) == "string" or Agent:IsA("Player"), "The provided agent Instance was not of class \"Player\"!");
    VerifyMetadata(Agent, TagData);

    if (ChatSpeakers[Agent]) then
        warn("Attempt to recreate a pre-existing chat speaker! ( \""..(tostring(Agent)).."\" is already registed. ) ");
        return;
    end

    local NewSpeaker = setmetatable({

        --// METADATA \\--

        ["Metadata"] = {
            ["Classic"] = {
                ["Tag"] = (TagData and TagData.Classic.Tag) or nil,
                ["Content"] = (TagData and TagData.Classic.Content) or nil,

                ["Username"] = { -- We only go in depth with our username data because the username color is a required dataset
                    ["Name"] = (
                        ((typeof(Agent) == "Instance") and ((Settings.UseDisplayNames and Agent.DisplayName) or Agent.Name)) -- "Agent" is a Player!
                        or Agent -- "Agent" is a string!
                    ),

                    ["Font"] = (TagData and TagData.Classic.Username and TagData.Classic.Username.Font) or nil,
                    ["Color"] = (TagData and TagData.Classic.Username and TagData.Classic.Username.Color) or GetRandomSpeakerColor(),
                };

                ["UserId"] = ((typeof(Agent) == "Instance" and Agent.UserId) or nil), -- UserId is useful for security cases!
            },

            ["Bubble"] = (TagData and TagData.ChatBubble) or nil
        };

        --// PROGRAMMABLE \\--

        ["Channels"] = {}, -- a table of channels that this speaker is in
        ["__previousNameColor"] = nil, -- a Color3 value that recalls the speaker's previous TagColor

    }, Speaker);

    ChatSpeakers[Agent] = NewSpeaker
    SpeakerAdded:Fire(Agent, NewSpeaker);

    --// Team Color Appliance \\--
    if (Settings.ApplyTeamColors and typeof(Agent) == "Instance") then
        Agent:GetPropertyChangedSignal("Team"):Connect(function()
            if (Agent.Team ~= nil) then -- This Player is now in a team
                NewSpeaker.__previousNameColor = NewSpeaker.TagData.NameColor
                NewSpeaker.TagData.NameColor = Agent.Team.TeamColor.Color
            else -- This player is no longer in a team
                NewSpeaker.TagData.NameColor = NewSpeaker.__previousNameColor
            end
        end);
    end

    Network.EventSpeakerAdded:FireAllClients(Agent, NewSpeaker.Metadata);
    return NewSpeaker
end

--- Returns the speaker object for the requested agent
function SpeakerMaster:GetSpeaker(Agent : string | Player) : Speaker
    assert(type(Agent) == "string" or typeof(Agent) == "Instance", "The provided speaker agent was not of type \"string\" or \"Instance\"! ( received type: \""..(typeof(Agent)).."\" )");
    assert(type(Agent) == "string" or Agent:IsA("Player"), "The provided agent Instance was not of class \"Player\"! ( got \""..(Agent.ClassName).."\" instead )");
    
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

    assert(type(Metadata) == "table", "The provided metadata was not of type \"table\", but as type \""..(type(Metadata)).."\". Metadata can only be read as a table.");
    assert(next(Metadata), "The provided metadata is an empty array. Metadata needs to hold at least one value.");
    assert(type(Metadata.Classic) == "table" or type(Metadata.ChatBubble) == "table", "The provided metadata does not hold any readable information! You must provide at least a \"Classic\" array OR a \"ChatBubble\" array with your data!");
    
    local function AnalyzeStructure(structureSet : string, fromTable : table, isForPlayer : boolean?)
        if (not fromTable) then return; end

        assert(not fromTable.Color or (typeof(fromTable.Color) == "Color3" or type(fromTable.Color) == "string")
        , "The provided \"Color\" Value for \""..(structureSet).."\" was not a \"string\" or \"Color3\"! (received "..(typeof(fromTable.Color))..")");
        
        assert(not fromTable.Color or typeof(fromTable.Color) == "Color3" or (type(fromTable.Color) == "string" and TextStyles[fromTable.Color])
        , "The requested color TextStyle \""..(tostring(fromTable.Color)).."\" does not exist! (are you sure you typed the name correctly? This is CASE-SENSITIVE!)");

        assert(typeof(fromTable.Font) ~= "EnumItem" or table.find(Enum.Font:GetEnumItems(), fromTable.Font)
        , "The provided EnumItem was not a valid item of \"Font\"! Please set this value as a valid \"Enum.Font\" value!");

        if (isForPlayer and fromTable.Name) then
            warn("The provided username metadata for "..(Agent.Name).." will be used, however, it's \"Name\" value will be ignored for all Player's who use the same metadata. (requested name: \""..(fromTable.Name).."\")");
        end
    end

    if (Metadata.Classic) then
        if (Metadata.Classic.Tag and Metadata.Classic.Tag.Icon) then
            local Icon = Metadata.Classic.Tag.Icon
            assert(type(tonumber(Icon)) == "number"
            , "The requested Icon ImageId was not a number! Please provide the asset id of your requested Icon image! (received "..(type(Icon))..")");
            
            local ProductInfo = MarketplaceService:GetProductInfo(Icon);

            if (ProductInfo.AssetTypeId ~= Enum.AssetType.Decal.Value) then
                error("The provided Icon AssetId ("..(Icon)..") was not a valid Decal asset! Are you sure this Asset was uploaded as an image?");
            end
        end

        AnalyzeStructure("Tag", Metadata.Classic.Tag);
        AnalyzeStructure("Content", Metadata.Classic.Content);
        AnalyzeStructure("Username", Metadata.Classic.Username, type(Agent) ~= "string");
    end

    if (Metadata.ChatBubble) then
        AnalyzeStructure("ChatBubble", Metadata.ChatBubble);
    end
end

SpeakerMaster.OnSpeakerAdded = SpeakerAdded.Event
return SpeakerMaster