pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- Cherrymander
-- by tinkkles and drell

-- Constants
ds = 0;
lastcalled = time();


g_flowersprites = { 4, 19, 20, 35, 36, 52};
g_weedsprites = {1, 2, 17, 18};

-- globals
tilecursor = 
{
	x = 60;
	y = 60;
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

g_canplant = false;

g_currentlevel = 1;
g_levelresults = {};
g_startoflevel = false;

debugvalidtiles = {};

badtiles = {};

-- variables that need to be reset pre game instance! 
function setglobals()
	tilecursor.x = 60;
	tilecursor.y = 60;
    camerax = 0
    cameray = 0
    g_currentlevel = 1
    g_amoutofpiecesforlevel = 0
    g_currentpieceindex = 1
    g_hidecursor = false
    g_currentflower.sprite = getrandomflowersprite();
    gamestate = "playing"; -- attract, playing, victory
    playstate = "playing"; -- playing, levelcomplete
end

g_possibleFlowers =
{
    {0, 1, 0,  0, 1, 0,  0, 1, 0}, -- 3 vertical (1) 
    {1, 0, 1,  0, 1, 0,  1, 0, 1}, -- x shape (2)
    {0, 0, 0,  0, 1, 0,  1, 0, 0}, -- bl 2 piece diag (3)
    {0, 0, 0,  1, 1, 1,  0, 0, 0}, -- 3 horizontal (4) 
    {1, 1, 1,  1, 1, 1,  1, 1, 1}, -- full block (5) 
    {0, 0, 0,  0, 1, 0,  0, 0, 1}, -- br 2 piece diag (6)
    {0, 0, 0,  0, 1, 0,  0, 1, 0}, -- mid 2 piece vertical (7)
    {1, 0, 1,  1, 0, 1,  1, 0, 1}, -- bun 3x (8)
    {0, 0, 0,  1, 0, 1,  1, 0, 1}, -- bun 2x (9)
    {1, 0, 0,  0, 1, 0,  0, 0, 1}, -- right 3 piece diagonal (10)
    {0, 0, 1,  0, 1, 0,  1, 0, 0}, -- left 3 piece diagonal (11)
    {0, 1, 0,  1, 1, 1,  0, 1, 0}, -- Plus sign + (12)
    {1, 0, 1,  0, 1, 0,  0, 0, 0}, -- micky mouse vertical (13)
    {1, 0, 0,  0, 1, 0,  1, 0, 0}, -- left micky mouse (14)
    {0, 0, 1,  0, 1, 0,  0, 0, 1}, -- right micky mouse (15)
    {0, 0, 0,  0, 1, 0,  1, 0, 1}, -- bottom micky mouse (16)

}

-- these use an index into g_possibleFlowers
g_levels = 
{
    { 1, 1, 4, 4,2,2},
    { 1, 1, 4, 4, 2, 2},
    { 3,6,3,6,6,3},
    { 3, 11, 6, 3,3,3},
    { 1,15, 16, 11, 3, 1, 7,7},
    { 15, 15, 1, 4, 6,7},
    { 5, 1, 2, 3},
    { 5, 1, 2, 3},
    { 5, 1, 2, 3},
    { 5, 1, 2, 3},
    { 5, 1, 2, 3},
}

g_levelnames =
{
	"utah",
	"arkansas",    
	"ohio",
	"lousianna",
	"kentucky",
	"west virginia",
	"penssylvania",
	"maryland",
	"north carolina",
	"texas",
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
    startoflevel(false)
end

--------------------------------------------------------------------------
function startoflevel(didwin)
    g_hidecursor = false
    if (didwin) then
        g_currentlevel+=1;
    else
        reload(0x2000, 0x2000, 0x1000);
    end
    g_currentpieceindex = 1;
    level = g_levels[g_currentlevel]
    g_currentflower.tiles = g_possibleFlowers[level[g_currentpieceindex]]
    g_amoutofpiecesforlevel = #level

    playstate = "playing";
    
    getalltheweedsinlevel();
    g_startoflevel = true;
    
end

--------------------------------------------------------------------------
-- update
--------------------------------------------------------------------------
function _update()
    calculatedeltaseconds()
    camera(camerax, cameray)

    if(gamestate == "attract") then attractupdate();
    elseif(gamestate == "playing") then playingupdate();
    elseif(gamestate == "victory") then victoryupdate();
    end
    if (g_startoflevel) g_startoflevel = false;
end

--------------------------------------------------------------------------
function attractupdate()
    if (btnp(4) or btnp(5)) then
        gamestate = "playing";
        startup();
    end
end

--------------------------------------------------------------------------
function playingupdate()
    _handleinput();
end

--------------------------------------------------------------------------
function victoryupdate()
    if (btnp(4) or btnp(5)) then
        gamestate = "attract";
    end
end

--------------------------------------------------------------------------
function _handleinput()
    if (playstate == "levelcomplete") handlelevelcompleteinput();
    if (playstate == "playing") handleplayinginput();
    
end

function handleplayinginput()
    handlecursorinput();
    if ((btnp(4) or btnp(5)) and (not g_startoflevel)) then
	    tryplaceflower();
       
        if(g_canplant) then
            afterplayerplants();
        end
    end
end

function handlelevelcompleteinput()
    if (btnp(4) or btnp(5)) then
        if (g_levelscore.flowercount > g_levelscore.weedcount) then
            if (g_currentlevel >= #g_levels) then
                gamestate = "victory";
            else
                movecameratonextmap();
                startoflevel(true);
            end
        else
            startoflevel(false);
        end
        
    end
end


function afterplayerplants()
    spreadtheweeds();
    local canstillspread = canweedsstillspread();
    if (not canstillspread) then
        -- game ends (maybe make all empty spaces flowers)
        completelevel(true);
    end

    --if player can't place
    if (not flowerscanbeplaced()) then
        completelevel(false);
    end
end


function completelevel(weedscontrolled)
    playstate = "levelcomplete";
    if (not weedscontrolled) then
        weedswerespread = spreadtheweeds();
        while (weedswerespread) do
            weedswerespread = spreadtheweeds();
        end
    else 
        fillwithflowers();
    end

    -- count weeds & flowers
    g_levelscore = {
        flowercount = 0;
        weedcount = 0;
    }

    local posx = camerax;
    local posy = cameray;
    for y=0, 15 do 
        for x=0, 15 do        
            local tileposx, tileposy = gettileposfromworldpos(posx,posy)
            spriteindex = gettilesprite(tileposx, tileposy);
            if (isflower(spriteindex)) then
                g_levelscore.flowercount+=1;
            elseif (isweed(spriteindex)) then
                g_levelscore.weedcount+=1;
            end
            
            posx += 8
        end
        posy += 8
        posx = camerax;
    end
    if (g_levelscore.flowercount > g_levelscore.weedcount) then
        g_levelresults[g_currentlevel] = levelscore;
    end
end

function debugprintcount()
    local levelscore = {
        flowercount = 0;
        weedcount = 0;
    }
    local posx = camerax;
    local posy = cameray;
    for y=0, 15 do 
        for x=0, 15 do        
            local tileposx, tileposy = gettileposfromworldpos(posx,posy)
            spriteindex = gettilesprite(tileposx, tileposy);
            if (isflower(spriteindex)) then
                levelscore.flowercount+=1;
            elseif (isweed(spriteindex)) then
                levelscore.weedcount+=1;
            end
            
            posx += 8
        end
        posy += 8
        posx = camerax;
    end
    printui(levelscore.flowercount .. " flowers, " .. levelscore.weedcount .. "weeds", 50, 0, 7);
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
    if (canplantflowerattile(g_currentflower, hovertile)) then
        plantflower(g_currentflower, hovertile);
        g_canplant = true;
        changetonextflowerpiece();
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
    printui(gamestate);
end

--------------------------------------------------------------------------
function playingrender()
    map(0,0,0,0,128,64)
    drawcursor();
    debugrendervalidtiles()
    debugprintcount();
    printui(g_currentlevel, 0, 0, 7);
    drawlevelpieceui()
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
    rectfillui(18, 18, 110, 72, 7); -- white border
    rectfillui(20, 20, 108, 70, 1); -- dark blue center
    printui("Level complete!", 30, 30, 7);
    printui(g_levelscore.flowercount .. " flowers and ", 30, 40, 7);
    printui(g_levelscore.weedcount .. " weeds!", 30, 50, 7);
    printui("Press x!", 35, 60, 7);
    
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
    printui("victory!!", 35, 45, 7);
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
    tilecursor.x = camerax + 60;
    tilecursor.y = cameray + 60;
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
    g_currentflower.sprite = getrandomflowersprite();
end

function getrandomflowersprite()
    random =flr(rnd(#g_flowersprites)) + 1 
    return g_flowersprites[random];
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
    added = false;
    for weedpos in all(allnewweeds) do
        weed = createweed(weedpos.x, weedpos.y)
        weedsprite = getrandomweedsprite();
        settilesprite(weedpos.x, weedpos.y, weedsprite)
        add(g_weedsinlevel, weed)
        added = true;
    end

    return added;
end

--------------------------------------------------------------------------
function getrandomweedsprite()
    index = flr(rnd(#g_weedsprites - 1)) + 2;
    return g_weedsprites[index];
end

--------------------------------------------------------------------------
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
function fillwithflowers()
    local posx = camerax;
    local posy = cameray;
    for y=0, 15 do 
        for x=0, 15 do        
            tileposx, tileposy = gettileposfromworldpos(posx,posy)
            if cangrowattile(tileposx, tileposy) then
                settilesprite(tileposx, tileposy, getrandomflowersprite())
            end

            posx += 8
        end

        posy += 8
        posx = camerax;
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

--------------------------------------------------------------------------
function isdirt(spriteindex)
    return (spriteindex == 5)
end

function isflower(spriteindex)
    for flowersprite in all (g_flowersprites) do
        if (spriteindex == flowersprite) then
            return true;
        end
    end
    return false;
end

function isweed(spriteindex)
    for weedsprite in all (g_weedsprites) do
        if (spriteindex == weedsprite) then
            return true;
        end
    end
    return false;
end

--------------------------------------------------------------------------
-- hello qtie
__gfx__
00000000448044444444444444441444449a91444444444444444444555555150000000033333333000000001111111100000000777500000000000066600666
00000000482848044f0444444441c144492219144444464445dd6644111111110000000033333b3b000000001222222100000000775000000000000060000006
00700700448082804f0445f0441cac144a221a14454444445ddddd645551555500000000333333b3000000001222222100000000717500000000000060000006
0007700044f0080444f44f044441c14449111914444494440dd6ddd4555155550000000033333333000000001222222100000000101700000000000000000000
00077000440f0f04480f0f04444b1444449a91144444444405ddddd011111111000000003b3b3333000000001222222100000000000100000000000000000000
007007005f0ff044400ff0044b4b4494431b1b344944445420555dd0515555150000000033b33333000000001222222100000000000000000000000060000006
0000000040fff054450f00f044bb3344413bb3144444444442000004515555150000000033333333000000001222222100000000000000000000000060000006
00000000440004454440040494434444441b31444444444444222244111111110000000033333333000000001111111100000000000000000000000066600666
000000004444444444444444441b1144444444440000000000000000000000000000000000000000000000000000000000000000000000000000000088888888
0000000044444444444f44804441b31444aabb140000000000000000000000000000000000000000000000000000000000000000000000000000000080000088
000000004f044480454f0f044433b9814a3333b10000000000000000000000000000000000000000000000000000000000000000000000000000000080000808
000000004ff44f044400ff044b98b881a3bbba310000000000000000000000000000000000000000000000000000000000000000000000000000000080008008
0000000040f04f044ff0f044428831143bba33b10000000000000000000000000000000000000000000000000000000000000000000000000000000080080008
0000000040fff044400ff004422231b13ba3bb310000000000000000000000000000000000000000000000000000000000000000000000000000000080800008
00000000500f00555f5f00454b33bb3113bb3b140000000000000000000000000000000000000000000000000000000000000000000000000000000088000008
0000000044000ff04000044444133314411111440000000000000000000000000000000000000000000000000000000000000000000000000000000088888888
00000000000000000000000044444444441144440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000441e144b41cc14440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000041eee1b31caac1440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004eeae1e11caacd140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004ea8829e41ccdad40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000b88811214b131d140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000001b11331144b3b3440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000041bb1144444b34440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000444b4444444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004444b3444b3444b40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004433b9844bb344310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004b98b88443bbb3310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000042883444443993110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000422234b4449a99140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000004b33bb3441a999140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000044533354445111440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000009090909090000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0909090909090909090909090909090909090707070707070707070707090909090909090909090909090909070909090b09090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909
0909070707070707070707090909090909090701050505050505050507090909090909090909090909090907010709090907070707070707070707070709090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909
0909070505050505050607090909090909090707050505050505050506070909090909070707070909090705050709090907050505050505050505050709090909090909090909090909090909090909090909090907070709090909090909090909090909090707090909090909090907070707070707070707070707070909
0909070505050505050507090909090909090907050505050505050507090909090907050505060709070505050709090907050505050505050505050709090909090909090909090707070709090909090909090907010709090909090909090909090909070107090909090909090907050505050505050505050505070909
0909070505050505050507070707070709090907050505050505060707070709090705050505060707050505050709090907050505050505050505070909090909090909090909090705050507090909090909090907050709090909090909090909090907010107090909090909090907050505050505050505050505070909
0909070505050505050505050505050709090707050505050505050505050107090705050505050605050505050709090907050505050505050507090909090909090909090907070505050505070909090909090907050707090707070909090909090701010107070707070707090907050505050505050505050505070909
0909070505050505050506050505050709090701060505050505050505050709090705050505050505050505050709090907050505050505050709090909090909090909090705050505050505050707090909090907050506070705060707070909070101010101010101010101070907070707070505050505050505070909
0909070505050605060605050505050709090705050505050505050505070909090705050505050505050505010709090909070505050505050707070707090909090909070505050605060505050507090909090907050506070505050505070909070b0b0b0101010b0b0b0b0b070909090909090705050505070505070909
0909070506060605060605050505050709090705050505050505050506070909090705050505050505050505050709090909090705050505050505050505070909090907050505050501050505050507090909090705050505050505050505070909070101010b0b0b0101010101010709090909090907050505070505070909
0909070506010505060605050505050709090705050505050505050506070909090705050505050505050505050709090909090705050505050505050505010709090705050505050605060505050709090909070505050505050505050701070909070b0b0b0101010b0b0b0b0b070909090909090907050505070505070909
0909070506060605060605050505050709090706060505050505050507090909090705050505050505050505050709090909090705050505050505050505050709070505050505050505050505070909090907050505050505050505070907090909070505050b0b0b0505050507090909090909090907050507070505070909
0909070505050605060605050505050709090707070505050505050607090909090705050505050505050505070909090909090705050505050505050505010709070505050505050505050507070909090701050505050505050505070909090909070505050505050505050507090909090909090907010507070505070709
0909070505050505050605050505050709090909070505050505050709090909090705050505050606050501070909090909070505050505050505050505070909070505050507070707070707090909090705050505050505050507090909090909070505050505050505050507090909090909090705050507070701050507
0909070505050505050505050505050709090909070605050505050709090909090907070505050706050507090909090907010505050507070707050507090909070505050505070909090909090909090701050505050505050507090909090909070505050505050505050505070909090909070505070507070705050507
0909070707070707070707070707070709090909070707070707070709090909090909090707070907050709090909090909070107070101070909070501070909070707070707070909090909090909090907070107050505050709090909090909070505050505050505050507090909090909070707070707070505050507
0909090909090909090909090909090909090909090909090909090909090909090909090909090909070909090909090909090707070707090909090707090909090909090909090909090909090909090909090707070707070909090909090909070707070707070707070709090909090909090909090909090707070709
0909090909090909090909090909090909090907070707070709090909090909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050509090905050505050505050505050505090909090909090909090909090909090909090909090909090909090909090909
0909090909090909090909090909090909090907050505050709090909090909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050509090905050505050505050505050505090905050505050505050505050505050909050505090909090909090909090909
0909090909090909090909090909090909090907050505050709090909090909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050509090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0909090909090907070707070707070909090907050505050709090909090909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050509090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0909090909090705050505050505070909090907050505050507070707070909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050509090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0909090909070505050505050505070909090907050505050505050505050709090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050509090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0909090907050505050505050507070909070707050505050505050505050507090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050509090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0909090707050505050505050507070907050505050505050505050505050505070505050505050505050505050505090909050505050505050505050505050909050505050505050505050505050909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0907070505050505050505050505070907050505050505050105050505050505070505050505050505050505050505090909050505050505050505050505050909050505050505050505050505050909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0705050505050505010505050505070907050505050505050505050505050507090505050505050505050505050505090909050505050505050505050505050909050505050505050505050505050909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0705050505050505050505050705070909070707050505050505050505050507090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0705050505050505050505050707070909090909070507050505050505050709090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0705050707050505050505050505050709090909090707050505050505070909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050509090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0907070907050505050505050505050709090909090909070505050507090909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050509090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0909090909070705050505070707070909090909090909090705050709090909090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050509090505050505050505050505050505090905050505050505050505050505050909050505050505050505050505050505
0909090909090907070707090909090909090909090909090907070709090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909090909
