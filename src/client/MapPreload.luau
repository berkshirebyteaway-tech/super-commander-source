local pack=script.Parent.Parent
local remote=pack:WaitForChild('MapStream')
local M={held=nil,building=nil,waiting=false,changed=Instance.new('BindableEvent')}
local function valid(m)
    return type(m)=='table'and type(m.key)=='string'and type(m.fnv)=='number'and type(m.data)=='string'
        and type(m.part)=='number'and type(m.parts)=='number'and type(m.piece)=='number'and type(m.pieces)=='number'
        and m.parts>=1 and m.parts<=64 and m.part>=1 and m.part<=m.parts and m.pieces>=1 and m.pieces<=64 and m.piece>=1 and m.piece<=m.pieces
end
remote.OnClientEvent:Connect(function(m)
    if not valid(m)then return end
    local b=M.building
    if not b or b.key~=m.key or b.fnv~=m.fnv or b.total~=m.parts then b={key=m.key,fnv=m.fnv,total=m.parts,parts={},pieces={},done=0,got=0};M.building=b end
    local list=b.pieces[m.part];if not list then list={count=0,total=m.pieces};b.pieces[m.part]=list end
    if list.total~=m.pieces or list[m.piece]then return end
    list[m.piece]=m.data;list.count+=1;b.got+=1/(list.total*b.total)
    if list.count==list.total then b.parts[m.part]=table.concat(list);b.pieces[m.part]=nil;b.done+=1 end
    if b.done==b.total then
        M.held={key=b.key,fnv=b.fnv,parts=b.parts};M.building=nil
        remote:FireServer({done=b.key..'/'..tostring(b.fnv)})
    end
    M.changed:Fire()
end)
function M.progress(key)
    if M.held and M.held.key==key then return 1 end
    local b=M.building;if b and b.key==key then return math.min(.99,b.got)end
    return nil
end
function M.resolve(s)
    if s.mapPacked then M.waiting=false;return s.mapPacked end
    if s.mapStreamed then
        local h=M.held
        if h and h.key==s.map and h.fnv==s.mapStreamed then M.waiting=false;return h.parts end
        M.waiting=s.version or true;remote:FireServer({missing=true});return false
    end
    if M.waiting~=false and M.waiting==(s.version or true)then return false end
    M.waiting=false
    return nil
end
return M
