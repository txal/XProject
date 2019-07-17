--运营活动,累积天数充值
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CDC:Ctor(nID)
	CYYBase.Ctor(self, nID)     	--继承基类
	self.m_nRounds = 1 				--不能放到Init函数里面
	self:Init()
end

function CDC:Init()
	self.m_tRechargeMap = {}		--充值数据
	self.m_tAwardMap = {}			--领取数据
	self.m_tMoneyMap = {} 			--充值数量
	self:MarkDirty(true)
end

function CDC:Save(tData)
	tData = tData or {}
	tData.m_nRounds = self.m_nRounds
	tData.m_tRechargeMap = self.m_tRechargeMap
	tData.m_tAwardMap = self.m_tAwardMap
	tData.m_tMoneyMap = self.m_tMoneyMap
	return tData
end

function CDC:Load(tData)
	tData = tData or {}
	self.m_nRounds =  tData.m_nRounds or self.m_nRounds
	self.m_tRechargeMap = tData.m_tRechargeMap or self.m_tRechargeMap
	self.m_tAwardMap = tData.m_tAwardMap or self.m_tAwardMap
	self.m_tMoneyMap = tData.m_tMoneyMap or self.m_tMoneyMap
end

--存储的key值,年份-天数
function CDC:GetChargeKey()
	local nNowTime = os.time()
	local nDays = os.YDay(nNowTime)
	local tDate = os.date("*t", nNowTime)
	local nYear = tDate.year
	return string.format("%s-%s",nYear,nDays)
end

function CDC:GetRoundConf(nRounds)
	local tRoundConf = {}
	local tDCConf = ctDCConf
	for k=1, #tDCConf do 
		if tDCConf[k].nRounds == nRounds then 
			tRoundConf[tDCConf[k].nID] = tDCConf[k]
		end
	end
	if not next(tRoundConf) then
		assert(false, "累天充活动轮次错误:"..nRounds)
	end
	return tRoundConf
end

function CDC:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)
	nExtID = math.max(1, nExtID or 1)
	self:GetRoundConf(nExtID)
	self.m_nRounds = nExtID
	self:MarkDirty(true)

	CYYBase.OpenAct(self, nStartTime, nEndTime, nAwardTime, nExtID)
end

function CDC:OnRechargeSuccess(oRole, nMoney)
	if not self:IsOpen() then
		return
	end
	local nRoleID = oRole:GetID()
	local sKey = self:GetChargeKey()
	if self:IsDayCharge(nRoleID,sKey) then
		return
	end
	if not self.m_tRechargeMap[nRoleID] then
		self.m_tRechargeMap[nRoleID] = {}
	end
	self.m_tRechargeMap[nRoleID][sKey] = true
	self.m_tMoneyMap[nRoleID] = (self.m_tMoneyMap[nRoleID] or 0) + nMoney
	self:MarkDirty(true)
	self:SyncState(oRole)
end

function CDC:IsDayCharge(nRoleID,sKey)
	local tChargeData = self.m_tRechargeMap[nRoleID] or {}
	if tChargeData[sKey] then
		return true
	end
	return false
end

--累积充值的天数
function CDC:GetChargeDayCnt(nRoleID)
	local tChargeData = self.m_tRechargeMap[nRoleID] or {}
	local nCnt = 0
	for sKey,_ in pairs(tChargeData) do
		nCnt = nCnt + 1
	end
	return nCnt
end

--取奖励状态
function CDC:GetAwardState(oRole, nID)
	local nRoleID = oRole:GetID()
	local tAwardMap = self.m_tAwardMap[nRoleID] or {}
	return (tAwardMap[nID] or 0) 
end

--设置奖励状态
function CDC:SetAwardState(oRole, nID, nState)
	local nRoleID = oRole:GetID()
	self.m_tAwardMap[nRoleID] = self.m_tAwardMap[nRoleID] or {}
	self.m_tAwardMap[nRoleID][nID] = nState
	self:MarkDirty(true)
end

--能否领取奖励
function CDC:CanGetAward(oRole)
	if not self:IsOpen() then
		return false
	end
	local nRoleID = oRole:GetID()
	local nChargeDays = self:GetChargeDayCnt(nRoleID)
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	for nID, tConf in pairs(tRoundConf) do
		local nState = self:GetAwardState(oRole,nID)
		if nState == 0 then
			if nChargeDays >= tConf.nDay then
				return true
			end
		end
	end
	return false
end

--检测奖励
function CDC:CheckAward()
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	for nRoleID, tData in pairs(self.m_tRechargeMap) do
		local nChargeDay = self:GetChargeDayCnt(nRoleID)
		if nChargeDay > 0 then
			for nID, tConf in pairs(tRoundConf) do
				self.m_tAwardMap[nRoleID] = self.m_tAwardMap[nRoleID] or {}
				local tAwardMap = self.m_tAwardMap[nRoleID] 
				if not tAwardMap[nID] then
					if nChargeDay >= tConf.nDay then
						tAwardMap[nID] = 2
						self:MarkDirty(true)

						local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
						local tList = table.DeepCopy(tConf.tAward)
						local sCont = string.format("您在累天充值活动中达到累充%d天，获得了以下奖励，请查收。", tConf.nDay) 
						CUtil:SendMail(oRole:GetServer(), "累天充值活动奖励", sCont, tList, nRoleID)
					end
				end
			end
		end
	end
end

--取信息
function CDC:InfoReq(oRole)
	if not self:IsOpen() then
		return
	end
	local nRoleID = oRole:GetID()
	local nBegTime,nEndTime,nRemainTime = self:GetStateTime()

	local nChargeDays = self:GetChargeDayCnt(nRoleID)
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tMsg = {nID = self.m_nID,nRemainTime=nRemainTime, nBeginTime=nBegTime, nEndTime=nEndTime, tList={}, sConf=cjson_raw.encode(tRoundConf)}	

	for nID, tConf in pairs(tRoundConf) do
		local nState = self:GetAwardState(oRole, nID)
		if nState == 0 then
			nState = nChargeDays >= tConf.nDay and 1 or 0
		end
		local tInfo = {nID=nID, nState=nState}
		table.insert(tMsg.tList, tInfo)
	end
	oRole:SendMsg("ActYYInfoRet", tMsg)
end

function CDC:RefreshInfo(oRole,nID)
	if not self:IsOpen() then
		return
	end
	local nRoleID = oRole:GetID()
	local nBegTime,nEndTime,nRemainTime = self:GetStateTime()

	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tConf = tRoundConf[nID]
	local nChargeDays = self:GetChargeDayCnt(nRoleID)
	local nState = self:GetAwardState(oRole, nID)
	if nState == 0 then
		nState = nChargeDays >= tConf.nDay and 1 or 0
	end
	local tInfo = {nID=nID, nState=nState}
	local tMsg = {nID = self.m_nID,tItem=tInfo}
	oRole:SendMsg("ActYYRewardRet", tMsg)
end

--领取奖励
function CDC:AwardReq(oRole, nID)
	if not self:IsOpen() then
		return oRole:Tips("不是领取奖励时间")
	end
	local nRoleID = oRole:GetID()
	local nState = self:GetAwardState(oRole, nID)
	if nState == 2 then
		return oRole:Tips("该奖励已经领取过了")
	end
	local nChargeDays = self:GetChargeDayCnt(nRoleID)
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tConf = tRoundConf[nID]
	if not tConf then
		return oRole:Tips("参数错误")
	end

	if nChargeDays < tConf.nDay then
		return oRole:Tips("未达到领取条件")
	end
	self:SetAwardState(oRole, nID, 2)

	local tItemList = {}
	for _, tItem in ipairs(tConf.tAward) do 
		table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end
	oRole:AddItem(tItemList, "累积天数充值奖励", function(bRet)
		if bRet then
			self:RefreshInfo(oRole,nID)
			self:SyncState(oRole)

			--日志
			goLogger:ActivityLog(oRole, self:GetID(), self:GetName(), {}, tConf.tAward, nChargeDays, nID, (self.m_tMoneyMap[nRoleID] or 0))
		end
	end)
end