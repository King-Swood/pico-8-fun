pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

-- todo: add a final winners screen which displays who won, and the state of their win calculated from the difference in times across the rounds.
--			by a long shot
--			by a small margin
--			only just...
-- todo: add sound effects
-- todo: consider pushing into the "incomplete" part of the forum.
-- todo: when game is over it should display the message for a few seconds, then tell the user to press x to return to the main screen.
-- todo: when the menu first displays the flag should appear on the bottom in a puff of smoke.
--			player 1 runs on, grabs, it and runs off screen
--			both players then are shown periodically chasing the other off-screen, with the player in front always holding the flag.
-- todo: centre the playing field on screen.
-- todo: setup on raspberry pi to do some playtesting with sarah.
-- todo: fix bug where players might be able to randomly be moved to out-of-bounds.
-- todo: fix bug where a player can randomly be placed on the flag and then not pick it up.

-- todo:	fix random movements.
--			they are a good idea, however they should still take into account the direction the player wishes to go.
--			so instead of moving in any direction, the random variable should hold either: any, up, down, left, or right.
--			then when we generate the random movement, if the player is randomly moving up, then y definitely decreases by 1, but x could be either -1, +1, or 0.

-- todo: atm the flag starts the new round wherever it was when the previous round finished. Decide whether we want this, or it should reset to middle.
-- todo: fix bug where after the first round finishes, the players then move 2 cells at a time instead of just one.
-- todo: fix bug where after the first round finishes, the countdown timer appears to be running at double speed.

enabledebug = true
-- enabledebug = false

function _init()
	title_init()
end

function title_init()
	_update60=title_update
	_draw=title_draw

	t={}
	t.x=14
	t.y=-5
	t.yspeedfast=1
	t.yspeedslow=0.25
	t.yspeed=t.yspeedfast
	t.setpoint1=40
	t.setpoint2=80
	t.colour=1
	t.colourtimer=0
	t.colourtimermax=15
	t.displayname=false
	t.skipped=false
	t.displaytime=0
end

function title_update()
	if (not t.skipped) then
		if (skipscreen()) then
			t.skipped=true
			t.displayname=false
			t.yspeed=t.yspeedfast*3
		else
			if (t.y >= t.setpoint2) then
				t.yspeed=t.yspeedfast
				t.displayname=false
			elseif (t.y >= t.setpoint1) then
				t.yspeed=t.yspeedslow
				t.displayname=true
			end
		end
	end
	if (t.y>=128) then
		menu_init()
	end
	t.y+=t.yspeed
	if (t.colourtimer>=t.colourtimermax) then
		t.colourtimer=0
		t.colour+=1
		if (t.colour>15) then
			t.colour=1
		end
	end
	t.colourtimer+=1
end

function title_draw()
	cls()
	print("manic ctf",t.x,t.y,t.colour)
	if (t.displayname) then
		print("by darren pearce",55,61,10)
	end
end

function skipscreen()
	if (btnp(4,0) or btnp(5,0) or btnp(4,0) or btnp(5,0)) then
		return true
	else
		return false
	end
end

function menu_init()
	_update60=menu_update
	_draw=menu_draw

	menu={}
	menu.p1rotate=false
	menu.p2rotate=false
	menu.p2ai=false
end

function menu_update()
	if (btnp(4) or btnp(5)) game_init()
end

function menu_draw()
	cls()
	map(0,0)
	print("manic ctf!!",22,24,9)

	print("steal the flag",32,50,10)
	print("and run!!!",40,64,10)

	print("press ❎ to start!",27,100,12)
end

function game_init()
	_update60=game_update
	_draw=game_draw

	g={}
	g.corners =
	{
		{
			x = 1,
			y = 2
		},
		{
			x = 13,
			y = 2
		},
		{
			x = 13,
			y = 14
		},
		{
			x = 1,
			y = 14
		}
	}
	g.round = 0
	g.roundsmax = 3
	g.players = {}
	g.playerstats={game_stats_create(),game_stats_create()}
	g.anims={}
	g.framerate = 60
	g.roundtime = 20 -- seconds in each round
	g.scoretimer = 0
	g.roundcomplete = false
	g.starttimer = 0

	game_round_init()
end

function game_update()
	anim_update(g.flag)
	foreach(g.anims,
		function(a)
			anim_update(a)
			if (a.remove) then del(g.anims,a) end
		end
	)

	if (g.roundcomplete) then
		updatescoretimer()
	else
		if g.starttimer > 0 then
			if game_update_start_timer(g) then
				foreach(g.players,
					function(p)
						p.visible=true
						add(g.anims, smoke_create(p.x,p.y))
					end
				)
			end
		elseif game_has_round_finished(g) then
			g.scoretimer = 3 * g.framerate
			g.roundcomplete = true
		else
			foreach(g.players, player_update)
			for i=1,2 do
				game_stats_update(g.playerstats[i], g.players[i])
			end
		end
	end
end

function game_draw()
	cls()
	map(0,0,0,8)
	anim_draw(g.flag)
	foreach(g.players, player_draw)
	foreach(g.anims, anim_draw)
	game_draw_score(g)
	if g.roundcomplete then
		game_draw_player_won(g)
	elseif g.starttimer > 0 then
		game_draw_start_time(g)
	end
end

function game_draw_start_time(self)
	print("starting in "..flr((self.starttimer/self.framerate)+1).."..",28,58,1)
end

function game_draw_score(self)
	print("p1: "..flr((self.playerstats[1].wintimer+(self.framerate-1))/self.framerate),5,0,self.players[1].colour)
	print("round "..self.round,50,0,11)
	print("p2: "..flr((self.playerstats[2].wintimer+(self.framerate-1))/self.framerate),93,0,self.players[2].colour)
end

function game_draw_player_won(self)
	for i=1,2 do
		if g.playerstats[i].won then
			if game_has_finished() then
				print("player " ..(i).. " won the game!!",14,61,1)
			else
				print("player " ..(i).. " won the round!!",14,61,1)
			end
		end
	end
end

function game_has_finished()
	local i = 1
	local result = false
	while i <= count(g.playerstats) do
		if g.playerstats[i].roundwins == self.roundsmax then
			result = true
			break
		end
		i += 1
	end
	return result
end

function game_stats_create()
	local o={}
	o.roundwins=0
	o.wintimer=0
	o.won=false
	return o
end

function game_stats_update(s, player)
	if player.flag then
		if s.wintimer > 0 then
			s.wintimer -= 1
		else
			s.won = true
			s.roundwins += 1
		end
	end
end

function game_round_init()
	g.flag = flag_create(7,8)
	game_create_players(g)
	g.roundcomplete=false
	g.starttimer = 3 * g.framerate
	g.round += 1

	foreach(g.playerstats,function(self)
		self.wintimer=0
		self.won=false
	end)
end

function game_update_start_timer(self)
	if self.starttimer > 0 then
		self.starttimer -= 1
		if self.starttimer == 0 then
			return true
		end
	end
	return false
end

function game_create_players(self)	
	self.players={}
	local p1corner = corner_random()
	local p2corner = corner_p2(p1corner)
	local p = player_create(self.corners[p1corner].x,self.corners[p1corner].y,1,false, menu.p1rotated)
	p.visible=false
	p.flipx = flip_player(p1corner)
	add(self.players, p)
	p = player_create(self.corners[p2corner].x,self.corners[p2corner].y,2,menu.p2ai, menu.p2rotated)
	p.visible=false
	p.flipx = flip_player(p2corner)
	add(self.players, p)
end

function game_has_round_finished(self)
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
end

function player_create(x,y,playerno,ai,rotate)
	local a={}
	anim_init(a,x,y)
	a.sp={1}
	a.stp=0
	-- a.initialx = xcell
	-- a.initialy = ycell
	a.flag=false
	a.colour=4
	a.ai=ai or false
	a.reacttime=0
	a.reactmin=10
	a.rotate=rotate or false
	a.falltimer=0
	a.player=playerno or 1


	a.anims=
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

	if (a.player==2) then a.colour=12 end

	return a
end

function player_update(p)
	if p.curanim == "fallen" then
		p.falltimer += 1
		if p.falltimer >= 60 then
			anim_set(p,"initial")
		else
			anim_update(p)
			return
		end
	end

	local oldx = p.xcell

	if p.ai then
		-- p:updateai()
	else
		player_update_human(p)
	end

	if p.xcell < oldx then
		p.flipx = true
	elseif p.xcell > oldx then
		p.flipx = false
	end
end

function player_update_human(self)
	local left = (self.rotate == false) and 0 or 3
	local right = (self.rotate == false) and 1 or 2
	local up = (self.rotate == false) and 2 or 0
	local down = (self.rotate == false) and 3 or 1

	if (btnp(left,self.player-1)) then
		player_set_position(self, self.xcell-1,self.ycell)
	end
	if (btnp(right,self.player-1)) then
		player_set_position(self, self.xcell+1,self.ycell)
	end
	if (btnp(up,self.player-1)) then
		player_set_position(self, self.xcell,self.ycell-1)
	end
	if (btnp(down,self.player-1)) then
		player_set_position(self, self.xcell,self.ycell+1)
	end
end

function player_draw(p)
	pal(4,p.colour)

	anim_draw(p)
	if p.flag then
		spr(3,
			p.x-(p.width/2),
			p.y-(p.height/2),
			1,1,
			p.flipx,
			p.flipy)
	end
	pal()
end

function player_set_position(self,xcell,ycell)
	if (not fget(mget(xcell,ycell-1),0)) then
		self.xcell = xcell
		self.ycell = ycell

		if (self.xcelllast ~= self.xcell) or (self.ycelllast ~= self.ycell) then
			if self.curanim == "initial" then
				anim_set(self,"walk")
			elseif self.curanim == "walk" then
				anim_set(self,"initial")
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

function flag_create(x, y)
	local f={}
	anim_init(f,x,y)
	f.sp={17,18,19,20,21,22,23}
	f.stp=15
	return f
end

function flag_drop(f,xcell,ycell)
	f.xcell = xcell
	f.ycell = ycell
	f.visible = true
end

function flag_update(f)
	anim_update(f)
end

function smoke_create(x,y)
	local a={}
	anim_init(a,x,y)
	a.sp={6,7,8}
	a.stp=15
	a.single=true
	return a
end

-- anything that requires one or more frames and is drawn in the 8*8 grid can be managed with
-- the anim_ functions.
function anim_init(a,x,y)
	a.x=x
	a.y=y
	a.flipx=false
	a.flipy=false
	a.visible=true
	a.f=1
	a.sp={0}
	a.t=0
	a.stp=60
	a.single=false
	a.remove=false
	a.curanim="initial"
end

function anim_update(a)
	a.t=(a.t+1)%a.stp
	if (a.t==0) then
		a.f=a.f%#a.sp+1
		if a.f==1 and a.single then
			a.remove=true
		end
	end
end

function anim_draw(a)
	if (a.visible and not a.remove) then
		local nx,ny=a.x*8,a.y*8
		spr(a.sp[a.f],nx,ny,1,1,a.flipx,a.flipy)
	end
end
	
function anim_set(a,anim)
	local temp=a.anims[anim]
	a.stp=temp.ticks
	a.sp=temp.frames
	a.f=1
	a.t=0
	a.curanim=anim
end

function corner_random()
	return flr(rnd(4)) + 1
end

function corner_p2(p1corner)
	return ((p1corner + 1) % 4) + 1
end

function flip_player(corner)
	if (corner == 2) or (corner == 3) then return true
	else return false end
end

-- game=
-- {


-- 	draw=function(self)
-- 		cls()
-- 		self:drawmap()
-- 		actors:draw()
-- 		self:drawscore()
-- 		if self.roundcomplete then
-- 			self:drawplayerwon()
-- 		elseif self.starttimer > 0 then
-- 			self:drawstarttime()
-- 		end
-- 	end,

-- 	roundreset=function(self)
-- 		self.roundcomplete = false
-- 		self.starttimer = 3 * self.framerate
-- 		self.flag:roundreset()
-- 		foreach(self.players,
-- 			function(p)
-- 				p:roundreset()
-- 			end
-- 		)
-- 		self.round += 1
-- 	end,

-- 	hasroundfinished=function(self)
-- 		local i = 1
-- 		local result = false
-- 		while i <= count(self.players) do
-- 			if (self.players[i].won) then
-- 				result = true
-- 				break
-- 			end
-- 			i += 1
-- 		end
-- 		return result
-- 	end,

-- 	gamehasfinished=function(self)
-- 		local i = 1
-- 		local result = false
-- 		while i <= count(self.players) do
-- 			if self.players[i].roundwins == self.roundsmax then
-- 				result = true
-- 				break
-- 			end
-- 			i += 1
-- 		end
-- 		return result
-- 	end,

-- 	updatestarttimer=function(self)
-- 		if self.starttimer > 0 then
-- 			self.starttimer -= 1
-- 			if self.starttimer == 0 then
-- 				actors:add(self.players[1])
-- 				actors:add(actor_smoke:new(self.players[1].xcell, self.players[1].ycell))
-- 				actors:add(self.players[2])
-- 				actors:add(actor_smoke:new(self.players[2].xcell, self.players[2].ycell))
-- 			end
-- 		end
-- 	end,

-- 	updatescoretimer=function(self)
-- 		if self.scoretimer > 0 then
-- 			self.scoretimer -= 1
-- 		elseif not self:gamehasfinished() then
-- 			self:roundreset()
-- 		end
-- 	end,

-- 	drawmap=function(self)
-- 		map(0,0,0,8)
-- 	end,

-- 	drawscore=function(self)
-- 		print("p1: "..flr((self.players[1].wintimer+(self.framerate-1))/self.framerate),5,0,self.players[1].colour)
-- 		print("round "..self.round,50,0,11)
-- 		print("p2: "..flr((self.players[2].wintimer+(self.framerate-1))/self.framerate),93,0,self.players[2].colour)
-- 	end,

-- 	drawplayerwon=function(self)
-- 		foreach(self.players,
-- 			function(p)
-- 				if p.won then
-- 					if self:gamehasfinished() then
-- 						print("player " ..(p.player).. " won the game!!",14,61,1)
-- 					else
-- 						print("player " ..(p.player).. " won the round!!",14,61,1)
-- 					end
-- 				end
-- 			end
-- 		)
-- 	end,

-- 	randomisecorner=function(self)
-- 		return flr(rnd(4)) + 1
-- 	end,

-- 	p2corner=function(self, p1corner)
-- 		return ((p1corner + 1) % 4) + 1
-- 	end,

-- 	flipplayer=function(self, corner)
-- 		if (corner == 2) or (corner == 3) then return true
-- 		else return false end
-- 	end,
-- }

function debug(str)
	if enabledebug then
		printh(str)
	end
end

-- actors=
-- {
-- 	list={},
-- 	add=function(self,a)
-- 		add(self.list,a)
-- 	end,
-- 	clear=function(self)
-- 		self.list={}
-- 	end,
-- 	update=function(self)
-- 		foreach(self.list,
-- 			function(a)
-- 				a:update()
-- 				if (a.remove) then del(self.list,a) end
-- 			end
-- 		)
-- 	end,
-- 	draw=function(self)
-- 		foreach(self.list,
-- 			function(a)
-- 				a:draw()
-- 			end
-- 		)
-- 	end,
-- }

-- actor_base =
-- {
-- 	x=0,
-- 	y=0,
-- 	xcell=0,
-- 	ycell=0,
-- 	xcelllast=0,
-- 	ycelllast=0,
-- 	width=8,
-- 	height=8,
-- 	flipx=false,
-- 	flipy=false,
-- 	remove=false,
-- 	singlepass=false,
-- 	curanim="initial",
-- 	curframe=0,
-- 	animtick=0,
-- 	visible=true,

-- 	-- x and y are the cells to draw in, not the pixel position.
-- 	new=function(self,xcell,ycell)
-- 		local o = setmetatable({}, self)
-- 		self.__index = self
-- 		o.xcell = xcell or 0
-- 		o.xcelllast = o.xcell
-- 		o.ycell = ycell or 0
-- 		o.ycelllast = o.ycell
-- 		return o
-- 	end,

-- 	init=function(self)
-- 		self:set_anim("initial")
-- 	end,

-- 	update=function(self)
-- 		if (self:outofbounds()) then self.remove=true end
		
-- 		--anim tick
-- 		self.animtick-=1
-- 		if self.animtick<=0 then
-- 			self.curframe+=1
-- 			local a=self.anims[self.curanim]
-- 			self.animtick=a.ticks--reset timer
-- 			if self.curframe>#a.frames then
-- 				if self.singlepass then
-- 					self.remove = true
-- 				else
-- 					self.curframe=1--loop
-- 				end
-- 			end
-- 		end
-- 		self.x = (self.xcell * 8) + 4
-- 		self.y = (self.ycell * 8) + 4
-- 	end,
	
-- 	draw=function(self)
-- 		-- repeat the setting of x and y here, just in case something was changed.
-- 		self.x = (self.xcell * 8) + 4
-- 		self.y = (self.ycell * 8) + 4
		
-- 		if self.visible then
-- 			local a=self.anims[self.curanim]
-- 			local frame=a.frames[self.curframe]
-- 			spr(frame,
-- 				self.x-(self.width/2),
-- 				self.y-(self.height/2),
-- 				self.width/8,self.height/8,
-- 				self.flipx,
-- 				self.flipy)
-- 		end
-- 	end,

-- 	outofbounds=function(self)
-- 		if ((self.x+self.width) < 0) then return true end
-- 		if ((self.x) > 127) then return true end
-- 		if ((self.y+self.height) < 0) then return true end
-- 		if ((self.y) > 127) then return true end
-- 	end,

-- 	--animation definitions.
-- 	--use with set_anim()
-- 	anims=
-- 	{
-- 		["initial"]=
-- 		{
-- 			ticks=1,--how long is each frame shown.
-- 			frames={0},--what frames are shown.
-- 		},
-- 	},
	
-- 	set_anim=function(self,anim)
-- 		if(anim==self.curanim)return--early out.
-- 		local a=self.anims[anim]
-- 		self.animtick=a.ticks--ticks count down.
-- 		self.curanim=anim
-- 		self.curframe=1
-- 	end,
-- }

-- game=
-- {

-- 	update=function(self)
-- 		if (self.roundcomplete) then
-- 			self:updatescoretimer()
-- 		else
-- 			if self.starttimer > 0 then
-- 				self:updatestarttimer()
-- 			elseif self:hasroundfinished() then
-- 				self.scoretimer = 3 * self.framerate
-- 				self.roundcomplete = true
-- 			end
-- 		end
-- 		actors:update()
-- 	end,

-- 	draw=function(self)
-- 		cls()
-- 		self:drawmap()
-- 		actors:draw()
-- 		self:drawscore()
-- 		if self.roundcomplete then
-- 			self:drawplayerwon()
-- 		elseif self.starttimer > 0 then
-- 			self:drawstarttime()
-- 		end
-- 	end,

-- 	roundreset=function(self)
-- 		self.roundcomplete = false
-- 		self.starttimer = 3 * self.framerate
-- 		self.flag:roundreset()
-- 		foreach(self.players,
-- 			function(p)
-- 				p:roundreset()
-- 			end
-- 		)
-- 		self.round += 1
-- 	end,

-- 	hasroundfinished=function(self)
-- 		local i = 1
-- 		local result = false
-- 		while i <= count(self.players) do
-- 			if (self.players[i].won) then
-- 				result = true
-- 				break
-- 			end
-- 			i += 1
-- 		end
-- 		return result
-- 	end,

-- 	updatestarttimer=function(self)
-- 		if self.starttimer > 0 then
-- 			self.starttimer -= 1
-- 			if self.starttimer == 0 then
-- 				actors:add(self.players[1])
-- 				actors:add(actor_smoke:new(self.players[1].xcell, self.players[1].ycell))
-- 				actors:add(self.players[2])
-- 				actors:add(actor_smoke:new(self.players[2].xcell, self.players[2].ycell))
-- 			end
-- 		end
-- 	end,

-- 	drawstarttime=function(self)
-- 		print("starting in "..flr((self.starttimer/self.framerate)+1).."..",28,58,1)
-- 	end,

-- 	updatescoretimer=function(self)
-- 		if self.scoretimer > 0 then
-- 			self.scoretimer -= 1
-- 		elseif not self:gamehasfinished() then
-- 			self:roundreset()
-- 		end
-- 	end,

-- 	drawmap=function(self)
-- 		map(0,0,0,8)
-- 	end,

-- 	drawscore=function(self)
-- 		print("p1: "..flr((self.players[1].wintimer+(self.framerate-1))/self.framerate),5,0,self.players[1].colour)
-- 		print("round "..self.round,50,0,11)
-- 		print("p2: "..flr((self.players[2].wintimer+(self.framerate-1))/self.framerate),93,0,self.players[2].colour)
-- 	end,

-- 	drawplayerwon=function(self)
-- 		foreach(self.players,
-- 			function(p)
-- 				if p.won then
-- 					if self:gamehasfinished() then
-- 						print("player " ..(p.player).. " won the game!!",14,61,1)
-- 					else
-- 						print("player " ..(p.player).. " won the round!!",14,61,1)
-- 					end
-- 				end
-- 			end
-- 		)
-- 	end,
-- }

-- function sametile(a1,a2)
-- 	if (a1.xcell == a2.xcell) and (a1.ycell == a2.ycell) then return true
-- 	else return false
-- 	end
-- end

-- actor_player = actor_base:new()

-- function actor_player:new (xcell,ycell,playerno,ai,rotate)
-- 	local o = actor_base:new(xcell,ycell)
-- 	setmetatable(o, self)
-- 	self.__index = self
   
-- 	o.init(o)
-- 	o.player=playerno or 1
-- 	o.roundwins = 0
-- 	o.initialx = xcell
-- 	o.initialy = ycell
-- 	o.flag = false
-- 	o.wintimer = 0
-- 	o.won = false
-- 	o.colour = 4
-- 	o.ai = ai or false
-- 	o.reacttime = 0
-- 	o.reactmin = 10
-- 	o.rotate = rotate or false
-- 	o.falltimer = 0

-- 	if (o.player==2) then
-- 		o.colour=12
-- 	end
	
-- 	self.roundreset=function(self)
-- 		self.flag = false
-- 		self.wintimer = game.roundtime*game.framerate
-- 		self.won = false
-- 		self.xcell = self.initialx
-- 		self.ycell = self.initialy
-- 		self.xcelllast = self.xcell
-- 		self.ycelllast = self.ycell
-- 	end

-- 	o.roundreset(o)

-- 	self.update=function(self)

-- 		if self.curanim == "fallen" then
-- 			self.falltimer += 1
-- 			if self.falltimer >= 60 then
-- 				self:set_anim("initial")
-- 			else
-- 				actor_base.update(self)
-- 				return
-- 			end
-- 		end

-- 		local oldx = self.xcell

-- 		if self.ai then
-- 			self:updateai()
-- 		else
-- 			self:updatehuman()
-- 		end
-- 		actor_base.update(self)

-- 		if self.xcell < oldx then
-- 			self.flipx = true
-- 		elseif self.xcell > oldx then
-- 			self.flipx = false
-- 		end		
		
-- 		if self.flag then
-- 			if self.wintimer > 0 then
-- 				self.wintimer -= 1
-- 			else
-- 				self.won = true
-- 				self.roundwins += 1
-- 			end
-- 		end
-- 	end

-- 	self.updateai=function(self)
-- 		self.reacttime += 1
-- 		if self.reacttime < self.reactmin then
-- 			return
-- 		end
-- 		self.reacttime = 0
-- 		local target = {xcell=0,ycell=0}
-- 		local otherplayer
-- 		local targetisotherplayer = false
-- 		local towards = 1
-- 		if self.player == 1 then
-- 			otherplayer = game.players[2]
-- 		else
-- 			otherplayer = game.players[1]
-- 		end
-- 		-- find the target the player should try and move towards
-- 		if self.flag then
-- 			target = {xcell=otherplayer.xcell,ycell=otherplayer.ycell}
-- 			targetisotherplayer = true
-- 			towards = -1
-- 		else
-- 			if otherplayer.flag then
-- 				target = {xcell=otherplayer.xcell,ycell=otherplayer.ycell}
-- 				targetisotherplayer = true
-- 			else
-- 				target = {xcell=game.flag.xcell,ycell=game.flag.ycell}
-- 			end
-- 		end

-- 		debug("p "..tostr(self.player).." target: x:"..tostr(target.xcell)..", y:"..tostr(target.ycell)..", towards: "..tostr(towards))

-- 		-- add the small possibility of a random movement.
-- 		local randommove = false
		
-- 		-- check if both players are in the same cell
-- 		if targetisotherplayer and (self.xcell == target.xcell) and (self.ycell == target.ycell) then
-- 			if self.flag then
-- 				-- if the current player has the flag the should run towards the quadrant which they are farthest from.
-- 				local x = 0
-- 				local y = 0
-- 				if self.xcell < 8 then
-- 					x = 1
-- 				else
-- 					x = -1
-- 				end
-- 				if self.ycell < 8 then
-- 					y = 1
-- 				else
-- 					y = -1
-- 				end
-- 				self:newposition(self.xcell+x,self.ycell+y)
-- 			else
-- 				-- if the current player doesn't have the flag they should move randomly.
-- 				randommove = true
-- 			end
-- 		else
-- 			if self.flag then
-- 				if rnd(100) > 65 then
-- 					randommove = true
-- 				end
-- 			else
-- 				if rnd(100) > 95 then
-- 					randommove = true
-- 				end
-- 			end
			
-- 			if not randommove then
-- 				if abs(target.xcell-self.xcell) > abs(target.ycell-self.ycell) then
-- 					-- move in x direction
-- 					if target.xcell > self.xcell then
-- 						self:newposition(self.xcell+towards,self.ycell)
-- 					elseif target.xcell < self.xcell then
-- 						self:newposition(self.xcell-towards,self.ycell)
-- 					else
-- 						randommove = true
-- 					end
-- 				elseif abs(target.xcell-self.xcell) < abs(target.ycell-self.ycell) then
-- 					-- move in y direction
-- 					if target.ycell > self.ycell then
-- 						self:newposition(self.xcell,self.ycell+towards)
-- 					elseif target.ycell < self.ycell then
-- 						self:newposition(self.xcell,self.ycell-towards)
-- 					else
-- 						randommove = true
-- 					end
-- 				else
-- 					randommove = true
-- 				end
-- 			end
-- 		end
		
-- 		if randommove then
-- 			local dirx = 0
-- 			local diry = 0
-- 			if self.xcell < target.xcell then
-- 				dirx = 1
-- 			elseif self.xcell > target.xcell then
-- 				dirx = -1
-- 			end
			
-- 			if self.ycell < target.ycell then
-- 				diry = 1
-- 			elseif self.ycell > target.ycell then
-- 				diry = -1
-- 			end
-- 			self:moverandom(dirx, diry)
-- 		end
-- 	end

-- 	self.moverandom=function(self, dirx, diry)
-- 		dirx = dirx or 0
-- 		diry = diry or 0

-- 		local x = dirx
-- 		if x == 0 then
-- 			x = flr(rnd(3))-1
-- 		end

-- 		local y = diry
-- 		if y == 0 then
-- 			y = flr(rnd(3))-1
-- 		end

-- 		if y ~= 0 and x ~= 0 then
-- 			if (rnd(2)) == 1 then
-- 				y = 0
-- 			else
-- 				x = 0
-- 			end
-- 		end

-- 		-- debug("p "..tostr(self.player).." random move")
-- 		-- local x = flr(rnd(3))-1
-- 		-- local y = flr(rnd(3))-1
-- 		self:newposition(self.xcell+x,self.ycell+y)
-- 	end

-- 	self.newposition=function(self,xcell,ycell)
-- 		if (not fget(mget(xcell,ycell-1),0)) then
-- 		   self.xcell = xcell
-- 		   self.ycell = ycell

-- 			if (self.xcelllast ~= self.xcell) or (self.ycelllast ~= self.ycell) then
-- 				if self.curanim == "initial" then
-- 					self:set_anim("walk")
-- 				elseif self.curanim == "walk" then
-- 					self:set_anim("initial")
-- 				end

-- 				foreach(game.players,
-- 					function(p)
-- 						if (p != self) then
-- 							if (sametile(self, p)) then
-- 								p:fallrandom()

-- 								if self.flag then
-- 									self.flag = false
-- 									game.flag:drop(self.xcell, self.ycell)
-- 									self:fallrandom()
-- 									debug("player "..tostr(self.player).." dropped the flag")
-- 								elseif p.flag then
-- 									p.flag = false
-- 									self.flag = true
-- 									debug("player "..tostr(self.player).." stole the flag")
-- 								else
-- 									self:fallrandom()
-- 								end

-- 								while sametile(self, p) do
-- 									p:moverandom()
-- 								end
-- 							end
-- 						end
-- 					end
-- 				)
-- 			end

-- 			self.xcelllast = self.xcell
-- 			self.ycelllast = self.ycell
-- 		end

-- 		if (game.flag.visible) then
-- 			if (sametile(self, game.flag)) then
-- 				game.flag.visible = false
-- 				self.flag = true
-- 			end
-- 		end
-- 	end

-- 	self.fallrandom=function(self)
-- 		if self.curanim ~= "fallen" then
-- 			self:set_anim("fallen")
-- 			self.falltimer = 0
-- 			self:moverandom()
-- 		end
-- 	end

-- 	return o
-- end

-- actor_smoke = actor_base:new()

-- function actor_smoke:new (xcell,ycell)
-- 	local o = actor_base:new(xcell,ycell)
-- 	setmetatable(o, self)
-- 	self.__index = self
   
-- 	o.visible = true
-- 	o.singlepass = true
-- 	o.init(o)
	
-- 	self.update=function(self)
-- 		actor_base.update(self)
-- 	end

-- 	o.anims=
-- 	{
-- 		["initial"]=
-- 		{
-- 			ticks=15,
-- 			frames={6,7,8},
-- 		},
-- 	}

-- 	return o
-- end

__gfx__
00000000000000000000000000000000070700700070700007077000000000000000000000000000000000000000000000000000000000000000000000000000
000000000004400000044000333000000004400000044000777d7d7000007d000000000000000000000000000000000000000000000000000000000000000000
00700700004004000040040003300000004004000040040007d7777706d777700070700000000000000000000000000000000000000000000000000000000000
00077000004004000040040033300000004004000040040077777d700077d700000d770000000000000000000000000000000000000000000000000000000000
0007700000044000000440000010000000044000000440007d777777077d77700077d00000000000000000000000000000000000000000000000000000000000
007007000004000000040000000000000004000000040000077d7d7d00777d000007070000000000000000000000000000000000000000000000000000000000
00000000004040000004000000000000004440000044400007777777007000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000007d7700000000000000000000000000000000000000000000000000000000000000000000000000
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
