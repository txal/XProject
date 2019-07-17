--时装
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CShiZhuang.tPos =
{
	eFlyMount = 1,  --飞行器
	eWing = 2,      --翅膀
	eHalo = 3,      --光影
}

function CShiZhuang:Ctor(oRole)
	self.m_oRole = oRole
	self.m_nCurrFlyMountID = 0              --当前使用飞行器ID
	self.m_nCurrWingID = 0                  --当前使用翅膀ID
	self.m_nCurrHaloID = 0                  --当前使用光影ID
	self.m_tShiZhuangMap = {}               --{[ShiZhuangID] = {}} 时装保存数据
	self.m_nQiLingExp = 0                   --器灵经验
	self.m_nQiLingLevel = 0                 --器灵等级
	self.m_nQiLingGrade = 0                 --器灵品阶
	
	--不保存数据
	self.m_tTotalAttr = {}                  --总属性
	self.m_tQiLingAttr = {}					--器灵属性
	self.m_tShiZhuangAndSuitAttr = {}		--时装和套装总属性

	self.m_tYuQiData = {}                   --御器数据
	self.m_tYuQiData.nLevel = 0
	self.m_tYuQiData.nExp = 0
	self.m_tYuQiData.tAttrList = {}

	self.m_tXianYuData = {}                 --仙羽数据
	self.m_tXianYuData.nLevel = 0
	self.m_tXianYuData.nExp = 0
	self.m_tXianYuData.tAttrList = {}
end

function CShiZhuang:LoadData(tData)
	if tData then
		self.m_nCurrFlyMountID = tData.m_nCurrFlyMountID or self.m_nCurrFlyMountID
		self.m_nCurrWingID = tData.m_nCurrWingID or self.m_nCurrWingID
		self.m_nCurrHaloID = tData.m_nCurrHaloID or self.m_nCurrHaloID
		self.m_tShiZhuangMap = tData.m_tShiZhuangMap or self.m_tShiZhuangMap
		for nID, tShiZhuang in pairs(self.m_tShiZhuangMap) do 
			if not tShiZhuang.tStrength then 
				tShiZhuang.tStrength = {nLevel = 0, nExp = 0}
				self:MarkDirty(true)
			end
			-- tShiZhuang.tBattleAttr = tData.tBattleAttr or {}
			-- tShiZhuang.tStrengthAttr = tData.tStrengthAttr or {}
			self:UpdateShiZhuangAttr(tShiZhuang)
		end

		self.m_nQiLingExp = tData.m_nQiLingExp or self.m_nQiLingExp
		self.m_nQiLingLevel = tData.m_nQiLingLevel or self.m_nQiLingLevel
		self.m_nQiLingGrade = tData.m_nQiLingGrade or self.m_nQiLingGrade

		self.m_tYuQiData = tData.m_tYuQiData or self.m_tYuQiData
		self.m_tXianYuData = tData.m_tXianYuData or self.m_tXianYuData

		self:UpdateYuQiAttr()
		self:UpdateXianYuAttr()
	end
end

function CShiZhuang:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
	local tData = {}
	tData.m_nCurrFlyMountID = self.m_nCurrFlyMountID
	tData.m_nCurrWingID = self.m_nCurrWingID
	tData.m_nCurrHaloID = self.m_nCurrHaloID
	tData.m_tShiZhuangMap = self.m_tShiZhuangMap
	tData.m_nQiLingExp = self.m_nQiLingExp
	tData.m_nQiLingLevel = self.m_nQiLingLevel
	tData.m_nQiLingGrade = self.m_nQiLingGrade

	tData.m_tYuQiData = self.m_tYuQiData
	tData.m_tXianYuData = self.m_tXianYuData
	return tData
end

function CShiZhuang:GetType()
	return gtModuleDef.tShiZhuang.nID, gtModuleDef.tShiZhuang.sName
end

function CShiZhuang:GetShiZhuang(nID)
	return self.m_tShiZhuangMap[nID]
end

--初始化时装数据
function CShiZhuang:InitShiZhuang(nShiZhuangID)
	assert(ctShiZhuangConf[nShiZhuangID], "不存在此时装")
	if self.m_tShiZhuangMap[nShiZhuangID] then return end
	self.m_tShiZhuangMap[nShiZhuangID] =
	{
		nShiZhuangID = nShiZhuangID,   --时装ID
		nPosType = ctShiZhuangConf[nShiZhuangID].nPosType,   --部位
		bIsAct = true,     --是否激活
		nValidTime = 0,     --有效时间戳
		tAttrList = {},     --属性列表  --原始基础属性
		tAttrListWash = {}, --洗出属性列表
		tStrength = {nLevel = 0, nExp = 0},  --强化数据
		tBattleAttr = {},    --最终属性
		tStrengthAttr = {},   --强化附加属性
	}
	
	--初始化每条初始属性
	for key, tAttrConf in ipairs(ctShiZhuangConf[nShiZhuangID].tAttrList) do
		local tAttr = {nAttrType = 0, nAttrVal = 0, nQuality = 0}
		local nRandQuality = math.random(6, 10)
		tAttr.nAttrType = tAttrConf[1]
		tAttr.nAttrVal = math.floor(tAttrConf[2] * nRandQuality / 10)
		tAttr.nQuality = nRandQuality   --正常数值应为0.6~1，增大十倍用于发送,如果是小数客户端解析为0
		table.insert(self.m_tShiZhuangMap[nShiZhuangID].tAttrList, tAttr)
	end
	self.m_tShiZhuangMap[nShiZhuangID].nValidTime = self:CalValidTimeStamp(nShiZhuangID)
	self:MarkDirty(true)
	local oDress = self:GetShiZhuang(nShiZhuangID) 
	self:UpdateShiZhuangAttr(oDress)
end

--计算有效期
function CShiZhuang:CalValidTimeStamp(nShiZhuangID)
	assert(ctShiZhuangConf[nShiZhuangID], "不存在此时装")
	local nConfTime = ctShiZhuangConf[nShiZhuangID].nValidTime
	local nSec = nConfTime * 24 * 3600
	local nValidTime = self.m_tShiZhuangMap[nShiZhuangID].nValidTime
	
	if nConfTime == - 1 then --永久
		return - 1
	else  --限时类型
		if nValidTime == 0 then
			return os.time() + nSec
		else    --已经激活的
			return nValidTime + nSec
		end
	end
end

--设置是否激活
function CShiZhuang:SetShiZhuangStatus(nShiZhuangID, bAct)
	assert(ctShiZhuangConf[nShiZhuangID] and bAct ~= nil, "设置时装状态参数有误")
	if not self.m_tShiZhuangMap[nShiZhuangID] then return end
	self.m_tShiZhuangMap[nShiZhuangID].bIsAct = bAct
	self:MarkDirty(true)
end

--设置有效时间
function CShiZhuang:SetValidTimeStamp(nShiZhuangID, nTimeStamp)
	assert(ctShiZhuangConf[nShiZhuangID] and nTimeStamp ~= nil, "设置时装有效期参数有误")
	if not self.m_tShiZhuangMap[nShiZhuangID] then return end
	if self.m_tShiZhuangMap[nShiZhuangID].nValidTime == - 1 then return end
	self.m_tShiZhuangMap[nShiZhuangID].nValidTime = nTimeStamp
	goLogger:EventLog(gtEvent.eShiZhuang, self.m_oRole, nShiZhuangID, self.m_tShiZhuangMap[nShiZhuangID].bIsAct, nTimeStamp)
	self:MarkDirty(true)
end

--时装是否已经激活
function CShiZhuang:IsActivated(nShiZhuangID)
	assert(type(nShiZhuangID) == "number", "时装是否激活参数有误")
	if not self.m_tShiZhuangMap[nShiZhuangID] then
		return false
	end
	
	if self.m_tShiZhuangMap[nShiZhuangID].bIsAct then
		return true
	else
		return false
	end
end

--增加器灵经验
function CShiZhuang:AddQiLingExp(nVal)
	local nExpUpLevel = ctQiLingLevelConf[self.m_nQiLingLevel].nNeedExp
	self.m_nQiLingExp = self.m_nQiLingExp + nVal
	if nExpUpLevel <= self.m_nQiLingExp then
		while(nExpUpLevel <= self.m_nQiLingExp) do
			if self.m_nQiLingLevel + 1 <= self:GetQiLingMaxLevel() then
				self.m_nQiLingLevel = self.m_nQiLingLevel + 1
				self.m_nQiLingExp = self.m_nQiLingExp - nExpUpLevel
				self:CalQiLingAttr()
				self.m_oRole:UpdateAttr()
				self:OnAttrChange()
				
				local tData = {}
				tData.nQiLingLevel = self.m_nQiLingLevel
				CEventHandler:OnQiLingUpLevel(self.m_oRole, tData)
				goLogger:EventLog(gtEvent.eQiLingUpgrade, self.m_oRole, self.m_nQiLingLevel, self.m_nQiLingGrade)

				nExpUpLevel = ctQiLingLevelConf[self.m_nQiLingLevel].nNeedExp
			else
				local nMaxLevelExp = ctQiLingLevelConf[self.m_nQiLingLevel].nNeedExp
				self.m_nQiLingExp = nMaxLevelExp
				break
			end
		end
	end
	self:SendQiLingInfo()
	self:MarkDirty(true)
end

function CShiZhuang:GetQiLingExp()
	return self.m_nQiLingExp
end

--背包使用时装道具激活时装
function CShiZhuang:ActShiZhuang(nShiZhuangID)
	if not ctShiZhuangConf[nShiZhuangID] then
		return self.m_oRole:Tips("不存在此时装")
	end
	
	if not self.m_tShiZhuangMap[nShiZhuangID] then  --初次激活
		self:InitShiZhuang(nShiZhuangID)
		self:OnFirstActive(nShiZhuangID)
	else
		self:SetShiZhuangStatus(nShiZhuangID, true)
		self:SetValidTimeStamp(nShiZhuangID, self:CalValidTimeStamp(nShiZhuangID))
	end
	self:MarkDirty(true)
	
	--计算总属性
	self.m_oRole:UpdateAttr()
	self:OnAttrChange()
	self:SendAllInfo()
end

--首次激活时装
function CShiZhuang:OnFirstActive(nShiZhuangID)
	local tConf = ctShiZhuangConf[nShiZhuangID]
	if not tConf then
		return
	end
	--传闻
	local tHearsyConf = ctHearsayConf["activefashion"]
	if tHearsyConf then
		CUtil:SendHearsayMsg(string.format(tHearsyConf.sHearsay, self.m_oRole:GetName(), tConf.sName))
	end
end

--时装所有信息请求
function CShiZhuang:AllInfoReq()
	self:SendAllInfo()
end

--激活时装请求
function CShiZhuang:ShiZhuangActReq(nShiZhuangID)
	if not ctShiZhuangConf[nShiZhuangID] then
		return self.m_oRole:Tips("不存在此时装")
	end

	if self.m_tShiZhuangMap[nShiZhuangID] then
		return self.m_oRole:Tips("时装已激活")		
	else
		local tCostConf = ctShiZhuangConf[nShiZhuangID].tCompound
		local tActCost = {{gtItemType.eProp, tCostConf[1][1], tCostConf[1][2]}}
		local bCostSucc = self.m_oRole:CheckSubShowNotEnoughTips(tActCost, "激活时装", true, true)
		if bCostSucc then
			self:InitShiZhuang(nShiZhuangID)
			self:MarkDirty(true)
			self.m_oRole:UpdateAttr()
			self:OnAttrChange()
			self:SendAllInfo()
		end
	end
end

--时装穿戴请求
function CShiZhuang:PutOnReq(nPosType, nShiZhuangID)
	assert(nPosType and self.m_tShiZhuangMap[nShiZhuangID], "穿戴时装参数有误")
	if nPosType < CShiZhuang.tPos.eFlyMount or nPosType > CShiZhuang.tPos.eHalo then
		return self.m_oRole:Tips("穿戴部位有误")
	end
	if not self:IsActivated(nShiZhuangID) then
		return self.m_oRole:Tips("时装未激活")
	end
	
	if nPosType == CShiZhuang.tPos.eFlyMount then
		self.m_nCurrFlyMountID = nShiZhuangID
		
	elseif nPosType == CShiZhuang.tPos.eWing then
		self.m_nCurrWingID = nShiZhuangID
		
	elseif nPosType == CShiZhuang.tPos.eHalo then
		self.m_nCurrHaloID = nShiZhuangID
	end
	self:MarkDirty(true)
	self:SendAllInfo()
	self.m_oRole:FlushRoleView()
end

--卸下时装
function CShiZhuang:PutOff(nPosType)
	if nPosType < CShiZhuang.tPos.eFlyMount or nPosType > CShiZhuang.tPos.eHalo then
		return self.m_oRole:Tips("卸下部位错误")
	end
	
	if nPosType == CShiZhuang.tPos.eFlyMount then
		self.m_nCurrFlyMountID = 0
		
	elseif nPosType == CShiZhuang.tPos.eWing then
		self.m_nCurrWingID = 0
		
	elseif nPosType == CShiZhuang.tPos.eHalo then
		self.m_nCurrHaloID = 0
	end
	self:MarkDirty(true)
	self:SendAllInfo()
	self.m_oRole:FlushRoleView()	
end

--时装洗练请求
function CShiZhuang:WashReq(nShiZhuangID, bIsUseGold)
	assert(self.m_tShiZhuangMap[nShiZhuangID] and bIsUseGold ~= nil, "时装洗练参数有误")
	if not self:IsActivated(nShiZhuangID) then
		return self.m_oRole:Tips("时装未激活")
	end
	
	--检查消耗
	local nCostItemID = 0
	local nCostNeed = 0
	local nItemType = 0
	local function ShiZhuangWash(bCostSucc)
		if bCostSucc then
			--洗练
			self.m_tShiZhuangMap[nShiZhuangID].tAttrListWash = {}
			for _, tAttrConf in ipairs(ctShiZhuangConf[nShiZhuangID].tAttrList) do
				local tAttr = {nAttrType = 0, nAttrVal = 0, nQuality = 0}
				local nRandQuality = math.random(6, 10)
				tAttr.nAttrType = tAttrConf[1]
				tAttr.nAttrVal = math.floor(tAttrConf[2] * nRandQuality / 10)
				tAttr.nQuality = nRandQuality
				table.insert(self.m_tShiZhuangMap[nShiZhuangID].tAttrListWash, tAttr)
			end
			self:MarkDirty(true)
			--下发协议
			self:SendShiZhuangInfo(nShiZhuangID)
		end
	end
	local tCost = ctShiZhuangConf[nShiZhuangID].tWashCost
	local tItemList = {{gtItemType.eProp, tCost[1][1], tCost[1][2]}}
	self.m_oRole:SubItemByYuanbao(tItemList, "时装洗练扣除", ShiZhuangWash, not bIsUseGold)
end

--时装属性替换请求
function CShiZhuang:AttrReplaceReq(nShiZhuangID)
	if not self:IsActivated(nShiZhuangID) then
		return self.m_oRole:Tips("时装未激活")
	end
	--复制属性
	local tAtrr = self.m_tShiZhuangMap[nShiZhuangID].tAttrList
	local tAtrrWash = self.m_tShiZhuangMap[nShiZhuangID].tAttrListWash
	if not next(tAtrrWash) then
		return self.m_oRole:Tips("没有替换属性")
	end
	for key, tData in ipairs(tAtrr) do
		if tData.nAttrType == tAtrrWash[key].nAttrType then
			tData.nAttrVal = tAtrrWash[key].nAttrVal
			tData.nQuality = tAtrrWash[key].nQuality
			tAtrrWash[key] = nil
		end
	end
	self:MarkDirty(true)
	local oDress = self:GetShiZhuang(nShiZhuangID)
	self:UpdateShiZhuangAttr(oDress)
	self.m_oRole:UpdateAttr()
	self:OnAttrChange()
	self:SendShiZhuangInfo(nShiZhuangID)
	self:SendAllInfo()
end

--取时装与器灵总的战斗属性
function CShiZhuang:GetBattleAttr()
    local tBattleAttr = {}
	self:CalQiLingAttr()
	self:CalShiZhuangAndSuitAttr()
	for nAttrIndex, nAttr in pairs(self.m_tShiZhuangAndSuitAttr) do
		local nOldAttr = tBattleAttr[nAttrIndex] or 0
		tBattleAttr[nAttrIndex] = nOldAttr + nAttr
	end

	for nAttrIndex, nAttr in pairs(self.m_tQiLingAttr) do
		local nOldAttr = tBattleAttr[nAttrIndex] or 0
		tBattleAttr[nAttrIndex] = nOldAttr + nAttr
	end

	--PrintTable(tBattleAttr)
	return tBattleAttr
end

function CShiZhuang:CalcAttrScore()
	local nScore = 0
	local tAttrList = self:GetBattleAttr()
	for nAttrID, nAttrVal in pairs(tAttrList) do
		nScore = nScore + CUtil:CalcAttrScore(nAttrID, nAttrVal)
	end
	return nScore
end

function CShiZhuang:CalShiZhuangAttrScore()
	local nScore = 0
	for nAttrID, nAttrVal in pairs(self.m_tShiZhuangAndSuitAttr) do
		nScore = nScore + CUtil:CalcAttrScore(nAttrID, nAttrVal)
	end
	return nScore
end

function CShiZhuang:CalQiLingAttrScore()
	-- local nScore = 0
	-- for nAttrID, nAttrVal in pairs(self.m_tQiLingAttr) do
	-- 	nScore = nScore + CUtil:CalcAttrScore(nAttrID, nAttrVal)
	-- end
	-- return nScore
	local nLevel = self.m_nQiLingLevel
	return math.floor(nLevel*1000*self:GetQiLingAttrFixParam())
end

--检查时装有效期
function CShiZhuang:CheckAndSetStatus()
	local bHadChange = false
	local nNowSec = os.time()
	for nShiZhuangID, tData in pairs(self.m_tShiZhuangMap) do
		if self:IsActivated(nShiZhuangID) and 0 < tData.nValidTime and tData.nValidTime <= nNowSec then
			self:SetShiZhuangStatus(nShiZhuangID, false)
			--主动卸下当前穿着过期的时装
			if nShiZhuangID == self.m_nCurrFlyMountID then
				self:PutOff(CShiZhuang.tPos.eFlyMount)
			elseif nShiZhuangID == self.m_nCurrWingID then
				self:PutOff(CShiZhuang.tPos.eWing)
			elseif nShiZhuangID == self.m_nCurrHaloID then
				self:PutOff(CShiZhuang.tPos.eHalo)
			end
			self:SetValidTimeStamp(nShiZhuangID, 0)
			bHadChange = true
			self:SendShiZhuangInfo(nShiZhuangID)
		end
	end
	if bHadChange then
		self.m_oRole:UpdateAttr()
		self:OnAttrChange()
		self:MarkDirty(true)
	end
end

--器灵请求所有信息
function CShiZhuang:QiLingInfoReq()
    self:CalQiLingAttr()
	self:SendQiLingInfo()
end

--器灵一键升级
function CShiZhuang:QiLingAutoUpLevel()
	local nUpLevelCostAID = 10108			--没地方配写死
	local nUpLevelCostBID = 10109
	local nHadCostANum = self.m_oRole:ItemCount(gtItemType.eProp, nUpLevelCostAID)
	local nHadCostBNum = self.m_oRole:ItemCount(gtItemType.eProp, nUpLevelCostBID)
	if (nHadCostANum == 0) and (nHadCostBNum == 0) then
		return self.m_oRole:Tips("没有用于升级器灵消耗的物品")
	end

	--判断当前是否可以升阶
	local nCanUp = math.floor(self.m_nQiLingLevel / 10)
	local nCurrGrade = self.m_nQiLingGrade
	if nCurrGrade < nCanUp then
		return self.m_oRole:Tips("器灵升阶才能继续升级")
	end
	--判断当前是否可以升级
	local nCurrLevel = self.m_nQiLingLevel
	if nCurrLevel >= CShiZhuang:GetQiLingMaxLevel() then
		return self.m_oRole:Tips("器灵已达到最高级")
	end

	--计算升级所需经验
	local nCurrQiLingExp = self:GetQiLingExp()
	local nExp = ctQiLingLevelConf[nCurrLevel].nNeedExp - nCurrQiLingExp    --下一级需要的经验
	local nNextLevel = nCurrLevel + 1
	local nCurrGradeMaxLevel = nCurrGrade * 10 + 9
	local nUpNextGradeExp = nExp                        --升到下一阶所需总经验
	for i=nNextLevel, nCurrGradeMaxLevel, 1 do
		nUpNextGradeExp = nUpNextGradeExp + ctQiLingLevelConf[i].nNeedExp
	end
	--print(">>>>>>>>>>>>>>器灵一键升级所需经验:", nUpNextGradeExp)
	local fnCalCostAExp = ctPropConf[nUpLevelCostAID].eParam
	local nCostAExp = fnCalCostAExp()
	local nNeedCostANum = math.ceil(nUpNextGradeExp / nCostAExp)
	local fnCalCostBExp = ctPropConf[nUpLevelCostBID].eParam
	local nCostBExp = fnCalCostBExp()
	local nRealCostANum = 0
	local nRealCostBNum = 0		
	if nHadCostANum < nNeedCostANum then
		nRealCostANum = nHadCostANum
		local nNeedCostBNum = math.ceil((nUpNextGradeExp - nRealCostANum*nCostAExp) / nCostBExp)
		if nHadCostBNum < nNeedCostBNum then
			nRealCostBNum = nHadCostBNum
		else
			nRealCostBNum = nNeedCostBNum
		end
	else
		nRealCostANum = nNeedCostANum
	end
	if nRealCostANum > 0 then
		self.m_oRole:AddItem(gtItemType.eProp, nUpLevelCostAID, -nRealCostANum, "使用器灵经验丹")
		-- local sName = ctPropConf[nPropID].sName
		-- self.m_oRole:Tips(sName.."使用成功")
		self:AddQiLingExp(nCostAExp * nRealCostANum)
	end
	if nRealCostBNum > 0 then
		self.m_oRole:AddItem(gtItemType.eProp, nUpLevelCostBID, -nRealCostBNum, "使用器灵经验丹")
		self:AddQiLingExp(nCostBExp * nRealCostBNum)
	end
	--print(">>器灵升级消耗经验丹", nRealCostANum, "经验值:", nCostAExp * nRealCostANum, "消耗精髓丹:", nRealCostBNum, "经验值:", nCostBExp * nRealCostBNum)
end

--器灵升品阶
function CShiZhuang:QiLingUpGrade()
	if self.m_nQiLingGrade == self:GetQiLingMaxGrade() then
		return self.m_oRole:Tips("器灵已经最高阶")
	end
	local nLevelLimit = ctQiLingGradeConf[self.m_nQiLingGrade + 1].nLevelLimit
	if self.m_oRole:GetLevel() < nLevelLimit then
		return self.m_oRole:Tips(string.format("人物需要达到%d级", nLevelLimit))
	end
	
	if self.m_nQiLingGrade >= math.floor(self.m_nQiLingLevel / 10) then
		return self.m_oRole:Tips("未能升阶")
	end
	
	--检查消耗的物品
	local tCostList = ctQiLingGradeConf[self.m_nQiLingGrade + 1].tGradeCost
	local bItemEnought = true
	for key, tCost in ipairs(tCostList) do
		if self.m_oRole:ItemCount(gtItemType.eProp, tCost[1]) < tCost[2] then
			bItemEnought = false
		end
	end
	if not bItemEnought then
		return self.m_oRole:Tips("消耗物品不足")
	end
	
	--消耗物品
	for key, tCost in ipairs(tCostList) do
		self.m_oRole:AddItem(gtItemType.eProp, tCost[1], - tCost[2], "器灵进阶消耗")
	end
	self.m_nQiLingGrade = self.m_nQiLingGrade + 1
	self:MarkDirty(true)
	self:SendQiLingInfo()
	self.m_oRole:UpdateAttr()
	self:OnAttrChange()
	local tData = {}
	tData.nQiLingGrade = self.m_nQiLingGrade
	CEventHandler:OnQiLingUpGrade(self.m_oRole, tData)
end

--计算时装和套装的属性总和
function CShiZhuang:CalShiZhuangAndSuitAttr()
	local tShiZhuangAndSuitArrt = {}
	for key, tShiZhuang in pairs(self.m_tShiZhuangMap) do
		if tShiZhuang.bIsAct then
			-- for _, tAttr in pairs(tShiZhuang.tAttrList) do
			-- 	local nOldAttr = tShiZhuangAndSuitArrt[tAttr.nAttrType] or 0
			-- 	tShiZhuangAndSuitArrt[tAttr.nAttrType] = nOldAttr + tAttr.nAttrVal
			-- end
			for nAttrID, nAttrVal in pairs(tShiZhuang.tBattleAttr) do 
				local nOldVal = tShiZhuangAndSuitArrt[nAttrID] or 0
				tShiZhuangAndSuitArrt[nAttrID] = nOldVal + nAttrVal
			end
		end
	end

	--每次重新计算套装的属性
	local tSuitActRec = {}
	for nShiZhuangID, tData in pairs(self.m_tShiZhuangMap) do
		if tData.bIsAct then    --是否激活
			if ctShiZhuangConf[nShiZhuangID].bIsSuit then   --是否是套装
				local nSuitIndex = ctShiZhuangConf[nShiZhuangID].nSuitIndex
				local tSuitIDList = ctSuitConf[nSuitIndex].tSuitIDList
				local nCountAct = 0     --统计一个套装已经激活几个包含的时装
				for _, tSuitID in ipairs(tSuitIDList) do
					if self:IsActivated(tSuitID[1]) then
						nCountAct = nCountAct + 1
					end
				end
				tSuitActRec[nSuitIndex] = nCountAct
			end
		end
	end
	for nSuitIndex, nNumAct in pairs(tSuitActRec) do
		local tAttrList = nil
		if nNumAct > 1 then     --套装激活两件件以上才有额外属性
			if nNumAct == 2 then
				tAttrList = ctSuitConf[nSuitIndex].tAttrActTwo
			elseif nNumAct == 3 then
				tAttrList = ctSuitConf[nSuitIndex].tAttrActThree
			end
			for _, tAttr in ipairs(tAttrList) do
				local nOldAttr = tShiZhuangAndSuitArrt[tAttr[1]] or 0				
				tShiZhuangAndSuitArrt[tAttr[1]] = nOldAttr + tAttr[2]
			end
		end
	end
	self.m_tShiZhuangAndSuitAttr = table.DeepCopy(tShiZhuangAndSuitArrt)
end

function CShiZhuang:GetQiLingAttrFixParam()
	return ctRoleModuleAttrFixParamConf[101].nFixParam
end

--计算器灵属性(仅仅器灵的属性)
function CShiZhuang:CalQiLingAttr()
	-- assert(ctQiLingLevelConf[self.m_nQiLingLevel], "器灵等级错误")
	-- local fnCalQiXue = ctQiLingLevelConf[self.m_nQiLingLevel].fnAttrQiXue
	-- local fnCalGongJi = ctQiLingLevelConf[self.m_nQiLingLevel].fnAttrGongJi
	-- local fnCalFangYu = ctQiLingLevelConf[self.m_nQiLingLevel].fnAttrFangYu
	-- local fnCalLingLi = ctQiLingLevelConf[self.m_nQiLingLevel].fnAttrLingLi
	-- local fnCalMoFa = ctQiLingLevelConf[self.m_nQiLingLevel].fnAttrMoFa
	-- local fnCalSuDu = ctQiLingLevelConf[self.m_nQiLingLevel].fnAttrSuDu
	-- local nAttrQiXue = fnCalQiXue(self.m_nQiLingLevel, self.m_nQiLingGrade)
	-- local nAttrGongJi = fnCalGongJi(self.m_nQiLingLevel, self.m_nQiLingGrade)
	-- local nAttrFangYu = fnCalFangYu(self.m_nQiLingLevel, self.m_nQiLingGrade)
	-- local nAttrLingLi = fnCalLingLi(self.m_nQiLingLevel, self.m_nQiLingGrade)
	-- local nAttrMoFa = fnCalMoFa(self.m_nQiLingLevel, self.m_nQiLingGrade)
    -- local nAttrSuDu = fnCalSuDu(self.m_nQiLingLevel, self.m_nQiLingGrade)
    
	-- --策划定属性是独立某等级的不是等级累加的
	-- self.m_tQiLingAttr[gtBAT.eQX] = self.m_tQiLingAttr[gtBAT.eQX] or 0
	-- self.m_tQiLingAttr[gtBAT.eGJ] = self.m_tQiLingAttr[gtBAT.eGJ] or 0
	-- self.m_tQiLingAttr[gtBAT.eFY] = self.m_tQiLingAttr[gtBAT.eFY] or 0
	-- self.m_tQiLingAttr[gtBAT.eLL] = self.m_tQiLingAttr[gtBAT.eLL] or 0
	-- self.m_tQiLingAttr[gtBAT.eMF] = self.m_tQiLingAttr[gtBAT.eMF] or 0
	-- self.m_tQiLingAttr[gtBAT.eSD] = self.m_tQiLingAttr[gtBAT.eSD] or 0
	-- self.m_tQiLingAttr[gtBAT.eQX] = nAttrQiXue
	-- self.m_tQiLingAttr[gtBAT.eGJ] = nAttrGongJi 
	-- self.m_tQiLingAttr[gtBAT.eFY] = nAttrFangYu 
	-- self.m_tQiLingAttr[gtBAT.eLL] = nAttrLingLi 
	-- self.m_tQiLingAttr[gtBAT.eMF] = nAttrMoFa 
    -- self.m_tQiLingAttr[gtBAT.eSD] = nAttrSuDu  
    -- print(">>>>>>>>>>>>>>>>>>>>器灵总属性")
	-- PrintTable(self.m_tQiLingAttr)
	
	-- local nLevel = self.m_nQiLingLevel
	-- local nParam = math.floor(nLevel*1000*self:GetQiLingAttrFixParam())
	local nParam = self:CalQiLingAttrScore()
	self.m_tQiLingAttr = self.m_oRole:CalcModuleGrowthAttr(nParam)
end

--每分钟检查一次有效期
function CShiZhuang:OnMinTimer()
	self:CheckAndSetStatus()
end

function CShiZhuang:Online()
	self:CheckAndSetStatus()
	self:AddQiLingExp(0)  --当升到最大级后追加配置时，加0经验只为做检查
	self:CalQiLingAttr()
	self:CalShiZhuangAndSuitAttr()
	self:SendAllInfo()
	self:SendQiLingInfo()
end

function CShiZhuang:GetQiLingMaxLevel()
	return #ctQiLingLevelConf
end

function CShiZhuang:GetQiLingMaxGrade()
	return #ctQiLingGradeConf
end

--时装所有信息应答
function CShiZhuang:SendAllInfo()
	local tMsg = {}
	tMsg.tShiZhuangInfoList = {}
	for nID, tShiZhuang in pairs(self.m_tShiZhuangMap) do
		-- local tSingleInfo = {}
		-- tSingleInfo.nShiZhuangID = tShiZhuang.nShiZhuangID
		-- tSingleInfo.nPosType = tShiZhuang.nPosType
		-- tSingleInfo.nValueTimeStamp = tShiZhuang.nValidTime
		-- tSingleInfo.bIsActivate = tShiZhuang.bIsAct
		-- tSingleInfo.tAttrList = tShiZhuang.tAttrList
		-- tSingleInfo.tAttrWashList = tShiZhuang.tAttrListWash
		local tSingleInfo = self:GetShiZhuangInfo(nID)
		table.insert(tMsg.tShiZhuangInfoList, tSingleInfo)
	end
	tMsg.nCurrFlyMountID = self.m_nCurrFlyMountID
	tMsg.nCurrWingID = self.m_nCurrWingID
	tMsg.nCurrHaloID = self.m_nCurrHaloID
	tMsg.nFightCapacity = self:CalShiZhuangAttrScore()
	self.m_oRole:SendMsg("ShiZhuangAllInfoRet", tMsg)
	--PrintTable(tMsg)
end

function CShiZhuang:GetShiZhuangInfo(nDressID)
	local oDress = self:GetShiZhuang(nDressID)
	assert(oDress)
	local tData = {}
	tData.nShiZhuangID = nDressID
	tData.nPosType = oDress.nPosType
	tData.nValueTimeStamp = oDress.nValidTime
	tData.bIsActivate = oDress.bIsAct
	tData.tAttrList = table.DeepCopy(oDress.tAttrList)
	tData.tAttrWashList = oDress.tAttrListWash

	for _, tAttr in ipairs(tData.tAttrList) do 
		local nAttrID = tAttr.nAttrType
		tAttr.nBattleVal = oDress.tBattleAttr[nAttrID] or (tAttr.nAttrVal or 0)
		tAttr.nStrengthVal = oDress.tStrengthAttr[nAttrID] or 0
	end

	tData.nStrengthLevel = oDress.tStrength.nLevel or 0
	tData.nStrengthExp = oDress.tStrength.nExp or 0
	
	return tData
end

--发送单个时装信息
function CShiZhuang:SendShiZhuangInfo(nShiZhuangID)
	if not self:IsActivated(nShiZhuangID) then
		return
	end
	local tShiZhuang = self.m_tShiZhuangMap[nShiZhuangID]
	if not tShiZhuang then 
		return 
	end
	-- local tInfo = {}
	-- tInfo.nShiZhuangID = tShiZhuang.nShiZhuangID
	-- tInfo.nPosType = tShiZhuang.nPosType
	-- tInfo.nValueTimeStamp = tShiZhuang.nValidTime
	-- tInfo.bIsActivate = tShiZhuang.bIsAct
	-- tInfo.tAttrList = tShiZhuang.tAttrList
	-- tInfo.tAttrWashList = tShiZhuang.tAttrListWash
	local tMsg = {tSingleInfo={}}
	local tInfo = self:GetShiZhuangInfo(nShiZhuangID)
	table.insert(tMsg.tSingleInfo, tInfo)
	self.m_oRole:SendMsg("ShiZhuangInfoRet", tMsg)
end

--器灵所有信息
function CShiZhuang:SendQiLingInfo()
	local tMsg = {tAttrList = {}}
	for nType, nAttrData in pairs(self.m_tQiLingAttr) do
		local tAttr = {}
		tAttr.nAttrType = nType
		tAttr.nAttrValue = nAttrData
		table.insert(tMsg.tAttrList, tAttr)
	end
	tMsg.nQiLingLevel = self.m_nQiLingLevel
	tMsg.nQiLingGrade = self.m_nQiLingGrade
	tMsg.nQiLingExp = self.m_nQiLingExp
	tMsg.nQiLingCapacity = self:CalQiLingAttrScore()
	
    self.m_oRole:SendMsg("QiLingInfoRet", tMsg)
    -- print(">>>>>>>>>>>>>>>>>>>>>>>器灵总属性")
    -- PrintTable(tMsg)
end

function CShiZhuang:OnAttrChange()
	self.m_oRole:UpdateActGTDressPower()
end

function CShiZhuang:GetYuQiGrowthID()
	return 1
end

function CShiZhuang:IsYuQiSysOpen(bTips)
	return self.m_oRole:IsSysOpen(90, bTips)
end

function CShiZhuang:GetYuQiLevel()
	return self.m_tYuQiData and self.m_tYuQiData.nLevel or 0
end

function CShiZhuang:GetYuQiLimitLevel()
	local nID = self:GetYuQiGrowthID()
	return math.min(self.m_oRole:GetLevel() * 8, ctRoleGrowthConf.GetConfMaxLevel(nID))
end

function CShiZhuang:SetYuQiLevel(nLevel)
	local nID = self:GetYuQiGrowthID()
	assert(nLevel > 0 and nLevel <= ctRoleGrowthConf.GetConfMaxLevel(nID))
	self.m_tYuQiData.nLevel = nLevel
	self:MarkDirty(true)
end

function CShiZhuang:GetYuQiExp()
	return self.m_tYuQiData and self.m_tYuQiData.nExp or 0
end

function CShiZhuang:GetYuQiAttr()
	if not self:IsYuQiSysOpen() then 
		return {} 
	end
	return self.m_tYuQiData.tAttrList or {}
end

function CShiZhuang:GetYuQiAttrRatio()
	local nID = self:GetYuQiGrowthID()
	local tConf = ctRoleGrowthConf[nID]
	return tConf.nRatio or 1
end

function CShiZhuang:GetYuQiScore()
	if not self:IsYuQiSysOpen() then 
		return 0 
	end
	return math.floor(self:GetYuQiLevel()*1000*self:GetYuQiAttrRatio())
end

function CShiZhuang:UpdateYuQiAttr()
	-- local nParam = self:GetYuQiLevel()*1000*1
	local nParam = self:GetYuQiScore()
	self.m_tYuQiData.tAttrList = self.m_oRole:CalcModuleGrowthAttr(nParam) or {}
end

function CShiZhuang:OnYuQiLevelChange()
	self:UpdateYuQiAttr()
	self.m_oRole:UpdateAttr()
end

function CShiZhuang:AddYuQiExp(nAddExp)
	local nID = self:GetYuQiGrowthID()
	local nCurLevel = self:GetYuQiLevel()
	local nLimitLevel = self:GetYuQiLimitLevel()
	local nCurExp = self:GetYuQiExp()
	local nTarLevel, nTarExp = ctRoleGrowthConf.AddExp(nID, nCurLevel, nLimitLevel, nCurExp, nAddExp)
	self:SetYuQiLevel(nTarLevel)
	self.m_tYuQiData.nExp = nTarExp
	self:MarkDirty(true)
	if nCurLevel ~= nTarLevel then 
		self:OnYuQiLevelChange()
	end
end

function CShiZhuang:SyncYuQiData()
	local tMsg = {}
	tMsg.nTotalLevel = self.m_tYuQiData.nLevel
	tMsg.nExp = self.m_tYuQiData.nExp
	tMsg.tAttrList = {}
	for nAttrID, nAttrVal in pairs(self.m_tYuQiData.tAttrList) do 
		table.insert(tMsg.tAttrList, {nAttrID = nAttrID, nAttrVal = nAttrVal})
	end
	tMsg.nScore = self:GetYuQiScore()
	self.m_oRole:SendMsg("ShiZhuangYuQiInfoRet", tMsg)
end

function CShiZhuang:YuQiLevelUpReq()
	if not self:IsYuQiSysOpen(true) then 
		return 
	end
	local oRole = self.m_oRole
	local nGrowthID = self:GetYuQiGrowthID()
	local nCurLevel = self:GetYuQiLevel()
	local nLimitLevel = self:GetYuQiLimitLevel()
	local nCurExp = self:GetYuQiExp()
	if nCurLevel >= ctRoleGrowthConf.GetConfMaxLevel(nGrowthID) then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	if nCurLevel >= nLimitLevel then 
		oRole:Tips("已达到当前限制等级，请先提升角色等级")
		return 
	end

	local nMaxAddExp = ctRoleGrowthConf.GetMaxAddExp(nGrowthID, nCurLevel, nLimitLevel, nCurExp)
	if nMaxAddExp <= 0 then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	local tCost = ctRoleGrowthConf.GetExpItemCost(nGrowthID, nMaxAddExp)
	assert(next(tCost))
	local nItemType = tCost[1]
	local nItemID = tCost[2]
	local nMaxItemNum = tCost[3]
	assert(nItemType > 0 and nItemID > 0 and nMaxItemNum > 0)
	local nKeepNum = oRole:ItemCount(nItemType, nItemID)
	if nKeepNum <= 0 then 
		oRole:Tips("材料不足，无法升级")
		return 
	end
	local nCostNum = math.min(nKeepNum, nMaxItemNum)
	local nAddExp = ctRoleGrowthConf.GetItemExp(nGrowthID, nItemType, nItemID, nCostNum)
	assert(nAddExp and nAddExp > 0)

	local tCost = {{nItemType, nItemID, nCostNum}, }
	if not oRole:CheckSubShowNotEnoughTips(tCost, "时装御器升级", true) then 
		return 
	end
	self:AddYuQiExp(nAddExp)
	self:SyncYuQiData()

	local nResultLevel = self:GetYuQiLevel()
	local sContent = nil 
	local sModuleName = "御器"
	local sPropName = ctPropConf:GetFormattedName(nItemID) --暂时只支持道具
	if nResultLevel > nCurLevel then 
		local sTemplate = "消耗%d个%s, %s等级提升到%d级"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nResultLevel)
	else
		local sTemplate = "消耗%d个%s, %s增加%d经验"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nAddExp)
	end
	if sContent then 
		oRole:Tips(sContent)
	end


	local tMsg = {}
	tMsg.nOldLevel = nCurLevel
	tMsg.nCurLevel = self:GetYuQiLevel()
	oRole:SendMsg("ShiZhuangYuQiLevelUpRet", tMsg)
end

function CShiZhuang:GetXianYuGrowthID()
	return 2
end

function CShiZhuang:IsXianYuSysOpen(bTips)
	return self.m_oRole:IsSysOpen(91, bTips)
end

function CShiZhuang:GetXianYuLevel()
	return self.m_tXianYuData and self.m_tXianYuData.nLevel or 0
end

function CShiZhuang:GetXianYuLimitLevel()
	local nID = self:GetXianYuGrowthID()
	return math.min(self.m_oRole:GetLevel(), ctRoleGrowthConf.GetConfMaxLevel(nID))
end

function CShiZhuang:SetXianYuLevel(nLevel)
	local nID = self:GetXianYuGrowthID()
	assert(nLevel > 0 and nLevel <= ctRoleGrowthConf.GetConfMaxLevel(nID))
	self.m_tXianYuData.nLevel = nLevel
	self:MarkDirty(true)
end

function CShiZhuang:GetXianYuExp()
	return self.m_tXianYuData and self.m_tXianYuData.nExp or 0
end

function CShiZhuang:GetXianYuAttr()
	if not self:IsXianYuSysOpen() then 
		return {}
	end
	return self.m_tXianYuData.tAttrList or {}
end

function CShiZhuang:GetXianYuAttrRatio()
	local nID = self:GetXianYuGrowthID()
	local tConf = ctRoleGrowthConf[nID]
	return tConf.nRatio or 1
end

function CShiZhuang:GetXianYuScore()
	if not self:IsXianYuSysOpen() then 
		return 0
	end
	return math.floor(self:GetXianYuLevel()*1000*self:GetXianYuAttrRatio())
end

function CShiZhuang:UpdateXianYuAttr()
	-- local nParam = self:GetXianYuLevel()*1000*1
	local nParam = self:GetXianYuScore()
	self.m_tXianYuData.tAttrList = self.m_oRole:CalcModuleGrowthAttr(nParam) or {}
end

function CShiZhuang:OnXianYuLevelChange()
	self:UpdateXianYuAttr()
	self.m_oRole:UpdateAttr()
end

function CShiZhuang:AddXianYuExp(nAddExp)
	local nID = self:GetXianYuGrowthID()
	local nCurLevel = self:GetXianYuLevel()
	local nLimitLevel = self:GetXianYuLimitLevel()
	local nCurExp = self:GetXianYuExp()
	local nTarLevel, nTarExp = ctRoleGrowthConf.AddExp(nID, nCurLevel, nLimitLevel, nCurExp, nAddExp)
	self:SetXianYuLevel(nTarLevel)
	self.m_tXianYuData.nExp = nTarExp
	self:MarkDirty(true)
	if nCurLevel ~= nTarLevel then 
		self:OnXianYuLevelChange()
	end
end

function CShiZhuang:SyncXianYuData()
	local tMsg = {}
	tMsg.nLevel = self.m_tXianYuData.nLevel
	tMsg.nExp = self.m_tXianYuData.nExp
	tMsg.tAttrList = {}
	for nAttrID, nAttrVal in pairs(self.m_tXianYuData.tAttrList) do 
		table.insert(tMsg.tAttrList, {nAttrID = nAttrID, nAttrVal = nAttrVal})
	end
	tMsg.nScore = self:GetXianYuScore()
	self.m_oRole:SendMsg("ShiZhuangXianYuInfoRet", tMsg)
end

function CShiZhuang:XianYuLevelUpReq()
	if not self:IsXianYuSysOpen(true) then 
		return 
	end
	local oRole = self.m_oRole
	local nGrowthID = self:GetXianYuGrowthID()
	local nCurLevel = self:GetXianYuLevel()
	local nLimitLevel = self:GetXianYuLimitLevel()
	local nCurExp = self:GetXianYuExp()
	if nCurLevel >= ctRoleGrowthConf.GetConfMaxLevel(nGrowthID) then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	if nCurLevel >= nLimitLevel then 
		oRole:Tips("已达到当前限制等级，请先提升角色等级")
		return 
	end

	local nMaxAddExp = ctRoleGrowthConf.GetMaxAddExp(nGrowthID, nCurLevel, nLimitLevel, nCurExp)
	if nMaxAddExp <= 0 then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	local tCost = ctRoleGrowthConf.GetExpItemCost(nGrowthID, nMaxAddExp)
	assert(next(tCost))
	local nItemType = tCost[1]
	local nItemID = tCost[2]
	local nMaxItemNum = tCost[3]
	assert(nItemType > 0 and nItemID > 0 and nMaxItemNum > 0)
	local nKeepNum = oRole:ItemCount(nItemType, nItemID)
	if nKeepNum <= 0 then 
		oRole:Tips("材料不足，无法升级")
		return 
	end
	local nCostNum = math.min(nKeepNum, nMaxItemNum)
	local nAddExp = ctRoleGrowthConf.GetItemExp(nGrowthID, nItemType, nItemID, nCostNum)
	assert(nAddExp and nAddExp > 0)

	local tCost = {{nItemType, nItemID, nCostNum}, }
	if not oRole:CheckSubShowNotEnoughTips(tCost, "时装仙羽升级", true) then 
		return 
	end
	self:AddXianYuExp(nAddExp)
	self:SyncXianYuData()

	local nResultLevel = self:GetXianYuLevel()
	local sContent = nil 
	local sModuleName = "仙羽"
	local sPropName = ctPropConf:GetFormattedName(nItemID) --暂时只支持道具
	if nResultLevel > nCurLevel then 
		local sTemplate = "消耗%d个%s, %s等级提升到%d级"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nResultLevel)
	else
		local sTemplate = "消耗%d个%s, %s增加%d经验"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nAddExp)
	end
	if sContent then 
		oRole:Tips(sContent)
	end

	local tMsg = {}
	tMsg.nOldLevel = nCurLevel
	tMsg.nCurLevel = self:GetXianYuLevel()
	oRole:SendMsg("ShiZhuangXianYuLevelUpRet", tMsg)
end

function CShiZhuang:GetStrengthGrowthID()
	return 3
end

function CShiZhuang:IsStrengthSysOpen(bTips)
	return self.m_oRole:IsSysOpen(92, bTips)
end

function CShiZhuang:GetStrengthLimitLevel()
	local nID = self:GetStrengthGrowthID()
	return ctRoleGrowthConf.GetConfMaxLevel(nID)
end

function CShiZhuang:UpdateShiZhuangAttr(oDress)
	if not oDress then 
		return 
	end
	local nGrowthID = self:GetStrengthGrowthID()
	local nStrengthRatio = ctRoleGrowthConf[nGrowthID].nParam
	local nStrengthLevel = oDress.tStrength.nLevel
	local nStrengthAdd = nStrengthRatio * nStrengthLevel
	
	local tBattleAttrList = {}
	local tStrengthAttrList = {}
	
	for _, tAttr in ipairs(oDress.tAttrList) do 
		local nBaseVal = tAttr.nAttrVal
		local nBattleVal = math.floor(nBaseVal*(1 + nStrengthAdd))
		local nStrengthVal = nBattleVal - nBaseVal
		
		tBattleAttrList[tAttr.nAttrType] = nBattleVal
		tStrengthAttrList[tAttr.nAttrType] = nStrengthVal
	end
	oDress.tBattleAttr = tBattleAttrList
	oDress.tStrengthAttr = tStrengthAttrList
end

function CShiZhuang:OnStrengthLevelUp(nDressID)
	local oDress = self:GetShiZhuang(nDressID)
	if not oDress then 
		return 
	end
	self:UpdateShiZhuangAttr(oDress)
	self.m_oRole:UpdateAttr()
	self:OnAttrChange()
	self:SendAllInfo()
end

function CShiZhuang:AddStrengthExp(nDressID, nAddExp)
	local oDress = self:GetShiZhuang(nDressID)
	assert(oDress)
	local nGrowthID = self:GetStrengthGrowthID()
	local nCurLevel = oDress.tStrength.nLevel
	local nLimitLevel = self:GetStrengthLimitLevel()
	local nCurExp = oDress.tStrength.nExp
	local nTarLevel, nTarExp = ctRoleGrowthConf.AddExp(nGrowthID, nCurLevel, nLimitLevel, nCurExp, nAddExp)
	oDress.tStrength.nLevel = nTarLevel
	oDress.tStrength.nExp = nTarExp
	self:MarkDirty(true)
	self:OnStrengthLevelUp(nDressID)
end

function CShiZhuang:StrengthLevelUpReq(nDressID, nPropID, nPropNum)
	if nDressID <= 0 or nPropID <= 0 or nPropNum <= 0 then 
		self.m_oRole:Tips("参数不合法")
		return 
	end
	if not self:IsStrengthSysOpen(true) then 
		return
	end
	local oRole = self.m_oRole
	local oDress = self:GetShiZhuang(nDressID)
	if not oDress then 
		oRole:Tips("当前时装未激活")
		return 
	end
	if nPropNum <= 0 then 
		oRole:Tips("参数错误")
		return
	end
	local nGrowthID = self:GetStrengthGrowthID()
	local tGrowthConf = ctRoleGrowthConf[nGrowthID]
	assert(tGrowthConf)
	local bItemValid = false
	local nSingleExp = 0
	for _, tItem in ipairs(tGrowthConf.tExpProp) do 
		local nItemType = tItem[1]
		local nItemID = tItem[2]
		local nAddExp  = tItem[3]
		if nItemType > 0 and nPropID > 0 and nPropID == nItemID then 
			bItemValid = true
			nSingleExp = nAddExp
			break
		end
	end
	if not bItemValid then 
		oRole:Tips("道具不合法")
		return 
	end
	assert(nSingleExp > 0, "配置错误")

	local nCurLevel = oDress.tStrength.nLevel
	local nLimitLevel = self:GetStrengthLimitLevel()
	local nCurExp = oDress.tStrength.nExp

	if nCurLevel >= ctRoleGrowthConf.GetConfMaxLevel(nGrowthID) then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	-- if nCurLevel >= nLimitLevel then 
	-- 	oRole:Tips("已达到当前限制等级，请先提升角色等级")
	-- 	return 
	-- end

	local nTotalAddExp = nPropNum * nSingleExp
	local nTotalExp = nTotalAddExp + nCurExp

	local nMaxAddExp = 0
	local tLevelConfList = ctRoleGrowthConf.GetLevelConfList(nGrowthID)
	for k = nCurLevel + 1, nLimitLevel do 
		local tLevelConf = tLevelConfList[k]
		assert(tLevelConf)
		nMaxAddExp = nMaxAddExp + tLevelConf.nExp
		if nTotalExp <= nMaxAddExp then 
			break
		end
	end
	if nMaxAddExp < nTotalExp then 
		local nAllowed = nMaxAddExp - nCurExp
		nPropNum = math.min(math.ceil(nAllowed/nSingleExp), nPropNum) --经验溢出, 修正下数量
	end
	assert(nPropNum > 0)

	local tCost = {gtItemType.eProp, nPropID, nPropNum}
	local tCostList = {}
	table.insert(tCostList, tCost)
	if not oRole:CheckSubShowNotEnoughTips(tCostList, "时装强化升级", true) then 
		return 
	end
	local nTotalAddExp = nPropNum * nSingleExp
	self:AddStrengthExp(nDressID, nTotalAddExp)
	self:SendShiZhuangInfo(nDressID)
end
