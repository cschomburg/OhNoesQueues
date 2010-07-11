local addon, ns = ...
local OhNoesQueues, BG, L = ns.OhNoesQueues, ns.BG, ns.ONQ_L

-- Why can't Blizz implement this function? :O
local function ColorGradient(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then return r3, g3, b3 elseif perc <= 0 then return r1, g1, b1 end

	local segment, relperc = math.modf(perc*2)
	if segment == 1 then r1, g1, b1, r2, g2, b2 = r2, g2, b2, r3, g3, b3 end
	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local function buttonClick(self, button)
	local status = BG(self.name).status

	if(status == "active") then
		if(button=="RightButton") then
			LeaveBattlefield()
		else
			TogglePVPFrame()
			ToggleWorldStateScoreFrame()
		end
	elseif(status == "queued" or status == "confirm") then
		AcceptBattlefieldPort(BG(self.name).statusID, button ~= "RightButton" and 1)
	else
		BG(self.name):Join(button == "LeftButton" and "group")
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
	GameTooltip:AddLine(self.localized, 1,1,1)
	GameTooltip:AddLine(" ")
	local status, statusID = BG(self.name).status, BG(self.name).statusID

	if(status == "confirm") then
		-- display expiration time
		local time = GetBattlefieldPortExpiration(statusID)
		if(time > 0) then
			GameTooltip:AddLine(formatL("[Expiration time]: #%d s#", time))
		end

		GameTooltip:AddLine(formatL("[Left-click]: #[Accept port]#"))
	end
	if(status == "active") then
		GameTooltip:AddLine(formatL("[Left-click]: #[Open score board]#"))
		GameTooltip:AddLine(formatL("[Right-click]: #[Leave battleground]#"))
	elseif(status == "confirm" or status == "queued") then
		-- display estimated wait time
		local time = GetBattlefieldEstimatedWaitTime(statusID)
		if(time > 0) then
			GameTooltip:AddLine(formatL("[Estimated wait time]: #%s#", getDuration(time)))
		end

		-- display waited time
		local time = GetBattlefieldTimeWaited(statusID)
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
	local win, total = BG(self.button.name):GetWonTotal()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(("|cff00ff00%d|r : |cffff0000%d|r (%d)"):format(win, total-win, total), 1,1,1)
	GameTooltip:Show()
end

local function Button_Update(self)
	local name, canEnter, isHoliday, isRandom, guid = BG(self.name):GetInfo()

	self:Show()
	self.localized = name

	self.icon:SetTexture(BG(self.name).icon)

	self:EnableMouse(canEnter)
	self:SetAlpha(canEnter and 1 or 0.6)

	local faded = not canEnter and 1
	self.icon:SetDesaturated(faded)
	self.border:SetDesaturated(faded)

	if(self.special) then
		local hasWin, winHonor, winArena, lossHonor, lossArena = BG(self.name):GetCurrencyBonus()
		if(winHonor) then
			if(hasWin) then
				self.text:SetTextColor(1, 1, 1, 0.7)
			else
				self.text:SetTextColor(0, 1, 0, 0.7)
			end
			self.text:SetText(OhNoesQueues:FormatUnit(winHonor, "honor").."\n"..OhNoesQueues:FormatUnit(winArena, "arena"))
			self.text:Show()
		else
			self.text:Hide()
		end
	else
		local win, total = BG(self.name):GetWonTotal()
		if(total > 0) then
			local r,g,b = ColorGradient(win/total, 1,0,0, 1,1,0, 0,1,0)
			self.text:SetTextColor(r,g,b, 0.7)
			self.text:SetFormattedText("%d%%", win/total*100)
		else
			self.text:SetText("")
		end
	end
end

local posID = 1
function OhNoesQueues:CreateButton(name, specialDir)
	local button = CreateFrame("Button", nil, self)

	button:SetSize(36, 36)
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

	button.Update = Button_Update

	button.name = name
	table.insert(self.buttons, button)

	if(specialDir) then
		local text = button:CreateFontString(nil, "OVERLAY")
		text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		button.text = text

		button.special = true
		button:SetScale(1.4)

		if(name == "Random Battleground") then
			BG:RegisterCallback("Currency_Updated_RandomBattleground", button, button.Update)
		elseif(name == "Call to Arms") then
			BG:RegisterCallback("Currency_Updated_CallToArms", button, button.Update)
		end

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
		textInfo.button = button

		button:SetPoint("TOPLEFT", 8+posID*45, -310)
		text:SetPoint("TOP", button, "BOTTOM", 0, -10)

		posID = posID + 1
	end

	return button
end
