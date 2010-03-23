--[[
Feature requests:
- movable join bar
- total honor
- default tab
- localization
]]

local OhNoesQueues = CreateFrame("Frame", "OhNoesQueues", PVPBattlegroundFrame)

local L = select(2, ...).ONQ_L

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
	local total, won = GetStatistic(info.won), GetStatistic(info.total)
	if(total == "--") then total = 0 else total = tonumber(total) or 0 end
	if(won == "--") then won = 0 else won = tonumber(won) or 0 end
	return won, total
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
--OhNoesQueues:SetFrameLevel(4)
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
			for _, button in pairs(buttons) do
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

function OhNoesQueues:CreateButtons()
	buttons = {}

	buttons.random = self:CreateButton("left")
	buttons.holiday = self:CreateButton("right")

	for i=1, GetNumBattlegroundTypes() do
		local name, canEnter, isHoliday, isRandom = GetBattlegroundInfo(i)
		if(isRandom) then
			buttons.random.id = i
		else
			if(isHoliday) then
				buttons.holiday.id = i
			end
			local button = self:CreateButton()
			button.id = i
			buttons[name] = button
		end
	end

	OhNoesQueues:UPDATE_BATTLEFIELD_STATUS()
	OhNoesQueues:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
end

OhNoesQueues:SetScript("OnShow", function(self)
	if(not buttons) then
		self:CreateButtons()
		self:CreateStats()
	end
	self:UpdateStats()

	for k, button in pairs(buttons) do
		self:UpdateButton(button)
	end

	PVPBATTLEGROUND_WINTERGRASPTIMER = format("%d |T%s:15:15:0:-5|t   %d |T%s:15:15:0:-5|t|n|cffffffff%%s|r",
		GetItemCount(43589),
		GetItemIcon(43589),
		GetItemCount(43228),
		GetItemIcon(43228)
	)
end)