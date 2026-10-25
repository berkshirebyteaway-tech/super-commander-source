local M={}
local sin,atan2,sqrt=math.sin,math.atan2,math.sqrt
function M.install(build,ink,kit)
    local tex,put,hash,bayer=kit.tex,kit.put,kit.hash,kit.bayer
    function build.stripes()
        local t=tex(12,12)
        for y=0,11 do for x=0,11 do local d=(x+y)%12;put(t,x,y,d==0 and 1 or d==1 and 2 or 0)end end
        return t
    end
    function build.plaid()
        local P=24;local t=tex(P,P)
        for y=0,P-1 do for x=0,P-1 do
            local h,v=y%P<4,x%P<4;local seam=x%P==12 or y%P==12
            put(t,x,y,h and v and 2 or (h or v)and 1 or seam and 3 or 0)
        end end
        return t
    end
    function build.scales()
        local W,H=16,12;local t=tex(W,H)
        for y=0,H-1 do for x=0,W-1 do
            local best,bdx,bdy=1e9,0,0
            for _,c in ipairs({{0,0},{16,0},{8,6},{-8,6},{24,6},{0,12},{16,12},{8,-6}})do
                local dx,dy=x+.5-c[1],y+.5-c[2];if dy>=-1 then local d=dx*dx+dy*dy;if d<best then best,bdx,bdy=d,dx,dy end end
            end
            local r=sqrt(best);local code=0
            if r>=6.6 then code=1 elseif bdy<2.5 and bdx<0 then code=2 elseif bdy>4 then code=3 end
            put(t,x,y,code)
        end end
        return t
    end
    function build.filigree()
        local P=32;local t=tex(P,P)
        for y=0,P-1 do for x=0,P-1 do
            local a,b=(x-y)%16,(x+y)%16;local code=0
            if a==0 or b==0 then code=1 elseif a==1 or b==15 then code=4 end
            local kx,ky=x%16,y%16
            if (kx<=1 or kx>=15)and(ky<=1 or ky>=15)or (math.abs(kx-8)<=1 and math.abs(ky-8)<=1)then code=2 end
            if code==0 and x%4==2 and y%4==2 then code=3 end
            put(t,x,y,code)
        end end
        return t
    end
    function build.galaxy()
        local P=48;local t=tex(P,P)
        for y=0,P-1 do for x=0,P-1 do
            local dx,dy=x+.5-P/2,y+.5-P/2;local r=sqrt(dx*dx+dy*dy);local a=atan2(dy,dx)
            local arm=sin(2*a-r*.36)
            local d=bayer[(y%4)*4+x%4+1]/16;local code=0
            if r<3.5 then code=2
            elseif arm>.72 and r<23 then code=1
            elseif arm>.35 and r<23 and d<(arm-.35)/.37 then code=5 end
            local s=hash(x,y,121)
            if s<.016 then code=3 elseif s<.032 then code=4 end
            put(t,x,y,code)
        end end
        return t
    end
    local lanternArt={
        '333333.....................33333',
        '3.333.......................333.',
        '...3.........................3..',
        '................................',
        '................................',
        '................................',
        '................................',
        '................................',
        '................................',
        '...............44...............',
        '..............44................',
        '...........1111111111...........',
        '.........11114111141111.........',
        '........1114111111114111........',
        '.......111411211112114111.......',
        '.......114112221122211411.......',
        '.......114122221122221411.......',
        '.......114111111111111411.......',
        '.......114111112211111411.......',
        '.......111411111111114111.......',
        '.......112121212121212111.......',
        '........1122222222222211........',
        '.........11121212121211.........',
        '...........1111111111...........',
        '................................',
        '................................',
        '................................',
        '................................',
        '................................',
        '................................',
        '.3.............................3',
        '333..3.....................3..33'}
    function build.lanterns()
        local P=32;local t=tex(P,P)
        for y=0,P-1 do local row=lanternArt[y+1];for x=0,P-1 do
            local c=row:sub(x+1,x+1);local code=c=='.'and 0 or tonumber(c)
            local dx,dy=(x+.5-16)/10,(y+.5-17)/8
            if code==0 and dx*dx+dy*dy<1 and bayer[(y%4)*4+x%4+1]<3 then code=5 end
            put(t,x,y,code)
        end end
        return t
    end
    ink.lanterns={{'accent',.62},{'gleam',.9},{'dark',.38},{'dark',.3},{'violet',.12}}
    ink.stripes={{'light',.13},{'dark',.08}}
    ink.plaid={{'light',.1},{'light',.2},{'accent',.3}}
    ink.scales={{'accent',.48},{'light',.16},{'dark',.14}}
    ink.filigree={{'gold',.5},{'bright',.8},{'gold',.14},{'dark',.22}}
    ink.galaxy={{'magenta',{.34,.44,.56}},{'white',{.55,.7,.85}},{'ice',{.6,.75,.92}},{'ice',{0,.5,.85}},{'violet',{.16,.22,.3}}}
end
return M
