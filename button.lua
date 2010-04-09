local L = select(2, ...).ONQ_L

-- Why can't Blizz implement this function? :O
local function ColorGradient(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then return r3, g3, b3 elseif perc <= 0 then return r1, g1, b1 end

	local segment, relperc = math.modf(perc*2)
	if segment == 1 then r1, g1, b1, r2, g2, b2 = r2, g2, b2, r3, g3, b3 end
	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local function buttonClick(self, button)
	local status = self.status
	if(status == "active") then
		if(button=="RightButton") then
			LeaveBattlefield()
		else
			TogglePVPFrame()
			ToggleWorldStateScoreFrame()
		end
	elseif(status == "queued" or status == "confirm") then
		AcceptBattlefieldPort(self.statusID, button ~= "RightButton" and 1)
	else
		OhNoesQueues:Join(button == "LeftButton" and "group" or "solo", self.id)
	end
end

-- returns a combination of hours/minutes/seconds from a given number of miliseconds
local function getDuration(time)
	-- treating something that is returned as 0ms from GetBattlefieldEstimatedWaitTime
	-- when you join a BG for which there are no instances existing
	-- I noticed that the values returned are below 800ms usually
	-- so treating this better than the previous one
	if(time < 800) then return "< 1 minute" end

	time = floor(time/1000)
	local sec = mod(time, 60)
	local min = mod(floor(time / 60), 60)
	local hours = floor(time / 3600)

	if(hours > 0) then
		return ("%d:%d:%d h"):format(hours, min, sec)
	elseif(min > 0) then
		return ("%d:%d min"):format(min, sec)
	else
		return ("%d s"):format(sec)
	end
end

local function formatL(string, ...)
	return string:gsub("%[(.-)%]", L):gsub("#(.-)#", "|cffffffff%1|r"):format(...)
end

local function buttonEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(self.name, 1,1,1)
	GameTooltip:AddLine(" ")
	local status = self.status
	if(status == "confirm") then
		-- adding expiration time
		local time = GetBattlefieldPortExpiration(self.statusID)
		if(time > 0) then
			GameTooltip:AddLine(formatL("[Expiration time]: #%d s#", time))
		end

		GameTooltip:AddLine(formatL("[Left-click]: #[Accept port]#"))
	end
	if(status == "active") then
		GameTooltip:AddLine(formatL("[Left-click]: #[Open score board]#"))
		GameTooltip:AddLine(formatL("[Right-click]: #[Leave battleground]#"))
	elseif(status == "confirm" or status == "queued") then
		-- adding to tooltip the estimated wait time
		local time = GetBattlefieldEstimatedWaitTime(self.statusID)
		if(time > 0) then
			GameTooltip:AddLine(formatL("[Estimated wait time]: #%s#", getDuration(time)))
		end

		-- adding to tooltip the waited time
		local time = GetBattlefieldTimeWaited(self.statusID)
		if(time > 0) then
			GameTooltip:AddLine(formatL("[Waited time]: #%s#", getDuration(time)))
		end

		GameTooltip:AddLine(formatL("[Right-click]: #[Leave queue]#"))
	else
		GameTooltip:AddLine(formatL("[Left-click]: #[Join as group or solo]#"))
		GameTooltip:AddLine(formatL("[Right-click]: #[Join solo]#"))
	end
	GameTooltip:Show()
end

local function tooltip_Hide() GameTooltip:Hide() end

local function winStats_Show(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(("|cff00ff00%d|r : |cffff0000%d|r (%d)"):format(self.win, self.total-self.win, self.total), 1,1,1)
	GameTooltip:Show()
end

local posID = 1
function OhNoesQueues:CreateButton(specialDir)
	local button = CreateFrame("Button", nil, self)

	button:SetWidth(36)
	button:SetHeight(36)

	button:RegisterForClicks("anyUp")

	button:SetScript("OnClick", buttonClick)
	button:SetScript("OnEnter", buttonEnter)
	button:SetScript("OnLeave", tooltip_Hide)
	button.UpdateTooltip = buttonEnter

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("CENTER", 0, 3)
	icon:SetWidth(25)
	icon:SetHeight(25)
	
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture[[Interface\AchievementFrame\UI-Achievement-IconFrame]]
	border:SetPoint("CENTER", -1, 2)
	border:SetWidth(36)
	border:SetHeight(36)
	border:SetTexCoord(0, 0.5625, 0, 0.5625)

	local color = button:CreateTexture(nil, "OVERLAY")
	color:SetTexture[[Interface\Buttons\UI-ActionButton-Border]]
	color:SetBlendMode"ADD"
	color:SetAlpha(1)
	color:SetWidth(65)
	color:SetHeight(65)
	color:SetPoint("CENTER", button, "CENTER", 0, 3)
	color:Hide()

	button.icon = icon
	button.border = border
	button.color = color

	if(specialDir) then
		local text = button:CreateFontString(nil, "OVERLAY")
		text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		button.text = text

		button.special = true
		button:SetScale(1.4)

		if(specialDir == "left") then
			button:SetPoint("TOPLEFT", 85, -150)
			text:SetPoint("RIGHT", button, "LEFT", -10, 0)
		else
			button:SetPoint("TOPLEFT", 135, -150)
			text:SetPoint("LEFT", button, "RIGHT", 10, 0)
		end
	else
		local text = button:CreateFontString(nil, "OVERLAY")
		text:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
		button.text = text

		local textInfo = CreateFrame("Frame", nil, button)
		textInfo:EnableMouse(true)
		textInfo:SetAllPoints(text)
		textInfo:SetScript("OnEnter", winStats_Show)
		textInfo:SetScript("OnLeave", tooltip_Hide)
		button.textInfo = textInfo

		button:SetPoint("TOPLEFT", 8+posID*45, -310)
		text:SetPoint("TOP", button, "BOTTOM", 0, -10)

		posID = posID + 1
	end

	return button
end

function OhNoesQueues:UpdateButton(button)
	if(not button.id) then return button:Hide() end

	local name, canEnter, isHoliday, isRandom, guid = GetBattlegroundInfo(button.id)

	button:Show()
	button.name = name

	button.icon:SetTexture(self:GetBattlegroundIcon(guid))

	button:EnableMouse(canEnter)
	button:SetAlpha(canEnter and 1 or 0.6)
	if(canEnter) then
		button.icon:SetDesaturated(nil)
		button.border:SetDesaturated(nil)
	else
		button.icon:SetDesaturated(1)
		button.border:SetDesaturated(1)
	end

	if(button.special) then
		local func = isHoliday and GetHolidayBGHonorCurrencyBonuses or GetRandomBGHonorCurrencyBonuses
		local hasWin, winHonor, winArena, lossHonor, lossArena = func()
		if(hasWin) then
			button.text:SetTextColor(1, 1, 1, 0.7)
		else
			button.text:SetTextColor(0, 1, 0, 0.7)
		end
		button.text:SetText(self:FormatUnit(winHonor, "honor").."\n"..self:FormatUnit(winArena, "arena"))
	else
		local win, total = self:GetWinTotal(guid)
		button.textInfo.win, button.textInfo.total = win, total
		if(total > 0) then
			local r,g,b = ColorGradient(win/total, 1,0,0, 1,1,0, 0,1,0)
			button.text:SetTextColor(r,g,b, 0.7)
			button.text:SetFormattedText("%d%%", win/total*100)
		else
			button.text:SetText("")
		end
	end
end