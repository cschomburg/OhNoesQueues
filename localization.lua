local L = {}


if(GetLocale() == "deDE") then
	L["Left-click"] = nil
	L["Right-click"] = nil
	L["Expiration Time"] = nil
	L["Accept port"] = nil
	L["Open score board"] = nil
	L["Leave battleground"] = nil
	L["Estimated wait time"] = nil
	L["Waited time"] = nil
	L["Leave queue"] = nil
	L["Join as group or solo"] = nil
	L["Join solo"] = nil
end

select(2, ...).ONQ_L = L