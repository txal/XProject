--月卡
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nMonthCardID = 9 --超值福利月卡
local nWeekCardID = 10 --双周福利

function CMonthCard:Ctor(oRole)
	self.m_oRole = oRole
	self.m_tCardMap = {} 			--月卡/周卡信息{[id]={nExpireTime=0,tAwardMap={}},..}
end

function CMonthCard:LoadData(tData)
	if tData then
		local tCardConf = ctCardConf
		self.m_tCardMap = {}
		for nID, tCard in pairs(tData.m_tCardMap) do
			if tCardConf[nID] then
				tCard.tAwardMap = tCard.tAwardMap or {}
				self.m_tCardMap[nID] = tCard
			end
		end
	end
end

function CMonthCard:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tCardMap = self.m_tCardMap
	return tData
end

function CMonthCard:GetType()
	return gtModuleDef.tMonthCard.nID, gtModuleDef.tMonthCard.sName
end

function CMonthCard:Online()
	self:MonthCardInfoReq()
end

--是否可以购买卡
function CMonthCard:CanBuyCard(nID)
	if nWeekCardID == nID then
		if self.m_tCardMap[nWeekCardID] then
			return false, "已经购买过了"
		end
		return true
	end
	if self.m_tCardMap[nMonthCardID] then
		return false, "已经购买过了"
	end
	local tWeekCard = self.m_tCardMap[nWeekCardID]
	if tWeekCard then
		local nDayNo = os.DayNo(tWeekCard.nExpireTime-1)
		if tWeekCard.tAwardMap[nDayNo] or os.time()>=tWeekCard.nExpireTime then --过期或者已领取
			return true
		end
	end
	local tRechConf = ctRechargeConf[nID]
	return false, string.format("需要先完成%s",tRechConf.sName)
end

--充值成功事件(处理月卡/周卡)
function CMonthCard:OnRechargeSuccess(nID)
	local tRechargeConf = ctRechargeConf[nID]
	if not tRechargeConf or not tRechargeConf.bCard then
		return
	end
	local bCanBuy, sTips = self:CanBuyCard(nID)
	if not bCanBuy then
		local sTmpTips = string.format("购买%s失败-%s", tRechargeConf.sName, sTips)
		LuaTrace(self.m_oRole:GetID(), sTmpTips)
		return self.m_oRole:Tips(sTmpTips)
	end

	local nZeroTime = os.ZeroTime(os.time())
	local tCardConf = ctCardConf
	local tCard = {nExpireTime=nZeroTime+tCardConf[nID].nDay*24*3600, tAwardMap={}}
	self.m_tCardMap[nID] = tCard
	self:MarkDirty(true)

	self:MonthCardInfoReq()
	self:MonthCardCheck(nID)
	self.m_oRole:Tips(string.format("成功购买%s", tRechargeConf.sName))

	--系统频道
	local function _fnCheckSysTalk(nID)
		local tRechConf = ctRechargeConf[nID]
		local tTalkConf = ctTalkConf["buycard"]
		if not (tRechConf and tTalkConf) then
			return
		end
		CUtil:SendSystemTalk("系统", string.format(tTalkConf.sContent, self.m_oRole:GetName(), tRechConf.sName))
	end
	_fnCheckSysTalk(nID)
end

--付费推送模块调用
function CMonthCard:MonthCardCheck(nID)
	if nID == nWeekCardID then
		self.m_oRole.m_oPayPush:BuyEvent(4)
	elseif nID == nMonthCardID then
		self.m_oRole.m_oPayPush:BuyEvent(2)
	end
end

function CMonthCard:GetMonthcard(nID)
	return self.m_tCardMap[nID]
end

--卡券信息请求
function CMonthCard:MonthCardInfoReq()
	local tCardConf = ctCardConf

	local tList = {}
	for nID, tConf in pairs(tCardConf) do
		local nMoney = assert(ctRechargeConf[nID]).nMoney
		local tInfo = {nID=nID, nMoney=nMoney, bCanGetAward=false, nCardRemainTime=0, bBuy=false, bCanBuy=false}

		tInfo.bCanBuy = self:CanBuyCard(nID)
		local tCard = self.m_tCardMap[nID]		
		if tCard then
			local nDayNo = os.DayNo(os.time())
			tInfo.bBuy = true
			tInfo.nCardRemainTime = math.max(0, tCard.nExpireTime-os.time())
			tInfo.bCanGetAward = not tCard.tAwardMap[nDayNo] and tInfo.nCardRemainTime>0
		end
		table.insert(tList, tInfo)
	end

	local tMsg = {tList=tList, sConf=cjson_raw.encode(tCardConf)}
	self.m_oRole:SendMsg("MonthCardInfoRet", tMsg)
end

--领取奖励请求
function CMonthCard:MonthCardAwardReq(nID)
	local tCardConf = ctCardConf
	local tConf = tCardConf[nID]
	if not tConf then
		return self.m_oRole:Tips("卡券不存在")
	end
	local tCard = self.m_tCardMap[nID]
	if not tCard then
		return self.m_oRole:Tips(string.format("请先购买%s", tConf.sName))
	end
	if os.time() >= tCard.nExpireTime then
		return self.m_oRole:Tips(string.format("%s已过期", tConf.sName))
	end
	local nDayNo = os.DayNo(os.time())
	if tCard.tAwardMap[nDayNo] then
		return self.m_oRole:Tips("您今日已领取过奖励，请明日再来")
	end
	tCard.tAwardMap[nDayNo] = 1
	self:MarkDirty(true)
	self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eBYuanBao, tConf.nDayYB, "领取"..tConf.sName)
	self.m_oRole:SendMsg("MonthCardAwardRet", {nYuanBao=tConf.nDayYB})
	self:MonthCardInfoReq()
	self:MonthCardCheck(nID)
end

--是否有月卡/周卡
function CMonthCard:HashCard()
	for nID, tCard in pairs(self.m_tCardMap) do
		if os.time() < tCard.nExpireTime then
			return true
		end
	end
	return false
end

--试用月卡请求
function CMonthCard:TrialMonthCardReq()
	self.m_oRole:Tips("不支持卡券试用")
end

