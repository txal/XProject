--运营活动,首充团购(跨服)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CTC:Ctor(nID)
	CYYBase.Ctor(self, nID)     	--继承基类
	self.m_nRounds = 1 				--不能放到Init函数里面
	self:Init()
end

function CTC:Init()
	self.m_tRechargeMap = {}		--充值数据{[nRole]={[nMoney]=1,}}
	self.m_tAwardMap = {}			--领取数据
	self.m_tHDTime = os.time()

	self.m_nAddCount = 0           --添加的数量
	self.m_nAddTimes = 0           --当前已添加次数
	self.m_nLastAddStamp = os.time() --最近一次添加时间戳

	self:MarkDirty(true)
end

function CTC:Save(tData)
	tData = tData or {}
	tData.m_nRounds = self.m_nRounds
	tData.m_tRechargeMap = self.m_tRechargeMap
	tData.m_tAwardMap = self.m_tAwardMap
	tData.m_tHDTime = self.m_tHDTime
	tData.m_nAddCount = self.m_nAddCount
	tData.m_nAddTimes = self.m_nAddTimes
	tData.m_nLastAddStamp = self.m_nLastAddStamp
	return tData
end

function CTC:Load(tData)
	tData = tData or {}
	self.m_nRounds = tData.m_nRounds or self.m_nRounds
	self.m_tRechargeMap = tData.m_tRechargeMap or self.m_tRechargeMap
	self.m_tAwardMap = tData.m_tAwardMap or self.m_tAwardMap
	self.m_tHDTime = tData.m_tHDTime or self.m_tHDTime

	self.m_nAddCount = tData.m_nAddCount or self.m_nAddCount
	self.m_nAddTimes = tData.m_nAddTimes or self.m_nAddTimes
	self.m_nLastAddStamp = tData.m_nLastAddStamp or self.m_nLastAddStamp
end

function CTC:UpdateState()
	self:UpdateRechargeAmount()
	self:CheckTodayData()
	CYYBase.UpdateState(self)
end

--更新重置总人数数据
function CTC:UpdateRechargeAmount()
	if not self:IsOpen() then 
		return 
	end
	local nTimeStamp = os.time()
	--重启或者跨天等
	if not os.IsSameDay(self.m_nLastAddStamp, nTimeStamp, 0) then 
		--Init中会重新初始化相关数据，这里无需处理
		return
	end
	if self.m_nAddTimes >= 6 then --最多添加6次
		return 
	end
	local nIntervalTime = 300
	if self.m_nAddTimes > 0 then --第一次，活动开启后5分钟，后续间隔30分钟
		nIntervalTime = 1800
	end
	if math.abs(nTimeStamp - self.m_nLastAddStamp) < nIntervalTime then 
		return
	end

	local tAddConf = 
	{
		{20, 35, },
		{10, 25, },
		{10, 20, },
		{10, 15, },
		{5, 10, },
		{2, 10, },
	}

	local tConf = tAddConf[self.m_nAddTimes + 1]
	if not tConf or tConf[1] < 0 or tConf[2] < 0 or tConf[1] > tConf[2] then 
		return 
	end
	local nAddNum = math.random(tConf[1], tConf[2])
	LuaTrace(string.format("团购首充, 第(%d)次添加充值人数(%d)", self.m_nAddTimes+1, nAddNum))
	self.m_nAddCount = self.m_nAddCount + nAddNum
	self.m_nAddTimes = self.m_nAddTimes + 1
	self.m_nLastAddStamp = nTimeStamp
	self:MarkDirty(true)
	local oWorldRechargeCB = goHDMgr:GetActivity(gtHDDef.eServerRechargeCB)
	oWorldRechargeCB:OnRobotRecharge(nAddNum)
end

--检查数据，每天清除
function CTC:CheckTodayData()
	if not self.m_tHDTime or self.m_tHDTime<=0 then
		self.m_tHDTime = os.time()
	end
	if os.IsSameDay(self.m_tHDTime,os.time(),0) then
		return
	end
	self.m_tHDTime = os.time()
	self:CheckAward()
	self:Init()
end

function CTC:GetRoundConf(nRounds)
	local tRoundConf = {}
	local tTCConf = goBackstage:GetConf(gnServerID, gtBackstageType.eAllFirstRecharge) --后台配置
	for k=1, #tTCConf do 
		if tTCConf[k].nRounds == nRounds then 
			tRoundConf[tTCConf[k].nID] = tTCConf[k]
		end
	end
	if not next(tRoundConf) then
		assert(false, "首充团购活动轮次错误:"..nRounds)
	end
	return tRoundConf
end

function CTC:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)
	nExtID = math.max(1, nExtID or 1)
	self:GetRoundConf(nExtID)
	self.m_nRounds = nExtID
	self:MarkDirty(true)

	CYYBase.OpenAct(self, nStartTime, nEndTime, nAwardTime, nExtID)
end

function CTC:OnRechargeSuccess(oRole,nMoney)
	if not self:IsOpen() then
		return
	end
	local nRoleID = oRole:GetID()
 
	self.m_tRechargeMap[nRoleID] = (self.m_tRechargeMap[nRoleID] or 0) + nMoney
	
	self:MarkDirty(true)
	self:SyncState(oRole)
end

--获取充值人数
function CTC:GetChargeAmount()
	local nCnt = table.Count(self.m_tRechargeMap)
	return nCnt + self.m_nAddCount
end

function CTC:IsChargeMoney(nRoleID,nMoney)
	local nChargeMoney = self.m_tRechargeMap[nRoleID] or 0
	if nChargeMoney >= nMoney then
		return true
	end
	return false
end

function CTC:GetChargeMoney(nRoleID)
	local nChargeMoney = self.m_tRechargeMap[nRoleID] or 0
	return nChargeMoney
end

--取奖励状态
function CTC:GetAwardState(oRole, nID)
	local nRoleID = oRole:GetID()
	local tAwardMap = self.m_tAwardMap[nRoleID] or {}
	return (tAwardMap[nID] or 0)
end

--设置奖励状态
function CTC:SetAwardState(oRole, nID, nState)
	local nRoleID = oRole:GetID()
	self.m_tAwardMap[nRoleID] = self.m_tAwardMap[nRoleID] or {}
	self.m_tAwardMap[nRoleID][nID] = nState
	self:MarkDirty(true)
end

--能否领取奖励
function CTC:CanGetAward(oRole)
	if not self:IsOpen() then
		return false
	end
	local nRoleID = oRole:GetID()
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local nChargeCnt = self:GetChargeAmount()
	for nID, tConf in pairs(tRoundConf) do
		local nState = self:GetAwardState(oRole,nID)
		local nCnt = tConf.nCnt
		local nMoney = tConf.nMoney
		if nState == 0 then
			if nChargeCnt >= nCnt and self:IsChargeMoney(nRoleID,nMoney) then
				return true
			end
		end
	end
	return false
end

--检测奖励
function CTC:CheckAward()
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local nCnt = self:GetChargeAmount()
	for nRoleID,nChargeMoney in pairs(self.m_tRechargeMap) do
		for nID,tConf in pairs(tRoundConf) do
			local nNeedCnt = tConf.nCnt
			local nMoney = tConf.nMoney
			if nCnt >= nNeedCnt and nChargeMoney>=nMoney then
				local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
				if oRole then
					local nState = self:GetAwardState(oRole, nID)
					if nState == 0 then
						self:MarkDirty(true)
						self:SetAwardState(oRole, nID, 2)
						local tList = table.DeepCopy(tConf.tAward)
						local sCont = string.format("您在充值团购充值活动中达到充值%d人民币，获得了以下奖励，请查收。", tConf.nMoney) 
						GF.SendMail(oRole:GetServer(), "充值团购活动奖励", sCont, tList, nRoleID)
					end
				end 
			end
		end
	end
end

--取信息
function CTC:InfoReq(oRole, nTarget)
	local nRoleID = oRole:GetID()
	local nBegTime,nEndTime,nRemainTime = self:GetStateTime()
	--local nBegTime, nEndTime = self:GetActTime()

	local nChargeCnt = self:GetChargeAmount()
	local nChargeMoney = self:GetChargeMoney(nRoleID)
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tMsg = {nID = self.m_nID,nRemainTime=nRemainTime, nBeginTime=nBegTime, nEndTime=nEndTime, tList={}, sConf=cjson_raw.encode(tRoundConf),nTotalRechargeCnt = nChargeCnt}	
	
	for nID, tConf in pairs(tRoundConf) do
		local nState = self:GetAwardState(oRole, nID)
		local nMoney = tConf.nMoney
		local nCnt = tConf.nCnt
		if nState == 0 then
			if nChargeCnt>=nCnt and nChargeMoney >=nMoney then
				nState = 1
			end
		end
		local tInfo = {nID=nID, nState=nState}
		if not nTarget or nTarget == 0 then
			table.insert(tMsg.tList, tInfo)
		else
			if nCnt == nTarget then
				table.insert(tMsg.tList, tInfo)
			end
		end
	end
	oRole:SendMsg("ActYYInfoRet", tMsg)
end

function CTC:RefreshInfo(oRole,nID)
	if not self:IsOpen() then
		return
	end
	local nRoleID = oRole:GetID()

	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tConf = tRoundConf[nID]
	local nState = self:GetAwardState(oRole, nID)
	local nCnt = tConf.nCnt
	local nChargeCnt = self:GetChargeAmount()
	local nChargeMoney = self:GetChargeMoney()
	if nState == 0 then
		if nChargeCnt >= nCnt and nChargeMoney >= tConf.nMoney then
			nState = 1
		end
	end
	local tInfo = {nID=nID, nState=nState}
	local tMsg = {nID = self.m_nID,tItem=tInfo}
	oRole:SendMsg("ActYYRewardRet", tMsg)
end

--领取奖励
function CTC:AwardReq(oRole, nID)
	if not self:IsOpen() then
		return oRole:Tips("不是领取奖励时间")
	end
	local nRoleID = oRole:GetID()
	local nState = self:GetAwardState(oRole, nID)
	if nState == 2 then
		return oRole:Tips("该奖励已经领取过了")
	end
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tConf = tRoundConf[nID]
	if not tConf then
		return oRole:Tips("配置错误")
	end
	local nChargeCnt = self:GetChargeAmount()
	if nChargeCnt < tConf.nCnt then
		return oRole:Tips("未达到领取条件")
	end
	local nMoney = tConf.nMoney
	if not self:IsChargeMoney(nRoleID,nMoney) then
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
			goLogger:ActivityLog(oRole, self:GetID(), self:GetName(), {}, tConf.tAward, nChargeCnt, nID)
		end
	end)
end