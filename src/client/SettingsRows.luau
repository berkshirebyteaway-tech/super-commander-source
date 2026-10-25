local UI=require(script.Parent.ToyUI)
local M={}
function M.heading(parent,title,y,w)
    local t=UI.label(parent,'Category',title,14,UI.colors.muted);UI.box(t,8,y,w-16,26)
    return y+34
end
local function caption(f,title,x,w,h)
    local main,detail=title:match('^(.-) / (.+)$');main=main or title
    local t=UI.label(f,'Label',main,15);t.Font=Enum.Font.BuilderSansBold;t.TextWrapped=false;t.TextTruncate=Enum.TextTruncate.AtEnd
    if detail then
        UI.box(t,x,h/2-19,w,20)
        local d=UI.label(f,'Detail',detail,12,UI.colors.muted);d.TextWrapped=false;d.TextTruncate=Enum.TextTruncate.AtEnd;UI.box(d,x,h/2+1,w,18)
    else UI.box(t,x,0,w,h)end
    return t
end
M.caption=caption
function M.toggle(parent,name,title,value,y,w,apply,enabled)
    local f=UI.panel(parent,name..'Row');UI.box(f,2,y,w-4,56)
    caption(f,title,14,w-110,56)
    local b=UI.button(f,name,'',function()apply(not value)end);UI.box(b,0,0,w-4,56);b.BackgroundTransparency=1
    local edge=b:FindFirstChildOfClass('UIStroke');if edge then edge.Enabled=false end
    b:SetAttribute('On',value==true)
    local track=UI.corner(UI.make('Frame',b,{Name='Switch',BackgroundColor3=value and UI.colors.accent or UI.colors.line,BorderSizePixel=0}),999);UI.box(track,w-4-52-16,14,52,28)
    local knob=UI.corner(UI.make('Frame',track,{Name='Knob',BackgroundColor3=value and UI.colors.bg or UI.colors.ink,BorderSizePixel=0}),999);UI.box(knob,value and 28 or 4,4,20,20)
    UI.enabled(b,enabled~=false);if enabled==false then track.BackgroundTransparency=.5;knob.BackgroundTransparency=.5 end
    return y+64
end
function M.numeric(parent,name,title,value,y,w,lo,hi,apply)
    local f=UI.panel(parent,name..'Row');UI.box(f,2,y,w-4,56)
    local controls=math.min(184,math.floor(w*.47));local x=w-controls-12
    caption(f,title,14,x-22,56)
    local input=UI.make('TextBox',f,{Name=name,Text=tostring(value),ClearTextOnFocus=false,TextSize=16,Font=Enum.Font.BuilderSansBold,TextColor3=UI.colors.ink,BackgroundColor3=UI.colors.bg,BorderSizePixel=0});UI.corner(input,3);UI.box(input,x+44,6,controls-88,44)
    local function commit(n)
        if type(n)=='number'and n==n and n>=lo and n<=hi then
            if n~=value then value=n;apply(n)end
            if input.Parent then input.Text=tostring(value)end
        elseif input.Parent then input.Text=tostring(value)end
    end
    local minus=UI.button(f,'Minus','−',function()commit(math.max(lo,value-1))end);UI.box(minus,x,6,44,44)
    local plus=UI.button(f,'Plus','+',function()commit(math.min(hi,value+1))end);UI.box(plus,w-56,6,44,44)
    input.FocusLost:Connect(function()local n=tonumber(input.Text);task.defer(commit,n)end)
    return y+64
end
function M.stepper(parent,name,title,valueText,y,w,step)
    local f=UI.panel(parent,name..'Row');UI.box(f,2,y,w-4,56)
    local controls=math.min(220,math.floor(w*.5));local x=w-controls-12
    caption(f,title,14,x-22,56)
    local value=UI.label(f,name,valueText,15);value.TextXAlignment=Enum.TextXAlignment.Center;UI.box(value,x+44,6,controls-88,44)
    local prev=UI.button(f,'Prev','‹',function()step(-1)end);UI.box(prev,x,6,44,44)
    local next=UI.button(f,'Next','›',function()step(1)end);UI.box(next,w-56,6,44,44)
    return y+64
end
function M.row20(parent,name,fmt,x,y,w,title,lock)
    local K=require(script.Parent.Kit20);local C=K.colors;local pt,ph=fmt=='pt',fmt=='ph'
    local h=pt and 44 or ph and 40 or 50
    local f=K.make('Frame',parent,{Name=name..'Row',BackgroundColor3=C.panel,BackgroundTransparency=pt and 1 or 0,BorderSizePixel=0});K.box(f,x,y,w,h)
    if pt then local line=K.make('Frame',f,{Name='Line',BackgroundColor3=C.line,BackgroundTransparency=.4,BorderSizePixel=0});K.box(line,0,h-1,w,1)else K.round(f,8)end
    local pad=pt and 0 or ph and 10 or 16;local fs=pt and 14 or ph and 12 or 15
    local l=K.text(f,'Label',title,fs,C.ink,700);local lw=K.width(title,fs,l);K.box(l,pad,0,lw+2,h)
    if lock then local chip=K.lock(f,lock,0,0,11);chip.Position=UDim2.fromOffset(pad+lw+(pt and 6 or 8),math.floor((h-chip.Size.Y.Offset)/2))end
    return f,h,pad
end
function M.heading20(parent,fmt,x,y,w,title,icon)
    local K=require(script.Parent.Kit20);local C=K.colors;local pt,ph=fmt=='pt',fmt=='ph'
    if pt then local t=K.text(parent,'Heading_'..title,title,12,C.muted,800);K.box(t,x,y+8,w,14);return y+30 end
    local is=ph and 12 or 14;local fs=ph and 11 or 13;local hh=ph and 22 or 28
    local top=ph and y or y+6
    local ic=K.icon(parent,icon,is,C.dim,'HeadingIcon_'..title);K.box(ic,x,top+(hh-is)/2,is,is)
    local t=K.text(parent,'Heading_'..title,title,fs,C.dim,800);K.box(t,x+is+(ph and 6 or 8),top,w-is-8,hh)
    return y+(ph and 24 or 36)
end
function M.choice(parent,name,title,values,current,y,w,apply)
    local wide=w>=520;local h=wide and 56 or 100
    local f=UI.panel(parent,name..'Row');UI.box(f,2,y,w-4,h)
    local cw=wide and math.min(360,math.floor(w*.58))or w-28;local x=wide and w-cw-12 or 12
    caption(f,title,14,wide and x-22 or w-30,wide and 56 or 44)
    local by=wide and 6 or 48
    for i,v in ipairs(values)do
        local b=UI.button(f,name..'_'..tostring(v[1]),v[2],function()apply(v[1])end,false);b.TextSize=13
        if v[1]==current then local st=b:FindFirstChildOfClass('UIStroke');if st then st.Color=UI.colors.accent;st.Thickness=2;st.Transparency=0 end;b.TextColor3=UI.colors.accent;b:SetAttribute('Selected',true)end
        UI.box(b,x+(i-1)*(cw+6)/#values,by,(cw-6*(#values-1))/#values,44)
    end
    return y+h+8
end
return M
