local K=require(script.Parent.Kit20)
local C=K.colors
local M={}
local function depthZ(root,base)
    local function walk(o,z)for _,c in ipairs(o:GetChildren())do if c:IsA('GuiObject')then c.ZIndex=c.Name=='Depth'and z-1 or z;walk(c,z+1)else walk(c,z)end end end
    if root:IsA('GuiObject')then root.ZIndex=base end;walk(root,base+1)
end
local widths={}
local function width(t,s,l)local k=t..'|'..s..'|'..(l and l:GetAttribute('Num20')and 'n'or 'w');local v=widths[k];if not v then v=K.width(t,s,l);widths[k]=v end;return v end
function M.build(view,parent,callbacks)
    local bar=K.make('Frame',parent,{Name='Participation',BackgroundTransparency=1,BorderSizePixel=0,ZIndex=23,Visible=false,Active=false})
    local plate=K.make('Frame',bar,{Name='Plate',BackgroundColor3=C.panel,BackgroundTransparency=.04,BorderSizePixel=0,Active=true,Size=UDim2.fromScale(1,1)})
    K.round(plate,10);K.stroke(plate,C.line,1)
    local u={bar=bar,plate=plate}
    u.title=K.text(plate,'Title','',15,C.ink,800)
    u.fill=K.fillBar(plate,'Seats',{p=0,fill=C.accent,track=C.raised})
    u.count=K.num(plate,'Count','',13,C.muted);u.count:SetAttribute('Num20',true)
    u.clock=K.num(plate,'Clock','',24,C.accent,Enum.TextXAlignment.Right);u.clock:SetAttribute('Num20',true)
    u.state=K.text(plate,'State','',13,C.muted,800,Enum.TextXAlignment.Right)
    u.suggest=K.button(plate,'Suggested',{kind='out',text='사람 있는 전장',size=14,weight=800},function()
        if view.queue and (view.queue.room or view.queue.trophySolo)and callbacks.matchRoom then callbacks.matchRoom()elseif view.practiceAvailable and not view.suggested then view.callbacks.practice()else view:inspectSuggestion()end end)
    u.cancel=K.button(plate,'Cancel',{kind='plain',text='대기 취소',size=14,weight=800},function()callbacks.cancel()end)
    u.suggest.button.Visible=false
    view.bar=bar;view.q20=u;view.barHeight=56
    bar:GetPropertyChangedSignal('Visible'):Connect(function()
        if bar.Visible and not K.reduced then
            plate:SetAttribute('Shown20',false);plate.Position=UDim2.fromOffset(0,0);K.rehome(plate)
            K.appear(plate,{dy=16,t=.18,noFade=true})
        end
    end)
    return u
end
function M.paint(view,q,info)
    local u=view.q20;local bar=u.bar
    local sw=info.screenWidth or 1366;local fmt=sw<600 and 'pt'or (info.screenHeight or 768)<500 and 'ph'or 'pc'
    local bw=math.min(690,sw-24)
    local pc,ph,pt=fmt=='pc',fmt=='ph',fmt=='pt'
    local stacked=bw<500 and info.suggestVisible
    local H=stacked and 96 or pc and 56 or ph and 48 or 52
    local bh=ph and 34 or 40;local fs=ph and 13 or 14
    local clockText,word
    if q then
        local ranked=q.mode=='ranked'
        if ranked then
            u.title.Text=string.format('랭크 %s',q.ladder=='clanwar'and '클랜전'or q.ladder=='2v2'and '2대2'or q.ladder=='ffa'and '개인전'or '1대1')
            word=q.phase=='transferring'and '상대 찾음, 이동 중…'or '상대 찾는 중'
            if q.trophySolo then
                if q.phase=='found'then clockText=info.clock((q.remaining or 0)-(info.elapsed or 0))
                elseif q.phase=='recovering'then word='상대 다시 찾는 중'end
            end
        else
            u.title.Text=info.title or ''
            if q.phase=='transferring'then word='이동 중…'elseif q.phase=='recovering'then word='연결 확인 중…'
            elseif q.remaining then clockText=info.clock(q.remaining-(info.elapsed or 0))
            elseif q.mode=='custom'then word='준비 대기'elseif q.needsOpponent then word='상대 진영 모집 중'elseif q.room and q.room.missing then word='1명 더 모집 중'else word='곧 출발'end
        end
        u.count.Visible=not ranked;u.fill.frame.Visible=not ranked
        if not ranked then u.count.Text=string.format('%d / %d',q.count or 0,q.max or 0);u.fill:set(math.clamp((q.count or 0)/math.max(1,q.max or 1),0,1),false)end
        u.cancel:setText(q.partyCount and '파티 대기 취소'or '대기 취소');u.cancel:setEnabled(not info.busy and not q.locked)
    end
    u.clock.Visible=clockText~=nil;u.clock.Text=clockText or ''
    u.state.Text=clockText and ('출발 '..clockText)or word or ''
    u.state.TextTransparency=clockText and 1 or 0
    u.suggest.button.Visible=info.suggestVisible==true
    if info.suggestVisible then u.suggest:setText(info.suggestText);u.suggest:setEnabled(info.suggestOn)end
    local x=(sw-bw)/2;local y=(info.screenHeight or 768)-H-8
    K.box(bar,x,y,bw,H)
    local pad=ph and 12 or 16;local right=bw-(ph and 7 or 8)
    local cw=math.max(ph and 84 or 96,width(u.cancel.label.Text,fs,u.cancel.label)+28)
    local sgw=info.suggestVisible and math.max(96,width(info.suggestText or '',fs,u.suggest.label)+28)or 0
    u.cancel.label.TextSize=fs;if u.suggest.label then u.suggest.label.TextSize=fs end
    local rowH=stacked and 48 or H
    if stacked then
        local by=48;local bx=pad-4
        u.cancel:place(bw-pad+4-cw,by,cw,bh)
        u.suggest:place(bx,by,bw-pad+4-cw-8-bx,bh)
    else
        local by=math.floor((H-bh)/2)
        u.cancel:place(right-cw,by,cw,bh);right-=cw+8
        if info.suggestVisible then u.suggest:place(right-sgw,by,sgw,bh);right-=sgw end
        right-=12
    end
    if stacked then right=bw-pad end
    local cs=ph and 20 or pt and 22 or 24;u.clock.TextSize=cs
    local status=u.clock.Visible and u.clock or u.state
    local stw=u.clock.Visible and width(u.clock.Text,cs,u.clock)or width(u.state.Text,13,u.state)
    stw=math.min(stw,math.floor(bw*.32))
    K.box(status,right-stw-2,0,stw+2,rowH)
    if status==u.clock then K.box(u.state,0,0,0,0)else K.box(u.clock,0,0,0,0)end
    local leftW=math.max(40,right-stw-12-pad)
    local two=u.count.Visible
    local ty=two and math.floor(rowH/2)-(ph and 17 or 19)or 0
    u.title.TextSize=ph and 14 or 15
    K.box(u.title,pad,ty,leftW,two and (ph and 17 or 19)or rowH)
    if two then
        local by2=math.floor(rowH/2)+(ph and 3 or 5)
        local cw2=width(u.count.Text,ph and 12 or 13,u.count);u.count.TextSize=ph and 12 or 13
        local fw=math.max(24,math.min(ph and 56 or 72,leftW-cw2-8))
        K.box(u.fill.frame,pad,by2+(ph and 5 or 6),fw,4);K.box(u.count,pad+fw+8,by2,cw2+2,ph and 14 or 16)
    end
    view.barHeight=H
    depthZ(bar,info.z or 23)
    return H
end
return M
