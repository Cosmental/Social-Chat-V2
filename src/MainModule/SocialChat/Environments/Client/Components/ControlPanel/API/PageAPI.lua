--[[

    Name: Mari
    Date: 2/22/2023

    Description: This is a rundown of what most Pages will use to perform the effects they use. Most of these are just shared methods.

]]--

--// Module
local PageAPI = {};

--- Returns a list of VISIBLE GuiObjects within the provided UI element!
function PageAPI:GetVisibleElements(Container : GuiObject, IgnoreList : table?) : table
    local Elements = {};

    for _, Object in pairs(Container:GetDescendants()) do
        if (not Object:IsA("GuiObject")) then continue; end
        if (not Object.Visible) then continue; end

        --// Ignore List
        if (IgnoreList) then
            local IgnoreObject : boolean?
            
            for _, Ignore in pairs(IgnoreList) do
                if ((Object:IsDescendantOf(Ignore)) or (Object == Ignore)) then
                    IgnoreObject = true
                    break;
                end
            end

            if (IgnoreObject) then continue; end
        end

        --// Property Saving
        local Properties = {
            BackgroundTransparency = Object.BackgroundTransparency,
            BackgroundColor3 = Object.BackgroundColor3,

            Position = Object.Position,
            Size = Object.Size
        };

        if (Object:IsA("TextBox") or Object:IsA("TextButton") or Object:IsA("TextLabel")) then
            Properties["TextColor3"] = Object.TextColor3
            Properties["TextStrokeColor3"] = Object.TextStrokeColor3
            Properties["TextTransparency"] = Object.TextTransparency
            Properties["TextStrokeTransparency"] = Object.TextStrokeTransparency
        elseif (Object:IsA("ImageLabel") or Object:IsA("ImageButton")) then
            Properties["ImageColor3"] = Object.ImageColor3
            Properties["ImageTransparency"] = Object.ImageTransparency
        end

        Elements[Object] = Properties
    end

    return Elements
end

--- Returns a list of descendant GuiObjects within the provided UI element which is ordered from highest to lowest element based on AbsPos!
function PageAPI:GetOrderedElements(Container : GuiObject) : table
    local Order = {};

    --// Order by Class
    for _, Object in pairs(Container:GetDescendants()) do
        if (not Object:IsA("GuiObject")) then continue; end
        if (not Object.Visible) then continue; end

        if (not Order[Object.ClassName]) then
            Order[Object.ClassName] = {};
        end

        table.insert(Order[Object.ClassName], Object);
    end

    --// Order each Class by AbsolutePosition
    for _, Objects in pairs(Order) do
        table.sort(Objects, function(a, b)
            return (a.AbsolutePosition.Y > b.AbsolutePosition.Y);
        end);
    end
    
    return Order
end

return PageAPI