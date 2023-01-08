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
local CollectionService = game:GetService("CollectionService");

--// Imports
local Settings
local ChatTag

local Channels

--// Constants
local SpeakerAdded = Instance.new("BindableEvent");
local Network

local ChatSpeakers = {};

--// Initialization

function SpeakerMaster:Initialize(Setup : table)
    local self = setmetatable(Setup, SpeakerMaster);

    Settings = self.Settings.SystemChannelSettings
    ChatTag = self.Settings.ChatTags

    Network = self.Remotes.Channels
    Channels = self.Src.Channels

    --// Setup

    local function onSocialChatReady(Player : Player)
        SpeakerMaster.new(Player, GetTag(Player));
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
function SpeakerMaster.new(agent : string | Player, tagData : table?) : Speaker
    assert(type(agent) == "string" or typeof(agent) == "Instance", "The provided speaker agent was not of type \"string\" or \"Instance\"! ( received type: \""..(typeof(agent)).."\" )");
    assert(type(agent) == "string" or agent:IsA("Player"), "The provided agent Instance was not of class \"Player\"!");
    assert(not tagData or type(tagData) == "table", "The provided tagData parameter was not of type \"table\". ( received \""..(type(tagData)).."\" instead ) ");

    if (ChatSpeakers[agent]) then
        warn("Attempt to recreate a pre-existing chat speaker! ( \""..(tostring(agent)).."\" is already registed. ) ");
        return;
    end

    local NewSpeaker = setmetatable({

        --// RESOURCE DATA \\--
        ["TagData"] = {
            
            ["UserId"] = ((typeof(agent) == "Instance" and agent.UserId) or nil), -- UserId is useful for security cases!

            --// VISUALS \\--

            ["Font"] = (tagData and tagData.Font) or nil,
            ["Name"] = (
                ((typeof(agent) == "Instance") and ((Settings.UseDisplayNames and agent.DisplayName) or agent.Name)) -- "agent" is a Player!
                or agent -- "agent" is a string!
            ),

            --// NAME METADATA \\--

            ["NameColor"] = (tagData and tagData.SpeakerColor) or getRandomSpeakerColor(),
            ["MessageColor"] = (tagData and tagData.MessageColor) or Color3.fromRGB(255, 255, 255),

            --// TAGNAME METADATA \\--

            ["TagName"] = ((tagData and tagData.TagName) or nil), -- opt.
            ["TagColor"] = ((tagData and tagData.TagColor) or nil) -- opt.

        };

        --// PROGRAMMABLE \\--

        ["Channels"] = {}, -- a table of channels that this speaker is in
        ["__previousNameColor"] = nil, -- a Color3 value that recalls the speaker's previous TagColor

    }, Speaker);

    ChatSpeakers[agent] = NewSpeaker
    SpeakerAdded:Fire(agent, NewSpeaker);

    --// Team Color Appliance \\--
    if (Settings.UserTeamColorsAsUsernameColor and typeof(agent) == "Instance") then
        agent:GetPropertyChangedSignal("Team"):Connect(function()
            if (agent.Team ~= nil) then -- This Player is now in a team
                NewSpeaker.__previousNameColor = NewSpeaker.TagData.NameColor
                NewSpeaker.TagData.NameColor = agent.Team.TeamColor.Color

                Network.EventSendMessage:FireClient(
                    agent,
                    "**{Team}** You are now on the \'*"..(agent.Team.Name).."*\' team.",
                    Channels:Get("General"),
                    {
                        ["MessageColor"] = Color3.fromRGB(255, 255, 255);
                    }
                );
            else -- This player is no longer in a team
                NewSpeaker.TagData.NameColor = NewSpeaker.__previousNameColor
            end
        end);
    end

    return NewSpeaker
end

--- Returns the speaker object for the requested agent
function SpeakerMaster:GetSpeaker(agent : string | Player) : Speaker
    assert(type(agent) == "string" or typeof(agent) == "Instance", "The provided speaker agent was not of type \"string\" or \"Instance\"! ( received type: \""..(typeof(agent)).."\" )");
    assert(type(agent) == "string" or agent:IsA("Player"), "The provided agent Instance was not of class \"Player\"! ( got \""..(agent.ClassName).."\" instead )");
    
    return ChatSpeakers[agent];
end

--// Functions

--- Returns a random Speaker color
function getRandomSpeakerColor() : Color3
    if (not Settings.AssignRandomUsernameColorOnJoin) then return Color3.fromRGB(255, 255, 255); end

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
	for _, Tag in pairs(ChatTag) do
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
		OwnedTag = Tag.TagData
		Priority = Tag.PriorityOrder
	end

    return OwnedTag
end

SpeakerMaster.OnSpeakerAdded = SpeakerAdded.Event
return SpeakerMaster