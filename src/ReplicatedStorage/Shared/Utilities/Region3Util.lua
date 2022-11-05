--[[

	Name: Cosmental
	Date: 8/8/2021
	
	Description: This module contains a lot of useful Region3 functions that I collected over on the devforums
	(because Region3s are stupidly complicated LOL) and compiled my findings into a singular module!
	
	-------------------------------------------------------------------------------------------------------------
	
	Credits:
	
	@@ [ XAXA ] || PartToRegion3 function
	@@ [ TOP_Crundee123 ] || Corner Checking method

]]--

--// Constants
local Vertices = {
	{1, 1, -1}, --// Top front right
	{1, -1, -1}, --// Bottom front right
	{-1, -1, -1},--// Bottom front left
	{-1, 1, -1}, --// Top front left

	{1, 1, 1},  --// Top back right
	{1, -1, 1}, --// Bottom back right
	{-1, -1, 1},--// Bottom back left
	{-1, 1, 1}  --// Top back left
};

--// Module
local Region3API = {};

--- Converts a simple Part into a convex Region3 using an algorythm
--@treturn Region3
function Region3API:CreateRegion(Object : Instance)
	assert(typeof(Object) == "Instance", "Expected an Instance to convert into a Region3, got "..(typeof(Object)));
	assert(Object:IsA("Part"), "Expected Object to be of type \"Part\", got "..(Object.ClassName));

	local AbsoluteCFrame = Object.CFrame
	local AbsoluteSize = Object.Size

	--// Creating our Region3
	local abs = math.abs

	local SizeX, SizeY, SizeZ = AbsoluteSize.X, AbsoluteSize.Y, AbsoluteSize.Z
	local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = AbsoluteCFrame:GetComponents();

	local WSX = 0.5 * (abs(R00) * SizeX + abs(R01) * SizeY + abs(R02) * SizeZ)
	local WSY = 0.5 * (abs(R10) * SizeX + abs(R11) * SizeY + abs(R12) * SizeZ)
	local WSZ = 0.5 * (abs(R20) * SizeX + abs(R21) * SizeY + abs(R22) * SizeZ)

	local MinX = X - WSX
	local MinY = Y - WSY
	local MinZ = Z - WSZ

	local MaxX = X + WSX
	local MaxY = Y + WSY
	local MaxZ = Z + WSZ

	local Min, Max = Vector3.new(MinX, MinY, MinZ), Vector3.new(MaxX, MaxY, MaxZ);
	return Region3.new(Min, Max); --// Returns an accurate Region3 based on our Instance
end

--- Returns a boolean value based on whether or not a Vector3 point is within the bounds of a Region3 datamodel
-- @treturn boolean
function Region3API:IsPointInRegion(Position : Vector3, Region : Region3)
	assert(typeof(Position) == "Vector3", "The provided Position was expected to be a \"Vector3\" parameter, recieved "..(typeof(Position)));
	assert(typeof(Region) == "Region3", "Expected Region3 as a valid Region, got "..(typeof(Region)));
	
	local RelativePos = (
		(Position - Region.Position)
			/ Region.Size
	);

	local InRegion = (
		-0.5 <= RelativePos.X
			and RelativePos.X <= 0.5
			and -0.5 <= RelativePos.Y 
			and RelativePos.Y <= 0.5
			and -0.5 <= RelativePos.Z 
			and RelativePos.Z <= 0.5
	);

	return InRegion --// Returns true/false depending on weather a Vector3 is within the bounds of the given Region3
end

--- Returns a boolean based on whether or not the bounds of the provided Object are within the bounds of the provided Region3
-- @treturn boolean
function Region3API:AreBoundsInRegion(Object : Instance, Region : Region3)
	assert(typeof(Object) == "Instance", "Expected Instances to determines bounds, got "..(typeof(Object)));
	assert(typeof(Region) == "Region3", "Expected Region3 to determine bounds, got "..(typeof(Region)));
	assert(Object:IsA("BasePart") or Object:IsA("Model"), "Expected BasePart/Model to retrieve bounds from, got "..(Object.ClassName));

	local ObjectCFrame
	local ObjectSize

	if (Object:IsA("BasePart")) then
		ObjectCFrame = Object.CFrame
		ObjectSize = Object.Size
	elseif (Object:IsA("Model")) then
		ObjectCFrame, ObjectSize = Object:GetBoundingBox();
	end

	--// Check corners	
	for _, Vector in pairs(Vertices) do
		local CornerPos = (
			ObjectCFrame 
				* CFrame.new(
					ObjectSize.X / 2 * Vector[1],
					ObjectSize.Y / 2 * Vector[2],
					ObjectSize.Z / 2 * Vector[3]
				)
		).Position

		--// Region Checking
		if (Region3API:IsPointInRegion(CornerPos, Region)) then return true; end
	end
end

return Region3API