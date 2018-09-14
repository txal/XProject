local function _RechargeConfCheck()
	for nID, tConf in pairs(ctRechargeConf) do
		if tConf.bCard then
			assert(ctCardConf[nID], tConf.sName.." 配置不存在")
		end
	end
end
_RechargeConfCheck()