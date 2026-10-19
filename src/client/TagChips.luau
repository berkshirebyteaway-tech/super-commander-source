local TextService=game:GetService('TextService')
local UI=require(script.Parent.ToyUI)
local L=require(script.Parent.Localization)
local M={}
M.colors={ffa=Color3.fromRGB(59,130,246),teams=Color3.fromRGB(139,92,246),custom=UI.colors.ice,coop=UI.colors.good}
M.GAP=5;M.PAD=6;M.SIZE=12
function M.tags(f)
    local r=f.rules or {};local out={}
    if f.kind=='custom'then
        table.insert(out,{text='커스텀',color=M.colors.custom,priority=1})
        table.insert(out,r.mode=='coop'and {text='협동',color=M.colors.coop,priority=2}or {text='대전',color=M.colors.custom,priority=3})
    else
        table.insert(out,{text='공식',color=UI.colors.muted,priority=3})
        if r.special then table.insert(out,{text='특수',color=UI.colors.gold,priority=2})end
        table.insert(out,r.mode=='teams'and {text='팀전',color=M.colors.teams,priority=1}or {text='개인전',color=M.colors.ffa,priority=1})
    end
    local teams=r.mode=='teams'and tonumber(r.teamCount)
    if teams and teams>=2 then table.insert(out,{text=string.format('%d팀',teams),color=M.colors.teams,priority=4})end
    return out
end
local function width(text,h)
    return TextService:GetTextSize(text,M.SIZE,Enum.Font.BuilderSansBold,Vector2.new(1000,h)).X+M.PAD*2
end
function M.render(holder,tags,w,h)
    local keep=table.clone(tags)
    local function total()local t=0;for i,c in ipairs(keep)do c.w=c.w or width(L.text(c.text),h);t+=c.w+(i>1 and M.GAP or 0)end;return t end
    while #keep>1 and total()>w do
        local low=1;for i,c in ipairs(keep)do if c.priority>keep[low].priority then low=i end end
        table.remove(keep,low)
    end
    total()
    local x=0
    for i=1,math.max(#keep,#holder:GetChildren())do
        local chip=holder:FindFirstChild('Chip'..i);local c=keep[i]
        if c then
            if not chip then
                chip=UI.make('Frame',holder,{Name='Chip'..i,BorderSizePixel=0});UI.corner(chip,3)
                local t=UI.label(chip,'Label','',M.SIZE);t.Font=Enum.Font.BuilderSansBold;t.TextWrapped=false;t.TextXAlignment=Enum.TextXAlignment.Center;t.Size=UDim2.fromScale(1,1)
            end
            chip.Visible=true;chip.BackgroundColor3=c.color;chip.BackgroundTransparency=.8
            local t=chip.Label;t.Text=c.text;t.TextColor3=c.color:Lerp(Color3.new(1,1,1),.25)
            local cw=math.min(c.w,w-x);UI.box(chip,x,0,cw,h);x+=cw+M.GAP
        elseif chip then chip.Visible=false end
    end
    return math.max(0,x-M.GAP)
end
return M
