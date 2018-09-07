_tMonsterDistMap= {}
local function _MonsterConfCheck()
	--怪物分布表检测	
	for _, tConf in pairs(ctMonsterDistributedConf) do
		local nSceneID = tConf.nSceneID
		if not _tMonsterDistMap[nSceneID] then
			_tMonsterDistMap[nSceneID] = {}
		end
		_tMonsterDistMap[nSceneID][tConf.nWaveID] = tConf
		if tConf.nPrepType == 0 then
			assert(tConf.nDelayTime == 0, "MonsterDistributedConf.xml怪物分布表nDelayTime错误")
		end
	end
	for nSceneID, tConfList in pairs(_tMonsterDistMap) do
		local nCount = 0
		for k, v in pairs(tConfList) do
			nCount = nCount + 1
		end
		assert(nCount == #tConfList, "MonsterDistributedConf.xml场景:"..nSceneID.."刷怪有坑没填")
	end
end
_MonsterConfCheck()

--格式化怪物分布表
function GetMonsterDistMap()
	return _tMonsterDistMap
end

