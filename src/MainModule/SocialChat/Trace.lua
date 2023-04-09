--[[

    Name: Mari
    Date: 4/9/2023

    Description: This module helps developers with easier debugging!

]]--

--// Module
local Trace = {};
local Stack = {};
Stack.__index = Stack

--// Methods

--- Asserts that a condition is true
function Trace:Assert(Condition : any?, Message : string)
    if (Condition) then return; end

    local Source : string = debug.info(1, "s");
    error((Message).."\n"..(Source.."\n")..(debug.traceback()), 2);
end

--- Throws an error in the output
function Trace:Error(Message : string)
    local Source : string = debug.info(1, "s");
    error((Message).."\n"..(Source.."\n")..(debug.traceback()), 2);
end

return Trace