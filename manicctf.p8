pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

-- todo: add a final winners screen which displays who won, and the state of their win calculated from the difference in times across the rounds.
--			by a long shot
--			by a small margin
--			only just...
-- todo: add sound effects
-- todo: consider pushing into the "incomplete" part of the forum.
-- todo: add a "starting in 3...2...1" message at the beginning of each round.
--			the players should only become visible after this, and they should appear in a little cloud so their colour is temporarily masked.
-- todo: randomise the corner that each player starts in, so they don't just start marching straight toward the flag.
-- todo: when game is over it should display the message for a few seconds, then tell the user to press x to return to the main screen.
-- todo: when the menu first displays the flag should appear on the bottom in a puff of smoke.
--			player 1 runs on, grabs, it and runs off screen
--			both players then are shown periodically chasing the other off-screen, with the player in front always holding the flag.
-- todo: centre the playing field on screen.
-- todo: setup on raspberry pi to do some playtesting with sarah.
-- todo: fix bug where if the flag is dropped it momentarily appears where it last was.
-- todo: fix bug where players might be able to randomly be moved to out-of-bounds.
-- todo: fix bug where a player can randomly be placed on the flag and then not pick it up.

-- todo:	fix random movements.
--			they are a good idea, however they should still take into account the direction the player wishes to go.
--			so instead of moving in any direction, the random variable should hold either: any, up, down, left, or right.
--			then when we generate the random movement, if the player is randomly moving up, then y definitely decreases by 1, but x could be either -1, +1, or 0.

-- todo: atm the flag starts the new round wherever it was when the previous round finished. Decide whether we want this, or it should reset to middle.

function _init()
end

function _update60()
	game_state:update()
end

function _draw()
	game_state:draw()
end

enabledebug = true
-- enabledebug = false

function debug(str)
	if enabledebug then
		printh(str)
	end
end

game_state =
{
	-- curstate="initial",
	-- curstate="menu",
	curstate="game",
	changed=true,

	states=
	{
		["initial"]=
		{
			init=function()
				titlescreen:init()
			end,
			update=function()
				titlescreen:update()
			end,
			draw=function()
				titlescreen:draw()
			end,
		},
		["menu"]=
		{
			init=function()
				menu:init()
			end,
			update=function()
				menu:update()
			end,
			draw=function()
				menu:draw()
			end,
		},
		["game"]=
		{
			init=function()
				game:init()
			end,
			update=function()
				game:update()
			end,
			draw=function()
				game:draw()
			end,
		},
	},
	
	set_state=function(self,state)
		self.curstate=state
		self.changed=true
	end,

	init=function(self)
		self.states[self.curstate].init(self)
	end,

	update=function(self)
		repeat
			if self.changed then
				self.changed=false
				self:init()
			end
			self.states[self.curstate].update(self)
		until self.changed ~= true
	end,

	draw=function(self)
		self.states[self.curstate].draw(self)
	end,
}

actors=
{
	list={},
	add=function(self,a)
		add(self.list,a)
	end,
	clear=function(self)
		self.list={}
	end,
	update=function(self)
		foreach(self.list,
			function(a)
				a:update()
				if (a.remove) then del(self.list,a) end
			end
		)
	end,
	draw=function(self)
		foreach(self.list,
			function(a)
				a:draw()
			end
		)
	end,
}

actor_base =
{
	x=0,
	y=0,
	xcell=0,
	ycell=0,
	xcelllast=0,
	ycelllast=0,
	width=8,
	height=8,
	flipx=false,
	flipy=false,
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
		o.xcelllast = o.xcell
		o.ycell = ycell or 0
		o.ycelllast = o.ycell
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

function skipscreen()
	if (btnp(4,0) or btnp(5,0) or btnp(4,0) or btnp(5,0)) then
		return true
	else
		return false
	end
end

titlescreen=
{
	x=14,
	y=-5,
	yspeedfast=1,
	yspeedslow=0.25,
	yspeed=0,
	setpoint1=40,
	setpoint2=80,
	colour=1,
	colourtimer=0,
	colourtimermax=15,
	displayname=false,
	skipped=false,

	init=function(self)
		self.displaytime = 0
		actors:clear()
		self.yspeed=self.yspeedfast
	end,

	update=function(self)
		if (not self.skipped) then
			if (skipscreen()) then
				self.skipped=true
				self.displayname=false
				self.yspeed=self.yspeedfast*3
			else
				if (self.y >= self.setpoint2) then
					self.yspeed=self.yspeedfast
					self.displayname=false
				elseif (self.y >= self.setpoint1) then
					self.yspeed=self.yspeedslow
					self.displayname=true
				end
			end
		end
		if (self.y>=128) then
			game_state:set_state("menu")
		end
		self.y+=self.yspeed
		if (self.colourtimer>=self.colourtimermax) then
			self.colourtimer=0
			self.colour+=1
			if (self.colour>15) then
				self.colour=1
			end
		end
		self.colourtimer+=1
	end,

	draw=function(self)
		cls()
		print("manic ctf",self.x,self.y,self.colour)
		if (self.displayname) then
			print("by darren pearce",55,61,10)
		end
	end,
}

menu=
{
	p1rotated=false,
	p2rotated=false,
	p2ai=false,
	x=20,
	y=40,
	spacebetween=10,
	currentitem=1,
	items=
	{
		{
			currentindex=1,
			options=
			{
				"start"
			},
			onchanged=function(self, button)
				if (button == 4) or (button == 5) then game_state:set_state("game") end
			end
		},
		{
			currentindex=1,
			options=
			{
				"p1 normal controller",
				"p1 rotated controller"
			},
			onchanged=function(self, button)
				if self:getcurrentvalueindex() == 2 then menu.p1rotated = true else menu.p1rotated = false end
			end
		},
		{
			currentindex=1,
			options=
			{
				"p2 normal controller",
				"p2 rotated controller",
				"p2 ai"
			},
			onchanged=function(self, button)
				if self:getcurrentvalueindex() == 2 then menu.p1rotated = true else menu.p1rotated = false end
				if self:getcurrentvalueindex() == 3 then menu.p2ai = true else menu.p2ai = false end
				debug(menu.p2ai)
			end
		},
	},

	init=function(self)
		actors:clear()
		self.currentitem=1
		for i=1,count(self.items) do
			self.items[i].onchanged(self,-1)
		end
	end,

	update=function(self)
		if (btnp(3,0)) then
			self:changecurrentitem(1)
		elseif (btnp(2,0)) then
			self:changecurrentitem(-1)
		elseif (btnp(0,0)) then
			self:changecurrentvalue(-1)
			self.items[self.currentitem].onchanged(self,0)
		elseif (btnp(1,0)) then
			self:changecurrentvalue(1)
			self:getcurrentitem().onchanged(self,1)
		elseif btnp(4,0)then
			self:getcurrentitem().onchanged(self,4)
		elseif btnp(5,0) then
			self:getcurrentitem().onchanged(self,5)
		end
	end,

	draw=function(self)
		cls()
		actors:draw()
		
		for i=1,count(self.items) do
			local colour = 10
			if (self.currentitem==i) then
				colour=11
			end
			print(self.items[i].options[self.items[i].currentindex],self.x,self.y+((i-1)*self.spacebetween),colour)
		end
	end,

	getcurrentitem=function(self)
		return self.items[self.currentitem]
	end,

	getcurrentvalueindex=function(self)
		return self.items[self.currentitem].currentindex
	end,

	changecurrentitem=function(self, dir)
		if dir > 0 then
			self.currentitem+=1
			if (self.currentitem>count(self.items)) then
				self.currentitem=1
			end
		elseif dir < 0 then
			self.currentitem-=1
			if (self.currentitem<1) then
				self.currentitem=count(self.items)
			end
		end
	end,

	changecurrentvalue=function(self, dir)
		if (dir > 0) then
			local currentitem = self.items[self.currentitem]
			currentitem.currentindex+=1
			if (currentitem.currentindex>count(currentitem.options)) then
				currentitem.currentindex=1
			end
		elseif (dir < 0) then
			local currentitem = self.items[self.currentitem]
			currentitem.currentindex-=1
			if (currentitem.currentindex<1) then
				currentitem.currentindex=count(currentitem.options)
			end
		end
	end,
}

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

	init=function(self)
		self.flag = actor_flag:new(7,8)
		self.players={}
		add(self.players, actor_player:new(1,2,1,false, menu.p1rotated))
		add(self.players, actor_player:new(13,14,2,menu.p2ai, menu.p2rotated))
		actors:clear()
		actors:add(self.flag)
		actors:add(self.players[1])
		actors:add(self.players[2])
		self.players[2].flipx = true
		self:roundreset()
	end,

	update=function(self)
		if (self.roundcomplete) then
			self:updatescoretimer()
		else
			if self:hasroundfinished() then
				self.scoretimer = 3 * self.framerate
				self.roundcomplete = true
			else
				actors:update()
			end
		end
	end,

	draw=function(self)
		cls()
		self:drawmap()
		actors:draw()
		self:drawscore()
		if self.roundcomplete then
			self:drawplayerwon()
		end
	end,

	roundreset=function(self)
		self.roundcomplete = false
		self.flag:roundreset()
		foreach(self.players,
			function(p)
				p:roundreset()
			end
		)
		self.round += 1
	end,

	hasroundfinished=function(self)
		local i = 1
		local result = false
		while i <= count(self.players) do
			if (self.players[i].won) then
				result = true
				break
			end
			i += 1
		end
		return result
	end,

	gamehasfinished=function(self)
		local i = 1
		local result = false
		while i <= count(self.players) do
			if self.players[i].roundwins == self.roundsmax then
				result = true
				break
			end
			i += 1
		end
		return result
	end,

	updatescoretimer=function(self)
		if self.scoretimer > 0 then
			self.scoretimer -= 1
		elseif not self:gamehasfinished() then
			self:roundreset()
		end
	end,

	drawmap=function(self)
		map(0,0,0,8)
	end,

	drawscore=function(self)
		print("p1: "..flr((self.players[1].wintimer+(self.framerate-1))/self.framerate),5,0,self.players[1].colour)
		print("round "..self.round,50,0,11)
		print("p2: "..flr((self.players[2].wintimer+(self.framerate-1))/self.framerate),93,0,self.players[2].colour)
	end,

	drawplayerwon=function(self)
		foreach(self.players,
			function(p)
				if p.won then
					if self:gamehasfinished() then
						print("player " ..(p.player).. " won the game!!",14,61,1)
					else
						print("player " ..(p.player).. " won the round!!",14,61,1)
					end
				end
			end
		)
	end,
}

function sametile(a1,a2)
	if (a1.xcell == a2.xcell) and (a1.ycell == a2.ycell) then return true
	else return false
	end
end

actor_player = actor_base:new()

function actor_player:new (xcell,ycell,playerno,ai,rotate)
	local o = actor_base:new(xcell,ycell)
	setmetatable(o, self)
	self.__index = self
   
	o.init(o)
	o.player=playerno or 1
	o.roundwins = 0
	o.initialx = xcell
	o.initialy = ycell
	o.flag = false
	o.wintimer = 0
	o.won = false
	o.colour = 4
	o.ai = ai or false
	o.reacttime = 0
	o.reactmin = 10
	o.rotate = rotate or false
	o.falltimer = 0

	if (o.player==2) then
		o.colour=12
	end
	
	self.roundreset=function(self)
		self.flag = false
		self.wintimer = game.roundtime*game.framerate
		self.won = false
		self.xcell = self.initialx
		self.ycell = self.initialy
		self.xcelllast = self.xcell
		self.ycelllast = self.ycell
	end

	o.roundreset(o)

	self.update=function(self)

		if self.curanim == "fallen" then
			self.falltimer += 1
			if self.falltimer >= 60 then
				self:set_anim("initial")
			else
				actor_base.update(self)
				return
			end
		end

		local oldx = self.xcell

		if self.ai then
			self:updateai()
		else
			self:updatehuman()
		end
		actor_base.update(self)

		if self.xcell < oldx then
			self.flipx = true
		elseif self.xcell > oldx then
			self.flipx = false
		end		
		
		if self.flag then
			if self.wintimer > 0 then
				self.wintimer -= 1
			else
				self.won = true
				self.roundwins += 1
			end
		end
	end

	self.updatehuman=function(self)
		local left = (self.rotate == false) and 0 or 3
		local right = (self.rotate == false) and 1 or 2
		local up = (self.rotate == false) and 2 or 0
		local down = (self.rotate == false) and 3 or 1

		if (btnp(left,self.player-1)) then
			self:newposition(self.xcell-1,self.ycell)
		end
		if (btnp(right,self.player-1)) then
			self:newposition(self.xcell+1,self.ycell)
		end
		if (btnp(up,self.player-1)) then
			self:newposition(self.xcell,self.ycell-1)
		end
		if (btnp(down,self.player-1)) then
			self:newposition(self.xcell,self.ycell+1)
		end
	end

	self.updateai=function(self)
		self.reacttime += 1
		if self.reacttime < self.reactmin then
			return
		end
		self.reacttime = 0
		local target = {xcell=0,ycell=0}
		local otherplayer
		local targetisotherplayer = false
		local towards = 1
		if self.player == 1 then
			otherplayer = game.players[2]
		else
			otherplayer = game.players[1]
		end
		-- find the target the player should try and move towards
		if self.flag then
			target = {xcell=otherplayer.xcell,ycell=otherplayer.ycell}
			targetisotherplayer = true
			towards = -1
		else
			if otherplayer.flag then
				target = {xcell=otherplayer.xcell,ycell=otherplayer.ycell}
				targetisotherplayer = true
			else
				target = {xcell=game.flag.xcell,ycell=game.flag.ycell}
			end
		end

		debug("p "..tostr(self.player).." target: x:"..tostr(target.xcell)..", y:"..tostr(target.ycell)..", towards: "..tostr(towards))

		-- add the small possibility of a random movement.
		local randommove = false
		
		-- check if both players are in the same cell
		if targetisotherplayer and (self.xcell == target.xcell) and (self.ycell == target.ycell) then
			if self.flag then
				-- if the current player has the flag the should run towards the quadrant which they are farthest from.
				local x = 0
				local y = 0
				if self.xcell < 8 then
					x = 1
				else
					x = -1
				end
				if self.ycell < 8 then
					y = 1
				else
					y = -1
				end
				self:newposition(self.xcell+x,self.ycell+y)
			else
				-- if the current player doesn't have the flag they should move randomly.
				randommove = true
			end
		else
			if self.flag then
				if rnd(100) > 65 then
					randommove = true
				end
			else
				if rnd(100) > 95 then
					randommove = true
				end
			end
			
			if not randommove then
				if abs(target.xcell-self.xcell) > abs(target.ycell-self.ycell) then
					-- move in x direction
					if target.xcell > self.xcell then
						self:newposition(self.xcell+towards,self.ycell)
					elseif target.xcell < self.xcell then
						self:newposition(self.xcell-towards,self.ycell)
					else
						randommove = true
					end
				elseif abs(target.xcell-self.xcell) < abs(target.ycell-self.ycell) then
					-- move in y direction
					if target.ycell > self.ycell then
						self:newposition(self.xcell,self.ycell+towards)
					elseif target.ycell < self.ycell then
						self:newposition(self.xcell,self.ycell-towards)
					else
						randommove = true
					end
				else
					randommove = true
				end
			end
		end
		
		if randommove then
			local dirx = 0
			local diry = 0
			if self.xcell < target.xcell then
				dirx = 1
			elseif self.xcell > target.xcell then
				dirx = -1
			end
			
			if self.ycell < target.ycell then
				diry = 1
			elseif self.ycell > target.ycell then
				diry = -1
			end
			self:moverandom(dirx, diry)
		end
	end

	self.moverandom=function(self, dirx, diry)
		dirx = dirx or 0
		diry = diry or 0

		local x = dirx
		if x == 0 then
			x = flr(rnd(3))-1
		end

		local y = diry
		if y == 0 then
			y = flr(rnd(3))-1
		end

		if y ~= 0 and x ~= 0 then
			if (rnd(2)) == 1 then
				y = 0
			else
				x = 0
			end
		end

		-- debug("p "..tostr(self.player).." random move")
		-- local x = flr(rnd(3))-1
		-- local y = flr(rnd(3))-1
		self:newposition(self.xcell+x,self.ycell+y)
	end

	self.draw=function(self)
		pal(4,self.colour)

		actor_base.draw(self)
		if self.flag then
			spr(3,
				self.x-(self.width/2),
				self.y-(self.height/2),
				self.width/8,self.height/8,
				self.flipx,
				self.flipy)
		end
		pal()
	end

	self.newposition=function(self,xcell,ycell)
		if (not fget(mget(xcell,ycell-1),0)) then
		   self.xcell = xcell
		   self.ycell = ycell

			if (self.xcelllast ~= self.xcell) or (self.ycelllast ~= self.ycell) then
				if self.curanim == "initial" then
					self:set_anim("walk")
				elseif self.curanim == "walk" then
					self:set_anim("initial")
				end

				foreach(game.players,
					function(p)
						if (p != self) then
							if (sametile(self, p)) then
								p:fallrandom()

								if self.flag then
									self.flag = false
									game.flag:drop(self.xcell, self.ycell)
									self:fallrandom()
									debug("player "..tostr(self.player).." dropped the flag")
								elseif p.flag then
									p.flag = false
									self.flag = true
									debug("player "..tostr(self.player).." stole the flag")
								else
									self:fallrandom()
								end

								while sametile(self, p) do
									p:moverandom()
								end
							end
						end
					end
				)
			end

			self.xcelllast = self.xcell
			self.ycelllast = self.ycell
		end

		if (game.flag.visible) then
			if (sametile(self, game.flag)) then
				game.flag.visible = false
				self.flag = true
			end
		end
	end

	self.fallrandom=function(self)
		if self.curanim ~= "fallen" then
			self:set_anim("fallen")
			self.falltimer = 0
			self:moverandom()
		end
	end

	o.anims=
	{
		["initial"]=
		{
			ticks=0,
			frames={1},
		},
		["walk"]=
		{
			ticks=0,
			frames={2},
		},
		["fallen"]=
		{
			ticks=15,
			frames={4,5},
		},
	}

	return o
end

actor_flag = actor_base:new()

function actor_flag:new (xcell,ycell)
	local o = actor_base:new(xcell,ycell)
	setmetatable(o, self)
	self.__index = self
   
	o.visible = true
	o.init(o)
	
	self.roundreset=function(self)
		self.visible = true
	end

	self:roundreset()

	self.drop=function(self, xcell, ycell)
		self.xcell = xcell
		self.ycell = ycell
		self.visible = true
	end

	o.anims=
	{
		["initial"]=
		{
			ticks=15,--how long is each frame shown.
			frames={16,17,18,19,20,21,22,23},--what frames are shown.
		},
	}

	return o
end

__gfx__
00000000000000000000000000000000070700700070700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000440000004400033300000000440000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700004004000040040003300000004004000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000004004000040040033300000004004000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000440000004400000100000000440000004400000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000400000004000000000000000400000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004040000004000000000000004440000044400000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333330033333003333300333330033333003333300333333033333330000000000000000000000000000000000000000000000000000000000000000
00333333003333330033333300333333003333330333333333333333303333330000000000000000000000000000000000000000000000000000000000000000
00003333000033330000333300033333003333330030333300003333000033330000000000000000000000000000000000000000000000000000000000000000
00333333003333330033333300303333000033330003333300333333003333330000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333033333300333333033333330000000000000000000000000000000000000000000000000000000000000000
00000001000003310000330100033001003300010330000133000001300000010000000000000000000000000000000000000000000000000000000000000000
00000001000000010000000100000001000000010000000100000001000000010000000000000000000000000000000000000000000000000000000000000000
00000001000000010000000100000001000000010000000100000001000000010000000000000000000000000000000000000000000000000000000000000000
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
