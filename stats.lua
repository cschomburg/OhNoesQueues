local addon, ns = ...
local LBG = LibStub("LibBattlegrounds-2.0")

-- Why can't Blizz implement this function? :O
local function ColorGradient(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then return r3, g3, b3 elseif perc <= 0 then return r1, g1, b1 end

	local segment, relperc = math.modf(perc*2)
	if segment == 1 then r1, g1, b1, r2, g2, b2 = r2, g2, b2, r3, g3, b3 end
	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end



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
	local height = 0

	local localized, canQueue, canEnter, isActive, startTime  = bg:GetInfo()
	local status = bg:GetQueueStatus()
	status = status and statusTexts[status]
	self.caption:SetText(status and ("%s (%s)"):format(localized, status) or localized)
	height = height + 40

	local win, total = bg:GetWonTotal()
	if(total and total > 0) then
		height = height + 30
		display.wins:Show()
		display.losses:Show()
		display.wintotal:Show()

		display.wins:SetText(win)
		display.losses:SetText(total - win)
		local r,g,b = ColorGradient(win/total, 1,0,0, 1,1,0, 0,1,0)
		display.wintotal:SetFormattedText("|cff%2x%2x%2x%.0f%%|r of %d", r*255, g*255, b*255, win/total*100, total)
	else
		display.wins:Hide()
		display.losses:Hide()
		display.wintotal:Hide()
	end

	if(bg.isWorld) then
		if(isActive) then
			height = height + 30
			display.wintotal:Show()
			display.wintotal:SetText(YELLOW_FONT_COLOR_CODE..WINTERGRASP_IN_PROGRESS..FONT_COLOR_CODE_CLOSE)
		elseif(startTime > 0) then
			height = height + 30
			display.wintotal:Show()
			if(canQueue) then
				display.wintotal:SetText(GREEN_FONT_COLOR_CODE..SecondsToTime(startTime)..FONT_COLOR_CODE_CLOSE)
			else
				display.wintotal:SetText(GRAY_FONT_COLOR_CODE..SecondsToTime(startTime)..FONT_COLOR_CODE_CLOSE)
			end
		else
			display.wintotal:Hide()
		end
	end

	display:SetHeight(height)
end

function Stats:Create()
	local width = OhNoesQueues:GetWidth()

	local display = CreateFrame("Frame", nil, OhNoesQueues)
	display:SetFrameLevel(OhNoesQueues:GetFrameLevel() + 2)
	display:Hide()
	display:SetWidth(width)
	display:SetBackdrop(backdrop)
	display:SetBackdropColor(unpack(backdropColor))

	local caption = display:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	caption:SetPoint("TOP", 0, -10)

	local wins = display:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	wins:SetTextColor(0, 1, 0)
	wins:SetPoint("BOTTOMLEFT", width * 1/4, 10)

	local losses = display:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	losses:SetTextColor(1, 0, 0)
	losses:SetPoint("BOTTOMRIGHT", width * -1/4, 10)

	local wintotal = display:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	wintotal:SetPoint("BOTTOM", 0, 10)

	display.caption = caption
	display.wins = wins
	display.losses = losses
	display.wintotal = wintotal
	display.Update = Display_Update

	LBG:RegisterCallback("Status_Updated", display, display.Update)

	return display
end
