pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--Basic platform tut
--@DarrenPearce
--Based on: advanced micro platformer by @matthughson

function _init()
	p1=m_player(40,32)
end

updater=4

function _update60()
	updater+=1
	if (updater == 5) then
	p1:update()
	updater = 4
	end
end

function _draw()
 cls()
 map(0,0,0,0)
 p1:draw()
 debug()
end

function debug()
 print("p1.x "..p1.x.." "..tostr(istilesolid(pixeltotile(p1.x),pixeltotile(p1.y))), 0, 0, 10)
 print("p1.dx "..p1.dx, 0, 6, 10)
 --print("p1.y "..p1.y.." "..tostr(p1.jumping), 0, 12, 10)
end

function pixeltotile(px) return flr(px / 8) end

function istilesolid(x,y) return fget(mget(x,y),0) end
function istilesolidpx(x,y) return istilesolid(pixeltotile(x),pixeltotile(y)) end
-->8
-- friction=0.75
gravity=0.15
-- pminspeed=1.0
-- pmaxspeed=1.0
-- jumptimemax=6

--sfx
snd=
{
	jump=0,
}

--music tracks
mus=
{

}

--math
--------------------------------

--point to box intersection.
function intersects_point_box(px,py,x,y,w,h)
	if flr(px)>=flr(x) and flr(px)<flr(x+w) and
				flr(py)>=flr(y) and flr(py)<flr(y+h) then
		return true
	else
		return false
	end
end

--box to box intersection
function intersects_box_box(
	x1,y1,
	w1,h1,
	x2,y2,
	w2,h2)

	local xd=x1-x2
	local xs=w1*0.5+w2*0.5
	if abs(xd)>=xs then return false end

	local yd=y1-y2
	local ys=h1*0.5+h2*0.5
	if abs(yd)>=ys then return false end
	
	return true
end

--check if pushing into side tile and resolve.
--requires self.dx,self.x,self.y, and 
--assumes tile flag 0 == solid
--assumes sprite size of 8x8
function collide_side(self)

	local offset=self.w/3
	for i=-(self.w/3),(self.w/3),2 do
	--if self.dx>0 then
		if fget(mget((self.x+(offset))/8,(self.y+i)/8),0) then
			self.dx=0
			self.x=(flr(((self.x+(offset))/8))*8)-(offset)
			return true
		end
	--elseif self.dx<0 then
		if fget(mget((self.x-(offset))/8,(self.y+i)/8),0) then
			self.dx=0
			self.x=(flr((self.x-(offset))/8)*8)+8+(offset)
			return true
		end
--	end
	end
	--didn't hit a solid tile.
	return false
end

--check if pushing into floor tile and resolve.
--requires self.dx,self.x,self.y,self.grounded,self.airtime and 
--assumes tile flag 0 or 1 == solid
function collide_floor(self)
	--only check for ground when falling.
	if self.dy<0 then
		return false
	end
	local landed=false
	--check for collision at multiple points along the bottom
	--of the sprite: left, center, and right.
	for i=-(self.w/3),(self.w/3),2 do
		local tile=mget((self.x+i)/8,(self.y+(self.h/2))/8)
		if fget(tile,0) or (fget(tile,1) and self.dy>=0) then
			self.dy=0
			self.y=(flr((self.y+(self.h/2))/8)*8)-(self.h/2)
			self.grounded=true
			self.airtime=0
			landed=true
		end
	end
	return landed
end

--check if pushing into roof tile and resolve.
--requires self.dy,self.x,self.y, and 
--assumes tile flag 0 == solid
function collide_roof(self)
	--check for collision at multiple points along the top
	--of the sprite: left, center, and right.
	for i=-(self.w/3),(self.w/3),2 do
		if fget(mget((self.x+i)/8,(self.y-(self.h/2))/8),0) then
			self.dy=0
			self.y=flr((self.y-(self.h/2))/8)*8+8+(self.h/2)
			self.jump_hold_time=0
		end
	end
end

--make 2d vector
function m_vec(x,y)
	local v=
	{
		x=x,
		y=y,
		
  --get the length of the vector
		get_length=function(self)
			return sqrt(self.x^2+self.y^2)
		end,
		
  --get the normal of the vector
		get_norm=function(self)
			local l = self:get_length()
			return m_vec(self.x / l, self.y / l),l;
		end,
	}
	return v
end

--square root.
function sqr(a) return a*a end

--round to the nearest whole number.
function round(a) return flr(a+0.5) end

--objects
--------------------------------

--make the player
function m_player(x,y)

	--todo: refactor with m_vec.
	local p=
	{
		x=x,
		y=y,

		dx=0,
		dy=0,

		w=8,
		h=8,
		
		max_dx=1,--max x speed
		max_dy=2,--max y speed

		jump_speed=-1.75,--jump veloclity
		acc=0.05,--acceleration
		dcc=0.8,--decceleration
		air_dcc=1,--air decceleration
		grav=0.15,
		
		--helper for more complex
		--button press tracking.
		--todo: generalize button index.
		jump_button=
		{
			update=function(self)
				--start with assumption
				--that not a new press.
				self.is_pressed=false
				if btn(5) then
					if not self.is_down then
						self.is_pressed=true
					end
					self.is_down=true
					self.ticks_down+=1
				else
					self.is_down=false
					self.is_pressed=false
					self.ticks_down=0
				end
			end,
			--state
			is_pressed=false,--pressed this frame
			is_down=false,--currently down
			ticks_down=0,--how long down
		},

		jump_hold_time=0,--how long jump is held
		min_jump_press=5,--min time jump can be held
		max_jump_press=15,--max time jump can be held

		jump_btn_released=true,--can we jump again?
		grounded=false,--on ground

		airtime=0,--time since grounded
		
		--animation definitions.
		--use with set_anim()
		anims=
		{
			["stand"]=
			{
				ticks=1,--how long is each frame shown.
				frames={1},--what frames are shown.
			},
			["walk"]=
			{
				ticks=5,
				frames={1},
			},
			["jump"]=
			{
				ticks=1,
				frames={1},
			},
			["slide"]=
			{
				ticks=1,
				frames={1},
			},
		},

		curanim="walk",--currently playing animation
		curframe=1,--curent frame of animation.
		animtick=0,--ticks until next frame should show.
		flipx=false,--show sprite be flipped.
		
		--request new animation to play.
		set_anim=function(self,anim)
			if(anim==self.curanim)return--early out.
			local a=self.anims[anim]
			self.animtick=a.ticks--ticks count down.
			self.curanim=anim
			self.curframe=1
		end,
		
		--call once per tick.
		update=function(self)
	
			--todo: kill enemies.
			
			--track button presses
			local bl=btn(0) --left
			local br=btn(1) --right
			
			--move left/right
			if bl==true then
				self.dx-=self.acc
				br=false--handle double press
			elseif br==true then
				self.dx+=self.acc
			else
				if self.grounded then
					self.dx*=self.dcc
				else
					self.dx*=self.air_dcc
				end
			end

			--limit walk speed
			self.dx=mid(-self.max_dx,self.dx,self.max_dx)
			
			--move in x
			self.x+=self.dx
			
			--hit walls
			collide_side(self)

			--jump buttons
			self.jump_button:update()
			
			--jump is complex.
			--we allow jump if:
			--	on ground
			--	recently on ground
			--	pressed btn right before landing
			--also, jump velocity is
			--not instant. it applies over
			--multiple frames.
			if self.jump_button.is_down then
				--is player on ground recently.
				--allow for jump right after 
				--walking off ledge.
				local on_ground=(self.grounded or self.airtime<5)
				--was btn presses recently?
				--allow for pressing right before
				--hitting ground.
				local new_jump_btn=self.jump_button.ticks_down<10
				--is player continuing a jump
				--or starting a new one?
				if self.jump_hold_time>0 or (on_ground and new_jump_btn) then
					if(self.jump_hold_time==0)sfx(snd.jump)--new jump snd
					self.jump_hold_time+=1
					--keep applying jump velocity
					--until max jump time.
					if self.jump_hold_time<self.max_jump_press then
						self.dy=self.jump_speed--keep going up while held
					end
				end
			else
				self.jump_hold_time=0
			end
			
			--move in y
			self.dy+=self.grav
			self.dy=mid(-self.max_dy,self.dy,self.max_dy)
			self.y+=self.dy

			--floor
			if not collide_floor(self) then
				self:set_anim("jump")
				self.grounded=false
				self.airtime+=1
			end

			--roof
			collide_roof(self)

			--handle playing correct animation when
			--on the ground.
			if self.grounded then
				if br then
					if self.dx<0 then
						--pressing right but still moving left.
						self:set_anim("slide")
					else
						self:set_anim("walk")
					end
				elseif bl then
					if self.dx>0 then
						--pressing left but still moving right.
						self:set_anim("slide")
					else
						self:set_anim("walk")
					end
				else
					self:set_anim("stand")
				end
			end

			--flip
			if br then
				self.flipx=false
			elseif bl then
				self.flipx=true
			end

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

		end,

		--draw the player
		draw=function(self)
			local a=self.anims[self.curanim]
			local frame=a.frames[self.curframe]
			spr(frame,
				self.x-(self.w/2),
				self.y-(self.h/2),
				self.w/8,self.h/8,
				self.flipx,
				false)
		end,
	}

	return p
end

-- function p1move(x,fast)
--   if (x > 0) then p1.b_right=true
--   elseif (x < 0) then p1.b_left=true end
-- end

-- function p1jump()
--  p1.b_up=true
-- end

-- function p1updatefriction()
--   local speedtouse = p1.speeds
--   if (not p1.grounded) then speedtouse/=3 end

--   if (p1.b_right) then
--     if (p1.ax > 0) then 
--       p1.ax+=speedtouse
--     else
--       p1.ax+=speedtouse*2
--     end
--     p1.moving=true
--     if (p1.ax > 0) and (p1.ax < pminspeed) then p1.ax=pminspeed end
--     if (p1.ax > pmaxspeed) then p1.ax=pmaxspeed end
--   elseif (p1.b_left) then
--     if (p1.ax < 0) then 
--       p1.ax-=speedtouse
--     else
--       p1.ax-=speedtouse*2
--     end
--     p1.moving=true
--     if (p1.ax < 0) and (p1.ax > -pminspeed) then p1.ax=-pminspeed end
--     if (p1.ax < -pmaxspeed) then p1.ax=-pmaxspeed end
--   end

--   if (p1.grounded and not p1.moving) then
--     if (p1.ax>0) then p1.ax-=friction end
--     if (p1.ax<0) then p1.ax+=friction end
--     if(abs(p1.ax)<friction) then p1.ax=0 end
--   end
--   p1.b_right=false
--   p1.b_left=false
--   p1.moving = false
-- end

-- function p1updategravity()
--   if (p1.b_up and (p1.grounded or p1.jumping) and (p1.jumptime < jumptimemax) and (p1.jumpallowed)) then
--     p1.jumping=true
--     p1.jumptime+=1
--     p1.grounded=false
--     if (p1.ay == 0) then p1.ay-=p1.speedj*2
--     else p1.ay-=p1.speedj end
--   else
--     p1.jumping=false
--     p1.jumptime=0
--     if (p1.grounded) then
--       p1.ay=0
--       if (p1.b_up) then
--         p1.jumpallowed=false
--       else
--         p1.jumpallowed=true
--       end
--     else
--       if(p1.ay<10) then p1.ay+=gravity end
--       p1.jumpallowed=false
--     end
--   end
--   p1.b_up=false
-- end

-- function p1update()
--  local i
--  if (p1.ax > 0) then
--   i=p1.x
--   while (p1.x < flr(i+p1.ax)) do
--    if (istilesolidpx(p1.x+8,p1.y)) or (istilesolidpx(p1.x+8,p1.y+7)) then
--     p1.ax=0
--     break
--    end
--    p1.x=p1.x+1
--   end
--  elseif (p1.ax < 0) then
--   i=p1.x
--   while (p1.x > flr(i-abs(p1.ax))) do
--    if (istilesolidpx(p1.x-1,p1.y)) or (istilesolidpx(p1.x-1,p1.y+7)) then
--     p1.ax=0
--     break
--    end
--    p1.x=p1.x-1
--   end
--  end
--   -- check to see if the player is standing on a tile
--   if (istilesolidpx(p1.x,p1.y+8)) or (istilesolidpx(p1.x+7,p1.y+8)) then
--     p1.grounded=true
--   else
--     p1.grounded=false
--   end

--  if (p1.ay > 0) then
--   i=p1.y
--   while (p1.y < flr(i+p1.ay)) do
--    if (istilesolidpx(p1.x,p1.y+8)) or (istilesolidpx(p1.x+7,p1.y+8)) then
--     p1.ay=0
--     p1.grounded=true
--     break
--    end
--    p1.y=p1.y+1
--   end
--  elseif (p1.ay < 0) then
--   i=p1.y
--   while (p1.y > flr(i-abs(p1.ay))) do
--    if (istilesolidpx(p1.x,p1.y-1)) or (istilesolidpx(p1.x+7,p1.y-1)) then
--     p1.ay=0
--     break
--    end
--    p1.y=p1.y-1
--   end
--  end

--  p1updatefriction()
--  p1updategravity()
__gfx__
00000000009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018881888
00000000099999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00000000000022212221
007007009991999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009900b0990a0a000081888188
00077000999999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000999999990090000012221222
0007700099cc91990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000949499490a0a0b0088188818
00700700099cc9900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000949499490000300021222122
000000000999c990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099949999000b030088818881
00000000009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000099999900000030022122212
__gff__
0000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000000000000000d0000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0000000000000f0f0000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000f00000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000f0f00000f0000000f0f00000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000000000000000f0000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000f00000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000000000000000f0000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000f0f00000f0f00000f0f000f000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0000000e0000000000000e0e00000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
