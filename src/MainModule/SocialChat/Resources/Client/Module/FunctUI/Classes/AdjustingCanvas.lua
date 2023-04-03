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
function AdjustingCanvas.new(Canvas : GuiObject, Container : GuiObject?, DominantAxis : string?, SizeCoefficient : Vector2?) : AdjustingCanvas
    assert(typeof(Canvas) == "Instance", "The provided 'Canvas' was not an Instance! (received "..(typeof(Canvas))..")");
    assert(Canvas:IsA("GuiObject"), "The provided Instance was not of ClassType \"GuiObject\". (received "..(Canvas.ClassName)..")");
    assert(not Container or typeof(Container) == "Instance", "The provided 'Container' was not an Instance! (received "..(typeof(Container))..")");
    assert(not Container or Container:IsA("GuiObject"), "The provided 'Container' was not of ClassType \"GuiObject\". (received "..((Container and Container.ClassName) or "nil")..")");
    assert(not DominantAxis or type(DominantAxis) == "string", "The provided canvas axis was not a string! (got "..(type(DominantAxis))..")");
    assert(not DominantAxis or (DominantAxis == "X" or DominantAxis == "Y"), "The provide axis was invalid! A scrolling axis can only be 'X' or 'Y' (case sensitive)");
    assert(not SizeCoefficient or typeof(SizeCoefficient) == "Vector2", "The provided 'SizeCoefficient' was not of type 'Vector2'! (received "..(typeof(SizeCoefficient))..")");

    local CanvasLayout = Canvas:FindFirstChildOfClass("UIListLayout");
    assert(CanvasLayout, "The provided Canvas does not have a \"UIListLayout\"! (this is required for the functuality of an 'AdjustingCanvas'!)");

    local self = setmetatable({

        --// PROPERTIES
        ["Canvas"] = Canvas,
        ["Layout"] = CanvasLayout,
        ["Container"] = (Container or Canvas.Parent),

        --// DATA
        ["ClassName"] = "AdjustingCanvas",
        ["PreviousSize"] = nil, -- number? : [ AbsoluteSize.DOMINANT_AXIS ]

        ["NScale"] = Canvas.Size[DominantAxis or "Y"].Scale, -- number :: We must save the un-used Axis as it is probably useful in UX
        ["Axis"] = (DominantAxis or "Y") -- string :: Our dominating canvas axis (default :: Y)

    }, AdjustingCanvas);

    --// Automatic Updates
	local function ResizeChild(Child : GuiObject)
        if (not SizeCoefficient) then return; end
        if (not Child:IsA("GuiObject")) then return; end

        local Relative = Canvas.AbsoluteSize
        local Coefficient = {
            X = (Relative.X * SizeCoefficient.X),
            Y = (Relative.Y * SizeCoefficient.Y)
        };

        Child.Size = UDim2.fromOffset(Coefficient.X, Coefficient.Y);
    end

    local function UpdateCanvas()
        for _, Child in pairs(Canvas:GetChildren()) do
            ResizeChild(Child);
        end

        self:Update(); -- The only reason this function exists is because 'self.FUNCTION' callbacks dont send metadata, hence the API would break
	end

    UpdateCanvas(); -- Just in case our Canvas already has instances present!

    Canvas.ChildAdded:Connect(ResizeChild);
	Canvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateCanvas);
	CanvasLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas);

    return self
end

--// Methods

--- Updates the size of our AdjustingCanvas. This is usually called automatically, but it can also be called manually!
function AdjustingCanvas:Update()
    local AbsoluteContentSize = self.Layout.AbsoluteContentSize

    local Property = ((self.Canvas:IsA("ScrollingFrame") and "CanvasSize") or "Size");
    local CanvasSize = UDim2.new(
        ((self.NScale == 0 and self.Canvas.AbsoluteSize.X) or 0),
        ((self.Axis == "X") and (AbsoluteContentSize.X + 5)) or (self.NScale),

        ((self.NScale == 0 and self.Canvas.AbsoluteSize.Y) or 0),
        ((self.Axis == "Y") and (AbsoluteContentSize.Y + 5)) or (self.NScale)
    );

    if (CanvasSize == self.Canvas.Size) then return; end -- No changes made to the canvas!
    self.Canvas[Property] = CanvasSize

    --// Solve for scrolling
    if (not self.Canvas:IsA("ScrollingFrame")) then return; end -- The following is for ScrollingFrames ONLY!
    
    local CurrentCanvasSize = self:GetCanvasSize();
    local SizeOffset = ((self.PreviousSize and CurrentCanvasSize - self.PreviousSize) or 0);

    if (self.Layout.VerticalAlignment == Enum.VerticalAlignment.Bottom) then -- Force to max position
        self.Canvas.CanvasPosition = Vector2.new(9e9, 9e9);
    elseif (not self:IsFullyScrolled()) then -- Maintain a constant position (not forced to max position)
        self.Canvas.CanvasPosition = Vector2.new(
            ((self.Axis == "X") and (self.Canvas.CanvasPosition.X - SizeOffset)) or 0,
            ((self.Axis == "Y") and (self.Canvas.CanvasPosition.Y - SizeOffset)) or 0
        );
    end
end

--- Returns the absolute CanvasSize based on its children and dominant axis
function AdjustingCanvas:GetCanvasSize() : number
    if (not self.Canvas:IsA("ScrollingFrame")) then return self.Canvas.AbsoluteSize[self.Axis]; end

    local CanvasAbsolute = self.Canvas.CanvasSize[self.Axis].Offset
    local CanvasSize = self.Canvas.AbsoluteSize[self.Axis];
    
    return (CanvasAbsolute - CanvasSize);
end

--- Returns a boolean that states whether the canvas is scrolled all the way down. This compensates for newly added instances!
function AdjustingCanvas:IsFullyScrolled() : boolean?
    if (not self.Canvas:IsA("ScrollingFrame")) then
        warn("'IsFullyScrolled()' is a method for ScrollingFrames only! (called Instance: "..(self.Canvas.Name)..") Please use a ScrollingFrame in order to use this method.");
        return;
    end

    local AbsoluteCanvas = self:GetCanvasSize();
    local AxisPosition = self.Canvas.CanvasPosition[self.Axis];
    
    local AbsoluteScroll = tonumber(string.format("%0.3f", AxisPosition));
    local WasScrolledDown = (self.PreviousSize and (AbsoluteScroll + 2 >= tonumber(string.format("%0.3f", self.PreviousSize))));
    
    self.PreviousSize = AbsoluteCanvas
    return WasScrolledDown
end

return AdjustingCanvas