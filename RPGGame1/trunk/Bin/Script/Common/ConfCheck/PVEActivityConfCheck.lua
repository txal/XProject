--PVE相关活动副本检查

local function _JuzZhanJiuXiaoConfCheck()
	for _,  tConf in pairs(ctJueZhanJiuXiao) do
		if tConf.nBattleGroup > 0 then
			local tMonster = ctMonsterConf[tConf.nBattleGroup]
			assert(tMonster, string.format("决战九霄怪物配置错误(%d)", tConf.nBattleGroup))
		end
	end
end 

local function _CheckDupMonster(tDupMonsterList, sActName)
	for _, tMonster in pairs(tDupMonsterList) do
		local tMonsterCfg = ctMonsterConf[tMonster[1]]
		assert(tMonsterCfg, string.format("(%s)活动怪物配置错误(%d)", sActName, tMonster[1]))
	end
end

local function _PVEReadyDupConfCheck()
	local tConf = ctDupConf[10400]
	assert(tConf, string.format("PVE大厅地图配置错误(%d)", 10400))
end

local function _PVEDupConfCheck()
	for _, tConf in pairs(ctBattleDupConf) do
		if tConf.nID == 201 or tConf.nID == 202 then
			_CheckDupMonster(tConf.tMonster, tConf.sName)
		end
	end

	_JuzZhanJiuXiaoConfCheck()
	_PVEReadyDupConfCheck()
end

_PVEDupConfCheck()
