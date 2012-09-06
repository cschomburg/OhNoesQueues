local addon, ns = ...

local LBG = LibStub("LibBattlegrounds-2.0")

local OhNoesQueues = CreateFrame("Frame", "OhNoesQueues", PVPFrame)

function OhNoesQueues:Init()
	self:SetScript("OnShow", nil)
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("PARTY_LEADER_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")

	--[[
		Main Layout
	]]
	self:Hide()
	self:SetPoint("TOPLEFT", 8, -64)
	self:SetPoint("BOTTOMRIGHT", -11, 6)

	local width, height = self:GetSize()

	for anchor, pos in pairs{
			TOPLEFT = "TopLeft",			-- It would be such much easier
			BOTTOMLEFT = "BotLeft",			-- if we just could write
			TOPRIGHT = "TopRight",			--  anchor = pos:upper()
			BOTTOMRIGHT = "BotRight"		-- Blizz :/
	} do
		local tex = OhNoesQueues:CreateTexture(nil, "BACKGROUND")
		tex:SetTexture("Interface\\QuestFrame\\UI-QuestLog-Empty-"..pos)
		tex:SetPoint(anchor)
		tex:SetVertexColor(0.7, 0.7, 0.7)

		local tcRight, tcBottom
		if(pos:find("Left")) then
			tex:SetWidth(256/302*width)
			tcRight = 1
		else
			tex:SetWidth(46/302*width)
			tcRight = 0.71875
		end

		if(pos:find("Top")) then
			tex:SetHeight(256/356*height)
			tcBottom = 1
		else
			tex:SetHeight(106/356*height)
			tcBottom = 0.828125
		end

		tex:SetTexCoord(0, tcRight, 0, tcBottom)
	end

	--[[
		Battlegrounds
	]]

	for i, bgName in pairs{"Random Battleground", "Call to Arms",
		"Wintergrasp", "Tol Barad"
	} do
		local bg = self.Buttons:Create(bgName)
		bg:SetScale(1.2)
		bg:SetPoint("TOPLEFT", self, "TOPLEFT", 55, -25 - (i-1)*60)
	end

	for i, bgName in pairs{
		"Warsong Gulch", "Arathi Basin", "Alterac Valley", "Eye of the Storm",
		"Strand of the Ancients", "Isle of Conquest", "Twin Peaks", "The Battle for Gilneas",
		"Silvershard Mines", "Temple of Kotmogu",
	} do
		self.Buttons:Create(bgName):SetPoint("TOPRIGHT",
			(i > 5 and -45 or -105),
			((i-1) % 5) * -60 - 20
		)
	end

	--[[
		Tab Setup
	]]

	local tabID = 4; while(_G["PVPFrameTab"..tabID]) do tabID = tabID+1 end
	local tab = CreateFrame("Button", "PVPFrameTab"..tabID, PVPFrame, "CharacterFrameTabButtonTemplate")
	PVPFrame.numTabs = tabID
	PVPFrame["panel"..tabID] = OhNoesQueues
	tab:SetID(tabID)
	tab:SetText("ONQ")
	tab:SetScript("OnClick", PVPFrameTab1:GetScript("OnClick"))
	tab:SetPoint(PVPFrameTab1:GetPoint())
	PVPFrameTab1:SetPoint("LEFT", tab, "RIGHT", -15, 0)
	tab:GetScript("OnShow")(tab)

	-- Shorten War Games tab
	PVPFrameTab4Text:SetText("War")
	PVPFrameTab4:SetWidth(50)
	PVPFrameTab4:Hide() -- force layout update
	PVPFrameTab4:Show()

	hooksecurefunc("PVPFrame_TabClicked", function(self)
		if(self:GetID() ~= tabID) then return OhNoesQueues:Hide() end
		PVPHonorFrame_ResetInfo()
		OhNoesQueues:Show()
		PVPFrame.lastSelectedTab = self
		PVPFrameLowLevelFrame:Hide()
		PVPFrameLeftButton:Hide()
		PVPFrameCurrencyLabel:SetText(HONOR)
		PVPFrameCurrency:SetPoint("TOP", 0, -20)
		PVPFrameConquestBar:Hide()
		PVPFrameCurrencyIcon:SetTexture("Interface\\PVPFrame\\PVPCurrency-Honor-"..UnitFactionGroup("player"))
		PVPFrame_UpdateCurrency(self, select(2, GetCurrencyInfo(HONOR_CURRENCY)))
	end)
	PVPFrame_TabClicked(tab)

	--[[
		JoinType Bar
	]]

	local hiFont = CreateFont("ONQ_HiFont")
	hiFont:CopyFontObject("GameFontHighlight")
	hiFont:SetTextColor(0.7, 1, 1)

	local function typeButton_OnClick(self)
		OhNoesQueues:SetJoinType(self.type)
	end

	local typeButtons = {}
	for i=1, 2 do
		local button = CreateFrame("Button", nil, OhNoesQueues)
		button:SetNormalFontObject("GameFontHighlight")
		button:SetDisabledFontObject("GameFontNormal")
		button:SetHighlightFontObject("ONQ_HiFont")
		button:SetSize(60, 20)
		button:SetScript("OnClick", typeButton_OnClick)
		typeButtons[i] = button
	end

	typeButtons[1]:SetPoint("BOTTOMLEFT", 60, -2)
	typeButtons[2]:SetPoint("BOTTOMRIGHT", -60, -2)

	typeButtons[1].type = "solo"
	typeButtons[2].type = "group"

	typeButtons[1].text = "Solo"
	typeButtons[2].text = "Group"

	self.TypeButtons = typeButtons
	self:UpdateJoinType()
end

function OhNoesQueues:SetJoinType(type)
	self.joinType = type
	for i, button in pairs(self.TypeButtons) do
		if(button.type == type) then
			button:SetText("|cff00ff00"..button.text.."|r")
		elseif(button:IsEnabled()) then
			button:SetText(button.text)
		else
			button:SetText("|cff808080"..button.text.."|r")
		end
	end
end

function OhNoesQueues:UpdateJoinType()
	if(IsInGroup() and UnitIsGroupLeader("player")) then
		self.TypeButtons[2]:Enable()
		self:SetJoinType("group")
	else
		self.TypeButtons[2]:Disable()
		self:SetJoinType("solo")
	end
end

function OhNoesQueues:ADDON_LOADED(event, name)
	if(name ~= addon) then return end

	if(self:IsVisible()) then
		self:Init()
	else
		self:SetScript("OnShow", self.Init)
	end
end

OhNoesQueues:SetScript("OnEvent", function(self, event, ...)
	if(event == "ADDON_LOADED") then
		local name = ...
		if(name ~= addon) then return end
		if(self:IsVisible()) then
			self:Init()
		else
			self:SetScript("OnShow", self.Init)
		end
	else
		self:UpdateJoinType()
	end
end)
OhNoesQueues:RegisterEvent("ADDON_LOADED")
