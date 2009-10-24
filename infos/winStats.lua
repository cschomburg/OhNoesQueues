local LPVP = LibStub("LibCargPVP")

local function onEnter(self)
	if(self.total == 0) then return end
	GameTooltip:AddLine(("|cff00ff00%d|r:|cffff0000%d|r of %d"):format(self.win, self.total-self.win, self.total), 1,1,1)
end

OhNoesQueues:RegisterInfoText("Win Chance", function(button, text)
	local win, total = LPVP.GetBattlegroundWinTotal(button.id)
	if(total > 0) then
		local r,g,b = OhNoesQueues.ColorGradient(win/total, 1,0,0, 1,1,0, 0,1,0)
		text:SetFormattedText("|cff%2x%2x%2x%.0f%%|r", r*255,g*255,b*255, win/total*100)
	else
		text:SetText("")
	end
	text.onEnter = onEnter
	text.win, text.total = win, total
end)

OhNoesQueues:RegisterInfoText("Win : Loss", function(button, text)
	local win, total = LPVP.GetBattlegroundWinTotal(button.id)
	if(total > 0) then
		text:SetFormattedText("|cff00ff00%d|r:|cffff0000%d|r", win, total-win)
	else
		text:SetText("")
	end
	text.onEnter = onEnter
	ext.win, text.total = win, total
end)