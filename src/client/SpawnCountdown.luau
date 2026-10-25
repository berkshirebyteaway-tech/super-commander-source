local UI=require(script.Parent.Theme)
local Audio=require(script.Parent.ToyAudio)
local TweenService=game:GetService("TweenService")
local C=UI.colors
local M={};M.__index=M
function M.new(parent)
    local self=setmetatable({deadline=0,shown=nil,seen=nil},M)
    local f=UI.panel(parent,'SpawnCountdown');f.ZIndex=20;f.Visible=false;f.BackgroundColor3=C.bg;f.BackgroundTransparency=.06;self.frame=f
    UI.stroke(f,C.accent,1)
    local chip=UI.make('Frame',f,{Name='Chip',BackgroundColor3=C.accent,BackgroundTransparency=.82,BorderSizePixel=0,ZIndex=21});UI.corner(chip,3);UI.stroke(chip,C.accent,2);self.chip=chip
    local n=UI.label(chip,'Number','5',44,C.accent);n.ZIndex=22;n.Size=UDim2.fromScale(1,1);n.TextXAlignment=Enum.TextXAlignment.Center;n:SetAttribute('LocalizationSkip',true);UI.display(n,true);self.number=n
    self.pop=UI.make('UIScale',n,{Scale=1})
    local title=UI.label(f,'Title','곧 시작',20,C.ink);title.ZIndex=21;title.Font=Enum.Font.BuilderSansBold;title.TextWrapped=false;self.title=title
    local sub=UI.label(f,'Sub','',13,C.muted);sub.ZIndex=21;self.sub=sub
    return self
end
function M:update(state,screen)
    local show=state~=nil and state.phase=='spawn' and not(state.drop and state.drop.active)and state.allSpawned==true and not state.observer
    if not show then if self.frame.Visible then self.frame.Visible=false end;self.shown=nil;self.seen=nil;return end
    if state~=self.seen then
        self.seen=state;local deadline=os.clock()+(state.spawnLeft or 0)
        if self.shown==nil or math.abs(deadline-self.deadline)>.25 then self.deadline=deadline end
    end
    local left=math.max(0,self.deadline-os.clock());local n=math.ceil(left)
    if n<=0 then self.frame.Visible=false;return end
    local ok20,H20=pcall(require,script.Parent.Hud20)
    if ok20 and H20.ENABLED then
        self.shown=n
        require(script.Parent.LandingCard20).card(self.frame,{seconds=n,title='곧 시작'},screen.X,screen.Y,{self.chip,self.title,self.sub})
        if not self.frame.Visible then self.frame.Visible=true end
        return
    end
    local w=math.min(440,screen.X-24);local h=92
    UI.box(self.frame,(screen.X-w)/2,math.max(64,screen.Y*.14),w,h)
    UI.box(self.chip,12,12,68,68)
    UI.box(self.title,94,32,w-106,28);UI.box(self.sub,94,42,w-106,38)
    if n~=self.shown then
        self.shown=n;self.number.Text=tostring(n)
        self.number.TextColor3=n<=2 and C.gold or C.accent
        self.pop.Scale=1.35;TweenService:Create(self.pop,TweenInfo.new(.28,Enum.EasingStyle.Back),{Scale=1}):Play()
        Audio.play(self.frame.Visible and 'click' or 'confirm')
    end
    if not self.frame.Visible then self.frame.Visible=true end
end
return M
