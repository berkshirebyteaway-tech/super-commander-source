local UI=require(script.Parent.ToyUI)
local Theme=require(script.Parent.Theme)
local M={ttl=60}
function M.show(lobby,r)
    local Step=require(script.Parent.TelemetryStep)
    if lobby.inviteCard and lobby.inviteCard.Parent then lobby.inviteCard:Destroy();Step.step('social','inviteToast',{result='closed',reason='replaced'})end
    Step.step('social','inviteToast',{result='shown'})
    local Tween=game:GetService('TweenService')
    local match=M.inMatch and M.inMatch()
    local card=UI.panel(match and M.parent or lobby.root,'PartyInviteCard');card.ZIndex=match and 18 or 46;card.Active=true;lobby.inviteCard=card
    local rw=lobby.root.AbsoluteSize.X/Theme.scale;local w=math.min(340,rw-24);UI.box(card,(rw-w)/2,64,w,112)
    local title=UI.label(card,'Title',string.format('%s님이 파티에 초대했어요',r.name or '친구'),17);UI.box(title,14,8,w-28,30);title.TextXAlignment=Enum.TextXAlignment.Center;title.ZIndex=47
    local left=UI.label(card,'Remaining','',12,UI.colors.muted);UI.box(left,14,38,w-28,18);left.TextXAlignment=Enum.TextXAlignment.Center;left.ZIndex=47
    local bw=(w-28-8)/2
    M.current=match and card or nil
    local function close()if card.Parent then card:Destroy()end;if lobby.inviteCard==card then lobby.inviteCard=nil end;if M.current==card then M.current=nil end;if M.changed then M.changed()end end
    local accept=UI.button(card,'Accept','수락',function()close();Step.step('social','inviteToast',{result='accepted'});lobby:request('accept',r.from)end,true);UI.box(accept,14,64,bw,36);accept.ZIndex=47
    local decline=UI.button(card,'Decline','거절',function()close();Step.step('social','inviteToast',{result='rejected'});lobby:request('decline',r.from)end);UI.box(decline,14+bw+8,64,bw,36);decline.ZIndex=47
    local bar
    if match then
        local face=Theme.make('ImageLabel',card,{Name='Avatar',BackgroundColor3=Theme.colors.raised,BorderSizePixel=0,ZIndex=19,Image=r.from and ('rbxthumb://type=AvatarHeadShot&id='..r.from..'&w=150&h=150')or ''})
        local edge=require(script.Parent.EdgeMask).fit(Theme.make('Frame',card,{Name='Edge',BorderSizePixel=0,ZIndex=19}));bar=Theme.make('Frame',card,{Name='TimeLeft',BorderSizePixel=0,ZIndex=19})
        title.Text=string.format('%s님의 파티 초대',r.name or '친구');title.TextXAlignment=Enum.TextXAlignment.Left;title:SetAttribute('LocalizationSkip',false)
        left.TextXAlignment=Enum.TextXAlignment.Left
        for _,o in ipairs({title,left,accept,decline})do o.ZIndex=19 end
        card:SetAttribute('Edge',true);M.paint=function(sw)require(script.Parent.DiplomacyInbox).card(card,{edge=edge,avatar=face,name=title,line=left,bar=bar,fraction=bar:GetAttribute('Fraction')or 1,buttons={accept,decline},color=Theme.colors.accent},sw)end
        M.paint(rw)
    else
        card.AnchorPoint=Vector2.new(.5,0)
        card.Position=UDim2.new(.5,0,0,64);card.Size=UDim2.new(1,-24,0,112)
        UI.make('UISizeConstraint',card,{MaxSize=Vector2.new(340,112)})
        title.Size=UDim2.new(1,-28,0,30);left.Size=UDim2.new(1,-28,0,18)
        accept.Size=UDim2.new(.5,-18,0,36)
        decline.Position=UDim2.new(.5,4,0,64);decline.Size=UDim2.new(.5,-18,0,36)
        local scale=UI.make('UIScale',card,{Scale=.7});Tween:Create(scale,TweenInfo.new(.3,Enum.EasingStyle.Quint),{Scale=1}):Play()
    end
    pcall(function()require(script.Parent.ToyAudio).play('milestone')end)
    if M.changed then M.changed()end
    local expires=os.clock()+M.ttl
    task.spawn(function()
        while card.Parent do
            local s=math.ceil(expires-os.clock());if s<=0 then close();Step.step('social','inviteToast',{result='expired',reason='timeout'});break end
            left.Text=match and string.format('다음 판을 같이 해요 %d초',s)or string.format('%d초 안에 응답',s)
            if bar then bar:SetAttribute('Fraction',s/M.ttl);bar.Size=UDim2.fromOffset(math.floor((card.Size.X.Offset-24)*s/M.ttl),3)end
            task.wait(.5)
        end
    end)
    return card
end
return M
