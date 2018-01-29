--神迹祝福活动
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nMonthCardID = 7 --月卡ID
local nSeasonCardID = 8 --季卡ID

function CShenJiZhuFu:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tCardMap = {} 			--月卡/季卡信息{[id]={expiretime=0,dayaward=false,bTrial=false},..}
	self.m_tZhuFuMap = {}			--祝福状态映射{[type]=times,...}
	self.m_nResetTime = os.time()	--重置触发祝福时间
	self.m_bTrialed = false 		--是否已经试用过月卡
	self.m_bTrialExpire = false 	--月卡过期(客户端弹框用)
end

function CShenJiZhuFu:LoadData(tData)
	if not tData then
		return
	end
	print("CShenJiZhuFu:LoadData***", tData)
	self.m_nResetTime = tData.m_nResetTime
	self.m_bTrialed = tData.m_bTrialed or self.m_bTrialed
	self.m_bTrialExpire = tData.m_bTrialExpire or self.m_bTrialExpire
	self.m_tZhuFuMap = tData.m_tZhuFuMap
	self.m_tCardMap = tData.m_tCardMap
end

function CShenJiZhuFu:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nResetTime = self.m_nResetTime
	tData.m_tZhuFuMap = self.m_tZhuFuMap
	tData.m_tCardMap = self.m_tCardMap
	tData.m_bTrialed = self.m_bTrialed
	tData.m_bTrialExpire = self.m_bTrialExpire
	return tData
end

function CShenJiZhuFu:GetType()
	return gtModuleDef.tShenJiZhuFu.nID, gtModuleDef.tShenJiZhuFu.sName
end

function CShenJiZhuFu:Online()
	self:ShenJiCardInfoReq()
end

--祝福上限
function CShenJiZhuFu:MaxZhuFu(nType)
	self:CheckReset()
	local nMaxTimes = ctSJZFContentConf[nType].nTimes
	for nID, tCard in pairs(self.m_tCardMap) do
		nMaxTimes = nMaxTimes + ctCardConf[nID].nSJAddTimes
	end
	return nMaxTimes
end

--检测重置
function CShenJiZhuFu:CheckReset()
	--检测月卡/季卡过期
	for nID, tCard in pairs(self.m_tCardMap) do
		local tConf = ctCardConf[nID]
		if os.time() >= tCard.nExpireTime then
			self.m_tCardMap[nID] = nil
			if tCard.bTrial then
				self.m_bTrialExpire = true
			end
			self:MarkDirty(true)
		end
	end

	--检测重置
	if not os.IsSameDay(os.time(), self.m_nResetTime, 5*3600) then
		print("CShenJiZhuFu:CheckReset***")
		self.m_nResetTime = os.time()
		self.m_tZhuFuMap = {}
		for nID, tCard in pairs(self.m_tCardMap) do
			tCard.bDayAward = false
		end
		self:MarkDirty(true)
	end
	return bTrialExpire
end

--神迹祝福
function CShenJiZhuFu:ShenJiZhuFu(nType, bNotSync)
	self:CheckReset()

	local tZhuFu = assert(ctSJZFContentConf[nType], "神迹不存在:"..nType)
	local nMaxTimes = self:MaxZhuFu(nType)
	local nProbability = tZhuFu.nProbability
	local nCurrTimes = self.m_tZhuFuMap[nType] or 0
	if nCurrTimes >= nMaxTimes then
		return 0
	else
		local nRnd = math.random(1, 100)
		if nRnd <= nProbability then 
			self.m_tZhuFuMap[nType] = nCurrTimes + 1
			self:MarkDirty(true)
			if not bNotSync then
				self:SyncShenJiZhuFu(nType)
			end
			goLogger:EventLog(gtEvent.eShenJiZhuFu, self.m_oPlayer, nType, tZhuFu.sName)
			return tZhuFu.nAward
		else
			return 0
		end
	end
end

--神迹祝福信息请求
function CShenJiZhuFu:ShenJiZhuFuInfoReq()
	local tZhuFu = {}
	for nID=1, #ctSJZFContentConf do 
		self.m_tZhuFuMap[nID] = self.m_tZhuFuMap[nID] or 0
		table.insert(tZhuFu, {nType=nID, nCount=self.m_tZhuFuMap[nID]})
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ShenJiZhuFuInfoRet", {tZhuFu=tZhuFu})
end

--触发神迹通知
function CShenJiZhuFu:SyncShenJiZhuFu(nType)
	local nTimes = self.m_tZhuFuMap[nType]
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ShenJiZhuFuRet", {nType=nType, nTimes=nTimes})
end

--充值成功事件(处理月卡/季卡)
function CShenJiZhuFu:OnRechargeSuccess(nID)
	local tRechargeConf = ctRechargeConf[nID]
	if not tRechargeConf or not tRechargeConf.bCard then
		return
	end
	self:CheckReset()

	local tCardConf = ctCardConf[nID]
	local tCard = self.m_tCardMap[nID]
	if not tCard or tCard.bTrial then
		tCard = {nExpireTime=os.time()+tCardConf.nDay*24*3600, bDayAward=false}
	else
		tCard.nExpireTime = tCard.nExpireTime+tCardConf.nDay*24*3600
	end
	self.m_tCardMap[nID] = tCard
	self:MarkDirty(true)

	--同步
	self:ShenJiCardInfoReq()
	self.m_oPlayer:Tips(string.format("成功购买%s", tRechargeConf.sName))
end

--神迹卡券信息请求
function CShenJiZhuFu:ShenJiCardInfoReq()
	self:CheckReset()

	local tList = {}
	for nID, tConf in pairs(ctCardConf) do
		local nMoney = assert(ctRechargeConf[nID]).nMoney
		local tInfo = {nID=nID, nMoney=nMoney, bCanGetAward=false, nCardRemainTime=0, bTrial=false}
		local tCard = self.m_tCardMap[nID]		
		if tCard then
			tInfo.bCanGetAward = not tCard.bDayAward 
			tInfo.nCardRemainTime = math.max(0, tCard.nExpireTime-os.time())
			tInfo.bTrial = tCard.bTrial or false
		end
		table.insert(tList, tInfo)
	end

	local tMsg = {tList=tList, bTrialExpire=false}
	if self.m_bTrialExpire then
		self.m_bTrialExpire = false
		tMsg.bTrialExpire = self.m_bTrialExpiretrue
		self:MarkDirty(true)
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ShenJiCardInfoRet", tMsg)
end

--领取奖励请求
function CShenJiZhuFu:ShenJiCardAwardReq(nID)
	self:CheckReset()
	local tConf = ctCardConf[nID]

	if not tConf then
		return self.m_oPlayer:Tips("卡券不存在")
	end
	local tCard = self.m_tCardMap[nID]
	if not tCard then
		return self.m_oPlayer:Tips(string.format("%s已过期", tConf.sName))
	end
	if tCard.bTrial then
		return self.m_oPlayer:Tips("体验卡不能领取元宝")
	end
	if tCard.bDayAward then
		return self.m_oPlayer:Tips("今日已领取过了")
	end
	tCard.bDayAward = true
	self:MarkDirty(true)

	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, tConf.nDayYB, "领取"..tConf.sName)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ShenJiCardAwardRet", {nYuanBao=tConf.nDayYB})
	self:ShenJiCardInfoReq()

	--任务
	if nID == nMonthCardID then
		self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond2, 1)
	elseif nID == nSeasonCardID then
		self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond19, 1)
	end
end

--是否有月卡/季卡
function CShenJiZhuFu:HashCard()
	self:CheckReset()
	local nID = next(self.m_tCardMap)
	if nID then
		return true
	end
	return false
end

--试用月卡请求
function CShenJiZhuFu:TrialMonthCardReq()
	self:CheckReset()
	if self.m_bTrialed then
		return self.m_oPlayer:Tips("您已试用过月卡")
	end
	local tCard = self.m_tCardMap[nMonthCardID]
	if tCard then
		return self.m_oPlayer:Tips("您已拥有月卡")
	end
	self.m_tCardMap[nMonthCardID] = {nExpireTime=os.time()+600, bDayAward=false, bTrial=true}
	self.m_bTrialed = true
	self:MarkDirty(true)
	self:ShenJiCardInfoReq()
	self.m_oPlayer:Tips("试用月卡成功")
end

