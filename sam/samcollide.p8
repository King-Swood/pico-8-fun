pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
p1={}

function _init()
 p1.x=10
 p1.y=25
 p1.sp=1
end

function _update()
 if(btn(1))then p1.x+=1 end
 if(btn(0))then p1.x-=1 end
 if(btn(3))then p1.y+=1 end
 if(btn(2))then p1.y-=1 end
 if(btnp(4))then
  p1.sp+=1
  if p1.sp > 3 then p1.sp=1 end
  sfx(0)
 end
end

function _draw()
	cls()
	map(0,0,0,0)
 spr(p1.sp,p1.x,p1.y)
 debug()
end

function debug()
 print("px:"..p1.x..",py:"..p1.y,0,0,10)
 print("tx:"..pxtotile(p1.x)..",ty:"..pxtotile(p1.y),0,6,10)
 print("brick:"..tostr(issolid(p1.x,p1.y)),0,12,10)
end

function pxtotile(px)
 return flr(px/8)
end

function issolid(x,y)
 local tx=pxtotile(x)
 local ty=pxtotile(y)
 return fget(mget(tx,ty),0)
end
__gfx__
000000000bbbb000009999000000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000044444222
000000000b3bbb0009999990000ccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045444442
00700700bbbb6bb099199199000ccc5c000000000000000000000000000000000000000000000000000000000000000000000000000000000a0a000045444442
000770000bb3b6bb9999999900cc5ccc000000000000000000000000000000000000000000000000000000000000000000000000000000000090000045244444
000770000bbb3bbb9919919900ccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000a0a0b0045244444
007007000bbbb33b999119990cccc5c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000300045222444
0000000000bbbbb0099999900cc55c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000b030045555554
000000000000b0000090090000cccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000030044444444
__gff__
0000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000000000f0f0f0000000f0f0f000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000e000f000f00000000000f000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000f0f0f000f0f0f0000000f000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0000000000000000000000000f000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000f000000000000000000000f000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000f00000000000f0f0f000e00000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000f000000000000000f0f0f0f000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000f0000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000f0000000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0000000f0f0f0f0f0000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f00000000000000000000000f0f000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0000000e000000000000000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000183501c3501e3501f3501e3501c350193500e3500b3500935004350013502535023350213501d350193500f3500000000000000000000000000000000000000000000000000000000000000000000000
