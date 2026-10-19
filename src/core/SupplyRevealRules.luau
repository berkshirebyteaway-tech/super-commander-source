local M={}
M.duration={normal=2.1,rare=2.7,epic=3.4,legendary=4.3,mythic=5.4}
M.rank={normal=1,rare=2,epic=3,legendary=4,mythic=5}
function M.phase(rarity,elapsed,reduced)
    local duration=reduced and .35 or M.duration[rarity]or 2.1
    local p=math.clamp(elapsed/duration,0,1)
    return p<.24 and 'delivery'or p<.63 and 'seal'or p<1 and 'reveal'or 'result',p
end
function M.serial(actor,sequence)
    local function base(n)
        local s='';repeat local d=n%36;s=string.sub('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',d+1,d+1)..s;n=math.floor(n/36)until n==0;return s
    end
    if type(actor)~='number'or actor<=0 or actor%1~=0 or actor>=2^53 then return nil end
    return 'SC-'..base(actor)..'-'..base(sequence)
end
function M.evolution(tier,share,danger)
    if tier~=5 then return 1 end
    return danger and 3 or share>=.3 and 3 or share>=.1 and 2 or 1
end
return M
