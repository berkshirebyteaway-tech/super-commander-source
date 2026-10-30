local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local L=require(script.Parent.Localization)
local Emblem=require(script.Parent.RankEmblem)
local Cup=require(script.Parent.TrophyIcon)
local Model=require(script.Parent.Parent.Core.TrophyResult)
local Step=require(script.Parent.TelemetryStep)
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local C=K.colors
local M={played={},order={}}
local function number(n)return Theme.commas(math.floor(n+.5))end
local function depth(o,z)
    if o.ZIndex~=z then o.ZIndex=z end;for _,c in ipairs(o:GetChildren())do if c:IsA('GuiObject')then depth(c,z+1)end end
end
local function stop(t)
    if t.conn then t.conn:Disconnect();t.conn=nil end
    if t.punch then t.punch:Cancel();t.punch=nil end
end
function M.destroy(view)if view.trophyResult then stop(view.trophyResult)end end
local function emblem(t,key,parent,size,tier)
    local e=t[key]
    if not e or e:GetAttribute('Tier')~=tier or e.Size.X.Offset~=size then
        if e then e:Destroy()end;e=Emblem.create(parent,key,size,tier);t[key]=e
    end
    return e
end
local function paint(t,amount,delta,progress)
    if t.drawnAmount==amount and t.drawnDelta==delta and t.drawnProgress==progress then return end
    t.drawnAmount,t.drawnDelta,t.drawnProgress=amount,delta,progress
    t.value.Text=number(amount)
    t.delta.Text=(t.model.delta<0 and '▼'or '▲')..number(math.abs(delta))
    local old=t.model.priorProgress;local lower=math.min(old,progress);local higher=math.max(old,progress)
    t.bar:setParts({{p=lower,color=C.accent,alpha=.65},{p=higher,color=t.model.delta<0 and C.recruitmentSlow or C.accent}})
end
local function showTier(t,tier)
    t.shownTier=tier
    local e=emblem(t,'Emblem',t.emblemHost,t.emblemSize,tier)
    depth(e,t.emblemHost.ZIndex+1)
end
function M.skip(view)
    local t=view.trophyResult;if not t or not t.model or t.model.pending then return end
    stop(t);paint(t,t.model.t,t.model.delta,t.model.progress);showTier(t,t.model.tier);t.scale.Scale=1
    view.seqDone=true
end
local function build(view)
    local t={}
    t.root=K.make('Frame',view.body,{Name='TrophyResult',BackgroundTransparency=1})
    t.outcome=K.text(t.root,'Outcome','',42,C.ink,800,Enum.TextXAlignment.Center)
    t.emblemHost=K.make('Frame',t.root,{Name='League',BackgroundTransparency=1})
    t.scale=K.make('UIScale',t.emblemHost,{Scale=1})
    t.row=K.make('Frame',t.root,{Name='TrophyRow',BackgroundTransparency=1})
    t.cup=Cup.create(t.row,'Cup',26,C.gold)
    t.value=K.num(t.row,'Total','',42,C.gold)
    t.delta=K.num(t.row,'Change','',24,C.accent)
    t.bar=K.fillBar(t.root,'LeagueProgress',{fill=C.accent,track=C.raised})
    t.min=K.num(t.root,'LeagueFloor','',12,C.muted)
    t.next=K.num(t.root,'NextLeague','',12,C.muted,Enum.TextXAlignment.Right)
    t.pending=K.text(t.root,'Pending','전적 저장 중',16,C.muted,700,Enum.TextXAlignment.Center)
    view.trophyResult=t;return t
end
function M.update(view,state,v,controls)
    local t=view.trophyResult or build(view);local r=Model.view(state.personalResult.trophySolo)
    local fmt,W,H=view:format();view.fmt=fmt
    local portrait=fmt=='pt';local landscape=fmt=='ph'
    local cw=math.min(portrait and 372 or landscape and 560 or 620,W-24)
    local ch=math.min(portrait and 520 or landscape and 380 or 440,H-24)
    local cx,cy=math.floor((W-cw)/2),math.floor((H-ch)/2)
    view:paintCard(v,fmt,cw,ch,cx,cy)
    if view.card then view.card.BackgroundTransparency=0;K.round(view.card,14)end
    if view.closeObj then view.closeObj.Visible=false end
    if view.details then view.details.button.Visible=false;view.detailsText.button.Visible=false end
    for _,o in ipairs(view.body:GetChildren())do if o:IsA('GuiObject')then o.Visible=o==t.root end end
    local ay=ch-(portrait and 132 or landscape and 76 or 88)
    K.box(view.body,0,0,cw,ay);view.body.CanvasPosition=Vector2.zero;view.body.CanvasSize=UDim2.fromOffset(0,ay);view.body.ScrollBarThickness=0
    K.box(t.root,0,0,cw,ay)
    local pad=27;local inner=cw-pad*2;local eh=landscape and 62 or 84
    local sy=math.min(1,ay/(portrait and 388 or landscape and 304 or 352))
    local ty=(landscape and 20 or portrait and 28 or 30)*sy
    local ey=(landscape and 117 or portrait and 143 or 130)*sy
    local ry=(landscape and 180 or portrait and 233 or 220)*sy
    local by=(landscape and 223 or portrait and 291 or 278)*sy
    local bw=math.min(inner,360);local bx=(cw-bw)/2
    t.outcome.Text=v.title;t.outcome.TextColor3=C.ink;t.outcome.TextSize=landscape and 34 or 40
    K.box(t.outcome,0,ty,cw,54)
    t.pending.Visible=r.pending;t.row.Visible=not r.pending;t.bar.frame.Visible=not r.pending
    t.min.Visible=not r.pending;t.next.Visible=not r.pending;t.emblemHost.Visible=not r.pending
    K.box(t.pending,pad,ey+eh/2,inner,40)
    if r.pending then stop(t);t.model=r;view.seqDone=true end
    if not r.pending then
        local key=tostring(state.personalResult.id or state.version)..':'..r.before..':'..r.t..':'..r.delta
        local changed=t.key~=key
        if changed then stop(t);t.model=r;t.key=key;t.drawnProgress=nil;t.scale.Scale=1;t.shownTier=r.promoted and r.beforeTier or r.tier else t.model=r end
        K.boxCentre(t.emblemHost,(cw-eh)/2,ey,eh,eh)
        t.emblemSize=eh;showTier(t,t.shownTier or r.tier)
        local fs=landscape and 30 or 36;local ds=22
        t.value.TextSize=fs;t.delta.TextSize=ds;t.delta.TextColor3=r.delta<0 and C.recruitmentSlow or r.delta>0 and C.accent or C.muted
        local vw=math.min(inner-112,K.width(number(math.max(r.t,r.before)),fs,t.value)+4)
        local dw=math.max(42,K.width('▲'..number(math.abs(r.delta)),ds,t.delta)+4)
        local rw=26+10+vw+10+dw;K.box(t.row,(cw-rw)/2,ry,rw,fs+8)
        K.box(t.cup,0,(fs-26)/2,26,26);K.box(t.value,36,0,vw,fs+8);K.box(t.delta,46+vw,fs-ds+2,dw,ds+6)
        K.box(t.bar.frame,bx,by,bw,8)
        t.min.Text=number(r.min);t.next.Text=r.nextAt and number(r.nextAt)or 'TOP 100'
        K.box(t.min,bx+19,by+11,bw/2-19,18);K.box(t.next,bx+bw/2,by+11,bw/2-19,18)
        local a=emblem(t,'Floor',t.root,14,r.tier);local b=emblem(t,'Next',t.root,14,r.nextTier or 'legend')
        K.box(a,bx,by+13,14,14);K.box(b,bx+bw-14,by+13,14,14)
        if changed then
            local played=M.played[key]
            if not played then M.played[key]=true;table.insert(M.order,key);if #M.order>256 then M.played[table.remove(M.order,1)]=nil end end
            if not played then Step.step('queue','result',{item='r1v1',amount=r.delta,balance=r.t,result=v.won and 'won'or 'lost',version=state.version})end
            if K.reduced or require(script.Parent.ResultCelebration).reduced or played then paint(t,r.t,r.delta,r.progress);showTier(t,r.tier);view.seqDone=true
            else
                local start=os.clock();view.seqStart=start;view.seqDone=false
                paint(t,r.before,0,r.priorProgress)
                t.conn=Run.RenderStepped:Connect(function()
                    if not t.root.Parent then stop(t);return end
                    local p=math.clamp((os.clock()-start)/.6,0,1);local eased=1-(1-p)^3
                    paint(t,r.before+(r.t-r.before)*eased,r.delta*eased,r.priorProgress+(r.progress-r.priorProgress)*eased)
                    if p>=1 then stop(t);showTier(t,r.tier);view.seqDone=true
                        K.punch(t.delta,1.1,.15)
                        if r.promoted then t.scale.Scale=.85;t.punch=Tween:Create(t.scale,TweenInfo.new(.25,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1});t.punch:Play()end
                    end
                end)
            end
        elseif not t.conn then paint(t,r.t,r.delta,r.progress);showTier(t,r.tier)end
    end
    if t.Floor then t.Floor.Visible=not r.pending;t.Next.Visible=not r.pending end
    local actions=view.actions
    if actions then
        K.box(actions,0,ay,cw,ch-ay)
        for _,b in ipairs(actions:GetChildren())do if b:IsA('GuiObject')then b.Visible=b.Name=='Again'or b.Name=='ChooseMode'end end
        local again,lobby=actions:FindFirstChild('Again'),actions:FindFirstChild('ChooseMode')
        local function button(b,kind,x,y,w,h,text)
            if not b then return end;b.Visible=true
            local face=controls.adopt(b,kind);controls.place(b,x,y,w,h);controls.content(face,kind=='pri'and C.bg or C.ink,nil,nil,L.text(text),18)
        end
        if portrait then button(again,'pri',pad,0,inner,50,'한 판 더');button(lobby,'plain',pad,60,inner,48,'로비')
        else local total=math.min(inner,360);local x=(cw-total)/2
            button(again,'pri',x,8,total-128,50,'한 판 더');button(lobby,'plain',x+total-118,8,118,50,'로비')end
    end
    depth(t.root,view.body.ZIndex+1)
    v.again='한 판 더';return v
end
return M
