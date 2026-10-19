local M={}
function M.funnelReady(state,key,step)return step==(state[key]or 0)+1 end
function M.sequence(state,version,id)
 if type(id)~='number'or id~=id or id%1~=0 or id<1 or id>9007199254740991 then return nil end
 state.sequenceVersions=state.sequenceVersions or {};state.sequenceOrder=state.sequenceOrder or M.ring(8)
 local key=tostring(version);local previous=state.sequenceVersions[key]
 if previous and id<=previous then return false end
 if not previous then if state.sequenceOrder.count==8 then state.sequenceVersions[M.pop(state.sequenceOrder)]=nil end;M.push(state.sequenceOrder,key)end
 state.sequenceVersions[key]=id;return true
end
function M.ring(capacity)return {capacity=capacity,head=1,count=0,items={},lost=0}end
function M.push(q,value)
 if q.count==q.capacity then q.items[q.head]=value;q.head=q.head%q.capacity+1;q.lost+=1;return false end
 local i=(q.head+q.count-1)%q.capacity+1;q.items[i]=value;q.count+=1;return true
end
function M.pop(q)
 if q.count==0 then return nil end
 local i=q.head;local v=q.items[i];q.items[i]=nil;q.head=i%q.capacity+1;q.count-=1;return v
end
function M.array(q)local out={};for i=0,q.count-1 do out[i+1]=q.items[(q.head+i-1)%q.capacity+1]end;return out end
function M.token(capacity,rate,now)return {capacity=capacity,rate=rate,value=capacity,at=now or 0}end
function M.take(t,now,amount)
 t.value=math.min(t.capacity,t.value+math.max(0,now-t.at)*t.rate);t.at=now;amount=amount or 1
 if t.value<amount then return false end;t.value-=amount;return true
end
function M.window(now)return {at=now,total=0,counts={},latency={},sum=0,max=0}end
function M.count(w,key,amount)amount=amount or 1;w.counts[key]=(w.counts[key]or 0)+amount;w.total+=amount end
function M.histogram(w,bucket,ms)w.latency[bucket]=(w.latency[bucket]or 0)+1;w.sum+=ms;w.max=math.max(w.max,ms)end
function M.once(owner,key,capacity)
 owner.seen=owner.seen or {};owner.order=owner.order or M.ring(capacity or 512)
 if owner.seen[key]then return false end
 if owner.order.count==owner.order.capacity then local old=M.pop(owner.order);owner.seen[old]=nil end
 M.push(owner.order,key);owner.seen[key]=true;return true
end
return M
