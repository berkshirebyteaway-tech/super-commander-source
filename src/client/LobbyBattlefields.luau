local UI=require(script.Parent.ToyUI)
local Maps=require(script.Parent.Parent.Maps.MapLoader)
local Players=game:GetService('Players')
local M={};M.__index=M
local function clock(n)local s=math.max(0,math.ceil(n or 0));return string.format('%02d:%02d',s//60,s%60)end
function M.new(lobby)return setmetatable({lobby=lobby,boards={}},M)end
function M:board(part,key,rows,big)
    local b=self.boards[key];if b and b.gui.Parent and b.gui.Adornee==part then return b end
    local gui=UI.make('SurfaceGui',Players.LocalPlayer.PlayerGui,{Name='Battlefields_'..key,Adornee=part,Face=Enum.NormalId.Back,CanvasSize=big and Vector2.new(1200,240)or Vector2.new(600,340),SizingMode=Enum.SurfaceGuiSizingMode.FixedSize,LightInfluence=0,AlwaysOnTop=false,MaxDistance=190,Active=true,ResetOnSpawn=false,ZOffset=1})
    require(script.Parent.Localization).bind(gui)
    if not big then
        local old=part:FindFirstChild('Print');if old then old.Enabled=false end
        local heading=UI.label(gui,'Heading',({single='혼자 하기',pvp='공식 전장',coop='커스텀'})[key],42,UI.colors.ink);UI.display(heading);UI.box(heading,24,10,552,64)
        local edge=UI.make('Frame',gui,{Name='TypeStrip',BackgroundColor3=key=='single'and UI.colors.accent or key=='pvp'and UI.colors.peach or UI.colors.lilac,BorderSizePixel=0});UI.box(edge,20,80,560,3)
    end
    local area=UI.make('Frame',gui,{Name='LiveFields',BackgroundColor3=UI.colors.bg,BorderSizePixel=0,Position=big and UDim2.fromOffset(922,44)or UDim2.fromOffset(20,94),Size=big and UDim2.fromOffset(270,190)or UDim2.fromOffset(560,236)})
    b={gui=gui,rows={},big=big};self.boards[key]=b
    for i=1,rows do
        local button=UI.button(area,'Field'..i,'',function()local r=b.rows[i];if r.field then self.lobby:openStation(r.mode,r.field.id)else self.lobby:openStation(r.mode or key)end end)
        local l=UI.label(button,'Summary','',big and 18 or 28);l.TextWrapped=true;l.TextXAlignment=Enum.TextXAlignment.Left
        UI.box(button,0,(i-1)*(big and 38 or 116),big and 270 or 560,big and 36 or 110);UI.box(l,12,2,big and 246 or 536,big and 32 or 106)
        b.rows[i]={button=button,label=l,mode=key}
    end
    return b
end
function M:update(directory,queue,menu)
    local world=workspace:FindFirstChild('FrontierWorld');local plaza=world and world:FindFirstChild('DeskPlaza');if not plaza then return end
    local all=directory and directory.fields or {};local official,coop={},{}
    for _,f in ipairs(all)do table.insert(f.kind=='official'and official or coop,f)end
    local sorted=table.clone(all);table.sort(sorted,function(a,b)return (a.remaining or 999)+(a.count==0 and 1000 or 0)<(b.remaining or 999)+(b.count==0 and 1000 or 0)end)
    for _,kind in ipairs({'single','pvp','coop','big'})do
        local part=plaza:FindFirstChild(kind=='big'and 'BigBoard'or 'SignNote_'..kind)
        if part then
            local b=self:board(part,kind,kind=='big'and 5 or 2,kind=='big');b.gui.Enabled=menu
            local list=kind=='pvp'and official or kind=='coop'and coop or sorted
            for i,r in ipairs(b.rows)do
                local f=list[i];r.field=kind=='single'and nil or f;r.mode=f and (f.kind=='official'and 'pvp'or f.rules.mode=='coop'and 'coop'or 'custom')or kind
                r.button.Visible=i==1 or kind~='single'and f~=nil
                if kind=='single'then r.label.Text='최근 / '..(Maps.meta(self.lobby.map)or Maps.catalog[1]).label..'\n혼자 하기';r.mode='single'
                elseif f then local meta=Maps.meta(f.rules.map);local state=f.remaining and ('출발 '..clock(f.remaining))or '모집 중'
                    r.label.Text=(meta and meta.label or f.rules.map)..' / '..(f.rules.mode=='teams'and '팀전'or f.rules.mode=='coop'and '협동'or '개인전')..'\n'..f.count..'/'..f.rules.maximum..' / '..state
                else r.label.Text='방 만들기\n함께 플레이할 규칙 선택';r.mode='create'end
                r.button:FindFirstChildOfClass('UIStroke').Color=queue and f and queue.field==f.id and UI.colors.accent or UI.colors.line
            end
        end
    end
end
return M
