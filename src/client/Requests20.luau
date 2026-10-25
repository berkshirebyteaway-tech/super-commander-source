local K=require(script.Parent.Kit20)
local X=require(script.Parent.Cards20)
local Tween=game:GetService('TweenService')
local M={}
local C=K.colors
M.groups={request={},renew={}}
local later,dismissed={},{}
local inst
local function tween(o,t,goal,style,dir)local tw=Tween:Create(o,TweenInfo.new(t,style or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),goal);tw:Play();return tw end
function M.attach(container)
    inst={container=container,views={},seen={}}
    container.BackgroundTransparency=1;container.ClipsDescendants=false
    for _,o in ipairs(container:GetChildren())do if o:IsA('GuiObject')then o.Visible=false elseif o:IsA('UIStroke')then o.Enabled=false end end
    X.watch(function(what)if inst and inst.fmt=='pt'and(what=='card'or what=='band')then M.render()end end)
    return inst
end
function M.set(group,list)M.groups[group]=list or {};M.render()end
function M.layout(w,h,obscured)if not inst then return end;inst.w,inst.h,inst.obscured=w,h,obscured==true;M.render()end

local function build(key,pc)
    local c=inst.container;local z=c.ZIndex+1
    local v={key=key,pc=pc}
    local f=K.make('Frame',c,{Name='Request20',BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0,BorderSizePixel=0,ZIndex=z,Size=UDim2.fromOffset(pc and 262 or 160,pc and 48 or 30)})
    v.frame=f
    K.round(f,pc and 10 or 'pill')
    v.stroke=K.stroke(f,pc and C.line or C.ally,1,pc and .1 or .4,true)
    X.edge(f,pc and C.ally or X.GLASS,3,X.GLASS,.94,pc and 262 or 160)
    local avatarSize=pc and 28 or 22
    v.face=K.avatar(f,'Face',nil,avatarSize);v.face.ZIndex=z+1;v.face.BackgroundColor3=C.raised
    K.box(v.face,pc and 13 or 4,pc and 10 or 4,avatarSize,avatarSize)
    v.npc=K.icon(v.face,'npc',pc and 16 or 13,C.muted,'Npc');v.npc.ZIndex=z+2
    K.box(v.npc,(avatarSize-(pc and 16 or 13))/2,(avatarSize-(pc and 16 or 13))/2,pc and 16 or 13,pc and 16 or 13)
    v.name=K.text(f,'Name','',pc and 13 or 11,C.ink,800);v.name.ZIndex=z+1
    v.hand=X.orig(f,'Alliance',pc and 12 or 13,C.ally,'Alliance');v.hand.ZIndex=z+1
    v.again=K.icon(f,'restore',pc and 12 or 13,C.ally,'Renew');v.again.ZIndex=z+1;v.again.Visible=false
    if pc then v.sub=K.text(f,'Kind','',11,C.ally,800);v.sub.ZIndex=z+1 end
    v.ring=X.ring(f,'Time',pc and 20 or 14,2,C.ally,C.line);v.ring.frame.ZIndex=z+1
    for _,d in ipairs(v.ring.frame:GetDescendants())do if d:IsA('GuiObject')then d.ZIndex=z+1 end end
    v.look=K.make('TextButton',f,{Name='Look',Text='',BackgroundTransparency=1,AutoButtonColor=false,ZIndex=z+3})
    v.look.Activated:Connect(function()local it=v.item;if it and it.inspect and not v.out then require(script.Parent.ToyAudio).play('click');it.inspect()end end)
    v.no=K.button(f,'Decline',{kind='plain',r=pc and 8 or 12,icon='x',iconSize=pc and 14 or 11,hit=pc and 36 or 40},function()M.decline(v)end)
    v.no.iconColorFixed=true;v.no.iconImage.ImageColor3=C.muted;v.no.face.BackgroundColor3=C.raised
    if not pc then v.no.faceStroke.Enabled=false end
    v.yes=K.button(f,'Accept',{kind='none',r=pc and 8 or 12,icon='check',iconSize=pc and 16 or 13,hit=pc and 44 or 40},function()M.accept(v)end)
    v.yes.iconColorFixed=true;v.yes.iconImage.ImageColor3=C.bg
    for _,b in ipairs({v.no,v.yes})do b.button.ZIndex=z+3;b.face.ZIndex=z+3;for _,d in ipairs(b.face:GetDescendants())do if d:IsA('GuiObject')then d.ZIndex=z+4 end end end
    v.yesLook=function(on,asked)
        local face=v.yes.face;face.BackgroundTransparency=asked and .94 or 0;face.BackgroundColor3=on and C.ally or C.raised
        v.yes.faceStroke.Enabled=asked==true;v.yes.faceStroke.Color=C.ally;v.yes.faceStroke.Thickness=1;v.yes.faceStroke.Transparency=.3
        v.yes.iconImage.ImageColor3=asked and C.ally or on and C.bg or C.dim
    end
    v.sweep=K.make('NumberValue',f,{Name='Sweep',Value=0})
    v.sweep.Changed:Connect(function()if v.sweep.Value>0 then X.sweep(f,C.ally,v.sweep.Value,X.GLASS,.94)end end)
    return v
end
local function paint(v,it)
    v.item=it;local pc=v.pc;local f=v.frame
    local renew=it.kind=='renew'
    v.face.Image=it.userId and it.userId>0 and('rbxthumb://type=AvatarHeadShot&id='..it.userId..'&w=150&h=150')or ''
    v.npc.Visible=v.face.Image==''
    v.name.Text=it.name or '';v.name:SetAttribute('LocalizationSkip',true)
    v.hand.Visible=not(renew and not pc);v.again.Visible=renew and not pc
    if pc then
        K.box(v.name,49,10,82,15)
        v.sub.Text=renew and '동맹 연장'or '동맹 요청'
        K.box(v.hand,49,27,12,12);K.box(v.sub,65,26,70,13)
        K.box(v.ring.frame,139,14,20,20);v.no:place(167,6,36,36);v.yes:place(211,6,44,36)
        K.box(v.look,0,0,135,48)
        v.w=262
    else
        local nw=math.min(52,X.width(v.name.Text,11,v.name));local x=32
        K.box(v.name,x,0,nw+2,30);x+=nw+6
        K.box(v.hand,x,9,13,13);K.box(v.again,x,9,13,13);x+=13+6
        K.box(v.ring.frame,x,8,14,14);x+=14+6
        v.no:place(x,3,26,24);x+=26+12
        v.yes:place(x,3,30,24);x+=30+3
        K.box(v.look,0,0,32+nw+6,30)
        v.w=x+1;f.Size=UDim2.fromOffset(v.w,30)
        if not v.out and v.sweep.Value<=0 then X.edge(f,X.GLASS,3,X.GLASS,.94,v.w)end
    end
    if not v.out then
        v.ring:set(it.ratio or 0,C.ally)
        local on=it.enabled~=false and not it.pending
        v.no:setEnabled(it.enabled~=false and not it.pending,true);v.yes:setEnabled(on and not it.asked,true)
        v.yesLook(it.enabled~=false,it.asked)
        if it.pending and v.sweep.Value<1 and not v.sweeping then v.sweeping=true;tween(v.sweep,K.reduced and 0.01 or .16,{Value=1},Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
        elseif not it.pending and v.sweep.Value>0 and not v.sweeping then v.sweep.Value=0;X.edge(f,pc and C.ally or X.GLASS,3,X.GLASS,.94,v.w)end
        if v.sweeping and v.sweep.Value>=1 then v.sweeping=false end
    end
end
local function drop(v)if inst.views[v.key]==v then inst.views[v.key]=nil end;v.frame:Destroy()end
local function fold(v)
    v.out=true;v.frame:SetAttribute('Out',true)
    if K.reduced then K.fade(v.frame,false,.12);task.delay(.12,function()drop(v)end);return end
    local s=K.make('UIScale',v.frame,{Name='Fold',Scale=1});tween(s,.12,{Scale=.9},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
    K.fade(v.frame,false,.12);task.delay(.12,function()drop(v)end)
end
function M.accept(v)
    local it=v.item;if not it or v.out or not it.accept then return end
    it.accept()
    if it.kind=='request'then v.sweeping=true;tween(v.sweep,K.reduced and .01 or .16,{Value=1}).Completed:Once(function()v.sweeping=false end)end
    M.render()
end
function M.decline(v)
    local it=v.item;if not it or v.out then return end
    if it.decline then it.decline()end
    dismissed[v.key]=true;v.out=true;v.frame:SetAttribute('Out',true)
    K.leave(v.frame,{dx=-12,t=.12},function()drop(v)end)
    M.render()
end
local function expire(v)
    v.out=true;v.frame:SetAttribute('Out',true)
    local t=K.reduced and .12 or .15
    v.ring:set(v.ring.ratio>0 and v.ring.ratio or 0,C.muted)
    tween(v.stroke,t,{Color=C.muted});X.tint(v.hand,C.muted);tween(v.yes.face,t,{BackgroundColor3=C.raised})
    if v.sub then tween(v.sub,t,{TextColor3=C.muted})end
    local g=v.frame:FindFirstChild('Edge20');if g and v.pc then X.edge(v.frame,C.muted,3,X.GLASS,.94,v.w)end
    task.delay(t,function()fold(v)end)
end

function M.render()
    if not inst then return end
    local c=inst.container;local panel=c.Parent;if not panel then return end
    local w,h=inst.w,inst.h;if not w then w,h=X.size(panel)end
    local fmt=X.fmt(w,h);inst.fmt=fmt;local pc=fmt=='pc'
    local all,alive={},{}
    for _,g in ipairs({'request','renew'})do for _,it in ipairs(M.groups[g])do alive[it.key]=true;if not dismissed[it.key]then table.insert(all,it)end end end
    for k in pairs(later)do if not alive[k]then later[k]=nil end end
    for k in pairs(dismissed)do if not alive[k]then dismissed[k]=nil end end
    local list={}
    for _,it in ipairs(all)do if not later[it.key]then table.insert(list,it)end end
    for _,it in ipairs(all)do if later[it.key]then table.insert(list,it)end end
    local cap=pc and 2 or 1;local shown=math.min(#list,cap)
    local _,clockBottom=X.clock(panel,fmt)
    local y=clockBottom+(pc and 12 or 6)
    if fmt=='pt'then y=math.max(y,X.columnBottom()+8)end
    if inst.y and inst.y~=y and c.Visible and not K.reduced then tween(c,.12,{Position=UDim2.fromOffset(12,y)})else c.Position=UDim2.fromOffset(12,y)end
    inst.y=y
    local want={}
    for i=1,shown do
        local it=list[i];want[it.key]=true
        local v=inst.views[it.key]
        if v and v.pc~=pc then v.frame:Destroy();inst.views[it.key]=nil;v=nil end
        local home=UDim2.fromOffset(0,pc and(i-1)*54 or 0)
        if not v then
            v=build(it.key,pc);inst.views[it.key]=v;paint(v,it)
            local new=not inst.seen[it.key];inst.seen[it.key]=true
            v.frame.Position=home;v.home=home
            if new then K.appear(v.frame,{dx=-16,t=.16,home=home})else K.appear(v.frame,{dy=8,t=.14,home=home})end
        else
            paint(v,it)
            if v.home~=home then v.home=home;v.frame:SetAttribute('Home20',home);if K.reduced then v.frame.Position=home else tween(v.frame,.12,{Position=home})end end
        end
    end
    for key,v in pairs(inst.views)do if not want[key]and not v.out then
        if alive[key]and not dismissed[key]then v.out=true;K.fade(v.frame,false,.10);task.delay(.10,function()drop(v)end)
        elseif v.sweep.Value>0 then if v.sweeping then local vv=v;task.delay(.17,function()fold(vv)end);v.out=true else fold(v)end
        else expire(v)end
    end end
    for k in pairs(inst.seen)do if not alive[k]then inst.seen[k]=nil end end
    local more=#list-shown
    if not inst.more then
        inst.more=K.button(c,'More20',{kind='glass',r='pill',text='',size=12,weight=800,hit=36},function()
            local first=inst.list and inst.list[1];if first then later[first.key]=true;require(script.Parent.ToyAudio).play('click');M.render()end
        end)
        inst.more.button.ZIndex=c.ZIndex+3;inst.more.face.ZIndex=c.ZIndex+3;if inst.more.label then inst.more.label.ZIndex=c.ZIndex+4 end
    end
    inst.list=list
    local m=inst.more;m.button.Visible=more>0
    local width=pc and 262 or 0;local height=pc and math.max(0,shown*54-6)or 30
    if more>0 then
        m:setText('+'..more);if m.label then m.label.TextSize=pc and 12 or 11;m.label.TextColor3=C.ally end
        local tw=X.width('+'..more,pc and 12 or 11,m.label)
        if pc then local mw=math.max(36,tw+20);m:place(0,shown*54,mw,26);height=shown*54+26
        else local first=inst.views[list[1].key];local px=(first and first.w or 160)+2;local mw=tw+16;m:place(px,3,mw,24);width=px+mw end
        if m.label then m.label.TextColor3=C.ally end
    end
    if not pc then local first=list[1]and inst.views[list[1].key];width=math.max(width,first and first.w or 0)end
    c.Size=UDim2.fromOffset(width,height)
    local leaving=false;for _,v in pairs(inst.views)do if v.out then leaving=true end end
    c.Visible=(shown>0 or leaving)and not inst.obscured
end
return M
