local K=require(script.Parent.Kit20)
local S=require(script.Parent.Sheet20)
local Theme=require(script.Parent.Theme)
local Emblem=require(script.Parent.RankEmblem)
local Cup=require(script.Parent.TrophyIcon)
local Board=require(script.Parent.RankBoard)
local Rules=require(script.Parent.Parent.Core.RankedRules)
local L=require(script.Parent.Localization)
local FullBleed=require(script.Parent.FullBleed)
local C=K.colors
local M={};M.__index=M
local function depth(root,z)
    root.ZIndex=z;for _,o in ipairs(root:GetChildren())do if o:IsA('GuiObject')then depth(o,z+1)end end
end
function M.new(root,insets)
    local self=setmetatable({root=root,insets=insets,tab='league'},M)
    self.frame=K.make('TextButton',root,{Name='TrophyRankSheet',Text='',BackgroundColor3=S.DIM,BackgroundTransparency=.28,AutoButtonColor=false,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Visible=false,ZIndex=60})
    self.frame.Activated:Connect(function()self:show(false)end)
    self.sized=root:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()if self.frame.Visible then self:draw()end end)
    game:GetService('UserInputService').InputBegan:Connect(function(i,used)
        if not used and self.frame.Visible and i.KeyCode==Enum.KeyCode.Escape then self:show(false)end
    end)
    return self
end
function M:show(on)
    if self.open==on then return end;self.open=on
    if on then
        self.frame.Visible=true;self:draw()
        if self.sheet and not K.reduced then K.rehome(self.sheet);K.appear(self.sheet,{dx=self.pt and 0 or 24,dy=self.pt and 24 or 0,t=.18,noFade=true})end
    elseif self.sheet and not K.reduced then
        K.rehome(self.sheet);K.leave(self.sheet,{dx=self.pt and 0 or 24,dy=self.pt and 24 or 0,t=.12,noFade=true},function()if not self.open then self.frame.Visible=false end end)
    else self.frame.Visible=false end
end
function M:update(v,menu)
    self.v=v
    if menu==false then self:show(false);return end
    if not self.open then return end
    local key=game:GetService('HttpService'):JSONEncode({v and v.t,v and v.tier,v and v.wins,v and v.losses,v and v.loaded,v and v.boardLoading,v and v.board,L.getLocale()})
    if key~=self.dataKey then self.dataKey=key;self:draw()end
end
function M:draw()
    local scale=Theme.scale or 1;local W=math.floor(self.root.AbsoluteSize.X/scale);local H=math.floor(self.root.AbsoluteSize.Y/scale)
    if W<1 or H<1 then return end
    local pt=W<600;local ph=not pt and H<500;self.pt=pt
    local sw=pt and W or math.min(ph and 400 or 440,W);local sh=pt and math.floor(H*.84+.5)or H
    local x=pt and 0 or W-sw;local y=pt and H-sh or 0
    local oldScroll=self.list and self.list.CanvasPosition
    if self.sheet then self.sheet:Destroy()end
    local f=K.make('TextButton',self.frame,{Name='Sheet',Text='',AutoButtonColor=false,BackgroundColor3=S.BG,BorderSizePixel=0,Active=true})
    self.sheet=f;K.round(f,16);K.stroke(f,C.line,1,0,true);K.box(f,x,y,sw,sh);FullBleed.edge(f)
    local edge=K.make('Frame',f,{Name='AttachedEdge',BackgroundColor3=S.BG,BorderSizePixel=0})
    if pt then K.box(edge,0,sh-16,sw,16)else K.box(edge,sw-16,0,16,sh)end
    local pad=ph and 16 or 20;local hy=ph and 14 or pt and 28 or 20;local eh=ph and 52 or 72
    if pt then local grip=K.make('Frame',f,{Name='Grip',BackgroundColor3=C.line,BorderSizePixel=0});K.round(grip,'pill');K.box(grip,(sw-40)/2,12,40,4)end
    local close=K.button(f,'Close',{kind='ghost',icon='x',iconSize=18,hit=48},function()self:show(false)end);close:place(sw-pad-32,hy,32,32)
    local v=self.v or {};local tier=v.tier or 'bronze';local loaded=v.loaded and v.available
    local e=Emblem.create(f,'Emblem',eh,tier,nil);K.box(e,pad,hy,eh,eh)
    local tx=pad+eh+14;local ty=hy+(ph and 3 or 7)
    local title=K.text(f,'League',loaded and v.tierName or '전적 불러오는 중',ph and 18 or 22,C.ink,800);K.box(title,tx,ty,sw-pad-100-tx,ph and 24 or 28)
    local cs=ph and 18 or 22;local vy=ty+(ph and 25 or 30)
    local cup=Cup.create(f,'Cup',cs,C.gold);K.box(cup,tx,vy+4,cs,cs)
    local value=K.num(f,'Trophies',loaded and Theme.commas(v.t)or '',ph and 20 or 24,C.gold);K.box(value,tx+cs+7,vy,sw-pad-100-tx-cs-7,32)
    local wx=sw-pad-100
    local wins=K.text(f,'Wins',string.format('%d 승',v.wins or 0),14,C.muted,700,Enum.TextXAlignment.Right);K.box(wins,wx,hy+8,56,18)
    local losses=K.text(f,'Losses',string.format('%d 패',v.losses or 0),14,C.muted,700,Enum.TextXAlignment.Right);K.box(losses,wx,hy+26,56,18)
    local tabY=hy+eh+(ph and 9 or 13);local tabW=math.floor((sw-pad*2-8)/2)
    for i,t in ipairs({{'league','리그'},{'board','순위'}})do
        local b=K.button(f,t[1],{kind=self.tab==t[1]and 'out'or 'plain',text=t[2],size=14,hit=48},function()if self.tab~=t[1]then self.tab=t[1];self:draw()end end)
        b:place(pad+(i-1)*(tabW+8),tabY,tabW,34)
    end
    local listY=tabY+34+(ph and 8 or 12);local lw=sw-pad*2
    self.list=S.scroll(f,'Ranks',pad,listY,lw,math.max(48,sh-listY-pad));local height=0
    if self.tab=='league'then
        local tiers={{id='legend',name=Rules.legend.name,top=true}}
        for i=#Rules.trophyTiers,1,-1 do table.insert(tiers,Rules.trophyTiers[i])end
        local rh=ph and 34 or pt and 46 or 52;local gap=ph and 4 or 6;local locked=true
        for i,t in ipairs(tiers)do
            local yy=(i-1)*(rh+gap);local mine=t.id==tier;if mine then locked=false end
            local row=K.make('Frame',self.list,{Name='League_'..t.id,BackgroundColor3=mine and C.gold or C.panel,BackgroundTransparency=mine and .88 or 1,BorderSizePixel=0})
            K.round(row,6);if mine then K.stroke(row,C.gold,1,0,true)end;K.box(row,0,yy,lw,rh)
            local es=ph and 24 or 30;local emblem=Emblem.create(row,'Emblem',es,t.id,nil);K.box(emblem,10,(rh-es)/2,es,es)
            local nx=ph and 44 or 52;local name=K.text(row,'Name',t.name,ph and 14 or 16,C.ink,800);K.box(name,nx,0,lw-nx-103,rh)
            local n=K.num(row,'Threshold',t.top and 'TOP 100'or Theme.commas(mine and v.t or t.min),14,mine and C.gold or C.muted,Enum.TextXAlignment.Right);K.box(n,lw-98,0,88,rh)
            if mine then
                local icon=Cup.create(row,'Cup',13,C.gold);local nw=math.min(88,K.width(n.Text,14,n))
                K.box(icon,lw-10-nw-6-13,(rh-13)/2,13,13)
            end
            if locked then
                for _,o in ipairs(row:GetDescendants())do
                    if o:IsA('GuiObject')then o.BackgroundTransparency=1-(1-o.BackgroundTransparency)*.55 end
                    if o:IsA('TextLabel')then o.TextTransparency=.45 elseif o:IsA('ImageLabel')then o.ImageTransparency=.45 end
                end
            end
        end
        height=#tiers*(rh+gap)-gap
    else
        local heading=K.text(self.list,'Top','TOP 100',14,C.gold,800);K.box(heading,8,0,lw-16,24)
        local rows={};for _,r in ipairs(v.board or {})do local row=table.clone(r);row.valueLabel=Theme.commas(r.value or 0);table.insert(rows,row)end
        height=32+Board.draw(self.list,{x=0,y=32,w=lw},rows,{rowHeight=48,empty=v.boardLoading and '순위 불러오는 중…'or '순위 없음'})
    end
    S.canvas(self.list,height+8);if oldScroll then self.list.CanvasPosition=oldScroll end
    depth(self.frame,60)
end
return M
