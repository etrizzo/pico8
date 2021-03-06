pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- dragon curves
-- by emily rizzo


--------------------
----- globals -----
--------------------
pi = 3.14159265359;

-- g_forward is the direction of the "pen" being used to draw. used to draw forward/rotate from a starting point instead of calculating all the points individually
g_forward = {}
g_forward.x = 1;
g_forward.y = 0;
g_forward.theta = 0;
g_forward.tau = 0;

-- g_position is the current position of the pen
g_position = {};
g_position.x = 0;
g_position.y = 0;

-- g_start is the starting position of the pen
g_start = {};
g_start.x = 64;
g_start.y = 64;

-- g_-points are the individual points of the dragon in order. _draw() calls line() between each point in this array.
g_points = {};

g_turns = {};     -- stores the pattern of the dragon as an array of 0 (left turn) and 1 (right turn). (could probably store as bits to optimize)
g_depth = 1;      -- depth of the current dragon
g_maxdepth = 8;     -- max depth of the program. can't really get to a much deeper depth than this
g_linelength = 1;   -- current line length (updated based on depth)

g_dragoncolors = {1, 2, 8, 14, 9, 10, 12};        -- array of colors the dragon cycles through
g_startingangle = 20;   -- starting angle to draw from
g_speed = .4;       -- speed of the sin wave. 1 is 1 cycle per second.



--------------------
-- game functions --
--------------------

function _init()
  add(g_points, g_position);
  rotate(0);
  generatedragon();
end


function _update()
  playerinput();       -- if you wanna manually play with the depth
  --updatedepthwithtime();          -- updates depth automatically with sin(time)
end

function _draw()
  beginframe();
  -- used to determine color stuff for quick playing around with it.
  local coloroffset = 1; -- distance of between colors for each dragon
  local startingcolor = 5; -- starting point in the color array

  -- draw the dragon 4 times, rotated 90 degrees, and with a different color
  drawdragonwithoffset(0,startingcolor)
  startingcolor += coloroffset;
  drawdragonwithoffset(90,startingcolor)
  startingcolor += coloroffset;
  drawdragonwithoffset(180,startingcolor)
  startingcolor += coloroffset;
  drawdragonwithoffset(270,startingcolor)


  --[[  
  -- debug stuff --
  print(#g_points, 0, 0);
  print(#g_turns, 16, 0);
  print(g_forward.x, 32, 0);
  print (g_forward.y, 48, 0);
  print(g_depth, 80, 0);
  
  
  for i=1,#g_turns do
    print(g_turns[i], i * 8, 16);
  end
  ]]
end

-- updates depth with sin function
function updatedepthwithtime()
  local olddepth = depth;
  local sinheight = sin(time() * g_speed);
  sinheight = (sinheight + 1 ) * .5;        --normalize the boy
  local depthfloat = sinheight * g_maxdepth;
  g_depth = ceil(depthfloat);
  clamp(g_depth, 1, g_maxdepth);

  if (not (olddepth == g_depth)) then
    generatedragon();   -- only generate the dragon when you are on a different depth
  end
end

function beginframe()
  cls();
  camera(0,0);
  --map(0,0,0,0,128,64)
end

-- draws the current dragon at a different angle and color
function drawdragonwithoffset(angle, coloroffset)
  setangle(g_startingangle);
  rotate(g_depth * 45);
  rotate(angle);
  g_points = {};
  generatedragonpoints();
  local colorindex = ((g_depth + coloroffset) % #g_dragoncolors) + 1
  color(g_dragoncolors[colorindex]);
  drawdragon(0,0);
end

-- generates dragon at g_depth
function generatedragon()
  g_points = {};
  g_turns = {};
  g_turns = createdragonturnsfordepth(g_depth);
  setangle(g_startingangle);
  rotate(g_depth * 45);
  determinelinelength();
  generatedragonpoints();
end

-- recursive function to generate the pattern of turns for the dragons (eventually make it a bitwise thing lololol)
function createdragonturnsfordepth(depth, turns)
  if (turns == nil) then
    turns = { 1 }   -- 0 = left, 1 = right
  end

  if (depth == 0) then
    return turns;
  end

  -- add a right turn
  add(turns, 1);
  --reverse the turns and append it to the end of the dragon
  initialnumturns = #turns - 1;
  for i=0,initialnumturns-1 do
    if (turns[initialnumturns - i] == 0) then
      add(turns,1)
    else
      add(turns,0)
    end
  end

  -- r e c u r s e
  return createdragonturnsfordepth(depth - 1, turns);
end

-- determine the length of a single line at this depth
-- this is mostly magic numbers to make it fit the screen, but the lines get 1/2 as long at the next highest depths
function determinelinelength()
  minlinelength = ceil(128 / (g_maxdepth * 16));
  local inversedepth = g_maxdepth - g_depth;      
  g_linelength = (minlinelength * 2) * inversedepth;
  if (g_linelength <= 0) then
    g_linelength = minlinelength;
  end
end

-- actually generate and store the points in the dragon
-- generated by "drawing forward" from the start point and rotating according to the turns array
-- (doesn't actually call draw line, just stores the points generated if you did draw forward)
function generatedragonpoints()
  g_position = g_start;
  for turn in all(g_turns) do
    drawforward(g_linelength);
    if (turn == 0) do
      rotate(90);
    else
      rotate(-90);
    end
  end
end

-- actually draw all of the lines in the g_points array
-- can pass in x and y offset to translate the entire dragon
function drawdragon(xoffset, yoffset)
  local offset = { };
  offset.x = xoffset;
  offset.y = yoffset;
  if (#g_points > 1) then
    for i=1,(#g_points - 1) do
      drawline(addvectors(g_points[i], offset), addvectors(g_points[i + 1], offset));
    end
  end
end

-- for manually changing depth ( comment out updatedepth call )
function playerinput();
  if (btnp(2)) then -- increase depth w/ up
    if (g_depth < g_maxdepth) then
      g_depth += 1;
      generatedragon();
    end
  end

  if (btnp(3)) then
    if (g_depth > 0) then -- decrease depth w/ down
      g_depth -= 1;
      generatedragon();
    end
  end
end

----------------------------
-- point generation (pen) --
----------------------------

-- rotates the forward direction of the pen by degrees
function rotate(degrees)
  g_forward.theta += degrees;
  local newforward = makedirectionatdegrees(g_forward.theta);
  g_forward.x = newforward.x;
  g_forward.y = newforward.y;
end

-- hard sets the forward direction of the pen
function setangle(degrees)
  g_forward.theta = degrees;
  local newforward = makedirectionatdegrees(g_forward.theta);
  g_forward.x = newforward.x;
  g_forward.y = newforward.y;
end

-- draws the pen forward by length
function drawforward(length)
  local endpoint = addvectors(g_position, scalevector(g_forward, length));
  add(g_points, endpoint);  
  g_position = endpoint;
end

--------------------
---- math utils ----
--------------------

-- pico8 uses whatever the tau equivalent of a radian is (1.0 == 360 degrees)
function tautodegrees(tau)
  return tau * 360;
end

function degreestotau(degrees)
  -- 90 deg = .25 = deg / 360
  g_forward.tau =  degrees /360;
  return degrees /360;
end

function cosdegrees(degrees)
  return cos(degreestotau(degrees));
end

function sindegrees(degrees)
  return sin(degreestotau(degrees));
end

-- makes a vector pointing in the provided direction
function makedirectionatdegrees(degrees)
  local xcoord = cosdegrees(degrees);
  local ycoord = sindegrees(degrees);
  local vector = {}
  vector.x = xcoord;
  vector.y = ycoord;
  return vector;
end

function normalize(vector)
  local normalized = {};
  local length  = getlength(vector);
  normalized.x = vector.x / length;
  normalized.y = vector.y / length;
  return normalized;
end

function getlength(vector)
  return sqrt((vector.x * vector.x) + (vector.y * vector.y));
end

function addvectors(v1, v2)
 local vec = {};
 vec.x = v1.x + v2.x;
 vec.y = v1.y + v2.y;
 return vec;
end

function scalevector(vec, scale)
  local returnvec = {};
  returnvec.x = vec.x * scale;
  returnvec.y = vec.y * scale;
  return returnvec;
end
  
function clamp(val, min, max)
  if (val < min) do
    return min;
  end

  if (val > max) do
    return max;
  end

  return val;

end


----------------
-- draw utils --
----------------

-- draws a line but between two "vectors", convenience
function drawline(startpoint, endpoint)
  line(startpoint.x, startpoint.y, endpoint.x, endpoint.y); 
end




function cflip() if(slowflip)flip()
end
ospr=spr
function spr(...)
ospr(...)
cflip()
end
osspr=sspr
function sspr(...)
osspr(...)
cflip()
end
omap=map
function map(...)
omap(...)
cflip()
end
orect=rect
function rect(...)
orect(...)
cflip()
end
orectfill=rectfill
function rectfill(...)
orectfill(...)
cflip()
end
ocircfill=circfill
function circfill(...)
ocircfill(...)
cflip()
end
ocirc=circ
function circ(...)
ocirc(...)
cflip()
end
oline=line
function line(...)
oline(...)
cflip()
end
opset=pset
psetctr=0
function pset(...)
opset(...)
psetctr+=1
if(slowflip and psetctr%4==0)flip()
end
odraw=_draw
function _draw()
if(slowflip)extcmd("rec")
odraw()
if(slowflip)for i=0,99 do flip() end extcmd("video")cls()stop("gif saved")
end
menuitem(1,"put a flip in it!",function() slowflip=not slowflip end)





__map__
1515151515151515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151516161616161515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151516161616161615151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151516161616161615151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151516161616161615151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01020000060500a0500f3501135013350173501b3501e3502135023350253502635026350273502635024350213501e3501a35015350113500f3500e3500d3500d3500d3500f350133501d350130501375013750
00030000347503475033750317502d7502975025750217501d7501a750177501575013750107500b75009750057400473002730017200172001720017200171001710017100f7501075015750197501d75000000
01100000183511a3511c3511d3511f351213512335124351247512475124751247512475124751247512475124751247512475124751247512475124751247510000000000000000000000000000000000000000
000800001355017550185501d5502455028550215501c5501a55016550155501b55022550275502b5502a550275501e55017550185501d55022550265502b5502d5502955026550205501b55015550145501a550
010b000002750017500175002750047500875011750167501d75023750287502c7503175035750387503c7503e7501575016750197501a7501e750207502275025750287502b7502f750337503d7503f7503f750
01200008303550000037355000003b355000003635500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000201f1521f1521f1521f1551f1521f1521f1521f1551e1521e1521e1521e1551e1521e1521e1521e1551f152000001e152000001c1520000023152000001915219152191321915519152191521913219155
012000201c4221c4221c4221c4221c4221c4221c4221c4211a4221a4221a4221a4221a4221a4221a4221a4211c4221c4221c4221c4221c4221c4221c4221c4211c4221c421184221842117422174211c4221c421
__music__
00 05464744
03 05060744


-- 1. Paste this at the very bottom of your PICO-8 
--    cart
-- 2. Hit return and select the menu item to save
--    a slow render gif (it's all automatic!)
-- 3. Tweet the gif with #PutAFlipInIt
-- 
-- Notes: 
--
-- This relies on the max gif length being long
-- enough. This can be set with the -gif_len 
-- command line option, e.g.:
--
--   pico8.exe -gif_len 30
--
-- The gif is where it would be when you hit F9.
-- Splore doesn't play nicely with this, you
-- need to save the splore cart locally and load
-- it.
--
-- You might need to remove unnecessary 
-- overrides to save tokens. pset() override
-- flips every 4th pset() call.
--
-- This doesn't always play nicely with optional
-- parameters, e.g. when leaving out the color 
-- param.
--
-- Name clashes might happen, didn't bother
-- to namespace etc.

