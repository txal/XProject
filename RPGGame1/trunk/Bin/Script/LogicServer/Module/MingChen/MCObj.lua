local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--技能配置预处理
local _MingChenSkillConf = {}
local _MingChenSkillAdvanceConf = {}
local function PreProcessSkillConf()
	for _, tConf in ipairs(ctMingChenSkillConf) do
		_MingChenSkillConf[tConf.nSkID] = _MingChenSkillConf[tConf.nSkID] or {}
		table.insert(_MingChenSkillConf[tConf.nSkID], tConf)
	end
	for _, tConf in ipairs(ctMingChenSkillAdvanceConf) do
		_MingChenSkillAdvanceConf[tConf.nSkID] = _MingChenSkillAdvanceConf[tConf.nSkID] or {}
		_MingChenSkillAdvanceConf[tConf.nSkID][tConf.nLv] = tConf
	end
end
PreProcessSkillConf()

--名臣对象
function CMCObj:Ctor(oModule, oPlayer, nSysID, nQinMi)
	self.m_oModule = oModule
	self.m_oPlayer = oPlayer

	local tConf = assert(ctMingChenConf[nSysID])
	self.m_nSysID = nSysID 			--配置ID
	self.m_sName = tConf.sName 		--名字
	
	self.m_nTec = tConf.nTec 		--特长资质
	self.m_nLv = tConf.nLv 			--等级
	self.m_nJWLv = 0 				--爵位等级

	self.m_nHlLv = 0 				--花翎等级
	self.m_nYinLiang = 0 			--升级投入银两
	self.m_nHistoryLv = self.m_nLv 	--历史最高等级

	self.m_nPinJi = tConf.nPinJi	--品级
	self.m_tQua = table.DeepCopy(tConf.tInitQua[1])		--资质
	self.m_tQuaGrow = table.DeepCopy(tConf.tQuaGrow[1]) --资质成长点

	self.m_tAttr = {0, 0, 0, 0} 						--属性(智才魅武)
	self.m_tBaseAttr = {0, 0, 0, 0}						--基础属性
	self.m_tPinJiAttr= {0, 0, 0, 0}						--品级属性
	self.m_tUnionAttr = {0, 0, 0, 0}					--联盟加成 
	self.m_tZouZheAttr = {0, 0, 0, 0} 					--奏折加成
	self.m_tTreasureAttr= {0, 0, 0, 0}					--珍宝加成
	self.m_tTalentAttr = {0, 0, 0, 0} 					--天赋加成(不保存)

	self.m_tBreach = {0, 0, 0, 0} 	--成功突破次数
	local nBaseRate = ctMingChenEtcConf[1].nBreachRate  --初始突破成功率
	self.m_tBreachRate = {nBaseRate, nBaseRate, nBaseRate, nBaseRate} --突破成功率

	self.m_tSkLv = table.DeepCopy(tConf.tSkLv[1])		--技能等级
	self.m_tSkQua = {0, 0, 0, 0} 						--技能阶级
	self.m_tSkLvQuaMap = {} 							--技能等级是否已升阶映射
	self.m_nSkPoint = 0

	self.m_nZhanJi = 0 				--战绩
	self.m_tTreasure = {} 			--赠送珍宝

	self.m_nHaoGan = 0 				--好感度(亲密度经验)
	self.m_nQinMi = nQinMi			--亲密度
	self.m_nTalentLv = 1 			--天赋等级
	self.m_nWenHua = 0 				--升级投入文化
	self.m_nChilds = 0

	self.m_nCreateTime = os.time()

	self:Init()
end

function CMCObj:Init()
	local tConf = ctMingChenConf[self.m_nSysID]
	local tTalent = tConf.tTalent
	for k = #tTalent, 1, -1 do
		if self.m_nQinMi >= tTalent[k][1] then
			self.m_nTalentLv = k
			break
		end
	end
end

function CMCObj:LoadData(tData)
	for sKey, xVal in pairs(tData) do
		self[sKey] = xVal
	end
end

function CMCObj:SaveData()
	local tData = {}
	tData.m_nSysID = self.m_nSysID
	tData.m_sName = self.m_sName
	
	tData.m_nTec = self.m_nTec
	tData.m_nLv = self.m_nLv
	tData.m_nJWLv = self.m_nJWLv

	tData.m_nHlLv = self.m_nHlLv
	tData.m_nYinLiang = self.m_nYinLiang
	tData.m_nHistoryLv = self.m_nHistoryLv

	tData.m_nPinJi = self.m_nPinJi
	tData.m_tQua = self.m_tQua
	tData.m_tQuaGrow = self.m_tQuaGrow

	tData.m_tAttr = self.m_tAttr
	tData.m_tBaseAttr = self.m_tBaseAttr
	tData.m_tPinJiAttr = self.m_tPinJiAttr
	tData.m_tUnionAttr = self.m_tUnionAttr
	tData.m_tZouZheAttr = self.m_tZouZheAttr
	tData.m_tTreasureAttr = self.m_tTreasureAttr

	tData.m_tBreach = self.m_tBreach
	tData.m_tBreachRate = self.m_tBreachRate

	tData.m_tSkLv = self.m_tSkLv
	tData.m_tSkQua = self.m_tSkQua
	tData.m_tSkLvQuaMap = self.m_tSkLvQuaMap
	tData.m_nSkPoint = self.m_nSkPoint

	tData.m_nZhanJi = self.m_nZhanJi
	tData.m_tTreasure = self.m_tTreasure

	tData.m_nQinMi = self.m_nQinMi
	tData.m_nHaoGan = self.m_nHaoGan
	tData.m_nTalentLv = self.m_nTalentLv
	tData.m_nWenHua = self.m_nWenHua
	tData.m_nChilds = self.m_nChilds

	tData.m_nCreateTime = self.m_nCreateTime

	return tData
end

function CMCObj:MarkDirty(bDirty) self.m_oModule:MarkDirty(bDirty) end
function CMCObj:GetID() return self.m_nSysID end
function CMCObj:GetName() return self.m_sName end
function CMCObj:GetLevel() return self.m_nLv end
function CMCObj:GetZhanJi() return self.m_nZhanJi end
function CMCObj:GetPinJi() return self.m_nPinJi end
function CMCObj:GetPingJi() return ctMingChenConf[self.m_nSysID].nPingJi end
function CMCObj:GetGrowPoint(nType) return self.m_tQuaGrow[nType] end
function CMCObj:GetSKPoint() return self.m_nSkPoint end
function CMCObj:GetAttr() return self.m_tAttr end
function CMCObj:GetSkillLv() return self.m_tSkLv end
function CMCObj:GetSkillQua() return self.m_tSkQua end
function CMCObj:GetQinMi() return self.m_nQinMi end
function CMCObj:GetHaoGan() return self.m_nHaoGan end

function CMCObj:GetQua(nType)
	if nType then return self.m_tQua[nType] end
	return self.m_tQua
end

--取总资质
function CMCObj:GetTotalQua()
	local nTotal = 0
	for _, v in ipairs(self.m_tQua) do
		nTotal = nTotal + v
	end
	return nTotal
end

--取总属性
function CMCObj:GetTotalAttr()
	local nTotal = 0
	for _, v in ipairs(self.m_tAttr) do
		nTotal = nTotal + v
	end
	return nTotal
end

--取升级需要经验
function CMCObj:UpgradeNeedWH()
	if self.m_nLv >= #ctMingChenLevelConf then
		return nMAX_INTEGER --已达等级上限
	end
	local nNeedWH = ctMingChenLevelConf[self.m_nLv].nNeedWH
	assert(nNeedWH > 0, "升级需要文化不能为0:"..self.m_nLv)
	return nNeedWH
end

--取名臣消息
function CMCObj:GetInfo()
	local tInfo = {}
	tInfo.bGot = true
	tInfo.nID = self.m_nSysID
	tInfo.sName = self.m_sName
	tInfo.nPinJi = self.m_nPinJi
	tInfo.nLv = self.m_nLv
	tInfo.nTec = self.m_nTec
	tInfo.tQua = self.m_tQua
	tInfo.nWH = self.m_nWenHua
	tInfo.nNeedWH = self:UpgradeNeedWH()
	tInfo.tSkLv = self.m_tSkLv
	tInfo.tSkQua = self.m_tSkQua
	tInfo.tQuaGrow = self.m_tQuaGrow
	tInfo.tBreach = self.m_tBreach
	tInfo.tBreachRate = self.m_tBreachRate
	tInfo.tAttr = self.m_tAttr
	tInfo.nZhanJi = self.m_nZhanJi
	tInfo.tTreasure = {}
	for nID, nNum in pairs(self.m_tTreasure) do
		table.insert(tInfo.tTreasure, {nID=nID, nNum=nNum})
	end
	tInfo.nMaxTreasure = self.m_nHistoryLv
	tInfo.nPingJi = self:GetPingJi()
	tInfo.nHaoGan = self.m_nHaoGan
	tInfo.nQinMi = self.m_nQinMi
	tInfo.nJWLv = self.m_nJWLv
	tInfo.nTalentLv = self.m_nTalentLv
	tInfo.nSKPoint = self.m_nSkPoint

	return tInfo
end

--更新属性
function CMCObj:UpdateAttr(bNotUpdateGuoLi)
	-- 	智力 = （基础属性 +品级加成 + 珍宝书籍加成 + 奏折加成）*（1+联盟加成%）
	-- 	基础属性 = int（10 + 智力资质*2 + （1 + 等级）*等级*智力资质/10）
	-- 	珍宝书籍加成 = 赏赐该知己的所有珍宝书籍智力属性总值
	-- 	品级加成：此知己官位提供的智力属性总值
	-- 	奏折加成：批阅奏折时，会遇到知己增加属性的事件
	-- 	联盟加成：联盟奇迹等级提供的百分比加成
	-- 	才力 = （基础属性 +品级加成 + 珍宝书籍加成 + 奏折加成）*（1+联盟加成%）
	-- 	魅力 = （基础属性 +品级加成 + 珍宝书籍加成 + 奏折加成）*（1+联盟加成%）
	-- 	武力 =（基础属性 +品级加成 + 珍宝书籍加成 + 奏折加成）*（1+联盟加成%）

	local tOldAttr = table.DeepCopy(self.m_tAttr, true)
	local tPJConf = ctMingChenPinJiConf[self.m_nPinJi]
	for k = 1, 4 do
		self.m_tAttr[k] = 0
		self.m_tBaseAttr[k] = 0
		self.m_tPinJiAttr[k] = 0
		
		--基础
		self.m_tBaseAttr[k]	= math.floor(10+self.m_tQua[k]*2+(1+self.m_nLv)*self.m_nLv*self.m_tQua[k]/10)
		--官品
		self.m_tPinJiAttr[k] = tPJConf.nAttr
	end

	--珍宝
	self.m_tTreasureAttr = {0, 0, 0, 0}
	for nPropID, nNum in pairs(self.m_tTreasure) do
		local tConf = ctPropConf[nPropID]
		self.m_tTreasureAttr[self.m_nTec] = self.m_tTreasureAttr[self.m_nTec] + tConf.nVal*nNum
	end

	--计算总属性
	for k = 1, 4 do
		self.m_tAttr[k] = self.m_tAttr[k]
			+ self.m_tBaseAttr[k]
			+ self.m_tPinJiAttr[k]
			+ self.m_tZouZheAttr[k]
			+ self.m_tTreasureAttr[k]
	end

	--联盟
	self.m_tUnionAttr = {0, 0, 0, 0}
	local oUnion = goUnionMgr:GetUnionByCharID(self.m_oPlayer:GetCharID())
	if oUnion then
		local tAddPercent = oUnion.m_oUnionMiracle:GetAddPercent()
		for k = 1, 4 do
			self.m_tUnionAttr[k] = math.floor(self.m_tAttr[k]*tAddPercent[k])
			self.m_tAttr[k] = self.m_tAttr[k] + self.m_tUnionAttr[k]
		end
	end

	--天赋加成
	local tAttrMap = self:AttrPerAdd()
	for k = 1, 4 do
		self.m_tTalentAttr[k] = math.floor(self.m_tAttr[k] * (tAttrMap[k] or 0))
		self.m_tAttr[k] = self.m_tAttr[k] + self.m_tTalentAttr[k]
	end
	self:MarkDirty(true)

	--更新国力
	for k = 1, 4 do
		if self.m_tAttr[k] ~= tOldAttr[k] then
			self.m_oModule:OnAttrChange()
			self.m_oModule:SyncMingChen(self.m_nSysID)
			if not bNotUpdateGuoLi then
				self.m_oPlayer:UpdateGuoLi("名臣属性变化")
			end
			return true
		end
	end
end

--当前最高等级
function CMCObj:MaxLevel()
	local tJWConf = assert(ctMingChenJueWeiConf[self.m_nJWLv])
	return tJWConf.nMaxLv
end

--是否可升级
function CMCObj:CanUpgrade(bTips)
	if self.m_nLv >= #ctMingChenLevelConf then
		if bTips then self.m_oPlayer:Tips("已达等级上限") end
		return 
	end
	if self.m_nLv >= self:MaxLevel() then
		if bTips then self.m_oPlayer:Tips("请先封爵") end
		return
	end
	return true
end

--名臣属性日志
function CMCObj:_AttrLog()
	goLogger:EventLog(gtEvent.eMCAttr, self.m_oPlayer, self.m_nSysID, self.m_nLv, self.m_tAttr, self.m_tQua, self.m_tSkLv)
end

--升级
function CMCObj:UpgradeReq(bOneKey)
	if not self:CanUpgrade(not bOneKey) then
		return
	end

	local bSuccess = false
	local nCurrWH = self.m_oPlayer:GetWenHua()
	local nFullNeedWH = self:UpgradeNeedWH()
	local nRealNeedWH = math.max(0, nFullNeedWH-self.m_nWenHua)
	if nCurrWH <= 0 then
		if not bOneKey then
			self.m_oPlayer:Tips("没有文化值")
		end
		return 

	elseif nCurrWH < nRealNeedWH then
		self.m_nWenHua = self.m_nWenHua + nCurrWH
		self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eWenHua, nCurrWH, "知己升级投入")
		
	else
		if not bOneKey then --1键升级不触发神迹
			local nZhuFu = 0
			if self.m_oPlayer.m_oShenJiZhuFu:ShenJiZhuFu(gtSJZFDef.eCYLD) > 0 then
				nZhuFu = nFullNeedWH
			end
			nRealNeedWH = nRealNeedWH - nZhuFu
		end
		self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eWenHua, nRealNeedWH, "知己升级")
		self.m_nWenHua = 0
		self.m_nLv = self.m_nLv + 1
		self.m_nHistoryLv = math.max(self.m_nHistoryLv, self.m_nLv)
		if not bOneKey then
			self:UpdateAttr()
			--任务
			self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond6, self.m_nSysID, self.m_nLv, true)
		end
		bSuccess = true
	end
	self:MarkDirty(true)
	if not bOneKey then
		self.m_oModule:SyncMingChen(self.m_nSysID)
	end
	--日常任务
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond3, 1)
	return bSuccess
end

--升10级
function CMCObj:OneKeyUpgradeReq()
	if not self:CanUpgrade(true) then
		return
	end
	local nCurrWH = self.m_oPlayer:GetWenHua()
	if nCurrWH <= 0 then
		return self.m_oPlayer:Tips("没有文化值")
	end

	local bSuccess = false
	for k = 1, 10 do
		if self:UpgradeReq(true) then
			bSuccess = true
		end
	end
	if bSuccess then
		if not self:UpdateAttr() then
			self.m_oModule:SyncMingChen(self.m_nSysID)
		end
		--任务
		self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond6, self.m_nSysID, self.m_nLv, true)
	else
		self.m_oModule:SyncMingChen(self.m_nSysID)
	end
end

--技能升级
function CMCObj:SkillUpgradeReq(nSkID, bOneKey)
	local nCurrLv = assert(self.m_tSkLv[nSkID])
	local tLvConf = _MingChenSkillConf[nSkID]
	if nCurrLv >= #tLvConf then
		return self.m_oPlayer:Tips("已达等级上限")
	end

	local tLvAdvConf  = _MingChenSkillAdvanceConf[nSkID]
	local tAdvConf = tLvAdvConf[nCurrLv]
	if tAdvConf and not self.m_tSkLvQuaMap[nSkID..nCurrLv] then
		return self.m_oPlayer:Tips("技能需要先进阶")
	end

	local tSkConf = assert(tLvConf[nCurrLv])
	local nSKPoint = self:GetSKPoint()
	if nSKPoint < tSkConf.nCost then
		return self.m_oPlayer:Tips("技能点不足")
	end
	self:AddSKPoint(-tSkConf.nCost, "知己技能升级")
	self.m_tSkLv[nSkID] = self.m_tSkLv[nSkID] + 1
	self:MarkDirty(true)
	if not bOneKey then
		self.m_oModule:SyncMingChen(self.m_nSysID)
		self.m_oPlayer:Tips(string.format("技能成功升到%d级", self.m_tSkLv[nSkID]))
	end
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond40, 1)
	return true
end

--技能1建升级(升10级)
function CMCObj:SkillOneKeyUpgradeReq(nSkID)
	local nCount = 0
	for k = 1, 10 do
		if not self:SkillUpgradeReq(nSkID, true) then
			break
		end
		nCount = nCount + 1
	end
	if nCount > 0 then
		self.m_oModule:SyncMingChen(self.m_nSysID)
		self.m_oPlayer:Tips(string.format("技能成功升到%d级", self.m_tSkLv[nSkID]))
	end
end

--技能升阶
function CMCObj:SkillAdvanceReq(nSkID)
	local nCurrLv = assert(self.m_tSkLv[nSkID])

	local tLvAdvConf  = _MingChenSkillAdvanceConf[nSkID]
	local tAdvConf = tLvAdvConf[nCurrLv]
	if not tAdvConf then
		return self.m_oPlayer:Tips("未满足进阶条件")
	end
	local tPropCost = tAdvConf.tPropCost[1]
	if tPropCost[1] <= 0 then
		return self.m_oPlayer:Tips("未满足进阶条件")
	end

	local nPropCount = self.m_oPlayer:GetItemCount(tPropCost[1], tPropCost[2])
	if nPropCount < tPropCost[3] then
		return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tPropCost[2])))
	end

	self.m_oPlayer:SubItem(tPropCost[1], tPropCost[2], tPropCost[3], "知己技能进阶")
	self.m_tSkQua[nSkID] = self.m_tSkQua[nSkID] + 1
	self.m_tSkLvQuaMap[nSkID..nCurrLv] = 1
	self:MarkDirty(true)
	self.m_oModule:SyncMingChen(self.m_nSysID)
end

--赏赐珍宝
function CMCObj:GiveTreasureReq(nPropID, nPropNum, bOneKey)
	assert(nPropID > 0 and nPropNum > 0)
	local nCurNum = self.m_tTreasure[nPropID] or 0
	local nMaxNum = self.m_nHistoryLv
	if nCurNum >= nMaxNum then
		return self.m_oPlayer:Tips("该珍宝已达到赏赐上限")
	end
	local tConf = assert(ctPropConf[nPropID], "道具不存在")
	if tConf.nDetType ~= gtDetType.eMCZhenBao then
		return self.m_oPlayer:Tips("非知己珍宝道具")
	end
	if tConf.nSubType ~= self.m_nTec then
		return self.m_oPlayer:Tips("珍宝特长和知己不匹配")
	end
	local nGiveNum = math.min(nMaxNum-nCurNum, nPropNum)
	local nPackNum = self.m_oPlayer:GetItemCount(gtItemType.eProp, nPropID)
	if nGiveNum > nPackNum then
		return self.m_oPlayer:Tips("珍宝道具不足")
	end
	self.m_oPlayer:SubItem(gtItemType.eProp, nPropID, nGiveNum, "名臣赏赐")
	self.m_tTreasure[nPropID] = (self.m_tTreasure[nPropID] or 0) + nGiveNum
	self:MarkDirty(true)
	if not bOneKey then
		if not self:UpdateAttr() then
			self.m_oModule:SyncMingChen(self.m_nSysID)
		end
	end
	self.m_oPlayer:Tips(string.format("使用%s，%s %s+%d", tConf.sName, self.m_sName, gtQuaNameMap[self.m_nTec], tConf.nVal*nGiveNum))
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond35, 1)
	return true
end

--一键赏赐
function CMCObj:OneKeyGiveTreasureReq()
	local tPropMap = self.m_oPlayer.m_oGuoKu:GetMCPropMap(self.m_nTec)
	if not tPropMap then
		return self.m_oPlayer:Tips("没有可赏赐的珍宝")
	end
	local bSuccess = false
	for nID, nNum in pairs(tPropMap) do
		if self:GiveTreasureReq(nID, nNum, true) then
			bSuccess = true
		end
	end
	if bSuccess then
		if not self:UpdateAttr() then
			self.m_oModule:SyncMingChen(self.m_nSysID)
		end
	end
end

--培养
function CMCObj:TrainReq()
	local tEtcConf = ctMingChenEtcConf[1]
	local nTrainProp = tEtcConf.nTrainProp
	if nTrainProp > 0 then
		local nPackNum = self.m_oPlayer:GetItemCount(gtItemType.eProp, nTrainProp)
		if nPackNum <= 0 then
			return self.m_oPlayer:Tips("资质果不足")
		end
		self.m_oPlayer:SubItem(gtItemType.eProp, nTrainProp, 1, "名臣培养")
		--活动
	    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eZZG, 1)
	    --任务
		self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond11, 1)
	end
	local nIndex = math.random(1, #self.m_tQua)
	self.m_tQua[nIndex] = self.m_tQua[nIndex] + 1
	self:MarkDirty(true)

	if not self:UpdateAttr() then
		self.m_oModule:SyncMingChen(self.m_nSysID)
	end

	self.m_oPlayer:Tips(string.format("%s %s +1", self.m_sName, gtQuaNameMap[nIndex]))
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond28, 1)
end

--突破
function CMCObj:BreachReq(nQuaID)
	local nBreachPoint = 80 * (self.m_tBreach[nQuaID] + 1)
	local nGrowPoint = self.m_tQuaGrow[nQuaID]
	if nGrowPoint < nBreachPoint then
		return self.m_oPlayer:Tips(string.format("%s成长点不足", gtQuaNameMap[nQuaID]))
	end

	--首次突破必成功
	local nRnd = math.random(1, 100)
	local bFirstBreach = self.m_oModule:GetFirstBreach()
	if bFirstBreach then
		nRnd = self.m_tBreachRate[nQuaID]
		self.m_oModule:SetFirstBreach()
	end
	self.m_tQuaGrow[nQuaID] = math.max(0, self.m_tQuaGrow[nQuaID]-nBreachPoint)
	self:MarkDirty(true)

	if nRnd <= self.m_tBreachRate[nQuaID] then --成功
		self.m_tBreachRate[nQuaID] = ctMingChenEtcConf[1].nBreachRate
		self.m_tBreach[nQuaID] = self.m_tBreach[nQuaID] + 1
		self.m_tQua[nQuaID] = self.m_tQua[nQuaID] + 1
		if not self:UpdateAttr() then
			self.m_oModule:SyncMingChen(self.m_nSysID)
		end
		self.m_oPlayer:Tips("突破成功")
		--任务
		self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond42, 1)
	else --失败
		self.m_tBreachRate[nQuaID] = self.m_tBreachRate[nQuaID] + 20
		self.m_oModule:SyncMingChen(self.m_nSysID)
		self.m_oPlayer:Tips("突破失败")
	end
	goLogger:EventLog(gtEvent.eMingChenBreach, self.m_oPlayer, nQuaID, self.m_tQua[nQuaID], self.m_nSysID)
end

--增加成长点
function CMCObj:AddGrowPoint(nType, nVal, sReason)
	self.m_tQuaGrow[nType] = math.min(nMAX_INTEGER, math.max(0, self.m_tQuaGrow[nType]+nVal))
	self:MarkDirty(true)
	self.m_oModule:SyncMingChen(self.m_nSysID)
	local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
	goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eRandGrow, nVal, self.m_tQuaGrow[nType], nType, self.m_nSysID)
end

--增加技能点
function CMCObj:AddSKPoint(nVal, sReason)
	self.m_nSkPoint = math.min(nMAX_INTEGER, math.max(0, self.m_nSkPoint+nVal))
	self:MarkDirty(true)
	self.m_oModule:SyncMingChen(self.m_nSysID)
	local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
	goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eSKPoint, nVal, self.m_nSkPoint, self.m_nSysID)
end


--增加战绩
function CMCObj:AddZhanJi(nVal, sReason)
	self.m_nZhanJi = math.min(nMAX_INTEGER, math.max(0, self.m_nZhanJi+nVal))
	self:MarkDirty(true)
	self.m_oModule:SyncMingChen(self.m_nSysID)
	local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
	goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eZhanJi, nVal, self.m_nZhanJi, self.m_nSysID)
	self.m_oModule:OnZhanJiChange()
end

--奏章添加属性
function CMCObj:AddZouZheAttr(nAttrID, nAttrVal)
	self.m_tZouZheAttr[nAttrID] = self.m_tZouZheAttr[nAttrID] + nAttrVal
	if not self:UpdateAttr() then
		self.m_oModule:SyncMingChen(self.m_nSysID)
	end
	self:MarkDirty(true)
end

--奏章添加资质
function CMCObj:AddZouZheQua(nType, nQua)
	assert(nType >= 1 and nType <= 4, "资质类型错误")
	self.m_tQua[nType] = self.m_tQua[nType] + nQua
	if not self:UpdateAttr() then
		self.m_oModule:SyncMingChen(self.m_nSysID)
	end
	self:MarkDirty(true)
end

--是否可以封官
function CMCObj:CanFengGuan()
	for k = self.m_nPinJi+1, #ctMingChenPinJiConf do
		local tConf = ctMingChenPinJiConf[k]
		if self.m_nZhanJi >= tConf.nZhanJi then
			return k
		end
	end
end

--封官品
function CMCObj:FengGuanReq()
	local nTarPinJi = self:CanFengGuan()
	if nTarPinJi then
		local nOrgPinJi = self.m_nPinJi
		self.m_nPinJi = nTarPinJi
		self:MarkDirty(true)
		if not self:UpdateAttr() then
			self.m_oModule:SyncMingChen(self.m_nSysID)
		end
		Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "MCFengGuanRet", {nMCID=self.m_nSysID, nPinJi=self.m_nPinJi})
		self.m_oModule:CheckRedPoint()
	else
		self.m_oPlayer:Tips("战绩不足")	
	end
end

--GM设置最大等级
function CMCObj:GMSetLv(nLv)
	local tJWConf = assert(ctMingChenJueWeiConf[self.m_nJWLv])
	nLv = math.max(1, math.min(nLv, tJWConf.nMaxLv))
	self.m_nLv = nLv
	self.m_nHistoryLv = math.max(self.m_nHistoryLv, self.m_nLv)
	if not self:UpdateAttr() then
		self.m_oModule:SyncMingChen(self.m_nSysID)
	end
	self:MarkDirty(true)
end

--名臣封号
function CMCObj:ModNameReq(sName, nType)
	assert(nType==1 or nType==2, "参数有误")
	if nType == 1 then --改名
	    local nCostYB = 5
		if self.m_oPlayer:GetYuanBao() < nCostYB then
			return self.m_oPlayer:YBDlg()
		end

		--名字长度检测
		local nNameLen = string.len(sName)
		if nNameLen <= 0 and nNameLen > 12 then 
			return self.m_oPlayer:Tips("名字长度非法:"..sName)
		end
		
		--非法字检测
	    if CUtil:HasBadWord(sName) then
	        return self.m_oPlayer:Tips("名字含有非法字，操作失败")
	    end
	    
	    if sName == self.m_sName then 
	    	return self.m_oPlayer:Tips("名臣封号未作出改变")
	    end

	    self.m_sName = sName
		self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nCostYB, "知己名修改")
		self.m_oPlayer:Tips("成功更改封号")

    elseif nType == 2 then --恢复
    	self.m_sName = ctMingChenConf[self.m_nSysID].sName
		self.m_oPlayer:Tips("已恢复为默认封号")

    end
	self:MarkDirty(true)
	self.m_oModule:SyncMingChen(self.m_nSysID)
end

--知己战力
function CMCObj:GetPower()
	--战斗力=1250*等级*总资质+军事值
	local nTotalQua = self:GetTotalQua()
	local nTotalAttr = self:GetTotalAttr()
	local nPower = 1250*self.m_nLv*nTotalQua+nTotalAttr
	return nPower
end

--属性详情请求
function CMCObj:AttrDetailReq()
	local tMsg = {
		tAttr = self.m_tAttr,
		tBaseAttr = self.m_tBaseAttr,
		tPinJiAttr = self.m_tPinJiAttr,
		tUnionAttr = self.m_tUnionAttr,
		tZouZheAttr = self.m_tZouZheAttr,
		tTreasureAttr = self.m_tTreasureAttr,
		tTalentAttr = self.m_tTalentAttr,
	}
	Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "MCAttrDetailRet", tMsg)
end

--封爵请求
function CMCObj:FengJueReq()
	if self.m_nJWLv>= #ctMingChenJueWeiConf then
		return self.m_oPlayer:Tips("已达爵位上限")
	end
	if self.m_nLv < self:MaxLevel() then
		return self.m_oPlayer:Tips("未达到封爵条件")
	end
	local tCost = ctMingChenJueWeiConf[self.m_nJWLv].tCost
	for _, tItem in ipairs(tCost) do
		if self.m_oPlayer:GetItemCount(tItem[1], tItem[2]) < tItem[3] then
			return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tItem[2])))
		end
	end
	for _, tItem in ipairs(tCost) do
		self.m_oPlayer:SubItem(tItem[1], tItem[2], tItem[3], "封爵消耗")
	end
	self.m_nJWLv = self.m_nJWLv + 1
	self:MarkDirty(true)
	self.m_oModule:SyncMingChen(self.m_nSysID)

	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond26, 1)
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond31, self.m_nSysID, self.m_nJWLv, true)
	--电视
	local tConf = ctMingChenJueWeiConf[self.m_nJWLv]
	local sNotice = string.format(ctLang[14], self.m_oPlayer:GetName(), self.m_sName, tConf.sName)
	goTV:_TVSend(sNotice)	
	--小红点
	self.m_oModule:CheckRedPoint()
end

--晋升
function CMCObj:UpgradeTalentReq()
	local tConf = ctMingChenConf[self.m_nSysID]
	local tTalent = tConf.tTalent
	if self.m_nTalentLv >= #tTalent then
		return self.m_oPlayer:Tips("已达天赋等级上限")
	end

	local nMaxTLV = 1
	for k = #tTalent, 1, -1 do
		if self.m_nQinMi >= tTalent[k][1] then
			nMaxTLV = k
			break
		end
	end

	if self.m_nTalentLv >= nMaxTLV then
		return self.m_oPlayer:Tips("亲密度不足")
	end

	self.m_nTalentLv = self.m_nTalentLv + 1
	self:MarkDirty(true)
	if not self:UpdateAttr() then
		self.m_oModule:SyncMingChen(self.m_nSysID)
	end

	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond39, self.m_nSysID, 1)
	--电视
	local sNotice = string.format(ctLang[5], self.m_oPlayer:GetName(), self.m_sName)
	goTV:_TVSend(sNotice)	
end

--增加好感度
function CMCObj:AddHaoGan(nVal, sReason)
	self.m_nHaoGan = math.max(0, math.min(nMAX_INTEGER, self.m_nHaoGan+nVal))
	self:MarkDirty(true)

	if sReason then
		local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
		goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eHaoGan, nVal, self.m_nHaoGan, self.m_nSysID)
	end

	if not self:CheckQMUpgrade() then
		self.m_oModule:SyncMingChen(self.m_nSysID)
	end
end

--检测亲密度提升
function CMCObj:CheckQMUpgrade()
	local bAddQinMi = false
	local i = 1024
	while i > 0 do
		i = i - 1
		local nQM = math.min(#ctMingChenQinMiConf, self.m_nQinMi)
		local nNeedHG = ctMingChenQinMiConf[nQM].nHaoGan
		if self.m_nHaoGan < nNeedHG then
			break
		end
		self.m_nHaoGan = self.m_nHaoGan - nNeedHG
		self:AddQinMi(1, "亲密度升级")
		bAddQinMi = true
	end
	self:MarkDirty(true)
	return bAddQinMi
end

--知己送礼请求
function CMCObj:SendGiftReq(nPropID, nPropNum, bOneKey)
	assert(nPropNum > 0)
	local tConf = assert(ctPropConf[nPropID], "道具不存在")
	assert(tConf.nDetType == gtDetType.eFZZhenBao, "非送礼道具")

	if self.m_nQinMi >= nMAX_INTEGER then
		return self.m_oPlayer:Tips("亲密度已达上限")
	end

	local nPackNum = self.m_oPlayer:GetItemCount(gtItemType.eProp, nPropID)
	if nPropNum > nPackNum then
		return self.m_oPlayer:Tips("道具不足，无法送礼")
	end
	self.m_oPlayer:SubItem(gtItemType.eProp, nPropID, nPropNum, "知己送礼")

	self:AddHaoGan(tConf.nVal*nPropNum, "知己送礼")
	if not bOneKey then
		self.m_oModule:SyncMingChen(self.m_nSysID)
	end
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond30, 1)
	return true
end

--一键送礼请求
function CMCObj:OneKeySendGiftReq()
	local nRes = 0
	local tPropList = self.m_oPlayer.m_oGuoKu:GetFZPropMap()
	for nID, nNum in pairs(tPropList) do
		if self:SendGiftReq(nID, nNum, true) then
			nRes = nRes + 1
		end
	end
	if nRes > 0 then
		self.m_oModule:SyncMingChen(self.m_nSysID)
	else
		self.m_oPlayer:Tips("没有可送礼的物品")
	end
end

--增加亲密度
function CMCObj:AddQinMi(nVal, sReason)
	self.m_nQinMi = math.max(1, math.min(nMAX_INTEGER, self.m_nQinMi+nVal))
	self:MarkDirty(true)
	self.m_oModule:SyncMingChen(self.m_nSysID)

	--通过CPlayer:AddItem不需要在这里写LOG
	if sReason then
		local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
		goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eQinMi, nVal, self.m_nQinMi, self.m_nSysID)
	end

	self.m_oModule:OnQinMiChange()
	return self.m_nQinMi
end

--邀约
function CMCObj:YaoYueReq(nTimes, bUseProp)
	assert(nTimes == 1 or nTimes == 10, "次数错误")
	local tMCConf = ctMingChenConf[self.m_nSysID]
	local tMCEtc = ctMingChenEtcConf[1]
	--元宝检测
	local nYYYuanBao = math.min(self.m_nQinMi*10, 800)
	if self.m_oPlayer:GetYuanBao() < nYYYuanBao then
		return self.m_oPlayer:YBDlg()
	end
	--扣除元宝
	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nYYYuanBao, "知己邀约")

	local tAward = tMCEtc.tYYAward[1]
	--好感/亲密度经验
	self:AddHaoGan(tAward[1], "知己邀约")
	--技能点
	self:AddSKPoint(tAward[2], "知己邀约")
	--给前端飘字
	self.m_oPlayer:Tips(string.format("亲密经验+%d", tAward[1]))
	self.m_oPlayer:Tips(string.format("技能点+%d", tAward[2]))

	--检测生孩子
	local nProp = tMCEtc.nSZDProp
	for k = 1, nTimes do
		--使用双丹
		if bUseProp then
			if self.m_oPlayer:GetItemCount(gtItemType.eProp, nProp) <= 0 then
				bUseProp = false
			end
		end
		local nChildRes = self:ChildCheck(bUseProp)
		if nChildRes == 0 then
			if bUseProp then
				--扣除物品
				self.m_oPlayer:SubItem(gtItemType.eProp, nProp, 1, "知己邀约")
				--活动(消耗双子丹数)
			    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eSZD, 1)
			end
		elseif nChildRes == -2 then --满员
			break
		end
	end

	--同步信息
	self.m_oModule:SyncMingChen(self.m_nSysID)
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond13, nTimes)
end

--检测活动宠物
function CMCObj:ChildCheck(bUseProp)
	--宗人府检测
	local nVIP = self.m_oPlayer:GetVIP()
	local nVIPRate = ctVIPConf[nVIP].nHZRate
	local nRate = (0.5 + nVIPRate) * 100
	local nRnd = math.random(1, 100) 

	--第1次一定生孩子(新手引导)
	if self.m_oPlayer.m_oZongRenFu:GetChildNum() == 0 then
		nRate = 100
	end

	if nRnd <= nRate then
		local nFreeGrid = self.m_oPlayer.m_oZongRenFu:GetFreeGrid()
		if nFreeGrid <= 0 then
			self.m_oPlayer:Tips("萌宠席位已满，无法获得更多萌宠")
			return -2
		end
		local nChildNum = bUseProp and 2 or 1
		local nChildSex1 = math.random(1, 2)
		if nChildNum == 1 then
			self.m_oPlayer.m_oZongRenFu:Create(self.m_nSysID, nChildSex1)	

		elseif nChildNum == 2 then
			local nChildSex2 = math.random(1, 2)
			self.m_oPlayer.m_oZongRenFu:CreateDouble(self.m_nSysID, nChildSex1, nChildSex2)	
			
		end
		self.m_nChilds = self.m_nChilds + nChildNum
		self:MarkDirty(true)
		return 0
	end
	return -1
end

--取属性加成(百分比)
function CMCObj:AttrPerAdd()
	local tConf = ctMingChenConf[self.m_nSysID]
	local tAttrMap = {}

	local tTalent = tConf.tTalent
	for k = 1, self.m_nTalentLv do
		local tItem = tTalent[k]
		local nAttrID = tItem[2]
		local nAttrVal = tItem[3]
		tAttrMap[nAttrID] = (tAttrMap[nAttrID] or 0) + nAttrVal
	end
	return tAttrMap
end

