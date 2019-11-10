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
nullflower = 
{
	tiles = {0, 0, 0,  0, 0, 0,  0, 0, 0}; 
	sprite = 3;
}

g_currentflower = nullflower;

canplant = false;

badtiles = {};

-- variables that need to be reset pre game instance! 
function setglobals()
	tilecursor.x = 0;
	tilecursor.y = 0;
    camerax = 0
    cameray = 0
    g_currentlevel = 1
    g_amoutofpiecesforlevel = 0
    g_currentpieceindex = 1
    g_hidecursor = false
    gamestate = "playing"; -- attract, playing, victory
end

g_possibleFlowers =
{
    {0, 1, 0,  0, 1, 0,  0, 1, 0}, -- 3 vertical (1) 
    {1, 0, 1,  0, 1, 0,  1, 0, 1}, -- x shape (2)
    {1, 0, 0,  0, 1, 0,  0, 0, 0}, -- bl 2 piece diag (3)
    {0, 0, 0,  1, 1, 1,  0, 0, 0}, -- 3 horizontal (4) 
    {1, 1, 1,  1, 1, 1,  1, 1, 1}, -- full block (5) 

}

-- these use an index into g_possibleFlowers
g_levels = 
{
    { 5, 1, 2, 3}
}

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
    startoflevel()
end

--------------------------------------------------------------------------
function startoflevel()
    g_hidecursor = false
    
    g_currentpieceindex = 1;
    level = g_levels[g_currentlevel]
    g_currentflower.tiles = g_possibleFlowers[level[g_currentpieceindex]]
    g_amoutofpiecesforlevel = #level
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
	handlecursorinput();
	if (btnp(4) or btnp(5)) then
		tryplaceflower();
        
        if(canplant) then
            afterplayerplants();
        end
    end
end

--------------------------------------------------------------------------
function afterplayerplants()
    
    local numberOfWeedsAtStart = #g_weedsinlevel
    spreadtheweeds()

    if numberOfWeedsAtStart == #g_weedsinlevel then
        -- game ends (maybe make all empty spaces flowers)
        
        gamestate = "victory"
        return
    end

    changetonextflowerpiece()

end

--------------------------------------------------------------------------
function tryplaceflower()
    if (canplantflowerattile(flower, hovertile)) then
        plantflower(g_currentflower, hovertile);
        canplant = true;
    else 
        canplant = false;
    end
end

--------------------------------------------------------------------------
function canplantflowerattile(flower, tile)
    -- spriteIndex = gettilesprite(tile.x, tile.y);
    -- if (isplantable(spriteIndex)) then
    --     return true
    -- end

    -- return false;

    badtiles ={};
    arraypos = 1;
    for y=tile.y-1, tile.y+1 do 
        for x=tile.x-1, tile.x+1 do
            spriteindex = gettilesprite(x, y);
            if ((g_currentflower.tiles[arraypos] != 0) and (not isplantable(spriteindex))) then
                bad = {
                    tilex = x;
                    tiley = y;
                    pos = arraypos
                }
                add(badtiles, bad);
                --return false;
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

function isplantable(spriteindex)
    return spriteindex == 5;
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

    if (canplant) then
        printui("can plant", 0, 0, 3);
    else
        printui("no can plant: " .. tostr(count(badtiles)), 0, 0, 0);
        
        y = 8;
        for tile in all (badtiles) do
            printui(tile.tilex .. ", " .. tile.tiley .. " array index: " .. tile.pos, 0, y);
            y+=8;
        end
    end
end

--------------------------------------------------------------------------
function attractrender()
    print(gamestate, 0, cameray);
end

--------------------------------------------------------------------------
function playingrender()
    map(0,0,0,0,128,64)
    drawcursor();
    drawlevelpieceui()
end

--------------------------------------------------------------------------
function drawlevelpieceui()
    if (g_amoutofpiecesforlevel - g_currentpieceindex) < 0 then
        return
    end
    
    rectfill(camerax + 2, cameray + 8, camerax + 21, cameray + 63, 14 )
    rect(camerax + 2, cameray + 8, camerax + 21, cameray + 63, 7 )

    currentheight = cameray + 11
    boxsize = 13
    amountToDraw = min(3, g_amoutofpiecesforlevel + 1 - g_currentpieceindex)

    for i = g_currentpieceindex, g_currentpieceindex + amountToDraw -1 do
        rectfill(camerax + 5, currentheight, camerax + 18, currentheight + 13, 7)
        
        if(i == g_currentpieceindex) then
            rect(camerax + 5, currentheight, camerax + 18, currentheight + boxsize, 3)
        end

        drawpieceforui(i, camerax + 6, currentheight, camerax + 16, currentheight + 14)
        
        currentheight += 18
    end

end

--------------------------------------------------------------------------
function drawpieceforui(tableindex, minx, miny)
    
    levelinfo = g_levels[g_currentlevel]
    currentpiece = g_possibleFlowers[levelinfo[tableindex]]
    
    minx += 1
    miny += 1

    if currentpiece[1] == 1 then
        rectfill(minx + 1, miny + 2, minx + 2, miny + 3,3)
    end

    if currentpiece[2] == 1 then
        rectfill(minx + 4, miny + 2, minx + 5, miny + 3, 3)
    end

    if currentpiece[3] == 1 then
        rectfill(minx + 7, miny + 2, minx + 8, miny + 3, 3)
    end
    
    -- 2nd
    if currentpiece[4] == 1 then
        rectfill(minx + 1, miny + 5, minx + 2, miny + 6, 3)

    end

    if currentpiece[5] == 1 then
        rectfill(minx + 4, miny + 5, minx + 5, miny + 6, 3)

    end

    if currentpiece[6] == 1 then
        rectfill(minx + 7, miny + 5, minx + 8, miny + 6, 3)
    end

    -- 3rd
    if currentpiece[7] == 1 then
        rectfill(minx + 1, miny + 8, minx + 2, miny + 9, 3)

    end

    if currentpiece[8] == 1 then
        rectfill(minx + 4, miny + 8, minx + 5, miny + 9, 3)
    end

    if currentpiece[9] == 1 then
        rectfill(minx + 7, miny + 8, minx + 8, miny + 9, 3)
    end


end

function getboxfrombox(minpercx, minpercy, maxpercx, maxpercy, theminx, theminy, themaxx, themaxy)
    width = abs(themaxx - theminx)
    height = abs(themaxy - theminy)

    newminsx = minpercx * width;
    newminsy = minpercy * height;

    newmaxx = maxpercx * width;
    newmaxy = maxpercy * height;

    return { minx = theminx + newminsx, miny = theminy + newminsy, maxx = theminx + newmaxx, maxy = newmaxy + theminy}
end

--------------------------------------------------------------------------
function victoryrender()
    print(gamestate, 0, cameray);
end

--------------------------------------------------------------------------
function drawcursor()
	--draw the tile cursor (if we have peices)
    
    if g_hidecursor == false then 
        arraypos = 1;
        canplace = true;
        for y=hovertile.y-1, hovertile.y+1 do 
            for x=hovertile.x-1, hovertile.x+1 do
                if (g_currentflower.tiles[arraypos] != 0) then
                    
                    spriteindex = gettilesprite(x, y);
                    if (isplantable(spriteindex)) then
                        spr(15, x * 8, y * 8);
                    else
                        spr(31, x * 8, y * 8);
                        canplace = false;
                    end
                end
                arraypos+=1;
            end
        end
    end
	
    --draw the mouse position
    if (canplace) then
        --pal(1, 3);
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
    
    tilecursor.x = camerax;
    tilecursor.y = cameray;
    updatehovertile();
end

--------------------------------------------------------------------------
function changetonextflowerpiece()
    g_currentpieceindex += 1;

    if g_currentpieceindex > g_amoutofpiecesforlevel then
        g_hidecursor = true
        g_currentflower = nullflower
        return
    end

    levels = g_levels[g_currentlevel]
    g_currentflower.tiles = g_possibleFlowers[levels[g_currentpieceindex]]
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
function getalltheweedsinlevel()
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
090909090909090909090909090909090b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050505050505050505050505090b05050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050505050105050505050505090b05050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050505050505050505050505090b05050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909010505050505050505050505090905050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050505050505050505050505090905050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050505050505050501050505090905050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050505050505050505050505090905050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050505050505050505050505090905050505050501050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050303030505050707050505090905050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050301050505050701050505090905050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050303030505050707050505090905050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050505050505050505050505090905050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050505050505050505050505090905050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
090909050505050505050505050505090905050505050505050505050505050b0b00000000000000000000000000000b0b00000000000000000000000000000b0b00000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09090909090909090909090909090909090909090909090909090b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090909090909090909090909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0900000000000000000000000000000909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0900000000000000000000000000000909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0900000000000000000000000000000909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0900000000000000000000000000000909000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
