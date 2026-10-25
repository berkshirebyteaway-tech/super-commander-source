local K=require(script.Parent.Kit20)
local S=require(script.Parent.SkinScreen)
local Items=require(script.Parent.WardrobeItems)
local Launch=require(script.Parent.Parent.Core.LaunchCommerce)
local Tween=game:GetService('TweenService')
local C=K.colors
local M={}
local ICON={commanderStandard='campaign',vehicle='quick',commanderTrail='march',territory='fields',city='custom',projectile='target',parachute='up',commanderOrder='point',motions='dance',honors='credits'}
local PAGE=Color3.fromRGB(8,11,15)
local STAGE=Color3.fromRGB(14,22,32)
local GLOW=Color3.fromRGB(29,58,82)
local LEFT,CENTER,RIGHT=Enum.TextXAlignment.Left,Enum.TextXAlignment.Center,Enum.TextXAlignment.Right
local F={
    pc={top=78,railItem=42,railGap=4,groupGap=10,railIcon=18,px=236,stageBottom=28,gridGap=10,cols=3,cardH=172,headH=28,headFont=15,cardTop=38,right=28,
        nameFont=24,nameH=29,namePad=20,nameTop=18,chipH=22,chipFont=12,art=300,artUp=170,btnW=260,btnH=60,btnFont=21,btnBottom=20,
        cardArt=104,cardArtTop=10,cardPad=10,cardFont=13,checkS=22,checkI=13,chestS=15,lockS=11,dot=10,stateFont=15,stateH=34},
    ph={top=54,railItem=30,railGap=2,groupGap=6,railIcon=16,px=60,stageBottom=10,gridGap=6,cols=2,cardH=92,headH=20,headFont=12,cardTop=24,right=12,
        nameFont=16,nameH=19,namePad=12,nameTop=10,chipH=18,chipFont=11,art=160,artUp=90,btnW=160,btnH=44,btnFont=17,btnBottom=10,
        cardArt=56,cardArtTop=6,cardPad=6,cardFont=11,checkS=18,checkI=10,chestS=13,lockS=11,dot=8,stateFont=13,stateH=30},
    pt={cardH=92,gridGap=8,cols=3,art=120,btnW=96,btnH=44,btnFont=16,cardArt=60,checkS=16,chestS=16,lockS=11,dot=9,stateFont=13,stateH=28,nameFont=16,chipH=20,chipFont=11},
}
local function itemsKey(key)return key~='motions'and key~='honors'and key~='flag'end
local function rarityOf(e)return K.rarity[e.rarity or 'normal']or K.rarity.normal end
local function groupOf(key)for gi,g in ipairs(S.groups)do for _,c in ipairs(g[2])do if c[1]==key then return gi end end end;return nil end
local function order(key)local n=0;for _,g in ipairs(S.groups)do for _,c in ipairs(g[2])do n+=1;if c[1]==key then return n end end end;return 0 end

local function motionEntries(hub)
    local Career=require(script.Parent.Parent.Core.CareerRules);local Loadout=require(script.Parent.Parent.Core.MotionLoadout)
    local MP=require(script.Parent.MotionsPage);local club=require(script.Parent.VipLock).allows('motion')
    local level=(hub.account.progress or {}).level or 1
    local list=Loadout.copy((hub.account.preferences or {}).motionLoadout,level)
    local out={}
    for _,m in ipairs(Career.motions)do local open=level>=m.level
        table.insert(out,{id=m.id,name=m.name,motion=m,glyph=MP.icons[m.id]or 'reward',owned=open,club=club,worn=table.find(list,m.id)~=nil,level=m.level,key=open and 'motion:'..m.id or nil,loadout=list,limit=Loadout.limit})
    end
    return out
end
local function plateEntries(hub)
    local career=(hub.account.progress or {}).career;if not career then return {}end
    local pending=hub.honorPending and hub.honorPending.plate;local worn=pending or (career.equipped or {}).plate or ''
    local out={{id='',name='기본 명판',owned=true,worn=worn=='',plate=true}}
    for _,item in ipairs(career.plates or {})do local c=item.color
        table.insert(out,{id=item.id,name=item.name,owned=true,worn=worn==item.id,plate=true,color=c and Color3.fromRGB(c[1],c[2],c[3])or nil,key='plates:'..item.id})
    end
    return out
end
local function entriesFor(hub,key,shop)
    if key=='motions'then return motionEntries(hub)elseif key=='honors'then return plateEntries(hub)
    elseif key=='flag'then return S.flagEntries(hub,shop)end
    return Items.entries(hub,key,shop)
end
local PICK={flag='flagPick',motions='motionPick',honors='platePick'}
local function pickField(key)return PICK[key]or 'wardrobePick'end
local function toggleMotion(shop,e)
    local T=require(script.Parent.TelemetryStep);local list=e.loadout;local at=table.find(list,e.id);local nextList=table.clone(list)
    if at then table.remove(nextList,at)elseif #nextList<e.limit then table.insert(nextList,e.id)
    else T.step('cosmetics','motionEquip',{item=T.code(e.id),result='rejected',reason='capacity'});return false end
    T.step('cosmetics','motionEquip',{item=T.code(e.id),result=at and 'closed'or 'selected',count=#nextList})
    shop:run(function()shop:request('preference','motionLoadout',nextList)end);return true
end

local glowImage
local function glow()
    if glowImage==nil then
        local ok,img=pcall(function()
            local n=64;local e=game:GetService('AssetService'):CreateEditableImage({Size=Vector2.new(n,n)});local b=buffer.create(n*n*4)
            for y=0,n-1 do for x=0,n-1 do
                local dx,dy=(x+.5)/n*2-1,(y+.5)/n*2-1;local t=math.clamp(1-math.sqrt(dx*dx+dy*dy),0,1)
                local o=(y*n+x)*4;buffer.writeu8(b,o,255);buffer.writeu8(b,o+1,255);buffer.writeu8(b,o+2,255);buffer.writeu8(b,o+3,math.floor(t*255+.5))
            end end
            e:WritePixelsBuffer(Vector2.zero,Vector2.new(n,n),b);return e
        end)
        glowImage=ok and img or false
    end
    return glowImage
end
local function glowLayer(parent,color,cx,cy,w,h)
    local img=glow();if not img then return end
    local g=K.make('ImageLabel',parent,{Name='Glow',BackgroundTransparency=1,ImageColor3=color,ScaleType=Enum.ScaleType.Stretch,Active=false})
    g.ImageContent=Content.fromObject(img);K.box(g,cx-w/2,cy-h/2,w,h);return g
end
local function dotHost(host,cx,cy,size,rim)
    host:SetAttribute('DotBadge',true);host:SetAttribute('RedDotAt',Vector2.new(math.floor(cx+.5),math.floor(cy+.5)))
    local d=K.make('Frame',host,{Name='CollectionDot',AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(size,size),Position=UDim2.fromOffset(cx,cy),BackgroundColor3=C.danger,BorderSizePixel=0,ZIndex=40,Active=false,Visible=false})
    K.round(d,'pill');if rim then K.stroke(d,C.bg,2)end;d:SetAttribute('AllowOverlap',true);d:SetAttribute('RedDot',true)
end
local function scroller(parent,name,x,y,w,h,hub,keep,bar)
    local s=K.make('ScrollingFrame',parent,{Name=name,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=bar or 3,ScrollBarImageColor3=C.line,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,Active=true})
    K.box(s,x,y,w,h);K.scrollPad(s,4)
    hub.skinScroll=hub.skinScroll or {}
    local saved=hub.skinScroll[keep];if saved then task.defer(function()if s.Parent then s.CanvasPosition=saved end end)end
    s:GetPropertyChangedSignal('CanvasPosition'):Connect(function()hub.skinScroll[keep]=s.CanvasPosition end)
    return s
end
local function kp(t,c)return ColorSequenceKeypoint.new(t,c)end
local function art(parent,e,key,x,y,w,h,hero,dim)
    local v
    if e.flagCode then local fw=math.min(w,math.floor(h/.66));v=K.make('Frame',parent,{Name='Flag',BackgroundTransparency=1});K.box(v,x+(w-fw)/2,y+(h-fw*.66)/2,fw,fw*.66);require(script.Parent.Flags).apply(v,e.flagCode)
    elseif e.motion then local s=math.floor(math.min(w,h)*(hero and .55 or .62));v=K.icon(parent,e.glyph,s,(e.owned and e.club)and C.accent or C.muted,'Look');K.box(v,x+(w-s)/2,y+(h-s)/2,s,s)
    elseif e.plate then
        local name=game.Players.LocalPlayer.DisplayName;local col=e.color or C.muted
        local fs=hero and(w>=400 and 24 or 18)or(h>=80 and 14 or 11);local ph=math.floor(fs*2.2/2)*2;local tw=K.width(name,fs)
        local pw=math.min(w,tw+fs*2+12)
        v=K.make('Frame',parent,{Name='Plate',BackgroundColor3=col:Lerp(C.bg,.62),BorderSizePixel=0});K.round(v,8);K.stroke(v,col,hero and 2 or 1,.2,true)
        K.box(v,x+(w-pw)/2,y+(h-ph)/2,pw,ph)
        local bar=K.make('Frame',v,{Name='Signal',BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Size=UDim2.fromScale(1,1)});K.round(bar,8)
        local cut=math.clamp(4/math.max(pw,1),0,.5)
        K.make('UIGradient',bar,{Color=ColorSequence.new(col),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(cut,0),NumberSequenceKeypoint.new(math.min(.999,cut+.001),1),NumberSequenceKeypoint.new(1,1)})})
        local l=K.text(v,'Name',name,fs,C.ink,800,CENTER);K.box(l,8,0,pw-12,ph);l.AutoLocalize=false
    elseif e.id=='none'and e.preview then local s=math.min(w,h,hero and 120 or 48);v=e.preview(parent,hero);K.box(v,x+(w-s)/2,y+(h-s)/2,s,s);K.round(v,'pill')
    elseif e.preview then
        v=e.preview(parent,hero and key~='commanderStandard');K.box(v,x,y,w,h)
        if v:IsA('ViewportFrame')then
            if hero and key=='commanderOrder'then local c=require(script.Parent.CollectionPreview).contextOf(v);if c then c.zoom=.72;c.viewSize=nil end end
            if not hero and e.item and e.item.category=='motion'then S.frameOrder(v,.92)end
        end
    end
    if v and dim then
        if v:IsA('ViewportFrame')or v:IsA('ImageLabel')then v.ImageTransparency=.55 end
        for _,d in ipairs(v:GetDescendants())do if d:IsA('ImageLabel')then d.ImageTransparency=math.max(d.ImageTransparency,.55)elseif d:IsA('Frame')and d.BackgroundTransparency<1 then d.BackgroundTransparency=1-(1-d.BackgroundTransparency)*.45 end end
    end
    return v
end

local function paint(view,c,sel)
    local st=c.b.faceStroke;st.Enabled=true;st.Transparency=0;st.Thickness=sel and 2 or 1
    st.Color=sel and(view.fmt=='pt'and C.accent or C.ink)or C.line;c.b.baseStroke=st.Color
    local col=rarityOf(c.e);local band=(st.Thickness+3)/c.h
    if view.fmt=='pt'then c.g.Color=ColorSequence.new({kp(0,C.panel),kp(1-band-.001,C.panel),kp(1-band,col),kp(1,col)})
    else c.g.Color=ColorSequence.new({kp(0,col),kp(band,col),kp(band+.001,PAGE:Lerp(col,.16)),kp(.65,C.panel),kp(1,C.panel)})end
end
local function square(e,key)return key=='commanderStandard'or e.flagCode~=nil or e.motion~=nil or e.plate==true or e.id=='none'end
local function card(view,grid,e,x,y,cw,ch)
    local P=view.F;local fmt=view.fmt
    local b=K.button(grid,'Item_'..tostring(e.id),{kind='plain',r=8},function()view.pick(e)end);b:place(x,y,cw,ch)
    local f=b.face;f.BackgroundColor3=Color3.new(1,1,1);f.BackgroundTransparency=0;b.baseFill=f.BackgroundColor3;b.baseAlpha=0
    local g=K.make('UIGradient',f,{Name='Paint',Rotation=90})
    b.button:SetAttribute('Owned',e.owned==true);if e.key then b.button:SetAttribute('CollectionKey',e.key)end
    local lock=not e.owned or(e.motion~=nil and not e.club)
    local c={b=b,g=g,e=e,h=ch};view.cards[e.id]=c
    if fmt=='pt'then
        if square(e,view.key)then art(f,e,view.key,(cw-P.cardArt)/2,11,P.cardArt,P.cardArt,false,lock)else art(f,e,view.key,6,8,cw-12,ch-24,false,lock)end
    else
        local rowY=ch-1-P.cardPad-(P.cardFont+2)
        if square(e,view.key)then art(f,e,view.key,(cw-P.cardArt)/2,P.cardArtTop+1,P.cardArt,P.cardArt,false,lock)
        else art(f,e,view.key,8,P.cardArtTop+1,cw-16,rowY-P.cardArtTop-6,false,lock)end
    end
    local rightW=0;local function corner(o,w,h)
        if fmt=='pt'then K.box(o,cw-7-w,7,w,h)else K.box(o,cw-1-P.cardPad-w,ch-1-P.cardPad-h,w,h)end;rightW=w end
    if e.motion and not e.owned or (not e.motion and not e.owned and not e.supply)then
        local lc,w,h=K.lock(f,e.level and string.format('Lv.%d',e.level)or '',0,0,P.lockS);corner(lc,w,h)
    elseif e.motion and not e.club then local lc,w,h=K.lock(f,'VIP',0,0,P.lockS);corner(lc,w,h)
    elseif not e.owned and e.supply then local i=K.icon(f,'chest',P.chestS,C.muted,'Crate');corner(i,P.chestS,P.chestS)end
    if e.worn then
        if fmt=='pt'then local i=K.icon(f,'check',P.checkS,C.accent,'Worn');K.box(i,cw-7-P.checkS,7,P.checkS,P.checkS)
        else local t=K.make('Frame',f,{Name='Worn',BackgroundColor3=C.accent,BorderSizePixel=0});K.round(t,'pill');K.box(t,cw-7-P.checkS,9,P.checkS,P.checkS)
            local i=K.icon(t,'check',P.checkI,C.bg,'Check');K.box(i,(P.checkS-P.checkI)/2,(P.checkS-P.checkI)/2,P.checkI,P.checkI)end
    end
    if fmt~='pt'then
        local nh=P.cardFont+4;local n=K.text(f,'Name',e.name,P.cardFont,lock and C.muted or C.ink,700)
        K.box(n,1+P.cardPad,ch-1-P.cardPad-nh+1,cw-2-P.cardPad*2-(rightW>0 and rightW+6 or 0),nh)
    end
    local ds=P.dot;local cx=e.worn and cw-7-P.checkS-ds or cw-9;local cy=e.worn and(fmt=='pt'and 7 or 9)+P.checkS/2 or 9
    dotHost(b.button,cx,cy,ds,true)
    paint(view,c,false)
    return c
end
local function cascade(cards)
    for i,b in ipairs(cards)do if i>6 then break end
        K.appear(b,{dy=8,t=.14,delay=(i-1)*.03})
        if not K.reduced then for _,v in ipairs(b:GetDescendants())do if v:IsA('ViewportFrame')then
            local rest=v.ImageTransparency;v.ImageTransparency=1
            task.delay((i-1)*.03,function()if v.Parent then Tween:Create(v,TweenInfo.new(.14,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageTransparency=rest}):Play()end end)
        end end end
    end
end

local function stateChip(parent,text,kind,icon,P,x,y,w,h)
    local c,cw,chh=K.chip(parent,'State',text,kind,{size=P.stateFont,height=P.stateH,icon=icon,border=kind=='accent'})
    K.box(c,x+(w-cw)/2,y+(h-chh)/2,cw,chh);return c
end
local function action(view,parent,e,x,y,w,h)
    local hub,shop,P=view.hub,view.shop,view.F;local short=view.fmt~='pc'
    local function pri(text,fn)
        local b=K.button(parent,'Equip',{kind='pri',text=text,size=P.btnFont,weight=800},function(btn)fn(btn)end);b:place(x,y,w,h)
        b:setEnabled(not shop.busy);return b
    end
    if e.motion then
        if not e.owned then local lc=K.lock(parent,string.format('Lv.%d',e.level),0,0,P.stateFont-2);K.box(lc,x+(w-lc.Size.X.Offset)/2,y+(h-lc.Size.Y.Offset)/2,lc.Size.X.Offset,lc.Size.Y.Offset);return end
        if not e.club then
            local lc,cw,chh=K.lock(parent,'VIP',0,0,P.stateFont-2)
            local b=K.button(parent,'VipLock',{kind='none'},function()require(script.Parent.VipLock).open('motion',true)end);b:place(x+(w-cw)/2,y+(h-chh)/2,cw,chh)
            lc.Parent=b.face;lc.Position=UDim2.new();return
        end
        if e.worn then local b=K.button(parent,'Unequip',{kind='plain',text='해제',size=P.btnFont,weight=800},function()toggleMotion(shop,e)end);b:place(x,y,w,h);b:setEnabled(not shop.busy);return end
        local b=pri('장착',function(btn)if toggleMotion(shop,e)then K.confirm(btn,true)end end)
        if #e.loadout>=e.limit and not shop.busy then b:setEnabled(false,true);b.onRefuse=function()toggleMotion(shop,e)end end
        return
    end
    if e.worn then stateChip(parent,'장착 중','accent','check',P,x,y,w,h);return end
    if e.plate then pri('장착',function(btn)K.confirm(btn,true);require(script.Parent.CareerWardrobe).pick(hub,'plate',e.id)end);return end
    if e.owned then pri('장착',function(btn)K.confirm(btn,true);S.step('equip',{item=e.id});e.equip()end);return end
    if e.supply then
        local b=K.button(parent,'GetSupply',{kind='plain',text=short and '보급 상자 ›'or '보급 상자에서 얻기 ›',size=view.fmt=='pt'and 14 or P.btnFont-2,weight=800,icon=view.fmt~='pt'and 'chest'or nil,iconSize=P.btnFont},function()S.step('toShop',{item=e.id});hub:openPage('shop')end)
        b:place(x,y,w,h);return
    end
    local lc=K.lock(parent,e.level and string.format('Lv.%d',e.level)or '',0,0,P.stateFont-2);K.box(lc,x+(w-lc.Size.X.Offset)/2,y+(h-lc.Size.Y.Offset)/2,lc.Size.X.Offset,lc.Size.Y.Offset)
end
local function gradeChip(parent,e,P,x,y,lighten)
    if e.motion or e.plate or not e.rarity or not(e.grade or e.level or e.rarity~='normal')then return 0 end
    local col=rarityOf(e)
    local c,_,h,l=K.chip(parent,'Grade',Launch.rarityNames[e.rarity]or '','rarity',{color=col,size=P.chipFont,height=P.chipH,tint=lighten and .18 or .2})
    if lighten then l.TextColor3=col:Lerp(Color3.new(1,1,1),.35)end
    c.Position=UDim2.fromOffset(x,y);return h
end
local function look(view,content,e)
    local old=content:FindFirstChild('Look');if old then old:Destroy()end
    local P,key,w,h=view.F,view.key,view.w,view.h
    local holder=K.make('Frame',content,{Name='Look',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
    local onMap=view.fmt=='pc'and view.hub.skinMapView==true and S.mapSlots[key]==true and e.item~=nil
    if view.fmt=='pt'then
        if square(e,key)and not e.plate then art(holder,e,key,(w-P.art)/2+1,17,P.art,P.art,true,false)else art(holder,e,key,12,12,w-24,98,true,false)end
    elseif onMap then local v=require(script.Parent.SkinMapScene).create(holder,e.item);K.box(v,P.namePad+1,view.lookTop,w-P.namePad*2-2,view.lookBottom-view.lookTop);v.ZIndex=2
    elseif key=='flag'then local box=K.make('Frame',holder,{Name='Plate',BackgroundTransparency=1});K.box(box,P.namePad,view.lookTop,w-P.namePad*2,view.lookBottom-view.lookTop);S.nameplate(box,e.flagCode,view.fmt~='pc')
    elseif square(e,key)and not e.plate then art(holder,e,key,w/2-P.art/2+1,h/2-P.artUp+1,P.art,P.art,true,false)
    else art(holder,e,key,P.namePad+1,view.lookTop,w-P.namePad*2-2,view.lookBottom-view.lookTop,true,false)end
    return holder
end
local function stage(view,e,animate)
    local panel=view.panel;local old=panel:FindFirstChild('Content');if old then old:Destroy()end
    local content=K.make('Frame',panel,{Name='Content',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)})
    local P,w,h,fmt=view.F,view.w,view.h,view.fmt
    if fmt=='pt'then
        local bx,by=w-12-1-P.btnW,h-12-1-P.btnH
        local nm=K.text(content,'Name',e.name,P.nameFont,C.ink,800);K.box(nm,13,117,bx-13-8,19)
        gradeChip(content,e,P,13,139,false)
        local gl=panel:FindFirstChild('Glow');if gl then gl.ImageColor3=PAGE:Lerp(rarityOf(e),.25)end
        look(view,content,e)
        action(view,content,e,bx,by,P.btnW,P.btnH)
    else
        local nm=K.text(content,'Name',e.name,P.nameFont,C.ink,800)
        local seg=fmt=='pc'and S.mapSlots[view.key]==true
        K.box(nm,P.namePad+1,P.nameTop+1,w-P.namePad*2-2-(seg and 190 or 0),P.nameH)
        local ch=gradeChip(content,e,P,P.namePad+1,P.nameTop+1+P.nameH+4,true)
        local bx,by=(w-P.btnW)/2,h-P.btnBottom-1-P.btnH
        view.lookTop=P.nameTop+1+P.nameH+4+(ch>0 and ch or 0)+12;view.lookBottom=by-12
        if seg then
            local onMap=view.hub.skinMapView==true
            local s=K.segment(content,'PreviewMode',{{'solo','단독'},{'map','지도 위'}},onMap and 'map'or 'solo',function(id)
                view.hub.skinMapView=id=='map';S.step('previewMode',{item=id});look(view,content,e)end,{size=13})
            s:place(w-18-1-170,19,170,36);s.frame.ZIndex=5
        end
        look(view,content,e)
        action(view,content,e,bx,by,P.btnW,P.btnH)
    end
    if animate then K.fade(content,false,0);K.fade(content,true,.08)end
end
local function previewPanel(view,root,x,y,w,h,e)
    local p=K.make('Frame',root,{Name='Preview',BackgroundColor3=view.fmt=='pt'and C.panel or STAGE,BorderSizePixel=0,ClipsDescendants=true});K.round(p,10);K.box(p,x,y,w,h)
    K.stroke(p,C.line,1,0,true)
    if view.fmt=='pt'then glowLayer(p,PAGE:Lerp(rarityOf(e),.25),w*.5,h*.6,w*1.262,h*1.01)
    else glowLayer(p,GLOW,w*.5,h*.45,w*1.105,h*.995)end
    view.panel,view.w,view.h=p,w,h
    return p
end

local function rail(view,root,H,key)
    local hub,fmt,P=view.hub,view.fmt,view.F;local pc=fmt=='pc'
    local list=scroller(root,'Rail',pc and 20 or 2,P.top-4,pc and 200 or 56,H-(P.top-4),hub,'rail',pc and 2 or 0);hub.collectionRows=list
    local iw=pc and 192 or 40;local ix=pc and 0 or 4
    local on=K.make('Frame',list,{Name='RailOn',BackgroundColor3=C.raised,BorderSizePixel=0,Visible=false,Active=false});K.round(on,8)
    local bar=K.make('Frame',on,{Name='Bar',BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Size=UDim2.fromScale(1,1)});K.round(bar,8)
    local cut=3/iw;K.make('UIGradient',bar,{Color=ColorSequence.new(C.accent),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(cut-.001,0),NumberSequenceKeypoint.new(cut,1),NumberSequenceKeypoint.new(1,1)})})
    local y=0;local onY
    for _,g in ipairs(S.groups)do
        if pc then local t=K.text(list,'Group_'..g[1],g[1],12,C.dim,800);K.box(t,8,y+6,180,14);y+=28 end
        for _,c in ipairs(g[2])do
            local id=c[1];local sel=id==key
            local b=K.button(list,'Slot_'..id,{kind='none',r=8},function()if not sel then hub.skin20Dir=order(id)>order(key)and 1 or -1;S.open(hub,id)end end)
            b.minHit=0;b:place(ix,y,iw,P.railItem)
            if pc then K.box(b.button,0,y-1,iw,P.railItem+2);b.face.Position=UDim2.fromOffset(iw/2,P.railItem/2+1)
            else K.box(b.button,0,y-1,48,P.railItem+2);b.face.Position=UDim2.fromOffset(ix+iw/2,P.railItem/2+1)end
            local ic=K.icon(b.face,ICON[id]or 'wardrobe',P.railIcon,sel and C.accent or C.muted,'Icon')
            if pc then K.box(ic,12,(P.railItem-P.railIcon)/2,P.railIcon,P.railIcon)
                local t=K.text(b.face,'Name',c[2],15,sel and C.ink or C.muted,sel and 800 or 600);K.box(t,42,0,iw-42-24,P.railItem)
                dotHost(b.button,iw-16,21,8,false)
            else K.box(ic,(iw-P.railIcon)/2,(P.railItem-P.railIcon)/2,P.railIcon,P.railIcon);dotHost(b.button,ix+32,9,8,false)end
            if sel then onY=y end
            y+=P.railItem+P.railGap
        end
        y+=P.groupGap
    end
    list.CanvasSize=UDim2.fromOffset(0,y+8)
    if onY then
        on.Visible=true;on.Size=UDim2.fromOffset(iw,P.railItem)
        local goal=UDim2.fromOffset(ix,onY);local from=hub.skin20RailY
        if from and from~=onY and not K.reduced then on.Position=UDim2.fromOffset(ix,from);Tween:Create(on,TweenInfo.new(.16,Enum.EasingStyle.Cubic,Enum.EasingDirection.InOut),{Position=goal}):Play()
        else on.Position=goal end
        hub.skin20RailY=onY
    end
end

local function countLabel(view,list)
    local key=view.key
    if key=='motions'then local e=list[1];return string.format('%d / %d',e and #e.loadout or 0,e and e.limit or 6)end
    if key=='flag'then return tostring(math.max(0,#list-1))end
    if key=='honors'then return tostring(#list)end
    local owned=0;for _,e in ipairs(list)do if e.owned then owned+=1 end end;return string.format('%d / %d',owned,#list)
end
local function counter(view,root,text,right,y,h,fs,minHit)
    local hub=view.hub;local on=hub.ownedOnly==true
    if not itemsKey(view.key)then local l=K.num(root,'Count',text,fs,C.muted,RIGHT);K.box(l,right-120,y,120,h);return end
    local b=K.button(root,'OwnedFilter',{kind='none',r=4},function()S.step('ownedFilter',{value=on and 0 or 1});hub.ownedOnly=not on;hub:drawPage()end)
    local l=K.num(b.face,'Count',text,fs,on and C.accent or C.muted,LEFT);local tw=K.width(text,fs,l)
    local is=on and fs-2 or 0;local w=tw+(on and is+4+12 or 2);b.minHit=minHit or 44
    b:place(right-w,y,w,h);if on then b.face.BackgroundColor3=C.accent;b.face.BackgroundTransparency=.86;b.baseFill=C.accent;b.baseAlpha=.86
        local i=K.icon(b.face,'check',is,C.accent,'On');K.box(i,6,(h-is)/2,is,is);K.box(l,6+is+4,0,tw+2,h)else K.box(l,0,0,tw+2,h)end
end

local function build(hub,shop,key,fmt)
    local list=entriesFor(hub,key,shop)
    local only=itemsKey(key)and hub.ownedOnly==true
    local shown={};for _,e in ipairs(list)do if not only or e.owned then table.insert(shown,e)end end
    local pid=hub[pickField(key)];local cur
    for _,e in ipairs(list)do if e.id==pid then cur=e end end
    if not cur then for _,e in ipairs(list)do if e.worn then cur=e;break end end end
    cur=cur or list[1]
    return {hub=hub,shop=shop,key=key,fmt=fmt,F=F[fmt],cards={},list=list,shown=shown,cur=cur}
end
local function grid(view,root,x,y,w,h,cw,ch,cols,gap)
    local hub=view.hub
    local s=scroller(root,'Grid',x-4,y-4,w+8,h+8,hub,'grid:'..view.key);hub.collectionBody=s
    local order_={}
    for i,e in ipairs(view.shown)do local c=card(view,s,e,(i-1)%cols*(cw+gap),math.floor((i-1)/cols)*(ch+gap),cw,ch);table.insert(order_,c.b.button)end
    s.CanvasSize=UDim2.fromOffset(0,math.max(0,math.ceil(#view.shown/cols)*(ch+gap)-gap)+8)
    if view.cur and view.cards[view.cur.id]then paint(view,view.cards[view.cur.id],true)end
    s:GetPropertyChangedSignal('CanvasPosition'):Connect(function()require(script.Parent.CollectionBadges).schedule(hub)end)
    return s,order_
end
local function picker(view)
    return function(e)
        local hub=view.hub;hub[pickField(view.key)]=e.id;S.step('previewOpened',{item=e.id})
        if e.motion and e.owned then if not e.club then require(script.Parent.VipLock).open('motion',true)else require(script.Parent.MotionsPage).play(e.motion)end end
        if view.cur==e then return end
        local old=view.cur and view.cards[view.cur.id];if old then paint(view,old,false)end
        local new=view.cards[e.id];if new then paint(view,new,true)end
        view.cur=e;stage(view,e,true)
    end
end

local function drawWide(hub,root,W,H,fmt,shop,key,fresh)
    local view=build(hub,shop,key,fmt);local P=view.F;view.pick=picker(view);hub.skinView=view
    rail(view,root,H,key)
    local gw,pw,cols
    if fmt=='pc'then gw=526;pw=W-P.px-16-gw-P.right;if pw<380 then pw=380;gw=W-P.px-16-pw-P.right end;cols=3
    else local extra=math.max(0,W-667);pw=250+math.floor(extra*.4);gw=W-P.px-pw-8-P.right;cols=gw>=480 and 3 or 2 end
    local gap=P.gridGap;local cw=math.floor((gw-(cols-1)*gap)/cols);cw-=cw%2
    local gx=P.px+pw+(fmt=='pc'and 16 or 8)
    local panel=previewPanel(view,root,P.px,P.top,pw,H-P.top-P.stageBottom,view.cur or {})
    if view.cur then stage(view,view.cur,false)end
    local t=K.text(root,'GridTitle',S.names[key]or '',P.headFont,C.ink,800);K.box(t,gx,P.top,gw*.6,P.headH)
    counter(view,root,countLabel(view,view.list),gx+gw,P.top,P.headH,P.headFont,fmt=='pc'and 44 or 28)
    local gy=P.top+P.cardTop
    local _,cards=grid(view,root,gx,gy,gw,H-gy-(fmt=='pc'and P.stageBottom or 4),cw,P.cardH,cols,gap)
    if fresh then cascade(cards)end
    if fresh and hub.skin20Dir then K.appear(panel,{dy=24*hub.skin20Dir,t=.16})end
    hub.skin20Dir=nil
end
local function drawPortrait(hub,root,W,H,shop,key,fresh)
    local view=build(hub,shop,key,'pt');local P=view.F;view.pick=picker(view);hub.skinView=view
    local G=16;local cwid=W-G*2
    local panel=previewPanel(view,root,G,68,cwid,170,view.cur or {})
    if view.cur then stage(view,view.cur,false)end
    local gi=groupOf(key)or 1;local prevG=hub.skin20Group;hub.skin20Group=gi
    hub.skin20GroupKey=hub.skin20GroupKey or {};hub.skin20GroupKey[gi]=key
    local items={};for i,g in ipairs(S.groups)do items[i]={i,g[1]}end
    local seg=K.segment(root,'Groups',items,prevG or gi,function(id)
        local g=S.groups[id];local to=hub.skin20GroupKey[id]or g[2][1][1];hub.skin20Dir=id>gi and 1 or -1;S.open(hub,to)end,{size=14})
    seg:place(G,248,cwid,40);if prevG and prevG~=gi then seg:select(gi,true)end
    local status=require(script.Parent.CollectionBadges).status(hub)
    for i,g in ipairs(S.groups)do local new=false
        for _,c in ipairs(g[2])do local id=c[1];if status[(id=='honors'or id=='motions')and id or 'items:'..id]then new=true end end
        local cell=seg.cells[i];if cell then K.dot(cell.button,'Dot20',new,cell.button.Size.X.Offset-10,10,P.dot)end
    end
    local row=K.make('Frame',root,{Name='Categories',BackgroundTransparency=1});K.box(row,0,290,W,44);hub.collectionRows=row
    local x=G
    for _,c in ipairs(S.groups[gi][2])do
        local id=c[1];local sel=id==key
        local b=K.button(row,'Slot_'..id,{kind='none',r=16},function()if not sel then hub.skin20Dir=order(id)>order(key)and 1 or -1;S.open(hub,id)end end)
        local l=K.text(b.face,'Label',c[2],13,sel and C.bg or C.muted,700,CENTER);local w=K.width(c[2],13,l)+24;w+=w%2
        b:place(x,6,w,32);b.face.BackgroundColor3=sel and C.ink or C.raised;b.face.BackgroundTransparency=0;b.baseFill=b.face.BackgroundColor3;b.baseAlpha=0
        K.box(l,0,0,w,32);dotHost(b.button,w-4,10,P.dot,true)
        x+=w+6
    end
    counter(view,root,countLabel(view,view.list),W-G,296,32,13,44)
    local cols,gap=3,P.gridGap;local cw=math.floor((cwid-(cols-1)*gap)/cols);cw-=cw%2
    local slack=cwid-(cw*cols+gap*(cols-1))
    local gy=338;local _,cards=grid(view,root,G+math.floor(slack/2),gy,cwid-slack,H-66-gy,cw,P.cardH,cols,gap)
    if fresh then cascade(cards)end
    if fresh and hub.skin20Dir then K.appear(panel,{dx=24*hub.skin20Dir,t=.16})end
    hub.skin20Dir=nil
end

function M.draw(hub,body,shop)
    local had=body:FindFirstChild('Skin20')~=nil
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    if body:IsA('ScrollingFrame')then body.CanvasSize=UDim2.new();body.CanvasPosition=Vector2.zero end
    hub.collectionBody=nil;hub.collectionRows=nil
    local root,W,H,fmt=K.screenRoot(hub,body,'Skin20');if W<10 then return end
    local key=S.current(hub)
    require(script.Parent.TelemetryStep).once('skinScreen','cosmetics','skinScreen',{item=key})
    local prevKey=hub.skin20Key;hub.skin20Key=key
    if prevKey~=key then hub.motionPick=nil;hub.platePick=nil end
    local fresh=not had or prevKey~=key
    if fmt=='pt'then drawPortrait(hub,root,W,H,shop,key,fresh)else drawWide(hub,root,W,H,fmt,shop,key,fresh)end
    if not hub.skin20Resize then hub.skin20Resize=hub.root:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
        if hub.page=='wardrobe'and not hub.skin20Redraw then hub.skin20Redraw=true;task.defer(function()hub.skin20Redraw=nil;if hub.page=='wardrobe'then hub:drawPage()end end)end end)end
end
return M
