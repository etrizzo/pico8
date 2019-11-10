pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- Cherrymander
-- by tinkkles and drell

-- Constants
ds = 0;
lastcalled = time();


-- globals
tilecursor = 
{
	x = 0;
	y = 0;
};
hovertile = 
{
	x = 0;
	y = 0;
};

g_weedsinlevel = {}
flower = {
	tiles = {1, 0, 1, 0, 1, 0, 1, 0, 1}; 
	sprite = 3;
}

g_currentflower = flower;
g_weedsaddedthisturn = 0;

g_canplant = false;

debugvalidtiles = {};

badtiles = {};

-- variables that need to be reset pre game instance! 
function setglobals()
	tilecursor.x = 0;
	tilecursor.y = 0;
    camerax = 0
    cameray = 0
    gamestate = "playing"; -- attract, playing, victory
    playstate = "playing"; -- playing, levelcomplete
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
    getalltheweedsinlevel()
end

--------------------------------------------------------------------------
-- update
--------------------------------------------------------------------------
function _update()
    calculatedeltaseconds()
    camera(camerax, cameray)

    if(gamestate == "attract") attractupdate();
    if(gamestate == "playing") playingupdate();
    if(gamestate == "victory") victoryupdate();
end

--------------------------------------------------------------------------
function attractupdate()
    if btnp(4) then
        gamestate = "playing";
    end
end

--------------------------------------------------------------------------
function playingupdate()
    _handleinput();
end

--------------------------------------------------------------------------
function victoryupdate()
end

--------------------------------------------------------------------------
function _handleinput()
    if (playstate == "levelcomplete") handlelevelcompleteinput();
    if (playstate == "playing") handleplayinginput();
    
end

function handleplayinginput()
    handlecursorinput();
	if (btnp(4) or btnp(5)) then
		tryplaceflower();
        
        if(g_canplant) then
            afterplayerplants();
        end
    end
end

function handlelevelcompleteinput()
    if (btnp(4) or btnp(5)) then
        movecameratonextmap();
    end
end


function afterplayerplants()
    spreadtheweeds()
    canstillspread = canweedsstillspread();
    if (not canstillspread) then
        -- game ends (maybe make all empty spaces flowers)
        playstate = "levelcomplete";
    end

    --if player can't place
    if (not flowerscanbeplaced()) then
        playstate = "levelcomplete";
    end
end

--------------------------------------------------------------------------
function flowerscanbeplaced()
    local posx = camerax;
    local posy = cameray;
    debugvalidtiles = {};

    local canplaceanywhere = false;

    for y=0, 15 do 
        for x=0, 15 do        
            local tileposx, tileposy = gettileposfromworldpos(posx,posy)
            if (cangrowattile(tileposx, tileposy)) then
                local tile = {
                    x = tileposx,
                    y = tileposy
                }
                if (canplantflowerattile(g_currentflower, tile)) then
                    canplaceanywhere = true;    --todo: return true
                    add(debugvalidtiles, tile);

                end
            end

            posx += 8
        end

        posy += 8
        posx = camerax;
    end
    return canplaceanywhere;
end

--------------------------------------------------------------------------
function tryplaceflower()
    if (canplantflowerattile(flower, hovertile)) then
        plantflower(g_currentflower, hovertile);
        g_canplant = true;
    else 
        g_canplant = false;
    end
end

--------------------------------------------------------------------------
function canplantflowerattile(flower, tile)

    badtiles ={};
    arraypos = 1;
    for y=tile.y-1, tile.y+1 do 
        for x=tile.x-1, tile.x+1 do
            if ((flower.tiles[arraypos] != 0) and (not cangrowattile(x, y))) then
                bad = {
                    tilex = x;
                    tiley = y;
                    pos = arraypos
                }
                add(badtiles, bad);
            end
            arraypos+=1;
        end
    end
    if (count(badtiles) > 0) then
      return false;  
    end
    return true;
end

--------------------------------------------------------------------------
function plantflower(flower, tile) 
    arraypos = 1;
    for y=tile.y-1, tile.y+1 do 
        for x=tile.x-1, tile.x+1 do
            if (flower.tiles[arraypos] != 0) then
                settilesprite(x, y, flower.sprite);
            end
            arraypos+=1;
        end
    end
end

--------------------------------------------------------------------------
function handlecursorinput()
	deltax = 0;
	deltay = 0;
	movespeed = 2;
	if (btn(0)) then
		deltax-=movespeed;
	end
	
	if (btn(1)) then
		deltax+=movespeed;
	end
	
	if (btn(2)) then
		deltay-=movespeed;
	end
	
	if (btn(3)) then
		deltay+=movespeed;
	end;
	
	tilecursor.x += deltax;
	tilecursor.y += deltay;
	
	updatehovertile();
end

--------------------------------------------------------------------------
function updatehovertile()
	hovertile.x = (tilecursor.x - (tilecursor.x % 8)) / 8;
	hovertile.y = (tilecursor.y - (tilecursor.y % 8)) / 8;
end

--------------------------------------------------------------------------
-- render
--------------------------------------------------------------------------
function _draw()
    cls()
    if(gamestate == "attract") attractrender();
    if(gamestate == "playing") playingrender();
    if(gamestate == "victory") victoryrender();
end

--------------------------------------------------------------------------
function attractrender()
    print(gamestate, 0, cameray);
end

--------------------------------------------------------------------------
function playingrender()
    map(0,0,0,0,128,64)
    drawcursor();
    debugrendervalidtiles()
    if (playstate == "levelcomplete") levelcompleterender();

end

--------------------------------------------------------------------------
function debugrendervalidtiles()
    for tile in all(debugvalidtiles) do
        worldposx = tile.x * 8 + 3;
        worldposy = tile.y * 8 + 3;

        rect(worldposx, worldposy, worldposx + 1, worldposy + 1, 10);
    end
end

--------------------------------------------------------------------------
function levelcompleterender()
    rectfillui(18, 18, 110, 52, 7); -- white border
    rectfillui(20, 20, 108, 50, 1); -- dark blue center
    printui("Level complete!", 30, 30, 7);
    printui("Press x!", 25, 40, 7);
end

--------------------------------------------------------------------------
function victoryrender()
    print(gamestate, 0, cameray);
end

--------------------------------------------------------------------------
function drawcursor()
	--draw the tile cursor
    arraypos = 1;
    canplace = true;
    for y=hovertile.y-1, hovertile.y+1 do 
        for x=hovertile.x-1, hovertile.x+1 do
            if (flower.tiles[arraypos] != 0) then
                
                if (cangrowattile(x, y)) then
                    spr(15, x * 8, y * 8);
                else
                    spr(31, x * 8, y * 8);
                    canplace = false;
                end
            end
            arraypos+=1;
        end
    end

	
    --draw the mouse position
    if (canplace) then
        pal(7, 11);
    end
    spr(13, tilecursor.x, tilecursor.y);
    
    pal();
end

--------------------------------------------------------------------------
-- utils
--------------------------------------------------------------------------
function calculatedeltaseconds()
    ds = (time() - lastcalled)
    lastcalled = time()
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

--------------------------------------------------------------------------
function gettilesprite(tileposx,tileposy)
    return mget(tileposx,tileposy)
end

--------------------------------------------------------------------------
function settilesprite(xpos,ypos,sprite)
    mset(xpos,ypos,sprite)
end

--------------------------------------------------------------------------
function movecameratonextmap()
    -- 8 by 4 is map dimensions
    camerax += 128
    if camerax > (128 * 8) then
        camerax = 0
        cameray += 128
    end
    playstate = "playing";
    tilecursor.x = camerax;
    tilecursor.y = cameray;
    updatehovertile();
    getalltheweedsinlevel();
end

--------------------------------------------------------------------------
function gettileposfromworldpos(worldposx, worldposy)
    local x = flr(worldposx / 8)
    local y = flr(worldposy / 8)

    return x,y
end

--------------------------------------------------------------------------
function printui(text, posx, posy, col)
	posx = posx or 0;
	posy = posy or 0;
	col = col or 7;
	print (text, posx + camerax, posy + cameray, col);
end

--------------------------------------------------------------------------
function rectui(x0, y0, x1, y1, col)
    rect(x0 + camerax, y0 + cameray, x1 + camerax, y1 + cameray, col);
end

--------------------------------------------------------------------------
function rectfillui(x0, y0, x1, y1, col)
    rectfill(x0 + camerax, y0 + cameray, x1 + camerax, y1 + cameray, col);
end

--------------------------------------------------------------------------
function getalltheweedsinlevel()
    g_weedsinlevel = {};
    posx = camerax;
    posy = cameray;

    for y=0, 15 do 
        for x=0, 15 do        
            tileposx, tileposy = gettileposfromworldpos(posx,posy)
            if gettilesprite(tileposx,tileposy) == 1 then
                weed = createweed(tileposx, tileposy)
                add(g_weedsinlevel, weed)
            end

            posx += 8
        end

        posy += 8
        posx = camerax;
    end
end

--------------------------------------------------------------------------
function createweed(tileposx, tileposy)
    local weed = {}
    weed.x = tileposx
    weed.y = tileposy

    return weed
end

--------------------------------------------------------------------------
function spreadtheweeds()
    local allnewweeds = {}
    for weed in all(g_weedsinlevel) do
        posx = weed.x;
        posy = weed.y

        if cangrowattile(posx + 1, posy) then
            newweedspos = {x = posx + 1, y = posy}

            if checkifpositionisinlist(newweedspos, allnewweeds) == false then
                add(allnewweeds, newweedspos)
            end
        end

        if cangrowattile(posx - 1, posy) then
            newweedspos = {x = posx - 1, y = posy}
            if checkifpositionisinlist(newweedspos, allnewweeds) == false then
                add(allnewweeds, newweedspos)
            end
        end

        if cangrowattile(posx, posy + 1) then
            newweedspos = {x = posx, y = posy + 1}
            if checkifpositionisinlist(newweedspos, allnewweeds) == false then
                add(allnewweeds, newweedspos)
            end
        end

        if cangrowattile(posx, posy - 1) then
            newweedspos = {x = posx, y = posy -1}
            if checkifpositionisinlist(newweedspos, allnewweeds) == false then
                add(allnewweeds, newweedspos)
            end
        end

    end

    for weedpos in all(allnewweeds) do
        weed = createweed(weedpos.x, weedpos.y)
        settilesprite(weedpos.x, weedpos.y, 1)
        add(g_weedsinlevel, weed)
    end
end

function canweedsstillspread()
    for weed in all(g_weedsinlevel) do
        posx = weed.x;
        posy = weed.y
        if (cangrowattile(posx + 1, posy)) return true;
        if (cangrowattile(posx - 1, posy)) return true;
        if (cangrowattile(posx, posy + 1)) return true;
        if (cangrowattile(posx, posy - 1)) return true;
    end
    return false;
end

--------------------------------------------------------------------------
function checkifpositionisinlist(pos, array)
    for currentPos in all(array) do
        if (pos.x == currentPos.x) and (pos.y == currentPos.y) then
            return true;
        end
    end

    return false
end

--------------------------------------------------------------------------
function cangrowattile(tileposx, tileposy)
    return (gettilesprite(tileposx,tileposy) == 5)
end

-- hello qtie
__gfx__
00000000555555550000000088888888000000004444444400000000555555150000000033333333000000001111111100000000777500000000000066600666
00000000500000050000000080000008000000004444464400000000111111110000000033333b3b000000001222222100000000775000000000000060000006
007007005000000500000000800eee080000000045444444000000005551555500000000333333b3000000001222222100000000717500000000000060000006
000770005090009500000000800e0008000000004444944400000000555155550000000033333333000000001222222100000000101700000000000000000000
000770005090909500000000800ee00800000000444444440000000011111111000000003b3b3333000000001222222100000000000100000000000000000000
007007005099999500000000800e0008000000004944445400000000515555150000000033b33333000000001222222100000000000000000000000060000006
00000000500000050000000080000008000000004444444400000000515555150000000033333333000000001222222100000000000000000000000060000006
00000000555555550000000088888888000000004444444400000000111111110000000033333333000000001111111100000000000000000000000066600666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000088
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000808
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080008008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080080008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080800008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088000008
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888888
__gff__
0000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050505050501050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050105050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050505050505050505010505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050105010505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050505050505050505050505050b0b05050505050501050105050505050b0b05050505010501050105050505050b0b05050505050105010505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050503030305050507070505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050503010505050507010505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050503030305050507070505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b09090505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b09090505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b05050505050505050505050505050b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b00000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
