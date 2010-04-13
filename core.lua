--[[
Feature requests:
- movable join bar
- total honor
- default tab
- localization
]]

local OhNoesQueues = CreateFrame("Frame", "OhNoesQueues", PVPBattlegroundFrame)

local L = select(2, ...).ONQ_L
setmetatable(L, {__index = function(self, k) return k end, __call = function(self, k) return self[k] end})

local colors = {
	["queued"] = { 1, 1, 0 },
	["confirm"] = { 1, 0, 0 },
	["active"] = { 0, 1, 0 },
}

local data = {
	[1] = { -- Alterac Valley 
		total = 53,
		won = 49,
		icon = "Interface\\Icons\\INV_Jewelry_Necklace_21",
	},
	[2] = { -- Warsong Gulch
		total = 52,
		won = 105,
		icon = "Interface\\Icons\\INV_Misc_Rune_07",
	},
	[3] = { -- Arathi Basin
		total = 55,
		won = 51,
		icon = "Interface\\Icons\\INV_Jewelry_Amulet_07",
	},
	[7] = { -- Eye of the Storm
		total = 54,
		won = 50,
		icon = "Interface\\Icons\\Spell_Nature_EyeOfTheStorm",
	},
	[9] = { -- Strand of the Ancients
		total = 1549,
		won = 1550,
		icon = "Interface\\Icons\\INV_Jewelry_Amulet_01",
	},
	[30] = { -- Isle of Conquest
		total = 4096,
		won = 4097,
		icon = "Interface\\Icons\\INV_Jewelry_Necklace_27",
	},
	[32] = { -- Random BG
		icon = "Interface\\Icons\\INV_Misc_QuestionMark"
	}
}

function OhNoesQueues:GetBattlegroundIcon(guid)
	return data[guid].icon
end

function OhNoesQueues:GetWinTotal(guid)
	local info = data[guid]
	if(not info or not info.won or not info.total) then return 0, 0 end
	local total, won = GetStatistic(info.total), GetStatistic(info.won)
	return tonumber(won) or 0, tonumber(total) or 0
end

function OhNoesQueues:FormatUnit(value, unit)
	unit = (unit == "arena" and "Interface\\PVPFrame\\PVP-ArenaPoints-Icon") or "Interface\\PVPFrame\\PVP-Currency-"..UnitFactionGroup("player")

	return ("%d |T%s:16:16:0:0|t"):format(value, unit)
end


-- Make room for the unbelievable

for k,v in pairs{
	PVPBattlegroundFrameTypeScrollFrame,
	PVPBattlegroundFrameInfoScrollFrame,
	PVPBattlegroundFrameNameHeader,
	BattlegroundType1,
	BattlegroundType2,
	BattlegroundType3,
	BattlegroundType4,
	BattlegroundType5,
} do
	v:Hide()
	v.Show = v.Hide
end

OhNoesQueues:SetAllPoints(PVPBattlegroundFrame)
OhNoesQueues:RegisterEvent("PVPQUEUE_ANYWHERE_SHOW")
OhNoesQueues:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)

local buttons

function OhNoesQueues:UPDATE_BATTLEFIELD_STATUS()
	for k, button in pairs(buttons) do
		button.color:Hide()
		button.status = "none"
	end
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, name = GetBattlefieldStatus(i)
		if(status ~= "none") then
			for k, button in pairs(buttons) do
				if(button.name == name) then
					button.status = status
					button.statusID = i
					if(colors[status]) then
						button.color:Show()
						button.color:SetVertexColor(unpack(colors[status]))
					end
				end
			end
		end
	end
end

local joinType, requested, reqTwo

-- Win: Blizz' Events-naming
function OhNoesQueues:PVPQUEUE_ANYWHERE_SHOW()
	if(buttons) then self:UpdateButtons() end
	if(not requested) then return end
	JoinBattlefield(0, joinType == "group" and IsPartyLeader() and CanJoinBattlefieldAsGroup())
	requested = nil
	if(reqTwo) then self:Join(joinType, reqTwo) end
end

function OhNoesQueues:Join(type, id, idTwo)
	joinType, requested, reqTwo = type, id, idTwo
	PVPBattlegroundFrame.selectedBG = id
	RequestBattlegroundInstanceInfo(id)
end

function OhNoesQueues:JoinByName(type, name1, name2)
	local id1, id2
	for i=1, GetNumBattlegroundTypes() do
		local name = GetBattlegroundInfo(i)
		if(name1 == name) then id1 = i end
		if(name2 == name) then id2 = i end
	end
	if(id1 or id2) then
		OhNoesQueues:Join(type, id1 or id2, id1 and id2)
	end
end

function OhNoesQueues:CreateButtons()
	buttons = {}

	buttons.random = self:CreateButton("left")
	buttons.holiday = self:CreateButton("right")

	for i=2, GetNumBattlegroundTypes() do
		buttons[i] = self:CreateButton()
		self:SetButtonID(buttons[i], i)
	end

	self:UPDATE_BATTLEFIELD_STATUS()
	self:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
end

function OhNoesQueues:SetButtonID(button, id)
	button.id = id
	local guid = select(5, GetBattlegroundInfo(id))
	if(button.id) then button:Show() end
	if(button.guid == guid) then return end
	button.guid = guid
	self:UpdateButton(button)
end

function OhNoesQueues:UpdateButtons()
	if(not buttons) then self:CreateButtons() end

	buttons.random:Hide()
	buttons.holiday:Hide()

	for i=1, GetNumBattlegroundTypes() do
		local name, canEnter, isHoliday, isRandom, guid = GetBattlegroundInfo(i)
		if(isRandom) then self:SetButtonID(buttons.random, i) end
		if(isHoliday) then self:SetButtonID(buttons.holiday, i) end
		if(buttons[i]) then self:SetButtonID(buttons[i], i) end
	end
end

function OhNoesQueues:PrintBattlegrounds()
	for i=1, GetNumBattlegroundTypes() do
		local name, canEnter, isHoliday, isRandom, textureID = GetBattlegroundInfo(i)
		debug(("%d. %s %s%s%s - %d"):format(i, name, canEnter and "" or "[D]", isHoliday and "[H]" or "", isRandom and "[R]" or "", textureID))
	end
end

function OhNoesQueues:Update()
	self:UpdateButtons()
	self:UpdateStats()

	PVPBATTLEGROUND_WINTERGRASPTIMER = format("%d |T%s:15:15:0:-5|t   %d |T%s:15:15:0:-5|t|n|cffffffff%%s|r",
		GetItemCount(43589),
		GetItemIcon(43589),
		GetItemCount(43228),
		GetItemIcon(43228)
	)
end

OhNoesQueues:SetScript("OnShow", OhNoesQueues.Update)