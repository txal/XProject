local function _PropConfCheck()
	for _, tConf in pairs(ctPropConf) do
		if tConf.nSubType == gtCurrType.eQinMi then
			local tMCConf = assert(ctMingChenConf[tConf.nVal], "道具:"..tConf.nID.." 知己不存在:"..tConf.nVal)
			assert(tMCConf.sName == tConf.sName, "道具:"..tConf.nID.." 知己:"..tConf.nVal.." 不对应")
		end
	end
end
_PropConfCheck()