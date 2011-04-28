--[[
	LibBattlegrounds-2.0
		A library to handle joining and updating of battlegrounds and world pvp areas.
		It provides simple access to battleground data via non-localized names and GUIDs.
]]

local lib = LibStub:NewLibrary("LibBattlegrounds-2.0", 1)
if(not lib) then return end

local byGUID, byName, byLocale

local Battleground = {}
Battleground.__index = Battleground

--[[############################################
	Generic Battleground Info
##############################################]]

function Battleground:GetInfo()
	if(not self.pvpID) then return end

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

function Battleground:GetCurrencyBonuses()
	if(self == byName["Random Battleground"]) then
		return true, GetRandomBGHonorCurrencyBonuses()
	elseif(self == byName["Call to Arms"]) then
		return true, GetHolidayBGHonorCurrencyBonuses
	else
		return nil
	end
end

function lib:HasReducedBonuses()
	return GetRandomBGHonorCurrencyBonuses() or GetHolidayBGHonorCurrencyBonuses()
end

function lib:BattlefieldIsBattleground(i)
	local status, name, instanceID, minLevel, maxLevel, teamSize, registeredMatch = GetBattlefieldStatus(i)
	local isInstance, instanceType = IsInInstance()
	if (not status or status == "none" or name == "All Arenas" or (status == "active" and instanceType ~= "pvp")) then
		return false
	else
		return true
	end
end

--[[############################################
	Interacting with battlegrounds
##############################################]]

local joinQueue, readyQueue, nextUpdate = {}, {}, 0
local updater = CreateFrame("Frame")

function Battleground:Join(type, noWait)
	self.joinType = type or true

	if(noWait) then
		joinQueue[self] = true
		lib:CheckJoin()
	else
		readyQueue[self] = true
		nextUpdate = 0
		updater:Show()
	end

	lib:UpdateStatus()
end

function Battleground:Leave()
	local status, statusID = self:GetQueueStatus()
	self.joinType = nil

	if(self.isWorld) then
		if(status == "wait") then
			readyQueue[self] = nil
			lib:UpdateStatus()
		elseif(status == "queued") then
			BattlefieldMgrExitRequest(self.statusID)
		end
	else
		if(status == "wait") then
			readyQueue[self] = nil
			lib:UpdateStatus()
		elseif(status == "queued" or status == "confirm") then
			AcceptBattlefieldPort(statusID, 0)
		elseif(status == "active") then
			LeaveBattlefield()
		end
	end
end

function Battleground:Enter()
	local status, statusID = self:GetQueueStatus()
	if(status == "confirm") then
		if(self.isWorld) then
			BattlefieldMgrEntryInviteResponse(statusID)
		else
			AcceptBattlefieldPort(statusID, 1)
		end
	end
end

function lib:CheckJoin()
	local selectedBG = self:GetSelectedBattleground()
	
	for bg in pairs(joinQueue) do
		if(bg.isWorld) then
			joinQueue[bg] = nil
			BattlefieldMgrQueueRequest(bg.uid)
			bg.joinType = nil
		elseif(bg == selectedBG) then
			joinQueue[bg] = nil

			if(bg.joinType == "wargame") then
				StartWarGame()
			else
				JoinBattlefield(0, bg.joinType == "group" and IsPartyLeader())
			end
			bg.joinType = nil
		end
	end

	local bg = next(joinQueue)
	if(bg) then
		self:SetSelectedBattleground(bg)
	end
end

updater:Hide()
updater:SetScript("OnUpdate", function(self, elapsed)
	nextUpdate = nextUpdate - elapsed
	if(nextUpdate > 0) then return end
	nextUpdate = nil

	for bg in pairs(readyQueue) do
		local localizedName, canQueue, canEnter, isActive, startTime = bg:GetInfo()
		local newTime

		if(canQueue) then
			readyQueue[bg] = nil
			bg:Join(bg.joinType, true)
		elseif(startTime) then
			newTime = startTime-(bg.queueReady or 0)
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

function lib:UpdateStatus()
	for name, bg in pairs(byName) do
		bg.status = bg.joinType and "wait" or nil
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
		if(lib:BattlefieldIsBattleground(i)) then
			local bg = byLocale[name]
			bg.status = status
			bg.statusID = i
		end
	end

	fire("Status_Updated")
end

local function events_OnEvent(self, event, ...)
	if(event == "PLAYER_ENTERING_WORLD") then
		PVPHonorFrame_ResetInfo()
	else
		lib:UpdateStatus()
	end
end

local events = CreateFrame("Frame")
events:SetScript("OnEvent", events_OnEvent)
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
events:RegisterEvent("BATTLEFIELD_MGR_QUEUE_REQUEST_RESPONSE")
events:RegisterEvent("BATTLEFIELD_MGR_QUEUE_INVITE")
events:RegisterEvent("BATTLEFIELD_MGR_ENTRY_INVITE")
events:RegisterEvent("BATTLEFIELD_MGR_EJECT_PENDING")
events:RegisterEvent("BATTLEFIELD_MGR_EJECTED")
events:RegisterEvent("BATTLEFIELD_MGR_ENTERED")

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
		icon = "Interface\\Icons\\Achievement_Zone_BoreanTundra_01",
	},
	["Random Battleground"] = {
		uid = 32,
		icon = "Interface\\Icons\\INV_Misc_QuestionMark",
	},
	["Twin Peaks"] = {
		uid = 108,
		total = 5232,
		won = 5233,
		icon = "Interface\\Icons\\Achievement_Zone_TwilightHighlands",
	},
	["The Battle for Gilneas"] = {
		uid = 120,
		total = 5236,
		won = 5237,
		icon = "Interface\\Icons\\Achievement_Battleground_BattleForGilneas",
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
		queueReady = 15*60,
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
lib:UpdateStatus()
