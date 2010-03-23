local stats = {}
OhNoesQueues.Stats = stats

function OhNoesQueues:CreateStats()
	stats.Header = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	stats.Header:SetPoint("TOPLEFT", 100, -45)

	local kills = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	kills:SetText(KILLS_PVP)
	kills:SetPoint("TOPLEFT", 80, -110)
	local honor = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	honor:SetText(HONOR)
	honor:SetPoint("TOPRIGHT", kills, "BOTTOMRIGHT", 0, -8)
	local today = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	today:SetText(HONOR_TODAY)
	today:SetPoint("BOTTOMLEFT", kills, "TOPRIGHT", 20, 8)
	local yesterday = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	yesterday:SetText(HONOR_YESTERDAY)
	yesterday:SetPoint("LEFT", today, "RIGHT", 20, 0)
	local lifetime = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	lifetime:SetText(HONOR_LIFETIME)
	lifetime:SetPoint("LEFT", yesterday, "RIGHT", 20, 0)

	stats.TodayKills = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	stats.TodayKills:SetPoint("TOP", today, "BOTTOM", 0, -8)

	stats.TodayHonor = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	stats.TodayHonor:SetPoint("TOP", stats.TodayKills, "BOTTOM", 0, -8)

	stats.YesterdayKills = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	stats.YesterdayKills:SetPoint("TOP", yesterday, "BOTTOM", 0, -8)

	stats.YesterdayHonor = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	stats.YesterdayHonor:SetPoint("TOP", stats.YesterdayKills, "BOTTOM", 0, -8)

	stats.LifetimeKills = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	stats.LifetimeKills:SetPoint("TOP", lifetime, "BOTTOM", 0, -8)

	local lthonor = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	lthonor:SetPoint("TOP", stats.LifetimeKills, "BOTTOM", 0, -8)
	lthonor:SetText("-")
end

function OhNoesQueues:UpdateStats()
	local todayKills, todayHonor = GetPVPSessionStats()
	local yesterdayKills, yesterdayHonor = GetPVPYesterdayStats()
	local lifeKills, rank = GetPVPLifetimeStats()


	stats.Header:SetText(self:FormatUnit(GetHonorCurrency(), "honor"))
	stats.TodayKills:SetText(todayKills)
	stats.TodayHonor:SetText(todayHonor)
	stats.YesterdayKills:SetText(yesterdayKills)
	stats.YesterdayHonor:SetText(yesterdayHonor)
	stats.LifetimeKills:SetText(lifeKills)
end