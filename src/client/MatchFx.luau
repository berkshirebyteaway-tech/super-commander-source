local K=require(script.Parent.FxKit)
local C=K.colors
local GOLD=C.gold:Lerp(C.ember,.3)
local UP=Vector3.yAxis
local T=K.textures
local M={}
M.kit=K
local function quality(reduced,light)return reduced or K.reduced,K.lite or light end

function M.explosion(at,s,rubble,owner,reduced,light)
    local calm,lite=quality(reduced,light);s=math.max(.8,s)
    if calm then K.ring(at,s*.3,s*1.4,C.fire,.5,s*.12,14);return end
    if T.has("fire","smoke","dust","ring","burst","scorch","glow")then return M.explosionTextured(at,s,rubble,owner,lite)end
    K.flash(at+UP*s*.32,s*.8,.14,nil,not lite)
    K.spikes(at,lite and 6 or 8,s*1.05,s*.13,C.flame,.26)
    K.fireball(at,s*.62,lite and 4 or 7,s*.95,lite and .8 or 1.05)
    K.ring(at,s*.35,s*1.8,C.flame,.38,s*.09,lite and 12 or 18)
    K.debris(at,lite and 3 or 8,{rubble,rubble,owner or rubble,C.soot},s*.8,at.Y,1.5)
    if lite then return end
    K.sparks(at+UP*s*.3,6,C.fire,s*.5,.9,at.Y)
    K.puffs(at,s*.42,8,C.dust,.8,s*.04,s*1.15,true)
    K.puffs(at+UP*s*.5,s*.45,4,C.smoke,1.7,s*1.3,s*.35,false,.25)
    K.scorch(at,s*.55,6,2.6)
end

function M.shell(at,tint,reduced)
    local calm,lite=quality(reduced)
    if calm then K.ring(at,.2,1.4,tint,.45,.16,12);return end
    if T.has("glow","burst","ring","dust")then return M.shellTextured(at,tint,lite)end
    K.flash(at+UP*.3,.9,.12,nil,false)
    K.spikes(at,6,1.5,.22,tint,.26,0,math.random()*math.pi)
    K.ring(at,.25,1.7,C.cream,.42,.2,14)
    K.debris(at,4,{C.dust,C.soot},.5,at.Y,.9)
    if lite then return end
    K.puffs(at,.32,6,C.dust,.6,.06,1.2,true)
end

function M.built(at,owner,first,reduced)
    local calm,lite=quality(reduced);local tint=first and C.gold or owner
    if calm then K.ring(at,.6,2.6,tint,.5,.18,14);return end
    if T.has("ring","dust","star","glow")then return M.builtTextured(at,first and GOLD or owner,first,lite)end
    K.brackets(at,2.3,C.cream,.6)
    K.ring(at,.9,4,tint,.6,.38,20)
    K.pillar(at,1.1,7,tint,.8,.08)
    K.puffs(at,.5,7,C.dust,.6,.06,2.3,true,.04)
    if lite then return end
    K.stars(at+UP*2.6,first and 8 or 5,{C.core,tint,C.gold},2,1.5,1.1,1.4,.18)
end

function M.upgraded(at,owner,reduced)
    local calm,lite=quality(reduced)
    if calm then K.ring(at,.6,2.6,owner,.5,.18,14);return end
    if T.has("ring","star")then return M.upgradedTextured(at,owner,lite)end
    K.ring(at,.8,3,owner,.55,.28,18)
    K.pillar(at,.7,4.5,owner,.6)
    K.chevrons(at,1.3,C.core:Lerp(owner,.35),1)
    if lite then return end
    K.stars(at+UP*2.4,5,{C.core,owner},1.8,1.3,1,1.2,.25)
end

function M.conquest(at,reduced)
    local calm,lite=quality(reduced)
    if calm then K.ring(at,1,5,C.gold,.6,.3,18);return end
    if T.has("glow","burst","ring","star")then return M.conquestTextured(at,lite)end
    K.flash(at+UP*.8,2.4,.2,C.core,false)
    K.spikes(at,12,6.5,.55,C.gold,.45)
    K.ring(at,1,7,C.gold,.75,.6,24)
    K.ring(at,.6,4.6,C.cream,.55,.3,18,nil,.08)
    K.pillar(at,1.4,9,C.gold,.9,.05)
    if lite then return end
    K.stars(at+UP*3,12,{C.gold,C.core,C.mint},5.5,2.2,1.6,2.6,.12)
    K.sparks(at+UP*4,10,C.gold,1.1,1.4,at.Y)
end

local POP={{0,0},{.12,1.15},{.25,1},{1,1}}
local function grow(a,b)return {{0,a},{1,b}}end
function M.explosionTextured(at,s,rubble,owner,lite)
    K.flash(at+UP*s*.32,s*.5,.12,nil,not lite)
    K.sprites("glow",at+UP*s*.4,{life={.18,.18},size=grow(s*2.2,s*3.2),color=C.flame,alpha={{0,0},{.5,.2},{1,1}},glow=1,z=1})
    K.sprites("burst",at+UP*.05,{flat=true,life={.3,.3},size={{0,s*.4},{.35,s*2.4},{1,s*2.8}},color=C.flame,alpha={{0,0},{.5,0},{1,1}},rot={0,360},glow=.8})
    K.sprites("fire",at+UP*s*1.05,{count=lite and 3 or 6,life={.85,1.1},size={{0,s*.5},{.15,s*1.3},{1,s*1.45}},speed={s*1,s*1.9},spread=70,
        accel=UP*s*1.2,drag=2.5,rot={-30,30},spin={-25,25},z=s*.7,alpha={{0,0},{.72,0},{.93,1},{1,1}}})
    K.sprites("ring",at+UP*.06,{flat=true,life={.42,.42},size={{0,s*.6},{.3,s*3.2},{1,s*4.2}},color=C.cream,alpha={{0,0},{.3,.1},{1,1}},glow=.5})
    K.debris(at,lite and 3 or 8,{rubble,rubble,owner or rubble,C.soot},s*.8,at.Y,1.5)
    if lite then return end
    K.sparks(at+UP*s*.3,6,C.fire,s*.5,.9,at.Y)
    K.sprites("dust",at+UP*s*.85,{count=8,life={.7,.95},size={{0,s*.6},{.2,s*1.3},{1,s*1.6}},color=C.dust,speed={s*3.2,s*4.2},spread=88,
        drag=5,rot={-15,15},z=s*.5,alpha={{0,0},{.7,0},{.95,1},{1,1}}})
    K.sprites("smoke",at+UP*s*1.1,{count=4,life={1.5,1.9},size={{0,s*.6},{.2,s*1.3},{1,s*1.9}},color=C.smoke,speed={s*.4,s*.9},spread=35,
        accel=UP*s*.5,drag=1.2,rot={-40,40},spin={-12,12},delay=.22,alpha={{0,.05},{.55,.1},{.8,1},{1,1}}})
    K.sprites("scorch",at+UP*.03,{flat=true,life={4.2,4.2},size={{0,s*.4},{.04,s*1.8},{1,s*1.8}},color=C.soot:Lerp(C.smoke,.35),alpha={{0,0},{.75,0},{1,1}},rot={0,360}})
end

function M.shellTextured(at,tint,lite)
    K.sprites("glow",at+UP*.4,{life={.14,.14},size=grow(1.4,2.2),color=C.flame,alpha={{0,0},{1,1}},glow=1,z=1})
    K.sprites("burst",at+UP*.05,{flat=true,life={.24,.24},size={{0,.4},{.4,2.8},{1,3.1}},color=tint,alpha={{0,0},{.5,0},{1,1}},rot={0,360},glow=.7})
    K.sprites("ring",at+UP*.06,{flat=true,life={.36,.36},size={{0,.5},{.3,2.8},{1,3.6}},color=C.cream,alpha={{0,0},{.3,.1},{1,1}},glow=.4})
    K.debris(at,4,{C.dust,C.soot},.5,at.Y,.9)
    if lite then return end
    K.sprites("dust",at+UP*.4,{count=5,life={.55,.75},size={{0,.8},{.25,1.8},{1,2.3}},color=C.dust,speed={6,8},spread=88,drag=6,rot={-15,15},alpha={{0,0},{.75,.05},{1,1}}})
end
local SPARKLE={{0,0},{.18,1},{.6,.8},{1,0}}
local function sizeSeq(k,shape)local t={};for i,p in ipairs(shape)do t[i]={p[1],p[2]*k}end;return t end
function M.builtTextured(at,tint,first,lite)
    K.brackets(at,2.3,C.cream,.6)
    K.sprites("glow",at+UP*1,{life={.3,.3},size=grow(3,4.5),color=tint,alpha={{0,.2},{1,1}},glow=1,z=1})
    K.sprites("ring",at+UP*.06,{flat=true,life={.55,.55},size={{0,2},{.3,7},{1,9}},color=tint,alpha={{0,0},{.4,.1},{1,1}},glow=.8})
    K.pillar(at,1.1,7,tint,.8,.08)
    K.sprites("dust",at+UP*.7,{count=7,life={.55,.75},size={{0,.8},{.25,1.6},{1,1.9}},color=C.dust,speed={9,11},spread=88,drag=6,rot={-15,15},alpha={{0,0},{.7,0},{1,1}}})
    if lite then return end
    K.sprites("star",at+UP*1.4,{count=first and 9 or 6,life={.95,1.35},size=sizeSeq(first and 2.4 or 2,SPARKLE),color=first and GOLD or C.core,speed={4,7},spread=85,
        accel=-UP*4,drag=2,rot={0,90},spin={-120,120},glow=1,delay=.05})
end
function M.upgradedTextured(at,owner,lite)
    K.sprites("ring",at+UP*.06,{flat=true,life={.5,.5},size={{0,1.6},{.3,5.5},{1,7.5}},color=owner,alpha={{0,0},{.4,.1},{1,1}},glow=.8})
    K.pillar(at,.7,4.5,owner,.6)
    K.chevrons(at,1.3,C.core:Lerp(owner,.35),1)
    if lite then return end
    K.sprites("star",at+UP*1.4,{count=5,life={.7,1},size=sizeSeq(1.9,SPARKLE),color=C.core,speed={3,5.5},spread=85,accel=-UP*3,drag=2,rot={0,90},spin={-120,120},glow=1,delay=.2})
end
function M.conquestTextured(at,lite)
    K.sprites("glow",at+UP*1,{life={.3,.3},size=grow(5,7),color=GOLD,alpha={{0,.1},{1,1}},glow=.6,z=1})
    K.sprites("burst",at+UP*.08,{flat=true,life={.5,.5},size={{0,1.5},{.3,8.5},{1,10}},color=GOLD,alpha={{0,0},{.55,0},{1,1}},rot={0,360},glow=.45})
    K.sprites("ring",at+UP*.1,{flat=true,life={.75,.75},size={{0,1.5},{.3,8},{1,11}},color=GOLD,alpha={{0,0},{.45,.1},{1,1}},glow=.45})
    K.sprites("ring",at+UP*.1,{flat=true,life={.55,.55},size={{0,1},{.3,5},{1,7}},color=C.cream,alpha={{0,0},{.4,.1},{1,1}},glow=.4,delay=.08})
    K.pillar(at,.9,6.5,GOLD,.8,.05)
    if lite then return end
    K.sprites("star",at+UP*3,{count=14,life={1.1,1.6},size=sizeSeq(3,SPARKLE),color=GOLD,speed={5,9},spread=80,accel=-UP*7,drag=1.5,rot={0,90},spin={-160,160},glow=1,delay=.1})
    K.sprites("star",at+UP*3,{count=6,life={1,1.4},size=sizeSeq(2.4,SPARKLE),color=C.mint,speed={4,7},spread=80,accel=-UP*6,drag=1.5,rot={0,90},spin={-160,160},glow=1,delay=.2})
end

return M
