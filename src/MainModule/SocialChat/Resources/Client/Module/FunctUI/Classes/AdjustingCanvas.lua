--[[

    Name: Mari
    Date: 2/22/2023

    Description: The 'AdjustingCanvas' class is a classtype that automatically adjusts the size of any GuiObject based on its container size
    using a UIListLayout!

]]--

--// Module
local AdjustingCanvas = {};
AdjustingCanvas.__index = AdjustingCanvas

--// Main Methods

--- Creates a new Adjusting Canvas
function AdjustingCanvas.new(Canvas : GuiObject, Container : GuiObject?) : AdjustingCanvas
    assert(typeof(Canvas) == "Instance", "The provided 'Canvas' was not an Instance! (received "..(typeof(Canvas))..")");
    assert(Canvas:IsA("GuiObject"), "The provided Instance was not of ClassType \"GuiObject\". (received "..(Canvas.ClassName)..")");
    assert(not Container or typeof(Container) == "Instance", "The provided 'Container' was not an Instance! (received "..(typeof(Container))..")");
    assert(not Container or Container:IsA("GuiObject"), "The provided 'Container' was not of ClassType \"GuiObject\". (received "..((Container and Container.ClassName) or "nil")..")");

    local CanvasLayout = Canvas:FindFirstChildOfClass("UIListLayout");
    assert(CanvasLayout, "The provided Canvas does not have a \"UIListLayout\"! (this is required for the functuality of an 'AdjustingCanvas'!)");

    local self = setmetatable({

        --// PROPERTIES
        ["Canvas"] = Canvas,
        ["Layout"] = CanvasLayout,
        ["Container"] = (Container or Canvas.Parent),

        --// DATA
        ["ClassName"] = "AdjustingCanvas",
        ["PreviousSize"] = nil, -- number? : [ AbsoluteSize.Y ]

        ["XScale"] = Canvas.Size.X.Scale,

    }, AdjustingCanvas);

    --// Automatic Updates
	local function UpdateCanvas()
        self:Update(); -- The only reason this function exists is because 'self.FUNCTION' callbacks dont send metadata, hence the API would break
	end
	
	Canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateCanvas);
	CanvasLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas);

    self:Update(); -- Just in case our Canvas already has instances present!
    return self
end

--// Methods

--- Updates the size of our AdjustingCanvas. This is usually called automatically, but it can also be called manually!
function AdjustingCanvas:Update()
    local AbsoluteContentSize = self.Layout.AbsoluteContentSize

    local Property = ((self.Canvas:IsA("ScrollingFrame") and "CanvasSize") or "Size");
    local CanvasSize = UDim2.new(
        self.XScale,
        ((self.XScale == 0 and self.Canvas.AbsoluteSize.X) or 0),
        0,
        AbsoluteContentSize.Y + 5
    );

    if (CanvasSize == self.Canvas.Size) then return; end -- No changes made to the canvas!
    self.Canvas[Property] = CanvasSize

    --// Solve for scrolling
    if (not self.Canvas:IsA("ScrollingFrame")) then return; end -- The following is for ScrollingFrames ONLY!
    
    local CurrentCanvasSize = self:GetCanvasSize();
    local SizeOffset = ((self.PreviousSize and CurrentCanvasSize - self.PreviousSize) or 0);

    if (self.Layout.VerticalAlignment == Enum.VerticalAlignment.Bottom) then -- Force to bottom
        self.Canvas.CanvasPosition = Vector2.new(0, 9e9);
    elseif (not self:IsScrolledDown()) then -- Maintain a constant position (not forced to bottom)
        self.Canvas.CanvasPosition = Vector2.new(
            0, (self.Canvas.CanvasPosition.Y - SizeOffset));
    end
end

--- Returns the absolute CanvasSize based on the children found within the Canvas!
function AdjustingCanvas:GetCanvasSize() : number
    if (not self.Canvas:IsA("ScrollingFrame")) then return self.Canvas.AbsoluteSize.Y; end

    local CanvasY = self.Canvas.CanvasSize.Y.Offset
    local AbsoluteY = self.Canvas.AbsoluteSize.Y
    
    return (CanvasY - AbsoluteY);
end

--- Returns a boolean that states whether the canvas is scrolled all the way down. This compensates for newly added instances!
function AdjustingCanvas:IsScrolledDown() : boolean?
    if (not self.Canvas:IsA("ScrollingFrame")) then
        warn("'IsScrolledDown()' is a method for ScrollingFrames only! (called Instance: "..(self.Canvas.Name)..") Please use a ScrollingFrame in order to use this method.");
        return;
    end

    local AbsoluteCanvas = self:GetCanvasSize();
    local CanvasY = self.Canvas.CanvasPosition.Y
    
    local AbsoluteScroll = tonumber(string.format("%0.3f", CanvasY));
    local WasScrolledDown = (self.PreviousSize and (AbsoluteScroll + 2 >= tonumber(string.format("%0.3f", self.PreviousSize))));
    
    self.PreviousSize = AbsoluteCanvas
    return WasScrolledDown
end

return AdjustingCanvas