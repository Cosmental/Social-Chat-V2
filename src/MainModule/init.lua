--[[

    Name: Mari
    Date: 12/21/2022

    Description: This module handles SocialChat initialization! You can also find the sourcecode to all of SocialChat within this module.

]]--

local ErrorTypes = {
	[1] = "The instance '%s' was missing! This is a required instance that must exist in order for SocialChat to work properly!\n\nPlease create an instance of type: %s named '%s' under the path:\n%s",
	[2] = "'%s' can not be of class '%s'!\n'%s' must either be a %s!\n\nPath: %s",
	[3] = "'%s' does not have a '%s' within it! Please add an Instance of class '%s' within the path:\n%s"
};

local function Error(ErrorType : number, ... : any?) : string
	local Params = table.pack(...);
	Params['n'] = nil

	local Message = ErrorTypes[ErrorType];

	for i = 1, #Params do
		local Starts, Ends = Message:find("%%s"); -- '%' searches for a LITERAL '%s' case rather than regexifying itself

		Message = Message:sub(1, Starts - 1)..
			tostring(Params[i])..
			Message:sub(Ends + 1)
	end

	return Message
end

local function IsFromValidClass(Object : Instance, Classes : table)
	for _, Class in pairs(Classes) do
		if (Object:IsA(Class)) then return true; end
	end
end

local function Ensure(Condition : any?, Err : string)
	if (Condition) then return; end
	error(Err, 2);
end

local function Validate(Container : Instance, Query : string, Classes : table) : Instance?
	local Object = ((Container:FindFirstChild(Query)) or (not Classes and Container:FindFirstChildOfClass(Query)));

	if (Classes) then
		Ensure(Object, Error(1, Query, "'"..table.concat(Classes, " or ").."'", Query, Container:GetFullName()));
		Ensure(IsFromValidClass(Object, Classes), Error(2, Query, Object.ClassName, Query, "'"..table.concat(Classes, " or ").."'", Object:GetFullName()));
	else
		Ensure(Object, Error(3, Container.Name, Query, Query, Container:GetFullName()));
	end

	return Object
end

--- Verifies if the current UI build is valid or not. This is done to prevent errors!
local function CheckChatUI(Interface : ScreenGui)
	local Chat = Validate(Interface, "Chat", {"Frame"});

	local ChannelBar = Validate(Chat, "ChannelBar", {"Frame"});
	Validate(ChannelBar, "Channels", {"Frame"});

	local InputFrame = Validate(Chat, "Input", {"Frame"});
	local InteractionBar = Validate(InputFrame, "InteractionBar", {"Frame"});
	Validate(InteractionBar, "Submit", {"ImageButton", "TextButton"});
	Validate(InteractionBar, "InputBox", {"TextBox"});
end

return function(Configurations : Folder, Extensions : Folder?)
	assert(game:GetService("RunService"):IsServer(), "SocialChat MainModule Error: The SocialChat main module can only be preloaded by a \"Server\" Script. (callback cancelation error)");
	assert(game:GetService("RunService"):IsRunning(), "SocialChat can only be initialized in an active game!");
	assert(Configurations:FindFirstChild("Chat") and Configurations.Chat:IsA("ScreenGui"), "SocialChat Misconfiguration: ChatUI Missing! Please install the 'Chat' ScreenGui object into the SocialChat configurations folder to fix this issue.");
	CheckChatUI(Configurations.Chat);
	
	--// Configurable Instancing
	local ServerSettings = Configurations.Server
	local ClientSettings = Configurations.Client
	local SharedSettings = Configurations.Shared

	ServerSettings.Name = "ServerChatSettings"
	ServerSettings.Parent = game.ServerStorage

	ClientSettings.Name = "ClientChatSettings"
	ClientSettings.Parent = game.ReplicatedFirst

	SharedSettings.Name = "SharedChatSettings"
	SharedSettings.Parent = game.ReplicatedStorage

	local SocialChat = script.SocialChat
	
	Configurations.Chat.Parent = SocialChat.Environments.Client
	Configurations:Destroy();
	
	--// Extensions
	if (Extensions) then
		local ServerExtensions = Extensions.Server
		ServerExtensions.Name = "ServerChatExtensions"
		ServerExtensions.Parent = game.ServerStorage
		
		local ClientExtensions = Extensions.Client
		ClientExtensions.Name = "ClientChatExtensions"
		ClientExtensions.Parent = game.ReplicatedFirst

		local SharedExtensions = Extensions.Shared
		SharedExtensions.Name = "SharedChatExtensions"
		SharedExtensions.Parent = game.ReplicatedStorage
		
		Extensions:Destroy();
	end

	--// Finalization
	SocialChat.Parent = game.ReplicatedStorage
	require(SocialChat);
	
	--// Player Handling
	local function HandlePlayer(Player : Player)
		local Container = Player:WaitForChild("PlayerGui");
		local SocialChatClient = script.SocialChatClient:Clone();
		
		SocialChatClient.Parent = Container
		SocialChatClient.Disabled = false
	end
	
	for _, Player in pairs(game.Players:GetPlayers()) do
		HandlePlayer(Player);
	end
	
	game.Players.PlayerAdded:Connect(HandlePlayer);
end