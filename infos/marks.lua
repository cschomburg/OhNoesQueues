local LPVP = LibStub("LibCargPVP")

OhNoesQueues:RegisterInfoText("Marks", function(button, text)
	local marks = LPVP.GetBattlegroundMarkCount(button.id)
	local r,g,b = OhNoesQueues.ColorGradient(marks/30, 1,0,0, 1,1,0, 0,1,0)
	text:SetFormattedText("|cff%2x%2x%2x%d|r", r*255,g*255,b*255, marks)
end)