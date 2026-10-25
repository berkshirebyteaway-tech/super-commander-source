local M={}
local function back(x)local c=1.9;return 1+(c+1)*(x-1)^3+c*(x-1)^2 end
local E={lin=function(x)return x end,out=function(x)return 1-(1-x)^3 end,inn=function(x)return x*x*x end,
    io=function(x)return x<.5 and 4*x*x*x or 1-(-2*x+2)^3/2 end,back=back}
M.ease=E
M.kinds={
    attack={dur=.8,jab=.07,flash=.13,trail={.11,.5},tracks={
        y={{0,0},{.07,-.35,'out'},{.16,.12,'out'},{.32,0}},
        lunge={{0,0},{.07,-.2,'out'},{.15,.75,'back'},{.5,.55},{.8,0}},
        twist={{0,0},{.07,-28,'out'},{.15,24,'back'},{.5,18},{.8,0}},
        lean={{0,0},{.07,-6},{.15,12,'back'},{.5,8},{.8,0}},
        rSx={{0,0},{.07,-50,'out'},{.14,96,'back'},{.5,92},{.8,0}},
        rE={{0,0},{.07,100,'out'},{.14,0,'out'},{.8,0}},
        lSx={{0,0},{.07,30},{.15,-35,'back'},{.5,-25},{.8,0}},
        lSz={{0,0},{.15,-12},{.8,0}},
        rHip={{0,0},{.15,28,'back'},{.5,20},{.8,0}},
        lHip={{0,0},{.15,-18,'back'},{.5,-12},{.8,0}}}},
    build={dur=.9,flash=.22,stamp=.22,tracks={
        y={{0,0},{.1,.25,'out'},{.22,-.4,'inn'},{.4,0,'out'}},
        lunge={{0,0},{.22,.4,'back'},{.6,.3},{.9,0}},
        twist={{0,0},{.1,-10},{.22,16,'back'},{.6,12},{.9,0}},
        lean={{0,0},{.1,-8},{.22,18,'back'},{.6,14},{.9,0}},
        rSx={{0,0},{.1,165,'out'},{.22,58,'inn'},{.3,64,'out'},{.6,62},{.9,0}},
        rE={{0,0},{.1,20},{.22,0},{.9,0}},
        lSx={{0,0},{.22,-20},{.9,0}},lSz={{0,0},{.12,-40},{.6,-38},{.9,0}},lE={{0,0},{.12,95},{.6,95},{.9,0}},
        rHip={{0,0},{.22,22,'back'},{.6,18},{.9,0}},lHip={{0,0},{.22,-10},{.9,0}}}},
    upgrade={dur=1,flash=.36,ring=.36,tracks={
        spin={{0,0},{.32,360,'out'}},
        y={{0,0},{.06,-.25},{.2,.9,'out'},{.34,0,'inn'},{.4,-.3,'out'},{.55,0}},
        rSz={{0,0},{.08,85,'out'},{.3,85},{.36,10,'out'},{1,0}},
        lSz={{0,0},{.08,-85,'out'},{.3,-85},{.4,-20,'out'},{1,0}},
        rSx={{0,0},{.3,0},{.38,150,'back'},{.7,140},{1,0}},
        rE={{0,0},{.3,0},{.36,40},{.42,0},{1,0}},
        lean={{0,0},{.38,-8},{.7,-6},{1,0}},
        twist={{0,0},{.38,14},{.7,10},{1,0}}}},
}
M.turn={time=.1,jab=.07}
M.hold=2.5
M.armIn,M.armOut=.05,.3
M.flashTime=.18
local ANGLE={y=false,lunge=false}

local function track(k,t)
    if t<=k[1][1]then return k[1][2]end
    for i=2,#k do local a,b=k[i-1],k[i]
        if t<=b[1]then local u=(t-a[1])/(b[1]-a[1]);return a[2]+(b[2]-a[2])*E[b[3]or'io'](u)end
    end
    return k[#k][2]
end
M.track=track

function M.sample(kind,t,out)
    local g=M.kinds[kind];if not g or t>=g.dur then return false end
    for name,k in pairs(g.tracks)do local v=track(k,math.max(0,t));out[name]=if ANGLE[name]==false then v else math.rad(v)end
    return true
end

function M.armWeight(kind,t)
    local g=M.kinds[kind];if not g or t>=g.dur or t<0 then return 0 end
    local fade=g.dur*M.armOut
    return math.min(1,t/M.armIn,(g.dur-t)/fade)
end

function M.start(kind,prevKind,elapsed)
    local g=M.kinds[kind];if not g then return nil end
    if kind=='attack'and prevKind=='attack'and elapsed and elapsed>.1 and elapsed<g.dur then return g.jab end
    return 0
end

function M.turnYaw(from,to,u)
    local d=(to-from+math.pi)%(2*math.pi)-math.pi
    return from+d*back(math.clamp(u,0,1))
end

function M.flash(kind,t)
    local g=M.kinds[kind];local d=g and t-g.flash
    if not d or d<0 or d>=M.flashTime then return 0 end
    return 1-d/M.flashTime
end
return M
