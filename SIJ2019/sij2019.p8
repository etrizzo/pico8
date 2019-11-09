pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- Cherrymander
-- by tinkkles and drell

-- Constants
ds = 0;
lastcalled = time();

-- variables that need to be reset pre game instance! 
function setglobals()

end

--------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------
function _init()
    startup()
end

--------------------------------------------------------------------------
function startup()
    setglobals()
end


--------------------------------------------------------------------------
-- update
--------------------------------------------------------------------------
function _update()
    calculatedeltaseconds();
end



--------------------------------------------------------------------------
-- render
--------------------------------------------------------------------------
function _draw()
    cls()
end


--------------------------------------------------------------------------
-- utils
--------------------------------------------------------------------------
function calculatedeltaseconds()
    ds = (time() - lastcalled)
    lastcalled = time()

   -- gametimer -= ds -- being lazy and putting this here
end

--------------------------------------------------------------------------
function getcoordsfromindex(index, width)
    xcoord = flr(index % width);
    ycoord = flr((index - xcoord) / width);
    return xcoord,ycoord
end

--------------------------------------------------------------------------
function rangemap(invalue, instart, inend, outstart, outend)

    if(instart == inend) return (outstart + outend) * .5;

    -- translate
    inrange = inend - instart;
    outrange = outend - outstart;
    inrelativetostart = invalue - instart;
    
    -- scale
    fractionintorange = inrelativetostart / inrange;
    outrelativetostart = fractionintorange * outrange;
    
    -- translate
    return outrelativetostart + outstart;
end

--------------------------------------------------------------------------
function clamp(invalue, minvalue, maxvalue)
    if(invalue < minvalue) return minvalue;
    if(invalue > maxvalue) return maxvalue;
    return invalue;
end

-- hello qtie
__gfx__
00000000555555550000000088888888000000004444444400000000555555150000000033333333000000000000000000000000000000000000000000000000
00000000500000050000000080000008000000004444464400000000111111110000000033333b3b000000000000000000000000000000000000000000000000
007007005000000500000000800eee080000000045444444000000005551555500000000333333b3000000000000000000000000000000000000000000000000
000770005090009500000000800e0008000000004444944400000000555155550000000033333333000000000000000000000000000000000000000000000000
000770005090909500000000800ee00800000000444444440000000011111111000000003b3b3333000000000000000000000000000000000000000000000000
007007005099999500000000800e0008000000004944445400000000515555150000000033b33333000000000000000000000000000000000000000000000000
00000000500000050000000080000008000000004444444400000000515555150000000033333333000000000000000000000000000000000000000000000000
00000000555555550000000088888888000000004444444400000000111111110000000033333333000000000000000000000000000000000000000000000000
