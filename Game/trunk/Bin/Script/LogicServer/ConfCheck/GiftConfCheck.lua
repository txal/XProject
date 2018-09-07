local function _GiftConfCheck()
	for k, v in pairs(ctGiftConf) do
		assert(ctPropConf[k], "gift.xml礼包:"..k.." prop.xml中不存在")
		assert(DropMgr:GetDropConf(v.nDropID), "gift.xml礼包:"..k.." drop.xml中不存在掉落:"..v.nDropID)
	end
end
_GiftConfCheck()
