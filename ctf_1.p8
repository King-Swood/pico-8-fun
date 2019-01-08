pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- todo: make a state machine that manages whether the game is running, a score is being displayed, or the title screen.
-- todo: add a title screen
-- todo: add a "number of rounds" editor to the title screen
-- todo: add the option to "rotate" the controller to the title screen.
--		this will allow users to hold the controller like a wiimote.
-- todo: add sound effects


game=
{
	round = 0,
	roundsmax = 3,
	flag = nil,
	players = {},
	framerate = 60,
	roundtime = 20, -- seconds in each round
	scoretimer = 0,
	roundcomplete = false,
}

function roundreset()
	game.roundcomplete = false
	game.flag:roundreset()
	foreach(game.players,
		function(p)
			p:roundreset()
		end
	)
	game.round += 1
end

function _init()
	game.flag = actor_flag:new(7,8)
	add(game.players, actor_player:new(1,2,0))
	add(game.players, actor_player:new(13,14,1))
	actors:add(game.flag)
	actors:add(game.players[1])
	actors:add(game.players[2])
	roundreset()
end

function _update60()
	if (game.roundcomplete) then
		updatescoretimer()
	else
		if hasroundfinished() then
			game.scoretimer = 3 * game.framerate
			game.roundcomplete = true
		else
			foreach(actors,
				function(a)
					a:update()
					if (a.remove) then del(actors,a) end
				end
			)
		end
	end
end

function hasroundfinished()
	local i = 1
	local result = false
	while i <= count(game.players) do
		if (game.players[i].won) then
			result = true
			break
		end
		i += 1
	end
	return result
end

function gamehasfinished()
	local i = 1
	local result = false
	while i <= count(game.players) do
		if game.players[i].roundwins == game.roundsmax then
			result = true
			break
		end
		i += 1
	end
	return result
end

function updatescoretimer()
	if game.scoretimer > 0 then
		game.scoretimer -= 1
	elseif not gamehasfinished() then
		roundreset()
	end
end

function _draw()
	cls()
	drawmap()
	foreach(actors,
		function(a)
			a:draw()
		end
	)
	drawscore()
	if game.roundcomplete then
		drawplayerwon()
	end
end

function drawmap()
	map(0,0,0,8)
end

function drawscore()
	print("p1: "..flr((game.players[1].wintimer+(game.framerate-1))/game.framerate),5,0,10)
	print("round "..game.round,50,0,11)
	print("p2: "..flr((game.players[2].wintimer+(game.framerate-1))/game.framerate),93,0,10)
end

function drawplayerwon()
	foreach(game.players,
		function(p)
			if p.won then
				if gamehasfinished() then
					print("player " ..(p.player+1).. " won the game!!",14,61,1)
				else
					print("player " ..(p.player+1).. " won the round!!",14,61,1)
				end
			end
		end
	)
end

function sametile(a1,a2)
	if (a1.xcell == a2.xcell) and (a1.ycell == a2.ycell) then return true
	else return false
	end
end

actors=
{
	add=function(self,a)
		add(self,a)
	end,
}

actor_base =
{
	x=0,
	y=0,
	xcell=0,
	ycell=0,
	width=8,
	height=8,
	flipx=false,
	flipy=false,
	-- sprinit=0,
	-- sprite=0,
	-- sprmax=0,
	-- sprtime=0,
	-- sprtimemax=0,
	remove=false,
	curanim="initial",
	curframe=1,
	animtick=0,
	visible=true,

	-- x and y are the cells to draw in, not the pixel position.
	new=function(self,xcell,ycell)
		local o = setmetatable({}, self)
		self.__index = self
		o.xcell = xcell or 0
		o.ycell = ycell or 0
		return o
	end,

	init=function(self)
		self:set_anim("initial")
	end,

	update=function(self)
		if (self:outofbounds()) then self.remove=true end
		
		--anim tick
		self.animtick-=1
		if self.animtick<=0 then
			self.curframe+=1
			local a=self.anims[self.curanim]
			self.animtick=a.ticks--reset timer
			if self.curframe>#a.frames then
				self.curframe=1--loop
			end
		end

		self.x = (self.xcell * 8) + 4
		self.y = (self.ycell * 8) + 4
	end,
	
	draw=function(self)
		if self.visible then
			local a=self.anims[self.curanim]
			local frame=a.frames[self.curframe]
			spr(frame,
				self.x-(self.width/2),
				self.y-(self.height/2),
				self.width/8,self.height/8,
				self.flipx,
				self.flipy)
		end
	end,

	outofbounds=function(self)
		if ((self.x+self.width) < 0) then return true end
		if ((self.x) > 127) then return true end
		if ((self.y+self.height) < 0) then return true end
		if ((self.y) > 127) then return true end
	end,

	--animation definitions.
	--use with set_anim()
	anims=
	{
		["initial"]=
		{
			ticks=1,--how long is each frame shown.
			frames={0},--what frames are shown.
		},
	},
	
	set_anim=function(self,anim)
		if(anim==self.curanim)return--early out.
		local a=self.anims[anim]
		self.animtick=a.ticks--ticks count down.
		self.curanim=anim
		self.curframe=1
	end,
}

actor_player = actor_base:new()

function actor_player:new (xcell,ycell,playerno)
	local o = actor_base:new(xcell,ycell)
	setmetatable(o, self)
	self.__index = self
   
	o.sprinit=2
	o.sprmax=2
	o.init(o)
	o.player=playerno or 0
	o.roundwins = 0
	o.initialx = xcell
	o.initialy = ycell
	o.flag = false
	o.wintimer = 0
	o.won = false
	
	self.roundreset=function(self)
		self.flag = false
		self.wintimer = game.roundtime*game.framerate
		self.won = false
		self.xcell = self.initialx
		self.ycell = self.initialy
	end

	o.roundreset(o)

	self.update=function(self)
		if (btnp(0,self.player)) then
			self.newposition(self,self.xcell-1,self.ycell)
		end
		if (btnp(1,self.player)) then
			self.newposition(self,self.xcell+1,self.ycell)
		end
		if (btnp(2,self.player)) then
			self.newposition(self,self.xcell,self.ycell-1)
		end
		if (btnp(3,self.player)) then
			self.newposition(self,self.xcell,self.ycell+1)
		end
		actor_base.update(self)
		
		if self.flag then
			if self.wintimer > 0 then
				self.wintimer -= 1
			else
				self.won = true
				self.roundwins += 1
			end
		end
	end

	self.draw=function(self)
		if self.player == 1 then pal(4,12) end

		actor_base.draw(self)
		if self.flag then
			spr(19,
				self.x-(self.width/2),
				self.y-(self.height/2),
				self.width/8,self.height/8,
				self.flipx,
				self.flipy)
		end
		if self.player == 1 then pal() end
	end

	self.newposition=function(self,xcell,ycell)
		if (not fget(mget(xcell,ycell-1),0)) then
		   self.xcell = xcell
		   self.ycell = ycell
		   
			if self.curanim == "initial" then
				self:set_anim("walk")
			else
				self:set_anim("initial")
			end
		end

		foreach(game.players,
			function(p)
				if (p != self) then
					if (sametile(self, p)) then
						if p.flag then
							p.flag = false
							self.flag = true
						end
					end
				end
			end
		)


		-- todo: if both players land on the same tile at the same time then they bounce a single tile in opposite directions.
		-- todo: if one player was already on the tile, that player gets bumped out of the way and loses the flag if they had it.
		-- todo: after checking this, check to see if either have landed on the flag

		if (game.flag.visible) then
			if (sametile(self, game.flag)) then
				game.flag.visible = false
				self.flag = true
			end
		end
	end

	o.anims=
	{
		["initial"]=
		{
			ticks=0,--how long is each frame shown.
			frames={1},--what frames are shown.
		},
		["walk"]=
		{
			ticks=0,--how long is each frame shown.
			frames={2},--what frames are shown.
		},
	}

	return o
end

actor_flag = actor_base:new()

function actor_flag:new (xcell,ycell)
	local o = actor_base:new(xcell,ycell)
	setmetatable(o, self)
	self.__index = self
   
	o.sprinit=1
	o.sprmax=1
	o.visible = true
	o.init(o)
	
	self.roundreset=function(self)
		self.visible = true
	end

	self.roundreset(self)

	self.update=function(self)
		actor_base.update(self)
	end

	o.anims=
	{
		["initial"]=
		{
			ticks=30,--how long is each frame shown.
			frames={16,17,18},--what frames are shown.
		},
	}

	return o
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000440000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700004004000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000004004000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000440000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000400000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004040000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000bb000000bb000000bb000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbb0000bbbb0000bbbb00bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbb000bbbbb000bbbbb000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbb0000bbbb0000bbbb0000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000bb000000bb000000bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000100000001000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666ddddddd50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666d66666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666d66666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666d66666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666d66666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666d66666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666d66666650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666d55555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
414141414141414141414141414141000f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4140404040404040404040404040410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414141414141414141414141410000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000