local M={}
M.excluded={
    ["Russia"]=true,["Ukraine"]=true,["Belarus"]=true,["Israel"]=true,["Iran"]=true,["Syria"]=true,["Lebanon"]=true,
    ["Yemen"]=true,["Sudan"]=true,["South Sudan"]=true,["Myanmar"]=true,["Afghanistan"]=true,
    ["North Korea"]=true,["Taiwan"]=true,["Tibet"]=true,["Xinjiang"]=true,["Hong Kong"]=true,["Macau"]=true,
    ["Kuril Islands"]=true,["Sakhalin"]=true,["Jewish Autonomous Oblast"]=true,["Judaea"]=true,["Cyprus"]=true,
    ["Russian Federation"]=true,["Russian State"]=true,["Syrian Arab Republic"]=true,["Islamic Republic of Iran"]=true,["Palestine"]=true,
}
M.excludedFlags={kp=true}
M.keep={marenostrum={["Syria"]=true,["Cyprus"]=true}}
M.flagFix={["Empire of Japan"]="jp"}
M.hiddenFlags={ru=true,ua=true,by=true,il=true,ir=true,sy=true,lb=true,ye=true,sd=true,ss=true,mm=true,af=true,kp=true,tw=true,hk=true,mo=true,cy=true,ps=true,xk=true,eh=true}
function M.allowed(mapKey,entry)
    local keep=M.keep[mapKey]
    if keep and keep[entry.name] then return true end
    if M.excluded[entry.name] then return false end
    if entry.flag and M.excludedFlags[entry.flag] then return false end
    return true
end
function M.filter(mapKey,list)
    local out={}
    for _,entry in ipairs(list or {})do if M.allowed(mapKey,entry)then table.insert(out,entry)end end
    return out
end
function M.flag(entry)
    local f=entry and entry.flag;f=M.flagFix[f] or f
    if type(f)=="string" and string.match(f,"^%l%l$") and not M.hiddenFlags[f] then return f end
    return nil
end
return M
