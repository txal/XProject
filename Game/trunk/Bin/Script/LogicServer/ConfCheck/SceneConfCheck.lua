local function _SceneConfCheck()
	for nSceneID, tConf in pairs(ctSceneConf) do
		assert(ctMapConf[tConf.nMapID], "MapConf.csv中不存在地图:"..tConf.nMapID.." 场景:"..nSceneID)
	end
end
_SceneConfCheck()