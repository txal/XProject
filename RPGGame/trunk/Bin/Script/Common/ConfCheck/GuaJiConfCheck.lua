--挂机配置预处理和检查
local function _GuaJiConfCheck()
	for nSeq, tConf in ipairs(ctGuaJiConf) do
		if nSeq > 1 then
			assert(ctGuaJiConf[nSeq-1], "挂机关卡配置错误，序号不连续")
			local tLastConf = ctGuaJiConf[nSeq-1]
			assert(tConf.nMinGuanQia == tLastConf.nMaxGuanQia+1, "挂机关卡配置错误,关卡不连续,配置ID: "..nSeq)
		end
		assert(ctDupConf[tConf.nDupID], "挂机关卡配置错误,场景ID错误,配置ID: "..nSeq)
		assert(tConf.nPatrolSec > 0, "挂机关卡配置错误,巡逻时间错误,配置ID: "..nSeq)
		assert(tConf.nChalBossLimit >= 0, "挂机关卡配置错误,挑战boss限制错误,配置ID: "..nSeq)
		assert(ctBattleGroupConf[tConf.nBattleGroup], "挂机关卡配置错误,boss战斗组错误,配置ID: "..nSeq)
	end
end
_GuaJiConfCheck()

function ctGuaJiConf:GetGuanQiaConf(nGuanQia)
	assert(nGuanQia > 0, "获取关卡配置参数错误："..nGuanQia)
	for nSeq, tConf in pairs(ctGuaJiConf) do
		if tConf.nMinGuanQia <= nGuanQia and nGuanQia <= tConf.nMaxGuanQia then
			return tConf
		end
	end
	assert(false, "获取挂机关卡配置失败, 关卡数："..nGuanQia)
end