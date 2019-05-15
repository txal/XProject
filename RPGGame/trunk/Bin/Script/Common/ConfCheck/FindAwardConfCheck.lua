--找回奖励配置检测

local function _FindAwardConfCheck()
	for nActID, _ in pairs(ctFATaskAwardConf) do
		assert(ctDailyActivity[nActID], string.format("找回奖励配置错误ID(%d)", nActID))
	end
end


_FindAwardConfCheck()