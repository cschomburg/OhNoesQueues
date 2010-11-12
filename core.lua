local addon, ns = ...

local LBG = LibStub("LibBattlegrounds-2.0")

local OhNoesQueues = CreateFrame("Frame", "OhNoesQueues", PVPFrame)

function OhNoesQueues:Init()
	self:SetScript("OnShow", nil)
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("PARTY_LEADER_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")

	-- Prevent PVPFrame from closing when leaving a queue
	PVPFrame:UnregisterEvent("BATTLEFIELDS_CLOSED")

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

	hooksecurefunc("PVPFrame_TabClicked", function(self)
		if(self:GetID() ~= tabID) then return OhNoesQueues:Hide() end

		OhNoesQueues:Show()
		PVPFrame.lastSelectedTab = self
		PVPFrameLowLevelFrame:Hide()
		PVPFrameLeftButton:Hide()
		PVPFrameTypeLabel:SetText(HONOR)
		PVPFrameTypeLabel:SetPoint("TOPRIGHT", -180, -38)
		PVPFrameConquestBar:Hide()
		PVPFrameTypeIcon:SetTexture("Interface\\PVPFrame\\PVPCurrency-Honor-"..UnitFactionGroup("player"))
		PVPFrame_UpdateCurrency(self, select(2, GetCurrencyInfo(HONOR_CURRENCY)))
	end)
	PVPFrame_TabClicked(tab)

	--[[
		Battlegrounds
	]]

	local random = self.Buttons:Create("Random Battleground")
	random:SetScale(1.2)
	random:SetPoint("TOPRIGHT", self, "TOP", -15, -25)

	local cta = self.Buttons:Create("Call to Arms")
	cta:SetScale(1.2)
	cta:SetPoint("TOPLEFT", self, "TOP", 15, -25)

	local wg = self.Buttons:Create("Wintergrasp")
	wg:SetScale(1.2)
	wg:SetPoint("TOPRIGHT", self, "TOP", -15, -85)

	local tb = self.Buttons:Create("Tol Barad")
	tb:SetScale(1.2)
	tb:SetPoint("TOPLEFT", self, "TOP", 15, -85)

	for i, bgName in pairs{
		"Warsong Gulch", "Arathi Basin", "Alterac Valley", "Eye of the Storm",
		"Strand of the Ancients", "Isle of Conquest", "Twin Peaks", "The Battle for Gilneas",
	} do
		self.Buttons:Create(bgName):SetPoint("BOTTOMLEFT",
			((i-1) % 4) * 65 + 45,
			math.floor((i-1)/4) * -65 + 120.
		)
	end

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
	for i=1, 3 do
		local button = CreateFrame("Button", nil, OhNoesQueues)
		button:SetNormalFontObject("GameFontHighlight")
		button:SetDisabledFontObject("GameFontNormal")
		button:SetHighlightFontObject("ONQ_HiFont")
		button:SetSize(60, 20)
		button:SetScript("OnClick", typeButton_OnClick)
		typeButtons[i] = button
	end

	typeButtons[1]:SetPoint("BOTTOMLEFT", 20, -2)
	typeButtons[2]:SetPoint("BOTTOM", 0, -2)
	typeButtons[3]:SetPoint("BOTTOMRIGHT", -20, -2)

	typeButtons[1].type = "solo"
	typeButtons[2].type = "group"
	typeButtons[3].type = "wargame"

	typeButtons[1].text = "Solo"
	typeButtons[2].text = "Group"
	typeButtons[3].text = "War Game"

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
	if((GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0) and IsPartyLeader()) then
		self.TypeButtons[2]:Enable()
		if(UnitIsPlayer("target")) then
			self.TypeButtons[3]:Enable()
			self:SetJoinType("wargame")
		else
			self.TypeButtons[3]:Disable()
			self:SetJoinType("group")
		end
	else
		self.TypeButtons[2]:Disable()
		self.TypeButtons[3]:Disable()
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
