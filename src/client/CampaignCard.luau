local Players=game:GetService('Players')
local UI=require(script.Parent.ToyUI)
local Style=require(script.Parent.HudStyle)
local Step=require(script.Parent.TelemetryStep)
local Lessons=require(script.Parent.Parent.Core.CampaignLessons)
local Campaign=require(script.Parent.Parent.Core.CampaignRules)
local Art=require(script.Parent.CampaignArt)
local M={seen={}}
local C=UI.colors
local GREEN=Color3.fromRGB(95,211,138);local ORANGE=Color3.fromRGB(236,112,52)
local function v2()local ok,H=pcall(require,script.Parent.Hud20);return ok and type(H)=='table'and H.ENABLED==true end
local K
local function code(id)return 'stage_'..tostring(id):gsub('%-','_')end
local function bar(parent,name,x,y,w,h,color,alpha)
    local f=UI.make('Frame',parent,{Name=name,BackgroundColor3=color,BackgroundTransparency=alpha or 0,BorderSizePixel=0});UI.box(f,x,y,w,h);return f
end
local ART={}
function ART.growth(f,w,h)
    bar(f,'Fast',w*.25,0,w*.40,h-18,GREEN,.85);bar(f,'Stop',w*.85,0,w*.15,h-18,ORANGE,.8)
    local n=24;local peak=0;local ys={}
    for i=1,n do local x=(i-.5)/n;local y=(10+(x*100000)^.73/4)*(1-x);ys[i]=y;peak=math.max(peak,y)end
    for i=1,n do local bh=(h-24)*ys[i]/peak;local c=(i/n>=.25 and i/n<=.65)and GREEN or i/n>.85 and ORANGE or C.muted
        UI.corner(bar(f,'Col'..i,(i-1)*w/n+1,h-18-bh,w/n-2,bh,c,.05),2)end
    local a=UI.label(f,'Fast','가장 빠름',12,GREEN);UI.box(a,w*.25,h-16,w*.4,16);a.TextXAlignment=Enum.TextXAlignment.Center
    local b=UI.label(f,'Stop','멈춤',12,ORANGE);UI.box(b,w*.8,h-16,w*.2,16);b.TextXAlignment=Enum.TextXAlignment.Center
end
function ART.terrain(f,w,h)
    local items={{'평지','1배',Color3.fromRGB(46,106,74)},{'언덕','1.2배',Color3.fromRGB(109,106,60)},{'산','1.5배',Color3.fromRGB(122,93,74)}}
    local cw=(w-16)/3
    for i,it in ipairs(items)do local c=UI.corner(bar(f,'T'..i,(i-1)*(cw+8),8,cw,h-16,it[3]),8)
        local l=UI.label(c,'Name',it[1]..'\n'..it[2],15,C.ink);UI.box(l,0,0,cw,h-16);l.TextXAlignment=Enum.TextXAlignment.Center end
end
function ART.area(f,w,h)
    local s1=h*.45;local s2=h-20
    UI.corner(bar(f,'Small',w*.12,h-20-s1,s1,s1,C.accent,.35),4);UI.corner(bar(f,'Big',w*.52,0,s2,s2,C.accent,.1),4)
    local a=UI.label(f,'Arrow','→',22,C.muted);UI.box(a,w*.12+s1,h*.3,w*.52-w*.12-s1,30);a.TextXAlignment=Enum.TextXAlignment.Center
    local l=UI.label(f,'Cap','상한 ↑',13,GREEN);UI.box(l,w*.52,h-18,s2,16);l.TextXAlignment=Enum.TextXAlignment.Center
end
function M.start()
    if M.gui then return M end
    local pg=Players.LocalPlayer:WaitForChild('PlayerGui')
    local gui=UI.make('ScreenGui',pg,{Name='CampaignCard',DisplayOrder=9,ResetOnSpawn=false,IgnoreGuiInset=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Enabled=false})
    M.gui=gui
    local dim=UI.make('Frame',gui,{Name='Dim',BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=.45,BorderSizePixel=0,Size=UDim2.fromScale(1,1)})
    require(script.Parent.FullBleed).watch(gui)
    M.card=UI.panel(dim,'Card');M.card.AnchorPoint=Vector2.new(.5,.5);M.card.Position=UDim2.fromScale(.5,.5)
    M.scale=UI.make('UIScale',M.card,{})
    M.card.BackgroundColor3=Style.colors.panel;M.card.BackgroundTransparency=.02;Style.round(M.card,14)
    M.tag=UI.pill(M.card,'Tag','',C.accent);Style.round(M.tag,5)
    M.title=UI.label(M.card,'Title','',22,C.ink)
    M.art=UI.make('Frame',M.card,{Name='Art',BackgroundTransparency=1,ClipsDescendants=true})
    M.lines=UI.label(M.card,'Lines','',15,C.ink);M.lines.Font=Enum.Font.BuilderSansMedium;M.lines.TextWrapped=true;M.lines.TextYAlignment=Enum.TextYAlignment.Top
    if v2()then M.build20()else
    M.ok=UI.button(M.card,'Ok','알겠어요',function()M.close('closed')end,true);M.ok.TextSize=17;Style.round(M.ok,9)end
    local pack=script.Parent.Parent
    task.spawn(function()
        local remote=pack:WaitForChild('State',60);if not remote then return end
        remote.OnClientEvent:Connect(function(s)pcall(M.update,s)end)
    end)
    return M
end
function M.build20()
    K=require(script.Parent.Kit20);M.v2=true
    GREEN=K.colors.accent;ORANGE=C.recruitmentSlow or Color3.fromRGB(255,173,66)
    local card=M.card
    for _,s in ipairs(card:GetChildren())do if s:IsA('UIStroke')and s.Name~='Stroke20'then s.Enabled=false end end
    card.BackgroundColor3=K.colors.panel;card.BackgroundTransparency=0;K.round(card,14);K.stroke(card,K.colors.line,1,0,true)
    M.tag.Visible=false
    M.title.TextColor3=K.colors.ink;M.title.TextWrapped=false;M.title.TextTruncate=Enum.TextTruncate.AtEnd;if K.fonts[800]then M.title.FontFace=K.fonts[800]end
    M.lines.TextColor3=K.colors.ink;if K.fonts[500]then M.lines.FontFace=K.fonts[500]end;M.lines.TextTruncate=Enum.TextTruncate.AtEnd
    M.ok20=K.button(card,'Ok',{kind='pri',text='알겠어요',size=17},function()M.close('closed')end)
end
function M.layout20(W,H)
    local short=H<480;local pad=short and 16 or 20
    local w=math.min(420,W-32);local artH=M.hasArt and (short and 92 or 132)or 0
    local y=pad
    if M.tag20 then M.tag20:Destroy()end
    M.tag20=K.chip(M.card,'Tag20',M.tag.Text,'campaign',{size=12});M.tag20.Position=UDim2.fromOffset(pad,y);y+=22+10
    M.title.TextSize=20;UI.box(M.title,pad,y,w-pad*2,28);M.title.TextXAlignment=Enum.TextXAlignment.Left;y+=28+12
    M.art.Visible=M.hasArt;if M.hasArt then UI.box(M.art,pad,y,w-pad*2,artH);y+=artH+12 end
    M.lines.TextSize=15;UI.box(M.lines,pad,y,w-pad*2,44);y+=44+14
    local bh=short and 44 or 48;M.ok20:place(pad,y,w-pad*2,bh);y+=bh+pad
    M.card.Size=UDim2.fromOffset(w,y);M.gui.Enabled=true
end
function M.open20()
    local dim=M.gui.Dim;M.token=(M.token or 0)+1
    K.fade(dim,false,0)
    if not K.reduced then
        local s=M.scale.Scale;M.scale.Scale=s*.96
        game:GetService('TweenService'):Create(M.scale,TweenInfo.new(.16,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out),{Scale=s}):Play()
    end
    K.fade(dim,true,.16,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out)
end
function M.close20()
    local token=(M.token or 0)+1;M.token=token
    K.fade(M.gui.Dim,false,.10)
    task.delay(K.reduced and .12 or .10,function()if M.token==token then M.gui.Enabled=false end end)
end
function M.layout()
    local gui=M.gui;local cam=workspace.CurrentCamera;local v=cam and cam.ViewportSize or Vector2.new(800,600)
    local ui=Players.LocalPlayer.PlayerGui:FindFirstChild('FrontierNativeUI');local s=ui and ui:GetAttribute('UIScale');s=type(s)=='number'and s>0 and s or 1
    M.scale.Scale=s;local W,H=v.X/s,v.Y/s
    if M.v2 then M.layout20(W,H);return W,H end
    local short=H<480
    local w=math.min(420,W-32);local artH=M.hasArt and (short and 92 or 132)or 0
    local y=16;UI.box(M.tag,16,y,120,22);M.tag.Size=UDim2.fromOffset(M.tag.TextBounds.X+16,22);y+=28
    UI.box(M.title,16,y,w-32,30);M.title.TextXAlignment=Enum.TextXAlignment.Left;y+=36
    M.art.Visible=M.hasArt;if M.hasArt then UI.box(M.art,16,y,w-32,artH);y+=artH+10 end
    UI.box(M.lines,16,y,w-32,48);y+=54
    UI.box(M.ok,16,y,w-32,48);y+=48+16
    M.card.Size=UDim2.fromOffset(w,y);gui.Enabled=true
    return W,H
end
function M.show(stageId,lesson)
    M.stage=stageId;M.shownAt=os.clock();M.seen[stageId]=true
    M.tag.Text=string.format('%s 배울 것',stageId);M.title.Text=lesson.title;M.lines.Text=table.concat(lesson.lines,'\n')
    for _,c in ipairs(M.art:GetChildren())do c:Destroy()end
    local draw=ART[lesson.art]or Art.has(lesson.art)and function(f,w,h)Art.draw(lesson.art,f,w,h,lesson)end or nil;M.hasArt=draw~=nil
    M.layout();if draw then pcall(draw,M.art,M.art.AbsoluteSize.X/M.scale.Scale,M.art.AbsoluteSize.Y/M.scale.Scale)end
    if M.v2 then M.open20()end
    Step.step('campaign','lessonCard',{item=code(stageId),result='shown'})
end
function M.close(result)
    if not M.stage then return end
    Step.step('campaign','lessonCard',{item=code(M.stage),result=result,duration_ms=(os.clock()-M.shownAt)*1000})
    M.stage=nil
    if M.v2 then M.close20()else M.gui.Enabled=false end
end
function M.update(s)
    if type(s)~='table'then return end
    local id=s.loading and s.loadingCampaign or nil
    if id and not M.stage and not M.seen[id]and Campaign.stage(id)then local l=Lessons.of(id);if l and l.lines then M.show(id,l)end end
    if M.stage and (s.phase=='playing'or s.phase=='menu'and not s.loading and os.clock()-M.shownAt>3)then M.close(s.phase=='playing'and 'skipped'or 'cancelled')end
end
return M
