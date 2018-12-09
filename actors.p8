pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
game=
{
	level=1,
}

function _init()
	actors:add(actor_base:new(50))
	actors:add(actor_paddle:new(100,0,0))
	actors:add(actor_paddle:new(110, 30,1))
	actors:add(actor_ball:new(0,0))
end

function _update60()
	foreach(actors,
		function(a)
			a:update()
			if (a.remove) then del(actors,a) end
		end
	)
end

function _draw()
	cls()
	drawmap()
	foreach(actors,
		function(a)
			a:draw()
		end
	)
end

function drawmap()
	if (game.level==1) then
		map(0,0,0,0)
	end
end
-->8
actors=
{
	add=function(self,a)
		add(self,a)
	end,
}

-- todo: copy the frames/animation stuff from stkit1_1
actor_base =
{
	x=0,
	y=0,
	width=8,
	height=8,
	flipx=false,
	flipy=false,
	sprinit=0,
	sprite=0,
	sprmax=0,
	sprtime=0,
	sprtimemax=0,
	remove=false,

	new=function(self,x,y)
		local o = setmetatable({}, self)
		self.__index = self
		o.x = x or 0
		o.y = y or 0
		return o
	end,

	init=function(self)
		self.sprite=self.sprinit
	end,

	update=function(self)
		self.y+=1
		if (self.sprtime > self.sprtimemax) then
		self.sprite+=1
		if (self.sprite > self.sprmax) then self.sprite=self.sprinit end
		else
		self.sprtime+=1
		end
		if (self:outofbounds()) then self.remove=true end
	end,
	

	draw=function(self)
		spr(self.sprite,
			self.x-(self.width/2),
			self.y-(self.height/2),
			self.width/8,self.height/8,
			self.flipx,
			self.flipy)
	end,

	outofbounds=function(self)
		if ((self.x+self.width) < 0) then return true end
		if ((self.x) > 127) then return true end
		if ((self.y+self.height) < 0) then return true end
		if ((self.y) > 127) then return true end
	end,
}

actor_paddle = actor_base:new()

function actor_paddle:new (x,y,playerno)
	local o = actor_base:new(x,y)
	setmetatable(o, self)
	self.__index = self
   
	o.sprinit=2
	o.sprmax=2
	o.init(o)
	o.player=playerno or 0

	self.update=function(self)
		if (btn(2,self.player)) then
			self.y-=2 end
		if (btn(3,self.player)) then
			self.y+=2 end
		actor_base.update(self)
	end

	return o
end

actor_ball = actor_base:new()

function actor_ball:new (x,y)
	local o = actor_base:new(x,y)
	setmetatable(o, self)
	self.__index = self
   
	o.sprinit=1
	o.sprmax=1
	o.init(o)

	self.update=function(self)
		self.x+=1
		actor_base.update(self)
	end

	return o
end

__gfx__
000000000aaaaa00cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777
00000000aa999aa0cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777
00700700a99999a0cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777
00077000a99999a0cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777
00077000a99999a0cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777
00700700aa999aa0cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777
000000000aaaaa00cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777
0000000000000000cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777777
__gff__
0000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
