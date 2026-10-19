local out={}
for k,v in pairs(if script then require(script.Parent.NationNamesKoData_1)else require('./NationNamesKoData_1'))do out[k]=v end
for k,v in pairs(if script then require(script.Parent.NationNamesKoData_2)else require('./NationNamesKoData_2'))do out[k]=v end
for k,v in pairs(if script then require(script.Parent.NationNamesKoData_3)else require('./NationNamesKoData_3'))do out[k]=v end
return out
