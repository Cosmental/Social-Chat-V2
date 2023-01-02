--[[

    Name: Mari
    Date: 12/26/2022

    Description: This component module handles SocialChat's input box!

]]--

--// Module
local MessageContainer = {};
MessageContainer.__index = MessageContainer

--// Constants
local ChatFrame

local ContainerFrame
local CanvasLayout

--// States
local PreviousSize : number?

--// Initialization

function MessageContainer:Initialize(Setup : table)
    local self = setmetatable(Setup, MessageContainer);

    ChatFrame = self.ChatUI.Chat
    ContainerFrame = ChatFrame.Input.MessageContainer
    CanvasLayout = ContainerFrame:FindFirstChildOfClass("UIListLayout");

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

    return self
end

--// Methods

--- Determines if our Chat is currently visible or not. (this will ONLY hide chat display! Networking calls will still be made regardless)
function MessageContainer:SetEnabled(state : boolean)
    
end

return MessageContainer