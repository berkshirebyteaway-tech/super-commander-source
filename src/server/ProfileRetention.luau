local M={}
function M.sealed(progress,event)
    local r=progress.receipts[event.id]
    if not r or not r.sealed then return false end
    r.revision=math.max(r.revision,event.revision)
    if event.basicsComplete then progress.basicsComplete=true end
    return true
end
function M.compact(progress,event)
    local r=progress.receipts[event.id];if not r or not event.final then return end
    progress.receipts[event.id]={sealed=true,revision=r.revision,xp=r.xp,medals=r.medals,paidXP=r.paidXP,grantedXP=r.grantedXP,grantedMedals=r.grantedMedals,totalsComplete=r.totalsComplete,won=r.won,counted=r.counted,firstWin=r.firstWin,parts=r.parts,time=event.time}
end
M.window=30*86400
function M.prune(progress,now,unpaid)
    if type(unpaid)~='table'then return end
    for id,r in pairs(progress.receipts)do if r.sealed and not unpaid[id]then
        if type(r.time)~='number'then r.time=now elseif r.time<now-M.window then progress.receipts[id]=nil end
    end end
end
return M
