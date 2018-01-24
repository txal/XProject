local _tMallGoodsList = {}
local function _CheckMallConf()
	for _, tConf in pairs(ctMallConf) do
		assert(tConf.nItemType == gtObjType.eProp 
			or tConf.nItemType == gtObjType.eWSProp
			or tConf.nItemType == gtObjType.eArm, "MallConf.xml nItemType不支持物品类型:"..tConf.nItemType)
		assert(tConf.nPageType > 0, "MallConf.xml nPageType必须大于0:"..tConf.nID)
		assert(tConf.nBuyNum > 0, "MallConf.xml nBuyNum必须大于0:"..tConf.nID)

		--格式化商城表
		if not _tMallGoodsList[tConf.nMallType] then
			_tMallGoodsList[tConf.nMallType] = {}
			_tMallGoodsList[tConf.nMallType][0] = {}
		end
		if not _tMallGoodsList[tConf.nMallType][tConf.nPageType] then
			_tMallGoodsList[tConf.nMallType][tConf.nPageType] = {}
		end
		table.insert(_tMallGoodsList[tConf.nMallType][tConf.nPageType], tConf)
		table.insert(_tMallGoodsList[tConf.nMallType][0], tConf)
	end
	for k, v in pairs(_tMallGoodsList) do
		for _, tPageGoodsList in pairs(v) do
			table.sort(tPageGoodsList, function(t1, t2) return t1.nID < t2.nID end )
		end
	end
end
_CheckMallConf()

--取格式化后的物品表
function GetMallGoodsList(nMallType, nPageType)
	assert(nMallType and nPageType)
	if _tMallGoodsList[nMallType] then
		return (_tMallGoodsList[nMallType][nPageType] or {})
	end
	return {}
end