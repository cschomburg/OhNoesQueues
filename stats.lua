local addon, ns = ...
local OhNoesQueues = ns.OhNoesQueues

local Stats = {}
OhNoesQueues:RegisterModule(Stats)

function Stats:Create()
	self.Header = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	self.Header:SetPoint("TOPLEFT", 100, -45)

	local kills = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	kills:SetText(KILLS_PVP)
	kills:SetPoint("TOPLEFT", 80, -110)
	local honor = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	honor:SetText(HONOR)
	honor:SetPoint("TOPRIGHT", kills, "BOTTOMRIGHT", 0, -8)
	local today = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	today:SetText(HONOR_TODAY)
	today:SetPoint("BOTTOMLEFT", kills, "TOPRIGHT", 20, 8)
	local yesterday = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	yesterday:SetText(HONOR_YESTERDAY)
	yesterday:SetPoint("LEFT", today, "RIGHT", 20, 0)
	local lifetime = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	lifetime:SetText(HONOR_LIFETIME)
	lifetime:SetPoint("LEFT", yesterday, "RIGHT", 20, 0)

	self.TodayKills = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.TodayKills:SetPoint("TOP", today, "BOTTOM", 0, -8)

	self.TodayHonor = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.TodayHonor:SetPoint("TOP", self.TodayKills, "BOTTOM", 0, -8)

	self.YesterdayKills = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.YesterdayKills:SetPoint("TOP", yesterday, "BOTTOM", 0, -8)

	self.YesterdayHonor = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.YesterdayHonor:SetPoint("TOP", self.YesterdayKills, "BOTTOM", 0, -8)

	self.LifetimeKills = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	self.LifetimeKills:SetPoint("TOP", lifetime, "BOTTOM", 0, -8)

	local lthonor = OhNoesQueues:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	lthonor:SetPoint("TOP", self.LifetimeKills, "BOTTOM", 0, -8)
	lthonor:SetText("-")
end

function Stats:Update()
	if(not self.Header) then self:Create() end

	local todayKills, todayHonor = GetPVPSessionStats()
	local yesterdayKills, yesterdayHonor = GetPVPYesterdayStats()
	local lifeKills, rank = GetPVPLifetimeStats()

	self.Header:SetText(OhNoesQueues:FormatUnit(GetHonorCurrency(), "honor"))
	self.TodayKills:SetText(todayKills)
	self.TodayHonor:SetText(todayHonor)
	self.YesterdayKills:SetText(yesterdayKills)
	self.YesterdayHonor:SetText(yesterdayHonor)
	self.LifetimeKills:SetText(lifeKills)
end
