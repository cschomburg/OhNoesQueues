local L = {
	["Alterac Valley"] = true,
	["Arathi Basin"] = true,
	["Eye of the Storm"] = true,
	["Isle of Conquest"] = true,
	["Strand of the Ancients"] = true,
	["Warsong Gulch"] = true,
}
for k,v in pairs(L) do
	if(v == true) then
		L[k] = k
	end
end

local colors = {
	["queued"]	= { 1, 1, 0 },
	["confirm"] = { 1, 0, 0 },
	["active"]	= { 0, 1, 0 },
}

local IDs = {
	["Alterac Valley"] = 20560,
	["Arathi Basin"] = 20559,
	["Eye of the Storm"] = 29024,
	["Isle of Conquest"] = 47395,
	["Strand of the Ancients"] = 42425,
	["Warsong Gulch"] = 20558,
}


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
frame.Locale = L

local buttons = {}
local requested

function frame:UPDATE_BATTLEFIELD_STATUS()
	for _, button in ipairs(buttons) do
		button.color:Hide()
		local _, canEnter = GetBattlegroundInfo(button.id)
		canEnter = not canEnter and 1 or nil
		if(canEnter) then
			button:SetAlpha(0.6)
			button:EnableMouse(nil)
			button.icon:SetDesaturated(1)
			button.border:SetDesaturated(1)
			button.marks:Hide()
		else
			button:SetAlpha(1)
			button:EnableMouse(true)
			button.icon:SetDesaturated(nil)
			button.border:SetDesaturated(nil)
			button.marks:Show()
		end
	end
	for i=1, MAX_BATTLEFIELD_QUEUES do
		local status, name = GetBattlefieldStatus(i)
		local button = buttons[name]
		if(button) then
			button.status = status
			button.statusID = i
			if(colors[status]) then
				button.color:Show()
				button.color:SetVertexColor(unpack(colors[status]))
			else
				button.color:Hide()
			end
		end
	end
end

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
		if(L[button.name]) then
			local marks = GetItemCount(IDs[L[button.name]], true)
			if(marks) then
				local r,g,b = ColorGradient(marks/30, 1,0,0, 1,1,0, 0,1,0)
				button.marks:SetTextColor(r,g,b, 0.7)
				button.marks:SetText(marks)
			end
		end
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

local function buttonEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(self.name, 1,1,1)
	GameTooltip:AddLine(" ")
	local status = self.status
	if(status == "confirm") then
		GameTooltip:AddLine("Left-click: |cffffffffAccept port|r")
	end
	if(status == "active") then
		GameTooltip:AddLine("Right-click: |cffffffffLeave battleground|r")
	elseif(status == "confirm" or status == "queued") then
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
		if(L[name]) then
			local iconTexture = select(10, GetItemInfo(IDs[L[name]]))
			icon:SetTexture(iconTexture)
		end
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
