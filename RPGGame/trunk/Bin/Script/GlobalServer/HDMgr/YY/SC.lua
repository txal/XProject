--运营活动,单笔充值
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CSC:Ctor(nID)
	CYYBase.Ctor(self, nID)     	--继承基类
	self.m_nRounds = 1 				--不能放到Init函数里面
	self:Init()
end

function CSC:Init()
	self.m_tRechargeMap = {}		--充值数据
	self.m_tRewardMap = {}			--领取数据
	self.m_tMoneyMap = {} 			--充值数量
	self:MarkDirty(true)
end

function CSC:Save(tData)
	tData = tData or {}
	tData.m_nRounds = self.m_nRounds		
	tData.m_tRechargeMap = self.m_tRechargeMap
	tData.m_tRewardMap = self.m_tRewardMap
	tData.m_tMoneyMap = self.m_tMoneyMap
	return tData
end

function CSC:Load(tData)
	self.m_nRounds = tData.m_nRounds or self.m_nRounds
	self.m_tRechargeMap = tData.m_tRechargeMap or self.m_tRechargeMap
	self.m_tRewardMap = tData.m_tRewardMap or self.m_tRewardMap
	self.m_tMoneyMap = tData.m_tMoneyMap or self.m_tMoneyMap
end

function CSC:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)
	nExtID = math.max(1, nExtID or 1)
	self:GetRoundConf(nExtID)
	self.m_nRounds = nExtID
	self:MarkDirty(true)

	CYYBase.OpenAct(self, nStartTime, nEndTime, nAwardTime, nExtID)
end

function CSC:OnRechargeSuccess(oRole, nMoney)
	if not self:IsOpen() then
		return
	end
	local nRewardID = self:GetRewardIDByMoney(oRole, nMoney)
	if not nRewardID then
		return
	end
	local nRoleID = oRole:GetID()
	self.m_tRechargeMap[nRoleID] = self.m_tRechargeMap[nRoleID] or {}
	self.m_tRechargeMap[nRoleID][nRewardID] = (self.m_tRechargeMap[nRoleID][nRewardID] or 0) + 1
	self.m_tMoneyMap[nRoleID] = (self.m_tMoneyMap[nRoleID] or 0) + nMoney
	self:MarkDirty(true)
	self:SyncState(oRole)
end

function CSC:GetRechargeCnt(nRoleID,nID)
	local tChargeData = self.m_tRechargeMap[nRoleID] or {}
	local nChargeCnt = tChargeData[nID] or 0
	return nChargeCnt
end

function CSC:GetRewardCnt(nRoleID,nID)
	local tRewardData = self.m_tRewardMap[nRoleID] or {}
	local nRewardCnt = tRewardData[nID] or 0
	return nRewardCnt
end

function CSC:GetRoundConf(nRounds)
	local tRoundConf = {}
	local tSCConf = goBackstage:GetConf(gnServerID, gtBackstageType.eSingleRecharge) --后台配置
	for k=1, #tSCConf do 
		if tSCConf[k].nRounds == nRounds then 
			tRoundConf[tSCConf[k].nID] = tSCConf[k]
		end
	end
	if not next(tRoundConf) then
		LuaTrace("单充活动轮次错误:"..nRounds)
		LuaTrace(debug.traceback())
	end
	return tRoundConf
end

function CSC:LimitCnt(nID)
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tConf = tRoundConf[nID]
	assert(tConf, string.format("单次充值ID配置错误,ID:%s",nID))
	return tConf.nLimitCnt
end

function CSC:IsAddChargeCnt(nID)
	local tRechargeMap = self.m_tRechargeMap[nRoleID]
	if not tRechargeMap then return false end
	local nChargeCnt = self.m_tRechargeMap[nRoleID][nID] or 0
	if nChargeCnt >= self:LimitCnt(nID) then return false end
	return true
end

function CSC:GetRewardIDByMoney(oRole, nMoney)
	local tRoundConf = self:GetRoundConf(self.m_nRounds)

	local nRewardID
	local nMaxMoney = 0
	for nID, tConf in pairs(tRoundConf) do
		if tConf.nMoney <= nMoney then
			if tConf.nMoney >= nMaxMoney then
				nMaxMoney = tConf.nMoney
				nRewardID = tConf.nID
			end
		end
	end
	return nRewardID
end

--取奖励状态
function CSC:GetAwardState(oRole, nID)
	local nRoleID = oRole:GetID()
	local nChargeCnt = self:GetRechargeCnt(nRoleID,nID)
	local nRewardCnt = self:GetRewardCnt(nRoleID,nID) 
	local nLimitCnt = self:LimitCnt(nID)
	if nRewardCnt >= nLimitCnt then
		return false
	end
	if nRewardCnt >= nChargeCnt then
		return false
	end
	if nChargeCnt <= 0 then
		return false
	end
	return true
end

--设置奖励状态,加奖励次数
function CSC:SetAwardState(oRole, nID)
	local nRoleID = oRole:GetID()
	if not self.m_tRewardMap[nRoleID] then
		self.m_tRewardMap[nRoleID] = {}
	end
	if not self.m_tRewardMap[nRoleID][nID] then
		self.m_tRewardMap[nRoleID][nID] = 0
	end
	self.m_tRewardMap[nRoleID][nID] = self.m_tRewardMap[nRoleID][nID] + 1
	self:MarkDirty(true)
end

--能否领取奖励
function CSC:CanGetAward(oRole)
	if not self:IsOpen() then
		return false
	end
	local nRoleID = oRole:GetID()
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	for nID, tConf in pairs(tRoundConf) do
		if self:GetAwardState(oRole, nID) then
			return true
		end
	end
	return false
end

--检测奖励
function CSC:CheckAward()
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	for nRoleID, tRechargeData in pairs(self.m_tRechargeMap) do
		for nID, tConf in pairs(tRoundConf) do
			local nChargeCnt = self:GetRechargeCnt(nRoleID,nID)
			local nRewardCnt = self:GetRewardCnt(nRoleID,nID)
			local nLimitCnt = self:LimitCnt(nID)
			local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
			nChargeCnt = math.min(nChargeCnt, nLimitCnt)
			if nRewardCnt < nChargeCnt then
				self:MarkDirty(true)
				for i = nRewardCnt+1, nChargeCnt do
					if self:GetAwardState(oRole,nID) then
						self:SetAwardState(oRole, nID)
						local tList = table.DeepCopy(tConf.tAward)
						local sCont = string.format("您在单笔充值活动中达到累计充值了%d人民币，获得了以下奖励，请查收。", tConf.nMoney) 
						GF.SendMail(oRole:GetServer(), "单笔充值活动奖励", sCont, tList, nRoleID)
					end
				end
			end
		end
	end
end

--取信息
function CSC:InfoReq(oRole)
	if not self:IsOpen() and not self:IsAward() then
		return
	end
	local nRoleID = oRole:GetID()
	local nBegTime,nEndTime,nRemainTime = self:GetStateTime()

	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tMsg = {nID = self.m_nID,nRemainTime=nRemainTime, nBeginTime=nBegTime, nEndTime=nEndTime, tList={}, sConf=cjson_raw.encode(tRoundConf)}	
	for nID, tConf in pairs(tRoundConf) do
		local nState = 0
		if self:GetAwardState(oRole,nID) then
			nState = 1
		end
		local nRewardCnt = self:GetRewardCnt(nRoleID,nID)
		local tInfo = {nID=nID, nState=nState,nRewardCnt=nRewardCnt}
		table.insert(tMsg.tList, tInfo)
	end
	oRole:SendMsg("ActSCInfoRet", tMsg)
end

function CSC:RefreshInfo(oRole,nID)
	if not self:IsOpen() then
		return
	end
	local nRoleID = oRole:GetID()
	local nBegTime,nEndTime,nRemainTime = self:GetStateTime()

	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tConf = tRoundConf[nID]
	local nState = 0
	if self:GetAwardState(oRole,nID) then
		nState = 1
	end
	local nRewardCnt = self:GetRewardCnt(nRoleID, nID)
	local tInfo = {nID=nID, nState=nState,nRewardCnt=nRewardCnt}
	local tMsg = {nID = self.m_nID,tItem=tInfo}
	oRole:SendMsg("ActYYRewardRet", tMsg)
end

--领取奖励
function CSC:AwardReq(oRole, nID)
	if not self:IsOpen() and not self:IsAward() then
		return oRole:Tips("活动已结束")
	end
	local nRoleID = oRole:GetID()
	if not self:GetAwardState(oRole,nID) then
		return oRole:Tips("该奖励已经不能领取了")
	end
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tConf = tRoundConf[nID]
	self:SetAwardState(oRole, nID)

	local tItemList = {}
	for _, tItem in ipairs(tConf.tAward) do 
		table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end
	oRole:AddItem(tItemList, "单笔充值奖励", function(bRet)
		if bRet then
			self:RefreshInfo(oRole,nID)
			self:SyncState(oRole)

			--日志
			local nValue = self.m_tRechargeMap[nRoleID][nID] or 0
			goLogger:ActivityLog(oRole, self:GetID(), self:GetName(), {}, tConf.tAward, nValue, nID, (self.m_tMoneyMap[nRoleID] or 0))
		end
	end)
end