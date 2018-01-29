--怡红院配置校验
local function _YHYConfCheck()
	for nID, tConf in pairs(ctYHYAwardConf) do
		if tConf.nType == gtItemType.eGongNv then
			assert(tConf.nShowType == 3, "怡红院奖励配置错误")
		end
	end
end
_YHYConfCheck()