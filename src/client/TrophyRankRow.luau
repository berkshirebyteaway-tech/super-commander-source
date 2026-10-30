local K=require(script.Parent.Kit20)
local Theme=require(script.Parent.Theme)
local Entry=require(script.Parent.Parent.Core.TrophyEntry)
local Cup=require(script.Parent.TrophyIcon)
local C=K.colors
local M={};M.__index=M
function M.new(parent,callbacks)
    local self=setmetatable({callbacks=callbacks},M)
    local function go()if self.state and self.state.resume then callbacks.restore()else callbacks.find()end end
    self.press=K.button(parent,'TrophyRank',{kind='goldo',hit=48},go)
    self.press.onRefuse=function()if self.state and self.state.reason then callbacks.refuse(self.state.reason)end end
    self.frame=self.press.button
    local f=self.press.face
    self.plate=K.make('Frame',f,{Name='CupPlate',BackgroundColor3=C.gold,BackgroundTransparency=.88,BorderSizePixel=0});K.round(self.plate,6)
    self.cup=Cup.create(self.plate,'Cup',22,C.gold)
    self.lock=K.icon(self.plate,'lock',22,C.dim,'LevelLock');self.lock.Visible=false
    self.title=K.text(f,'Title','1대1 랭크',16,C.ink,800)
    self.score=K.button(f,'Trophies',{kind='none',hit=48},callbacks.inspect)
    self.mini=Cup.create(self.score.face,'Cup',13,C.gold)
    self.value=K.num(self.score.face,'Value','0',15,C.gold)
    self.waiting=K.num(f,'Waiting','',12,C.muted)
    self.dot=K.make('Frame',f,{Name='WaitingDot',BackgroundColor3=C.accent,BorderSizePixel=0});K.round(self.dot,'pill')
    self.find=K.button(f,'Find',{kind='goldo',text='찾기',size=14,hit=48},go);self.find.onRefuse=self.press.onRefuse
    self.arrow=K.text(f,'Chevron','›',22,C.gold,800,Enum.TextXAlignment.Center)
    return self
end
function M:paint(x,y,w,h,fmt,options)
    options=options or {};local v=options.trophy
    local state=Entry.state(v,options.party,options.queue,options.busy);self.state=state
    self.frame.Visible=state.visible==true;if not state.visible then return false end
    local narrow=options.split==true;local pt=fmt=='pt';local ph=fmt=='ph'
    self.press:place(x,y,w,h);self.press:setEnabled(state.enabled)
    local ink=state.reason and C.dim or C.gold;local iconSize=(ph or narrow)and 30 or 42
    K.box(self.plate,10,math.floor((h-iconSize)/2),iconSize,iconSize)
    K.box(self.cup,math.floor((iconSize-22)/2),math.floor((iconSize-22)/2),22,22)
    K.box(self.lock,math.floor((iconSize-22)/2),math.floor((iconSize-22)/2),22,22)
    self.lock.Visible=state.locked==true;self.cup.Visible=not self.lock.Visible
    self.plate.BackgroundColor3=ink;Cup.tint(self.cup,ink);Cup.tint(self.mini,ink)
    self.value.TextColor3=ink;self.arrow.TextColor3=ink
    local left=10+iconSize+10;local endPad=not narrow and (pt and 78 or 32)or 8
    K.box(self.title,left,math.floor(h/2)-23,w-left-endPad,24);self.title.TextSize=(ph or narrow)and 14 or 16
    self.title.TextColor3=state.reason and C.dim or C.ink
    local scoreY=math.min(h-48,math.max(0,math.floor(h/2)-12))
    local scoreText=Theme.commas(state.t);local scoreSize=(ph or narrow)and 13 or 15
    local scoreWidth=math.min(102,math.ceil(#scoreText*scoreSize*.65)+29,w-left-endPad+6)
    self.score:place(left-6,scoreY,scoreWidth,48)
    local valueY=math.floor(h/2)-1-scoreY
    K.box(self.mini,6,valueY+7,13,13);K.box(self.value,23,valueY,math.max(1,self.score.w-25),26)
    self.value.Text=scoreText;self.value.TextSize=scoreSize
    self.score:setEnabled(true);self.find:setEnabled(state.enabled)
    self.find.button.Visible=pt and not narrow;self.arrow.Visible=not pt and not narrow
    if self.find.button.Visible then self.find:place(w-72,math.floor((h-40)/2),62,40)end
    K.box(self.arrow,w-28,0,20,h)
    local n=options.waiting or 0;local dotX=left+scoreWidth
    local show=n>0 and dotX+35<w-endPad
    self.dot.Visible=show;self.waiting.Visible=show;self.waiting.Text=tostring(n)
    K.box(self.dot,dotX,math.floor(h/2)+9,6,6);K.box(self.waiting,dotX+10,math.floor(h/2)+1,26,22)
    self.frame:SetAttribute('AdmissionReason',state.reason);self.frame:SetAttribute('TrophySolo',true)
    local function depth(root,z)root.ZIndex=z;for _,o in ipairs(root:GetChildren())do if o:IsA('GuiObject')then depth(o,z+1)end end end
    depth(self.frame,3)
    return true
end
return M
