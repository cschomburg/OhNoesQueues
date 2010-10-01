--[[
	LibBattlegrounds-2.0
		A library to handle joining and updating of battlegrounds and world pvp areas.
		It provides simple access to battleground data via non-localized names and GUIDs.
]]

local lib = LibStub:NewLibrary("LibBattlegrounds-2.0", 1)
if(not lib) then return end

local byGUID, byName, byLocale
local cta_hasWin, cta_winHonor, cta_winArena, cta_lossHonor, cta_lossArena
local rnd_hasWin, rnd_winHonor, rnd_winArena, rnd_lossHonor, rnd_lossArena


--[[############################################
	Class: Battleground
		Holds all info related to a battleground
##############################################]]

local Battleground = {}
Battleground.__index = Battleground

function Battleground:GetInfo()
	local uid, localizedName, isActive, canQueue, startTime, canEnter, isHoliday, isRandom

	if(self.isWorld) then
		uid, localizedName, isActive, canQueue, startTime, canEnter = GetWorldPVPAreaInfo(self.pvpID)
	else
		localizedName, canEnter, isHoliday, isRandom, uid = GetBattlegroundInfo(self.pvpID)
		canQueue = canEnter
	end

	return localizedName, canQueue, canEnter, isActive, startTime
end

function Battleground:GetWonTotal()
	if(not self.total or not self.won) then return end

	local total, won = GetStatistic(self.total), GetStatistic(self.won)
	return tonumber(won) or 0, tonumber(total) or 0
end

function Battleground:GetQueueStatus() return self.status, self.statusID end
function Battleground:GetIcon() return self.icon end

function Battleground:GetCurrencyBonus()
	if(self == byName["Random Battleground"]) then
		return rnd_hasWin, rnd_winHonor, rnd_winArena, rnd_lossHonor, rnd_lossArena
	elseif(self == byName["Call to Arms"]) then
		return cta_hasWin, cta_winHonor, cta_winArena, cta_lossHonor, cta_lossArena
	end
end

--[[############################################
	Joining battlegrounds
##############################################]]

local joinQueue = {}

function lib:Join(bg, type)
	bg = self:Get(bg)
	bg:Join(type)
end

function Battleground:Join(type)
	joinQueue[self] = type or true
	lib:CheckJoin()
end

function lib:CheckJoin()
	local selectedBG = self:GetSelectedBattleground()

	for bg, joinType in pairs(joinQueue) do
		if(bg.isWorld) then
			joinQueue[bg] = nil
			BattlefieldMgrQueueRequest(bg.uid)
		elseif(bg == selectedBG) then
			joinQueue[bg] = nil
			if(joinType == "wargame") then
				StartWarGame()
			else
				JoinBattlefield(0, joinType == "group" and IsPartyLeader() and CanJoinBattlefieldAsGroup())
			end
		end
	end

	local bg = next(joinQueue)
	if(bg) then
		self:SetSelectedBattleground(bg)
	end
end


--[[############################################
	Join when queue is ready
		(or 'QueueForTheQueue' as I call it =D)
##############################################]]

local readyQueue, nextUpdate = {}, 0
local updater = CreateFrame"Frame"

function lib:JoinWhenReady(bg, type)
	bg = self:Get(bg)
	bg:JoinWhenReady(type)
end

function Battleground:JoinWhenReady(type)
	readyQueue[self] = joinType or true
	nextUpdate = 0
	updater:Show()
end

updater:Hide()
updater:SetScript("OnUpdate", function(self, elapsed)
	nextUpdate = nextUpdate - elapsed
	if(nextUpdate > 0) then return end
	nextUpdate = nil

	for bg, joinType in pairs(readyQueue) do
		local localizedName, canQueue, canEnter, isActive, startTime = bg:GetInfo()
		local newTime

		if(canQueue) then
			readyQueue[bg] = nil
			lib:Join(bg, joinType)
		elseif(startTime) then
			newTime = startTime-bg.queueReady
			if(newTime <= 0) then
				newTime = 1
			end
		else
			newTime = 5*60
		end

		if(newTime) then
			nextUpdate = nextUpdate and math.min(nextUpdate, newTime) or newTime
		end
	end

	if(not nextUpdate) then
		updater:Hide()
	end
end)



--[[############################################
	Callback functions
##############################################]]

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


--[[############################################
	Library functions
##############################################]]

function lib:ToGUID(pvpID, isWorld)
	return isWorld and -pvpID or pvpID
end

function lib:FromGUID(guid)
	if(guid < 0) then
		return -guid, true
	else
		return guid
	end
end


function lib:Get(arg1)
	return byName[arg1]
		or byLocale[arg1]
		or (type(arg1) == "table" and arg1.__index == Battleground and arg1)
end

function lib:PrintBattlegrounds()
	for i=1, GetNumBattlegroundTypes() do
		local name, canEnter, isHoliday, isRandom, uid = GetBattlegroundInfo(i)
		 print(("%d. %s %s%s%s - %d"):format(i, name, canEnter and "" or "[DIS]", isHoliday and "[CTA]" or "", isRandom and "[RND]" or "", uid))
	end
end

function lib:GetSelectedBattleground()
	local pvpID = PVPHonorFrame.selectedPvpID
	local isWorld = PVPHonorFrame.selectedIsWorldPvp and true or nil

	for name, bg in pairs(byName) do
		if(bg.pvpID == pvpID and bg.isWorld == isWorld) then
			return bg, pvpID, isWorld
		end
	end

	return nil, pvpID, isWorld -- this should never happen
end

function lib:SetSelectedBattleground(arg1)
	local bg = self:Get(arg1)
	PVPHonorFrame.selectedPvpID = bg.pvpID
	PVPHonorFrame.selectedIsWorldPvp = bg.isWorld and true

	if(not bg.isWorld) then
		RequestBattlegroundInstanceInfo(bg.pvpID)
	end
end

function lib:UpdateBattlegroundStatus()
	for name, bg in pairs(byName) do
		bg.status = nil
		bg.statusID = nil
	end

	for i=1, MAX_WORLD_PVP_QUEUES do
		local status, name, queueID = GetWorldPVPQueueStatus(i)

		if(status ~= "none") then
			local bg = byLocale[name]
			bg.status = status
			bg.statusID = queueID
		end
	end

	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, name, instanceID, minLevel, maxLevel, teamSize, registeredMatch = GetBattlefieldStatus(i)
		if(teamSize == 0 and status ~= "none") then
			local bg = byLocale[name]
			bg.status = status
			bg.statusID = i
		end
	end

	fire("Status_Updated")	
end

hooksecurefunc("PVP_UpdateStatus", function() lib:UpdateBattlegroundStatus() end)

function lib:UpdateBattlegrounds()
	local cta_old, cta_new = byName["Call to Arms"]

	-- World PvP Areas
	for pvpID=1, GetNumWorldPVPAreas() do
		local uid, localizedName, isActive, canEnter, startTime, canEnter = GetWorldPVPAreaInfo(pvpID)
		local guid = self:ToGUID(uid, true)

		if(byGUID[guid]) then
			local bg = byGUID[guid]
			bg.pvpID = pvpID
			byLocale[localizedName] = bg
		end
	end

	-- Normal Battlegrounds
	for pvpID=1, GetNumBattlegroundTypes() do
		local localizedName, canEnter, isHoliday, isRandom, uid = GetBattlegroundInfo(pvpID)
		local guid = self:ToGUID(uid, nil)

		if(byGUID[guid]) then
			local bg = byGUID[guid]
			bg.pvpID = pvpID
			byLocale[localizedName] = bg
			if(isHoliday) then cta_new = bg end
		end
	end

	fire("IDs_Updated")

	-- Set holiday / call to arms BG
	if(cta_new ~= cta_old) then
		byName["Call to Arms"] = cta_new
		fire("CallToArms_Changed", cta_new, cta_old)
	end

	-- Fetch currency data (it's only available when BG is selected)
	local selectedBG = self:GetSelectedBattleground()
	if(not selectedBG) then return end -- This should never happen

	if(selectedBG == byName["Call to Arms"]) then
		cta_hasWin, cta_winHonor, cta_winArena, cta_lossHonor, cta_lossArena = GetHolidayBGHonorCurrencyBonuses()
		fire("Currency_Updated_CallToArms")
	elseif(selectedBG == byName["Random Battleground"]) then
		rnd_hasWin, rnd_winHonor, rnd_winArena, rnd_lossHonor, rnd_lossArena = GetRandomBGHonorCurrencyBonuses()
		fire("Currency_Updated_RandomBattleground")
	end

	-- Handle join requests
	self:CheckJoin()
end

hooksecurefunc("PVPHonor_UpdateBattlegrounds", function() lib:UpdateBattlegrounds() end)


--[[############################################
	Battleground Data
##############################################]]

byGUID, byLocale, byName = {}, {}, {
	["Alterac Valley"] = {
		uid = 1,
		total = 53,
		won = 49,
		icon = "Interface\\Icons\\Achievement_Zone_DunMorogh",
	},
	["Warsong Gulch"] = {
		uid = 2,
		total = 52,
		won = 105,
		icon = "Interface\\Icons\\Achievement_Zone_Ashenvale_01",
	},
	["Arathi Basin"] = {
		uid = 3,
		total = 55,
		won = 51,
		icon = "Interface\\Icons\\Achievement_Zone_ArathiHighlands_01",
	},
	["Eye of the Storm"] = {
		uid = 7,
		total = 54,
		won = 50,
		icon = "Interface\\Icons\\Achievement_Zone_Netherstorm_01",
	},
	["Strand of the Ancients"] = {
		uid = 9,
		total = 1549,
		won = 1550,
		icon = "Interface\\Icons\\Achievement_BG_WinSoA",
	},
	["Isle of Conquest"] = {
		uid = 30,
		total = 4096,
		won = 4097,
		icon = "",
	},
	["Random Battleground"] = {
		uid = 32,
		icon = "Interface\\Icons\\INV_Misc_QuestionMark",
	},
	["Twin Peaks"] = {
		uid = 108,
		total = 5232,
		win = 5233,
		icon = "Interface\\Icons\\Achievement_Zone_TwilightHighlands",
	},
	["The Battle for Gilneas"] = {
		uid = 120,
		total = 5236,
		win = 5237,
		icon = "Interface\\Icons\\Achievement_Zone_Silverpine_01",
	},

	["Wintergrasp"] = {
		uid = 1,
		icon = "",
		icon = "",
		isWorld = true,
		queueReady = 15*60,
		icon = "Interface\\Icons\\Achievement_Zone_DragonBlight_09",
	},
	["Tol Barad"] = {
		uid = 21,
		icon = "Interface\\Icons\\Achievement_Zone_TolBarad",
		isWorld = true,
		queueReady = 1*60,
	},
}

for name, bg in pairs(byName) do
	local guid = lib:ToGUID(bg.uid, bg.isWorld)
	setmetatable(bg, Battleground)
	byGUID[guid] = bg
	bg.guid = guid
	bg.name = name
end

lib:UpdateBattlegrounds()
lib:UpdateBattlegroundStatus()
