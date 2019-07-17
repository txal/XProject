--奖励池检测
local _ctAwardPoolConf = {}
local function _AwardPoolConfCheck()
	for _, tConf in pairs(ctAwardPoolConf) do
		assert(ConfCheckBase:CheckItemExist(tConf.nItemType, tConf.nItemID), 
			string.format("奖池表,配置ID(%d),物品类型(%d),物品ID(%d)不存在", tConf.nID, tConf.nItemType, tConf.nItemID))
		if not _ctAwardPoolConf[tConf.nPoolID] then
			_ctAwardPoolConf[tConf.nPoolID] = {}
		end
		table.insert(_ctAwardPoolConf[tConf.nPoolID], tConf)
	end
end
_AwardPoolConfCheck()


--取奖池物品配置列表
--@nPoolID 奖池ID
--@nLevel 角色等级
--@nRoleCondID 限定角色配置ID, 0不限制
function ctAwardPoolConf.GetPool(nPoolID, nLevel, nRoleConfID)
	assert(nPoolID and nLevel, "参数错误")
	nRoleConfID = nRoleConfID or 0

	local tConfList = assert(_ctAwardPoolConf[nPoolID], "奖池不存在:"..nPoolID)
	local tLevelConfList = {}
	for _, tConf in pairs(tConfList) do
		if nLevel >= tConf.nMinLv and nLevel <= tConf.nMaxLv then
			local bLimitOk = false
			for _, tLimit in pairs(tConf.tRoleLimit) do
				if tLimit[1] == 0 or tLimit[1] == nRoleConfID then
					bLimitOk = true
					break
				end
			end
			if bLimitOk then
				table.insert(tLevelConfList, tConf)
			end
		end
	end
	return tLevelConfList
end

function ctAwardPoolConf.IsPoolExist(nPoolID)
	return _ctAwardPoolConf[nPoolID]
end
