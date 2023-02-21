--[[

    Name: Mari
    Date: 12/26/2022

    Description: This component module handles SocialChat's input box!

]]--

--// Module
local ChatUIManager = {};
ChatUIManager.__index = ChatUIManager

--// Services
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

--// Imports
local Settings

--// Constants
local ChatFrame
local Mouse = game.Players.LocalPlayer:GetMouse();

local ContainerFrame
local CanvasLayout

local InputBox

--// States
local PreviousSize : number?
local IsMouseOverChat : boolean?

--// Initialization

function ChatUIManager:Initialize(Setup : table)
    local self = setmetatable(Setup, ChatUIManager);

    ChatFrame = self.ChatUI.Chat
    ContainerFrame = ChatFrame.Input.MessageContainer
	InputBox = ChatFrame.Input.InteractionBar.InputBox
    CanvasLayout = ContainerFrame:FindFirstChildOfClass("UIListLayout");

	Settings = self.Settings.Channels

	self.BackgroundTransparency = ChatFrame.BackgroundTransparency
	self.LastInteraction = os.clock();
	self.Enabled = true

    --// Canvas Control
    local function GetCanvasSize()
		local yCanvasSize = ContainerFrame.CanvasSize.Y.Offset
		local yAbsoluteSize = ContainerFrame.AbsoluteSize.Y
		
		return (yCanvasSize - yAbsoluteSize);
	end
	
	local function IsScrolledDown()
		local yScrolledPosition = ContainerFrame.CanvasPosition.Y
		local AbsoluteCanvas = GetCanvasSize();
		
		--// Comparing
		local AbsoluteScroll = tonumber(string.format("%0.3f", yScrolledPosition));		
		local WasScrolledDown = (PreviousSize and (AbsoluteScroll + 2 >= tonumber(string.format("%0.3f", PreviousSize))));
		
		PreviousSize = AbsoluteCanvas
		return WasScrolledDown
	end
	
	local function UpdateCanvas()
		local AbsoluteContentSize = CanvasLayout.AbsoluteContentSize
		ContainerFrame.CanvasSize = UDim2.new(0, 0, 0, AbsoluteContentSize.Y + 5);
		
		--// Solve for scrolling
		local CurrentCanvasSize = GetCanvasSize();
		local SizeOffset = ((PreviousSize and CurrentCanvasSize - PreviousSize) or 0);
		
		local WasAtBottom = IsScrolledDown();
		
		if (not WasAtBottom) then
			ContainerFrame.CanvasPosition = Vector2.new(
				0, (ContainerFrame.CanvasPosition.Y - SizeOffset));
		else
			ContainerFrame.CanvasPosition = Vector2.new(0, 9e9);
		end
	end
	
	CanvasLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas);
	ContainerFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateCanvas);

	--// Visibility Management
	RunService.RenderStepped:Connect(function()
		local AbsolutePosition = ChatFrame.AbsolutePosition
		local AbsoluteSize = ChatFrame.AbsoluteSize

		local MeetsXBound = ((Mouse.X >= AbsolutePosition.X) and (Mouse.X < AbsolutePosition.X + AbsoluteSize.X));
		local MeetsYBound = ((Mouse.Y >= AbsolutePosition.Y) and (Mouse.Y < AbsolutePosition.Y + AbsoluteSize.Y));
		
		IsMouseOverChat = (MeetsXBound and MeetsYBound);

		if (not IsMouseOverChat) then return; end
		self:Interact();
	end);

	InputBox.Focused:Connect(function()
		self:Interact();
	end);

	InputBox.FocusLost:Connect(function()
		self:Interact();
	end);

	RunService.Heartbeat:Connect(function()
		if (not self.Enabled) then return; end -- We can't hide chat if it's already hidden!
		if (IsMouseOverChat) then return; end -- We can't hide chat if our Mouse is over it!
		if (InputBox:IsFocused()) then return; end -- Can't hide chat while we're typing!
		if ((os.clock() - self.LastInteraction) < Settings.IdleTime) then return; end

		self:SetEnabled(false);
	end);

    return self
end

--// Methods

--- Determines if our Chat is currently visible or not. (this will ONLY hide chat display! Networking calls will still be made regardless)
function ChatUIManager:SetEnabled(State : boolean, NoTween : boolean?)
	if (self.Enabled == State) then return; end -- We're already at this state! Cancel API request.
	self.Enabled = State

	if (State) then
		ChatFrame.Visible = true
	end

    if (not NoTween) then
		local TweenTime = ((not State and 0.1) or 0.2);
		local MainTween = TweenService:Create(ChatFrame, TweenInfo.new(TweenTime), {
			BackgroundTransparency = (State and self.BackgroundTransparency) or 1
		});

		if (State and self._displayCache) then
			for Object, Properties in pairs(self._displayCache) do
				TweenService:Create(Object, TweenInfo.new(0.2), Properties):Play();
			end

			self._displayCache = nil
		elseif (not State) then
			local DisplayedObjects : table = GetVisibleInstances();
			self._displayCache = DisplayedObjects

			for Object, Properties in pairs(DisplayedObjects) do
				local Goal = {};

				for Property, Value in pairs(Properties) do
					if (type(Value) ~= "number") then continue; end
					Goal[Property] = 1
				end

				TweenService:Create(Object, TweenInfo.new(TweenTime), Goal):Play();
			end
		end

		MainTween:Play();
		MainTween.Completed:Wait();
	end

	if (State) then return; end
	ChatFrame.Visible = false
end

--- Fires an interaction signal [ **NOTE:** This WILL make the ChatUI visible! ]
function ChatUIManager:Interact()
	if (not self.ChatButton.isSelected) then return; end -- Chat was manually closed, DO NOT ping it!

	self.LastInteraction = os.clock();
	self:SetEnabled(true);
end

--// Functions

--- Returns a list of hideable instances
function GetVisibleInstances() : table
	local Result = {};

	for _, Object in pairs(ChatFrame:GetDescendants()) do
		if (not Object:IsA("GuiBase2d")) then continue; end -- Ignores UIListLayouts, Folders, etc.
		if (not Object.Visible) then continue; end -- Ignore already non-visible Instances
		
		if (Object:IsA("ImageButton") or Object:IsA("ImageLabel")) then
			if (((Object.ImageTransparency >= 1) and (Object.BackgroundTransparency >= 1)) or (Object.Image:gsub("%s", ""):len() == 0)) then continue; end

			Result[Object] = {
				ImageTransparency = Object.ImageTransparency,
				BackgroundTransparency = Object.BackgroundTransparency,
				Position = Object.Position,
				Size = Object.Size
			};

			continue;
		end

		if (Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox")) then
			if (
				((Object.BackgroundTransparency >= 1) and (Object.TextTransparency == 1) and (Object.TextStrokeTransparency == 1))
				or (Object.Text:gsub("%s", ""):len() == 0)
			) then continue; end

			Result[Object] = {
				TextTransparency = Object.TextTransparency,
				TextStrokeTransparency = Object.TextStrokeTransparency,
				BackgroundTransparency = Object.BackgroundTransparency,
				Position = Object.Position,
				Size = Object.Size
			};

			continue;
		end

		Result[Object] = {
			BackgroundTransparency = Object.BackgroundTransparency,
			Position = Object.Position,
			Size = Object.Size
		};
	end

	return Result
end

return ChatUIManager