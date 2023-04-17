--// Constants
local AlertEvents = {

    --// ROBLOX EVENTS

    ["PlayerAdded"] = { -- Fires whenever a player joins the game
        ["Trigger"] = function(Submit : callback, PlayerJoining : Player)
            Submit(
                game.Players:GetPlayers(),
                {PlayerJoining}
            );
        end,

        ["Signal"] = function(Trigger : callback, Hook : callback)
            local function Fire(PlayerWhoJoined : Player)
                Trigger(Hook, PlayerWhoJoined);
            end

            for _, Player in pairs(game.Players:GetPlayers()) do
                Fire(Player);
            end

            game.Players.PlayerAdded:Connect(Fire);
        end
    },

    ["PlayerRemoving"] = { -- Fires whenever a player leaves the game
        ["Trigger"] = function(Submit : callback, PlayerLeaving : Player)
            Submit(
                game.Players:GetPlayers(),
                {PlayerLeaving}
            );
        end,

        ["Signal"] = function(Trigger : callback, Hook : callback)
            local function Fire(PlayerWhoLeft : Player)
                Trigger(Hook, PlayerWhoLeft);
            end

            game:BindToClose(function()
                for _, Player in pairs(game.Players:GetPlayers()) do
                    Fire(Player);
                end
            end);

            game.Players.PlayerRemoving:Connect(Fire);
        end
    },
    
    --// CUSTOM EVENTS

    ["TeamChanged"] = { -- Fires whenever a player's team changes
        ["Trigger"] = function(Submit : callback, Player : Player, Team : Team)
            if (not Team) then return; end
            
            Submit(
                {Player},
                {Team}
            );
        end,

        ["Signal"] = function(Trigger : callback, Hook : callback)
            local function Subscribe(PlayerWhoJoined : Player)
                PlayerWhoJoined:GetPropertyChangedSignal("Team"):Connect(function()
                    Trigger(Hook, PlayerWhoJoined, PlayerWhoJoined.Team);
                end);
            end

            for _, Player in pairs(game.Players:GetPlayers()) do
                Subscribe(Player);
            end

            game.Players.PlayerAdded:Connect(Subscribe);
        end
    },

    ["FriendJoined"] = { -- Fires whenever a player's friend joins the game
        ["Trigger"] = function(Submit : callback, PlayerJoining : Player)
            local Friends = {};

            for _, Player in pairs(game.Players:GetPlayers()) do
                if (Player.UserId == PlayerJoining.UserId) then continue; end
                if (not Player:IsFriendsWith(PlayerJoining.UserId)) then continue; end

                table.insert(Friends, Player);
            end

            Submit(
                Friends,
                {PlayerJoining}
            );
        end,

        ["HookTo"] = "PlayerAdded"
    },

    ["FriendLeaving"] = { -- Fires whenever a player's friend leaves the game
        ["Trigger"] = function(Submit : callback, PlayerLeaving : Player)
            local Friends = {};

            for _, Player in pairs(game.Players:GetPlayers()) do
                if (Player:IsFriendsWith(PlayerLeaving.UserId)) then
                    table.insert(Friends, Player);
                end
            end

            Submit(
                Friends,
                {PlayerLeaving}
            );
        end,

        ["HookTo"] = "PlayerAdded"
    },

    --// EXAMPLE
    --\\ [NOTE]: DO NOT USE THE EXAMPLE METHOD! This will be nullified by our API as it serves NO actual functuality!

    ["__example"] = {
        ["Trigger"] = function(Submit : callback, ... : any?) -- This function will signal our main API using the 'Submit' callback. This will send a message to the server based on its metadata
            Submit(
                game.Players:GetPlayers(), -- Who will this be sent to? ('table' of players)
                {...} -- This will be the information passed onto our API. All information passed here will be formatted (eg. "%s wow!" --> "<param 1> wow!")
            );
        end,

        ["Signal"] = function(Trigger : callback, Hook : callback) -- This function controls when our 'Trigger' callback is fired
            Trigger(Hook); -- Our HOOK is a predefined function that handles API signalling. This MUST be sent in order for any effects to take place
        end,

        ["HookTo"] = "NAME_OF_OTHER_EVENT" -- An optional configurations that CONNECTS to another AlertEvent's signal. (If none, set to 'nil')
    },

};

--// Configuration
local SystemChannelSettings = {

    --// CHAT SYSTEM SETTINGS \\--

    ["DefaultChannel"] = "General", -- The default chat channel that processes player messages.
    ["MaxMessagesPerChannel"] = 50, -- The maximum number of messages that can be stored in each chat channel.
    ["MaxMessageLength"] = 200, -- The maximum utf-8 length of a single chat message.
    ["MessageRate"] = 10, -- The maximum number of messages a player can send within a 10 second period.
    
    ["UseDisplayNames"] = false, -- Determines whether player usernames or display names will be used in chat messages.

    --// METADATA \\--

    ["ApplyRandomColorAsDefault"] = true, -- Determines if the chat will assign a random color to players' usernames when they join the game.
    ["ApplyTeamColors"] = true, -- Determines whether to apply a player's team color to their username in chat messages.
    
    ["ServerErrorColor"] = Color3.fromRGB(255, 80, 80), -- This will be the color used to send server error messages to clients
    ["UsernameColors"] = { -- A list of preset colors that can be randomly assigned to players' usernames. Each value must be in Color3!
        Color3.fromRGB(255, 80, 80),
        Color3.fromRGB(100, 100, 255),
        Color3.fromRGB(70, 255, 100),
        Color3.fromRGB(255, 120, 255),
        Color3.fromRGB(105, 225, 255),
        Color3.fromRGB(240, 240, 125),
        Color3.fromRGB(255, 180, 15),
        Color3.fromRGB(255, 65, 160),
        Color3.fromRGB(255, 150, 210)
    };

    ["ServerTagData"] = { -- The TagData used for the server when sending messages.
        ["Classic"] = {
            ["Username"] = {
                ["Color"] = Color3.fromRGB(255, 100, 100)
            },

            ["Content"] = {
                ["Color"] = Color3.fromRGB(200, 200, 200)
            }
        };
    };

    --// BEHAVIOR \\--

    ["SystemAlerts"] = { -- A list of system alerts that can be enabled or disabled.
        
        --// FRIENDS

        ["OnFriendJoining"] = { -- Displays a system message whenever a player's friend joins the game (default : true)
            ["Tag"] = nil, -- Setting your tag to 'nil' will not give your alert message any tagdata and will send it as a plain message!
            ["Enabled"] = true,

            ["Message"] = "**{System} Your friend %s has joined the game**", -- This message will be sent through SocialChat whenever the specified event fires. These messages will ALWAYS bypass Markdown settings regardless if theyre enabled or not!
            ["Event"] = AlertEvents.FriendJoined -- Events can either be RBXScriptSignals OR custom SocialChat events!
        },

        ["OnFriendLeaving"] = { -- Displays a custom system message whenever a player's friend leaves the game (default : false)
            ["Tag"] = nil,
            ["Enabled"] = false,

            ["Message"] = "**{System} Your friend %s has left the game**",
            ["Event"] = AlertEvents.FriendLeaving
        },

        --// PLAYER STATES

        ["PlayerJoining"] = { -- Displays a system message whenever a player joins the game (default : false)
            ["Tag"] = "SERVER",
            ["Enabled"] = true,

            ["Message"] = "**{System}** %s has joined the server",
            ["Event"] = AlertEvents.PlayerAdded
        },

        ["PlayerLeaving"] = { -- Displays a system message whenever a player leaves the game (default : false)
            ["Tag"] = "SERVER",
            ["Enabled"] = false,

            ["Message"] = "**{System}** %s has left the server",
            ["Event"] = AlertEvents.PlayerRemoving
        },

        --// MISC

        ["TeamChanged"] = { -- Displays a system message whenever a player leaves the game (default : false)
            ["Tag"] = nil,
            ["Enabled"] = true,

            ["Message"] = "**{Team}** You are now in the *\'%s\'* team",
            ["Event"] = AlertEvents.TeamChanged
        },

    },

};

SystemChannelSettings.AlertEvents = AlertEvents
return SystemChannelSettings