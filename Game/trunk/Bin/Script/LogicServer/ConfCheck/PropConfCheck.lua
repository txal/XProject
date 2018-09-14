local function _PropConfCheck()
	for _, tConf in pairs(ctPropConf) do
		assert(tConf.nCollapse == 0 or tConf.nCollapse == 1, "Prop.xml collapse(折叠)只支持0和1")
		if tConf.nType == gtPropType.eFeature then
			assert(ctGunFeatureConf[tConf.nSubType], "Prop.xml 特性零件特性"..tConf.nSubType.."不存在")
		elseif tConf.nType == gtPropType.eCurrency then
			assert(tConf.nSubType > 0, "Prop.xml 道具:"..tConf.nID.."子类错误")
		end
	end
end
_PropConfCheck()