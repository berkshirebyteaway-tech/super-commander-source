local M={}
function M.points(tiles,width)
    local pts={}
    for i,t in ipairs(tiles)do pts[i]=Vector2.new(t%width+.5,t//width+.5)end
    return pts
end
function M.trim(pts,cutA,cutB)
    local function cut(list,amount)
        local out={list[1]};local i=1
        while amount>0 and i<#list do
            local d=list[i+1]-out[1];local length=d.Magnitude
            if length>amount then out[1]=out[1]+d.Unit*amount;amount=0 else amount-=length;i+=1;out[1]=list[i] end
        end
        if amount>0 then return nil end
        for j=i+1,#list do table.insert(out,list[j])end
        return out
    end
    local a=cut(pts,cutA);if not a or #a<2 then return nil end
    local reversed={};for i=#a,1,-1 do table.insert(reversed,a[i])end
    local b=cut(reversed,cutB);if not b or #b<2 then return nil end
    local out={};for i=#b,1,-1 do table.insert(out,b[i])end
    return out
end
return M
