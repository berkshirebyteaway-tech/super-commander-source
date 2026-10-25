local UI=require(script.Parent.ToyUI)
local M={}
local function text(parent,name,value,x,y,w,h,size,color)local l=UI.label(parent,name,value,size or 14,color);UI.box(l,x,y,w,h);return l end
function M.draw(hub,body,w)
    local a=hub.account;local p=a.progress or {};local shop=hub.callbacks.shop();local y=0
    local function action(name,title,fn,primary)local b=UI.button(body,name,title,fn,primary);UI.box(b,2,y,w-4,46);y+=54;UI.enabled(b,a.ready==true and not shop.busy);return b end
    if not a.ready and hub.page=='records'then
        local K=require(script.Parent.Kit20);local root,W,H=K.screenRoot(hub,body,'Page20')
        local t=K.text(root,'Loading',a.loading and '기록을 불러오는 중…'or '기록 불러오기 실패',16,K.colors.muted,700,Enum.TextXAlignment.Center);K.box(t,16,H/2-60,W-32,24)
        local retry=K.button(root,'Restore',{kind='pri',text='다시 불러오기',size=16},function()shop:run(function()shop:request('restore')end)end)
        retry:place(math.floor((W-220)/2),H/2-20,220,48);retry:setEnabled(not shop.busy and not a.loading)
        return
    end
    if not a.ready then
        text(body,'Loading',a.loading and '기록을 불러오는 중…'or '기록 불러오기 실패',8,8,w-16,50,16);y=70
        local retry=action('Restore','다시 불러오기',function()shop:run(function()shop:request('restore')end)end,true);UI.enabled(retry,not shop.busy)
        body.CanvasSize=UDim2.fromOffset(0,y);return
    end
    if hub.page=='missions'then
        require(script.Parent.GoalsScreen).draw(hub,body,shop);return
    elseif hub.page=='records'then
        require(script.Parent.RecordsView).page(hub,body,p);return
    elseif hub.page=='wardrobe'then
        require(script.Parent.SkinScreen).draw(hub,body,shop);return
    end
    body.CanvasSize=UDim2.fromOffset(0,y+8)
end
return M
