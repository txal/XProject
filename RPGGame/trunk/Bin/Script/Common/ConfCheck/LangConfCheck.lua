local function _ProcessLang(tLang, nIndex)
	local tConf = ctLangConf[nIndex]
	assert(tConf, "语言编号:"..nIndex.." 不存在")
	return tConf.sCont
end

ctLang = {}
setmetatable(ctLang, {__index=_ProcessLang})