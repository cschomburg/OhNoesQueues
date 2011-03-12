local addon, ns = ...

local LBG = LibStub("LibBattlegrounds-2.0")

local Buttons = {}
OhNoesQueues.Buttons = Buttons

local glowColors = {
	["wait"] = { 1, 0.8, 0.5 },
	["queued"] = { 1, 1, 0.5 },
	["confirm"] = { 1, 0.5, 0.5 },
	["active"] = { 0.5, 1, 0.5 },
}

local function Button_SetBattleground(self, bgName)
	self.bgName = bgName
	self:Update()
end

local function Button_Update(self)
	local bg = self.bgName and LBG:Get(self.bgName)
	self.bg = bg

	if(bg) then
		local lName, canQueue, canEnter, isActive, startTime = bg:GetInfo()

		self.icon:SetTexture(bg:GetIcon())

		if(canEnter) then
			self:Enable()
			self:SetAlpha(1)
		else
			self:Disable()
			self:SetAlpha(0.2)
			self.icon:SetDesaturated()
		end
	else
		self:Disable()
		self:SetAlpha(0.3)
		self.icon:SetTexture()
	end

	self:UpdateStatus()
end

local function Button_UpdateStatus(self)
	if(not self.bg) then return end

	local status, statusID = self.bg:GetQueueStatus()
	if(status and glowColors[status]) then
		self.glow:Show()
		self.glow:SetVertexColor(unpack(glowColors[status]))
	else
		self.glow:Hide()
	end

	local hasBonuses, hasWin, winHonor, winArena, lossHonor, lossArena = self.bg:GetCurrencyBonuses()
	if(hasBonuses and not LBG:HasReducedBonuses()) then
		if(not self.shine) then
			local shine = SpellBook_GetAutoCastShine()
			shine:SetParent(self)
			shine:SetPoint("CENTER", self, "CENTER")
			AutoCastShine_AutoCastStart(shine, 0, 1)
			self.shine = shine
		end
		self.shine:Show()
	elseif(self.shine) then
		self.shine:Hide()
		SpellBook_ReleaseAutoCastShine(self.shine)
		self.shine = nil
	end
end

local function Button_OnClick(self, button)
	local status, statusID = self.bg:GetQueueStatus()

	if(status == "active") then
		if(button == "RightButton") then
			self.bg:Leave()
		elseif(self.bg.isWorld) then
			TogglePVPFrame()
			ToggleWorldStateScoreFrame()
		end
	elseif(status == "wait" or status == "queued" or status == "confirm") then
		if(button == "RightButton") then
			self.bg:Leave()
		elseif(status == "confirm") then
			self.bg:Enter()
		end
	else
		self.bg:Join(OhNoesQueues.joinType)
	end
end

function Buttons:Create(bgName)
	local button = CreateFrame("Button", nil, OhNoesQueues)
	button:RegisterForClicks("AnyUp")
	button:SetSize(37, 37)
	button:SetHighlightTexture[[Interface\Buttons\ButtonHilight-Square]]
	button:SetPushedTexture[[Interface\Buttons\UI-Quickslot-Depress]]

	local glow = button:CreateTexture(nil, "BACKGROUND")
	glow:SetTexture[[Interface\TalentFrame\TalentFrame-Parts]]
	glow:SetTexCoord(0.00396025, 0.72265625, 0.00195313, 0.36132813)
	glow:SetBlendMode("ADD")
	glow:SetPoint("CENTER")
	glow:SetSize(128, 128)
	glow:Hide()

	local bg = button:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture[[Interface\Spellbook\Spellbook-Parts]]
	bg:SetTexCoord(0.79296875, 0.96093750, 0.00390625, 0.17187500)
	bg:SetSize(43, 43)
	bg:SetPoint("CENTER")

	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetAllPoints()

	local border = button:CreateTexture(nil, "OVERLAY", nil, -1)
	border:SetTexture[[Interface\Spellbook\Spellbook-Parts]]
	border:SetTexCoord(0.00390625, 0.27734375, 0.44140625, 0.69531250)
	border:SetSize(70, 65)
	border:SetPoint("CENTER", 1.5, 0)

	button.glow = glow
	button.icon = icon
	button.SetBattleground = Button_SetBattleground
	button.Update = Button_Update
	button.UpdateStatus = Button_UpdateStatus

	button:SetScript("OnClick", Button_OnClick)
	button:SetScript("OnEnter", OhNoesQueues.Stats.Show)
	button:SetScript("OnLeave", OhNoesQueues.Stats.Hide)

	button:SetBattleground(bgName)
	LBG:RegisterCallback("Status_Updated", button, Button_UpdateStatus)

	return button
end
