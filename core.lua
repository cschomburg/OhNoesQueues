local OhNoesQueues = CreateFrame("Frame", "OhNoesQueues", PVPBattlegroundFrame)
local LPVP = LibStub("LibCargPVP")
local colors = {
	["queued"] = { 1, 1, 0 },
	["confirm"] = { 1, 0, 0 },
	["active"] = { 0, 1, 0 },
}

-- Why can't Blizz implement this function? :O
local function ColorGradient(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then return r3, g3, b3 elseif perc <= 0 then return r1, g1, b1 end

	local segment, relperc = math.modf(perc*2)
	if segment == 1 then r1, g1, b1, r2, g2, b2 = r2, g2, b2, r3, g3, b3 end
	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local holidayInd, holidayID
local function createHolidayIndicator()
	holidayInd = CreateFrame("Frame")
	holidayInd:Hide()
	holidayInd:SetWidth(61)
	holidayInd:SetHeight(57)
	holidayInd:SetScale(0.8)
	holidayInd.tex = holidayInd:CreateTexture(nil, "OVERLAY")
	holidayInd.tex:SetTexture([[Interface\ItemSocketingFrame\UI-ItemSockets]])
	holidayInd.tex:SetAllPoints()
	holidayInd.tex:SetTexCoord(0.7578125, 0.9921875, 0, 0.22265625)
end


-- Make room for the unbelievable
local zoneDesc = PVPBattlegroundFrameZoneDescription or PVPBattlegroundFrameZoneDescriptionText
zoneDesc:Hide()

OhNoesQueues:SetPoint("TOPLEFT", 17, -73)
OhNoesQueues:SetWidth(323)
OhNoesQueues:SetHeight(356)
OhNoesQueues:SetFrameLevel(4)
OhNoesQueues:RegisterEvent("PVPQUEUE_ANYWHERE_SHOW")
OhNoesQueues:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)

for i,dir in pairs{"TopLeft", "BottomLeft", "TopRight", "BottomRight"} do
	local tex = OhNoesQueues:CreateTexture(nil, "BACKGROUND")
	tex:SetPoint(dir:upper())
	dir = dir:gsub("Bottom", "Bot") -- Thanks Blizz ...
	tex:SetTexture("Interface\\QuestFrame\\UI-QuestLog-Empty-"..dir)
	tex:SetWidth(i > 2 and 50 or 274)
	tex:SetHeight(i % 2 == 0 and 106 or 256)
	tex:SetTexCoord(0, i > 2 and 0.71875 or 1, 0, i % 2 == 0 and 0.828125 or 1)
end

local infoTexts = {}
OhNoesQueues.InfoTexts = infoTexts
function OhNoesQueues:RegisterInfoText(name, func)
	infoTexts[name] = func
end

local buttons

function OhNoesQueues:UPDATE_BATTLEFIELD_STATUS()
	-- We need this, because Blizz' GetBattlefieldStatus() delivers sometimes funny results ...
	for _, button in ipairs(buttons) do
		button.color:Hide()
		button.status = "none"
	end
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, name = GetBattlefieldStatus(i)
		local button = buttons[name]
		if(button and status ~= "none") then
			button.status = status
			button.statusID = i
			if(colors[status]) then
				button.color:Show()
				button.color:SetVertexColor(unpack(colors[status]))
			end
		end
	end
end

OhNoesQueues:SetScript("OnShow", function(self)
	if(not buttons) then self:CreateButtons() end

	for _, button in ipairs(buttons) do
		-- Can enter
		local _, canEnter, isHoliday = GetBattlegroundInfo(button.id)

		button:EnableMouse(canEnter)
		button:SetAlpha(canEnter and 1 or 0.6)
		if(canEnter) then
			button.icon:SetDesaturated(nil)
			button.border:SetDesaturated(nil)
			button.primText:Show()
			button.secText:Show()
			button.thirdText:Show()
		else
			button.icon:SetDesaturated(1)
			button.border:SetDesaturated(1)
			button.primText:Hide()
			button.secText:Hide()
			button.thirdText:Hide()
		end

		-- Holiday indicator
		if(isHoliday) then
			if(not holidayInd) then createHolidayIndicator() end
			holidayInd:Show()
			holidayInd:SetParent(button)
			holidayInd:ClearAllPoints()
			holidayInd:SetPoint("CENTER", button, "CENTER", 0, 1)
			holidayID = button.id
		elseif(holidayID == button.id) then
			holidayInd:Hide()
		end

		local marks = LPVP.GetBattlegroundMarkCount(button.id)
		local r,g,b = ColorGradient(marks/30, 1,0,0, 1,1,0, 0,1,0)
		button.primText:SetFormattedText("|cff%2x%2x%2x%d|r", r*255,g*255,b*255, marks)

		local xp = LPVP.GetAverageBattlegroundExperience(button.id)
		if(xp) then
			local forLevel = (UnitXPMax("player")-UnitXP("player")) / xp
			local r,g,b = ColorGradient(forLevel/10, 0,1,0, 1,1,0, 1,0,0)
			button.secText:SetFormattedText("|cff%2x%2x%2x%.1f|r", r*255,g*255,b*255, forLevel)
		else
			button.secText:SetText("")
		end

		local win, total = LPVP.GetBattlegroundWinTotal(button.id)
		if(total > 0) then
			local r,g,b = ColorGradient(win/total, 1,0,0, 1,1,0, 0,1,0)
			button.thirdText:SetFormattedText("|cff%2x%2x%2x%d%%|r of %d", r*255, g*255, b*255, win/total*100, total)
		else
			button.thirdText:SetText("")
		end

		-- Wintergrasp mark and shard count
		PVPBATTLEGROUND_WINTERGRASPTIMER = format("%d |T%s:15:15:0:-5|t   %d |T%s:15:15:0:-5|t|n|cffffffff%%s|r",
			GetItemCount(43589),
			GetItemIcon(43589),
			GetItemCount(43228),
			GetItemIcon(43228)
		)
	end
end)

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

local function buttonClick(self, button)
	local status = self.status
	if(status == "active") then
		if(button=="RightButton") then
			LeaveBattlefield()
		else
			if(toggletfs) then
				TogglePVPFrame()
				toggletfs()
			else
				ToggleWorldStateScoreFrame()
			end
		end
	elseif(status == "queued" or status == "confirm") then
		local accept = button ~= "RightButton" and 1
		AcceptBattlefieldPort(self.statusID, accept)
	else
		OhNoesQueues:Join(button == "LeftButton" and "group" or "solo", self.id)
	end
end

-- returns the plural of a measuring unit according to the value
local function plural(value, unit)
	return ("%d %s%s"):format(value, unit, value == 1 and "" or "s")
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

	-- we return time in hours, minutes and seconds
	if(hours > 0) then
		return plural(hours, "hour" )..", "..plural(min, "minute" )..", "..plural(sec, "second")
	elseif(min > 0) then -- we return time in minutes and seconds
		return plural(min, "minute")..", "..plural(sec, "second")
	else -- we return time in seconds
		return plural(sec, "second")
	end
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
			GameTooltip:AddLine("Expiration time: |cffffffff"..plural(time, "second").."|r")
		end

		GameTooltip:AddLine("Left-click: |cffffffffAccept port|r")
	end
	if(status == "active") then
		GameTooltip:AddLine("Left-click: |cffffffffOpen score board|r")
		GameTooltip:AddLine("Right-click: |cffffffffLeave battleground|r")
	elseif(status == "confirm" or status == "queued") then
		-- adding to tooltip the estimated wait time
		local time = GetBattlefieldEstimatedWaitTime(self.statusID)
		if(time > 0) then
			GameTooltip:AddLine("Estimated wait time: |cffffffff"..getDuration(time).."|r")
		end

		-- adding to tooltip the waited time
		local time = GetBattlefieldTimeWaited(self.statusID)
		if(time > 0) then
			GameTooltip:AddLine("Waited time: |cffffffff"..getDuration(time).."|r")
		end

		GameTooltip:AddLine("Right-click: |cffffffffLeave queue|r")
	else
		GameTooltip:AddLine("Left-click: |cffffffffJoin as group or solo|r")
		GameTooltip:AddLine("Right-click: |cffffffffJoin solo|r")
	end
	GameTooltip:Show()
end

local function buttonLeave() GameTooltip:Hide() end

local function textEnter(self)
	if(self.onEnter) then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		self.onEnter(text)
		GameTooltip:Show()
	end
end

function OhNoesQueues:CreateButtons()
	buttons = {}
	local maxBG = GetNumBattlegroundTypes()
	for i=1, maxBG do
		local name, canEnter, isHoliday, minlevel = GetBattlegroundInfo(i)

		local button = CreateFrame("Button", nil, self)
		button:SetWidth(36)
		button:SetHeight(36)

		button:SetPoint("TOP", 0, 25-i*45)

		button:RegisterForClicks("anyUp")

		button:SetScript("OnClick", buttonClick)
		button:SetScript("OnEnter", buttonEnter)
		button:SetScript("OnLeave", buttonLeave)
		button.UpdateTooltip = buttonEnter

		local icon = button:CreateTexture(nil, "ARTWORK")
		local itemTexture = GetItemIcon(LPVP.GetBattlegroundMarkID(i))
		icon:SetTexture(itemTexture)
		icon:SetPoint("CENTER", 0, 3)
		icon:SetWidth(25)
		icon:SetHeight(25)
		
		local border = button:CreateTexture(nil, "OVERLAY")
		border:SetTexture([[Interface\AchievementFrame\UI-Achievement-IconFrame]])
		border:SetPoint("CENTER", -1, 2)
		border:SetWidth(36)
		border:SetHeight(36)
		border:SetTexCoord(0, 0.5625, 0, 0.5625)

		local color = button:CreateTexture(nil, "OVERLAY")
		color:SetTexture"Interface\\Buttons\\UI-ActionButton-Border"
		color:SetBlendMode"ADD"
		color:SetAlpha(1)
		color:SetWidth(65)
		color:SetHeight(65)
		color:SetPoint("CENTER", button, "CENTER", 0, 3)
		color:Hide()

		local primText = button:CreateFontString(nil, "OVERLAY")
		primText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
		primText:SetPoint("LEFT", button, "RIGHT", 30, 0)

		local secText = button:CreateFontString(nil, "OVERLAY")
		secText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		secText:SetPoint("LEFT", primText, "RIGHT", 30, 0)

		local thirdText = button:CreateFontString(nil, "OVERLAY")
		thirdText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
		thirdText:SetPoint("CENTER", button, "LEFT", -70, 0)

		button.id = i
		button.name = name
		button.icon = icon
		button.border = border
		button.color = color

		button.primText = primText
		button.secText = secText
		button.thirdText = thirdText

		buttons[i] = button
		buttons[name] = button
	end
	OhNoesQueues:UPDATE_BATTLEFIELD_STATUS()
	OhNoesQueues:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
end