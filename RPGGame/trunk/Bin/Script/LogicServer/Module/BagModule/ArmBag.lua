local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--取装备孔中
function CBagModule:GetSlotArm(nSlotID)
	return self.m_tSlotArmMap[nSlotID]
end

--已放的槽位
function CBagModule:GetOpenSlot()
	local tSlotList = {}
	local nLevel = self.m_oPlayer:GetLevel()
	for nSlotID, tConf in ipairs(ctArmSlotConf) do
		if nLevel >= tConf.nOpenLevel then
			table.insert(tSlotList, nSlotID)
		end
	end
	return tSlotList
end

--取背包栏装备
function CBagModule:GetBagArm(nGridID)
	local oItem = self.m_tGridItemMap[nGridID]
	if oItem and oItem:GetObjType() == gtObjType.eArm then
		return oItem
	end
end

--生成装备
function CBagModule:CreateArm(nConfID, nNum)
	if self:GetFreeGridNum() < nNum then
		return
	end
	local tArmList = {}
	local tArmConf = assert(ctArmConf[nConfID], "装备:"..nConfID.."找不到")
	for i = 1, nNum do
		local oArm
		if tArmConf.nType == gtArmType.eDecoration then
			oArm = self:CreateDecorationArm(tArmConf)
		else
			oArm = self:CreateNormalArm(tArmConf)
		end
		if oArm then
			local nGridID = self:GetFreeGridID(gtObjType.eArm, nConfID) 
			assert(nGridID > 0)
			self.m_tGridItemMap[nGridID] = oArm
			self.m_nCurrItem = self.m_nCurrItem + 1
			table.insert(tArmList, {nGridID, oArm})
		end
	end
	if #tArmList > 0 then
		self:OnBagItemAdded(tArmList)
		return tArmList
	end
end

--生成初始属性
function CBagModule:GenInitAttr(tArmConf)
	assert(tArmConf.nType ~= gtArmType.eDecoration)
	local tAttrInit = {0, 0, 0}
	local tInitLimit = tArmConf.tInitLimit[1]
	if tArmConf.nPinJi == gtArmPinJi.sj then
		for k = 1, 3 do
			tAttrInit[k] = tInitLimit[k]
		end
	end

	local nTopAttrID = 0
	local nTopRnd = math.random(1, 10000)
	if nTopRnd >= 1 and nTopRnd <= 500 then
		nTopAttrID = math.random(1, #tAttrInit)
	end
	if nTopAttrID > 0 then
		tAttrInit[nTopAttrID] = math.random(math.floor(0.9 * tInitLimit[nTopAttrID]), tInitLimit[nTopAttrID])
	end
	for k = 1, 3 do
		if k ~= nTopAttrID then
			tAttrInit[k] = math.random(math.floor(0.5 * tInitLimit[k]), math.floor(0.9 * tInitLimit[k]))
		end
	end
	return tAttrInit
end

--生成成长属性
function CBagModule:GenGrowAttr(tArmConf, tFloatVal)
	tFloatVal = tFloatVal or {1, 1, 1}
	local tAttrGrow = {0, 0, 0}	
	local tGrowLimit = tArmConf.tGrowLimit[1]
	for i = 1, 3 do
		tAttrGrow[i] = math.floor(tGrowLimit[i] * 0.1 * (tFloatVal[i] or 1))
	end
	return tAttrGrow
end

--特性生成
function CBagModule:GenFeatures(tArmConf)
	local tFeatureList = {}
	if tArmConf.nType ~= gtArmType.eGun then
		return tFeatureList
	end

	local tFeatureConfList = tArmConf.tFeatures
	if not tFeatureConfList.nTotalWeight then
		local nPreWeight, nTotalWeight = 0, 0
		for _, tConf in ipairs(tFeatureConfList) do
			if tConf[1] <= 0 then
				tConf.nMinWeight = 0
				tConf.nMaxWeight = 0
			else
				tConf.nMinWeight = nPreWeight + 1	
				tConf.nMaxWeight = tConf.nMinWeight + tConf[1] - 1
				nPreWeight = tConf.nMaxWeight 
				nTotalWeight = nTotalWeight + tConf[1]
			end
		end
		tFeatureConfList.nTotalWeight = nTotalWeight
	end
	if tFeatureConfList.nTotalWeight <= 0 then
		return tFeatureList
	end

	local nRndType = tArmConf.nFeatureRandType
	if nRndType == 1 then
	--随出有且只有一个
		local nRnd = math.random(1, tFeatureConfList.nTotalWeight)
		for _, tConf in ipairs(tFeatureConfList) do
			if nRnd >= tConf.nMinWeight and nRnd <= tConf.nMaxWeight then
				table.insert(tFeatureList, {tConf[2], gtFeatureType.eNor})
				break
			end
		end

	elseif nRndType == 2 then
	--单独随机每个
		for _, tConf in ipairs(tFeatureConfList) do
			local nRnd = math.random(1, tFeatureConfList.nTotalWeight)
			if nRnd >= tConf.nMinWeight and nRnd <= tConf.nMaxWeight then
				table.insert(tFeatureList, {tConf[2], gtFeatureType.eNor})
			end
			--普通特性最多5个
			if tFeatureList >= 5 then
				break
			end
		end
	end
	return tFeatureList
end

--非饰品装备生成
function CBagModule:CreateNormalArm(tArmConf)
	assert(tArmConf.nType ~= gtArmType.eDecoration)
	--初始属性
	local tAttrInit = self:GenInitAttr(tArmConf)

	--成长属性
	local tAttrGrow = self:GenGrowAttr(tArmConf)

	--特性
	local tFeature = self:GenFeatures(tArmConf)

	local oArm = CArmItem:new(self)
	oArm:Init(self:GenAutoID(), tArmConf.nID, tArmConf.nLevel, tArmConf.nExp, tAttrInit, tAttrGrow, tFeature)
	return oArm
end

--饰品装备生成
function CBagModule:CreateDecorationArm(tArmConf)
	assert(tArmConf.nType == gtArmType.eDecoration)
	local tInitLimit = tArmConf.tInitLimit[1]
	local tGrowLimit = tArmConf.tGrowLimit[1]
	local tAttrInit, tAttrGrow, tFeature = { table.unpack(tInitLimit) }, { table.unpack(tGrowLimit) }, {}
	local oArm = CArmItem:new(self)
	oArm:Init(self:GenAutoID(), tArmConf.nID, tArmConf.nLevel, tArmConf.nExp, tAttrInit, tAttrGrow, tFeature)
	return oArm
end

--删除装备栏中装备
function CBagModule:RemoveArm(nGridID, nReason)
	local oArm = self:GetBagArm(nGridID)
	if not oArm then
		return
	end
	self.m_tGridItemMap[nGridID] = nil
	self.m_nCurrItem = self.m_nCurrItem - 1
	self:OnBagItemRemoved({nGridID})
	goLogger:AwardLog(gtEvent.eSubItem, nReason, self.m_oPlayer, gtObjType.eArm, oArm:GetConfID(), 1)
	return true
end

--穿装备
function CBagModule:PutOnArm(nGridID)
	local oArm = self:GetBagArm(nGridID)
	if not oArm then
		return
	end
	--选择槽位
	local nTarSlot = 0
	local tArmConf = oArm:GetConf()
	local nArmType, nSubType = tArmConf.nType, tArmConf.nSubType
	if nArmType == gtArmType.eGun or nArmType == gtArmType.eDecoration then
		for nSlotID, tConf in ipairs(ctArmSlotConf) do
			if tConf.nArmType == nArmType and tConf.nSubType == nSubType then
				nTarSlot = nSlotID
				break
			end
		end
	elseif nArmType == gtArmType.eBomb then
		for nSlotID, tConf in ipairs(ctArmSlotConf) do
			if tConf.nArmType == nArmType then
				nTarSlot = nSlotID
				if not self.m_tSlotArmMap[nSlotID] then
					break
				end
			end
		end
	else
		assert(false, "装备类型不支持:"..nArmType)
	end
	assert(nTarSlot > 0)

	local tSlotConf = assert(ctArmSlotConf[nTarSlot])
	local nLevel = self.m_oPlayer:GetLevel()
	if tSlotConf.nOpenLevel > nLevel then
		local sCont = string.format(ctLang[8], tSlotConf.sName, tSlotConf.nOpenLevel)
		return self.m_oPlayer:ScrollMsg(sCont)
	end
	local oOldArm = self.m_tSlotArmMap[nTarSlot]
	if oOldArm == oArm then
		return
	end

	--穿上新装备
	self.m_tSlotArmMap[nTarSlot] = oArm
	self:UpdateBattleAttr()

	--发送成功
	local tItem = self:_slot_arm_info(nTarSlot, oArm)
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "PutOnArmRet", {tItem=tItem})

	--删除背包装备
	self:RemoveArm(nGridID, gtReason.ePutOnArm)

	--被替换的返回到背包
	if oOldArm then
		self.m_tGridItemMap[nGridID] = oOldArm
		self.m_nCurrItem = self.m_nCurrItem + 1
		self:OnBagItemAdded({{nGridID, oOldArm}})
	end

	--飘字
	local sCont = oOldArm and ctLang[22] or ctLang[23]
	self.m_oPlayer:ScrollMsg(sCont)	
end

--卸装备
function CBagModule:PutOffArm(nSlotID)
	local oArm = self:GetSlotArm(nSlotID)
	if not oArm then
		return
	end
	local nGunNum = 0
	local tArmConf = ctArmConf[oArm:GetConfID()]
	if tArmConf.nType == gtArmType.eGun then
		for nSlot, tConf in ipairs(ctArmSlotConf) do
			if tConf.nArmType == gtArmType.eGun then
				if self.m_tSlotArmMap[nSlot] then
					nGunNum = nGunNum + 1
				end
			end
		end
		--至少需要1把枪
		if nGunNum <= 1 then
			self.m_oPlayer:ScrollMsg(ctLang[21])	
			return
		end
	end
	local nGridID = self:GetFreeGridID(gtObjType.eArm, oArm:GetConfID())
	if nGridID <= 0 then
		self.m_oPlayer:ScrollMsg(ctLang[41])
		return
	end

	--脱装备
	self.m_tSlotArmMap[nSlotID] = nil
	self:UpdateBattleAttr()

	--发送通知
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "PutOffArmRet", {nSlotID=nSlotID})

	--返回到背包	
	self.m_tGridItemMap[nGridID] = oArm
	self.m_nCurrItem = self.m_nCurrItem + 1
	self:OnBagItemAdded({{nGridID, oArm}})
end

--穿装备请求
function CBagModule:OnPutOnArmReq(nGridID)
	self:PutOnArm(nGridID)
end

--卸装备请求
function CBagModule:OnPutOffArmReq(nSlotID)
	self:PutOffArm(nSlotID)
end

--更新玩家装备战斗属性
function CBagModule:UpdateBattleAttr()
	self.m_oPlayer:UpdateBattleAttr()
end

--计算所有装备战斗属性
function CBagModule:CalcArmBattleAttr(nLevel)
	local tBattleAttr = {}
	local tDecoration = {}
	for nSlotID, oArm in pairs(self.m_tSlotArmMap) do
		if oArm then
			local tAttr = oArm:CalcBattleAttr(nLevel)
			for nAttrID, nValue in pairs(tAttr) do
				tBattleAttr[nAttrID] = (tBattleAttr[nAttrID] or 0) + nValue
			end
			if oArm:GetType() == gtArmType.eDecoration then
				table.insert(tDecoration, oArm:GetConfID())
			end
		end
	end
	--套装属性加成(百分数10000倍)
	local tSuitMap = {}
	for k = 1, #tDecoration do
		local nArmID = tDecoration[k]
		local nSuitID = ctArmConf[nArmID].nSuitID
		if nSuitID > 0 then
			tSuitMap[nSuitID] = (tSuitMap[nSuitID] or 0) + 1
		end
	end
	for nSuitID, nNum in pairs(tSuitMap) do
		if nNum > 1 then
			local tSuitConf = assert(ctDecorationSuitConf[nSuitID])
			local tAttrAdd = tSuitConf["tAdd"..nNum]
			for _, tAdd in ipairs(tAttrAdd) do
				tBattleAttr[tAdd[1]] = (tBattleAttr[tAdd[1]] or 0) + tAdd[2]
			end
		end
	end
	--装备大师属性加成(值)
	local nMasterGrade = self:GetMasterGrade()
	local tMasterConf = ctArmMasterConf[nMasterGrade]	
	if tMasterConf then
		for _, tAttr in ipairs(tMasterConf.tAdd) do
			tBattleAttr[tAttr[1]] = (tBattleAttr[tAttr[1]] or 0) + tAttr[2]
		end
	end
	return tBattleAttr
end

--检测暴级
function CBagModule:_check_break_level_(oArm)
	local bBreakLevel = false
	local nLevel = oArm:GetLevel()
	local nBreakLevel = oArm:GetBreakLevel()
	if nBreakLevel > 0 and nLevel >= nBreakLevel then
		local nMaxLevel = oArm:GetMaxLevel()
		if nMaxLevel > nLevel then
			oArm:SetLevel(nMaxLevel)
			bBreakLevel = true
		end
		oArm:SetMaxLevel(0)
		oArm:SetBreakLevel(0)
	end
	return bBreakLevel
end

--设置暴级
function CBagModule:_set_break_level_(oArm, nQuality)
	local nLevel = oArm:GetLevel()
	local nMaxLevel = oArm:GetMaxLevel()
	if nMaxLevel >= nLevel then
		return
	end

	oArm:SetMaxLevel(nLevel)
	local nBreakLevel = 0
	for k = #ctArmBreakLevelConf, 1, -1 do
		local tConf = ctArmBreakLevelConf[k]
		if nQuality >= tConf.tTotalStar[1][1] then
			nBreakLevel = tConf.nBreakLevel
			break
		end
	end
	assert(nBreakLevel > 0)
	oArm:SetBreakLevel(nBreakLevel)
end

--计算合成单位数值 
function CBagModule:_calc_compose_unit_value(nGrowAttr, nGrowLimit)
	--计算N值
	local N = 1
	if nGrowAttr >= nGrowLimit then
		N = 18	--注意：合成的成长允许突破极限成长
	elseif nGrowAttr >= nGrowLimit*0.95 then
		N = 16.8
	elseif nGrowAttr >= nGrowLimit*0.9 then
		N = 15.6
	elseif nGrowAttr >= nGrowLimit*0.85 then
		N = 14.4
	elseif nGrowAttr >= nGrowLimit*0.8 then
		N = 13.2
	elseif nGrowAttr >= nGrowLimit*0.75 then
		N = 12
	elseif nGrowAttr >= nGrowLimit*0.7 then
		N = 10.8
	elseif nGrowAttr >= nGrowLimit*0.65 then
		N = 9.6
	elseif nGrowAttr >= nGrowLimit*0.6 then
		N = 8.4
	elseif nGrowAttr >= nGrowLimit*0.55 then
		N = 7.2
	elseif nGrowAttr >= 0 then
		N = 6
	end
	local nUnitVal = nGrowLimit / 20 / N
	return nUnitVal
end

--检测是否可以合成
function CBagModule:CheckCompose(oArm, oTarArm)
	if not oArm or not oTarArm then
		return
	end
	if oArm == oTarArm then
		return
	end
	local tArmConf = oArm:GetConf()
	local tTarConf = oTarArm:GetConf()
	if tArmConf.nType == gtArmType.eDecoration or (tArmConf.sName ~= tTarConf.sName and tTarConf.nType ~= gtArmType.eMate) then
		return
	end
	if oTarArm:GetLevel() < ctArmEtcConf[1].nComposeSubMinLevel then
		return
	end
	
	local nNeedMainLevel, nNeedSubTotalStar
	local nMainGrowStar = oArm:GrowStar()
	for k = #ctArmComposeConf, 1, -1 do
		local tConf = ctArmComposeConf[k]
		if nMainGrowStar >= tConf.tMainStar[1][1] then
			nNeedMainLevel = tConf.nMainLevel
			nNeedSubTotalStar = tConf.nTotalStar
			break
		end
	end
	if oArm:GetLevel() < nNeedMainLevel then
		return
	end
	local nSubTotalStar = oTarArm:CalcQuality()
	if nSubTotalStar < nNeedSubTotalStar then
		return
	end
	
	return true, nSubTotalStar
end

--取合成副装备列表
function CBagModule:GetComposeSubArmList(oArm)
	local tItemList = {}
	for nGridID, oItem in pairs(self.m_tGridItemMap) do
		local nObjType = oItem:GetObjType()
		if nObjType == gtObjType.eArm then
			local bCanCompose, nSubTotalStar = self:CheckCompose(oArm, oItem)
			if bCanCompose then
				local tInfo = {}
				tInfo.nGridID = nGridID
				tInfo.nArmID = oItem:GetConfID()
				tInfo.nLevel = oItem:GetLevel()
				tInfo.nStar = nSubTotalStar
				tInfo.tGrowAttr = oItem:GetGrowAttr()
				table.insert(tItemList, tInfo)
			end
		end
	end
	return tItemList
end

--合成副装备列表请求
function CBagModule:ComposeSubArmReq(nPosType, nPosID)
	local oArm
 	if nPosType == 1 then		--装备孔
 		oArm = self:GetSlotArm(nPosID)	
 	elseif nPosType == 2 then	--背包
		oArm = self:GetBagArm(nPosID)
 	end
	if not oArm then	
		return
	end
	local tItemList = self:GetComposeSubArmList(oArm)
	local nStoneNum = self:GetItemCount(gtObjType.eProp, ctArmEtcConf[1].nLuckyStone)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ComposeSubArmRet", {tArmList=tItemList, nStoneNum=nStoneNum})
end

--装备合成
 function CBagModule:ComposeArm(nPosType, nPosID, nGridID, bUseProp)
 	local oArm
 	if nPosType == 1 then		--装备孔
 		oArm = self:GetSlotArm(nPosID)	
 	elseif nPosType == 2 then	--背包
		oArm = self:GetBagArm(nPosID)
 	end
	local oTarArm = self:GetBagArm(nGridID)
	if not oArm or not oTarArm then
		return
	end

	if not self:CheckCompose(oArm, oTarArm) then
		return
	end

	local nMainGrowStar = oArm:GrowStar()
	local nCostGold = nMainGrowStar * ctArmEtcConf[1].nComposeCostGold + 1500
	if self.m_oPlayer:GetGold() < nCostGold then
		return self.m_oPlayer:ScrollMsg(ctLang[12])
	end

	--判断幸运石
	if bUseProp then
		local oBagModule = self.m_oPlayer:GetModule(CBagModule:GetType())
		local nLuckyStone = ctArmEtcConf[1].nLuckyStone
		local bRes = oBagModule:SubItem(gtObjType.eProp, nLuckyStone, 1, gtReason.eComposeArm)
		if not bRes then
			local sCont = string.format(ctLang[6], ctPropConf[nLuckyStone].sName)
			self.m_oPlayer:ScrollMsg(sCont)
			return
		end
	end

	--丢骰子
	local tDiceList, tAddList = {}, {}
	local tArmConf = oArm:GetConf()
	local tGrowAttr = oArm:GetGrowAttr()
	local tGrowLimit = tArmConf.tGrowLimit[1]
	for k = 1, 3 do
		local nDiceNum = bUseProp and 6 or math.random(1, 6)
		local nUnitVal = self:_calc_compose_unit_value(tGrowAttr[k], tGrowLimit[k])
		local nAttrAdd = math.floor(nDiceNum * nUnitVal)
		tGrowAttr[k] = tGrowAttr[k] + nAttrAdd
		tDiceList[k], tAddList[k] = nDiceNum, nAttrAdd
	end
	--扣钱
	self.m_oPlayer:SubGold(nCostGold, gtReason.eComposeArm)
	--删副装备
	self:RemoveArm(nGridID, gtReason.eComposeArm)
	-- --设置暴级
	-- local nQuality = oArm:CalcQuality()
	-- self:_set_break_level_(oArm, nQuality)
	-- --重置等级
	-- oArm:SetLevel(1)
	-- oArm:SetExp(0)

	--更新战斗属性	
	if nPosType == 1 then
		self:UpdateBattleAttr()
	end
	--同步装备信息
	self:SyncArmDetailInfo(oArm)
	local tMsg = {tDice=tDiceList, tAttrAdd=tAddList, nOldStar=nQuality, nNewStar=oArm:CalcQuality(), nColor=oArm:GetColor()}
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ComposeArmRet", tMsg)	
end


--检测是否可以强化
function CBagModule:CheckStrengthen(oArm, oTarArm)
	if not oArm or not oTarArm then
		return
	end
	if oArm == oTarArm then
		return
	end
	local tArmConf = oArm:GetConf()
	local tTarConf = oTarArm:GetConf()
	if tArmConf.nType == gtArmType.eDecoration or tArmConf.nPinJi == gtArmPinJi.sj then
		return
	end
	if tArmConf.sName ~= tTarConf.sName and tTarConf.nType ~= gtArmType.eMate then
		return
	end
	if oArm:GetLevel() < ctArmEtcConf[1].nStrengthenMainMinLevel then
		return
	end
	if oTarArm:GetLevel() < ctArmEtcConf[1].nStrengthenSubMinLevel then
		return
	end
	local tDiffAttr = {}
	local tInitAttr = oArm:GetInitAttr()
	local tTarInitAttr = oTarArm:GetInitAttr()
	local bResult = false
	for k = 1, 3 do
		tDiffAttr[k] = math.max(0, tTarInitAttr[k] - tInitAttr[k])
		bResult = bResult or tDiffAttr[k] > 0
	end
	return bResult, tDiffAttr
end

--取强化副装备列表
function CBagModule:StrengthenSubArmReq(nPosType, nPosID)
	local oArm
 	if nPosType == 1 then		--装备孔
 		oArm = self:GetSlotArm(nPosID)	
 	elseif nPosType == 2 then	--背包
		oArm = self:GetBagArm(nPosID)
 	end
 	if not oArm then
 		return
 	end
	local tItemList = {}
	for nGridID, oItem in pairs(self.m_tGridItemMap) do
		local nObjType = oItem:GetObjType()
		if nObjType == gtObjType.eArm then
			local tArmConf = oItem:GetConf()
			local bCanStrengthen, tDiffAttr = self:CheckStrengthen(oArm, oItem)
			if bCanStrengthen then
				local tInfo = {}
				tInfo.nGridID = nGridID
				tInfo.nArmID = tArmConf.nID
				tInfo.nLevel = oItem:GetLevel()
				tInfo.nStar = nSubTotalStar
				tInfo.tInitAttr = oItem:GetInitAttr()
				table.insert(tItemList, tInfo)
			end
		end
	end
	print("StrengthenSubArmReq:", tItemList)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "StrengthenSubArmRet", {tArmList=tItemList})
end

--装备强化
function CBagModule:StrengthenArm(nPosType, nPosID, nGridID)
 	local oArm
 	if nPosType == 1 then		--装备孔
 		oArm = self:GetSlotArm(nPosID)	
 	elseif nPosType == 2 then	--背包
		oArm = self:GetBagArm(nPosID)
 	end
	local oTarArm = self:GetBagArm(nGridID)
	if not oArm or not oTarArm then
		return
	end
	local bCanStrengthen, tDiffAttr = self:CheckStrengthen(oArm, oTarArm)
	if not bCanStrengthen then
		return
	end
	local nInitStar = oArm:InitStar()
	local nCostGold = nInitStar * ctArmEtcConf[1].nStrengthenCostGold + 500
	if self.m_oPlayer:GetGold() < nCostGold then
		return self.m_oPlayer:ScrollMsg(ctLang[12])
	end
	local tAttrAdd = {}
	local nQuality = oArm:CalcQuality()
	local tInitAttr = oArm:GetInitAttr()
	for k = 1, 3 do
		local nAttrAdd = math.ceil(tDiffAttr[k] * math.random(1, 5) * 0.01)
		tInitAttr[k] = tInitAttr[k] + nAttrAdd
		tAttrAdd[k] = nAttrAdd
	end
	local tArmConf = oArm:GetConf()
	--扣钱
	self.m_oPlayer:SubGold(nCostGold, gtReason.eStrengthenArm)
	--删副装备
	self:RemoveArm(nGridID, gtReason.eStrengthenArm)
	-- --设置暴级
	-- self:_set_break_level_(oArm, nQuality)
	-- --重置等级
	-- oArm:SetLevel(1)
	-- oArm:SetExp(0)

	--更新战斗属性	
	if nPosType == 1 then
		self:UpdateBattleAttr()
	end
	--同步装备信息
	self:SyncArmDetailInfo(oArm)
	local tMsg = {tAttrAdd=tAttrAdd, nOldStar=nQuality, nNewStar=oArm:CalcQuality(), nColor=oArm:GetColor()}
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "StrengthenArmRet", tMsg)	
end

--取当前所装备的枪支
function CBagModule:GetCurrGunID()
	for _, nGunType in ipairs(ctPlayerInitConf[1].tDefGunOrder[1]) do
		for nSlotID, tConf in pairs(ctArmSlotConf) do
			if tConf.nArmType == gtArmType.eGun then
				if tConf.nSubType == nGunType then
					local oArm = self.m_tSlotArmMap[nSlotID]
					if oArm then
						return oArm:GetConfID()
					end
				end
			end
		end
	end
	return 0
end

--取战斗时武器列表
function CBagModule:GetWeaponList()
	local tWeaponList = {tGunList={}, tBombList={}}
	local tGunList = tWeaponList.tGunList
	local tBombList = tWeaponList.tBombList

	for nSlotID, oArm in pairs(self.m_tSlotArmMap) do
		local nArmType = oArm:GetType()
		if nArmType == gtArmType.eGun then
			local nArmID = oArm:GetConfID()
			local tGun = {nArmID=nArmID, nLevel=oArm:GetLevel(), tFeature={}}
			local tFeature = oArm:GetFeature()
			for k, v in ipairs(tFeature) do
				tGun.tFeature[k] = v[1]
			end
			table.insert(tGunList, tGun)

		elseif nArmType == gtArmType.eBomb then
			local nArmID = oArm:GetConfID()
			local tBomb = {nArmID=nArmID, nLevel=oArm:GetLevel(), tFeature={}}
			local tFeature = oArm:GetFeature()
			for k, v in ipairs(tFeature) do
				tBomb.tFeature[k] = v[1]
			end
			table.insert(tBombList, tBomb)
		end
	end
	tWeaponList.nCurrWeapon = self:GetCurrGunID()
	return tWeaponList
end

--取装备大师套装品阶
function CBagModule:GetMasterGrade()
	local nMinQuality = 0
	for nSlotID, tConf in pairs(ctArmSlotConf) do
		if tConf.nArmType == gtArmType.eGun or tConf.nArmType == gtArmType.eBomb then
			local oArm = self.m_tSlotArmMap[nSlotID]
			if not oArm then
				return 0
			end
			local nArmQuality = oArm:CalcQuality()
			if nMinQuality == 0 or nArmQuality < nMinQuality then
				nMinQuality = nArmQuality
			end
		end
	end
	assert(nMinQuality > 0)
	for k = #ctArmMasterConf, 1 do
		local tConf = ctArmMasterConf[k]
		if nMinQuality >= tConf.nNeedQuality then
			return k
		end
	end
	return 0
end

--取装备大师信息
function CBagModule:GetMasterInfo()
	local tCurrArm= {}
	local nGrade = self:GetMasterGrade()
	local nNextGrade = math.min(nGrade+1, #ctArmMasterConf)
	for nSlotID, tConf in pairs(ctArmSlotConf) do
		if tConf.nArmType == gtArmType.eGun or tConf.nArmType == gtArmType.eBomb then
			local oArm = self.m_tSlotArmMap[nSlotID]
			if oArm then
				local nArmID = oArm:GetConfID()
				local nQuality = oArm:CalcQuality()
				local nNextQuality = ctArmMasterConf[nNextGrade].nNeedQuality
				table.insert(tCurrArm, {nArmID=nArmID, nQuality=nQuality, nNextQuality=nNextQuality})
			end
		end
	end
	local tSendData = {nGrade=nGrade, nNextGrade=nNextGrade, tCurrArm=tCurrArm}
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ArmMasterRet", tSendData)	
end

--取特性零件列表
function CBagModule:FeaturePropListReq(nPosType, nPosID)
 	local oArm
 	if nPosType == 1 then		--装备孔
 		oArm = self:GetSlotArm(nPosID)	
 	elseif nPosType == 2 then	--背包
		oArm = self:GetBagArm(nPosID)
 	end
 	if not oArm then
 		return
 	end
	local tFeaturePropList = {}
	for nGridID, oItem in pairs(self.m_tGridItemMap) do
		if oItem:GetObjType() == gtObjType.eProp then 
			if self:CheckReform(oArm, oItem) then
				local tConf = oItem:GetConf()
				local tInfo = {}
				tInfo.nGridID = nGridID
				tInfo.nPropID = tConf.nID
				tInfo.nFeatureID = tConf.nSubType
				tInfo.nPropNum = oItem:GetCount()
				table.insert(tFeaturePropList, tInfo)
			end
		end
	end
	local nLockProp = ctArmEtcConf[1].nReformLockProp
	local nPropCount = self:GetItemCount(gtObjType.eProp, nLockProp)
	local tMsg = {tPropList=tFeaturePropList, nLockPropCount=nPropCount}
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "FeaturePropListRet", tMsg)	
end

--是否可以改造
function CBagModule:CheckReform(oArm, oProp)
	if not oArm or not oProp then
		return
	end
	if oProp:GetObjType() ~= gtObjType.eProp then
		return
	end
	local tPropConf = oProp:GetConf()
	if tPropConf.nType ~= gtPropType.eFeature then
		return
	end
	local tArmConf = oArm:GetConf()
	if tArmConf.nType ~= gtArmType.eGun then
		return
	end
	local nFeature = tPropConf.nSubType
	-- local tFeatureConf = assert(ctGunFeatureConf[nFeature])
	-- if tArmConf.nSubType ~= tFeatureConf.nGunType then
	-- 	return
	-- end
	local tFeatureList = oArm:GetFeature()
	for _, v in ipairs(tFeatureList) do
		if v[1] == nFeature then
			return
		end
	end
	return true, nFeature
end

--装备改造
function CBagModule:ArmReformReq(nPosType, nPosID, nGridID, nLockFeature)
 	local oArm
 	if nPosType == 1 then		--装备孔
 		oArm = self:GetSlotArm(nPosID)	
 	elseif nPosType == 2 then	--背包
		oArm = self:GetBagArm(nPosID)
 	end
	if not oArm then
		return
	end
	local oProp = self:GetBagItem(nGridID)
	if not oProp then
		return
	end
	local bCanReform, nFeature = self:CheckReform(oArm, oProp)
	if not bCanReform then
		return	
	end
	local nFeatureStar = oArm:FeatureStar()
	local nCostGold = nFeatureStar * ctArmEtcConf[1].nReformCostGold + 2500
	if self.m_oPlayer:GetGold() < nCostGold then
		return self.m_oPlayer:ScrollMsg(ctLang[12])
	end
	local nLockProp = ctArmEtcConf[1].nReformLockProp
	if nLockFeature > 0 then
		if self:GetItemCount(gtObjType.eProp, nLockProp) <= 0 then
			return self.m_oPlayer:ScrollMsg(string.format(ctLang[6], ctPropConf[nLockProp].sName))
		end
	end
	local nNorFeatureNum = 0
	local tUnlockFeature = {}
	local tFeatureList = oArm:GetFeature()
	for k, v in ipairs(tFeatureList) do
		if v[2] == gtFeatureType.eNor then
			nNorFeatureNum = nNorFeatureNum + 1
			if nLockFeature ~= v[1] then
				table.insert(tUnlockFeature, k)
			end
		end
	end
	local tReformConf = ctArmReformConf[nNorFeatureNum]
	local nRate = tReformConf and tReformConf.nRate or 0
	nRate = nNorFeatureNum >= 5 and 0 or nRate

	local nRnd = math.random(1, 10000)
	local bNew = nRnd <= nRate

	local tResult = {}
	if bNew or #tUnlockFeature <= 0 then
		assert(nNorFeatureNum < 5)
		table.insert(tFeatureList, {nFeature, gtFeatureType.eNor})
		tResult[1] = nFeature
		tResult[2] = 0
	else
		assert(#tUnlockFeature > 0)
		local nRndIdx = math.random(1, #tUnlockFeature)
		local nReplaceIdx = tUnlockFeature[nRndIdx]
		tResult[1] = nFeature
		tResult[2] = tFeatureList[nReplaceIdx][1]
		tFeatureList[nReplaceIdx] = {nFeature, gtFeatureType.eNor}
	end
	self:SubItem(gtObjType.eProp, oProp:GetConfID(), 1, gtReason.eArmReform)
	self.m_oPlayer:SubGold(nCostGold, gtReason.eArmReform)
	if nLockFeature > 0 then
		self:SubItem(gtObjType.eProp, nLockProp, 1, gtReason.eArmReform)
	end
	local tMsg = {nNewFeatureID=tResult[1], nReplaceFeatureID=tResult[2]}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ArmReformRet", tMsg)
end

--装备洗练信息请求
function CBagModule:ArmPolishInfoReq(nPosType, nPosID)
 	local oArm
 	if nPosType == 1 then		--装备孔
 		return self.m_oPlayer:ScrollMsg(ctLang[29])
 		--oArm = self:GetSlotArm(nPosID)	
 	elseif nPosType == 2 then	--背包
		oArm = self:GetBagArm(nPosID)
 	end
	if not oArm then
		return
	end
	local tArmConf = oArm:GetConf()
	local nRare = math.max(1, math.min(tArmConf.nRare, #ctArmPolishConsumeConf))
	local tConsumeConf = assert(ctArmPolishConsumeConf[nRare])
	local nConsume = tConsumeConf.nConsume
	local nCurrNum = self:GetItemCount(gtObjType.eProp, ctArmEtcConf[1].nPolishProp)
	local nLackNum = math.max(0, nConsume - nCurrNum)

	local nCostMoney = nLackNum * 2
	local nRealConsume = nConsume - nLackNum

	local tMsg = {nCurrPropNum=nCurrNum, nCostPropNum=nConsume, nCostMoney=nCostMoney}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ArmPolishInfoRet", tMsg)
end

--装备洗练
function CBagModule:ArmPolishReq(nPosType, nPosID)
 	local oArm
 	if nPosType == 1 then		--装备孔
 		return self.m_oPlayer:ScrollMsg(ctLang[29])
 		--oArm = self:GetSlotArm(nPosID)	
 	elseif nPosType == 2 then	--背包
		oArm = self:GetBagArm(nPosID)
 	end
	if not oArm then
		return
	end
	local tArmConf = oArm:GetConf()
	if tArmConf.nType == gtArmType.eDecoration or tArmConf.nPinJi ~= gtArmPinJi.pt then
		return
	end
	local nGrowStar = oArm:GrowStar()
	if nGrowStar >= ctArmEtcConf[1].nPolishGrowStar then
		return
	end
	local nRare = math.max(1, math.min(tArmConf.nRare, #ctArmPolishConsumeConf))
	local tConsumeConf = assert(ctArmPolishConsumeConf[nRare])
	local nConsume = tConsumeConf.nConsume
	local nPropID = ctArmEtcConf[1].nPolishProp
	local nCurrNum = self:GetItemCount(gtObjType.eProp, nPropID)
	local nLackNum = math.max(0, nConsume - nCurrNum)
	local nCostMoney = nLackNum * 2
	local nRealConsume = nConsume - nLackNum
	if self.m_oPlayer:GetMoney() < nCostMoney then
		return self.m_oPlayer:ScrollMsg(ctLang[4])
	end
	if nRealConsume > 0 then
		self:SubItem(gtObjType.eProp, nPropID, nRealConsume, gtReason.eArmPolish)
	end
	if nCostMoney > 0 then
		self.m_oPlayer:SubMoney(nCostMoney, gtReason.eArmPolish)
	end
	oArm:SetLevel(1)
	oArm:SetExp(0)

	local tOldFeature = oArm:GetFeature()
	local tInitAttr, tGrowAttr, tFeatureList
	local nRnd = math.random(1, 10000)
	local bVariation = false --变异
	if nRnd <= 100 then
		local nRare = oArm:RareStar()
		local tSameRareMate = {}
		local tMateArmConf = GetMaterialArmConfList()
		for k, v in pairs(tMateArmConf) do
			if v.nRare == nRare then
				table.insert(tSameRareMate, v)
			end
		end
		assert(#tSameRareMate > 0)
		local tTarArmConf = tSameRareMate[math.random(1, #tSameRareMate)]
		self:RemoveArm(nPosID, gtReason.eArmPolish)
		self.m_oPlayer:AddItem(gtObjType.eArm, tTarArmConf.nID, 1, gtReason.eArmPolish)	
	else
		nRnd = math.random(1, 10000)
		if nRnd <= 200 then
			tInitAttr = self:GenInitAttr(tArmConf)
			local nFloatVal = math.random(105, 110) * 0.01
			local tFloatVal = {nFloatVal, nFloatVal, nFloatVal}
			tGrowAttr = self:GenGrowAttr(tArmConf, tFloatVal)
			tFeatureList = self:GenFeatures(tArmConf)
			bVariation = true
		else
			tInitAttr = self:GenInitAttr(tArmConf)
			tGrowAttr = self:GenGrowAttr(tArmConf)
			tFeatureList = self:GenFeatures(tArmConf)
		end
	end
	--保留护符特性
	for _, tFeature in ipairs(tOldFeature) do
		if tFeature[2] == gtFeatureType.eAmu then
			table.insert(tFeatureList, tFeature)
		end
	end
	local tFeatureMap = {}
	for _, tFeature in ipairs(tFeatureList) do
		tFeatureMap[tFeature[1]] = tFeature[2]
	end

	if bVariation then
		if tArmConf.nType == gtArmType.eGun then
			local tFeatureConfList = {}
			local nRnd = math.random(1, 10000)
			if nRnd <= 2500 then
				for _, tFeatureConf in pairs(ctGunFeatureConf) do
					if not tFeatureMap[tFeatureConf.nID] then
						table.insert(tFeatureConfList, tFeatureConf)
					end
				end
			end
			if #tFeatureConfList > 0 then
				local nIndex = math.random(1, #tFeatureConfList)
				local tFeatureConf = tFeatureConfList[nIndex]
				table.insert(tFeatureList, {tFeatureConf.nID, gtFeatureType.eVar})
			end
		end
	end
	oArm:SetInitAttr(tInitAttr)
	oArm:SetGrowAttr(tGrowAttr)
	oArm:SetFeature(tFeatureList)
	oArm:SetVariation(bVariation)

	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ArmPolishSuccRet", {})

	if bVariation then
		local sCont = string.format(ctLang[9], self.m_oPlayer:GetName(), tArmConf.sName)
		goRollingMsg:SendMsg(sCont)
	end
end

function CBagModule:GetWeaponDetail(nArmType, nArmID, tFeature)
	if nArmType == gtArmType.eGun then
		local tArmConf = assert(ctArmConf[nArmID])
		local tGunConf = assert(ctGunConf[nArmID])
		local tGun = 
		{
			  uID = nArmID
			, uSubType = tArmConf.nSubType
			, uClipCap = tGunConf.nClipCap
			, uBulletBackup = tGunConf.nBulletBackup
			, uReloadTime = tGunConf.nReloadTime
			, uTimePerShot = math.ceil(1 / tGunConf.nShotSpeed * 1000)
			, uRecoilTime = tGunConf.nRecoilTime
			, tFeature = tFeature
		}
		CastGunFeature(tGun, tFeature)
		return tGun
	end
	if nArmType == gtArmType.eBomb then
		local tConf = assert(ctBombConf[nArmID])
		local tBomb = 
		{
			  uID = nArmID
			, uBombCap = tConf.nBombCap
			, uBombCD = tConf.nCD
		}
		return tBomb
	end
	assert(false, "不支持武器类型:"..nArmType)
end

--升级装备
function CBagModule:UpgradeArm(nPosID, nPosType, bOneKey)
	local oArm
	if nPosType == 1 then
	--装备孔中
		oArm = self:GetSlotArm(nPosID)

	elseif nPosType == 2 then
	--背包栏中
		oArm = self:GetBagArm(nPosID)
	end
	if not oArm then
		return
	end
	local nCurrExp = oArm:GetExp()
	local nCurrLevel = oArm:GetLevel()
	local nMaxLevel = #ctArmUpgradeConf
	if nCurrLevel >= nMaxLevel then
		return
	end
	local nUpgradeCostGold = ctArmEtcConf[1].nUpgradeCostGold
	local nCurrGold = self.m_oPlayer:GetGold()
	if nCurrGold < nUpgradeCostGold then
		if bOneKey then return end
		return self.m_oPlayer:ScrollMsg(ctLang[12])
	end
	local nUpgradeGetExp = ctArmEtcConf[1].nUpgradeGetExp
	if nCurrLevel >= self.m_oPlayer:GetLevel() then
		local nNextExp = ctArmUpgradeConf[nCurrLevel+1].nExp
		if nCurrExp >= nNextExp - 1 then
			if bOneKey then return end
			return self.m_oPlayer:ScrollMsg(ctLang[7])
		end
		nCurrExp = math.min(nCurrExp + nUpgradeGetExp, nNextExp - 1)
	else
		nCurrExp = nCurrExp + nUpgradeGetExp
	end
	self.m_oPlayer:SubGold(nUpgradeCostGold, gtReason.eUpgradeArm)
	oArm:SetExp(nCurrExp)
	local bLevelChanged = false
	for i = nCurrLevel + 1, nMaxLevel do
		local nNeedExp = ctArmUpgradeConf[i].nExp
		if nCurrExp >= nNeedExp then
			oArm:SetLevel(i)
			nCurrExp = nCurrExp - nNeedExp
			oArm:SetExp(nCurrExp)
			bLevelChanged = true
		else
			break
		end
	end
	-- if bLevelChanged then
	-- 	self:_check_break_level_(oArm)
	-- end
	return true
end

--1键升级装备
function CBagModule:OneKeyUpgradeArmReq()
	local nCharLevel = self.m_oPlayer:GetLevel()
	local tArmList = {}
	for nSlot, oArm in pairs(self.m_tSlotArmMap) do
		table.insert(tArmList, {nSlot, oArm})
	end
	if #tArmList <= 0 then
		return
	end
	local bGoldLack = false
	local tResultMap = {}
	while #tArmList > 0 do
		table.sort(tArmList, function(tArm1, tArm2) return tArm1[2]:GetLevel() < tArm2[2]:GetLevel() end)
		local nSlot, oArm = table.unpack(tArmList[1])
		if self:UpgradeArm(nSlot, 1, true) then
			tResultMap[nSlot] = oArm
		else
			table.remove(tArmList, 1)
			bGoldLack = bGoldLack or oArm:GetLevel() < nCharLevel	--判断是否缺少金币
		end
	end
	if not next(tResultMap) then
		if bGoldLack then
			return self.m_oPlayer:ScrollMsg(ctLang[12])
		else
			return self.m_oPlayer:ScrollMsg(ctLang[39])
		end
	end
	self:UpdateBattleAttr()
	local tSlotList = {}
	for nSlot, oArm in pairs(tResultMap) do
		local tItem = self:_slot_arm_info(nSlot, oArm)
		table.insert(tSlotList, tItem)
		self.m_oPlayer:ScrollMsg(string.format(ctLang[38], oArm:GetName(), oArm:GetLevel()))
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "OneKeyUpgradeArmRet", {tSlotList=tSlotList})	
end

--升级装备请求
function CBagModule:OnUpgradeArmReq(nPosID, nPosType, nUpgradeType)
	local bRes = false
	if nUpgradeType == 1 then --1次
		bRes = self:UpgradeArm(nPosID, nPosType)
	elseif nUpgradeType == 2 then --10次
		for k = 1, 10 do
			if self:UpgradeArm(nPosID, nPosType) then
				bRes = true
			else
				break
			end
		end
	end
	if bRes then
		local oArm
		if nPosType == 1 then
			self:UpdateBattleAttr()
			oArm = self:GetSlotArm(nPosID)

		elseif nPosType == 2 then
			oArm = self:GetBagArm(nPosID)

		end
		local nLevel, nCurrExp, nNextExp = oArm:GetLevelInfo()
		local tMsg = {nLevel=nLevel, nCurrExp=nCurrExp, nNextExp=nNextExp}
		local tBattleAttr = oArm:CalcBattleAttr()
		tMsg.tCurrAttr = {tBattleAttr[1], tBattleAttr[2], tBattleAttr[3]}
	    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "UpgradeArmRet", tMsg)
	end
end

--分解装备请求
function CBagModule:OnDecomposeArmReq(nGridID)
	local oItem = self:GetBagItem(nGridID)
	if not oItem then
		return
	end
	if oItem:GetObjType() == gtObjType.eArm then	
		local tItemList = {}
		local tConf = oItem:GetConf()
		self:RemoveArm(nGridID, gtReason.eDecomposeArm)
		local tDecompose = tConf.tDecompose or {}
		for _, tItem in ipairs(tDecompose) do
			local nType, nID, nNum = table.unpack(tItem)
			if nID > 0 then
				local tList = self.m_oPlayer:AddItem(nType, nID, nNum, gtReason.eDecomposeArm)
				local oArm 
				if nType == gtObjType.eArm then
					oArm = tList and #tList > 0 and tList[1][2]
				end
				local nColor = GF.GetItemColor(nType, nID, oArm)	
				table.insert(tItemList, {nType=nType, nID=nID, nNum=nNum, nColor=nColor})
			end
		end
		CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "DecomposeArmRet", {tItemList=tItemList})
	else
		assert(false, "类型不支持:"..oItem:GetObjType())
	end
end
