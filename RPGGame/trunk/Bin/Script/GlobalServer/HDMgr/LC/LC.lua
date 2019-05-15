--累充活动
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLC:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self.m_nRounds = 1 				--不能放到Init函数里面

	self:Init()
end

function CLC:Init()
	self.m_tAwardMap = {} 		--{[roleid]={[id]=flag,...},...}
	self.m_tRechargeMap = {} 	--{[roleid]=num,...}
	self:MarkDirty(true)
end

function CLC:LoadData()
	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local sData = oSSDB:HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData == "" then
		return
	end
	local tData = cjson.decode(sData)
	CHDBase.LoadData(self, tData)
	self.m_nRounds = tData.m_nRounds or 1
	self.m_tAwardMap = tData.m_tAwardMap
	self.m_tRechargeMap = tData.m_tRechargeMap
end

function CLC:SaveData()
	if not self:IsDirty() then
		return
	end
	local tData = CHDBase.SaveData(self)
	tData.m_nRounds = self.m_nRounds
	tData.m_tAwardMap = self.m_tAwardMap
	tData.m_tRechargeMap = self.m_tRechargeMap

	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	oSSDB:HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
	self:MarkDirty(false)

end

--玩家上线
function CLC:Online(oRole)
	self:SyncState(oRole)
end

--进入初始状态
function CLC:OnStateInit()
	LuaTrace("活动:", self.m_nID, "进入初始状态")
	self:SyncState()
end

--进入活动状态
function CLC:OnStateStart()
	LuaTrace("活动:", self.m_nID, "进入开始状态")
	self:Init()
	self:SyncState()
end

--进入领奖状态
function CLC:OnStateAward()
	LuaTrace("活动:", self.m_nID, "进入奖励状态")
	self:SyncState()
end

--进入关闭状态
function CLC:OnStateClose()
	LuaTrace("活动:", self.m_nID, "进入关闭状态")
	self:SyncState()
	self:CheckAward()
end

--取奖励状态
function CLC:GetAwardState(oRole, nID)
	local nRoleID = oRole:GetID()
	local tAwardMap = self.m_tAwardMap[nRoleID] or {}
	return (tAwardMap[nID] or 0) 
end

--设置奖励状态
function CLC:SetAwardState(oRole, nID, nState)
	local nRoleID = oRole:GetID()
	self.m_tAwardMap[nRoleID] = self.m_tAwardMap[nRoleID] or {}
	self.m_tAwardMap[nRoleID][nID] = nState
	self:MarkDirty(true)
end

--取轮次配置
function CLC:GetRoundConf(nRounds)
	local tRoundConf = {}
	local tLCConf = goBackstage:GetConf(gnServerID, gtBackstageType.eAccumulativeRecharge) --后台配置
	for k=1, #tLCConf do 
		if tLCConf[k].nRounds == nRounds then 
			tRoundConf[tLCConf[k].nID] = tLCConf[k]
		end
	end
	if not next(tRoundConf) then
		assert(false, "累充活动轮次错误:"..nRounds)
	end
	return tRoundConf
end

--开启活动
function CLC:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)
	nExtID = math.max(1, nExtID or 1)
	self:GetRoundConf(nExtID)
	self.m_nRounds = nExtID
	self:MarkDirty(true)

	CHDBase.OpenAct(self, nStartTime, nEndTime, nAwardTime, nExtID)	
end

--充值成功
function CLC:OnRechargeSuccess(oRole, nMoney)
	if not self:IsOpen() then
		return
	end
	local nRoleID = oRole:GetID()
	self.m_tRechargeMap[nRoleID] = (self.m_tRechargeMap[nRoleID] or 0) + nMoney
	self:MarkDirty(true)
	self:SyncState(oRole)
end

--取充值金额
function CLC:GetTotalRecharge(oRole)
	local nRoleID = oRole:GetID()
	return (self.m_tRechargeMap[nRoleID] or 0)
end

--是否可领奖
function CLC:CanGetAward(oRole)
	if not self:IsOpen() then
		return false
	end
	local nTimeRecharge = self:GetTotalRecharge(oRole)
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	for nID, tConf in pairs(tRoundConf) do
		local nState = self:GetAwardState(oRole, nID)
		if nState == 0 and nTimeRecharge >= tConf.nMoney then
			return true
		end
	end
	return false
end

--同步活动状态
function CLC:SyncState(oRole)
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
	}
	--同步给指定玩家
	if oRole then
		tMsg.bCanGetAward = self:CanGetAward(oRole)
		oRole:SendMsg("ActLCStateRet", tMsg)
	--全服广播
	else
		local tSessionMap = goGPlayerMgr:GetRoleSSMap()
		for nSession, oTmpRole in pairs(tSessionMap) do
			tMsg.bCanGetAward = self:CanGetAward(oTmpRole)
			oTmpRole:SendMsg("ActLCStateRet", tMsg)
		end
	end
end

--检测活动结束奖励
function CLC:CheckAward()
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	for nRoleID, nMoney in pairs(self.m_tRechargeMap) do
		if nMoney > 0 then
			for nID, tConf in pairs(tRoundConf) do
				self.m_tAwardMap[nRoleID] = self.m_tAwardMap[nRoleID] or {}
				local tAwardMap = self.m_tAwardMap[nRoleID] 
				if not tAwardMap[nID] then
					if nMoney >= tConf.nMoney then
						tAwardMap[nID] = 2
						self:MarkDirty(true)

						local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
						local tList = table.DeepCopy(tConf.tAward)
						local sCont = string.format("您在累计充值活动中达到累充%d元，获得了以下奖励，请查收。", tConf.nMoney) 
						GF.SendMail(oRole:GetServer(), "累计充值奖励", sCont, tList, nRoleID)
					end
				end
			end
		end
	end
end

--取信息
function CLC:InfoReq(oRole)
	if not self:IsOpen() then
		return oRole:Tips("活动已结束或未开启")
	end
	local nRemainTime = self:GetStateTime()
	local nBegTime, nEndTime = self:GetActTime()
	local nTimeRecharge = self:GetTotalRecharge(oRole)

	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tMsg = {nRemainTime=nRemainTime, nTimeRecharge=nTimeRecharge, nBeginTime=nBegTime, nEndTime=nEndTime, tList={}, sConf=cjson_raw.encode(tRoundConf)}	
	for nID, tConf in pairs(tRoundConf) do
		local nState = self:GetAwardState(oRole, nID)
		if nState == 0 then
			nState = nTimeRecharge >= tConf.nMoney and 1 or 0
		end
		local tInfo = {nID=nID, nState=nState}
		table.insert(tMsg.tList, tInfo)
	end
	oRole:SendMsg("ActLCInfoRet", tMsg)
end

--领取奖励
function CLC:AwardReq(oRole, nID)
	if not self:IsOpen() then
		return oRole:Tips("活动已结束或未开启")
	end
	local nState = self:GetAwardState(oRole, nID)
	if nState == 2 then
		return oRole:Tips("该奖励已经领取过了")
	end
	local nTimeRecharge = self:GetTotalRecharge(oRole)
	local tRoundConf = self:GetRoundConf(self.m_nRounds)
	local tConf = tRoundConf[nID]
	if nTimeRecharge < tConf.nMoney then
		return oRole:Tips("未达到领取条件")
	end
	self:SetAwardState(oRole, nID, 2)

	local tItemList = {}
	for _, tItem in ipairs(tConf.tAward) do 
		table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end
	oRole:AddItem(tItemList, string.format("%s奖励", self:GetName()), function(bRet)
		if bRet then
			self:InfoReq(oRole)
			self:SyncState(oRole)

			--日志
			goLogger:ActivityLog(oRole, self:GetID(), self:GetName(), {}, tConf.tAward, nTimeRecharge, nID)
		end
	end)
end