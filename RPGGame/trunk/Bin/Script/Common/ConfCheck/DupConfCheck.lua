local function DupConfCheck()
	for nID, tConf in pairs(ctBattleDupConf) do
		for _, tDup in pairs(tConf.tDupList) do
			if tDup[1] > 0 then
				assert(ctDupConf[tDup[1]], "DupConf场景不存在:"..tDup[1])
				assert(ctDupConf[tDup[1]].nBattleType==nID, "DupConf场景战斗类型对不上:"..nID.." "..tDup[1])
			end
		end
	end
	--检测玩法逻辑服
	local tLogicMap = {}
	for nID, tConf in pairs(ctDupConf) do
		assert(tConf.nLine > 0 and tConf.nLine <= 300, "分线人数错误[1-300] 场景:"..nID)
		if tConf.nBattleType > 0 then
			if not tLogicMap[tConf.nBattleType] then
				tLogicMap[tConf.nBattleType] = tConf.nLogic
			else
				assert(tLogicMap[tConf.nBattleType]==tConf.nLogic, "DupConf同一副本玩法必须在同个逻辑服:"..tConf.nBattleType)
			end
		end
	end
end
DupConfCheck()