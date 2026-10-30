local M={}
function M.layout(width,gap,ranked,world)
    local split=ranked and world
    local left=split and math.floor((width-gap)/2)or width
    return {split=split==true,rankWidth=left,worldX=split and left+gap or 0,worldWidth=split and width-left-gap or width}
end
function M.state(v,party,q,busy)
    if not v or not v.enabled then return {visible=false}end
    local out={visible=true,t=v.t or 0,inspect=true}
    if party and #(party.users or {})>1 then out.reason='혼자일 때만'
    elseif q and q.trophySolo then out.resume=true
    elseif not v.loaded or not v.level then out.reason='전적 불러오는 중'
    elseif v.level<(v.minLevel or 5)then out.reason='레벨 5부터';out.locked=true
    elseif v.pending then out.reason='전적 저장 중'
    elseif not v.available then out.reason='전적 확인 필요'
    elseif (v.banLeft or 0)>0 then out.reason='랭크 잠시 대기'
    elseif q then out.reason='참가 중'
    end
    out.enabled=not busy and out.reason==nil
    return out
end
return M
