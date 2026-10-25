local Run=game:GetService('RunService')
local UI=require(script.Parent.ToyUI)
local M={AFTER=40}
function M.attach(cover,opts)
    if typeof(cover)=='Instance'and cover.Parent then
        local band=UI.make('Frame',cover.Parent,{Name='LoadingInset',Position=UDim2.fromOffset(0,-200),Size=UDim2.new(1,0,0,200),BackgroundColor3=cover.BackgroundColor3,BorderSizePixel=0,ZIndex=cover.ZIndex,Visible=cover.Visible})
        cover:GetPropertyChangedSignal('Visible'):Connect(function()band.Visible=cover.Visible end)
    end
    local row=UI.make('Frame',cover,{Name='StuckActions',AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,.5,52),Size=UDim2.fromOffset(328,48),BackgroundTransparency=1,ZIndex=37,Visible=false})
    local since
    local retry=UI.button(row,'StuckRetry','다시 시도',function()since=os.clock();row.Visible=false;opts.retry()end,true)
    local leave=UI.button(row,'StuckLobby','로비로 나가기',function()since=os.clock();row.Visible=false;opts.lobby()end)
    for i,b in ipairs({retry,leave})do b.Size=UDim2.fromOffset(160,48);b.Position=UDim2.fromOffset((i-1)*168,0);b.ZIndex=38;b.TextSize=15 end
    Run.Heartbeat:Connect(function()
        local stuck=cover.Visible and opts.inMatch()
        if not stuck then since=nil;row.Visible=false return end
        since=since or os.clock()
        row.Visible=os.clock()-since>M.AFTER
    end)
    return row
end
return M
