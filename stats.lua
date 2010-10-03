local addon, ns = ...
local LBG = LibStub("LibBattlegrounds-2.0")

local Stats = {}
OhNoesQueues.Stats = Stats

local backdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
}
local backdropColor = { 0, 0, 0, 0.8 }

local statusTexts = {
	["wait"] = "|cffffcc00waiting|r",
	["queued"] = "|cffffff80queued|r",
	["confirm"] = "|cffff8080ready|r",
	["active"] = "|cff80ff80active|r",
}

local display

function Stats.Show(frame)
	if(not display) then display = Stats:Create() end
	display.bg = frame.bg

	local pos = select(2, frame:GetCenter()) * frame:GetScale() - OhNoesQueues:GetBottom()
	display:ClearAllPoints()
	if(pos > OhNoesQueues:GetHeight()/2) then
		display:SetPoint("BOTTOM", 0, 20)
	else
		display:SetPoint("TOP")
	end

	display:Show()
	display:Update()
end

function Stats.Hide(frame)
	display.bg = nil
	display:Hide()
end

local function Display_Update(self)
	if(not self.bg) then return end
	local bg = self.bg

	local localized = bg:GetInfo()
	local status = bg:GetQueueStatus()
	status = status and statusTexts[status]
	self.caption:SetText(status and ("%s (%s)"):format(localized, status) or localized)
end

function Stats:Create()
	local width = OhNoesQueues:GetWidth()

	local display = CreateFrame("Frame", nil, OhNoesQueues)
	display:SetFrameLevel(OhNoesQueues:GetFrameLevel() + 2)
	display:Hide()
	display:SetSize(width, 40)
	display:SetBackdrop(backdrop)
	display:SetBackdropColor(unpack(backdropColor))

	local caption = display:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	caption:SetPoint("TOP", 0, -10)

	display.caption = caption
	display.Update = Display_Update

	LBG:RegisterCallback("Status_Updated", display, display.Update)

	return display
end
