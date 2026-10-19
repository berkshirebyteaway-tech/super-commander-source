local M={}
function M.create(kind)
    local w,h=48,28;local terrain,owners={},{}
    for y=0,h-1 do for x=0,w-1 do
        local byte=128+(kind=="mixed" and (x*7+y*11)%31 or 0)
        if kind=="channels" and x==math.floor(w/2) and y%7~=3 then byte=32 end
        if kind=="channels" and y==math.floor(h/2) and x%9==0 then byte=159 end
        table.insert(terrain,byte)
        table.insert(owners,bit32.band(byte,128)~=0 and bit32.band(byte,31)~=31 and (x<w/2 and 1 or kind=="neutral" and 0 or 2) or 0)
    end end
    return {width=w,height=h,terrain=terrain,owners=owners,troops={40000,40000}}
end
return M
