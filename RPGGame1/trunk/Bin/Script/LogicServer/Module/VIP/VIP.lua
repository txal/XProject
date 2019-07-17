	--VIP系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CVIP:Ctor(oRole)
	self.m_oRole = oRole
	self.m_nTotalMoney = 0 			--累计充值RMB
	self.m_tRechargeMap = {} 		--充值记录:{[nTime]={nMoney,nYuanBao}, ...}
	self.m_tRechargeIDMap = {} 		--充值ID记录:{[id]=count}, ...}
	self.m_nFirstRechargeState = 0 	--首充状态:0未满足; 1未领取; 2已领取
	self.m_tAwardMap = {[0]=1} 		--特权礼包:{[nVIP]=nState, ...} nState:0未达成; 1已达成未领取; 2已领取
	self.m_nTotalPureYuanBao = 0 	--累计充值元宝数(不包括赠送)
	self.m_tRechargeRebateAward = {}	--充值返利信息{[nID] = {nState = 1}}

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
	self.m_nTotalPureYuanBao = tData.m_nTotalPureYuanBao or 0
	self.m_tRechargeRebateAward =  tData.m_tRechargeRebateAward or {}
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
	tData.m_nTotalPureYuanBao = self.m_nTotalPureYuanBao
	tData.m_tRechargeRebateAward = self.m_tRechargeRebateAward
	return tData
end

function CVIP:GetType()
	return gtModuleDef.tVIP.nID, gtModuleDef.tVIP.sName
end

function CVIP:AfterOnline()
	self:VIPAwardListReq()
	self:SyncFirstRecharge()
	self:GetTotalPureYuanBaoReq()
end

--取累计充值
function CVIP:GetTotalRecharge()
	return self.m_nTotalMoney
end

--取累计充值元宝数(非绑定)
function CVIP:GetTotalYuanBao()
	return self.m_nTotalPureYuanBao
end

--处理订单
function CVIP:ProcessRechargeOrderReq(sOrderID, nRechargeID, nTime)
	assert(sOrderID and nRechargeID, "参数错误")
	if not self.m_tProccessedOrder[sOrderID] then
		self.m_tProccessedOrder[sOrderID] = nRechargeID
		local tConf = assert(ctRechargeConf[nRechargeID])
		local nBuyYuanBao = tConf.nBuyYuanBao
		if tConf.nType == gtRechargeType.eEverydayGift then
			nBuyYuanBao = 0
		end
		local nBYuanBao = tConf.nGiveYuanBao
		local bDouble = self:FirstRechargeDouble(nRechargeID)
		if bDouble then
			nBYuanBao = nBuyYuanBao*2 --首次翻倍的档次,不赠送额外赠送的绑定元宝(tConf.nGiveYuanBao)
		end
		--记录充值ID充值次数和充值元宝数
		self.m_tRechargeIDMap[nRechargeID] = (self.m_tRechargeIDMap[nRechargeID] or 0) + 1
		self.m_nTotalPureYuanBao = math.floor(self.m_nTotalPureYuanBao + nBuyYuanBao)
		self:MarkDirty(true)

		self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, nBuyYuanBao, "充值获得")
		self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eBYuanBao, nBYuanBao, "充值获得")
		self:GetTotalPureYuanBaoReq()
		--充值成功
		self:OnRechargeSuccess(nRechargeID, tConf.nMoney, nBuyYuanBao, nBYuanBao, nTime)
		--日志
		goLogger:EventLog(gtEvent.eRecharge, self.m_oRole, sOrderID, nRechargeID, tConf.nMoney, nBuyYuanBao, nBYuanBao, bDouble)
	else
		LuaTrace("订单已处理,说明逻辑服3秒内没处理完成订单或订单号冲突", sOrderID, nRechargeID)

	end

	return sOrderID, nRechargeID
end

--检测VIP升级
function CVIP:CheckVIPUpgrade()
	local nVIP = self.m_oRole:GetVIP()
	for k=#ctVIPConf, nVIP+1, -1 do
		local tConf = ctVIPConf[k]
		if self.m_nTotalMoney >= tConf.nMoney then
			self.m_oRole:SetVIP(k, "充值")
			break
		end
	end
end

--充值成功
function CVIP:OnRechargeSuccess(nID, nMoney, nYuanBao, nBYuanBao, nTime)
	self.m_nTotalMoney = math.min(gtGDef.tConst.nMaxInteger, math.max(0, self.m_nTotalMoney+nMoney))
    self.m_tRechargeMap[nTime] = {nMoney, nYuanBao, nBYuanBao}
	self:MarkDirty(true)
	self.m_oRole:SaveData()
	
	local tConf = assert(ctRechargeConf[nID])
	--通知充值成功
	self.m_oRole:SendMsg("RechargeSuccessRet", {nYuanBao=nYuanBao, nBYuanBao=nBYuanBao})

	if tConf.nType == gtRechargeType.eCommon then		--普通充值
		--检测VIP
		self:CheckVIPUpgrade()
		--刷新充值表
		self:RechargeListReq()
		--首充状态
		self:SyncFirstRecharge()
		--检测充值返利
		self:RechargeRebateAwardCheck()

		--模块关联
		self.m_oRole.m_oMonthCard:OnRechargeSuccess(nID)
		self.m_oRole.m_oFund:OnRechargeSuccess(nID)
		self.m_oRole.m_oPayPush:BuyEvent(1)

		local tGlobalServiceList = goServerMgr:GetGlobalServiceList(self.m_oRole:GetServer())
		for _, tService in ipairs(tGlobalServiceList) do 
			Network.oRemoteCall:Call("OnRoleRechargeSuccess", tService.nServer, tService.nID, 0, self.m_oRole:GetID(), nID, nMoney, nYuanBao, nBYuanBao, nTime)
		end

	elseif tConf.nType == gtRechargeType.eEverydayGift then		--每日礼包充值
		self.m_oRole.m_oEverydayGift:OnRechargeSuccess(tConf.nMoney)

	end
end

--VIP特权奖励
function CVIP:OnVIPChange()
	local nVIP = self.m_oRole:GetVIP()
	for k=0, nVIP do
		if not self.m_tAwardMap[k] then
			self.m_tAwardMap[k] = 1
			self:MarkDirty(true)
		end
	end
	self:VIPAwardListReq()
end

--VIP特权奖励列表请求
function CVIP:VIPAwardListReq()
	local tList = {}
	local nVIP = self.m_oRole:GetVIP()
	for k=0, nVIP do
		table.insert(tList, {nVIP=k, nState=self.m_tAwardMap[k] or 0})
	end
	self.m_oRole:SendMsg("VIPAwardListRet", {tList=tList})
end

--领取VIP特权奖励
function CVIP:VIPAwardReq(nVIP)
	if not self.m_tAwardMap[nVIP] then
		return self.m_oRole:Tips("VIP等级未达成")
	end
	if self.m_tAwardMap[nVIP] == 2 then
		return self.m_oRole:Tips("VIP特权已领取")
	end
	assert(self.m_tAwardMap[nVIP] == 1, "状态错误")
	local tConf = ctVIPConf[nVIP]
	for _, tAward in ipairs(tConf.tAward) do
		self.m_oRole:AddItem(tAward[1], tAward[2], tAward[3], "VIP特权", false, tAward[4])
	end
	self.m_tAwardMap[nVIP] = 2
	self:MarkDirty(true)

	self.m_oRole:SendMsg("VIPAwardRet", {nVIP=nVIP})
	self:VIPAwardListReq()
end

--取日充值额
function CVIP:GetDayRecharge(nTime)
	local nBegTime = os.ZeroTime(nTime)
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

	local nBegTime = os.ZeroTime(nTime-nDiffTime)
	local nEndTime = nBegTime + 7*24*3600-1

	local nRechargeTimes, tDayMap = 0, {}
	for k, v in pairs(self.m_tRechargeMap) do
		if k >= nBegTime and k <= nEndTime then		 
			local nDay = os.YDay(k)
			if not tDayMap[nDay] then
				tDayMap[nDay] = 1
				nRechargeTimes = nRechargeTimes + 1
			end
		end
	end
	return nRechargeTimes, nBegTime, nEndTime
end

--是否首充翻倍
function CVIP:FirstRechargeDouble(nID)
	local tConf = ctRechargeConf[nID]
	if not tConf.bFirstDouble then
		return false
	end
	--永久开启
	-- if not self.m_oRole.m_oSysOpen:IsSysOpen(80) then
	-- 	return false
	-- end
	if (self.m_tRechargeIDMap[nID] or 0) > 0 then
		return false
	end
	return true
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
		local bCanBuy = true
		if tConf.bFund then
			bCanBuy = self.m_oRole.m_oFund:CanBuyFund(nID)
		end
		if bCanBuy then
			local tItem = {
				nID = nID,
				sName = tConf.sName,
				nMoney = tConf.nMoney,
				nBuyYuanBao = tConf.nBuyYuanBao,
				nGiveYuanBao = tConf.nGiveYuanBao,
				sDesc = tConf.sDesc,
				sIcon = tConf.sIcon,
				bCard = tConf.bCard,
				sProduct = tConf.sProduct,
				bFirstDouble = self:FirstRechargeDouble(nID),
			}
			if not tConf.bCard and not tConf.bFund then
				table.insert(tList, tItem)
			else
				table.insert(tCardList, tItem)
			end
		end
	end
	
	table.sort(tList, function(t1, t2) return t1.nMoney > t2.nMoney end)
	table.sort(tCardList, function(t1, t2) return t1.nID < t2.nID end)
	for k = #tCardList, 1, -1 do
		table.insert(tList, 1, tCardList[k])
	end
	self.m_oRole:SendMsg("RechargeListRet", {tList=tList, nRecharged=self.m_nTotalMoney})
end

--同步首充状态
function CVIP:SyncFirstRecharge()
	if self.m_nTotalMoney > 0 then
		if self.m_nFirstRechargeState == 0 then
			self.m_nFirstRechargeState = 1
			self:MarkDirty(true)
		end
	end
	local tConf = ctRechargeEtcConf
	self.m_oRole:SendMsg("FirstRechargeStateRet", {nState=self.m_nFirstRechargeState, sConf=cjson_raw.encode(tConf)})
end

--领取首充奖励
function CVIP:FirstRechargeAwardReq()
	if self.m_nFirstRechargeState == 0 then
		return self.m_oRole:Tips("未满足领取条件")
	end
	if self.m_nFirstRechargeState == 2 then
		return self.m_oRole:Tips("已经领取过奖励")
	end
	if self.m_nFirstRechargeState ~= 1 then
		return self.m_oRole:Tips("状态错误")
	end
	self.m_nFirstRechargeState = 2
	self:MarkDirty(true)

	--系统频道
	local function _fnCheckSysTalk(tItem)
		if tItem[2] == gtItemType.ePet then
			local tPetConf = ctPetInfoConf[tItem[3]]
			local tTalkConf = ctTalkConf["firstrechargepet"]
			if tPetConf and tTalkConf then
				CUtil:SendSystemTalk("系统", string.format(tTalkConf.sContent, self.m_oRole:GetName(), tPetConf.sName, tPetConf.sName))
			end
		end
	end

	local tConf = ctRechargeEtcConf
	local tFirstRecargeAward = tConf[1].tFirstRecargeAward 
	for _, tItem in ipairs(tFirstRecargeAward) do
		if tItem[1] == 0 or tItem[1] == self.m_oRole:GetConfID() then 
			local tPropExt = nil
			if tItem[5] and tItem[5] > 0 then 
				tPropExt = {nQuality = tItem[5]}
			end
			self.m_oRole:AddItem(tItem[2], tItem[3], tItem[4], "首充奖励", nil, nil, tPropExt)
			_fnCheckSysTalk(tItem)
		end
	end

	self.m_oRole:SendMsg("FirstRechargeAwardRet", {})
	self:SyncFirstRecharge()

	--关闭图标
	self.m_oRole.m_oSysOpen:CloseSystem(65)
	--开启特惠
	self.m_oRole.m_oSysOpen:OpenSystem(76)
end

--充值返利奖励检查
function CVIP:RechargeRebateAwardCheck()
	for nID, tItem in pairs(ctRecargeAwardConf) do
		if self.m_nTotalPureYuanBao >= tItem.nRecargeYunBao and not self.m_tRechargeRebateAward[nID] then
			self.m_tRechargeRebateAward[nID] = {nID, nState = 1}
			self:MarkDirty(true)
		end
	end
	--self:RechargeRebateAwardInfoReq()
end

--充值返利列表请求
function CVIP:RechargeRebateAwardInfoReq()
	local tMsg = {}
	tMsg.nTotalPureYuanBao = self.m_nTotalPureYuanBao
	tMsg.tItemList = {}

	for nID, tItem in pairs(self.m_tRechargeRebateAward) do 
		tMsg.tItemList[#tMsg.tItemList+1] = {nID = nID, nState = tItem.nState}
	end
	print("返利消息返回", tMsg)
	self.m_oRole:SendMsg("RechargeRebateAwardInfoRet", tMsg)
end

function CVIP:GetTotalPureYuanBaoReq()
	local tMsg = {}
	tMsg.nTotalPureYuanBao = self.m_nTotalPureYuanBao
	self.m_oRole:SendMsg("RechargeGetTotalPureYuanBaoRet", tMsg)
end

--领取充值返利道具
function CVIP:RechargeRebateAwardReq(nID)
	local tItem = ctRecargeAwardConf[nID]
	if not tItem or (not self.m_tRechargeRebateAward[nID]) then
		return 
	end
	if self.m_tRechargeRebateAward[nID].nState == 2 then
		return self.m_oRole:Tips("该奖励已经领取")
	end

	for _, tConf in pairs(tItem.tAwardProp) do
		if tConf[1] > 0 and ctPropConf[tConf[2]] and tConf[3] > 0 then
			self.m_oRole:AddItem(tConf[1], tConf[2],tConf[3], "充值返利获得")
		end
	end
	self.m_tRechargeRebateAward[nID].nState = 2
	self.m_oRole:SendMsg("RechargeRebateAwardRet", {nID = nID, nState = 2})
	self:MarkDirty(true)
end

--增加VIP经验(相当于人民币)
function CVIP:AddVIPExp(nVal)
	self.m_nTotalMoney = math.min(gtGDef.tConst.nMaxInteger, math.max(0, self.m_nTotalMoney+nVal))
	self:MarkDirty(true)
	self:CheckVIPUpgrade()
	return self.m_nTotalMoney
end

--GM模拟充值
function CVIP:GMRecharge(nID)
	local tConf = ctRechargeConf[nID]
	if not tConf then
		return self.m_oRole:Tips("充值ID:"..nID.."不存在")
	end
	self:ProcessRechargeOrderReq("gm_"..os.time(), nID, os.time())
	self.m_oRole:Tips("模拟充值:"..nID.."成功")
end
