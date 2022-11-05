--[[

	Name: Cosmental
	Date: 7/19/2022
	
	Description: This utility helps to create new linked list arrays!

]]--

local LinkedListUtil = {};
local LinkedListMethods = {};

--// Constructor

function LinkedListUtil.new(customMethods : table?) : LinkedList -- Creates a new LinkedList!
    local metalist
    metalist = setmetatable({
        ["__list"] = {},
        ["Size"] = 0,

        ["First"] = false,
        ["Last"] = false,
    }, {
        __index = function(_, Index)
            if (LinkedListMethods[Index]) then
                return LinkedListMethods[Index];
            end

            if ((customMethods) and (customMethods[Index])) then
                return customMethods[Index];
            end

            return metalist.__list[Index];
        end,

        __newindex = function(_, Index, Value)
            if (Value == nil) then --> Removing a value...
                local Element = metalist.__list[Index];
                if (not Element) then return; end
            
                if (Element.Previous) then --> Just in case we remove the FIRST value
                    Element.Previous.Next = Element.Next
                end

                if (Element.Next) then --> Just in case we remvoe the LAST value
                    Element.Next.Previous = Element.Previous 
                end
            
                table.remove(metalist.__list, table.find(metalist.__list, Element));
            else
                if (metalist.__list[Index]) then --> Index already exists! (Probably changing values...)
                    metalist.__list[Index].Value = Value
                else --> Index is new! (Create new linkedlist object)
                    local Prior = ((metalist.Last and table.find(metalist.__list, metalist.Last)) or 1);
                    local Element = {
                        ["Value"] = Value,
                        ["Previous"] = metalist.__list[(Prior > 1 and (Prior - 1)) or 1];
                    };
                
                    if (not metalist.First) then
                        metalist.First = Element
                    else
                        metalist.Last.Next = Element
                    end
                
                    metalist.Last = Element
                    table.insert(metalist.__list, Element);

                    metalist.Size += 1
                    return Element
                end
            
            end
        end
    });

    return metalist
end

--// Methods

--- Placeholder until roblox adds the "__iter" metamethod. This does the same thing as a "for i, v" loop
function LinkedListMethods:Iter(Callback : callback)
    for Index, Data in pairs(self.__list) do
        local cancelFurtherIterations = Callback(Index, Data);
        if (cancelFurtherIterations) then break; end --> If our callback returns TRUE, we can break any further iterations
    end
end

return LinkedListUtil