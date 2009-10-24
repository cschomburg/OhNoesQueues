local LPVP = LibStub("LibCargPVP")

OhNoesQueues:RegisterInfoText("BG XP needed", function(button, text)
	local xp = LPVP.GetAverageBattlegroundHonor(button.id)
	if(not xp) then return text:SetText("") end

	local forLevel = (UnitXPMax("player")-UnitXP("player")) / xp / LPVP.XP_FACTOR
	local r,g,b = OhNoesQueues.ColorGradient(forLevel/15, 1,0,0, 1,1,0, 0,1,0)
	text:SetFormattedText("|cff%2x%2x%2x%.1f|r", r*255,g*255,b*255, forLevel)
end)