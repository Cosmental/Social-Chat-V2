--[[
	nooneisback's SpriteClip module
	>> FPS Cap implemented by @CosRBX
	
	A Roblox module for easy sprite animation. The only function it has is .new which returns a SpriteClip object.
		
	SpriteClip
		Properties:
			<Instance> Adornee				Def: nil				Desc: The image object to work on.
			<string> SpriteSheet			Def: nil				Desc: The AssetId of the sprite sheet. Check value below.
			<bool> InheritSpriteSheet		Def: true				Desc: Whether the SpriteSheet value will automatically take the Image value of a GUI object when the Adornee is set.
			<number> CurrentFrame			Def: 1
			<Vector2> SpriteSizePixel		Def: (100,100)			Desc: Size of individual sprites in pixels
			<Vector2> SpriteOffsetPixel		Def: (0,0)				Desc: Offset between sprites
			<Vector2> EdgeOffsetPixel 		Def: (0,0)				Desc: Offset from sprite sheet's edge
			<number> SpriteCount  			Def: 25					Desc: Global sprite count
			<number> SpriteCountX  			Def: 5					Desc: Horizontal sprite count
			<number> FrameRate  			Def: 15					Desc: Framerate that gets turned into FrameTime, needs to be a divisor of 60
			<number> FrameTime 				Def: 4					Desc: How many frames to skip-1
			<number> Looped  				Def: true				Desc: If the CurrentFrame will reset after each cycle
			<bool> State					Def: false				Desc: Whether the animation is playing
			
		Functions:
			(<bool>success) :Play()			Desc: Sets the State property to true
			(<bool>success) :Pause()		Desc: Sets the State property to false
			(<bool>success) :Stop()			Desc: Pauses the animation and resets the CurrentFrame
			() :Advance(<number> count) 	Desc: Increments animation by the given number of frames or a single frame
			() :Destroy() 					Desc: Removes the animation from the list and clears its metatable.
			(<SpriteClip>clone) :Clone()	Desc: Creates a new SpriteClip with the same properties as the original. Doesn't copy Adornee.
	
]]--

local newVec2 = Vector2.new
local next = next
local newproxy = newproxy
local getmetatable = getmetatable

local SpriteClip = {};
local methods = {};

local realFrameRate = 60 -- This is the ABSOLUTE framelimit! Some monitors exceed 60 FPS, making some gifs render a little too quickly...

do
	local ClipList = {}
	local sorting = false

	local frame = 0
	local lastRender = os.clock();

	game:GetService("RunService").Heartbeat:Connect(function() -- RenderStepped can be intensive for player FPS
		if ((os.clock() - lastRender) < (1 / realFrameRate)) then return; end -- Anything above 60s looks wrong ~.~
		lastRender = os.clock();

		frame = frame+1
		if ClipList[1] then
			for animi=1,#ClipList do
				local animv = ClipList[animi]
				if animv.State then
					local frametime = animv.FrameTime
					if frame%frametime==0 then
						animv:Advance(1)
					end
				end
			end
		end
	end);

	methods.Play = function(self)
		if not self.State then
			if not self.Adornee then
				error("SpriteClip: No Instance assigned to this SpriteClip.")
				return false
			end
			self.State = true
			return true
		end
		return false
	end
	methods.Pause = function(self)
		if self.State then
			self.State = false
		end
		return false
	end
	methods.Stop = function(self)
		self:Pause()
		self.CurrentFrame = 0
		return true
	end
	methods.Advance = function(self,count)
		local frame = self.CurrentFrame+(count or 1)
		if frame>self.SpriteCount-1 then
			if self.Looped then
				frame=0
			else
				self:Stop()
				return
			end
		end
		self.CurrentFrame = frame
		local size = self.SpriteSizePixel
		local sizex,sizey = size.X,size.Y
		local off = self.SpriteOffsetPixel
		local offx,offy = off.X,off.Y
		local eoff = self.EdgeOffsetPixel
		local countx = self.SpriteCountX
		local count = self.SpriteCount
		local x = (frame)%countx
		local y = (frame-x)/countx
		x=eoff.X+x*(sizex+offx)
		y=eoff.Y+y*(sizey+offy)
		local img = self.Adornee
		img.ImageRectOffset = newVec2(x,y)
	end

	SpriteClip.new = function()
		local tab = {
			Adornee = nil,
			SpriteSheet = nil,
			InheritSpriteSheet = true,
			CurrentFrame = 0,
			SpriteSizePixel = newVec2(100,100),
			EdgeOffsetPixel = newVec2(0,0),
			SpriteOffsetPixel = newVec2(0,0),
			SpriteCount = 25,
			SpriteCountX = 5,
			FrameRate = 60,
			FrameTime = 60/10,
			Looped = true,
			State = false,
			Sorted = true,
		}
		for i,v in next, methods do
			tab[i]=v
		end
		local proxy = newproxy(true)
		local meta = getmetatable(proxy)
		meta.__index = tab
		meta.__newindex = function(self,i,v)
			tab[i]=v
			if i=="Adornee" or i=="SpriteSizePixel" then
				local img = tab.Adornee
				local size = tab.SpriteSizePixel
				if img then
					img.ImageRectSize = size
				end
				if i=="Adornee" then
					if tab.InheritSpriteSheet then
						tab.SpriteSheet = img.Image
					else
						img.Image = tab.SpriteSheet
					end
				end
			elseif i=="SpriteSheet" then
				if tab.Adornee then
					tab.Adornee.Image = v
				end
			elseif i=="FrameRate" then
				tab.FrameTime = 60/v
			end
		end
		meta.__metatable = "The metatable is locked"

		tab.Destroy = function(self)
			self:Pause()
			while sorting do task.wait() end
			sorting = true
			for i=1,#ClipList do
				if ClipList[i]==tab then
					ClipList[i],ClipList[#ClipList] = ClipList[#ClipList],nil
				end
			end
			sorting = false
			for i in next, meta do
				meta[i] = nil
			end
		end
		tab.Clone = function(self)
			local new = SpriteClip.new()
			for i,v in next, tab do
				if v~="Adornee" then
					new[i]=v
				end
			end
			return new
		end

		ClipList[#ClipList+1] = tab
		return proxy
	end
end

return SpriteClip