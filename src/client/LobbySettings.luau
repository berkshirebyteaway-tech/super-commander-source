local K=require(script.Parent.Kit20)
local S=require(script.Parent.Sheet20)
local Rows=require(script.Parent.SettingsRows)
local Step=require(script.Parent.TelemetryStep)
local C=K.colors
local M={}
function M.draw(hub,body,_w)
    for _,o in ipairs(body:GetChildren())do if o:IsA('GuiObject')then o:Destroy()end end
    local root,W,H,fmt=K.screenRoot(hub,body,'Page20')
    local pt,ph=fmt=='pt',fmt=='ph'
    local shop=hub.callbacks.shop();local a=hub.account or {};local p=a.preferences or {}
    local on=a.ready==true and not shop.busy
    local function saved(r)if r and r.ok==false and shop.notify then shop.notify('설정을 저장할 수 없어요.',true)end end
    local VipLock=require(script.Parent.VipLock);local voiceOk=VipLock.allows('voice')
    local hitPos,hitSize=UDim2.fromOffset(0,ph and -2 or 0),UDim2.new(1,0,1,ph and 4 or 0)
    local function toggle(key,value,apply,locked)
        return function(row,w,h,pad)
            local sw,sh,kn,ins=pt and 46 or ph and 40 or 48,pt and 28 or ph and 22 or 26,pt and 20 or ph and 16 or 20,pt and 4 or 3
            local s=S.switch(row,'Switch',value,sw,sh,kn,ins,locked~=nil);K.box(s.frame,w-pad-sw,(h-sh)/2,sw,sh)
            if not locked and not on then s.frame.BackgroundTransparency=.5;s.knob.BackgroundTransparency=.5 end
            local hit=K.make('TextButton',row,{Name=key,Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,Position=hitPos,Size=hitSize,ZIndex=3})
            hit:SetAttribute('On',value==true);if locked then hit:SetAttribute('Locked',true)end
            hit.Activated:Connect(function()
                if locked then K.refuse(s.frame);locked(s.frame);return end
                if not on then K.refuse(s.frame,nil,true);return end
                require(script.Parent.ToyAudio).play('click');value=not value;s.set(value,true);apply(value)
            end)
        end
    end
    local function seg(key,items,value,apply,width)
        return function(row,w,h,pad)
            local sw,sh=width or (pt and 170 or ph and 180 or 240),pt and 34 or ph and 30 or 38
            local sg=S.segment(row,key,items,value,function(v)apply(v)end,{size=pt and 12 or ph and 11 or 14,guard=function()return on end})
            sg:place(w-pad-sw,(h-sh)/2,sw,sh)
        end
    end
    local function link(key,value,fn)
        return function(row,w,h,pad)
            local cs=pt and 14 or ph and 14 or 16;local fs=pt and 13 or ph and 12 or 14
            local chev=K.icon(row,'chev',cs,C.muted,'Chevron');K.box(chev,w-pad-cs,(h-cs)/2,cs,cs)
            if value and value~=''then local v=K.text(row,'Value',value,fs,C.muted,pt and 700 or 600,Enum.TextXAlignment.Right);K.box(v,w-pad-cs-(pt and 4 or 6)-160,0,160,h)end
            local hit=K.make('TextButton',row,{Name=key,Text='',BackgroundTransparency=1,AutoButtonColor=false,BorderSizePixel=0,Position=hitPos,Size=hitSize,ZIndex=3})
            hit.Activated:Connect(function()require(script.Parent.ToyAudio).play('click');fn(hit)end)
        end
    end
    local function pref(key,value)shop:run(function()saved(shop:request('preference',key,value))end)end
    local me=game.Players.LocalPlayer;local locale=me:GetAttribute('ToyfrontLocale')or 'auto'
    local LANG={auto='자동',['ko-kr']='한국어',['en-us']='English'}
    local vol=p.soundsMuted==true and 'off'or (p.sfxVolume or 1)
    local groups={
        {'화면','screen',{
            {'reducedEffects','간소한 이펙트',toggle('reducedEffects',p.reducedEffects==true,function(v)Step.step('settings','toggle',{item='reducedEffects',result=v and 'active'or 'inactive'});pref('reducedEffects',v)end)},
            {'cameraShake','화면 흔들림',toggle('cameraShake',p.cameraShake~=false,function(v)Step.step('settings','toggle',{item='cameraShake',result=v and 'active'or 'inactive'});pref('cameraShake',v)end)},
            {'mapFlashes','지도 섬광',toggle('mapFlashes',p.mapFlashes~=false,function(v)Step.step('settings','toggle',{item='mapFlashes',result=v and 'active'or 'inactive'});pref('mapFlashes',v)end)},
            {'HudOpacity','경기 패널 배경',seg('HudOpacity',{{1,'100'},{.75,'75'},{.5,'50'},{.25,'25'}},p.hudOpacity or 1,function(v)Step.step('settings','hudOpacity',{value=v*100});pref('hudOpacity',v)end)},
        }},
        {'소리','vol',{
            {'Volume','효과음',seg('Volume',{{'off','끔'},{.5,'작게'},{1,'보통'},{1.5,'크게'}},vol,function(v)
                Step.step('settings','volume',{item=v=='off'and 'off'or 'on',value=v=='off'and 0 or v*100})
                shop:run(function()if v=='off'then saved(shop:request('preference','soundsMuted',true))else saved(shop:request('preference','sfxVolume',v));require(script.Parent.ToyAudio).play('confirm')end end)end)},
            {'Music','배경음',seg('Music',{{0,'끔'},{.5,'작게'},{1,'보통'},{1.5,'크게'}},p.musicVolume or 1,function(v)Step.step('settings','musicVolume',{value=v*100});pref('musicVolume',v)end)},
            {'voiceTeamOnly','팀끼리만 음성',toggle('voiceTeamOnly',p.voiceTeamOnly~=false,function(v)Step.step('settings','toggle',{item='voiceTeamOnly',result=v and 'active'or 'inactive'});pref('voiceTeamOnly',v)end,
                not voiceOk and function(a)VipLock.open('voice',false,a)end or nil),lock=not voiceOk and 'VIP'or nil},
        }},
        {'기타','more',{
            {'Language','언어',link('Language',LANG[locale]or '자동',function(anchor)
                local items={}
                for _,v in ipairs({{'auto','자동'},{'ko-kr','한국어'},{'en-us','English'}})do
                    table.insert(items,{text=v[2],check=locale==v[1],fn=function()
                        Step.step('settings','language',{item=(v[1]:gsub('-','_'))});me:SetAttribute('ToyfrontLocale',v[1]~='auto'and v[1]or nil)
                        if a.ready==true then shop:run(function()shop:request('preference','language',v[1])end)end;hub:drawPage()end})
                end
                S.menu(hub,anchor,items,{width=180})
            end)},
            {'Help','도움말',link('Help','',function(anchor)
                S.menu(hub,anchor,{{text='조작 도움말',fn=function()hub.callbacks.help()end},
                    {text='조작 연습 다시 하기',fn=function()require(script.Parent.LobbyConfirm).open(hub,'조작 연습','튜토리얼','시작',function()hub:closePage();hub.callbacks.learn()end,'preferences')end}},{width=180})
            end)},
            {'Restore','구매 복원',link('Restore','',function()Step.step('settings','restore',{});shop:run(function()shop:request('restore')end)end)},
            {'Credits','크레딧',link('Credits','',function()hub.callbacks.credits()end)},
        }},
    }
    local top,bottom
    if pt then
        local head=S.head(root,fmt,W,'설정',function()hub:closePage()end)
        local lift=0;local d=hub.deployment;if hub.data and hub.data.queue and d and d.bar and d.bar.Visible then lift=(d.barHeight or 48)+8 end
        local _,cb=S.band(H,lift);top=head.y+head.h+8;bottom=cb
    else top=ph and 54 or 80;bottom=H-(ph and 8 or 24)end
    local cw=pt and W-32 or ph and math.floor((W-40)/2)or 620
    local x0=pt and 16 or ph and 16 or math.floor((W-cw)/2)
    local listW=ph and W-32 or cw
    local scroll=S.scroll(root,'Settings',x0,top,listW,bottom-top)
    local rows={}
    local function column(list,x)
        local y=ph and 2 or pt and 0 or 8
        for _,g in ipairs(list)do
            y=Rows.heading20(scroll,fmt,x,y,cw,g[1],g[2])
            for _,r in ipairs(g[3])do
                local row,h,pad=Rows.row20(scroll,r[1],fmt,x,y,cw,r[2],r.lock)
                r[3](row,cw,h,pad);table.insert(rows,row)
                y+=h+(pt and 0 or ph and 4 or 6)
            end
        end
        return y
    end
    local height
    if ph then height=math.max(column({groups[1],groups[3]},0),column({groups[2]},cw+8))
    else height=column(groups,0)end
    S.canvas(scroll,height)
    local first=hub.first20=='preferences';hub.first20=nil
    S.stagger(rows,first)
end
return M
