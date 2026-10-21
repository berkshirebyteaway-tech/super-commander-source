local Players=game:GetService('Players')
local UI=require(script.Parent.ToyUI)
local Honor=require(script.Parent.CommanderHonor)
local Badge=require(script.Parent.BenefitBadge)
local Emblem=require(script.Parent.RankEmblem)
local L=require(script.Parent.Localization)
local Step=require(script.Parent.TelemetryStep)
local M={}
local C=UI.colors
local LADDERS={{'1v1','랭크 1대1'},{'2v2','랭크 2대2'}}
local function skip(o)o:SetAttribute('LocalizationSkip',true);o.AutoLocalize=false;return o end
local function text(parent,name,value,x,y,w,h,size,color)
    local l=UI.label(parent,name,value,size,color);UI.box(l,x,y,w,h);l.TextXAlignment=Enum.TextXAlignment.Left;l.TextWrapped=false;l.TextTruncate=Enum.TextTruncate.AtEnd;return l
end
function M.fetch(lobby,userId)
    local s=lobby.commanderProfile;if not s or s.userId~=userId then return end
    s.loading=true;s.error=nil
    task.spawn(function()
        local ok,r=pcall(function()return script.Parent.Parent:WaitForChild('AccountRequest'):InvokeServer('profile',userId)end)
        if lobby.commanderProfile~=s then return end
        s.loading=false
        if ok and type(r)=='table'and r.ok and type(r.profile)=='table'then s.data=r.profile;Step.step('social','commanderProfile',{result='loaded'})
        else s.error=ok and type(r)=='table'and r.message or '연결이 끊겼어요. 다시 시도하세요.';Step.step('social','commanderProfile',{result='failed',reason=ok and 'refused'or 'network'})end
        if lobby.page=='commander'then lobby:drawPage()end
    end)
end
function M.open(lobby,player,source)
    if not player or player==Players.LocalPlayer then return end
    lobby.commanderProfile={userId=player.UserId,player=player,hub={recordOther=true,drawPage=function()lobby:drawPage()end}}
    Step.step('social','commanderProfile',{result='opened',item=source})
    local from=lobby.page;lobby:openPage('commander');if from and from~='commander'then lobby.backTo=from end
    M.fetch(lobby,player.UserId)
end
local function header(lobby,body,w,s,y)
    local p=s.player;local here=p and p.Parent==Players
    local h=here and Honor.of(p)or nil;local d=s.data
    local card=UI.panel(body,'ProfileHead');UI.box(card,0,y,w,104);card.BackgroundColor3=C.raised
    local plate=h and h.plate
    require(script.Parent.EdgeMask).fit(UI.make('Frame',card,{Name='Strip',BackgroundColor3=plate and Honor.edge(plate)or C.accent,BorderSizePixel=0,Size=UDim2.new(1,0,0,3)}))
    local avatar=UI.make('ImageLabel',card,{Name='Avatar',BackgroundColor3=C.bg,BorderSizePixel=0,Image='rbxthumb://type=AvatarHeadShot&id='..s.userId..'&w=150&h=150'})
    UI.corner(avatar,3);UI.box(avatar,14,18,72,72)
    local clan=here and p:GetAttribute('CommanderClan');clan=type(clan)=='string'and clan~=''and clan or nil
    local name=p and p.DisplayName or '지휘관'
    local tw=w-100-14
    local badge=Badge.create(card,18);Badge.update(badge,here and p:GetAttribute('CommanderPermanent')==true,here and p:GetAttribute('CommanderVIP')==true)
    local bw=Badge.width(badge);badge.root.Position=UDim2.fromOffset(w-14-bw,19)
    local n=skip(text(card,'Name',clan and string.format('[%s] %s',clan,name)or name,100,14,bw>0 and tw-bw-8 or tw,26,20,C.ink));UI.display(n)
    skip(text(card,'Handle',p and '@'..p.Name or '',100,40,tw,18,12,C.muted))
    local level=h and h.level or d and d.level or 1
    local rank=h and h.rank or d and L.text(d.title or '')or ''
    local worn=h and h.title~=''and h.title~=h.rank and h.title or nil
    skip(text(card,'Rank',worn and string.format('Lv. %d  %s  %s',level,rank,worn)or string.format('Lv. %d  %s',level,rank),100,60,tw,20,14,C.gold))
    local mine=Players.LocalPlayer:GetAttribute('CommanderClan')
    text(card,'Unit',clan and (clan==mine and '같은 클랜'or '클랜 소속')or '클랜 없음',100,80,tw,18,12,clan and clan==mine and C.accent or C.muted)
    return y+116
end
local function ranked(body,w,d,y)
    local list={};for _,l in ipairs(LADDERS)do local v=d.ranked and d.ranked[l[1]];if v and (v.games or 0)>0 then table.insert(list,{l,v})end end
    if #list==0 then return y end
    local cols=w<420 and 1 or 2;local cw=(w-(cols-1)*8)/cols;local ch=72
    for i,e in ipairs(list)do
        local l,v=e[1],e[2];local tier=v.placing and 'unranked'or v.tier
        local card=UI.panel(body,'Ladder'..l[1]);UI.box(card,(i-1)%cols*(cw+8),y+math.floor((i-1)/cols)*(ch+8),cw,ch)
        UI.box(Emblem.create(card,'Emblem',52,tier,not v.placing and v.division or nil),10,10,52,52)
        text(card,'Mode',l[2],72,8,cw-84,18,12,C.muted)
        local label=v.placing and L.text('배치 중')or (v.division and L.text(v.tierName)..' '..v.division or L.text(v.tierName or ''))
        local t=skip(text(card,'Tier',label,72,26,cw-84,24,18,v.placing and C.muted or Emblem.color(tier)));UI.display(t)
        local record=string.format(L.text('%d승 %d패'),v.wins or 0,math.max(0,(v.games or 0)-(v.wins or 0)))
        skip(text(card,'Record',v.placing and record or UI.commas(v.rp)..' RP  '..record,72,50,cw-84,16,12,C.muted))
    end
    return y+math.ceil(#list/cols)*(ch+8)+8
end
function M.draw(lobby,body,w)
    local s=lobby.commanderProfile;if not s then lobby:closePage();return end
    lobby.pageTitle.Text='지휘관 프로필'
    local y=header(lobby,body,w,s,0)
    local d=s.data
    if not d then
        local msg=text(body,'Status',s.error or '전적 불러오는 중',2,y+8,w-4,40,15,s.error and C.muted or C.ice);msg.TextXAlignment=Enum.TextXAlignment.Center;msg.TextWrapped=true
        y+=56
        if s.error then
            local again=UI.button(body,'Retry','다시 시도',function()if not s.loading then M.fetch(lobby,s.userId);lobby:drawPage()end end,true);UI.box(again,math.floor((w-180)/2),y,180,48);y+=60
        end
        body.CanvasSize=UDim2.fromOffset(0,y+8);return
    end
    y=ranked(body,w,d,y)
    y=require(script.Parent.RecordsView).draw(s.hub,body,w,y,{records=d.records,history=d.history})
    body.CanvasSize=UDim2.fromOffset(0,y+8)
end
return M
