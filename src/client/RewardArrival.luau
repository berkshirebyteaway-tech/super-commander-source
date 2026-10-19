local UI=require(script.Parent.Theme)
local Icons=require(script.Parent.OutgameIcons)
local M={};M.__index=M
function M.new(root,target)return setmetatable({root=root,target=target,queued={xp=0,medals=0},generation=0,entries={}},M)end
function M:cancel(requeue)
    self.generation+=1
    if requeue and self.receipt then for _,key in ipairs({'xp','medals'})do self.queued[key]+=self.receipt[key]end end
    self.receipt=nil;self.busy=false
    for _,e in ipairs(self.entries)do e.tween:Cancel();e.icon:Destroy()end;table.clear(self.entries)
    if self.pulse then self.pulse:Destroy();self.pulse=nil end
end
function M:capture(before,after)
    if not before or not after then return end
    for _,key in ipairs({'xp','medals'})do self.queued[key]+=math.max(0,(after[key]or 0)-(before[key]or 0))end
end
function M:step(visible,reduced)
    self.eligible=visible and self.root.Parent~=nil and self.target.Parent~=nil
    if not self.eligible then if self.busy then self:cancel(visible==false)end;return end
    if self.busy or self.queued.xp+self.queued.medals<=0 then return end
    local amounts=self.queued;self.queued={xp=0,medals=0};self.busy=true;self.receipt=amounts
    self.generation+=1;local generation=self.generation
    local function valid()return self.generation==generation and self.eligible and self.root.Parent and self.target.Parent end
    local finish=(self.target.AbsolutePosition+self.target.AbsoluteSize*.5-self.root.AbsolutePosition)/UI.scale
    local size=self.root.AbsoluteSize/UI.scale;local count=0
    for _,key in ipairs({'xp','medals'})do if amounts[key]>0 then
        for i=1,reduced and 1 or 4 do
            count+=1;local index=count
            task.delay((index-1)*.055,function()
                if not valid()then return end
                local icon=Icons.create(self.root,key=='medals'and 'coin'or 'xp',20,key=='medals'and UI.colors.gold or UI.colors.ice);icon.ZIndex=28
                icon.AnchorPoint=Vector2.new(.5,.5);icon.Position=UDim2.fromOffset(size.X*.5+(i-2.5)*22,size.Y*.64+(key=='xp'and -20 or 20))
                local tween=game:GetService('TweenService'):Create(icon,TweenInfo.new(reduced and .2 or .5,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromOffset(finish.X,finish.Y),ImageTransparency=.15})
                table.insert(self.entries,{icon=icon,tween=tween})
                tween.Completed:Once(function()icon:Destroy()end);tween:Play()
            end)
        end
    end end
    task.delay(.8,function()
        if not valid()then return end
        self.receipt=nil;table.clear(self.entries)
        local edge=UI.stroke(self.target,UI.colors.gold,2);edge.Name='RewardPulse';self.pulse=edge
        local t=game:GetService('TweenService'):Create(edge,TweenInfo.new(.5),{Transparency=1})
        t.Completed:Once(function()edge:Destroy();if self.generation==generation then self.pulse=nil;self.busy=false end end);t:Play()
    end)
end
return M
