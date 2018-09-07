local function _WorkShopConfCheck()
	for k, v in pairs(ctWSPropConf) do
		if v.nFloorDropID > 0 then
			assert(ctWSDropConf[v.nFloorDropID], "WSDropConf.xml中不存在掉落:"..v.nFloorDropID)
		end
		if v.nStandardDropID > 0 then
			assert(ctWSDropConf[v.nStandardDropID], "WSDropConf.xml中不存在掉落:"..v.nStandardDropID)
		end
	end
end
_WorkShopConfCheck()