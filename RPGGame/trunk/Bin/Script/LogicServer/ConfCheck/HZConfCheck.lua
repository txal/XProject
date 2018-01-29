--皇子配置校验
local function _HZConfCheck()
	for k, v in pairs(ctHZTalentConf) do
		assert(#ctHZLevelConf >= v.nMaxLv, "皇子天赋等级上限和等级表不一致")
	end
end
_HZConfCheck()