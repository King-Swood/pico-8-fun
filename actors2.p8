pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
actors={}
game={}

-- todo: works, but don't know how to pass x/y into the base class....
function _init()
	add(actors,actor_base:new())
	add(actors,actor_paddle:new{x=50,y=100})
--  game.level=1
--  paddleadd(0,60,0)
--  paddleadd(120,60,1)
end

function _update()
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
actor_base =
{
	x=0,
	y=0,
	pw=8,	-- width in pixels
	ph=8, -- height in pixels
	fx=false,
	fy=false,
	sprinit=0,
	sprite=0,
	sprmax=0,
	sprtime=0,
	sprtimemax=0,
	sw=1, -- sprite width
	sh=1, -- sprite height
	remove=false,

	new=function(self,a)
		local a = a or {}
		setmetatable(a, self)
		self.__index = self
		return a
	end,

	init=function(self)
		sprite=sprinit
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
		-- todo: copy the draw function from stkit1_1
		spr(self.sprite,self.x,self.y,self.sw,self.sh,self.fx,self.fy)
	end,

	outofbounds=function(self)
		if ((self.x+self.pw) < 0) then return true end
		if ((self.x) > 127) then return true end
		if ((self.y+self.ph) < 0) then return true end
		if ((self.y) > 127) then return true end
	end,
}

actor_paddle = actor_base:new()

function actor_paddle:new (a,playerno)
   a = a or actor_base:new(a)
   setmetatable(a, self)
   self.__index = self
   
	a.sprinit=2
	a.sprmax=2
	a:init()
	a.player=playerno

	a.update=function(self)
		if (btn(2,self.player)) then
			self.y-=2 end
		if (btn(3,self.player)) then
			self.y+=2 end
		actor_base.update(self)
	end

	return a
end


-- function actorupdate(a)
--  if (a.sprtime > a.sprtimemax) then
--   a.spr+=1
--   if (a.spr > a.sprmax) then a.spr=a.sprinit end
--  else
--   a.sprtime+=1
--  end
--  if (actoroutofbounds(a)) then a.remove=true end
-- end

-- function actordraw(a)
--  spr(a.spr,a.x,a.y,a.sw,a.sh,a.fx,a.fy)
-- end
-->8
-- paddle=actor_base:new()
-- function paddle:new()

-- end

-- function paddleadd(x,y,player)
--  a=actoradd(x,y)
--  if (player==1) then a.fx=true end
--  a.sprinit=2
--  a.spr=a.sprinit
--  a.sprmax=2
--  a.update=paddleupdate
--  a.player=player
-- end

-- function paddleupdate(a)
--  actorupdate(a)
--  if (btn(2,a.player)) then
--   a.y-=1
--  end
--  if (btn(3,a.player)) then
--   a.y+=1
--  end
-- end
-- -->8
-- function balladd(x,y)
--  a=actoradd(x,y)
--  a.sprinit=1
--  a.sprmax=1
--  a.update=ballupdate
-- end

-- function ballupdate(a)
--  actorupdate(a)
--  a.x+=1
-- end
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
