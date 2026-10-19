local M={default='standard',items={
    {id='standard',name='커맨더 깃발',level=1,cut='stepped',trim=0,finial=1,crest=1,effect=0},
    {id='vanguard',name='선봉 깃발',level=5,cut='stepped',trim=1,finial=1,crest=2,effect=0},
    {id='pathfinder',name='개척 깃발',level=15,cut='forked',trim=1,finial=1,crest=3,effect=0},
    {id='sentinel',name='수호 깃발',level=30,cut='forked',trim=2,finial=2,crest=4,effect=0},
    {id='marshal',name='지휘 깃발',level=60,cut='crown',trim=2,finial=2,crest=5,effect=0},
    {id='grandmarshal',name='대원수 깃발',level=75,cut='crown',trim=3,finial=2,crest=6,effect=0},
    {id='ascendant',name='초월 지휘관 깃발',level=90,cut='crown',trim=3,finial=3,crest=7,effect=1},
    {id='sovereign',name='최고 지휘관 깃발',level=100,cut='crown',trim=3,finial=3,crest=8,effect=2},
}}
M.mark={{.50,.23,.46,.12,-18},{.26,.36,.12,.28,0},{.50,.50,.46,.12,-18},{.74,.64,.12,.28,0},{.50,.77,.46,.12,-18}}
function M.emblem(id)
    local item=M.find(id)or M.items[1];local out={}
    for _,s in ipairs(M.mark)do table.insert(out,{.5+(s[1]-.5)*.62,.5+(s[2]-.5)*.62,s[3]*.62,s[4]*.62,s[5]})end
    local function stroke(x,y,w,h,a)table.insert(out,{x,y,w,h,a or 0})end
    local n=item.crest
    if n>=2 then stroke(.38,.88,.24,.035,22);stroke(.62,.88,.24,.035,-22)end
    if n>=3 then stroke(.18,.47,.035,.52);stroke(.82,.47,.035,.52);stroke(.34,.78,.36,.035,34);stroke(.66,.78,.36,.035,-34)end
    if n>=4 then stroke(.27,.17,.26,.035,-12);stroke(.73,.17,.26,.035,12)end
    if n>=5 then for _,side in ipairs({-1,1})do for i=1,3 do stroke(.5+side*(.28+i*.035),.34+i*.09,.19,.035,side*-24)end end end
    if n>=6 then stroke(.5,.10,.25,.035);stroke(.5,.055,.06,.06,45)end
    if n>=7 then stroke(.36,.07,.035,.10,-24);stroke(.64,.07,.035,.10,24);stroke(.5,.95,.06,.06,45)end
    if n>=8 then stroke(.08,.5,.045,.045,45);stroke(.92,.5,.045,.045,45);stroke(.24,.095,.045,.045,45);stroke(.76,.095,.045,.045,45)end
    return out
end
function M.find(id)for _,item in ipairs(M.items)do if item.id==id then return item end end end
function M.owns(id,level)local item=M.find(id);return item~=nil and type(level)=='number'and level==level and level%1==0 and level>=item.level and level<=100 end
function M.effective(id,level)return M.owns(id,level)and id or M.default end
function M.next(level)for _,item in ipairs(M.items)do if item.level>level then return item end end end
function M.testLevel(isStudio,localMode)return isStudio==true and localMode==true and 100 or nil end
return M
