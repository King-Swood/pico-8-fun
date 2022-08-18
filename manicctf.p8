pico-8 cartridge // http://www.pico-8.com
version 36
__lua__

-- todo: add a final winners screen which displays who won, and the state of their win calculated from the difference in times across the rounds.
--			by a long shot
--			by a small margin
--			only just...
--		add a endtimeleft variable in each players state. (done)
--		at the end of each round, add the time the player still had to get to this variable. (done)
--		at the end of the game, divide this value by the number of rounds.
--		then compare the times between the players to come up with the messages.

-- todo: setup on raspberry pi to do some playtesting with sarah.

-- enabledebug = true
enabledebug = false
p1colour = 9
p2colour = 12

function _init()
	title_init()
end

function anykey_pressed()
	return (btnp() ~= 0)	
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
	if (anykey_pressed()) then
		return true
	else
		return false
	end
end

function menu_init()
	_update60=menu_update
	_draw=menu_draw

	menu={}
	menu.p1=player_create(72,24,1,false,false)
	menu.p2=player_create(24,40,2,false,false)
	menu.p2.flipx=true
	anim_set(menu.p2,"fallen")
	menu.flag = flag_create(56,15)
	menu.p2.falltimer = 0
	menu.p1rotate=false
	menu.p2rotate=false
	menu.p2ai=false
end

function menu_update()
	if (anykey_pressed()) game_init()
end

function menu_draw()
	cls()
	anim_draw_scale(menu.p1,3)
	pal(p1colour,p2colour)
	anim_draw_scale(menu.p2,3)
	pal()
	menu.p2.falltimer += 1
	anim_update(menu.p2)
	anim_update(menu.flag)
	anim_draw_scale(menu.flag,3)
	print("manic ctf!!",56,60,9)
	print("press any key to start!",20,100,12)
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
	g.roundsmax = 2
	g.players = {}
	g.playerstats={game_stats_create(),game_stats_create()}
	g.anims={}
	g.framerate = 60
	g.roundtime = 15 -- seconds in each round
	g.scoretimer = 0
	g.roundcomplete = false
	g.starttimer = 0

	game_round_init(g)
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
		if g.scoretimer > 0 then
			g.scoretimer -= 1
		elseif game_has_finished(g) then
			if skipscreen() then
				menu_init()
			end
		else
			if skipscreen() then
				game_round_init(g)
			end
		end
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
			for i=1,#g.playerstats do
				g.playerstats[i].endtimeleft += g.playerstats[i].wintimer
			end
			g.roundcomplete = true
			if game_has_finished(g) then
				sfx(2)
			else
				sfx(1)
			end
		else
			foreach(g.players,player_update)
			players_check_collisions()
			for i=1,#g.playerstats do
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
	print("p1: "..flr((self.playerstats[1].wintimer+(self.framerate-1))/self.framerate),5,0,p1colour)
	print("round "..self.round,50,0,11)
	print("p2: "..flr((self.playerstats[2].wintimer+(self.framerate-1))/self.framerate),93,0,p2colour)
end

function game_draw_player_won(self)
	for i=1,2 do
		if self.playerstats[i].won then
			if game_has_finished(self) then
				print("player " ..(i).. " won the game!!",14,61,1)
				if g.scoretimer==0 then
					print("press any key to finish",14,100,12)
				end
			else
				print("player " ..(i).. " won the round!!",14,61,1)
				if g.scoretimer==0 then
					print("press any key to continue",11,100,12)
				end
			end
		end
	end
end

function game_stats_create()
	local o={}
	o.roundwins=0
	o.wintimer=0
	o.endtimeleft=0
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

function game_round_init(self)
	self.flag = flag_create(7,8)
	game_create_players(self)
	self.roundcomplete=false
	self.starttimer = 3 * self.framerate
	self.round += 1

	foreach(self.playerstats,function(s)
		s.wintimer = self.roundtime*self.framerate
		s.won=false
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
	for s in all (self.playerstats) do
		if (s.won) then
			return true
		end
	end
	return false
end

function game_has_finished(self)
	local i = 1
	local result = false
	while i <= count(self.playerstats) do
		if self.playerstats[i].roundwins == self.roundsmax then
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
	a.xlast=-999
	a.ylast=-999
	a.flag=false
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

	local oldx = p.x

	if p.ai then
		-- p:updateai()
	else
		player_update_human(p)
	end

	if p.x < oldx then
		p.flipx = true
	elseif p.x > oldx then
		p.flipx = false
	end
end

function player_update_human(self)
	local left = (self.rotate == false) and 0 or 3
	local right = (self.rotate == false) and 1 or 2
	local up = (self.rotate == false) and 2 or 0
	local down = (self.rotate == false) and 3 or 1

	if (btnp(left,self.player-1)) then
		player_walk(self,-1,0)
	end
	if (btnp(right,self.player-1)) then
		player_walk(self,1,0)
	end
	if (btnp(up,self.player-1)) then
		player_walk(self,0,-1)
	end
	if (btnp(down,self.player-1)) then
		player_walk(self,0,1)
	end
end

function player_draw(p)
 if (p.player == 2) then	pal(p1colour,p2colour) end

	anim_draw(p)
	if p.flag then
		local x = p.x*8-3
		if p.flipx then x = p.x*8+3 end
		spr(3,
			x,
			p.y*8-1,
			1,1,
			p.flipx,
			p.flipy)
	end
	pal()
end

function players_check_collisions()
	local game=g --uses global variable
	foreach(game.players,
		function(p)
			foreach(game.players,
				function(pn)
					if ((p ~= pn) and sametile(p,pn)) then
						if p.flag or pn.flag then
							p.flag = pn.flag
							pn.flag = not p.flag

							if (not p.flag) then
								player_fall_random(p)
								debug("player "..tostr(p.player).." lost the flag")
							else
								player_fall_random(pn)
								debug("player "..tostr(pn.player).." lost the flag")
							end
						else
							player_fall_random(p)
							player_fall_random(pn)
							debug("players bumped into each other")
						end

						while sametile(p, pn) do
							player_move_random(pn)
						end
					end
				end
			)

			if (game.flag.visible) then
				if (sametile(p, game.flag)) then
					game.flag.visible = false
					p.flag = true
					sfx(1)
				end
			end
		end
	)
end

function player_walk(self,x,y)
	local game=g --uses global variable
	if (not fget(mget(self.x+x,self.y+y-1),0)) then
		self.x = self.x+x
		self.y = self.y+y

		if (self.xlast ~= self.x) or (self.ylast ~= self.y) then
			if self.curanim == "initial" then
				anim_set(self,"walk")
				sfx(3)
			elseif self.curanim == "walk" then
				anim_set(self,"initial")
				sfx(4)
			end
		end
		self.xlast = self.x
		self.ylast = self.y
	end
end

function player_set_position(self,x,y)
	local game=g --uses global variable
	if (not fget(mget(x,y-1),0)) then
		self.x = x
		self.y = y

		-- if (self.xlast ~= self.x) or (self.ylast ~= self.y) then
		-- 	if self.curanim == "initial" then
		-- 		anim_set(self,"walk")
		-- 	elseif self.curanim == "walk" then
		-- 		anim_set(self,"initial")
		-- 	end
		-- end
		self.xlast = self.x
		self.ylast = self.y
	end
end

function player_fall_random(self)
	if self.curanim ~= "fallen" then
		anim_set(self,"fallen")
		self.falltimer = 0
		player_move_random(self)
		sfx(0)
	end
end

function player_move_random(self, dirx, diry)
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

	player_set_position(self, self.x+x,self.y+y)
end

function flag_create(x, y)
	local f={}
	anim_init(f,x,y)
	f.sp={16,17,18,19,20,21,22,23,24}
	f.stp=15
	return f
end

function flag_drop(f,x,y)
	f.x = x
	f.y = y
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
	a.width=8
	a.height=8
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

function anim_draw_scale(a,scale)
	if (a.visible and not a.remove) then
		local sx, sy = (a.sp[a.f] % 16) * 8, flr(a.sp[a.f] \ 16) * 8
		-- spr(a.sp[a.f],nx,ny,1,1,a.flipx,a.flipy)
		sspr(sx,sy,8,8,a.x,a.y,8*scale,8*scale,a.flipx,a.flipy)
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

function sametile(a1,a2)
	if (a1.x == a2.x) and (a1.y == a2.y) then return true
	else return false
	end
end

function debug(str)
	if enabledebug then
		printh(str)
	end
end

__gfx__
00000000001111000011110011111000070700700070700007077000000000000000000000000000000000000000000000000000000000000000000000000000
0000000001ffff1001ffff101bbb10000011110000111100777d7d7000007d000000000000000000000000000000000000000000000000000000000000000000
0070070001f5f51001f5f51011bb100001ffff1001ffff1007d7777706d777700070700000000000000000000000000000000000000000000000000000000000
0007700001ffff1001ffff101bbb100001f5f51001f5f51077777d700077d700000d770000000000000000000000000000000000000000000000000000000000
0007700000191000001910001111100001ffff1001ffff107d777777077d77700077d00000000000000000000000000000000000000000000000000000000000
007007000199910001999100000400000019100000191000077d7d7d00777d000007070000000000000000000000000000000000000000000000000000000000
00000000014141000144100000000000019991000199910007777777007000000000000000000000000000000000000000000000000000000000000000000000
000000000010100000110000000000000141410001414100007d7700000000000000000000000000000000000000000000000000000000000000000000000000
11111101111110011111001111100111110011111001111100111111011111111111111100000000000000000000000000000000000000000000000000000000
01bbbb1101bbb11101bb11b101b11bb10011bbb1011bbbb111bbbbb111bbbbb101bbbbb100000000000000000000000000000000000000000000000000000000
0011bbb10011bbb10011bbb1001bbbb101bbbbb101b1bbb10011bbb10011bbb10011bbb100000000000000000000000000000000000000000000000000000000
01bbbbb101bbbbb101bbbbb101b1bbb10011bbb1001bbbb101bbbbb101bbbbb101bbbbb100000000000000000000000000000000000000000000000000000000
111111b111111bb11111bb11111bb11111bb111110b1111100111111011111111111111100000000000000000000000000000000000000000000000000000000
00000014000001140000110400011004001100040110000411000004100000040000000400000000000000000000000000000000000000000000000000000000
00000004000000040000000400000004000000040000000400000004000000040000000400000000000000000000000000000000000000000000000000000000
00000004000000040000000400000004000000040000000400000004000000040000000400000000000000000000000000000000000000000000000000000000
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
__sfx__
000100000f5301253012530125301253012530115300f5300d5300e5300f5300f53011530145301653017530175300c53017530165300f53010530105300f5300e5300d5300e5300f5300f5300f5300d5300c530
010700001c55000000000001c550000001c55000000235502355023550235501350013500115001150010500105000e5000c5000c500135001350015500155001350011500000000000000000000000000000000
010a00001f5500000000000000001f550000001f550000002155000000000001f5500000000000215500000000000235502355023550235502355023550000000000000000000000000000000000000000000000
000400003351000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000400003251000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
