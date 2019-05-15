--辅助技能
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nVitalityDan = 10003 --回神丹道具
local nJinChunYaoID = 22000 --金创药道具
--构造函数
function CAssistedSkill:Ctor(oRole)
	self.m_oRole = oRole
	self.m_tSkillMap = {}  --门派技能

	self.m_tFactionSkillMap = {}	--帮派技能
	self.m_tLiveSkillMap = {} 		--生活技能
	self.m_tBattleAttr = {} --战斗属性
	-- self:init()
end

function CAssistedSkill:LoadData(tData)
	if tData then 
		self.m_tSkillMap = tData.m_tSkillMap or self.m_tSkillMap
		self.m_tLiveSkillMap = tData.m_tLiveSkillMap or self.m_tLiveSkillMap
		self.m_tBattleAttr = tData.m_tBattleAttr or self.m_tBattleAttr
	end
	self:OnLoaded()
	self:init()
end
function CAssistedSkill:init()
	if next(self.m_tSkillMap) == nil then
		for nID, tItem in pairs(ctAssistedSkillConf) do
			self.m_tSkillMap[nID] = {nID = nID, nLevel = 0}
		end
		self:MarkDirty(true)
	end
end
function CAssistedSkill:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tSkillMap = self.m_tSkillMap
	tData.m_tLiveSkillMap = self.m_tLiveSkillMap
	tData.m_tBattleAttr = self.m_tBattleAttr
	return tData
end

function CAssistedSkill:GetType()
	return gtModuleDef.tAssistedSkill.nID, gtModuleDef.tAssistedSkill.sName
end

function CAssistedSkill:OnLoaded()
	self:OnRoleLevelChange()
end

function CAssistedSkill:GetConf(nID) return ctAssistedSkillConf[nID] end
function CAssistedSkill:GetSkill(nID) return self.m_tSkillMap[nID] end
function CAssistedSkill:GetLevel(nID) return self.m_tSkillMap[nID].nLevel end
function CAssistedSkill:GetName(nID) return self:GetConf(nID).sName end
function CAssistedSkill:MaxLevel(nID) return self:GetConf(nID).eMaxLevel(self.m_oRole:GetLevel()) end
function CAssistedSkill:GetSkillMap() return self.m_tSkillMap end
function CAssistedSkill:GetBattleAttr() return self.m_tBattleAttr end

function CAssistedSkill:OnSysOpen()
	self:ListReq()
end

function CAssistedSkill:IsSysOpen()
	return self.m_oRole.m_oSysOpen:IsSysOpen(41)
end
--激活技能
function CAssistedSkill:AddSkill(nID, nLevel)
	nLevel = nLevel or 0
	if self.m_tSkillMap[nID] then
		return
	end
	self.m_tSkillMap[nID] = {nID=nID, nLevel=nLevel}
	self:MarkDirty(true)
	self:UpdateAttr()
end

function CAssistedSkill:Online()
	self:SkillStateCheck()
end

--角色等级变化
function CAssistedSkill:OnRoleLevelChange(nLevel)
	for _, tConf in ipairs(ctAssistedSkillConf) do
		if nLevel >= tConf.nLearnLevel then
			self:AddSkill(tConf.nID)
		end
	end
	--self:SkillStateCheck()
end

function CAssistedSkill:OnYinBiChange()
	self:SkillStateCheck()
end

--帮贡变化通知
function CAssistedSkill:ChangeUnionContri()
	self:SkillStateCheck()
end

--小红点检查推送(追捕、逃离、强身、冥想四项满足升级条件时，辅助页签显示红点，四项技能显示红点)
function CAssistedSkill:SkillStateCheck()
	if not self:IsSysOpen() then
		return 
	end
	local nGlobalLogic = goServerMgr:GetGlobalService(self.m_oRole:GetServer(), 20)
	goRemoteCall:CallWait("UnionContriReq", function(nUnionContri)
		local tMsg = {tSkillList = {}}
		nUnionContri = nUnionContri or 0
		for nSkillID, tData in pairs(self.m_tSkillMap) do
			if ctAssistedSkillConf[nSkillID] and ctAssistedSkillConf[nSkillID].bState and tData.nLevel < self:MaxLevel(nSkillID) then
				local nCostYB, nCostUC = self:UpgradeCost(nSkillID)
				if self.m_oRole:GetYinBi() >= nCostYB and nUnionContri >= nCostUC then
					table.insert(tMsg.tSkillList, nSkillID)
				end
			end
		end
		self.m_oRole:SendMsg("lifeskillStateRet", tMsg)
	 end, 
	self.m_oRole:GetServer(), nGlobalLogic, 0, self.m_oRole:GetID())
end

--更新结果属性
function CAssistedSkill:UpdateAttr()
	self.m_tBattleAttr = {}
	for nID, tSkill in pairs(self.m_tSkillMap) do
		local tConf = ctAssistedSkillConf[nID]
		for _, tAttr in ipairs(tConf.tAttr) do
			if tAttr[1] > 0 then
				self.m_tBattleAttr[tAttr[1]] = tAttr[2](tSkill.nLevel)
			end
		end
	end
	self:MarkDirty(true)
	self.m_oRole:UpdateAttr()
end

--技能列表请求
function CAssistedSkill:ListReq()
	local tMsg = {tList={}}
	for _, tConf in pairs(self.m_tSkillMap) do
		local tInfo = {
			nID = tConf.nID,
			nLevel = tConf.nLevel,
			nMaxLevel = self:MaxLevel(tConf.nID),
			nCostYB = 0,
			nCostUC = 0,
		}
		tInfo.nCostYB,tInfo.nCostUC  = self:UpgradeCost(tConf.nID)
		table.insert(tMsg.tList, tInfo)
	end

	tMsg.tItemList = self:GetItemListInfo()
	tMsg.nCurrYB = self.m_oRole:GetYinBi()
	tMsg.nCurrVitality = self.m_oRole:GetVitality()
	local nGlobalLogic = goServerMgr:GetGlobalService(self.m_oRole:GetServer(), 20)
	goRemoteCall:CallWait("UnionContriReq", function(nUnionContri) tMsg.nCurrUC  = nUnionContri
		self.m_oRole:SendMsg("lifeskillListRet", tMsg)
	 end, 
	self.m_oRole:GetServer(), nGlobalLogic, 0, self.m_oRole:GetID())
end

--取升级消耗
function CAssistedSkill:UpgradeCost(nID)
	local nLevel = self:GetLevel(nID)
	local tSkillCof = self:GetConf(nID)
	if not tSkillCof then
		return 
	end
	--通过公式计算
	local nCostUC = 0
	local nCostYB = 0
	if tSkillCof.nSkillType == gtSkillType.eProduce then
		if nLevel >= 30 then
			nCostUC = tSkillCof.eContributeFormula(nLevel)
			--技能等级低于服务器等级减去20,帮贡消耗减少30%
			if nLevel <= goServerMgr:GetServerLevel(self.m_oRole:GetServer()) - 20 then
				nCostUC = math.ceil(nCostUC - nCostUC * 0.3)
			end
		end
		--nCostUC = tSkillCof.eContributeFormula(nLevel+1)
		if nLevel >= tSkillCof.tLevelRangeStr1[1][1] and nLevel <= tSkillCof.tLevelRangeStr1[1][2] then
			nCostYB = math.ceil(tSkillCof.eCopperFormula1(nLevel+1))
		elseif nLevel >= tSkillCof.tLevelRangeStr2[1][1] and nLevel <= tSkillCof.tLevelRangeStr2[1][2] then
			nCostYB = math.ceil(tSkillCof.eCopperFormula2(nLevel+1))
		elseif nLevel >= tSkillCof.tLevelRangeStr3[1][1] and nLevel <= tSkillCof.tLevelRangeStr3[1][2] then
			nCostYB =  math.ceil(tSkillCof.eCopperFormula3(nLevel+1))
		elseif nLevel >= tSkillCof.tLevelRangeStr4[1][1] and nLevel <= tSkillCof.tLevelRangeStr4[1][2] then
			nCostYB =  math.ceil(tSkillCof.eCopperFormula4(nLevel+1))
		elseif nLevel >= tSkillCof.tLevelRangeStr5[1][1] and nLevel <= tSkillCof.tLevelRangeStr5[1][2] then
			nCostYB = math.ceil(tSkillCof.eCopperFormula5(nLevel+1))
		end
	elseif tSkillCof.nSkillType == gtSkillType.eOther then
		if nLevel >=20 then
			nCostUC = tSkillCof.eContributeFormula(nLevel)
			--技能等级低于服务器等级减去20,帮贡消耗减少30%
			if nLevel <= goServerMgr:GetServerLevel(self.m_oRole:GetServer()) - 20 then
				nCostUC = math.ceil(nCostUC - nCostUC * 0.3)
			end
		end
		nCostYB = math.ceil(tSkillCof.eCopperFormula1(nLevel+1))
	end
	if nCostYB < 0 then
		nCostYB = 0
	end
	return nCostYB, nCostUC
end

--技能升级请求
--@nUpdateCount 升级次数
function CAssistedSkill:UpgradeReq(nID, nUpdateCount)
	if not self:IsSysOpen(true) then
		-- return self.m_oRole:Tips("辅助技能功能尚未开启")
		return
	end
	nUpdateCount = math.max(1, nUpdateCount)
	local tSkill = self:GetSkill(nID)
	if not tSkill then
		return self.m_oRole:Tips("技能不存在")
	end

	local nLevel = self:GetLevel(nID)
	local nUpdateLevel
	local nMaxLevel = self:MaxLevel(nID)
	if nLevel >= nMaxLevel then
		return self.m_oRole:Tips("技能已达学习上限，你无法继续学习")
	end
	nUpdateLevel = nLevel + nUpdateCount > nMaxLevel and nMaxLevel - nLevel or nUpdateCount
	local bUpdateLevel = false
	local nOldYinBi = self.m_oRole:GetYinBi()
	local nGlobalLogic = goServerMgr:GetGlobalService(self.m_oRole:GetServer(), 20)

	--根据策划需求，现在取消使用金币补足帮贡
	goRemoteCall:CallWait("UnionContriReq", function(nUnionContri)
		for i = 1, nUpdateLevel, 1 do
			local nCostYB, nCostUC = self:UpgradeCost(nID)
			if self.m_oRole:GetYinBi () < nCostYB then
				self.m_oRole:YinBiTips()
				break
			end
			if nCostUC > nUnionContri then
				self.m_oRole:Tips("帮贡不足")
				break
			end
			tSkill.nLevel = tSkill.nLevel + 1
			self:MarkDirty(true)
			self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eYinBi, nCostYB, "生活技能升级", nil, nil, true)
			if nCostUC >= 1 then
				self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eUnionContri, nCostUC, "生活技能升级")
				nUnionContri = nUnionContri - nCostUC
			end
			bUpdateLevel = true
		end

		if bUpdateLevel then
			self:ListReq()
			self:UpdateAttr()
			self:SkillStateCheck()
			self.m_oRole:Tips("升级成功")
			local tData = {}
			tData.nLevel = tSkill.nLevel
			CEventHandler:OnAssistedSkillUpLevel(self.m_oRole, tData)

			 self.m_oRole:SyncCurrency(gtCurrType.eYinBi, self.m_oRole:GetYinBi())
			--减轻客户端压力,所以在这里发送银币及道具消耗消耗
	        local nSubYinBi = nOldYinBi - self.m_oRole:GetYinBi()
	        local nYinBiID = ctPropConf:GetCurrProp(gtCurrType.eYinBi)
			GF.SendItemTalk(self.m_oRole, "subitem", {nYinBiID, nSubYinBi})
		end

	end, self.m_oRole:GetServer(), nGlobalLogic, 0, self.m_oRole:GetID())
	return true
end

--技能制作物品
function CAssistedSkill:SkillManufactureItem(nID, nItemID, nCount)
	 if not self.m_oRole.m_oSysOpen:IsSysOpen(43, true) then
	 	-- return self.m_oRole:Tips("活力使用功能尚未开启")
	 	return
	 end
	if not self:GetConf(nID) then
		return self.m_oRole:Tips("技能不存在")
	end
	if self.m_tSkillMap[nID].nLevel < self:GetConf(nID).nAvailableLevel then
		return self.m_oRole:Tips("该技能需要" .. self:GetConf(nID).nAvailableLevel .. "级才能生产物品")
	end

	local tSkill = self.m_tSkillMap[nID]
	if not tSkill then
		return 
	end
	
	local tSkillCof = self:GetConf(nID)
	if tSkillCof.nSkillSubType == gtSkillSubID.eLapping then
		self:HandleLapping(nID, nItemID, tSkillCof)
	elseif tSkillCof.nSkillSubType == gtSkillSubID.eCooKing then
		self:HandleCooking(tSkillCof, tSkill.nLevel, nCount)
	elseif tSkillCof.nSkillSubType == gtSkillSubID.eLianYao then
		self:HandleLianYao(tSkillCof, tSkill.nLevel, nCount)
	end
end

--属性加成
function CAssistedSkill:GetBattleAttr()
	return self.m_tBattleAttr
end

function CAssistedSkill:CalcAttrScore()
	local nScore = 0
	local tAttrList = self:GetBattleAttr()
	for nAttrID, nAttrVal in pairs(tAttrList) do 
		nScore = nScore + CPropEqu:CalcAttrScore(nAttrID, nAttrVal)
	end
	return nScore
end

function CAssistedSkill:HandleCooking(tSkillCof, nSkillLevel, nCount)
	nCount = math.max(1, nCount)
	local nVitality = tSkillCof.eVigourConsumeFormula(nSkillLevel)
	--注：烹饪和炼药技能，当技能等级≤服务器等级-20时，活力消耗降低20%
	if self.m_tSkillMap[tSkillCof.nID].nLevel <= goServerMgr:GetServerLevel(self.m_oRole:GetServer()) - 20 then
			nVitality = nVitality - nVitality * 0.2
	end
	local nMaxVitality = self.m_oRole:GetVitality()
	local nCostVitality = nVitality * nCount
	nCount = nCostVitality <= nMaxVitality and nCount or math.floor(nMaxVitality/nVitality)
	if nCount <= 0 then
		return self.m_oRole:Tips("活力点不足")
	end
	self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eVitality, nVitality * nCount, "生活技能制造消耗")
	local tItemList = {}
	for nID, tItem in pairs(ctAssistSkillCookProduct) do
		if nSkillLevel >= tItem.nSkillLevelLimit then
			tItemList[#tItemList+1] = nID
		else
			break
		end
	end
	for i = 1, nCount, 1 do
		local nID =  tItemList[math.random(1, #tItemList)]
		local nIndex = math.modf(nSkillLevel/10)
		--为了防止策划改配置出现问题，在加一个判断条件
		if nSkillLevel < 10 then
			nIndex = 1
		end
		nIndex = nIndex > 10 and 10 or nIndex
		local nItemID = ctAssistSkillCookProduct[nID]["nSubProducts" .. tostring(nIndex)]
		self.m_oRole:AddItem(gtItemType.eProp, nItemID, 1, "生活技能制造获得")
	end
end

function CAssistedSkill:HandleLapping(nID, nItemID, tSkillCof)
	local tItem2
	for _, tItem in pairs(ctAssistSkillProduct) do
		if tItem.nID == nItemID and tItem.nAssistSkillId == nID then
			tItem2 = tItem
		end
	end
	if not tItem2 then
		print("配置文件不存在")
		return 
	end
	if self.m_tSkillMap[nID].nLevel < tItem2.nSkillLevelLimit then
		return self.m_oRole:Tips("该产品需要" .. tostring(tItem2.nSkillLevelLimit) .. "级才能产出")
	end
	local nVitality = tSkillCof.eVigourConsumeFormula(tItem2.nLevel)
	
	if nVitality > self.m_oRole:GetVitality() then
		return self.m_oRole:Tips("活力点不足")
	end
	self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eVitality, nVitality, "生活技能制造消耗")
	self.m_oRole:AddItem(gtItemType.eProp, nItemID, 1 , "生活技能制造获得")
end

function CAssistedSkill:HandleLianYao(tSkillCof, nSkillLevel, nCount)
	nCount = math.max(1, nCount)
	local nVitality = tSkillCof.eVigourConsumeFormula(nSkillLevel)
	--注：烹饪和炼药技能，当技能等级≤服务器等级-20时，活力消耗降低20%
	if self.m_tSkillMap[tSkillCof.nID].nLevel <= goServerMgr:GetServerLevel(self.m_oRole:GetServer()) - 20 then
		nVitality = nVitality - nVitality * 0.2
	end
	local nMaxVitality = self.m_oRole:GetVitality()
	local nCostVitality = nVitality * nCount
	nCount = nCostVitality <= nMaxVitality and nCount or math.floor(nMaxVitality/nVitality)
	if nCount <= 0 then
		return self.m_oRole:Tips("活力点不足")
	end

	local tItemList = {}
	for nID, tItem in pairs(ctAssistSkillRefine) do
		if nSkillLevel >= tItem.nSkillLevelLimit and tItem.nShowItemId ~= nJinChunYaoID then
			tItemList[#tItemList+1] = nID
		elseif nSkillLevel < tItem.nSkillLevelLimit then
			break
		end
	end
	self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eVitality, nVitality * nCount , "生活技能制造消耗")
	--炼药成功，则有一定概率直接产出止血散（22007），概率=max((300-技能等级*6)/1000,20%)
	 --math.max((100/10-3)*8,10)
	 for i = 1, nCount, 1 do
		 local fnProbability = ctAssistSkillRefine[1].eMainPropRateFormula
		 local nRan = fnProbability(nSkillLevel)
		 local nRet = math.random(1,100)
		 if nRan >= nRet then
		 	--命中止血散
		 	local nPropID = ctAssistSkillRefine[1].nShowItemId
		 	self.m_oRole:AddItem(gtItemType.eProp, nPropID, 1, "生活技能制造获得")
		 else
		 	local nItemID = tItemList[math.random(1,#tItemList)]
			local nIndex = string.format("%.0f", nSkillLevel/10)
			local nID = ctAssistSkillRefine[nItemID]["nSubProducts" .. tostring(nIndex)]
			if not nID then
				return 
			end
			self.m_oRole:AddItem(gtItemType.eProp, nID, 1, "生活技能制造获得")
		end
	end
end

function CAssistedSkill:OutSkillInfo()
	print("生活技能---->", self.m_tSkillMap)
end

function CAssistedSkill:GetItemListInfo()
	local tSkillList = {}
	local tItemList = {}
	for nSkillID, tSkill in pairs(self.m_tSkillMap) do
		if ctAssistedSkillConf[nSkillID].nSkillSubID == gtSkillSubID.eLapping then
			tSkillList[#tSkillList+1] = {nID = nSkillID, nLevel = tSkill.nLevel}
		end
	end
	for _, tSkill in ipairs(tSkillList) do
		for nItemID, tItem in pairs(ctAssistSkillProduct) do
			if tSkill.nID == tItem.nAssistSkillId then
				local nCurVitality = self:HandleVitality(tSkill.nID, tSkill.nLevel, nItemID)
				tItemList[#tItemList+1] = {nID = nItemID, nSkillID = tSkill.nID, nCostVitality = nCurVitality}
			end
		end
	end
	return tItemList
end

function CAssistedSkill:HandleVitality(nSkillID, nSkillLevel, nItemID)
	local tSkillCof = ctAssistedSkillConf[nSkillID]
	if not tSkillCof then return end
	local nVitality = tSkillCof.eVigourConsumeFormula(nSkillLevel) or 0
	--注：烹饪和炼药技能，当技能等级≤服务器等级-20时，活力消耗降低20%
	if self.m_tSkillMap[tSkillCof.nID].nLevel <= goServerMgr:GetServerLevel(self.m_oRole:GetServer()) - 20 then
		nVitality = nVitality - nVitality * 0.2
	end
	return  nVitality or 0
end

--活力兑换界面请求
function CAssistedSkill:VitalityPagReq()
	--获取门派技能
	local tSkillList = {}
	local tFMSkill = self:GetFuMoSkill()
	if tFMSkill then
		tSkillList[#tSkillList+1] = tFMSkill
	end
	for nSKID, tSkill in pairs(self.m_tSkillMap) do
		local tSkillCfg = ctAssistedSkillConf[nSKID]
		if tSkillCfg and tSkill.nLevel >= tSkillCfg.nAvailableLevel and tSkillCfg.tVitalityPage[1][1] > 0 then
			local tLifeSk = self:GetVitalityInfo(tSkillCfg)
			if  tLifeSk then
				tSkillList[#tSkillList+1] = tLifeSk
			end
		end
	end
	local tMsg = {}
	tMsg.tItemList = self:ItemSort(tSkillList)
	tMsg.nCurrVitality = self.m_oRole:GetVitality()
	tMsg.nMaxVitality = self.m_oRole:MaxVitality()
	print("活力兑换界面信息", tMsg.tItemList)
	self.m_oRole:SendMsg("lifeskillVitalityPagRet", tMsg)
end

function CAssistedSkill:ItemSort(tItemList)
	local tLifeList = {}
	local tOther
	local tTemp
	local bFalg = false
	local i 
	local j 
	for k, tItem in ipairs(tItemList) do
		if ctAssistedSkillConf[tItem.nSkillID] then
			tLifeList[#tLifeList+1] = tItem
		else
			tOther = tItem
		end
	end
	for i = 1, #tLifeList, 1 do
		for j = 1,#tLifeList - i, 1 do
			if ctAssistedSkillConf[tLifeList[i].nSkillID].tVitalityPage[1][2] > ctAssistedSkillConf[tLifeList[i+1].nSkillID].tVitalityPage[1][2] then
				tTemp = tLifeList[i]
				tLifeList[i] = tLifeList[i+1]
				tLifeList[i+1] = tTemp
				if not bFalg then bFalg = true end
			end	
		end 
		if not bFalg then break end
	end
	if tOther then
		table.insert(tLifeList, 1, tOther)
	end
	return tLifeList
end
function CAssistedSkill:GetVitalityInfo(tSkillCfg)
	local tItem = {}
	tItem.tPropList = {}
	tItem.nSkillID = tSkillCfg.nID
	tItem.nIcon = tSkillCfg.nIcon
	local nVitality = 0
	local tList = {}
	if tSkillCfg.nSkillSubType == gtSkillSubID.eLapping then
		for nPropID, tItemConf in pairs(ctAssistSkillProduct) do
			if tSkillCfg.nID == tItemConf.nAssistSkillId and self.m_tSkillMap[tSkillCfg.nID].nLevel >= tItemConf.nLevel then
				nVitality = tSkillCfg.eVigourConsumeFormula(tItemConf.nLevel)
				tList[#tList+1]= {nItemID = nPropID, nCostUC = nVitality}
			end
		end
		tItem.nType = 2
		tItem.tPropList = tList
	else
		tItem.nType = 1
		tItem.sName = tSkillCfg.sName
		tItem.nCostUC = tSkillCfg.eVigourConsumeFormula(self.m_tSkillMap[tSkillCfg.nID].nLevel)
	end
	return tItem
end


--活力兑换制造物品请求
function CAssistedSkill:VitalityMakeReq(nSkillID, nPropID)
	if not self:IsSysOpen() then
		return self.m_oRole:Tips("辅助技能功能尚未开启")
	end
	local tConf = ctAssistedSkillConf[nSkillID]
	if tConf then
		self:SkillManufactureItem(nSkillID, nPropID,1)
	else
		self.m_oRole.m_oSkill:ManufactureItemReq(nSkillID)
	end

	local tMsg = {}
	tMsg.nCurrVitality = self.m_oRole:GetVitality()
	tMsg.nMaxVitality = self.m_oRole:MaxVitality()
	print("活力兑换制造物品消息", tMsg)
	self.m_oRole:SendMsg("lifeskillVitalityMakeRet", tMsg)
end

--获取附魔技能
function CAssistedSkill:GetFuMoSkill()
	local tSkill = {}
	local tItemConf = ctFuMoSkillConf[self.m_oRole:GetSchool()]
	if not tItemConf then
		return self.m_oRole:Tips("附魔技能错误")
	end
	local nFuMoSkillID = tItemConf.nSkillID
	if not ctSkillConf[nFuMoSkillID] then
		return self.m_oRole:Tips("附魔技能配置不存在")
	end
	if not self.m_oRole.m_oSkill:GetSkill(nFuMoSkillID) then
		return
	end
	if self.m_oRole.m_oSkill:GetSkill(nFuMoSkillID).nLevel < self.m_oRole.m_oSkill:GetConf(nFuMoSkillID).nLearn then
		return 
	end
	local nCostVitality = tItemConf.eProduceCostVitalityFormula(self.m_oRole.m_oSkill:GetSkill(nFuMoSkillID).nLevel)
	local nStar = math.modf(tItemConf.eItemLevelFormula(self.m_oRole.m_oSkill:GetSkill(nFuMoSkillID).nLevel))
	local nItemID  = tItemConf["nSubProducts" .. nStar]
	if not nItemID then return end
	local nIcon = ctPropConf[nItemID].nIcon
	tSkill.nSkillID = nFuMoSkillID
	tSkill.nType = 1
	tSkill.nIcon = nIcon or 0
	tSkill.nCostUC = nCostVitality
	tSkill.sName = tItemConf.sItemName
	tSkill.tPropList = {}
	return tSkill
end

--增加活力
function CAssistedSkill:AddVitalityReq()
	local tProp = ctPropConf[nVitalityDan]
	if not tProp then
		return self.m_oRole:Tips("道具配置不存在")
	end
	if self.m_oRole:GetVitality() >= self.m_oRole:MaxVitality() then
		return self.m_oRole:Tips("活力达到上限了,不用加了哦")
	end
	local bRet = self.m_oRole:CheckSubItem(gtItemType.eProp, nVitalityDan, 1, "增加活力消耗")
	if bRet then
		self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eVitality, tProp.eParam(), "使用道具获得")
	else
		local nCostYuanBao = tProp.nBuyPrice
		local nYuanBaoType = tProp.nYuanBaoType
		local bRet = self.m_oRole:CheckSubItem(gtItemType.eCurr, nYuanBaoType, nCostYuanBao, "使用道具消耗")
		if bRet then
			self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eVitality, tProp.eParam(), "使用道具获得")
		else
			return self.m_oRole:YuanBaoTips()
		end
	end
	local tMsg = {}
	tMsg.nCurrVitality = self.m_oRole:GetVitality()
	tMsg.nMaxVitality = self.m_oRole:MaxVitality()
	print("增加活力返回", tMsg)
	self.m_oRole:SendMsg("lifeskillAddVitalityRet", tMsg)
end