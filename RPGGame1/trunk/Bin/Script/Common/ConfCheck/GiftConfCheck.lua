--礼包配置检测
local function _GiftConfCheck()
	for _, tConf in pairs(ctGiftConf) do
		for _, tItem in pairs(tConf.tDrop) do
			assert(ConfCheckBase:CheckItemExist(tItem[3], tItem[4]), 
				string.format("礼包ID(%d),物品类型(%d),物品ID(%d)不存在", tConf.nID, tItem[3], tItem[4]))
		end
	end
end
_GiftConfCheck()
