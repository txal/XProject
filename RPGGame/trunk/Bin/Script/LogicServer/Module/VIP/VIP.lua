--VIP系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CVIP:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nTotalMoney = 0 	--累计充值RMB
	self.m_tRechargeMap = {} 	--充值记录:{[nTime]={nMoney,nYuanBao}, ...}
	self.m_tRechargeIDMap = {} 	--充值ID记录:{[id]=count}, ...}
	self.m_nFirstRechargeState = 0 	--首充状态:0未满足; 1未领取; 2已领取
	self.m_tAwardMap = {[0]=1} 	--特权礼包:{[nVIP]=nState, ...} nState:0未达成; 1已达成未领取; 2已领取

	--不保存(用来防止重复处理同一订单)
	self.m_tProccessedOrder = {}
end

function CVIP:LoadData(tData)
	if not tData then
		return
	end
	self.m_nTotalMoney = tData.m_nTotalMoney
	self.m_tAwardMap = tData.m_tAwardMap
	self.m_tAwardMap[0] = self.m_tAwardMap[0] or 1 --vip0也有奖励
	self.m_tRechargeMap = tData.m_tRechargeMap
	self.m_tRechargeIDMap = tData.m_tRechargeIDMap
	self.m_nFirstRechargeState = tData.m_nFirstRechargeState or 0
end

function CVIP:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nTotalMoney = self.m_nTotalMoney
	tData.m_tAwardMap = self.m_tAwardMap
	tData.m_tRechargeMap = self.m_tRechargeMap
	tData.m_tRechargeIDMap = self.m_tRechargeIDMap
	tData.m_nFirstRechargeState = self.m_nFirstRechargeState
	return tData
end

function CVIP:GetType()
	return gtModuleDef.tVIP.nID, gtModuleDef.tVIP.sName
end

function CVIP:Online()
	-- self:VIPAwardListReq()
	-- self:SyncFirstRecharge()
end

--取累计充值
function CVIP:GetTotalRecharge()
	return self.m_nTotalMoney
end

--处理订单
function CVIP:ProcessRechargeOrderReq(sOrderID, nRechargeID, nTime)
	assert(sOrderID and nRechargeID, "参数错误")
	if not self.m_tProccessedOrder[sOrderID] then
		self.m_tProccessedOrder[sOrderID] = nRechargeID

		local tConf = assert(ctRechargeConf[nRechargeID])
		local nTotalYuanBao = tConf.nBuyYuanBao + tConf.nGiveYuanBao
		local bFirstRecharge = self:IsFirstRecharge(nRechargeID)
		local bDouble = false
		if tConf.bFirstDouble and bFirstRecharge then --首充翻倍
			nTotalYuanBao = nTotalYuanBao * 2
			bDouble = true
		end

		self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, nTotalYuanBao, "充值获得:"..nRechargeID)

		--记录充值ID充值次数
		self.m_tRechargeIDMap[nRechargeID] = (self.m_tRechargeIDMap[nRechargeID] or 0) + 1

		--充值成功
		self:OnRechargeSuccess(tConf.nID, tConf.nMoney, nTotalYuanBao, nTime)
		self:MarkDirty(true)

		--日志
		goLogger:EventLog(gtEvent.eRecharge, self.m_oPlayer, sOrderID, nRechargeID, tConf.nMoney, nTotalYuanBao, bDouble)
	else
		LuaTrace("订单已处理,说明逻辑服3秒内没处理完成订单或订单号冲突", sOrderID, nRechargeID)
	end
	Srv2Srv.ProccessRechargeOrderRet(gtNetConf:GlobalService(), self.m_oPlayer:GetSession(), sOrderID, nRechargeID)
end

--充值成功
function CVIP:OnRechargeSuccess(nID, nMoney, nYuanBao, nTime)
	self.m_nTotalMoney = math.min(nMAX_INTEGER, math.max(0, self.m_nTotalMoney+nMoney))
    self.m_tRechargeMap[nTime] = {nMoney, nYuanBao}
	self:MarkDirty(true)
	self.m_oPlayer:SaveData()

	--检测VIP
	local nVIP = self.m_oPlayer:GetVIP()
	for k=#ctVIPConf, nVIP+1, -1 do
		local tConf = ctVIPConf[k]
		if self.m_nTotalMoney >= tConf.nMoney then
			self.m_oPlayer:SetVIP(k, "充值")
			break
		end
	end

	--通知充值成功
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "RechargeSuccessRet", {nYuanBao=nYuanBao})
	--刷新充值表
	self:RechargeListReq()
	--首充状态
	self:SyncFirstRecharge()

	--模块关联
	self.m_oPlayer.m_oDayRecharge:OnRechargeSuccess(nMoney)
	self.m_oPlayer.m_oWeekRecharge:OnRechargeSuccess(nMoney)
	self.m_oPlayer.m_oLeiChong:OnRechargeSuccess(nMoney)
	self.m_oPlayer.m_oShenJiZhuFu:OnRechargeSuccess(nID)

	--任务
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond1, 1)

	--更新离线数据
	goOfflineDataMgr:UpdateRecharge(self.m_oPlayer, self.m_nTotalMoney)
end

--VIP特权奖励
function CVIP:OnVIPChange()
	local nVIP = self.m_oPlayer:GetVIP()
	for k=0, nVIP do
		if not self.m_tAwardMap[k] then
			self.m_tAwardMap[k] = 1
			self:MarkDirty(true)
		end
	end
	self:VIPAwardListReq()
	--成就
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond10, nVIP, true)
end

--VIP特权奖励列表请求
function CVIP:VIPAwardListReq()
	local tList = {}
	local nVIP = self.m_oPlayer:GetVIP()
	for k=0, nVIP do
		table.insert(tList, {nVIP=k, nState=self.m_tAwardMap[k] or 0})
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "VIPAwardListRet", {tList=tList})
end

--领取VIP特权奖励
function CVIP:VIPAwardReq(nVIP)
	if not self.m_tAwardMap[nVIP] then
		return self.m_oPlayer:Tips("VIP等级未达成")
	end
	if self.m_tAwardMap[nVIP] == 2 then
		return self.m_oPlayer:Tips("VIP特权已领取")
	end
	assert(self.m_tAwardMap[nVIP] == 1, "状态错误")
	local tConf = ctVIPConf[nVIP]
	for _, tAward in ipairs(tConf.tAward) do
		self.m_oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "VIP特权")
	end
	self.m_tAwardMap[nVIP] = 2
	self:MarkDirty(true)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "VIPAwardRet", {nVIP=nVIP})
	self:VIPAwardListReq()
end

--取日充值额
function CVIP:GetDayRecharge(nTime)
	local tDate = os.date("*t", nTime)
	tDate.hour, tDate.min, tDate.sec = 0, 0, 0
	local nBegTime = os.time(tDate)
	local nEndTime = nBegTime + 24*3600
	local nRecharge = 0
	for k, v in pairs(self.m_tRechargeMap) do
		if k >= nBegTime and k < nEndTime then
			nRecharge = nRecharge + v[1]
		end
	end
	return nRecharge
end

--取周充值次数
function CVIP:GetWeekRechargeTimes(nTime)
	local nWeekDay = os.WDay(nTime) 
	local nDiffTime = (nWeekDay-1) * 24*3600
	local nBegTime = nTime - nDiffTime
	local tDate = os.date("*t", nBegTime)
	tDate.hour, tDate.min, tDate.sec = 0, 0, 0
	nBegTime = os.time(tDate)
	local nEndTime = nBegTime + 7*24*3600-1

	local nRechTims, tDayMap = 0, {}
	for k, v in pairs(self.m_tRechargeMap) do
		if k >= nBegTime and k <= nEndTime then		 
			local nDay = math.floor(k / (24*3600))
			if not tDayMap[nDay] then
				nRechTims = nRechTims + 1
				tDayMap[nDay] = 1
			end
		end
	end
	return nRechTims, nBegTime, nEndTime
end

--是否第一次充值
function CVIP:IsFirstRecharge(nID)
	if not nID then
		return (self.m_nTotalMoney == 0)
	end
	return (not self.m_tRechargeIDMap[nID])
end

--取时间区间充值
function CVIP:GetTimeRecharge(nBegTime, nEndTime)
	local nTimeRecharge = 0
	for k, v in pairs(self.m_tRechargeMap) do
		if k >= nBegTime and k < nEndTime then		 
			nTimeRecharge = nTimeRecharge + v[1]
		end
	end
	return nTimeRecharge
end

--商品列表请求
function CVIP:RechargeListReq()
	local tList = {}
	local tCardList = {}
	for nID, tConf in pairs(ctRechargeConf) do
		local bFirstDouble = tConf.bFirstDouble and self:IsFirstRecharge(nID)
		local tItem = {
			nID = nID,
			sName = tConf.sName,
			nMoney = tConf.nMoney,
			nBuyYuanBao = tConf.nBuyYuanBao,
			nGiveYuanBao = tConf.nGiveYuanBao,
			sProduct = tConf.sProduct,
			sDesc = tConf.sDesc,
			sIcon = tConf.sIcon,
			bFirstDouble = bFirstDouble,
			bCard = tConf.bCard,
		}
		if not tConf.bCard then
			table.insert(tList, tItem)
		else
			table.insert(tCardList, tItem)
		end
	end
	table.sort(tList, function(t1, t2)
		return t1.nMoney > t2.nMoney
	end)
	table.sort(tCardList, function(t1, t2)
		return t1.nID < t2.nID
	end)
	for k = #tCardList, 1, -1 do
		table.insert(tList, 1, tCardList[k])
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "RechargeListRet", {tList=tList, nRecharged=self.m_nTotalMoney})
end

--同步首充状态
function CVIP:SyncFirstRecharge()
	if self.m_nTotalMoney > 0 then
		if self.m_nFirstRechargeState == 0 then
			self.m_nFirstRechargeState = 1
			self:MarkDirty(true)
		end
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "FirstRechargeStateRet", {nState=self.m_nFirstRechargeState})
end

--领取首充奖励
function CVIP:FirstRechargeAwardReq()
	if self.m_nFirstRechargeState == 0 then
		return self.m_oPlayer:Tips("未满足领取条件")
	end
	if self.m_nFirstRechargeState == 2 then
		return self.m_oPlayer:Tips("已经领取过奖励")
	end
	if self.m_nFirstRechargeState ~= 1 then
		return self.m_oPlayer:Tips("状态错误")
	end
	self.m_nFirstRechargeState = 2
	self:MarkDirty(true)

	local tFirstRecargeAward = ctRechargeEtcConf[1].tFirstRecargeAward 
	for _, tItem in ipairs(tFirstRecargeAward) do
		self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "首充奖励")
	end

	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "FirstRechargeAwardRet", {})
	self:SyncFirstRecharge()
end

--增加VIP经验(相当于人民币)
function CVIP:AddVIPExp(nVal)
	self:OnRechargeSuccess(0, nVal, 0)
	return self.m_nTotalMoney
end

--GM模拟充值
function CVIP:GMRecharge(nID)
	local tConf = ctRechargeConf[nID]
	if not tConf then
		return self.m_oPlayer:Tips("充值ID:"..nID.."不存在")
	end
	self:OnProcessRechargeOrderReq("gm_"..os.time(), nID)
	self.m_oPlayer:Tips("模拟充值:"..nID.."成功")
end

