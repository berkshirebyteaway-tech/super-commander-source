local UI=require(script.Parent.Theme)
local M={};M.__index=M
M.INCREMENT=3;M.TICK=.1
M.DELAY=.24
M.ANIM_CAP=12;M.DUST_CAP=24;M.RING_CAP=8
M.DUST=Color3.fromRGB(214,196,160);M.DUST_FRAME=.1;M.DUST_SIZE={5,7,9};M.DUST_ALPHA={.25,.5,.75};M.DUST_RISE={0,2,4}
M.RING_TIME=.2;M.RING_FROM=12;M.RING_TO=36
function M.new(root)
    return setmetatable({root=root,anims={},count=0,dust={},dustCount=0,rings={},ringCount=0,dustPool={},ringPool={}},M)
end
function M:busy()return self.count>0 or self.dustCount>0 or self.ringCount>0 end
function M:clear()
    table.clear(self.anims);self.count=0
    for i=1,self.dustCount do self.dust[i].frame.Visible=false end;self.dustCount=0
    for i=1,self.ringCount do self.rings[i].frame.Visible=false end;self.ringCount=0
end
function M:start(r,now)
    if self.count>=M.ANIM_CAP or self.anims[r.id]then return false end
    self.anims[r.id]={tiles=r.tiles,n=#r.tiles,t0=now+M.DELAY,h=0,k=0};self.count+=1
    return true
end
local function puff(self,tile,now)
    if self.dustCount>=M.DUST_CAP then return end
    self.dustCount+=1;local d=self.dust[self.dustCount]
    if not d then
        local f=UI.make('Frame',self.root,{Name='RailDust',BorderSizePixel=0,BackgroundColor3=M.DUST,AnchorPoint=Vector2.new(.5,.5),Visible=false,ZIndex=2})
        local c=Instance.new('UICorner');c.CornerRadius=UDim.new(.5,0);c.Parent=f
        d={frame=f};self.dust[self.dustCount]=d
    end
    d.tile=tile;d.t0=now;d.f=0
end
local function ring(self,tile,color,now)
    if self.ringCount>=M.RING_CAP then return end
    self.ringCount+=1;local r=self.rings[self.ringCount]
    if not r then
        local f=UI.make('Frame',self.root,{Name='RailJoined',BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Visible=false,ZIndex=2})
        local c=Instance.new('UICorner');c.CornerRadius=UDim.new(.5,0);c.Parent=f
        local s=Instance.new('UIStroke');s.Thickness=2;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=f
        r={frame=f,stroke=s};self.rings[self.ringCount]=r
    end
    r.tile=tile;r.t0=now;r.stroke.Color=color
end
function M:advance(now,colorOf)
    if self.count==0 then return false end
    local changed=false;local inc=M.INCREMENT
    for id,a in pairs(self.anims)do
        local k=now<a.t0 and 0 or math.floor((now-a.t0)/M.TICK)+1
        if k~=a.k then
            local n,old=a.n,a.h
            local h=k>0 and n-2*inc*(k-1)<=2*inc and n or math.min(n,inc*k)
            for j=old+1,math.min(h,n-old)do if j%3==0 then puff(self,a.tiles[j],now)end end
            for j=math.max(n-h+1,h+1),n-old do if j%3==0 then puff(self,a.tiles[j],now)end end
            a.h=h;a.k=k;changed=true
            if 2*h>=n then
                self.anims[id]=nil;self.count-=1
                ring(self,a.tiles[1],colorOf(a.tiles[1]),now);ring(self,a.tiles[n],colorOf(a.tiles[n]),now)
            end
        end
    end
    return changed
end
function M:clip(s)
    local a=self.anims[s.rail];if not a then return s[1],s[2]end
    local h,n,t,i0,i1=a.h,a.n,a.tiles,s.i0,s.i1
    local ha,hb,ta,tb
    local e=math.min(i1,h);if e>i0 then ha,hb=t[i0],t[e]end
    local b=math.max(i0,n-h+1);if i1>b then ta,tb=t[b],t[i1]end
    if not ha then return ta,tb end
    return ha,hb,ta,tb
end
function M:draw(now,project)
    local i=1
    while i<=self.dustCount do
        local d=self.dust[i];local age=now-d.t0;local f=d.frame
        if age>=M.DUST_FRAME*3 then
            f.Visible=false;self.dust[i]=self.dust[self.dustCount];self.dust[self.dustCount]=d;self.dustCount-=1
        else
            local k=math.floor(age/M.DUST_FRAME)+1;local p=project(d.tile)
            if d.f~=k then d.f=k;local s=M.DUST_SIZE[k];f.Size=UDim2.fromOffset(s,s);f.BackgroundTransparency=M.DUST_ALPHA[k]end
            f.Position=UDim2.fromOffset(math.floor(p.X+.5),math.floor(p.Y+.5)-M.DUST_RISE[k]);f.Visible=true
            i+=1
        end
    end
    i=1
    while i<=self.ringCount do
        local r=self.rings[i];local t=(now-r.t0)/M.RING_TIME;local f=r.frame
        if t>=1 then
            f.Visible=false;self.rings[i]=self.rings[self.ringCount];self.rings[self.ringCount]=r;self.ringCount-=1
        else
            local p=project(r.tile);local s=math.floor(M.RING_FROM+(M.RING_TO-M.RING_FROM)*t+.5)
            f.Size=UDim2.fromOffset(s,s);f.Position=UDim2.fromOffset(math.floor(p.X+.5),math.floor(p.Y+.5));r.stroke.Transparency=t;f.Visible=true
            i+=1
        end
    end
end
return M
