--货币->道具映射
local _ctCurrencyMap = {}
local function _PropConfCheck()
	for nID, tConf in pairs(ctGiftConf) do
		assert(ctPropConf[nID], "礼包道具不存在:"..nID)
	end
	for nID, tConf in pairs(ctPropConf) do
		if tConf.nType == 7 then
			assert(ctGiftConf[nID], "礼包配置不存:"..nID)
		end
		if tConf.nType == 5 then
			_ctCurrencyMap[tConf.nSubType] = tConf
		end
	end
end
_PropConfCheck()

--道具名
function ctPropConf:PropName(nPropID)
	local tConf = ctPropConf[nPropID]
	return tConf and tConf.sName or ""
end

--通过货币取道具ID,名字
function ctPropConf:GetCurrProp(nCurrency)
	local tConf = _ctCurrencyMap[nCurrency]
	if tConf then
		return tConf.nID, tConf.sName
	end
end

--根据道具ID获取根据品质颜色格式化后的名称
function ctPropConf:GetFormattedName(nPropID)
	assert(nPropID and type(nPropID) == "number")
	local tConf = ctPropConf[nPropID]
	assert(tConf, "道具不存在")
	return CUtil:FormatPropQualityString(tConf.nQuality, tConf.sName)
end
