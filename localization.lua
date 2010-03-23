local L = {}


if(GetLocale() == "deDE") then
end

setmetatable(L, {__index = function(self, k) return k end})
select(2, ...).ONQ_L = L