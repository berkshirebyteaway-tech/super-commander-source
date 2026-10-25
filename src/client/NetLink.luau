local UI=require(script.Parent.Theme)
local Step=require(script.Parent.TelemetryStep)
local Run=game:GetService('RunService')
local Players=game:GetService('Players')
local C=UI.colors
local M={}
M.weakGap,M.lostGap,M.weakPing,M.okPing,M.pingHold,M.clearHold=1.4,5,.45,.3,3,2
local TEXT={weak='연결 불안정',lost='다시 연결하는 중…'}
local BARS={6,10,14,18}

function M.new(parent,remote)
    local self={lastAt=os.clock(),phase=nil,level=nil,pingSince=nil,okSince=nil,since=0,peak=0,reports=0}
    local pill=UI.make('Frame',parent,{Name='NetLink',BackgroundColor3=C.bg,BackgroundTransparency=.06,BorderSizePixel=0,Active=false,Visible=false,ZIndex=24})
    UI.corner(pill,40);local stroke=UI.stroke(pill,C.recruitmentSlow,1);stroke.Transparency=.35
    local bars={}
    for i,h in ipairs(BARS)do
        bars[i]=UI.make('Frame',pill,{Name='Bar'..i,BackgroundColor3=C.ink,BorderSizePixel=0,Active=false,ZIndex=25,Position=UDim2.fromOffset(12+(i-1)*5,8+18-h),Size=UDim2.fromOffset(3,h)})
    end
    local label=UI.label(pill,'Text','',13,C.ink);label.ZIndex=25;label.TextWrapped=false;label.Font=Enum.Font.BuilderSansBold
    label.Position=UDim2.fromOffset(38,0);label.Size=UDim2.new(1,-46,1,0)
    self.pill,self.bars,self.label,self.stroke=pill,bars,label,stroke

    local function place()
        local screen=parent.AbsoluteSize;if screen.X<=0 then return end
        local tw=game:GetService('TextService'):GetTextSize(label.Text,13,label.Font,Vector2.new(400,40)).X
        local w,h=math.ceil(tw)+52,34
        local y=math.max(72,math.floor(screen.Y*.2))
        local cd=parent:FindFirstChild('SpawnCountdown')
        if cd and cd.Visible then y=math.max(y,cd.AbsolutePosition.Y-parent.AbsolutePosition.Y+cd.AbsoluteSize.Y+8)end
        UI.box(pill,math.floor((screen.X-w)/2),y,w,h)
    end
    local function show(level,now,gap,ping)
        if level==self.level then return end
        local was=self.level;self.level=level
        if not level then
            pill.Visible=false
            Step.step('perf','netBack',{value=math.floor((now-self.since)*10+.5)/10,amount=math.floor(self.peak*10+.5)/10})
            return
        end
        if not was then self.since=now;self.peak=0 end
        label.Text=TEXT[level];stroke.Color=level=='lost'and C.muted or C.recruitmentSlow;self.lit=nil
        place();pill.Visible=true
        self.reports+=1;if self.reports<=20 then Step.step('perf',level=='lost'and'netLost'or'netWeak',{value=math.floor(gap*10+.5)/10,amount=math.floor(ping*1000)})end
    end
    remote.OnClientEvent:Connect(function(v)
        self.lastAt=os.clock()
        if type(v)=='table'and v.phase~=nil then self.phase=v.phase end
    end)
    local acc=0
    Run.Heartbeat:Connect(function(dt)
        local now=os.clock()
        if dt>.5 then self.lastAt=now;self.pingSince=nil end
        local armed=parent.Visible and(self.phase=='playing'or self.phase=='spawn')
        if not armed then self.lastAt=now;self.pingSince=nil;self.okSince=nil;if self.level then self.level=nil;pill.Visible=false end;return end
        if self.level then
            local lit=self.level=='lost'and(math.floor(now*4)%4)+1 or 1
            if lit~=self.lit then
                self.lit=lit;local color=self.level=='lost'and C.ink or C.recruitmentSlow
                for i,b in ipairs(self.bars)do b.BackgroundTransparency=i<=lit and 0 or .72;b.BackgroundColor3=i<=lit and color or C.ink end
            end
        end
        acc+=dt;if acc<.25 then return end;acc=0
        local gap=now-self.lastAt
        local ping=0;pcall(function()ping=Players.LocalPlayer:GetNetworkPing()end)
        if ping>M.weakPing then self.pingSince=self.pingSince or now else self.pingSince=nil end
        local level=gap>M.lostGap and'lost'or(gap>M.weakGap or self.pingSince and now-self.pingSince>=M.pingHold)and'weak'or nil
        if self.level then self.peak=math.max(self.peak,gap)end
        if level then self.okSince=nil;show(level,now,gap,ping)
        elseif self.level then
            if gap<.8 and ping<M.okPing then self.okSince=self.okSince or now;if now-self.okSince>=M.clearHold then self.okSince=nil;show(nil,now,gap,ping)end
            else self.okSince=nil end
        end
        if self.level then place()end
    end)
    return self
end
return M
