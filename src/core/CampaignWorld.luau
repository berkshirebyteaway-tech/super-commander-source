local Rules=if script then require(script.Parent.CampaignRules) else require("./CampaignRules")
local M={}
M.home='Korea'
M.stages={
    ['1-1']={'China','Mongolia','Kazakhstan','India','Thailand'},
    ['1-2']={'Japan','Philippines'},
    ['1-3']={'Indonesia','Bhutan'},
    ['1-4']={'Pakistan','Sri Lanka'},
    ['1-5']={'Siberia'},
    ['2-1']={'Italy'},
    ['2-2']={'Germany','Poland'},
    ['2-3']={'France','Spain'},
    ['2-4']={'Latvia','Finland'},
    ['2-5']={'Brazil','Argentina','Peru','Bolivia','Uruguay'},
    ['3-1']={'Iceland'},
    ['3-2']={'Cuba','Colombia','Venezuela'},
    ['3-3']={'Sweden','Norway'},
    ['3-4']={'Greenland'},
    ['3-5']={'Romania','Türkiye'},
    ['4-1']={'United Kingdom','Ireland'},
    ['4-2']={'Morocco','Algeria'},
    ['4-3']={'Oman'},
    ['4-4']={'Saudi Arabia'},
    ['4-5']={'Libya','Egypt','Niger','Chad'},
    ['5-1']={'Senegal','Benin'},
    ['5-2']={'Ethiopia','Kenya'},
    ['5-3']={'United States','Canada','Mexico'},
    ['5-4']={'DR Congo','Zambia'},
    ['5-5']={'Madagascar'},
    ['6-1']={'Australia'},
    ['6-2']={'Quebec','Nunavut'},
    ['6-3']={'New Zealand'},
    ['6-4']={'Namibia','South Africa'},
    ['6-5']={'Texas','California'},
    ['7-1']={'Alaska'},
    ['7-2']={'Yukon'},
    ['7-3']={'West Antarctica'},
    ['7-4']={'East Antarctica'},
    ['7-5']={'Antarctica'},
}
M.byNation={};do for id,list in pairs(M.stages)do for _,n in ipairs(list)do M.byNation[n]=id end end end
M.total=0;do for _ in pairs(M.byNation)do M.total+=1 end end
function M.owned(p)
    local out={[M.home]=true}
    for id,list in pairs(M.stages)do if Rules.cleared(p,id)then for _,n in ipairs(list)do out[n]=true end end end
    return out
end
function M.share(p)
    local n=0;for id,list in pairs(M.stages)do if Rules.cleared(p,id)then n+=#list end end
    return n/M.total
end
function M.percent(p)return math.floor(M.share(p)*100+1e-6)end
function M.chapterCount(p,ch)
    local got,all=0,0
    for _,s in ipairs(Rules.stages)do if s.chapter==ch then local n=#(M.stages[s.id]or{});all+=n;if Rules.cleared(p,s.id)then got+=n end end end
    return got,all
end
return M
