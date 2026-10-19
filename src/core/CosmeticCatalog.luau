local C={version=1,default="classic",slots={"commanderOrder","territory","city","defensePost","projectile","trail","impact","commanderTrail","parachute","vehicle"}}
C.styles={
    classic={name="기본",access="free",primary={70,84,100},secondary={190,200,212},accent={54,226,208},territory={54,226,208},border={191,239,255},architecture="classic",orderShape="rays",trail="line",impact="rings"},
    arctic={name="아크틱",access="pass",primary={80,96,116},secondary={214,226,238},accent={125,211,252},territory={56,189,248},border={214,244,255},architecture="spire",orderShape="rings",trail="double",impact="rings"},
    copper={name="코퍼",access="pass",primary={92,74,60},secondary={214,190,160},accent={251,146,60},territory={234,140,60},border={255,214,160},architecture="fortress",orderShape="rays",trail="sparks",impact="rays"},
}
local Collection=if script then require(script.Parent.CollectionDefinitions)else require('./CollectionDefinitions')
for id,style in pairs(Collection.styles())do C.styles[id]=style end
function C.get(id) return C.styles[id] or C.styles[C.default] end
function C.loadout(id) local out={};for _,slot in ipairs(C.slots) do out[slot]=C.styles[id] and id or C.default end;return out end
function C.validSlot(slot) for _,name in ipairs(C.slots) do if slot==name then return true end end;return false end
function C.forSlot(loadout,slot) return C.get(loadout and loadout[slot]) end
return C
