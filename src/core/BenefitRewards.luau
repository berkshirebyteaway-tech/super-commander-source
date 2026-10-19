local M={}
function M.apply(out,before,event)
    local receipt=out.receipts[event.id];local prior=before.receipts[event.id]
    local multiplier=event.benefitXPMultiplier or(event.benefitXP2==true and 2 or 1)
    if not receipt or (multiplier~=2 and multiplier~=4)or (prior and prior.revision>=receipt.revision)then return out end
    local delta=math.max(0,out.xp-before.xp)
    if delta>0 then
        local extra=delta*(multiplier-1);out.xp+=extra;receipt.paidXP=(prior and prior.paidXP or 0)+extra
        receipt.parts=receipt.parts or {};local part=receipt.parts.benefit or {x=0,m=0};receipt.parts.benefit=part;part.x+=extra
    end
    return out
end
return M
