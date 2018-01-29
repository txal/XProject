--结伴游园
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CJingShiFang:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nOpenGrid = 1		--解锁格子数
	self.m_tUseTimes = {} 		--格子已翻牌次数
	self.m_tGridMap = {} 		--{[id]={nMCID=0,nTime=0},...}
	self.m_nResetTime = os.time()
	self.m_tMCCDMap = {} 		--知己冷却
end

function CJingShiFang:LoadData(tData)
	if not tData then
		return
	end
	self.m_nOpenGrid = tData.m_nOpenGrid
	self.m_tUseTimes = tData.m_tUseTimes
	self.m_nResetTime = tData.m_nResetTime
	self.m_tMCCDMap = tData.m_tMCCDMap or {}
	for nID, tTmp in pairs(tData.m_tGridMap) do
		if ctMingChenConf[tTmp.nMCID] then
			self.m_tGridMap[nID] = tTmp
		end
	end
end

function CJingShiFang:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nOpenGrid = self.m_nOpenGrid
	tData.m_tUseTimes = self.m_tUseTimes
	tData.m_nResetTime = self.m_nResetTime
	tData.m_tGridMap = self.m_tGridMap
	tData.m_tMCCDMap = self.m_tMCCDMap
	return tData
end

function CJingShiFang:GetType()
	return gtModuleDef.tJingShiFang.nID, gtModuleDef.tJingShiFang.sName
end

function CJingShiFang:Online()
	self:CheckReset()
	self:CheckRedPoint()
end

--游玩信息请求
function CJingShiFang:InfoReq()
	self:SyncInfo()
	self:CheckRedPoint()
end

--同步信息
function CJingShiFang:SyncInfo()
	self:CheckReset()
	local nNowSec = os.time()
	local nKeepTime = ctJingShiFangEtcConf[1].nKeepTime
	local nZRFFreeGrids = self.m_oPlayer.m_oZongRenFu:GetFreeGrid()
	local tMsg = {tList={}, nOpenGrid=self.m_nOpenGrid, nZRFFreeGrids=nZRFFreeGrids}

	for k = 1, self.m_nOpenGrid do
		local tInfo = {nMCID=0, nRemainTime=0}
		local nDailyTimes = ctJingShiFangEtcConf[1].tTimes[1][k]
		tInfo.nRemainTimes = nDailyTimes - (self.m_tUseTimes[k] or 0)
		
		local tGrid = self.m_tGridMap[k]
		if tGrid then
			tInfo.nMCID = tGrid.nMCID
			tInfo.nRemainTime = math.max(0, tGrid.nTime+nKeepTime-nNowSec)
		end
		table.insert(tMsg.tList, tInfo)
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JSFInfoRet", tMsg)
end

--扩建
function CJingShiFang:OpenGridReq(nGridID)
	assert(self.m_nOpenGrid < nGridID, "已经解锁")
	assert(nGridID >= 2 and nGridID <= 3, "参数错误")
	if self.m_nOpenGrid+1 ~= nGridID then 
		return self.m_oPlayer:Tips("请按顺序开启")
	end
	local nYuanBao = ctJingShiFangEtcConf[1].tYuanBao[1][nGridID]
	if self.m_oPlayer:GetYuanBao() < nYuanBao then
		return self.m_oPlayer:YBDlg()
	end
	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nYuanBao, "游园扩建")
	self.m_nOpenGrid = self.m_nOpenGrid + 1
	self:MarkDirty(true)
	self:SyncInfo()
	self.m_oPlayer:Tips("扩建成功")
	--小红点
	self:CheckRedPoint()
	--电视
	local sNotice = string.format(ctLang[6], self.m_oPlayer:GetName())
	goTV:_TVSend(sNotice)	
	--任务
    self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond48, 1)
end

--检测次数重置
function CJingShiFang:CheckReset()
	local nNowSec = os.time()
	if not os.IsSameDay(nNowSec, self.m_nResetTime, 5*3600) then
		self.m_nResetTime = nNowSec
		self.m_tUseTimes = {}
		self:MarkDirty(true)
		--小红点
		self:CheckRedPoint()
	end
end

--取空闲知己列表
function CJingShiFang:GetFreeZJList()
	local nNowSec = os.time()

	local tList = {}
	local tZJMap = self.m_oPlayer.m_oMingChen:GetMCMap()
	for nID, oMC in pairs(tZJMap) do
		if (self.m_tMCCDMap[nID] or 0) <= nNowSec then
			table.insert(tList, oMC)
		end
	end
	return tList
end

--翻牌
function CJingShiFang:OpenCardReq(nGridID)
	assert(nGridID >= 1 and nGridID <= self.m_nOpenGrid, "格子非法")
	if self.m_tGridMap[nGridID] then
		return self.m_oPlayer:Tips("该位置已经有游伴了")
	end
	self:CheckReset()

	local nUseTimes = self.m_tUseTimes[nGridID] or 0
	local tDailyTimes = ctJingShiFangEtcConf[1].tTimes[1]
	if nUseTimes >= tDailyTimes[nGridID] then
		return self.m_oPlayer:Tips("游园次数已达上限，请娘娘明天再来吧")
	end

	local tMCList = self:GetFreeZJList()
	if #tMCList <= 0 then
		return self.m_oPlayer:Tips("娘娘，知己们目前都在休息中呢，请稍后再来吧。")
	end

	local nRnd = math.random(1, #tMCList)
	local oMC = tMCList[nRnd]
	self.m_tUseTimes[nGridID] = (self.m_tUseTimes[nGridID] or 0) + 1
	self.m_tGridMap[nGridID] = {nMCID=oMC:GetID(), nTime=os.time()}
	self.m_tMCCDMap[oMC:GetID()] = nMAX_INTEGER
	self:MarkDirty(true)
	self:SyncInfo()

	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond12, 1)	
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond12, 1)	
	--成就
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond20, 1)
	--小红点
	self:CheckRedPoint()
end

--游园完成
function CJingShiFang:OnYWFinish(oMC, bChild)
	local nCDTime = 0
	local nQinMi = oMC:GetQinMi()
	for k = #ctJingShiFangChildConf, 1, -1  do
		local tConf = ctJingShiFangChildConf[k]
		if nQinMi >= tConf.nQinMi then
			nCDTime = bChild and tConf.nChildCD*60 or tConf.nNoChildCD*60
			break
		end
	end
	local nMCID = oMC:GetID()
	self.m_tMCCDMap[nMCID] = os.time() + nCDTime
	self:MarkDirty(true)
end

--完成
function CJingShiFang:FinishReq(nGridID)
	assert(nGridID >= 1 and nGridID <= self.m_nOpenGrid, "格子非法")
	assert(self.m_tGridMap[nGridID], "格子没自己")
	local nKeepTime = ctJingShiFangEtcConf[1].nKeepTime
	if os.time() < nKeepTime + self.m_tGridMap[nGridID].nTime then
		return self.m_oPlayer:Tips("游园时间未结束")
	end

	local nChildRes = -1 
	local nMCID = self.m_tGridMap[nGridID].nMCID
	local nTec = ctMingChenConf[nMCID].nTec
	local oMC = self.m_oPlayer.m_oMingChen:GetObj(nMCID)
	local nAttrAdd = 100 --fix pd
	if oMC then
		local nZhuFu = self.m_oPlayer.m_oShenJiZhuFu:ShenJiZhuFu(gtSJZFDef.eLYCF)  --神迹祝福
		nZhuFu = math.max(1, nZhuFu)
		nAttrAdd = nAttrAdd * nZhuFu
		--技能点
		oMC:AddSKPoint(nAttrAdd, "知己游园")
		nChildRes = oMC:ChildCheck() --生孩子检测
	else
		self.m_oPlayer:Tips("知己不存在")
	end
	self.m_tGridMap[nGridID] = nil
	self:MarkDirty(true)
	self:SyncInfo()
	
	if oMC then
		self:OnYWFinish(oMC, nChildRes==0)
		self.m_oPlayer:Tips(string.format("技能点+%d", nAttrAdd))
	end
	--小红点
	self:CheckRedPoint()
end

--是否在游园中
function CJingShiFang:CheckYouWan(nMCID, bNotTips)
	local tGrid
	for k = 1, self.m_nOpenGrid do
		local tMC = self.m_tGridMap[k]
		if tMC and tMC.nMCID == nMCID then
			tGrid = tMC
			break
		end
	end
	if not tGrid then
		if not bNotTips then
			self.m_oPlayer:Tips("知己不在游园中")
		end
		return
	end

	local nKeepTime = ctJingShiFangEtcConf[1].nKeepTime
	local nRemainTime = math.max(0, nKeepTime+tGrid.nTime-os.time())
	if nRemainTime <= 0 then
		if not bNotTips then
			self.m_oPlayer:Tips("知己游园已结束")
		end
	end
	return tGrid, nRemainTime
end

--取加速信息
function CJingShiFang:SpeedUpInfoReq(nMCID)
	local tGrid, nRemainTime = self:CheckYouWan(nMCID)
	if not tGrid or nRemainTime <= 0 then --不在游园中或已结束
		return
	end
	local tProp = ctJingShiFangEtcConf[1].tProp[1] --加速道具
	local nKeepTime = ctJingShiFangEtcConf[1].nKeepTime
	local nRemainTime = tGrid.nTime+nKeepTime-os.time()
	local nCostYB = self:SpeedUpCostYB(nRemainTime)
	local tMsg = {
		nPropID = tProp[2],
		nPropNum = tProp[3],
		nCostYB = nCostYB,
	}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JSFSpeedUpInfoRet", tMsg)
end

function CJingShiFang:SpeedUpCostYB(nCDTime)
	local nRemainMin = math.ceil(nCDTime/60)
	return nRemainMin
end

--加速侍寝请求
function CJingShiFang:SpeedUpReq(nMCID, nType)
	local tGrid, nRemainTime = self:CheckYouWan(nMCID)
	if not tGrid or nRemainTime <= 0 then --不在游园中或已结束
		return
	end
	local nKeepTime = ctJingShiFangEtcConf[1].nKeepTime
	if nType == 1 then --加速道具
		local tProp = ctJingShiFangEtcConf[1].tProp[1]
		if self.m_oPlayer:GetItemCount(tProp[1], tProp[2]) < tProp[3] then
			return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tProp[2])))
		end
		self.m_oPlayer:SubItem(tProp[1], tProp[2], tProp[3], "游园加速")
		tGrid.nTime = tGrid.nTime - 3600 --加速1小时
		self:MarkDirty(true)
		self:SyncInfo()

	elseif nType == 2 then --元宝
		local nRemainTime = tGrid.nTime+nKeepTime-os.time()
		local nCostYB = self:SpeedUpCostYB(nRemainTime)
		if self.m_oPlayer:GetYuanBao() < nCostYB then
			return self.m_oPlayer:YBDlg()
		end
		self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nCostYB, "游园加速")
		tGrid.nTime = tGrid.nTime - nRemainTime
		self:MarkDirty(true)
		self:SyncInfo()

	end
	self.m_oPlayer:Tips("加速游园成功")
	self:DetailReq()
end

--小红点
function CJingShiFang:CheckRedPoint()
	local tDailyTimes = ctJingShiFangEtcConf[1].tTimes[1]
	local nKeepTime = ctJingShiFangEtcConf[1].nKeepTime

	for k = 1, self.m_nOpenGrid do
		if not self.m_tGridMap[k] then
			local nUseTimes = self.m_tUseTimes[k] or 0
			local tMCList = self:GetFreeZJList()
			if nUseTimes < tDailyTimes[k] and #tMCList > 0 then
				return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eJSFCard, 1)
			end
		else
			if os.time() >= nKeepTime+self.m_tGridMap[k].nTime then
				return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eJSFCard, 1)
			end
		end
	end
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eJSFCard, 0)
end

--详情请求
function CJingShiFang:DetailReq()
	local tList = {}
	local tMCMap = self.m_oPlayer.m_oMingChen:GetMCMap()
	for nID, oMC in pairs(tMCMap) do
		local tConf = ctMingChenConf[nID]
		--nState: 0空闲中; 1游园中; 2休息中
		local tInfo = {nMCID=nID, sName=oMC:GetName(), nPingJi=tConf.nPingJi, nState=0, nStateTime=0}
		local tGrid, nRemainTime = self:CheckYouWan(nID, true)
		if tGrid then
			tInfo.nState = 1
			tInfo.nStateTime = nRemainTime
		else
			local nCDTime = (self.m_tMCCDMap[nID] or 0) - os.time()
			if nCDTime > 0 then
				tInfo.nState = 2
				tInfo.nStateTime = nCDTime
			end
		end
		table.insert(tList, tInfo)
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JSFDetailRet", {tList=tList})
end

--重置次数
function CJingShiFang:GMReset()
	self.m_nResetTime = 0
	self:CheckReset()
end