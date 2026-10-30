local Rules=if script then require(script.Parent.OutgameRules)else require('./OutgameRules')
local M={}
local function UI_number(n)local s=tostring(math.floor(n));local out=s:reverse():gsub('(%d%d%d)','%1,'):reverse();return (out:gsub('^,',''))end
function M.tally(out,before,event)
    local receipt=out.receipts[event.id];local prior=before.receipts[event.id]
    if not receipt or (event.revision or 0)<=(prior and prior.revision or 0)then return out end
    receipt.grantedXP=(prior and (prior.grantedXP or prior.xp)or 0)+(out.xp-before.xp)
    receipt.grantedMedals=(prior and (prior.grantedMedals or prior.medals)or 0)+(out.medals-before.medals)
    receipt.totalsComplete=prior==nil or prior.totalsComplete==true
    if receipt.totalsComplete then for _,row in ipairs(out.history or {})do if row.id==event.id then row.grantedXP=receipt.grantedXP;row.grantedMedals=receipt.grantedMedals end end end
    return out
end
function M.goalPaid(out,before,event)
    local r=out.receipts[event.id];local prior=before.receipts[event.id]
    if not r or type(r.parts)~='table'then return nil end
    local xp,medals=0,0
    for _,kind in ipairs({'daily','weekly','achievement'})do
        local e=r.parts[kind];local o=prior and type(prior.parts)=='table'and prior.parts[kind]
        if type(e)=='table'then xp+=(e.x or 0)-(o and o.x or 0);medals+=(e.m or 0)-(o and o.m or 0)end
    end
    return (xp>0 or medals>0)and {xp=xp,medals=medals}or nil
end
M.partNames={daily='오늘의 목표',weekly='주간 목표',onboarding='처음 시작하기',firstWin='오늘의 첫 승리',firstMatch='오늘 첫 판 2배',returned='복귀 보너스',pool='주간 2배 XP',
    recruit='초대 보상',comrade='같이 하기',dailyOp='오늘의 도전',supply='오늘의 보급',campaign='캠페인 첫 클리어',campaignChest='캠페인 별 상자',boost='이벤트 XP',benefit='커맨더 XP 보너스',conquest='지도 정복',tactic='전술 기장',season='시즌 단계',achievement='업적'}
function M.bonusParts(receipt)
    if not receipt or type(receipt.parts)~='table'then return nil end
    local list={};for kind,e in pairs(receipt.parts)do if type(e)=='table'and ((e.x or 0)>0 or (e.m or 0)>0)then table.insert(list,{kind=kind,xp=e.x or 0,medals=e.m or 0})end end
    table.sort(list,function(a,b)return a.xp+a.medals>b.xp+b.medals or a.xp+a.medals==b.xp+b.medals and a.kind<b.kind end)
    if #list>4 then local rest={kind='other',xp=0,medals=0};for i=4,#list do rest.xp+=list[i].xp;rest.medals+=list[i].medals end;for i=#list,4,-1 do table.remove(list,i)end;table.insert(list,rest)end
    return list
end
function M.partRow(e)return {name=M.partNames[e.kind]or '기타 보너스',xp=e.xp or 0,medals=e.medals or 0}end
function M.partLine(e)
    local name=M.partNames[e.kind]or '기타 보너스'
    if e.xp>0 and e.medals>0 then return string.format('+%d XP  +%d 코인  %s',e.xp,e.medals,name)end
    return e.xp>0 and string.format('+%d XP  %s',e.xp,name)or string.format('+%d 코인  %s',e.medals,name)
end
function M.baseline(v)
    if type(v)~='table'or not v.level then return nil end
    local b={xp=v.xp,level=v.level,achievements={},tactics={},season=v.career and v.career.season and {id=v.career.season.id,tier=v.career.season.tier}or nil}
    for _,a in ipairs(v.achievementList or {})do if a.done then b.achievements[a.id]=true end end
    for _,t in ipairs(v.tactics or {})do b.tactics[t.id]=t.tier end
    b.peaks={};for map,m in pairs(type(v.mastery)=='table'and v.mastery or {})do if type(m)=='table'and type(m.peak)=='number'then b.peaks[map]=m.peak end end
    return b
end
function M.unlocks(b,v)
    local out={};if not b or type(v)~='table'then return out end
    for _,r in ipairs(Rules.career.between(b.level,v.level or b.level))do table.insert(out,string.format('새 보상 %s',Rules.career.rewardLabel(r.reward)))end
    for _,a in ipairs(v.achievementList or {})do if a.done and not b.achievements[a.id]then table.insert(out,string.format('업적 달성 %s  +%d 코인',a.name,a.medals))end end
    for _,t in ipairs(v.tactics or {})do if t.tier>(b.tactics[t.id]or 0)then table.insert(out,string.format('전술 기장 %s %s',string.rep('★',t.tier),t.name))end end
    local s=v.career and v.career.season
    if s and b.season and s.id==b.season.id and s.tier>b.season.tier and s.steps then
        local coins=0;for i=b.season.tier+1,s.tier do coins+=s.steps[i]and s.steps[i].coins or 0 end
        table.insert(out,string.format('%s %s점 달성  +%d 코인',s.name,UI_number(s.steps[s.tier]and s.steps[s.tier].score or 0),coins))
    end
    return out
end
function M.recordState(progress,receipt,pending,ready,localMode)
    if progress.unrecorded then return 'practice'end
    if progress.mode=='training'then return 'training'end
    if pending then return 'pending'end
    if not ready then return 'unavailable'end
    if receipt and (receipt.revision or 0)>=(progress.revision or 0)and progress.ended then return localMode and 'local'or 'saved'end
    return 'pending'
end
function M.goal(progress)
    if not progress then return nil end
    local daily=progress.daily or {};local best,ratio=nil,-1
    for _,g in ipairs(Rules.daily)do if not(daily.paid and daily.paid[g.id])then
        local value=math.min(daily[g.id]or 0,g.target);local share=value/g.target
        if share>ratio then ratio=share;best={name=g.name,value=value,target=g.target,seconds=g.id=='seconds',weekly=false}end
    end end
    if best then return best end
    local weekly=progress.weekly or {}
    if not weekly.paid then for _,g in ipairs(Rules.weeklyPaths)do
        local value=math.min(weekly[g.id]or 0,g.target);local share=value/g.target
        if share>ratio then ratio=share;best={name=g.name,value=value,target=g.target,seconds=g.id=='seconds',weekly=true}end
    end end
    return best
end
function M.retryIntro(state)
    return false
end
function M.tomorrow(progress)
    if type(progress)~='table'then return nil end
    local medals=type(progress.login)=='table'and tonumber(progress.login.nextReward)or Rules.streakRewards[1]
    local st=Rules.campaign.stage(progress.campaignNext)
    if st then return string.format('내일 출석 +%d 코인  캠페인 %s %s',medals,st.id,st.name)end
    return string.format('내일 출석 +%d 코인',medals)
end
function M.personalBest(r,status)
    local peak=tonumber(r.peak)
    if status=='practice'or status=='training'or not peak or peak<.01 then return false end
    return type(r.priorPeak)=='number'and r.priorPeak>0 and peak>r.priorPeak+.0005
end
function M.view(state)
    local r=state.personalResult or {};local continuing=state.multiplayer==true and not state.matchEnded
    local outcome=r.outcome or (state.phase=='won'and 'won'or 'lost')
    local won=outcome=='won'
    local title=won and '승리'or outcome=='forfeit'and '중단'or continuing and '탈락'or '패배'
    if won and state.multiplayer and (state.mode=='coop'or state.mode=='teams'or state.player and state.player.team)then title='팀 승리'end
    local status=r.recordStatus or (r.unrecorded and 'practice'or r.pending and 'pending'or 'pending')
    local message=({practice='연습, 기록과 보상 없음',training='연습, 경기 기록 제외',pending='기록 저장 중, 다음 판 진행 가능',unavailable='저장 연결 대기, 기록 재시도 중',['local']='Studio 임시 기록, 정지하면 초기화',saved='기록 저장 완료'})[status]or '기록 저장 중, 다음 판 진행 가능'
    local rewardNote=r.mode=='custom'and '자유 설정, 경기 보상 없음'or (r.seconds or 0)<120 and '경기 보상은 2분 참여부터'or '경기 보상'
    if status=='practice'or status=='training'then rewardNote='연습, 경기 보상 없음'end
    local xp,medals=r.xp or 0,r.medals or 0;local g=status~='practice'and r.granted
    local base;if g and (g.xp>xp or g.medals>medals)then base={xp=xp,medals=medals};xp,medals=g.xp,g.medals end
    local rank,total;if not continuing then rank,total=M.rank(state,won)end
    return {title=title,won=won,continuing=continuing,status=status,message=message,rewardNote=rewardNote,base=base,winner=M.winner(state,won),
        peak=math.clamp(r.peak or (state.player and state.player.share)or 0,0,1),cities=r.cities or 0,supports=r.supports or 0,seconds=r.seconds or 0,
        xp=status=='practice'and 0 or xp,medals=status=='practice'and 0 or medals,rank=rank,total=total,daily=r.daily,campaign=r.campaign,supply=r.supply,casual=state.casual and true or nil,
        retryIntro=M.retryIntro(state),
        nextStage=state.intro and not M.retryIntro(state)and r.campaign and r.campaign.next or nil,
        tomorrow=state.intro and status~='practice'and M.tomorrow(r.progression)or nil,
        again=M.retryIntro(state)and '첫 작전 다시 도전'or state.intro and (r.campaign and r.campaign.next and string.format('다음 작전 %s',r.campaign.next)or '첫 공식전 출전')or r.campaign and (r.campaign.next and string.format('다음 작전 %s',r.campaign.next)or '다시 도전')or r.daily and '다시 도전'or state.casual and (state.nextRoundIn and string.format('다음 판 바로 시작 %d초',state.nextRoundIn)or '다음 판 바로 시작')or state.intro and '첫 공식전 출전'or state.multiplayer and (state.queueMode=='custom'and '같은 설정으로 방 만들기'or '다음 전장 고르기')or '같은 설정으로 한 판 더',
        invite=status~='practice'and type(r.invite)=='table'and r.invite or nil,
        bonus=r.bonus,progression=r.progression,goal=M.goal(r.progression),personalBest=M.personalBest(r,status),
        records=r.conquered~=nil and {conquered=r.conquered or 0,troops=r.troopsSent or 0,built=r.built or 0,nukes=r.nukes or 0}or nil,
        settled=status=='saved'or status=='local'or status=='practice'or status=='training'}
end
function M.rank(state,won)
    if state.intro or state.mode=='coop'or state.mode=='teams'or state.player and state.player.team~=nil then return nil end
    local me;local list={}
    for _,f in ipairs(state.factions or {})do if f.kind~='BOT'then table.insert(list,f);if f.id==1 then me=f end end end
    local total=math.max(state.commanderCount or 0,#list+(me and 0 or 1));if total<2 then return nil end
    local pr=state.personalResult
    if not won and pr and type(pr.place)=='number'and pr.place>=1 then return pr.place,math.max(total,tonumber(pr.field)or 0)end
    local share=me and me.share or 0;local rank=1
    for _,f in ipairs(list)do if f~=me and (f.share or 0)>share then rank+=1 end end
    return won and 1 or rank,total
end
local reasons={timer='시간 종료',territory='영토 기준 달성',lastCommander='최후의 지휘관',hardLimit='시간 종료'}
function M.winner(state,won)
    if won or state.winnerId==nil then return nil end
    local f;for _,x in ipairs(state.factions or {})do if x.id==state.winnerId then f=x;break end end
    local name=state.winnerName or f and f.name
    if not name or name==''then return nil end
    local mine=state.player and state.player.team
    local text=f and f.team~=nil and mine~=nil and f.team~=mine and name..'의 팀 승리'or name..' 승리'
    local why=reasons[state.winReason or '']
    return why and text..', '..why or text
end
function M.spectators(state)
    local list={}
    for _,f in ipairs(state.factions or {})do if (f.id~=1 or state.observer~=nil)and f.kind~='BOT'and not f.eliminated and (f.tiles or 0)>0 and f.labelTile~=nil then table.insert(list,f)end end
    table.sort(list,function(a,b)return a.id<b.id end)
    return list
end
function M.spectatorTarget(list,id,direction)
    if #list==0 then return nil end
    local index;for i,f in ipairs(list)do if f.id==id then index=i;break end end
    if not index then return list[1]end
    return list[(index-1+(direction or 0))%#list+1]
end
return M
