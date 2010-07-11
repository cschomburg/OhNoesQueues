--[[
Feature requests:
- movable join bar
- total honor
- default tab
- localization
]]

local addon, ns = ...

local OhNoesQueues = CreateFrame("Frame", "OhNoesQueues", PVPBattlegroundFrame)
ns.OhNoesQueues = OhNoesQueues

local BG = LibStub("LibBattlegrounds-1.0")
ns.BG = BG

local L = ns.ONQ_L
setmetatable(L, {__index = function(self, k) return k end, __call = function(self, k) return self[k] end})

local colors = {
	["queued"] = { 1, 1, 0 },
	["confirm"] = { 1, 0, 0 },
	["active"] = { 0, 1, 0 },
}

local modules = {}

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

local buttons

BG:RegisterCallback("Status_Updated", OhNoesQueues, function(self)
	if(not buttons) then return end

	for k, button in pairs(buttons) do
		local status = BG(button.name).status

		if(status and colors[status]) then
			button.color:Show()
			button.color:SetVertexColor(unpack(colors[status]))
		else
			button.color:Hide()
		end
	end
end)

function OhNoesQueues:RegisterModule(key, module)
	modules[key] = module or key
end

function OhNoesQueues:Update()
	if(not buttons) then
		buttons = {}
		self.buttons = buttons

		self:CreateButton("Random Battleground", "left")
		self:CreateButton("Call to Arms", "right")

		self:CreateButton("Isle of Conquest")
		self:CreateButton("Warsong Gulch")
		self:CreateButton("Arathi Basin")
		self:CreateButton("Alterac Valley")
		self:CreateButton("Eye of the Storm")
		self:CreateButton("Strand of the Ancients")
	end

	for k, button in pairs(buttons) do
		button:Update()
	end

	PVPBATTLEGROUND_WINTERGRASPTIMER = format("%d |T%s:15:15:0:-5|t   %d |T%s:15:15:0:-5|t|n|cffffffff%%s|r",
		GetItemCount(43589),
		GetItemIcon(43589),
		GetItemCount(43228),
		GetItemIcon(43228)
	)

	for key, module in pairs(modules) do
		if(module.Update) then
			module:Update()
		end
	end
end

OhNoesQueues:RegisterEvent("ADDON_LOADED")
OhNoesQueues:SetScript("OnEvent", function(self, event, addon)
	if(addon ~= "OhNoesQueues") then return end

	self:SetScript("OnShow", self.Update)

	if(self:IsVisible()) then
		self:Update()
	end
end)
