local M={}
M.kst=9*3600
M.warnMinutes=30
M.gateMinutes=10
M.graceSeconds=60
M.flashMaxMinutes=120
M.moveSeconds=45
M.moveMaxHops=2
M.partyWaitSeconds=600
M.textMax=80
M.held={start=true,daily=true,again=true,ranked=true,joinField=true,join=true,play=true,customCreate=true,joinCode=true,customStart=true,customLaunch=true,campaign=true}
M.bans={['1d']=86400,['7d']=7*86400,['30d']=30*86400,perm=-1}
M.banOrder={'1d','7d','30d','perm'}
M.banLabel={['1d']='1일',['7d']='7일',['30d']='30일',perm='영구'}
M.reasons={
    {id='cheat',ko='핵이나 외부 프로그램 사용',en='Using cheats or exploits'},
    {id='abuse',ko='욕설이나 괴롭힘',en='Harassment or abusive language'},
    {id='bug',ko='버그 악용',en='Abusing a bug'},
    {id='grief',ko='고의로 팀 방해',en='Deliberately ruining matches'},
    {id='other',ko='이용 규칙 위반',en='Breaking the experience rules'},
}

local function days(y,m,d)
    y=m<=2 and y-1 or y
    local era=(y>=0 and y or y-399)//400
    local yoe=y-era*400
    local doy=(153*(m+(m>2 and -3 or 9))+2)//5+d-1
    local doe=yoe*365+yoe//4-yoe//100+doy
    return era*146097+doe-719468
end
function M.parseTime(text)
    if type(text)~='string'then return nil end
    local s=text:gsub('^%s+',''):gsub('%s+$','')
    if s==''then return nil end
    local y,mo,d,h,mi,rest=s:match('^(%d%d%d%d)%-(%d%d?)%-(%d%d?)[T%s]+(%d%d?):(%d%d)(.*)$')
    if not y then return nil end
    y,mo,d,h,mi=tonumber(y),tonumber(mo),tonumber(d),tonumber(h),tonumber(mi)
    if mo<1 or mo>12 or d<1 or d>31 or h>23 or mi>59 then return nil end
    local tail=rest:gsub('%s',''):upper()
    local offset
    if tail==''or tail=='KST'then offset=M.kst elseif tail=='Z'or tail=='UTC'then offset=0 else return nil end
    return days(y,mo,d)*86400+h*3600+mi*60-offset
end
function M.kstText(t)
    if type(t)~='number'then return '없음'end
    local k=t+M.kst;local z=k//86400;local s=k%86400
    z+=719468;local era=(z>=0 and z or z-146096)//146097;local doe=z-era*146097
    local yoe=(doe-doe//1460+doe//36524-doe//146096)//365;local doy=doe-(365*yoe+yoe//4-yoe//100)
    local mp=(5*doy+2)//153;local d=doy-(153*mp+2)//5+1;local m=mp<10 and mp+3 or mp-9
    return string.format('%d월 %d일 %02d:%02d',m,d,s//3600,s%3600//60)
end
local function minutes(v,default,lo,hi)
    if type(v)~='number'or v~=v then return default end
    return math.clamp(math.floor(v),lo,hi)
end
function M.phase(cfg,now,startedAt,outdated)
    cfg=cfg or {}
    local closeAt,reopenAt=M.parseTime(cfg.closeAt),M.parseTime(cfg.reopenAt)
    if reopenAt and closeAt and reopenAt<=closeAt then reopenAt=nil end
    local warn=minutes(cfg.closeWarnMinutes,M.warnMinutes,0,24*60)*60
    local gate=minutes(cfg.closeGateMinutes,M.gateMinutes,0,120)*60
    local p={state='normal',closeAt=closeAt,reopenAt=reopenAt}
    if cfg.maintenance==true then p.state='maintenance';p.manual=true;return p end
    if closeAt and now>=closeAt then
        if reopenAt and now<reopenAt then p.state='maintenance';return p end
        if (startedAt or now)<closeAt and not reopenAt then p.state='closing'end
    elseif closeAt then
        local left=closeAt-now;p.left=left
        if left<=gate then p.state='gated'elseif left<=warn then p.state='warn'end
    end
    if outdated==true then p.state='outdated'end
    return p
end
function M.outdated(placeVersion,latest)
    return type(placeVersion)=='number'and type(latest)=='number'and placeVersion>0 and latest>placeVersion
end
function M.planMove(members,now,delay)
    delay=type(delay)=='number'and delay==delay and math.clamp(math.floor(delay),10,600)or M.moveSeconds
    local go,stay,busy,first,last={},{},false,nil,nil
    for _,m in ipairs(members)do
        if m.inMatch then busy=true
        elseif (m.hops or 0)>=M.moveMaxHops then table.insert(stay,m.id)
        else table.insert(go,m.id);local f=m.freeSince or now;first=math.min(first or f,f);last=math.max(last or f,f)end
    end
    if #go==0 then return {ids=go,stay=stay}end
    if busy and now-first<M.partyWaitSeconds then return {ids=go,stay=stay}end
    return {ids=go,stay=stay,at=last+delay}
end
function M.holds(state,action)
    return (state=='gated'or state=='closing'or state=='outdated'or state=='maintenance')and M.held[action]==true
end
function M.heldMessage(state)
    if state=='maintenance'then return '점검 중이라 새 경기는 잠시 쉬어요.'end
    if state=='outdated'then return '새 버전이 나왔어요. 곧 새 버전 로비로 옮겨 드릴게요.'end
    return '곧 업데이트가 있어서 새 경기는 잠시 쉬어요. 업데이트 뒤에 다시 만나요.'
end
function M.duration(seconds,en)
    seconds=math.max(0,math.floor(seconds or 0))
    if seconds<60 then return string.format(en and '%ds'or '%d초',seconds)end
    local m=math.ceil(seconds/60)
    if m<60 then return string.format(en and '%d min'or '%d분',m)end
    local h,r=m//60,m%60
    if r==0 then return string.format(en and '%d h'or '%d시간',h)end
    return string.format(en and '%d h %d min'or '%d시간 %d분',h,r)
end
function M.autoLine(p,now,en)
    if p.state=='warn'or p.state=='gated'then
        local left=M.duration(p.closeAt-now,en)
        if p.state=='gated'then return string.format(en and 'Update in %s. New matches are paused until then.'or '%s 뒤 업데이트가 있어요. 새 경기는 잠시 쉬어요.',left)end
        return string.format(en and 'Update in %s. Matches still running then will not count.'or '%s 뒤 업데이트가 있어요. 그때 진행 중인 경기는 기록되지 않아요.',left)
    elseif p.state=='outdated'then
        if p.moveAt==-1 then return nil end
        if p.moveAt and p.moveAt>now then return string.format(en and 'New version is out. Moving you there in %s.'or '새 버전이 나왔어요. %s 뒤 새 버전 로비로 옮겨요.',M.duration(p.moveAt-now,en))end
        if p.moveAt then return en and 'Moving you to the new version.'or '새 버전 로비로 옮기는 중이에요.'end
        return en and 'New version is out. After this match you will move to it.'or '새 버전이 나왔어요. 이번 판이 끝나면 새 버전으로 옮겨 드릴게요.'
    elseif p.state=='closing'then return en and 'The update is starting. See you in a moment.'or '업데이트를 시작해요. 잠시 뒤에 다시 만나요.'
    elseif p.state=='maintenance'then
        if p.reopenAt and p.reopenAt>now then return string.format(en and 'Maintenance. Back in about %s.'or '점검 중이에요. 약 %s 뒤에 다시 열려요.',M.duration(p.reopenAt-now,en))end
        return en and 'Maintenance. HQ closes after your match.'or '점검 중이에요. 지금 경기가 끝나면 로비가 닫혀요.'
    end
    return nil
end
function M.kickMessage(p,now,en)
    if p.reopenAt and p.reopenAt>now then
        return string.format(en and 'Super Commander is under maintenance. Please come back in about %s.'or '슈퍼 커맨더 점검 중이에요. 약 %s 뒤에 다시 와 주세요.',M.duration(p.reopenAt-now,en))
    end
    return en and 'Super Commander is under maintenance. Please come back a little later.'or '슈퍼 커맨더 점검 중이에요. 조금 뒤에 다시 와 주세요.'
end
function M.line(text,max)
    if type(text)~='string'then return nil end
    text=text:gsub('[\r\n\t]',' '):gsub('^%s+',''):gsub('%s+$','')
    if text==''or not utf8.len(text)then return nil end
    max=max or M.textMax
    if utf8.len(text)>max then text=text:sub(1,utf8.offset(text,max+1)-1)end
    return text
end
function M.topLine(p,now,en,flash,ticker,tickerEn)
    local auto=M.autoLine(p,now,en);if auto then return auto,'phase'end
    if flash and type(flash.untilAt)=='number'and flash.untilAt>now then
        local t=M.line(en and flash.textEn~=''and flash.textEn or flash.text);if t then return t,'flash'end
    end
    local t=M.line(en and type(tickerEn)=='string'and tickerEn~=''and tickerEn or ticker);if t then return t,'ticker'end
    return nil
end
function M.reason(id)for _,r in ipairs(M.reasons)do if r.id==id then return r end end;return nil end
function M.banConfig(userId,duration,reasonId,note)
    if type(userId)~='number'or userId<1 or userId%1~=0 then return nil,'유저를 먼저 찾아 주세요.'end
    local seconds=M.bans[duration];if not seconds then return nil,'기간을 골라 주세요.'end
    local r=M.reason(reasonId);if not r then return nil,'사유를 골라 주세요.'end
    note=M.line(note,200)
    return {UserIds={userId},ApplyToUniverse=true,Duration=seconds,
        DisplayReason=r.ko..' / '..r.en,
        PrivateReason=string.format('[%s] %s',reasonId,note or ''),ExcludeAltAccounts=false}
end
return M
