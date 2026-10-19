local Terrain=require(script.Parent.LobbyHoloTerrain)
local M={}
local W,H=800,400
M.size=Vector2.new(W,H)
local SW,SH=Terrain.width,Terrain.height
local function c3(r,g,b)return {r/255,g/255,b/255}end
local sea,shallow,gridC,ice,rest=c3(12,32,50),c3(24,74,100),c3(32,70,96),c3(196,240,255),c3(70,86,104)
local powers={c3(54,226,208),c3(59,130,246),c3(139,92,246)}
M.capitals={{.173,.385,1},{.538,.462,2},{.827,.615,3}}
local function decode()
    local code={};for i=1,#Terrain.alpha do code[string.byte(Terrain.alpha,i)]=i-1 end
    local val=table.create(SW*SH,0)
    for y,row in ipairs(Terrain.rows)do
        local x=0
        for i=1,#row,2 do
            local v,n=code[string.byte(row,i)],code[string.byte(row,i+1)]+1
            for k=0,n-1 do val[(y-1)*SW+x+k+1]=v end
            x+=n
        end
    end
    return val
end
function M.paint(step)
    local val=decode()
    if step then step(-1)end
    local land,elev,glow,shade=table.create(SW*SH,0),table.create(SW*SH,0),table.create(SW*SH,0),table.create(SW*SH,0)
    for i=1,SW*SH do local v=val[i];if v>0 then land[i]=1;elev[i]=v==8 and 1 or (v-1)/6 end;if step and i%8000==0 then step(-1)end end
    local function blur(src,r)
        local tmp,out=table.create(SW*SH,0),table.create(SW*SH,0)
        for y=0,SH-1 do for x=0,SW-1 do local s,n=0,0;for d=-r,r do local xx=x+d;if xx>=0 and xx<SW then s+=src[y*SW+xx+1];n+=1 end end;tmp[y*SW+x+1]=s/n end;if step and y%8==0 then step(-1)end end
        for y=0,SH-1 do for x=0,SW-1 do local s,n=0,0;for d=-r,r do local yy=y+d;if yy>=0 and yy<SH then s+=tmp[yy*SW+x+1];n+=1 end end;out[y*SW+x+1]=s/n end;if step and y%8==0 then step(-1)end end
        return out
    end
    glow=blur(blur(land,3),3)
    if step then step(-1)end
    local soft=blur(elev,2)
    if step then step(-1)end
    local function e(xx,yy)xx=math.clamp(xx,0,SW-1);yy=math.clamp(yy,0,SH-1);return soft[yy*SW+xx+1]end
    for y=0,SH-1 do for x=0,SW-1 do
        shade[y*SW+x+1]=(e(x-1,y)-e(x+1,y))+(e(x,y-1)-e(x,y+1))
    end;if step and y%8==0 then step(-1)end end
    local function bil(f,fx,fy)
        local x0=math.floor(fx);local y0=math.floor(fy);local tx,ty=fx-x0,fy-y0
        local x1,y1=math.clamp(x0+1,0,SW-1),math.clamp(y0+1,0,SH-1);x0=math.clamp(x0,0,SW-1);y0=math.clamp(y0,0,SH-1)
        local a,b,c,d=f[y0*SW+x0+1],f[y0*SW+x1+1],f[y1*SW+x0+1],f[y1*SW+x1+1]
        return (a*(1-tx)+b*tx)*(1-ty)+(c*(1-tx)+d*tx)*ty
    end
    local out=buffer.create(W*H*4)
    local sx,sy=SW/W,SH/H
    local function smooth(a,b,t)t=math.clamp((t-a)/(b-a),0,1);return t*t*(3-2*t)end
    for py=0,H-1 do
        local v=(py+.5)/H;local fy=(py+.5)*sy-.5
        local scan=py%4==0 and .9 or 1
        for px=0,W-1 do
            local u=(px+.5)/W;local fx=(px+.5)*sx-.5
            local f=bil(land,fx,fy)
            local r,g,b
            local s=bil(glow,fx,fy)
            local k=math.min(1,s*2.2)*.85
            r,g,b=sea[1]+(shallow[1]-sea[1])*k,sea[2]+(shallow[2]-sea[2])*k,sea[3]+(shallow[3]-sea[3])*k
            if px%50==0 or py%50==0 then r,g,b=r+(gridC[1]-r)*.7,g+(gridC[2]-g)*.7,b+(gridC[3]-b)*.7 end
            local a=smooth(.4,.6,f)
            if a>0 then
                local el=bil(elev,fx,fy)
                local bend=math.sin(v*9.5)*.018
                local power=(v>.86 or el>=.99) and 0 or (u<.36+bend and 1 or u<.62-bend and 2 or 3)
                local tint=power==0 and rest or powers[power]
                local mix=power==0 and .3 or .46+el*.22
                local lr,lg,lb=sea[1]+(tint[1]-sea[1])*mix,sea[2]+(tint[2]-sea[2])*mix,sea[3]+(tint[3]-sea[3])*mix
                local sh=math.clamp(bil(shade,fx,fy)*1.1,-.25,.25)
                if sh>0 then lr,lg,lb=lr+(ice[1]-lr)*sh*.55,lg+(ice[2]-lg)*sh*.55,lb+(ice[3]-lb)*sh*.55
                else lr,lg,lb=lr*(1+sh*.8),lg*(1+sh*.8),lb*(1+sh*.8)end
                local band=bil(soft,fx,fy)*5;local d=math.abs(band-math.floor(band+.5))
                if band>.6 and band<4.85 and d<.06 then local t=(1-d/.06)*.22;lr,lg,lb=lr+(ice[1]-lr)*t,lg+(ice[2]-lg)*t,lb+(ice[3]-lb)*t end
                if power~=0 then
                    local dl=math.min(math.abs(u-(.36+bend)),math.abs(u-(.62-bend)))*W
                    if dl<1.6 then local t=(1-dl/1.6)*.8;lr,lg,lb=lr+(1-lr)*t,lg+(1-lg)*t,lb+(1-lb)*t end
                end
                r,g,b=r+(lr-r)*a,g+(lg-g)*a,b+(lb-b)*a
            end
            local c=1-math.abs(f-.5)/.16
            if c>0 then local t=c*.55;r,g,b=r+(ice[1]-r)*t,g+(ice[2]-g)*t,b+(ice[3]-b)*t end
            for _,cap in ipairs(M.capitals)do
                local dx,dy=(u-cap[1])*W,(v-cap[2])*H;local d=math.sqrt(dx*dx+dy*dy)
                local ring=math.max(0,1-math.abs(d-9)/1.3)+(d<3.2 and 1 or 0)
                if ring>0 then local t=math.min(1,ring)*.9;local col=powers[cap[3]];r,g,b=r+(col[1]-r)*t,g+(col[2]-g)*t,b+(col[3]-b)*t end
            end
            local edge=math.min(u,1-u,v,1-v)*W
            local vig=edge<24 and .82+.18*edge/24 or 1
            local m=scan*vig
            local i=(py*W+px)*4
            buffer.writeu8(out,i,math.clamp(math.floor(r*m*255+.5),0,255));buffer.writeu8(out,i+1,math.clamp(math.floor(g*m*255+.5),0,255))
            buffer.writeu8(out,i+2,math.clamp(math.floor(b*m*255+.5),0,255));buffer.writeu8(out,i+3,255)
        end
        if step then step(py)end
    end
    return out
end
function M.attach(plaza)
    local seaPart=plaza:FindFirstChild('MapSea')or plaza:WaitForChild('MapSea',15);if not seaPart then return false end
    local ok,img=pcall(function()return game:GetService('AssetService'):CreateEditableImage({Size=M.size})end)
    if not ok or not img then return false end
    local last=os.clock()
    local painted,buf=pcall(M.paint,function()if os.clock()-last>.004 then task.wait();last=os.clock()end end)
    if not painted or not plaza.Parent then img:Destroy();return false end
    img:WritePixelsBuffer(Vector2.zero,M.size,buf)
    local size=seaPart.Size
    local p=Instance.new('Part');p.Name='HoloMapSurface';p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
    p.Transparency=1;p.Size=Vector3.new(size.Z,.02,size.X);p.CFrame=(seaPart.CFrame+Vector3.new(0,size.Y/2+.03,0))*CFrame.Angles(0,-math.pi/2,0)
    local gui=Instance.new('SurfaceGui');gui.Name='HoloMap';gui.Face=Enum.NormalId.Top;gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;gui.CanvasSize=M.size;gui.LightInfluence=0;gui.MaxDistance=420;gui.Parent=p
    local label=Instance.new('ImageLabel');label.Name='Map';label.BackgroundTransparency=1;label.Size=UDim2.fromScale(1,1);label.ResampleMode=Enum.ResamplerMode.Default
    label.ImageContent=Content.fromObject(img);label.Parent=gui
    p.Parent=plaza
    local function hide(c)if c.Name=='Territory'and c:IsA('BasePart')then c.LocalTransparencyModifier=1 end end
    for _,c in ipairs(plaza:GetChildren())do hide(c)end
    plaza.ChildAdded:Connect(hide)
    plaza:SetAttribute('HoloMap','EditableImage')
    return true
end
return M
