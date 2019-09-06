--累登
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLD:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self.m_nRounds = 1 				--不能放到Init函数里面
	self:Init()

end

function CLD:Init()
	self.m_tAwardMap = {} 		--已领取奖励映射{[roleid]={[id]=flag, ...},...}
	self.m_tLastLogin = {} 		--上次登录时间
	self.m_tLoginCount = {} 	--累计登录次数
	self:MarkDirty(true)
end

function CLD:LoadData()
	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	local sData = oSSDB:HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData == "" then return end

	local tData = cseri.decode(sData)
	CHDBase.LoadData(self, tData)

	self.m_nRounds = tData.m_nRounds or {}
	self.m_tAwardMap = tData.m_tAwardMap or {}
	self.m_tLastLogin = tData.m_tLastLogin or {}
	self.m_tLoginCount = tData.m_tLoginCount or {}
end

function CLD:SaveData()
	if not self:IsDirty() then
		return
	end

	local tData = CHDBase.SaveData(self)
	tData.m_nRounds = self.m_nRounds
	tData.m_tAwardMap = self.m_tAwardMap
	tData.m_tLastLogin = self.m_tLastLogin
	tData.m_tLoginCount = self.m_tLoginCount

	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	oSSDB:HSet(gtDBDef.sHuoDongDB, self:GetID(), cseri.encode(tData))
	self:MarkDirty(false)
end

--开启活动
function CLD:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)
	nExtID = math.max(1, nExtID or 1)

	local bExist = false
	for k=1, #ctLDConf do 
		if ctLDConf[k].nRounds == nExtID then 
			bExist = true
			break
		end
	end
	assert(bExist, "累登活动轮次错误")
	
	self.m_nRounds = nExtID
	self:MarkDirty(true)

	CHDBase.OpenAct(self, nStartTime, nEndTime, nAwardTime, nExtID)	
end

function CLD:GetRounds()
	return self.m_nRounds
end

--玩家上线
function CLD:Online(oRole)
	if not self:IsOpen() then
		self:SyncState(oRole)
		return
	end
	local nRoleID = oRole:GetID()
	local nLastLogin = self.m_tLastLogin[nRoleID] or 0
	if not os.IsSameDay(nLastLogin, os.time(), 0) then
		self.m_tLastLogin[nRoleID] = os.time()
		self.m_tLoginCount[nRoleID] = (self.m_tLoginCount[nRoleID] or 0) + 1
		self:MarkDirty(true)
	end
	self:SyncState(oRole)
end

--取登录天数
function CLD:GetLoginCount(nRoleID)
	return (self.m_tLoginCount[nRoleID] or 0)
end

--取奖励状态
function CLD:GetAwardState(nRoleID, nID)
	local tAwardMap = self.m_tAwardMap[nRoleID]
	if not tAwardMap then return 0 end
	return (tAwardMap[nID] or 0)
end

--设置奖励状态
function CLD:SetAwardState(oRole, nID, nState)
	local nRoleID = oRole:GetID()
	if not self.m_tAwardMap[nRoleID] then
		self.m_tAwardMap[nRoleID] = {}
	end
	self.m_tAwardMap[nRoleID][nID] = nState
	self:MarkDirty(true)
end

--取剩余天数
function CLD:GetRemainDays()
	local nBegDay = os.YDay(self.m_nBegTime)
	local nEndDay = os.YDay(self.m_nEndTime)
	local nYearDay = os.YearDays(self.m_nBegTime)
	if nEndDay < nBegDay then
		return nYearDay - nBegDay + nEndDay + 1
	else
		return nEndDay - os.YDay(os.time()) + 1
	end
end

--进入初始状态
function CLD:OnStateInit()
	LuaTrace("活动:", self.m_nID, "进入初始状态")
	self:SyncState()
end

--进入活动状态
function CLD:OnStateStart()
	LuaTrace("活动:", self.m_nID, "进入开始状态")
	self:Init()
	self:SyncState()
end

--进入领奖状态
function CLD:OnStateAward()
	LuaTrace("活动:", self.m_nID, "进入奖励状态")
	self:SyncState()
end

--进入关闭状态
function CLD:OnStateClose()
	LuaTrace("活动:", self.m_nID, "进入关闭状态")
	self:SyncState()
	self:CheckAward()
end

function CLD:CanGetAward(nRoleID)
	for nID, tConf in ipairs(ctLDConf) do
		if self:GetAwardState(nRoleID, nID) == 0 and self:GetLoginCount(nRoleID) >= tConf.nLoginCount then
			return true
		end
	end
	return false
end

--同步活动状态
function CLD:SyncState(oRole)
	local nState = self:GetState()
	local nBeginTime, nEndTime, nStateTime = self:GetStateTime()
	if nState == CHDBase.tState.eClose then
		nBeginTime, nEndTime = goHDCircle:GetActNextOpenTime(self:GetID())
		if nBeginTime > 0 and nBeginTime > os.time() then
			assert(nEndTime>nBeginTime, "下次开启时间错误")
			nState = CHDBase.tState.eInit
			nStateTime = nEndTime - nBeginTime
		end
	end
	local tMsg = {
		nID = self:GetID(),
		nState = nState,
		nStateTime = nStateTime,
		nBeginTime = nBeginTime,
		nEndTime = nEndTime,
		bCanGetAward = false,
		nRounds = self:GetRounds(),
		nOpenTimes = self:GetOpenTimes(),
	}
	--同步给指定玩家
	if oRole then
		tMsg.bCanGetAward = self:CanGetAward(oRole:GetID())
		oRole:SendMsg("ActLDStateRet", tMsg)
	--全服广播
	else
		local tSessionMap = goGPlayerMgr:GetRoleSSMap()
		for nSession, oTmpRole in pairs(tSessionMap) do
			tMsg.bCanGetAward = self:CanGetAward(oTmpRole:GetID())
			oTmpRole:SendMsg("ActLDStateRet", tMsg)
		end
	end
end

--检测奖励
function CLD:CheckAward()
	for nRoleID, nCount in pairs(self.m_tLoginCount) do
		if nCount > 0 then
			for nID, tConf in ipairs(ctLDConf) do
				if tConf.nRounds == self.m_nRounds then
					local nState = self:GetAwardState(nRoleID, nID)
					if nState == 0 and nCount >= tConf.nLoginCount then
						self.m_tAwardMap[nRoleID] = self.m_tAwardMap[nRoleID] or {}
						self.m_tAwardMap[nRoleID][nID] = 2
						self:MarkDirty(true)

						local oRole = goGPlayerMgr:GetRoleByID(nRoleID)	
						local tList = table.DeepCopy(tConf.tAward)
						local sCont = string.format("您在%s活动中达到累登%d次，获得了以下奖励，请查收。", self:GetName(), tConf.nLoginCount) 
						CUtil:SendMail(oRole:GetServer(), string.format("%s活动奖励", self:GetName()), sCont, tList, nRoleID)
					end
				end
			end
		end
	end
end

--取信息
function CLD:InfoReq(oRole)
	if not self:IsOpen() and not self:IsAward() then
		return oRole:Tips("活动已结束")
	end
	local nRounds = self:GetRounds()
	local nRemainDays = self:GetRemainDays()
	local nLoginCount = self:GetLoginCount(oRole:GetID())

	local tMsg = {nLoginCount=nLoginCount, nRemainDays=nRemainDays, tList={}}
	for nID, tConf in ipairs(ctLDConf) do
		if tConf.nRounds == nRounds then
			local nState = self:GetAwardState(oRole:GetID(), nID)
			if nState == 0 then
				nState = nLoginCount>=tConf.nLoginCount and 1 or 0
			end
			local tInfo = {nID=nID, nState=nState}
			table.insert(tMsg.tList, tInfo)
		end
	end
	oRole:SendMsg("ActLDInfoRet", tMsg)
	return tMsg
end

--领取奖励
function CLD:AwardReq(oRole, nID)
	if not self:IsOpen() and not self:IsAward() then
		return oRole:Tips("活动已结束")
	end
	local nState = self:GetAwardState(oRole:GetID(), nID)
	if nState == 2 then
		return oRole:Tips("该奖励已经领取过了")
	end
	local tConf = ctLDConf[nID]
	local nRounds = self:GetRounds()
	if tConf.nRounds ~= nRounds then
		return oRole("奖励轮次错误")
	end
	local nLoginCount = self:GetLoginCount(oRole:GetID())
	if nLoginCount < tConf.nLoginCount then
		return oRole:Tips("未达到领取条件")
	end
	self:SetAwardState(oRole, nID, 2)

	local tItemList = {}
	for _, tItem in ipairs(tConf.tAward) do 
		table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end
	oRole:AddItem(tItemList, "累登活动奖励", function(bRet)
		if bRet then
			self:InfoReq(oRole)
			self:SyncState(oRole)

			--日志
			goLogger:ActivityLog(oRole, self:GetID(), self:GetName(), {}, tConf.tAward, nLoginCount, nID)
		end
	end)
end