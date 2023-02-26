--[[

    Name: Mari
    Date: 2/24/2023

    Description: This FunctUI API provides sliding-button functuality for the provided UI Element.

]]--

--// Module
local Slider = {};

--// Services
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

--// Constants
local Mouse = game.Players.LocalPlayer:GetMouse();

--// Methods

--- Applies Slider functuality to the provided GuiObject!
function Slider.new(Element : GuiObject) : Slider
    assert(typeof(Element) == "Instance", "The provided Slider GuiObject was not an Instance! (received "..(typeof(Element))..")");
    assert(Element:IsA("GuiObject"), "The provided Instance was not of ClassType \"GuiObject\". (received "..(Element.ClassName)..")");
    
    local Socket = (Element:FindFirstChildOfClass("TextButton") or Element:FindFirstChildOfClass("ImageButton"));
    assert(Socket, "Attempt to create new FunctUI Class 'Slider' with instance '"..(Element.Name).."' without a Socket! (you must add a GuiButton named 'Socket' under your requested UI element)");

    --// Object Setup

    local ValueChangedEvent = Instance.new("BindableEvent");

    local self
    local Data = {

        --// DATA

        ["Disabled"] = nil, -- Determines if the slider is enabled or not
        ["Value"] = 0, -- Current Slider value

        --// METADATA

        ["_visuals"] = {
            ["Appearance"] = {
                SocketColor = Color3.fromRGB(0, 120, 255),
                SliderColor = Color3.fromRGB(0, 120, 255),
            };

            ["Range"] = NumberRange.new(0, 30)
        }

    };

    self = setmetatable({

        --// PROPERTIES
        ["Element"] = Element,

        --// EVENTS
        ["ValueChanged"] = ValueChangedEvent.Event

    }, {
        __index = function(_, Index : string)
            return (Slider[Index] or Data[Index]);
        end,

        __newindex = function(_, Index : string, Value : any?)
            if (Index == "Value" and type(Value) == "number") then
                local Parse = math.clamp(math.floor(Value), Data._visuals.Range.Min, Data._visuals.Range.Max); -- Force clamp values

                if (Parse ~= Data[Index]) then
                    ValueChangedEvent:Fire(Parse);
                end
                
                Data[Index] = Parse
                
                self:Update();
            else
                Data[Index] = Value
            end
        end
    });

    self:Apply(Data._visuals);
    self:Update();

    --// Functuality
    local IsMouseActive : boolean?
    local IsMouseHovering : boolean?

    local function UpdateVisual()
        if (not IsMouseHovering and not IsMouseActive) then
            TweenService:Create(Socket.Progress, TweenInfo.new(0.2), {
                BackgroundTransparency = 1
            }):Play();
    
            TweenService:Create(Socket.Progress.Value, TweenInfo.new(0.2), {
                TextTransparency = 1
            }):Play();
        elseif (IsMouseHovering or IsMouseActive) then
            TweenService:Create(Socket.Progress, TweenInfo.new(0.1), {
                BackgroundTransparency = 0
            }):Play();
    
            TweenService:Create(Socket.Progress.Value, TweenInfo.new(0.1), {
                TextTransparency = 0
            }):Play();
        end
    end

    Socket.InputBegan:Connect(function(Input)
        if (Input.UserInputType ~= Enum.UserInputType.MouseButton1) then return; end

        IsMouseActive = true
        UpdateVisual();
    end);

    Socket.InputEnded:Connect(function(Input)
        if (Input.UserInputType ~= Enum.UserInputType.MouseButton1) then return; end

        IsMouseActive = false
        UpdateVisual();
    end);

    Socket.MouseEnter:Connect(function()
        IsMouseHovering = true
        UpdateVisual();
    end);

    Socket.MouseLeave:Connect(function()
        IsMouseHovering = false
        UpdateVisual();
    end);

    RunService.RenderStepped:Connect(function()
        if (not IsMouseActive) then return; end

        local AbsoluteBarPos : Vector2 = self.Element.AbsolutePosition
        local AbsolteBarSize : Vector2 = self.Element.AbsoluteSize

        local Start : number = (AbsoluteBarPos.X);
        local Goal : number = (AbsoluteBarPos.X + AbsolteBarSize.X);

        local Progress = math.clamp((Mouse.X - Start) / (Goal - Start), 0, 1);
        self.Value = (self._visuals.Range.Min + ((self._visuals.Range.Max - self._visuals.Range.Min) * Progress));
    end);
    
    return self
end

--- Updates the value text of our Slider!
function Slider:Update()
    local Max = self._visuals.Range.Max
    local Min = self._visuals.Range.Min

    local Progress = ((self.Value - (Min)) / ((Max) - (Min)));
    self.Element.Socket.Position = UDim2.fromScale(Progress - 0.025, 0.5);

    self.Element.Socket.Progress.Value.Text = self.Value
    self.Element.Parent.Start.Text = Min
    self.Element.Parent.End.Text = Max
end

--- Determines the current state of this interactable. Disabling your slider will lock it from further inputs, but its value will remain the same
function Slider:SetEnabled(State : boolean)
    self.Disabled = State

    if (self.Disabled) then
        local Metadata = self._visuals

        local TextDisabled = {TextTransparency = 1};
        local BackgroundDisabled = {BackgroundTransparency = 0.5};

        TweenService:Create(self.Element, TweenInfo.new(Metadata.Tween.Speed, Metadata.Tween.EasingStyle), BackgroundDisabled):Play();
        TweenService:Create(self.Element.Socket, TweenInfo.new(Metadata.Tween.Speed, Metadata.Tween.EasingStyle), BackgroundDisabled):Play();
        TweenService:Create(self.Element.Progress, TweenInfo.new(Metadata.Tween.Speed, Metadata.Tween.EasingStyle), BackgroundDisabled):Play();

        TweenService:Create(self.Element.Parent.End, TweenInfo.new(Metadata.Tween.Speed, Metadata.Tween.EasingStyle), TextDisabled):Play();
        TweenService:Create(self.Element.Parent.Start, TweenInfo.new(Metadata.Tween.Speed, Metadata.Tween.EasingStyle), TextDisabled):Play();
        TweenService:Create(self.Element.Progress.Value, TweenInfo.new(Metadata.Tween.Speed, Metadata.Tween.EasingStyle), TextDisabled):Play();
    else
        self:Update();
    end
end

--- Applies the provided visual metadata to the Button's appearance
function Slider:Apply(Metadata : table)
    assert(type(Metadata) == "table", "Expected new Slider metadata as type 'table'. (received "..(type(Metadata)).." instead)");
    assert(Metadata.Appearance and Metadata.Range, "New Slider metadata was malformed! (did you include an \"Appearance\" and \"Range\" data entry?) ");

    if ((self.Value < Metadata.Range.Min) or (self.Value > Metadata.Range.Max)) then
        self.Value = math.clamp(self.Value, Metadata.Range.Min, Metadata.Range.Max);
    end

    self.Element.BackgroundColor3 = Metadata.Appearance.SliderColor
    self.Element.Socket.BackgroundColor3 = Metadata.Appearance.SocketColor

    self._visuals = Metadata
    self:Update();
end

return Slider