local lib = LibStub:NewLibrary("LibBattlegrounds-1.0", 1)
if(not lib) then return end

local byGUID, byName, byLocale
local joinType, join1, join2
local cta_hasWin, cta_winHonor, cta_winArena, cta_lossHonor, cta_lossArena
local rnd_hasWin, rnd_winHonor, rnd_winArena, rnd_lossHonor, rnd_lossArena

local Battleground = {}
Battleground.__index = Battleground

function Battleground:GetInfo()
	return GetBattlegroundInfo(self.id)
end

function Battleground:GetWonTotal(arg1)
	local total, won = GetStatistic(self.total), GetStatistic(self.won)
	return tonumber(won) or 0, tonumber(total) or 0
end

function Battleground.GetStatus(arg1)
	return bg.status, bg.statusID
end

function Battleground:Join(asGroup)
	lib:Join(asGroup, self.guid)
end

function Battleground:GetCurrencyBonus()
	if(self == byName["Random Battleground"]) then
		return rnd_hasWin, rnd_winHonor, rnd_winArena, rnd_lossHonor, rnd_lossArena
	elseif(self == byName["Call to Arms"]) then
		return cta_hasWin, cta_winHonor, cta_winArena, cta_lossHonor, cta_lossArena
	end
end

function lib:Join(asGroup, arg1, arg2)
	local bg1, bg2 = self:Get(arg1), self:Get(arg2)
	joinType, join1, join2 = asGroup, bg1 and bg1.id, bg2 and bg2.id
	PVPBattlegroundFrame.selectedBG = join1
	RequestBattlegroundInstanceInfo(join1)
end

function lib:Get(arg1)
	return byGUID[arg1]
		or byName[arg1]
		or byLocale[arg1]
		or (type(arg1) == "table" and arg1.__index == Battleground and arg1)
end
setmetatable(lib, {__call = lib.Get})


local callbacks = {}

function lib:RegisterCallback(event, key, func)
	callbacks[event] = callbacks[event] or {}
	callbacks[event][key] = func
end

local function fire(event, ...)
	if(not callbacks[event]) then return end

	for key, func in pairs(callbacks[event]) do
		func(key, event, ...)
	end
end

local events = CreateFrame"Frame"
events:RegisterEvent("PVPQUEUE_ANYWHERE_SHOW")
events:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
events:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)

function events:UPDATE_BATTLEFIELD_STATUS()
	for guid, bg in pairs(byGUID) do
		bg.status = nil
		bg.statusID = nil
	end
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, name = GetBattlefieldStatus(i)
		if(status ~= "none") then
			local bg = byLocale[name]

			bg.status = status
			bg.statusID = i
		end
	end

	fire("Status_Updated")	
end

function events:PVPQUEUE_ANYWHERE_SHOW()
	local cta_old, cta_new = byName["Call to Arms"]

	for i=1, GetNumBattlegroundTypes() do
		local name, canEnter, isHoliday, isRandom, guid = GetBattlegroundInfo(i)
		local bg = byGUID[guid]
		bg.id = i

		byLocale[name] = bg
		if(isHoliday) then cta_new = bg end
	end
	fire("IDs_Updated")

	-- Set holiday / call to arms BG
	if(cta_new ~= cta_old) then
		byName["Call to Arms"] = cta_new
		fire("CallToArms_Changed", cta_new, cta_old)
	end

	-- Fetch currency data (it's only available when BG is selected)
	local id = PVPBattlegroundFrame.selectedBG
	if(not id) then return end

	if(id and id == byName["Call to Arms"].id) then
		cta_hasWin, cta_winHonor, cta_winArena, cta_lossHonor, cta_lossArena = GetHolidayBGHonorCurrencyBonuses()
		fire("Currency_Updated_CallToArms")
	elseif(id and id == byName["Random Battleground"].id) then
		rnd_hasWin, rnd_winHonor, rnd_winArena, rnd_lossHonor, rnd_lossArena = GetRandomBGHonorCurrencyBonuses()
		fire("Currency_Updated_RandomBattleground")
	end

	-- Handle join requests
	if(join1 == id) then
		JoinBattlefield(0, joinType and IsPartyLeader() and CanJoinBattlefieldAsGroup())
		join1 = nil
		if(join2) then lib.Join(joinType, join2) end
	end
end

byName, byLocale, byGUID = {},{}, {
	[1] = {
		name = "Alterac Valley",
		guid = 1,
		total = 53,
		won = 49,
		icon = "Interface\\Icons\\INV_Jewelry_Necklace_21",
	},
	[2] = {
		name = "Warsong Gulch",
		guid = 2,
		total = 52,
		won = 105,
		icon = "Interface\\Icons\\INV_Misc_Rune_07",
	},
	[3] = {
		name = "Arathi Basin",
		guid = 3,
		total = 55,
		won = 51,
		icon = "Interface\\Icons\\INV_Jewelry_Amulet_07",
	},
	[7] = {
		name = "Eye of the Storm",
		guid = 7,
		total = 54,
		won = 50,
		icon = "Interface\\Icons\\Spell_Nature_EyeOfTheStorm",
	},
	[9] = {
		name = "Strand of the Ancients",
		guid = 9,
		total = 1549,
		won = 1550,
		icon = "Interface\\Icons\\INV_Jewelry_Amulet_01",
	},
	[30] = {
		name = "Isle of Conquest",
		guid = 30,
		total = 4096,
		won = 4097,
		icon = "Interface\\Icons\\INV_Jewelry_Necklace_27",
	},
	[32] = {
		name = "Random Battleground",
		guid = 32,
		icon = "Interface\\Icons\\INV_Misc_QuestionMark",
	}
}

for i, bg in pairs(byGUID) do
	setmetatable(bg, Battleground)
	byName[bg.name] = bg
end

events:PVPQUEUE_ANYWHERE_SHOW()
