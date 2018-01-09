local function _SceneDropConfCheck()
	for _, tConf in pairs(ctSceneDropConf) do
		for _, tItem in pairs(tConf.tItemPool) do
			if tConf.nType == gtDropItemType.eBuff then
				if tItem[1] > 0 then
					assert(ctBuffConf[tItem[1]], "buff.xml不存在编号:"..tItem[1].." 来自scenedrop.xml")
				end
			end
		end
	end
end
_SceneDropConfCheck()