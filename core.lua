local IDs = {
	20560, -- AV
	20558, -- WS
	20559, -- AB
	29024, -- EotS
	42425, -- IoC
	47395, -- SotA
}

local colors = {
	["queued"] = { 1, 1, 0 },
	["confirm"] = { 1, 0, 0 },
	["active"] = { 0, 1, 0 },
}

--local wgMarks, wgShards = 43589, 43228

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
PVPBattlegroundFrameZoneDescription:Hide()

local frame = CreateFrame("Frame", "OhNoesQueues", PVPBattlegroundFrame)
frame:SetPoint("TOPLEFT", 30, -290)
frame:SetWidth(293)
frame:SetHeight(115)
frame:RegisterEvent("PVPQUEUE_ANYWHERE_SHOW")
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("BAG_UPDATE")
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)

local buttons = {}
local requested

function frame:UPDATE_BATTLEFIELD_STATUS()
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

frame:SetScript("OnShow", function()
	for _, button in ipairs(buttons) do
		local _, canEnter, isHoliday = GetBattlegroundInfo(button.id)
		button:EnableMouse(canEnter)
		button:SetAlpha(canEnter and 1 or 0.6)
		if(canEnter) then
			button.icon:SetDesaturated(nil)
			button.border:SetDesaturated(nil)
			button.marks:Show() -- need some kind of button:SetShown(bool) :/
		else
			button.icon:SetDesaturated(1)
			button.border:SetDesaturated(1)
			button.marks:Hide()
		end
		if(isHoliday and not holidayID == button.id) then
			if(not holidayInd) then createHolidayIndicator() end
			holidayInd:Show()
			holidayInd:SetParent(button)
			holidayInd:ClearAllPoints()
			holidayInd:SetPoint("CENTER", button, "CENTER", 0, 1)
			holidayID = button.id
		elseif(holidayID == button.id) then
			holidayInd:Hide()
		end
	end
end)

-- Win: Blizz' Events-naming
function frame:PVPQUEUE_ANYWHERE_SHOW()
	if(not requested) then return end
	JoinBattlefield(0, (requested == "group" and CanJoinBattlefieldAsGroup() and 1 or 0))
	requested = nil
end

-- Color function for Marks of Honor
local function ColorGradient(perc, r1, g1, b1, r2, g2, b2, r3, g3, b3)
	if perc >= 1 then return r3, g3, b3 elseif perc <= 0 then return r1, g1, b1 end

	local segment, relperc = math.modf(perc*2)
	if segment == 1 then r1, g1, b1, r2, g2, b2 = r2, g2, b2, r3, g3, b3 end
	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end


function frame:BAG_UPDATE()
	for _, button in ipairs(buttons) do
		local marks = GetItemCount(IDs[button.id], true)
		local r,g,b = ColorGradient(marks/30, 1,0,0, 1,1,0, 0,1,0)
		button.marks:SetTextColor(r,g,b, 0.7)
		button.marks:SetText(marks)
	end
end

local function buttonClick(self, button)
	local status = self.status
	if(status == "active" and button == "RightButton") then
		LeaveBattlefield()
	elseif(status == "queued" or status == "confirm") then
		local accept = button ~= "RightButton" and 1
		AcceptBattlefieldPort(self.statusID, accept)
	else
		if(button == "LeftButton") then
			requested = "group"
		else
			requested = "solo"
		end
		PVPBattlegroundFrame.selectedBG = self.id
		RequestBattlegroundInstanceInfo(self.id)
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
	-- not 100% correct
	if(time == 0) then return "< 1 minute" end

	time = math.floor(time/1000)
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
			GameTooltip:AddLine("Expiration time: |cffffffff"..getDuration(time).."|r")
		end

		GameTooltip:AddLine("Left-click: |cffffffffAccept port|r")
	end
	if(status == "active") then
		GameTooltip:AddLine("Right-click: |cffffffffLeave battleground|r")
	elseif(status == "confirm" or status == "queued") then
		-- adding to tooltip the estimated wait time
		local time = GetBattlefieldEstimatedWaitTime(self.statusID)
		if(time > 0) then
			GameTooltip:AddLine("Estimated wait time: |cffffffff"..getDuration(time).."|r")
		end

		-- adding to tooltip the waited time
		local time = GetBattlefieldTimeWaited( self.statusID )
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

function frame:PLAYER_ENTERING_WORLD()
	for i=1, GetNumBattlegroundTypes() do
		local name, canEnter, isHoliday, minlevel = GetBattlegroundInfo(i)

		local button = CreateFrame("Button", nil, frame)
		button:SetWidth(36)
		button:SetHeight(36)
		button:SetPoint("TOPLEFT", 8 + (i-1)*47, -27)

		button:RegisterForClicks("anyUp")

		button:SetScript("OnClick", buttonClick)
		button:SetScript("OnEnter", buttonEnter)
		button:SetScript("OnLeave", buttonLeave)

		local icon = button:CreateTexture(nil, "ARTWORK")
		local iconTexture = select(10, GetItemInfo(IDs[i]))
		icon:SetTexture(iconTexture)
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

		local marks = button:CreateFontString(nil, "OVERLAY")
		marks:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
		marks:SetPoint("TOP", button, "BOTTOM", 0, -10)

		button.id = i
		button.name = name
		button.icon = icon
		button.border = border
		button.color = color
		button.marks = marks
		buttons[i] = button
		buttons[name] = button
	end
	self:UPDATE_BATTLEFIELD_STATUS()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end