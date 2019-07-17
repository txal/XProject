--运营活动,累积消耗元宝
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLY:Ctor(nID)
	CYYBase.Ctor(self, nID)     	--继承基类
	self.m_nRounds = 1 				--不能放到Init函数里面
	self:Init()
end

function CLY:Init()
	self.m_tResumeYBMap = {}		--消耗数据数据
	self.m_tAwardMap = {}			--领取数据
	self:MarkDirty(true)
end

function CLY:Save(tData)
	tData = tData or {}
	tData.m_nRounds = self.m_nRounds
	tData.m_tResumeYBMap = self.m_tResumeYBMap
	tData.m_tAwardMap = self.m_tAwardMap
	tData.m_tMoneyMap = self.m_tMoneyMap
	return tData
end

function CLY:Load(tData)
	tData = tData or {}
	self.m_nRounds = tData.m_nRounds or self.m_nRounds
	self.m_tResumeYBMap = tData.m_tResumeYBMap or self.m_tResumeYBMap
	self.m_tAwardMap = tData.m_tAwardMap or self.m_tAwardMap
	self.m_tMoneyMap = tData.m_tMoneyMap or self.m_tMoneyMap
end

function CLY:GetRoundConf(nRounds)
	local tRoundConf = {}
	local tLYConf = ctLYConf
	for k=1, #tLYConf do 
		if tLYConf[k].nRounds == nRounds then 
			tRoundConf[tLYConf[k].nID] = tLYConf[k]
		end
	end
	if not next(tRoundConf) then
		LuaTrace(string.format("%s活动轮次错误:%d", self:GetName(), nRounds), debug.traceback())
	end
	return tRoundConf
end

function CLY:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)
	nExtID = math.max(1, nExtID or 1)
	self:GetRoundConf(nExtID)
	self.m_nRounds = nExtID
	self:MarkDirty(true)

	CYYBase.OpenAct(self, nStartTime, nEndTime, nAwardTime, nExtID)
end

function CLY:OnYYResumeYuanBao(oRole,nVal)
	if not self:IsOpen() then
		return
	end
	local nRoleID = oRole:GetID()
	self.m_tResumeYBMap[nRoleID] = (self.m_tResumeYBMap[nRoleID] or 0) + nVal
	self:MarkDirty(true)
	self:SyncState(oRole)
end

--取奖励状态
function CLY:GetAwardState(oRole, nID)
	local nRoleID = oRole:GetID()
	local tAwardMap = self.m_tAwardMap[nRoleID] or {}
	return (tAwardMap[nID] or 0) 
end

--设置奖励状态
function CLY:SetAwardState(oRole, nID, nState)
	local nRoleID = oRole:GetID()
	self.m_tAwardMap[nRoleID] = self.m_tAwardMap[nRoleID] or {}
	self.m_tAwardMap[nRoleID][nID] = nState
	self:MarkDirty(true)
end

--取消耗元宝数目
function CLY:GetTotalResumeYB(oRole)
	local nRoleID = oRole:GetID()
	return (self.m_tResumeYBMap[nRoleID] or 0)
end

--能否领取奖励
function CLY:CanGetAward(oRole)
	if not self:IsOpen() then
		return false
	end
	local nRoleID = oRole:GetID()
	local nTotalResumeYB = self:GetTotalResumeYB(oRole)
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	for nID, tConf in pairs(tRoundConf) do
		local nState = self:GetAwardState(oRole,nID)
		if nState == 0 then
			if nTotalResumeYB >= tConf.nYuanBao then
				return true
			end
		end
	end
	return false
end

--检测奖励
function CLY:CheckAward()
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	for nRoleID, nYuanBao in pairs(self.m_tResumeYBMap) do
		if nYuanBao > 0 then
			for nID, tConf in pairs(tRoundConf) do
				self.m_tAwardMap[nRoleID] = self.m_tAwardMap[nRoleID] or {}
				local tAwardMap = self.m_tAwardMap[nRoleID] 
				if not tAwardMap[nID] then
					if nYuanBao >= tConf.nYuanBao then
						tAwardMap[nID] = 2
						self:MarkDirty(true)

						local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
						local tList = table.DeepCopy(tConf.tAward)
						local sCont = string.format("您在累计消耗元宝活动中达到累计消耗了%d元宝，获得了以下奖励，请查收。", tConf.nYuanBao) 
						CUtil:SendMail(oRole:GetServer(), "累计消耗元宝活动奖励", sCont, tList, nRoleID)
					end
				end
			end
		end
	end
end

--取信息
function CLY:InfoReq(oRole)
	if not self:IsOpen() then
		return
	end
	local nRoleID = oRole:GetID()
	local nBegTime,nEndTime,nRemainTime = self:GetStateTime()

	local nTotalResumeYB = self:GetTotalResumeYB(oRole)
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tMsg = {nID = self.m_nID,nRemainTime=nRemainTime, nBeginTime=nBegTime, nEndTime=nEndTime, tList={}, sConf=cjson_raw.encode(tRoundConf),nTotalRechargeCnt=nTotalResumeYB}	

	for nID, tConf in pairs(tRoundConf) do
		local nState = self:GetAwardState(oRole, nID)
		if nState == 0 then
			nState = nTotalResumeYB >= tConf.nYuanBao and 1 or 0
		end
		local tInfo = {nID=nID, nState=nState}
		table.insert(tMsg.tList, tInfo)
	end
	oRole:SendMsg("ActYYInfoRet", tMsg)
end

function CLY:RefreshInfo(oRole,nID)
	if not self:IsOpen() then
		return
	end
	local nRoleID = oRole:GetID()
	local nBegTime,nEndTime,nRemainTime = self:GetStateTime()

	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tConf = tRoundConf[nID]
	local nTotalResumeYB = self:GetTotalResumeYB(oRole)
	local nState = self:GetAwardState(oRole, nID)
	if nState == 0 then
		nState = nTotalResumeYB >= tConf.nYuanBao and 1 or 0
	end
	local tInfo = {nID=nID, nState=nState}
	local tMsg = {nID = self.m_nID,tItem=tInfo}
	oRole:SendMsg("ActYYRewardRet", tMsg)
end


--领取奖励
function CLY:AwardReq(oRole, nID)
	if not self:IsOpen() then
		return oRole:Tips("不是领取奖励时间")
	end
	local nRoleID = oRole:GetID()
	local nState = self:GetAwardState(oRole, nID)
	if nState == 2 then
		return oRole:Tips("该奖励已经领取过了")
	end
	local nTotalResumeYB = self:GetTotalResumeYB(oRole)

	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tConf = tRoundConf[nID]

	if nTotalResumeYB < tConf.nYuanBao then
		return oRole:Tips("未达到领取条件")
	end
	self:SetAwardState(oRole, nID, 2)

	local tItemList = {}
	for _, tItem in ipairs(tConf.tAward) do 
		table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end
	oRole:AddItem(tItemList, "累积消耗元宝奖励", function(bRet)
		if bRet then
			self:RefreshInfo(oRole,nID)
			self:SyncState(oRole)

			--日志
			goLogger:ActivityLog(oRole, self:GetID(), self:GetName(), {}, tConf.tAward, nTotalResumeYB, nID)
		end
	end)
end