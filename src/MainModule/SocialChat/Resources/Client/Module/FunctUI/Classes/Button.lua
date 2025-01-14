--[[

    Name: Mari
    Date: 2/24/2023

    Description: This FunctUI API provides sliding-button functuality for the provided UI Element.

]]--

--// Module
local Button = {};

--// Services
local TweenService = game:GetService("TweenService");

--// Methods

--- Applies Sliding-Button functuality to the provided GuiObject!
function Button.new(Element : GuiObject) : Button
    assert(typeof(Element) == "Instance", "The provided Button GuiObject was not an Instance! (received "..(typeof(Element))..")");
    assert(Element:IsA("GuiObject"), "The provided Instance was not of ClassType \"GuiObject\". (received "..(Element.ClassName)..")");
    
    local Clicker = (Element:FindFirstChildOfClass("TextButton") or Element:FindFirstChildOfClass("ImageButton"));
    assert(Clicker, "Attempt to create new FunctUI Class 'Button' with instance '"..(Element.Name).."' without a Clicker! (you must add a GuiButton named 'Clicker' under your requested UI element)");

    local ValueChangedEvent = Instance.new("BindableEvent");

    local self
    local Data = {

        --// DATA
        ["Disabled"] = nil, -- Determines if the button is clickable or not
        ["Value"] = true, -- Determines if the button is currently active or not. This is based on the user's inputs.

        --// METADATA

        ["_visuals"] = {
            ["Active"] = {
                StrokeColor = Color3.fromRGB(255, 255, 255),
                ButtonColor = Color3.fromRGB(100, 255, 105),
                
                StrokeTransparency = 0,
                ButtonTransparency = 0
            };

            ["Inactive"] = {
                StrokeColor = Color3.fromRGB(255, 255, 255),
                ButtonColor = Color3.fromRGB(100, 255, 105),
                
                StrokeTransparency = 0.5,
                ButtonTransparency = 0.5
            };

            ["Tween"] = {
                Speed = 0.5,
                EasingStyle = Enum.EasingStyle.Exponential
            }
        }

    };

    self = setmetatable({

        --// PROPERTIES
        ["Element"] = Element,

        --// EVENTS
        ["ValueChanged"] = ValueChangedEvent.Event,

    }, {
        __index = function(_, Index : string)
            return (Button[Index] or Data[Index]);
        end,

        __newindex = function(_, Index : string, Value : any?)
            if (Index == "Value" and type(Value) == "boolean") then
                ValueChangedEvent:Fire(Value);
                Data[Index] = Value
                
                self:Update();
            else
                Data[Index] = Value
            end
        end
    });

    Clicker.MouseButton1Click:Connect(function()
        if (self.Disabled) then return; end
        self.Value = (not self.Value); -- Auto updating variables? COUNT ME IN >:D
    end);

    self:Update();
    return self
end

--- Updates the current state of the button based on its activity state
function Button:Update()
    if (self.Disabled) then return; end

    local Metadata = self._visuals
    local Properties = {
        Button = {},
        Stroke = {}
    };

    local VisualInfo : table?

    if (self.Value) then
        VisualInfo = Metadata.Active
    else
        VisualInfo = Metadata.Inactive
    end

    Properties.Button = {
        ["BackgroundColor3"] = VisualInfo.ButtonColor,
        ["BackgroundTransparency"] = VisualInfo.ButtonTransparency,

        ["Position"] = (self.Value and UDim2.fromScale(0.07, 0.5)) or UDim2.fromScale(0.5, 0.5)
    };

    Properties.Stroke = {
        ["Color"] = VisualInfo.StrokeColor,
        ["Transparency"] = VisualInfo.StrokeTransparency,
    };

    TweenService:Create(self.Element.Clicker, TweenInfo.new(Metadata.Tween.Speed, Metadata.Tween.EasingStyle), Properties.Button):Play();
    TweenService:Create(self.Element.UIStroke, TweenInfo.new(Metadata.Tween.Speed, Metadata.Tween.EasingStyle), Properties.Stroke):Play();
end

--- Determines the current state of this interactable. Disabling your button will lock it from further inputs, but its value will remain the same
function Button:SetEnabled(State : boolean)
    self.Disabled = State

    if (self.Disabled) then
        local Metadata = self._visuals

        TweenService:Create(self.Element.Clicker, TweenInfo.new(Metadata.Tween.Speed, Metadata.Tween.EasingStyle), {
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 0.5
        }):Play();

        TweenService:Create(self.Element.UIStroke, TweenInfo.new(Metadata.Tween.Speed, Metadata.Tween.EasingStyle), {
            Color = Color3.fromRGB(0, 0, 0),
            Transparency = 0.5
        }):Play();
    else
        self:Update();
    end
end

--- Applies the provided visual metadata to the Button's appearance
function Button:Apply(Metadata : table)
    assert(type(Metadata) == "table", "Expected new Button metadata as type 'table'. (received "..(type(Metadata)).." instead)");
    assert(Metadata.Active and Metadata.Inactive, "New Button metadata was malformed! (did you include an \"Active\" and \"Inactive\" data entry?)");

    self._visuals = Metadata
    self:Update();
end

return Button