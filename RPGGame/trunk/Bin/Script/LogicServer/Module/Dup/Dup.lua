--征服世界
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--章节关卡配置预处理
local _tChapterDupConf = {}
local function PreProcessChapter()
	for _, tConf in pairs(ctCheckPointConf) do
		_tChapterDupConf[tConf.nChapter] = _tChapterDupConf[tConf.nChapter] or {}
		table.insert(_tChapterDupConf[tConf.nChapter], tConf)
	end
	for _, tDupList in pairs(_tChapterDupConf) do
		table.sort(tDupList, function(t1, t2) return t1.nID<t2.nID end)
	end
end
PreProcessChapter()

--副本类型
CDup.tType = {
	eNormal = 1,	--普通
	eBoss = 2, 		--BOSS
	eFashion = 3, 	--时装
}

--外交点恢复时间
local nWJRecoverTime = ctDupEtcConf[1].nWJRecoverTime
function CDup:Ctor(oPlayer)
	self.m_oPlayer = oPlayer

	local tConf = _tChapterDupConf[1][1]
	self.m_nDupID = tConf.nID 	--下个要打的关卡ID
	self.m_nStrongHold = 1 		--下个要打的据点
	self.m_nRemainBingLi = tConf.nBingLi 	--据点剩余兵力
	self.m_nLastWaiJiaoTime = os.time() 	--最后的外交点获取时间

	--BOSS战
	self.m_nCurrMC = 0 			--当前出战知己
	self.m_tMCBatMap = {} 		--已出战知己映射
	self.m_tMCRecMap = {}		--恢复次数映射
	self.m_nLastResetTime = 0 	--上次恢复时间 

	--时装副本
	self.m_tRecFashion = {} 	--推荐时装查看
	self.m_nRecoverTick = nil 	--外交点回复计时器
end

function CDup:LoadData(tData)
	if tData then
		self.m_nLastWaiJiaoTime = tData.m_nLastWaiJiaoTime

		self.m_nCurrMC = tData.m_nCurrMC or 0
		self.m_tMCBatMap = tData.m_tMCBatMap or self.m_tMCBatMap
		self.m_tMCRecMap = tData.m_tMCRecMap or self.m_tMCRecMap
		self.m_nLastResetTime = tData.m_nLastResetTime or 0 --上次恢复时间

		local tConf = ctCheckPointConf[tData.m_nDupID]
		if tConf then
			self.m_nDupID = tData.m_nDupID
			self.m_nStrongHold = tData.m_nStrongHold
			self.m_nRemainBingLi = tData.m_nRemainBingLi
			if self.m_nRemainBingLi == 0 then
				self.m_nRemainBingLi = 1
			end
		else
			for k = tData.m_nDupID + 1, #ctCheckPointConf do
				if ctCheckPointConf[k] then
					self.m_nDupID = k
					self.m_nStrongHold = 1
					self.m_nRemainBingLi= ctCheckPointConf[k].nBingLi
					self:MarkDirty(true)
					break
				end
			end
		end

		self.m_tRecFashion = tData.m_tRecFashion or self.m_tRecFashion
	end
	self:OnLoaded()
end

function CDup:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nDupID = self.m_nDupID
	tData.m_nStrongHold = self.m_nStrongHold
	tData.m_nRemainBingLi= self.m_nRemainBingLi
	tData.m_nLastWaiJiaoTime = self.m_nLastWaiJiaoTime

	tData.m_nCurrMC = self.m_nCurrMC
	tData.m_tMCBatMap = self.m_tMCBatMap
	tData.m_tMCRecMap = self.m_tMCRecMap
	tData.m_nLastResetTime = self.m_nLastResetTime

	tData.m_tRecFashion = self.m_tRecFashion

	return tData
end

function CDup:GetType()
	return gtModuleDef.tDup.nID, gtModuleDef.tDup.sName
end

--离线
function CDup:Offline()
	goTimerMgr:Clear(self.m_nRecoverTick)
	self.m_nRecoverTick = nil
end

--登陆
function CDup:Online()
	self:SyncChapterInfo()
end

--加载数据完成
function CDup:OnLoaded()
	self:CheckRecover()
end

--注册计时器
function CDup:CheckRecover()
	goTimerMgr:Clear(self.m_nRecoverTick)
	self.m_nRecoverTick = nil

	local nNowSec = os.time()
    local nPassTime = nNowSec - self.m_nLastWaiJiaoTime
    local nAddTimes  = math.floor(nPassTime / nWJRecoverTime)
    if nAddTimes > 0 then
        self.m_nLastWaiJiaoTime = self.m_nLastWaiJiaoTime + nAddTimes * nWJRecoverTime
		self:MarkDirty(true)
        self:TimeAward(nAddTimes)
    end

	local nRemainTimeSec = self.m_nLastWaiJiaoTime + nWJRecoverTime - os.time()
    self.m_nRecoverTick = goTimerMgr:Interval(nRemainTimeSec, function() self:CheckRecover() end)
end

--检测知己出战重置
function CDup:CheckReset()
	if not os.IsSameDay(os.time(), self.m_nLastResetTime, 0) then
		self.m_nLastResetTime = os.time()
		self.m_tMCBatMap = {}
		self.m_tMCRecMap = {}
		self:MarkDirty(true)
	end
end
--发放每天奖励
function CDup:TimeAward(nAddTimes)
	local nPropID, nPropNum = self:TimeAwardItem()
	if nPropID <= 0 then
		return
	end
	nPropNum = nPropNum * nAddTimes
	self.m_oPlayer:AddItem(gtItemType.eProp, nPropID, nPropNum, "副本章节每天奖励")
end

--每天获得道具信息
function CDup:TimeAwardItem()
	local tConf = ctCheckPointConf[self.m_nDupID]
	local nChapter = tConf.nChapter
	if not self:IsChapterPass(tConf.nChapter) then
		nChapter = tConf.nChapter - 1
	end
	if nChapter <= 0 then
		return 0, 0
	end
	local tChapterConf = ctChapterConf[nChapter]
	local tAward = tChapterConf.tTimeAward[1]
	return tAward[2], tAward[3]
end

--据点兵力
function CDup:GetBingLi(nDupID, nSh)
	local tConf = assert(ctCheckPointConf[nDupID])
	local nBingLi = math.floor(tConf.nBingLi * (1 + (nSh - 1) * 0.03))
	return nBingLi
end

--据点战力
function CDup:GetZhanLi(nDupID, nSh)
	local tConf = assert(ctCheckPointConf[nDupID])
	local nZhanLi = math.floor(tConf.nZhanLi * (1 + (nSh - 1) * 0.03))
	return nZhanLi
end

--最大的副本ID
function CDup:MaxDupPass()
	if self:IsDupPass(self.m_nDupID) then
		return self.m_nDupID
	end
	return self.m_nDupID - 1
end

--最大通关章节数
function CDup:MaxChapterPass()
	local tConf = ctCheckPointConf[self.m_nDupID]
	if self:IsChapterPass(tConf.nChapter) then
		return tConf.nChapter, self.m_nDupID
	end
	return tConf.nChapter-1, self.m_nDupID
end

--当前已通关的据点数
function CDup:PassSHNum()
	local nSH = 0
	local tConf = ctCheckPointConf[self.m_nDupID]
	for k = 1, tConf.nChapter do
		for _, tDup in ipairs(_tChapterDupConf[k]) do
			if tDup.nID == self.m_nDupID then
				nSH = nSH + self.m_nStrongHold - 1
				break
			elseif tDup.nType ~= self.tType.eFashion then
				nSH = nSH + tDup.nJDNum
			end
		end
	end
	return nSH
end

--章节是否通关
function CDup:IsChapterPass(nChapter)
	local tConf = ctCheckPointConf[self.m_nDupID]
	if not tConf then
		return false
	end
	if nChapter < tConf.nChapter then
		return true
	end
	if nChapter > tConf.nChapter then
		return false
	end
	local nCount = #_tChapterDupConf[tConf.nChapter]
	local tLastConf = _tChapterDupConf[tConf.nChapter][nCount] 
	if tConf.nID == tLastConf.nID and self.m_nStrongHold > tConf.nJDNum then
		return true
	end
	return false
end

--关卡是否通关
function CDup:IsDupPass(nDupID)
	local tCurConf = ctCheckPointConf[self.m_nDupID]
	if not tCurConf then
		return
	end
	local tTarConf = ctCheckPointConf[nDupID]
	if not tTarConf then
		return
	end
	if tTarConf.nChapter < tCurConf.nChapter then
		return true
	end
	if tTarConf.nChapter > tCurConf.nChapter then
		return
	end
	if nDupID < self.m_nDupID then
		return true
	end
	if nDupID > self.m_nDupID then
		return
	end
	if self.m_nStrongHold > tCurConf.nJDNum then
		return true
	end
end

--跳到下1据点
function CDup:TurnNextDup()
	assert(self.m_nDupID > 0)
	local nOldDupID = self.m_nDupID
	local nOldStrongHold = self.m_nStrongHold

	local tConf = ctCheckPointConf[self.m_nDupID]
	local tDupList = _tChapterDupConf[tConf.nChapter]

	if self.m_nStrongHold >= tConf.nJDNum then	
		--下1章
		if self.m_nDupID == tDupList[#tDupList].nID then
			if _tChapterDupConf[tConf.nChapter+1] then
				local tTmpConf = _tChapterDupConf[tConf.nChapter+1][1]
				self.m_nDupID = tTmpConf.nID
				self.m_nStrongHold = 1
				self.m_nRemainBingLi = self:GetBingLi(self.m_nDupID, self.m_nStrongHold)
			else
				self.m_nStrongHold = tConf.nJDNum + 1 --最后据点下1个(已通关所有章节)
				self.m_nRemainBingLi = 0
			end
		else
		--下1关卡
			local nDupID = 0
			for _, tTmpConf in ipairs(tDupList) do
				if tTmpConf.nID > self.m_nDupID then
					nDupID = tTmpConf.nID
					break
				end
			end
			assert(nDupID > 0, "数据错误")
			self.m_nDupID = nDupID
			self.m_nStrongHold = 1
			self.m_nRemainBingLi = self:GetBingLi(self.m_nDupID, self.m_nStrongHold)
		end

	else
	--下1据点
		self.m_nStrongHold = self.m_nStrongHold + 1
		self.m_nRemainBingLi = self:GetBingLi(self.m_nDupID, self.m_nStrongHold)

	end
	self:MarkDirty(true)

	--更新外交点(役事点上限)
	self.m_oPlayer:UpdateMaxWaiJiao()
	--任务(通过某章某关卡)
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond10, self.m_nDupID, self.m_nStrongHold, true)	
	if tConf.nType ~= self.tType.eFashion then
		--任务(通关据点数)
		self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond41, self:PassSHNum(), nil, true)
		--每日任务(通关据点数)
		self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond8, 1)
		--成就系统(关卡胜利次数)
		self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond5, 1)
	end
    goOfflineDataMgr:UpdateChapter(self.m_oPlayer, self:MaxChapterPass())
    goRankingMgr.m_oDupRanking:Update(self.m_oPlayer, self:PassSHNum(), self.m_nDupID)

    --每关BOSS战次数独立
    if self:IsDupPass(nOldDupID) then
    	self.m_nLastResetTime = 0
    	self:CheckReset()
    end
    
    --激活藩属(赐礼)
    if self:IsChapterPass(tConf.nChapter) then
	    self.m_oPlayer.m_oLiFanYuan:OnChapterPass(tConf.nChapter)
	    -- self.m_oPlayer.m_oMingChen:OnChapterPass(tConf.nChapter)
    end
end

--取章节信息
function CDup:SyncChapterInfo()
	local tConf = assert(ctCheckPointConf[self.m_nDupID])
	local tMsg = {
		nDupID = self.m_nDupID,
		nStrongHold = self.m_nStrongHold,
		nMyBingLi = self.m_oPlayer:GetBingLi(),
		nMaxChapter = self:MaxChapterPass(),
		nMaxDupID = self:MaxDupPass(),
	}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ChapterInfoRet", tMsg)

	--奖励记录
	goAwardRecordMgr:AwardRecordReq(self.m_oPlayer, gtAwardRecordDef.eZhengFuShiJie)
end

--关卡信息请求
function CDup:DupInfoReq()
	self:CheckReset()	
	local tConf = assert(ctCheckPointConf[self.m_nDupID])
	if tConf.nType == self.tType.eBoss then
		self:AutoSelectMC()
	elseif tConf.nType == self.tType.eFashion then
	end
	self:SyncDupInfo()
end

--取关卡信息
function CDup:SyncDupInfo()
	local tConf = ctCheckPointConf[self.m_nDupID]
	local tMsg = {
		nType = tConf.nType,
		nDupID = self.m_nDupID,
		nStrongHold = self.m_nStrongHold,
		nMyBingLi = self.m_oPlayer:GetBingLi(),
		nDupOrgBingLi = self:GetBingLi(self.m_nDupID, self.m_nStrongHold),
		nDupBingLi = self.m_nRemainBingLi,
		nMaxChapter = self:MaxChapterPass(),
		nMaxDupID = self:MaxDupPass(),
		bHasCard = self.m_oPlayer.m_oShenJiZhuFu:HashCard(),
	}

	--BOSS信息
	if tMsg.nType == self.tType.eBoss then
		local oMC = self.m_oPlayer.m_oMingChen:GetObj(self.m_nCurrMC)
		local nPower = oMC and oMC:GetPower() or 0
		tMsg.tMC = {nMCID=self.m_nCurrMC, nPower=nPower}

	--时装副本是否免费查看推荐
	elseif tMsg.nType == self.tType.eFashion then
		tMsg.bFreeFashion = self.m_tRecFashion[self.m_nDupID] and true or false

	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "DupInfoRet", tMsg)
end

--战斗
function CDup:BattleReq()
	local tConf = assert(ctCheckPointConf[self.m_nDupID])
	local nChapter = tConf.nChapter

	if self.m_nStrongHold > tConf.nJDNum then
		return self.m_oPlayer:Tips("已经通关所有关卡")
	end

	local tMsg
	local nZhuFu, nLostBingLi = 0, 0
	if tConf.nType == self.tType.eBoss then
		tMsg, nLostBingLi, nZhuFu = self:BossBattle()
	elseif tConf.nType == self.tType.eNormal then
		tMsg, nLostBingLi, nZhuFu = self:NormalBattle()
	elseif tConf.nType == self.tType.eFashion then
		tMsg, nLostBingLi, nZhuFu = self:CalcScoreReq()
	end
	if not tMsg then
		return self.m_oPlayer:Tips("数据错误")
	end

	if tMsg.bWin then
		--最后据点通关额外奖励
		if self.m_nStrongHold >= tConf.nJDNum then
			for _, tItem in ipairs(tConf.tJDAward) do
				if tItem[1] > 0 then
					self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "通关据点奖励")
					table.insert(tMsg.tAward, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
				end
			end
		end
		--进入下1关卡	
		self:TurnNextDup()
		--发送消息	
		tMsg.nPassChapter = self:IsChapterPass(nChapter) and nChapter or 0
		--更新账号日志
		goLogger:UpdateAccountLog(self.m_oPlayer, {chapter=self:MaxChapterPass()})

		--添加奖励记录
		if self:IsChapterPass(nChapter) then
			local sChapterName = self:ChapterName(nChapter)
			local sRecord = string.format(ctLang[25], self.m_oPlayer:GetName(), sChapterName)
			goAwardRecordMgr:AddRecord(gtAwardRecordDef.eZhengFuShiJie, sRecord)
		end
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "BattleRet", tMsg)

	--日志
	goLogger:EventLog(gtEvent.eBattle, self.m_oPlayer, tMsg.bWin, nLostBingLi, self.m_nDupID, self.m_nStrongHold, nZhuFu>0)
	-- self:SyncDupInfo()
end

--BOSS战斗
function CDup:BossBattle()
	local tConf = ctCheckPointConf[self.m_nDupID]

	if self.m_nRemainBingLi <= 0 then
		return self.m_oPlayer:Tips("BOSS已死亡")
	end
	if self.m_nCurrMC <= 0 then
		return self.m_oPlayer:Tips("请选择出战知己")
	end

	local oMC = self.m_oPlayer.m_oMingChen:GetObj(self.m_nCurrMC)
	if not oMC then
		return self.m_oPlayer:Tips("请先招募知己")
	end
	local nMCID, nPower = oMC:GetID(), oMC:GetPower()
	self.m_tMCBatMap[nMCID] = 1
	self.m_nRemainBingLi = math.max(0, self.m_nRemainBingLi-nPower) 
	self:MarkDirty(true)

	local tRound = {}
	table.insert(tRound, {nMCID=nMCID,
		nPower=nPower,
		nHurt=nPower,
		nOrgBossHP=self:GetBingLi(self.m_nDupID, self.m_nStrongHold),
		nBossHP=self.m_nRemainBingLi,
	})
	self:AutoSelectMC()

	--消息
	local tMsg = {
		bWin = false,
		nDupID = self.m_nDupID,
		nType = self.tType.eBoss,
		nStrongHold = self.m_nStrongHold,
		tRound = tRound,
		nPassChapter = 0,
		tAward = {}
	}

	if self.m_nRemainBingLi <= 0 then
		tMsg.bWin = true
		for _, tItem in ipairs(tConf.tAward) do
			self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "BOSS战斗胜利")
			table.insert(tMsg.tAward, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
		end
	end
	return tMsg, 0, 0
end

--普通战斗
function CDup:NormalBattle()
	local tConf = assert(ctCheckPointConf[self.m_nDupID])
	local tMyAttr = self.m_oPlayer:GetAttr()
	local nMyBingLi = self.m_oPlayer:GetBingLi()
	local nLostBingLi = math.floor(self.m_nRemainBingLi * tConf.nZhanLi / math.max(1, tMyAttr[4]))

	local tMsg =  {
		bWin=false,
		nDupID=self.m_nDupID,
		nType=self.tType.eNormal,
		nStrongHold=self.m_nStrongHold,
		nPassChapter=0,
		tAward = {},
		tNPC = {},
	}
	--NPC1
	tMsg.tNPC[1] = ctCheckPointNpcConf[math.random(#ctCheckPointNpcConf)].nID
	--NPC2
	local n = 128
	while n > 0 do
		n = n - 1
		local nNPC2 = ctCheckPointNpcConf[math.random(#ctCheckPointNpcConf)].nID
		if tMsg.tNPC[1] ~= nNPC2 then
			tMsg.tNPC[2] = nNPC2
			break
		end
	end

	local nZhuFu = 0	
	--胜利
	if nMyBingLi >= nLostBingLi then
		--神迹祝福
		if self.m_oPlayer.m_oShenJiZhuFu:ShenJiZhuFu(gtSJZFDef.eQSHS) > 0 then
			nZhuFu = nLostBingLi
		end
		nLostBingLi = nLostBingLi - nZhuFu
		self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eBingLi, nLostBingLi, "战斗胜利")

		for _, tItem in ipairs(tConf.tAward) do
			self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "战斗胜利")
			table.insert(tMsg.tAward, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
		end

		--消息
		tMsg.bWin = true
		tMsg.tBL = {{nBefore=nMyBingLi,nAfter=self.m_oPlayer:GetBingLi()},{nBefore=self.m_nRemainBingLi,nAfter=0}}

	--失败
	else
		--神迹祝福
		-- if self.m_oPlayer.m_oShenJiZhuFu:ShenJiZhuFu(gtSJZFDef.eQSHS) > 0 then
		-- 	nZhuFu = nMyBingLi
		-- end
		-- if nZhuFu == 0 then
		-- 	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eBingLi, nMyBingLi, "战斗失败")
		-- end
		-- local nRealLostBingLi = math.min(nMyBingLi, nLostBingLi)
		-- local nSubBingLi = math.floor(nRealLostBingLi / math.max(1, tConf.nZhanLi) * tMyAttr[4])
		-- local nOrgRemainBingLi = self.m_nRemainBingLi 
		-- self.m_nRemainBingLi = math.max(0, self.m_nRemainBingLi-nSubBingLi)
		-- print("失败敌方扣除兵力:", nSubBingLi)

		--消息
		tMsg.bWin = false
		tMsg.tBL = {{nBefore=nMyBingLi,nAfter=nMyBingLi},{nBefore=self.m_nRemainBingLi,nAfter=self.m_nRemainBingLi}}

	end
	self:MarkDirty(true)
	return tMsg, nLostBingLi, nZhuFu
end

--章节名字
function CDup:ChapterName(nChapterID)
	local tConf = ctChapterConf[nChapterID]
	return (tConf and tConf.sName or "")
end

--关卡名字
function CDup:DupName(nDupID)
	local tConf = ctCheckPointConf[nDupID]
	return (tConf and tConf.sName or "")
end


--自动选择知己
function CDup:AutoSelectMC()
	self.m_nCurrMC = 0	
	self:MarkDirty(true)

	local tMCList = {}
	local tMCMap = self.m_oPlayer.m_oMingChen:GetMCMap()
	for nID, oMC in pairs(tMCMap) do
		if not self.m_tMCBatMap[nID] then
			table.insert(tMCList, {nID=nID, nPower=oMC:GetPower()})
		end
	end
	table.sort(tMCList, function(tMC1, tMC2) return tMC1.nPower > tMC2.nPower end)
	local tMC = tMCList[1]
	if tMC then
		self.m_nCurrMC = tMC.nID
		self:MarkDirty(true)
	end
	if self.m_nCurrMC > 0 then	
		return true
	end
end

--知己列表请求
function CDup:DupMCListReq()
	self:CheckReset()

	local tList = {}
	local tMCMap = self.m_oPlayer.m_oMingChen:GetMCMap()
	for nID, oMC in pairs(tMCMap) do
		local tInfo = {}
		tInfo.nID = nID
		tInfo.sName = oMC:GetName()
		tInfo.nLv = oMC:GetLevel()
		tInfo.nAttr = oMC:GetQua(4)
		tInfo.nPower = oMC:GetPower()
		tInfo.nState = 0 --可出战
		if self.m_nCurrMC == nID then
			tInfo.nState = 1 --出战中

		elseif self.m_tMCBatMap[nID] then
			if not self.m_tMCRecMap[nID] then
				tInfo.nState = 2 --可恢复
			else 
				tInfo.nState = 3 --已出战
			end

		end
		table.insert(tList, tInfo)
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "DupMCListRet", {tList=tList})
end

--知己出战请求
function CDup:DupMCCZReq(nMCID)
	--已出战
	if self.m_tMCBatMap[nMCID]	then
		return self.m_oPlayer:Tips("知己已经出战过")
	end
	--出战中
	if self.m_nCurrMC == nMCID then
		return self.m_oPlayer:Tips("知己已经出战中")
	end
	self.m_nCurrMC = nMCID
	self:MarkDirty(true)
	self:DupMCListReq()
	self:SyncDupInfo() --用来显示当前大臣
end

--恢复次数请求
function CDup:DupMCRecReq(nMCID)
	--没有出战过
	if not self.m_tMCBatMap[nMCID] then
		return
	end
	--已恢复过
	if self.m_tMCRecMap[nMCID] then
		return
	end
	local nPropID = ctDupEtcConf[1].nCZLProp
	if self.m_oPlayer:GetItemCount(gtItemType.eProp, nPropID) <= 0 then
		return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(nPropID)))
	end
	self.m_oPlayer:SubItem(gtItemType.eProp, nPropID, 1, "知己恢复出战")
	self.m_tMCBatMap[nMCID] = nil
	self.m_tMCRecMap[nMCID] = 1
	self:MarkDirty(true)
	self:DupMCListReq()
end

--查看时装推荐
function CDup:RecFashionReq()
	local tConf = ctCheckPointConf[self.m_nDupID]
	if tConf.nType ~= self.tType.eFashion then
		return self.m_oPlayer:Tips("副本类型错误")
	end
	local tFSConf = ctFashionDupConf[self.m_nDupID]
	local nCost = tFSConf.nCost
	if not self.m_tRecFashion[self.m_nDupID] then
		if self.m_oPlayer:GetYuanBao() < nCost then
			return self.m_oPlayer:YBDlg()
		end
		self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nCost, "时装推荐")
		self.m_tRecFashion[self.m_nDupID] = 1
		self:MarkDirty(true)
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "RecFashionRet", {bSuccess=true})
	self:SyncDupInfo()
end

--评分请求
function CDup:CalcScoreReq()
	local nTotalScore, tScoreList = self.m_oPlayer.m_oFashion:CalcDupScore(self.m_nDupID)
	local tFSDupConf = ctFashionDupConf[self.m_nDupID]
	local bWin = nTotalScore >= tFSDupConf.nPassScore and true or false
	local tPingJi = {"S", "A", "B", "C"}
	local sPingJi = ""
	for k=1, #tFSDupConf.tPingJi[1] do
		if nTotalScore >= tFSDupConf.tPingJi[1][k] then
			sPingJi = tPingJi[k]
			break
		end
	end
	local tAward = {}
	if bWin then
		local tDupConf = ctCheckPointConf[self.m_nDupID]
		for _, tItem in ipairs(tDupConf.tAward) do
			self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "战斗胜利")
			table.insert(tAward, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
		end
	end
	local tMsg = {
		bWin = bWin,
		nDupID = self.m_nDupID,
		nType = self.tType.eFashion,
		nStrongHold = self.m_nStrongHold,
		tFashion = {nTotalScore=nTotalScore, sPingJi=sPingJi, tScoreList=tScoreList},
		nPassChapter = 0,
		tAward = tAward,
	}
	return tMsg, 0, 0
end

--GM通关
function CDup:GMDupPass(nDupID)
	local tConf = ctCheckPointConf[nDupID]
	if not tConf then
		return self.m_oPlayer:Tips("关卡不存在:"..nDupID)
	end
	self.m_nDupID = nDupID
	self.m_nStrongHold = ctCheckPointConf[nDupID].nJDNum
	self:TurnNextDup()
	self:SyncChapterInfo()
	self:MarkDirty(true)
	return true
end