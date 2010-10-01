local LBG = LibStub("LibBattlegrounds-2.0")

local Buttons = {}
OhNoesQueues.Buttons = Buttons

local function Button_SetBattleground(self, bgName)
	self.bgName = bgName
	self:Update()
end

local function Button_Update(self)
	local bg = self.bgName and LBG:Get(self.bgName)
	self.bg = bg


	if(bg) then
		local lName, canQueue, canEnter, isActive, startTime = bg:GetInfo()

		self.icon:SetTexture(bg.newIcon)

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
end

local function Button_OnClick(self, button)
	local status = self.bg.status

	if(status == "active") then
		if(button == "RightButton") then
			LeaveBattlefield()
		else
			TogglePVPFrame()
			ToggleWorldStateScoreFrame()
		end
	elseif(status == "queued" or status == "confirm") then
		AcceptBattlefieldPort(self.bg.statusID, button ~= "RightButton" and 1)
	else
		self.bg:Join(button == "LeftButton" and "group")
	end
end

function Buttons:Create(bgName)
	local button = CreateFrame("Button", nil, OhNoesQueues)
	button:SetSize(37, 37)
	button:SetHighlightTexture[[Interface\Buttons\ButtonHilight-Square]]
	button:SetPushedTexture[[Interface\Buttons\UI-Quickslot-Depress]]

	local bg = button:CreateTexture(nil, "BACKGROUND", "Spellbook-EmptySlot")
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

	button.icon = icon
	button.SetBattleground = Button_SetBattleground
	button.Update = Button_Update

	button:SetScript("OnClick", Button_OnClick)

	button:SetBattleground(bgName)

	return button
end
