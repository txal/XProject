local _tMaterialArmConfList = {} 
local function _ArmConfCheck()
	--装备表
	for nArmID, tConf in pairs(ctArmConf) do
		if tConf.nPinJi == gtArmPinJi.cl or tConf.nType == gtArmType.eMate then
			assert(tConf.nType == gtArmType.eMate and tConf.nSubType == 0 and tConf.nPinJi==gtArmPinJi.cl, "arm.xml零件:"..nArmID.."配置错误")
		end
		--特性检测
		for _, tFeature in ipairs(tConf.tFeatures) do
			local nFeatureID = tFeature[2]
			if nFeatureID > 0 then
				assert(tConf.nType == gtArmType.eGun, "arm.xml 只有枪支有特性")
				assert(ctGunFeatureConf[nFeatureID], "gunfeature.xml 枪支特性:"..nFeatureID.."不存在")
			end
		end
		--饰品套装检测	
		if tConf.nSuitID > 0 then
			assert(ctDecorationSuitConf[tConf.nSuitID], "套装:"..tConf.nSuitID.."不存在")
			local tArmID = ctDecorationSuitConf[tConf.nSuitID].tArmID
			local bExist = false
			for _, nSuitArmID in ipairs(tArmID[1]) do
				if nSuitArmID == nArmID then
					bExist = true
					break
				end
			end
			assert(bExist, "套装:"..tConf.nSuitID.."不存在装备:"..nArmID)
		end
		--缘分
		for _, tMaster in ipairs(tConf.tMaster) do
			local nAdd = tMaster[3]
			local nIntAdd = math.floor(tMaster[3])
			assert(nIntAdd == nAdd, "掌握属性值加成要放大10000倍")
		end
		--材料装备列表
		if tConf.nPinJi == gtArmPinJi.cl then
			table.insert(_tMaterialArmConfList, tConf)
		end
	end

	--枪支表
	for nArmID, tConf in pairs(ctGunConf) do
		assert(ctArmConf[nArmID], "Arm.xml中不存在枪支:"..nArmID..",在Gun.xml中")
		assert(tConf.nClipCap >= 1 and tConf.nClipCap <= 0xFF, "Gun.xml枪支:"..nArmID.."弹夹容量错误[1,255]")
	end

	--炸弹表
	for nArmID, tConf in pairs(ctBombConf) do
		assert(ctArmConf[nArmID], "Arm.xml中不存在雷:"..nArmID)
		if tConf.nBuffID > 0 then
			assert(ctBuffConf[tConf.nBuffID], "Buff.xml中不存在Buff:"..tConf.nBuffID)
		end
	end

	--套装表检测
	for nSuitID, tConf in pairs(ctDecorationSuitConf) do
		for _, nArmID in ipairs(tConf.tArmID[1]) do
			if nArmID > 0 then
				local tArmConf = ctArmConf[nArmID]
				assert(tArmConf and tArmConf.nSuitID == nSuitID, "套装表和装备不匹配")
			end
		end
	end

	--装备合成
	local nPreVal = -1 
	for nIndex, tConf in ipairs(ctArmComposeConf) do
		assert(tConf.tMainStar[1][1] == nPreVal + 1, "ArmComposeConf.xml成长品质不连续")
		nPreVal = tConf.tMainStar[1][2] 
	end

	--装备暴级
	nPreVal = -1
	for nIndex, tConf in ipairs(ctArmBreakLevelConf) do
		assert(tConf.tTotalStar[1][1] == nPreVal + 1, "ArmBreakLevelConf.xml品质不连续")
		nPreVal = tConf.tTotalStar[1][2] 
	end

	--杂项检测
	local tEtcConf = ctArmEtcConf[1]
	assert(ctPropConf[tEtcConf.nLuckyStone], "ArmEtc.xml 幸运石道具不存在")
	assert(ctPropConf[tEtcConf.nReformLockProp], "ArmEtc.xml 改造锁定道具不存在")
	assert(ctPropConf[tEtcConf.nPolishProp], "ArmEtc.xml 洗练道具不存在")

	--玩家初始装备
	for _, tArm in pairs(ctPlayerInitConf[1].tInitArm) do
		assert(ctArmConf[tArm[1]], "PlayerInitConf.xml中装备:"..tArm[1].."不存在")
	end
end
_ArmConfCheck()

function GetMaterialArmConfList()
	return _tMaterialArmConfList
end