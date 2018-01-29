local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--知己系统
function CMingChen:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_bFirstBreach = true --是否第一次突破
	self.m_tMingChenMap = {}
	self.m_tOutMCMap = {} --未入宫知己映射{[sysid]=qinmi,...}
	self.m_nCount = 0 --知己数量(不保存)
end

function CMingChen:GetType()
	return gtModuleDef.tMingChen.nID, gtModuleDef.tMingChen.sName
end

function CMingChen:LoadData(tData)
	if not tData then
		return
	end

	for nSysID, tMCData in pairs(tData) do
		if ctMingChenConf[nSysID] then
			local oMC = CMCObj:new(self, self.m_oPlayer, nSysID, 0)
			oMC:LoadData(tMCData)
			self.m_tMingChenMap[nSysID] = oMC
			self.m_nCount = self.m_nCount + 1
		end
	end
	self.m_bFirstBreach = tData.m_bFirstBreach or self.m_bFirstBreach
	self.m_tOutMCMap = tData.m_tOutMCMap
end

function CMingChen:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	for nSysID, _ in pairs(self.m_tMingChenMap) do
		local oMC = self.m_tMingChenMap[nSysID]
		tData[nSysID] = oMC:SaveData()
	end
	tData.m_bFirstBreach = self.m_bFirstBreach
	tData.m_tOutMCMap = self.m_tOutMCMap
	return tData
end

--上线
function CMingChen:Online()
	for nSysID, tConf in pairs(ctMingChenConf) do
		local oMC = self.m_tMingChenMap[nSysID]
		if oMC then
			oMC:UpdateAttr(true) --重新计算属性，因为离线期间联盟加成可能会变更
		elseif tConf.bInitGet then
			self:Create(nSysID, true)
		elseif not self.m_tOutMCMap[nSysID] then
			self.m_tOutMCMap[nSysID] = 0
			self:MarkDirty(true)
		end
	end
	self:SyncMingChen()
	--小红点	
	self:CheckRedPoint()
end

function CMingChen:SetFirstBreach()
	self.m_bFirstBreach = false
	self:MarkDirty(true)
end

--取数量
function CMingChen:GetCount() return self.m_nCount end
--获取
function CMingChen:GetObj(nSysID) return self.m_tMingChenMap[nSysID] end
--取映射表
function CMingChen:GetMCMap() return self.m_tMingChenMap end
--首次突破
function CMingChen:GetFirstBreach() return self.m_bFirstBreach end

--直接添加知己
function CMingChen:Create(nSysID, bOnline)
	local tConf = assert(ctMingChenConf[nSysID], "知己配置不存在:"..nSysID)
	--如果已经有知己,转成亲密度
	if not self.m_tMingChenMap[nSysID] then
		self.m_tOutMCMap[nSysID] = (self.m_tOutMCMap[nSysID] or 0) + tConf.nQinMi
		self:RuGongReq(nSysID, bOnline)
	else
		self.m_tMingChenMap[nSysID]:AddQinMi(tConf.nQinMiExchange, "知己兑换成亲密度")
	end
	return self:GetCount()
end

--知己入宫(玩家点击)
function CMingChen:RuGongReq(nSysID, bOnline)
	if self.m_tMingChenMap[nSysID] then
		return self.m_oPlayer:Tips("知己已在宫中:"..nSysID)
	end
	local nQinMi = assert(self.m_tOutMCMap[nSysID])
	local nQinMiNeed= ctMingChenConf[nSysID].nQinMi
	if nQinMi < nQinMiNeed then
		return self.m_oPlayer:Tips("亲密度不足:"..nSysID)
	end
	
	local oMC = CMCObj:new(self, self.m_oPlayer, nSysID, nQinMi)
	self.m_tMingChenMap[nSysID] = oMC
	self.m_tOutMCMap[nSysID] = nil
	self.m_nCount = self.m_nCount + 1
	self:MarkDirty(true)
	oMC:UpdateAttr()

	--不是上线的时候创建的名臣才同步信息
	if not bOnline then
		self:SyncMingChen(nSysID)
	end
	--LOG
	goLogger:EventLog(gtEvent.eCreateMingChen, self.m_oPlayer, nSysID)
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond33, nSysID, 1)
	--成就
    self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond4, self.m_nCount, true)
	-- 更新榜单
	self:OnQinMiChange()
	-- self:OnNengLiChange()
end

--取未入宫知己信息
function CMingChen:GetOutMCInfo(nSysID)
	local nQinMi = assert(self.m_tOutMCMap[nSysID])
	local tConf = assert(ctMingChenConf[nSysID])
	local tInfo = {}
	tInfo.nID = nSysID
	tInfo.sName = tConf.sName
	tInfo.nQinMi = nQinMi
	tInfo.bGot = false
	return tInfo
end

--知己信息同步
function CMingChen:SyncMingChen(nSysID)
	local tList = {}
	if not nSysID then
		for _, oMC in pairs(self.m_tMingChenMap) do
			local tInfo = oMC:GetInfo()
			table.insert(tList, tInfo)
		end
		
		for nSysID, nQinMi in pairs(self.m_tOutMCMap) do
			table.insert(tList, self:GetOutMCInfo(nSysID))
		end
	else
		if self.m_tMingChenMap[nSysID] then
			table.insert(tList, self.m_tMingChenMap[nSysID]:GetInfo())

		elseif self.m_tOutMCMap[nSysID] then
			table.insert(tList, self:GetOutMCInfo(nSysID))
		end
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "MCListRet", {tList=tList})
	-- print("CMingChen:SyncMingChen***", tList)
end

--知己总属性
function CMingChen:GetTotalAttr()
	local nTotalAttr = 0
	local tAttr = {0, 0, 0, 0}
	for nID, oMC in pairs(self.m_tMingChenMap) do
		for k = 1, 4 do
			tAttr[k] = tAttr[k] + oMC.m_tAttr[k]
			nTotalAttr = nTotalAttr + oMC.m_tAttr[k]
		end
	end
	return tAttr, nTotalAttr
end

--取所有知己公会属性加成
function CMingChen:GetTotalUnionAttrAdd()
	local tAttr = {0, 0, 0, 0}
	for nID, oMC in pairs(self.m_tMingChenMap) do
		for k = 1, 4 do
			tAttr[k] = tAttr[k] + oMC.m_tUnionAttr[k]
		end
	end
	return tAttr
end

--随机已招募知己
function CMingChen:RandObj(nNum)
	local tMCList = {}
	local tTarMCList = {}
	for nID, oMC in pairs(self.m_tMingChenMap) do
		table.insert(tMCList, oMC)
	end
	if #tMCList <= 0 then
		return tTarMCList
	end
	for k = 1, nNum do
		local nRnd = math.random(1, #tMCList)
		table.insert(tTarMCList, tMCList[nRnd])
		table.remove(tMCList, nRnd)
		if #tMCList <= 0 then break end
	end
	return tTarMCList
end

--战绩变更
function CMingChen:OnZhanJiChange()
	local nTotalZJ = 0
	for nID, oMC in pairs(self.m_tMingChenMap) do
		nTotalZJ = nTotalZJ + oMC:GetZhanJi()
	end
	goRankingMgr.m_oZJRanking:Update(self.m_oPlayer, nTotalZJ)
	--小红点	
	self:CheckRedPoint()
end

--小红点检测
function CMingChen:CheckRedPoint()
	--军机处未开放
	if not self.m_oPlayer.m_oJunJiChu:IsOpen() then
		return
	end
	for nID, oMC in pairs(self.m_tMingChenMap) do
		if oMC:CanFengGuan() then
			return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eFengGuan, 1) 
		end
	end
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eFengGuan, 0) 
end

--联盟变更(在线的话会直接调用，离线的话在上线时处理)
function CMingChen:OnUnionChange()
	for nID, oMC in pairs(self.m_tMingChenMap) do
		oMC:UpdateAttr(true)
	end
	self.m_oPlayer:UpdateGuoLi("退出/加入联盟")
end

--属性变化事件(更新排行榜)
function CMingChen:OnAttrChange()
	local _, nTotalAttr = self:GetTotalAttr()
	goRankingMgr.m_oMCRanking:Update(self.m_oPlayer, nTotalAttr)
end

--增加知己亲密度
function CMingChen:AddQinMi(nSysID, nQinMi, sReason)
	local oMC = self.m_tMingChenMap[nSysID]
	if oMC then
		oMC:AddQinMi(nQinMi, sReason)
		return oMC:GetQinMi()
	end
	
	if self.m_tOutMCMap[nSysID] then
		self.m_tOutMCMap[nSysID] = math.max(1, math.min(nMAX_INTEGER, self.m_tOutMCMap[nSysID]+nQinMi))
		self:SyncMingChen(nSysID)
		self:MarkDirty(true)

		if sReason then --通过CPlayer:AddItem不需要在这里写LOG
			local nEventID = nQinMi > 0 and gtEvent.eAddItem or gtEvent.eSubItem
			goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eQinMi, nQinMi, self.m_tOutMCMap[nSysID], nSysID)
		end
		return self.m_tOutMCMap[nSysID]
		
	end
end

--亲密度变化
function CMingChen:OnQinMiChange()
	local nTotalQinMi = self:GetTotalQinMi()
	goRankingMgr.m_oQMRanking:Update(self.m_oPlayer, nTotalQinMi)
end


--所有知己亲密度
function CMingChen:GetTotalQinMi()
	local nTotalQinMi = 0
	for nID, oMC in pairs(self.m_tMingChenMap) do
		nTotalQinMi = nTotalQinMi + oMC:GetQinMi()		
	end
	return nTotalQinMi
end

--取某等级知己数
function CMingChen:GetLevelMCCount(nLevel)
	local nCount = 0
	for nID, oMC in pairs(self.m_tMingChenMap) do
		if oMC:GetLevel() >= nLevel then
			nCount = nCount + 1
		end
	end
	return nCount
end
