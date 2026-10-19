local UI=require(script.Parent.ToyUI)
local G=require(script.Parent.ToyGeometry)
local Preview=require(script.Parent.CollectionPreview)
local Art=require(script.Parent.CollectionArt)
local Catalog=require(script.Parent.Parent.Core.CosmeticCatalog)
local Finish=require(script.Parent.MapFinish)
local Pattern=require(script.Parent.TerritoryCollection)
local FactionColors=require(script.Parent.FactionColors)
local M={}
local LAND=Finish.base[128+6]or Color3.fromRGB(64,78,62);local SEA=Finish.base[32+20]or Color3.fromRGB(8,19,31)
local OURS=FactionColors.self;local THEIRS=Color3.fromRGB(150,110,255)
local EDGE=Color3.fromRGB(191,239,255)
local function reduced()return game.Players.LocalPlayer:GetAttribute('CommanderReducedEffects')==true end
local function rgb(a,f)return a and Color3.fromRGB(a[1],a[2],a[3])or f end
local W,H=168,100
local function mapOwner(x,y)
    local function blob(cx,cy,rx,ry,wob)local dx,dy=(x-cx)/rx,(y-cy)/ry;local a=math.atan2(dy,dx);return dx*dx+dy*dy<(1+wob*math.sin(a*5+cx)+wob*.6*math.cos(a*3))^2 end
    if not blob(82,50,76,45,.08)then return 'sea'end
    if blob(62,50,42,31,.1)then return 'ours'end
    if blob(134,48,28,25,.12)then return 'theirs'end
    return 'land'
end
local function paint(img,style,phase,W,H,owner)
    local spec=Pattern.spec(style,phase)
    local buf=buffer.create(W*H*4);local grid={}
    for y=0,H-1 do for x=0,W-1 do grid[y*W+x]=owner(x,y)end end
    local function at(x,y)if x<0 or y<0 or x>=W or y>=H then return 'sea'end;return grid[y*W+x]end
    for y=0,H-1 do for x=0,W-1 do
        local o=grid[y*W+x];local c
        if o=='sea'then c=SEA
        elseif o=='land'then c=LAND
        else
            local tint=o=='ours'and OURS or THEIRS
            local edge=at(x-1,y)~=o or at(x+1,y)~=o or at(x,y-1)~=o or at(x,y+1)~=o
            if edge then
                local front=(at(x-1,y)=='ours'or at(x-1,y)=='theirs')and at(x-1,y)~=o or (at(x+1,y)=='ours'or at(x+1,y)=='theirs')and at(x+1,y)~=o
                c=tint:Lerp(EDGE,front and .66 or .2)
            else
                c=LAND:Lerp(tint,o=='ours'and .56 or .5)
                if o=='ours'and spec then c=Pattern.pattern(c,y*W+x,W,spec)end
            end
        end
        local i=(y*W+x)*4
        buffer.writeu8(buf,i,math.floor(c.R*255+.5));buffer.writeu8(buf,i+1,math.floor(c.G*255+.5));buffer.writeu8(buf,i+2,math.floor(c.B*255+.5));buffer.writeu8(buf,i+3,255)
    end end
    img:WritePixelsBuffer(Vector2.zero,Vector2.new(W,H),buf)
end
local CX,CY,RX,RY=62,50,42,31
local LOOP,GROW=6.4,2.2
local function demo(frame,img,style,owner)
    local spec={};local grid,dist,edge={},{},{}
    for y=0,H-1 do for x=0,W-1 do local i=y*W+x;local o=owner(x,y);grid[i]=o
        dist[i]=math.sqrt(((x-CX)/RX)^2+((y-CY)/RY)^2)/1.25 end end
    local function at(x,y)if x<0 or y<0 or x>=W or y>=H then return 'sea'end;return grid[y*W+x]end
    for y=0,H-1 do for x=0,W-1 do local i=y*W+x
        local o=grid[i]
        if o=='ours'or o=='theirs'then
            local n={at(x-1,y),at(x+1,y),at(x,y-1),at(x,y+1)};local border,front=false,false
            for _,v in ipairs(n)do if v~=o then border=true;if v=='ours'or v=='theirs'then front=true end end end
            if border then edge[i]=(o=='ours'and OURS or THEIRS):Lerp(EDGE,front and .66 or .2)end
        end end end
    local base={}
    local function colors(phase)
        if base[phase]then return base[phase]end
        local s=Pattern.spec(style,phase);spec[phase]=s;local out={}
        for i,o in pairs(grid)do
            if o=='sea'then out[i]=SEA elseif o=='land'then out[i]=LAND
            elseif o=='theirs'then out[i]=LAND:Lerp(THEIRS,.5)
            else local c=LAND:Lerp(OURS,.56);out[i]=s and Pattern.pattern(c,i,W,s)or c end
        end
        base[phase]=out;return out
    end
    local wave=rgb(style.accent,UI.colors.gold);local tier=style.tier or 0
    local buf=buffer.create(W*H*4)
    local function draw(t)
        local loop=math.floor(t/LOOP);local u=t%LOOP;local phase=tier>=5 and loop%3+1 or 1
        local c=colors(phase);local r=math.min(1,u/GROW);r=1-(1-r)^2
        local band=u>GROW and ((u-GROW)*.42)%1.3-.15 or -9
        for i,o in pairs(grid)do
            local col=c[i]
            if o=='ours'then
                local d=dist[i]
                if d>r then col=LAND
                elseif r-d<.035 and r<1 then col=OURS:Lerp(EDGE,.66)
                elseif edge[i]then col=edge[i]
                else local k=1-math.abs(d-band)/.09;if k>0 then col=col:Lerp(wave,k*.45)end end
            elseif edge[i]then col=edge[i]end
            local p=i*4
            buffer.writeu8(buf,p,math.floor(col.R*255+.5));buffer.writeu8(buf,p+1,math.floor(col.G*255+.5));buffer.writeu8(buf,p+2,math.floor(col.B*255+.5));buffer.writeu8(buf,p+3,255)
        end
        img:WritePixelsBuffer(Vector2.zero,Vector2.new(W,H),buf)
        return r
    end
    draw(LOOP*0+GROW)
    local sparks={};local rng=Random.new(1018)
    local count=tier>=5 and 9 or tier>=4 and 5 or 0
    for i=1,count do
        local s=UI.make('ImageLabel',frame,{Name='Glint',BackgroundTransparency=1,Image='rbxasset://textures/particles/sparkles_main.dds',ImageTransparency=1,AnchorPoint=Vector2.new(.5,.5),ZIndex=3})
        sparks[i]={label=s,age=rng:NextNumber()*1.2,life=tier>=5 and 1.1 or 1.4}
    end
    local alt=rgb(style.secondary,Color3.new(1,1,1))
    local last,drawn,r=0,-1,1
    return function(t)
        if t-drawn>=.05 then r=draw(t);drawn=t end;local dt=t-last;last=t
        local size=frame.AbsoluteSize;if size.X<1 or size.Y<1 then return end;local k=math.max(size.X/W,size.Y/H);local ox,oy=(size.X-W*k)/2,(size.Y-H*k)/2
        for _,s in ipairs(sparks)do
            s.age+=dt
            if s.age>=s.life then
                s.age=0;s.at=nil
                for _=1,8 do local x,y=rng:NextInteger(0,W-1),rng:NextInteger(0,H-1);local i=y*W+x
                    if grid[i]=='ours'and dist[i]<r-.05 then s.at=Vector2.new(x+.5,y+.5);break end end
                s.color=tier>=5 and (rng:NextNumber()<.5 and wave or alt)or wave
            end
            local bloom=s.at and math.sin(s.age/s.life*math.pi)or 0
            local px=(tier>=5 and 46 or 36)*(.4+.6*bloom)
            s.label.Visible=s.at~=nil
            if s.at then
                s.label.Position=UDim2.fromScale((ox+s.at.X*k)/size.X,(oy+s.at.Y*k)/size.Y);s.label.Size=UDim2.fromOffset(px,px)
                s.label.ImageColor3=s.color:Lerp(Color3.new(1,1,1),.3*bloom);s.label.ImageTransparency=1-bloom*.95;s.label.Rotation=s.age*40
            end
        end
    end
end
local function territory(parent,item,w,h,owner)
    local full=w==nil
    w,h,owner=w or W,h or H,owner or mapOwner
    local style=Catalog.get(item.style)
    local frame=UI.make('Frame',parent,{Name='MapScene',BackgroundColor3=SEA,BorderSizePixel=0,ClipsDescendants=true})
    local label=UI.make('ImageLabel',frame,{Name='MapRaster',BackgroundTransparency=1,ResampleMode=Enum.ResamplerMode.Pixelated,ScaleType=Enum.ScaleType.Crop,Size=UDim2.fromScale(1,1)})
    local ok,img=pcall(function()return game:GetService('AssetService'):CreateEditableImage({Size=Vector2.new(w,h)})end)
    if not ok or not img then return frame end
    label.ImageContent=Content.fromObject(img)
    frame.Destroying:Once(function()pcall(function()img:Destroy()end)end)
    if full and not reduced()then
        local step=demo(frame,img,style,owner)
        task.defer(function()if frame.Parent then M.run(frame,step)end end)
        return frame
    end
    paint(img,style,1,w,h,owner)
    if (style.tier or 0)>=5 and not reduced()then
        task.spawn(function()local phase=1
            while frame.Parent do task.wait(1.6);if not frame.Parent then break end;phase=phase%3+1;paint(img,style,phase,w,h,owner)end end)
    end
    return frame
end
local function stage(parent)
    local frame=UI.make('ViewportFrame',parent,{Name='MapScene',BackgroundColor3=SEA,BackgroundTransparency=0,Ambient=Color3.fromRGB(148,162,185),LightColor=Color3.fromRGB(241,246,255),LightDirection=Vector3.new(-1,-2,-.6)})
    local world=Instance.new('WorldModel');world.Parent=frame
    G.block(world,'Sea',Vector3.new(160,.2,160),CFrame.new(0,-.35,0),SEA)
    G.block(world,'Land',Vector3.new(44,.4,30),CFrame.new(0,-.1,0),LAND)
    G.block(world,'MyTerritory',Vector3.new(26,.42,22),CFrame.new(-5,-.09,0),LAND:Lerp(OURS,.56))
    G.block(world,'Front',Vector3.new(.5,.44,22),CFrame.new(8,-.08,0),OURS:Lerp(EDGE,.66))
    G.block(world,'Neighbour',Vector3.new(13,.42,22),CFrame.new(14.75,-.09,0),LAND:Lerp(THEIRS,.5))
    local camera=Instance.new('Camera');camera.FieldOfView=36;camera.Parent=frame;frame.CurrentCamera=camera
    return frame,world,camera
end
local function fit(model,size)
    model:PivotTo(CFrame.identity);local _,s=Preview.visibleBounds(model);local big=math.max(s.X,s.Y,s.Z)
    if big>0 then pcall(function()model:ScaleTo(model:GetScale()*size/big)end)end
    model:PivotTo(CFrame.identity);local cf,b=Preview.visibleBounds(model);return CFrame.new(-cf.X,-(cf.Y-b.Y/2),-cf.Z),b
end
local function run(frame,fn)
    local clock,acc=0,0
    local c;c=game:GetService('RunService').RenderStepped:Connect(function(dt)
        if not frame.Parent then c:Disconnect();return end
        clock+=dt;acc+=dt;if acc<1/30 then return end;acc=0;fn(clock)
    end)
    frame.Destroying:Once(function()c:Disconnect()end)
end
M.run=run
local function buildings(parent,item)
    local frame,world,camera=stage(parent)
    local city=Preview.model(item,'City');city.Parent=world;local co=fit(city,9)
    local fort=Preview.model(item,'DefensePost');fort.Parent=world;local fo=fit(fort,6)
    city:PivotTo(CFrame.new(-8,.12,1)*CFrame.Angles(0,math.rad(20),0)*co);fort:PivotTo(CFrame.new(2,.12,-4)*CFrame.Angles(0,math.rad(-25),0)*fo)
    camera.CFrame=CFrame.lookAt(Vector3.new(-3,30,36),Vector3.new(-3,1,0))
    local still=reduced()
    run(frame,function(t)
        for _,m in ipairs({city,fort})do Art.step(m,t,still,1+math.floor(t/2)%3);pcall(function()require(script.Parent.BuildingRoleSkins).step(m,t,still)end)end
    end)
    return frame
end
local function nuclear(parent,item)
    local frame,world,camera=stage(parent)
    local style=Catalog.get(item.style);local color=rgb(style.accent,UI.colors.gold)
    local bomb=Preview.model(item);bomb.Parent=world;local bo=fit(bomb,3)
    local beads={};for i=1,14 do local b=G.ball(world,'Trail'..i,Vector3.one*.5,CFrame.new(0,-50,0),color);b.Material=Enum.Material.Neon;b.Transparency=1;beads[i]=b end
    local ring=G.cylinder(world,'Blast',1,.12,CFrame.new(10,0,0),color);ring.Material=Enum.Material.Neon;ring.Transparency=1
    local flash=G.ball(world,'Flash',Vector3.one,CFrame.new(10,0,0),color:Lerp(Color3.new(1,1,1),.5));flash.Material=Enum.Material.Neon;flash.Transparency=1
    camera.CFrame=CFrame.lookAt(Vector3.new(-2,36,50),Vector3.new(-1,3,0))
    local a,b=Vector3.new(-16,1,4),Vector3.new(11,.2,-2);local fly,hold=2.4,1.2;local history={}
    run(frame,function(t)
        local u=(t%(fly+hold))/fly
        if u<=1 then
            local p=a:Lerp(b,u)+Vector3.new(0,math.sin(u*math.pi)*11,0)
            local q=a:Lerp(b,math.min(1,u+.02))+Vector3.new(0,math.sin(math.min(1,u+.02)*math.pi)*11,0)
            local target=(q-p).Magnitude>1e-3 and q or p+Vector3.xAxis
            bomb:PivotTo(CFrame.lookAt(p,target)*CFrame.Angles(-math.pi/2,0,0)*bo)
            table.insert(history,1,p);if #history>14 then table.remove(history)end
            for i,bd in ipairs(beads)do local hp=history[i];if hp then bd.CFrame=CFrame.new(hp);bd.Transparency=.25+i/16;bd.Size=Vector3.one*(.55-i*.025)else bd.Transparency=1 end end
            ring.Transparency=1;flash.Transparency=1
        else
            local k=(u-1)*fly/hold
            bomb:PivotTo(CFrame.new(0,-50,0));for _,bd in ipairs(beads)do bd.Transparency=1 end;table.clear(history)
            local r=2+k*16;ring.Size=Vector3.new(.12,r,r);ring.CFrame=CFrame.new(b+Vector3.new(0,.3,0))*CFrame.Angles(0,0,math.pi/2);ring.Transparency=.15+k*.85
            local f=3+k*6;flash.Size=Vector3.one*f;flash.CFrame=CFrame.new(b+Vector3.new(0,f*.3,0));flash.Transparency=.2+k*.8
        end
        Art.step(bomb,t,reduced(),1)
    end)
    return frame
end
local function parachute(parent,item)
    local frame,world,camera=stage(parent)
    local model,extra=Preview.model(item);model.Parent=world
    if model:FindFirstChildOfClass('Humanoid')then require(script.Parent.DropAvatar).lockVisual(model)end
    camera.CFrame=CFrame.lookAt(Vector3.new(-2,22,38),Vector3.new(-4,6,0))
    local drop,rest=3.6,1.2
    run(frame,function(t)
        local u=math.min(1,(t%(drop+rest))/drop);local y=14*(1-u)^1.3+.2
        if extra and extra.rig then
            local m=extra.motion;m.time=t;m.landed=u>=1;m.inflation=u>=1 and math.max(0,1-((t%(drop+rest))-drop)/.6)or 1
            m.canopyRoll=math.sin(t*.8)*.04;extra.rig:step(CFrame.new(-5,y,0),m,true)
            Art.step(extra.rig.canopy,t,reduced(),1+math.floor(t/2)%3)
        else model:PivotTo(CFrame.new(-5,y,0))end
    end)
    return frame
end
function M.patch(parent,item)
    local f=territory(parent,item,40,40,function(x,y)return (x==0 or y==0 or x==39 or y==39)and 'theirs'or 'ours'end)
    f.Name='PatternPatch';return f
end
function M.create(parent,item)
    local cat=item and item.category
    local ok,frame=pcall(function()
        if cat=='territory'then return territory(parent,item)
        elseif cat=='buildings'then return buildings(parent,item)
        elseif cat=='nuclear'then return nuclear(parent,item)
        elseif cat=='parachute'then return parachute(parent,item)end
    end)
    if ok and frame then return frame end
    if not ok then warn('SkinMapScene',frame)end
    return Preview.create(parent,item)
end
return M
