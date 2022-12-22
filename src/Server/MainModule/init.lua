--[[

    Name: Mari
    Date: 12/21/2022

    Description: This module handles SocialChat initialization! You can also find the sourcecode to all of SocialChat within this module.

]]--

return function(Configurations : Folder)
	assert(game:GetService("RunService"):IsServer(), "SocialChat MainModule Error: The SocialChat main module can only be preloaded by a \"Server\" Script. (callback cancelation error)");
	assert(game:GetService("RunService"):IsRunning(), "Social Chat can only be initialized in an active game!");
	
	Configurations.Name = "SocialChatConfigurations"
	Configurations.Parent = game.ReplicatedStorage
		
	script.SocialChat.Parent = game.ReplicatedStorage
	require(game.ReplicatedStorage:WaitForChild("SocialChat"));
	
	--// Player Handling
	local function handlePlayer(Player : Player)
		local Container = Player:WaitForChild("PlayerGui");
		local SocialChatClient = script.SocialChatClient:Clone();
		
		SocialChatClient.Parent = Container
		SocialChatClient.Disabled = false
	end
	
	for _, Player in pairs(game.Players:GetPlayers()) do
		handlePlayer(Player);
	end
	
	game.Players.PlayerAdded:Connect(handlePlayer);
end