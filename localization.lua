local L = {}

--[[
This is the stuff you need to fill out for your locale:
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

	Missing locales:
	- frFR
	- esES
	- esMX
	- ruRU
	- zhCN
	- koKR
	- zhTW
]]

if(GetLocale() == "deDE") then
	L["Left-click"] = "Linksklick"
	L["Right-click"] = "Rechtsklick"
	L["Expiration Time"] = "Zeit bis Abbruch"
	L["Accept port"] = "Teleport annehmen"
	L["Open score board"] = "Punkteübersicht öffnen"
	L["Leave battleground"] = "Schlachtfeld verlassen"
	L["Estimated wait time"] = "Erwartete Wartezeit"
	L["Waited time"] = "Bisherige Wartezeit"
	L["Leave queue"] = "Warteschlange verlassen"
	L["Join as group or solo"] = "Alleine oder als Gruppe beitreten"
	L["Join solo"] = "Alleine beitreten"
end

select(2, ...).ONQ_L = L