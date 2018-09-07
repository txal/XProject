--宝箱掉落预处理
local function _BoxConfCheck()
	for nID, tConf in pairs(ctBoxConf) do
		local nPreWeight = 0
		tConf.nTotalWeight = 0
		for _, tItem in ipairs(tConf.tDrop or {}) do
			if tItem[1] > 0 then
				tItem.nMinWeight = nPreWeight + 1
				tItem.nMaxWeight = tItem.nMinWeight + tItem[1] - 1
				nPreWeight = tItem.nMaxWeight
				tConf.nTotalWeight = tConf.nTotalWeight + tItem[1]
			end
		end
	end
end
_BoxConfCheck()

--掉落物品
ctBoxConf.GetDropItem = function(nID)
	local tConf = assert(ctBoxConf[nID], "宝箱不存在")
	
	local tItemMap = {}
	for k = 1, tConf.nRndTimes do
		local nRnd = math.random(1, tConf.nTotalWeight)	
		for _, tItem in ipairs(tConf.tDrop or {}) do
			if nRnd >= tItem.nMinWeight and nRnd <= tItem.nMaxWeight then
				tItemMap[tItem[3]] = (tItemMap[tItem[3]] or 0) + tItem[4]
				break
			end
		end
	end

	local tItemList = {}
	for nID, nNum in pairs(tItemMap) do
		table.insert(tItemList, {nType=gtItemType.eProp, nID=nID, nNum=nNum})
	end
	return tItemList
end
