--战斗外BUFF
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

gtRoleStateDef = 
{
	eBaoshi = 601,                       --饱食度
	eMarriageSuit = 620,                 --新婚时装
	eMarriageBless = 621,                --新婚祝福
	eTeamMarriageBless = 622,            --队伍新婚祝福buff
	eTeamLeader = 630,                   --队长加成buff
	eHoneyRelationship = 631,            --同心加成 子类型 1夫妻, 2结拜, 3情缘, 4师徒
}

local tHoneyRelationBuffDef =   --角色同心buff子类型,注意，这个数值直接对应配置表中tParam的索引下标
{
	eSpouse = 1,                --夫妻
	eBrother = 2,               --结拜
	eLover = 3,                 --情缘
	eMentorship = 4,            --师徒
}

local tOnRoleStateExpiredHandle = 
{
	[gtRoleStateDef.eMarriageSuit] = function(oRole, nStateID) oRole.m_oRoleState:OnMarriageSuitExpired() end,
	[gtRoleStateDef.eMarriageBless] = function(oRole, nStateID) oRole.m_oRoleState:OnMarriageBlessExpired() end,
}

function CRoleState:Ctor(oRole)
	self.m_oRole = oRole
	self.m_tStateMap = {}

	--不保存,记录处理过的战斗
	self.m_tBattleMap = {} --{[buff]={[battleid]=0,},...}
end

function CRoleState:LoadData(tData)
	if tData then
		self.m_tStateMap = tData.m_tStateMap
	end

	local tBaoshiState = self:GetState(gtRoleStateDef.eBaoshi)
	if tBaoshiState and not tBaoshiState.nStateID then 
		self.m_tStateMap = {}  --错误数据全部扔掉
		self:MarkDirty(true)
		tBaoshiState = nil
	end

	if not tBaoshiState then 
		local tBaoshiConf = ctRoleStateConf[gtRoleStateDef.eBaoshi]
		self.m_tStateMap[gtRoleStateDef.eBaoshi] = {
			nStateID = gtRoleStateDef.eBaoshi,
			nTimes = tBaoshiConf.nMaxTimes,
		}
		self:MarkDirty(true)
	end
end

function CRoleState:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
	local tData = {}
	tData.m_tStateMap = self.m_tStateMap
	return tData
end

function CRoleState:GetType()
	return gtModuleDef.tRoleState.nID, gtModuleDef.tRoleState.sName
end

function CRoleState:GetState(nState)
	return self.m_tStateMap[nState]
end

function CRoleState:Online()
	self:SyncState()
end

function CRoleState:GetState(nStateID) 
	return self.m_tStateMap[nStateID]
end

function CRoleState:RemoveState(nStateID, bSync) 
	if not self.m_tStateMap[nStateID] then
		return 
	end
	self.m_tStateMap[nStateID] = nil
	self:MarkDirty(true)
	if bSync then 
		self:SyncState()
	end
end

--同步BUFF
function CRoleState:SyncState()
	local tMsg = {}
	tMsg.tBaoShi = self:GetBaoShiInfo()
	tMsg.tEquDur = self:GetEquDurableInfo()
	tMsg.tMarriageSuit = self:GetMarriageSuitInfo()
	tMsg.tMarriageBless = self:GetMarriageBlessInfo()
	tMsg.tTeamMarriageBless = self:GetTeamMarriageBlessInfo()
	tMsg.tTeamLeaderBuff = self:GetTeamLeaderBuffInfo()
	tMsg.tHoneyRelation = self:GetHoneyRelationshipInfo()
	self.m_oRole:SendMsg("RoleStateSyncRet", tMsg)
end

--状态时效相关处理函数
---------------------------------------------------
function CRoleState:OnRoleStateExpired(nStateID) 
	local fnExpiredHandle = tOnRoleStateExpiredHandle[nStateID]
	if fnExpiredHandle then 
		fnExpiredHandle(self.m_oRole, nStateID)
	end
end

function CRoleState:OnEnterLogic() 
	local tExpiryState = {
		gtRoleStateDef.eMarriageSuit,
		gtRoleStateDef.eMarriageBless,
	}

	local nRoleID = self.m_oRole:GetID()
	local nCurStamp = os.time()
	for _, nRoleStateID in ipairs(tExpiryState) do 
		local tState = self:GetState(nRoleStateID)
		if tState and tState.nTimeStamp and tState.nLastTime then 
			if tState.nTimeStamp > nCurStamp then --防止测试更改时间 
				tState.nTimeStamp = nCurStamp  --暂时不考虑不同逻辑服务之间时间不同步问题
				self:MarkDirty(true)
			end

			local tExpiryData = self:GetRoleStateExpiryData(nRoleStateID)
			goRoleTimeExpiryMgr:Update(nRoleID, gtRoleTimeExpiryType.eRoleState, 
				nRoleStateID, tExpiryData)
		end
	end
end

function CRoleState:GetRoleStateExpiryData(nStateID)
	local tRoleState = self:GetState(nStateID)
	if not tRoleState then 
		return 
	end
	local tExpiredData = {}
	tExpiredData.nRoleID = self.m_oRole:GetID()
	tExpiredData.nStateID = nStateID
	tExpiredData.nTimeStamp = tRoleState.nTimeStamp or 0
	tExpiredData.nLastTime = tRoleState.nLastTime or 0
	tExpiredData.nExpiryTime = tExpiredData.nTimeStamp + tExpiredData.nLastTime
	return tExpiredData
end

function CRoleState.RoleStateExpiryCmp(tDataL, tDataR) 
	if tDataL.nExpiryTime ~= tDataR.nExpiryTime then 
		return tDataL.nExpiryTime < tDataR.nExpiryTime and -1 or 1
	end

	if tDataL.nRoleID < tDataR.nRoleID then 
		return -1
	elseif tDataL.nRoleID > tDataR.nRoleID then 
		return 1
	end
	return 0
end

function CRoleState.RoleStateExpiryCheckHandle(tData, nTimeStamp) 
	--防止测试更改时间
	if math.abs(nTimeStamp - tData.nTimeStamp) >= tData.nLastTime then 
		return true 
	end
	return false
end

function CRoleState.RoleStateExpiryHandle(nRoleID, nExpiryType, nBuffID) 
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then 
		return
	end
	oRole.m_oRoleState:OnRoleStateExpired(nBuffID)
end

---------------饱食
--战斗结束检测和扣除饱食
--@nBattleID 战斗ID
--@nBattleDupType 副本战斗玩法,在BattleDupDef.lua
function CRoleState:CheckSubBaoShi(nBattleID, nBattleDupType)
	if not self.m_tBattleMap[601] then 
		self.m_tBattleMap[601] = {}
	end
	local tBattleMap = self.m_tBattleMap[601]

	--已处理过直接返回
	if tBattleMap[nBattleID] ~= nil then
		return tBattleMap[nBattleID]
	end

	--处理饱食点
	local bSubBaoShi = true
	for _, tCond in ipairs(ctRoleStateConf[601].tCond) do
		if tCond[1] == nBattleDupType then
			bSubBaoShi = math.random(100)<tCond[2]
			break
		end
	end
	if not bSubBaoShi then
		tBattleMap[nBattleID] = true
		return true
	end
	if self:GetBaoShiTimes() <= 0 then
		tBattleMap[nBattleID] = false
		return
	end
	self:AddBaoShiTimes(-1)
	tBattleMap[nBattleID] = true
	return true
end

function CRoleState:GetBaoShiInfo()
	local nRemainTimes = self:GetBaoShiTimes()
	local nMaxTimes = self:MaxBaoShiTimes()
	-- local nCostSilver = math.floor((gnSilverRatio/10)*(nMaxTimes-nRemainTimes))
	local nCostSilver = 600*(nMaxTimes-nRemainTimes) --单价600

	local tInfo = {
		nStateID = 601,
		nRemainTimes = nRemainTimes,	
		nMaxTimes = nMaxTimes,
		nCostSilver = nCostSilver,
	}
	return tInfo
end

function CRoleState:MaxBaoShiTimes()
	return ctRoleStateConf[601].nMaxTimes
end

function CRoleState:GetBaoShiTimes()
	local tState = self:GetState(601)
	return (tState.nTimes or 0)
end

function CRoleState:AddBaoShiTimes(nTimes)
	local tState = self:GetState(601)
	tState.nTimes = math.max(0, math.min(tState.nTimes+nTimes, self:MaxBaoShiTimes()))
	self:MarkDirty(true)
	self:SyncState()
	return tState.nTimes
end

function CRoleState:BuyBaoShiTimesReq()
	local nAddTimes = self:MaxBaoShiTimes() - self:GetBaoShiTimes()
	if nAddTimes <= 0 then
		return self.m_oRole:Tips("饱食次数已满")
	end
	local nCostSilver = 600*nAddTimes --单价600
	if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eYinBi, nCostSilver, "购买饱食度") then
		return self.m_oRole:YinBiTips()
	end
	self:AddBaoShiTimes(nAddTimes)
	self.m_oRole:Tips(string.format("消耗了%d银币，饱食度增加至%d场", nCostSilver, self:MaxBaoShiTimes()))

	if self.m_oRole:IsResidualHP() then
		self:AddBaoShiTimes(-1)
	    self.m_oRole:RecoverMPHP()
	end
end

------装备耐久
function CRoleState:CheckEquDurable()
	self:SyncState()
end


function CRoleState:GetEquDurableInfo()
	local tEquList = self.m_oRole.m_oKnapsack:GetDurableWearEqu(49)
	if #tEquList <= 0 then
		return
	end
	return {nStateID=607}
end

function CRoleState:FixEquDurableReq()
	--耐久低于50的身上装备
	local tEquList = self.m_oRole.m_oKnapsack:GetDurableWearEqu(49)
	if #tEquList <= 0 then
		return self.m_oRole:Tips("装备无需修复")
	end

	local nTotalPrice = 0
	for _, oEqu in ipairs(tEquList) do
		nTotalPrice = nTotalPrice + oEqu:GetFixPrice()
	end

	local sCont = string.format("修复所有装备需要%d银币，确定要修复吗？", nTotalPrice)
	local tMsg = {sCont=sCont, tOption={"取消","确定"}, nTimeOut=30}
	goClientCall:CallWait("ConfirmRet", function(tData)
		if tData.nSelIdx == 1 then return end

		if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eYinBi, nTotalPrice, "BUFF修理装备") then
			return self.m_oRole:YinBiTips()
		end

		for _, oEqu in pairs(tEquList) do
			self.m_oRole.m_oKnapsack:DoFixEqu(oEqu)
		end
		self.m_oRole:Tips(string.format("消耗了%d铜币，所有装备的耐久已恢复至满值", nTotalPrice))

	end, self.m_oRole, tMsg)
end


--新婚时装
---------------------------------------------------
function CRoleState:AddMarriageSuit() 
	local nStateID = gtRoleStateDef.eMarriageSuit
	assert(ctRoleStateConf[nStateID])
	local tData = {}
	tData.nStateID = nStateID
	tData.nTimeStamp = os.time()     --添加时间
	tData.nLastTime = 7*24*3600      --持续时长
	tData.bActive = true             --是否激活  --默认激活
	
	self.m_tStateMap[nStateID] = tData

	self:MarkDirty(true)
	local tExpiryData = self:GetRoleStateExpiryData(nStateID)
	goRoleTimeExpiryMgr:Update(self.m_oRole:GetID(), gtRoleTimeExpiryType.eRoleState, nStateID, tExpiryData)

	self.m_oRole:FlushRoleView()
end

function CRoleState:OnMarriageSuitExpired() 
	local tMarriageSuit = self:GetState(gtRoleStateDef.eMarriageSuit)
	local bActive = false
	if tMarriageSuit then 
		bActive = tMarriageSuit.bActive
	end
	self:RemoveState(gtRoleStateDef.eMarriageSuit, true)
	if bActive then 
		self.m_oRole:FlushRoleView()
	end
end

function CRoleState:IsMarriageSuitActive() 
	local tMarriageSuit = self:GetState(gtRoleStateDef.eMarriageSuit)
	if not tMarriageSuit then 
		return false 
	end
	return tMarriageSuit.bActive
end

function CRoleState:GetMarriageSuitInfo() 
	local tState = self:GetState(gtRoleStateDef.eMarriageSuit)
	if not tState then 
		return 
	end
	local tInfo = {}
	tInfo.nStateID = gtRoleStateDef.eMarriageSuit
	tInfo.nExpiryStamp = tState.nTimeStamp + tState.nLastTime
	tInfo.nTimeRemain = math.max(tInfo.nExpiryStamp - os.time(), 0)
	tInfo.bActive = tState.bActive
	return tInfo
end

function CRoleState:MarriageSuitActiveSet(bActive) 
	bActive = bActive and true or false
	local tState = self:GetState(gtRoleStateDef.eMarriageSuit)
	if not tState then 
		return 
	end
	if tState.bActive == bActive then 
		return 
	end
	tState.bActive = bActive
	self:MarkDirty(true)
	self:SyncState()
	self.m_oRole:FlushRoleView()
end

--新婚祝福
---------------------------------------------------
function CRoleState:AddMarriageBless() 
	-- assert(nTriggerRoleID > 0 and nTriggerRoleID ~= self.m_oRole:GetID(), "参数错误")
	local nStateID = gtRoleStateDef.eMarriageBless
	assert(ctRoleStateConf[nStateID])
	local tData = {}
	tData.nStateID = nStateID
	tData.nTimeStamp = os.time()     --添加时间
	tData.nLastTime = 7*24*3600      --持续时长
	-- tData.bActive = false
	-- tData.nTriggerRoleID = nTriggerRoleID    --可以触发激活的角色ID
	
	self.m_tStateMap[nStateID] = tData
	--获取全局服队伍数据，更新队伍buff相关数据
	self.m_oRole:UpdateTeamDataReq()

	self:MarkDirty(true)
	local tExpiryData = self:GetRoleStateExpiryData(nStateID)
	goRoleTimeExpiryMgr:Update(self.m_oRole:GetID(), gtRoleTimeExpiryType.eRoleState, 
		nStateID, tExpiryData)
	print("添加角色新婚祝福buff")
end

function CRoleState:OnMarriageBlessExpired()
	print("角色新婚祝福buff过期被移除") 
	self:RemoveState(gtRoleStateDef.eMarriageSuit, true)
	self.m_oRole:UpdateTeamDataReq()
end

function CRoleState:GetMarriageBlessInfo()
	local tState = self:GetState(gtRoleStateDef.eMarriageBless)
	if not tState then 
		return 
	end 
	local tInfo = {}
	tInfo.nStateID = gtRoleStateDef.eMarriageBless
	tInfo.nExpiryStamp = tState.nTimeStamp + tState.nLastTime
	tInfo.nTimeRemain = math.max(tInfo.nExpiryStamp - os.time(), 0)
	tInfo.bActive = true
	return tInfo
end

-- --更新结婚祝福状态
-- --[[
-- 	--全局服队伍数据发生变化(成功归队、暂离、离开队伍、队伍解散)
-- 	--给所有角色逻辑服发送完整队伍数据，更新队伍buff
-- 	--每个玩家只需要处理自己当前队伍buff是否需要变更

-- 	--角色上线，需要触发整个队伍成员数据更新下
-- 	--角色下线，需要触发整个队伍成员数据更新下
-- 	(这个不能放在角色释放处，否则会多出很多回调检查，放在执行下线成功后面，回调检查)
-- 	--角色结婚buff添加时，需要触发整个队伍成员数据更新下
-- 	--角色结婚buff移除时，需要触发整个队伍成员数据更新下
-- ]]
-- function CRoleState:UpdateMarriageBlessStateReq()
-- 	local oRole = self.m_oRole
-- 	Network.oRemoteCall:Call("UpdateMarriageBlessStateReq", gnWorldServerID, 
-- 		goServerMgr:GetGlobalService(gnWorldServerID, 110), oRole:GetSession(), oRole:GetID())
-- end

function CRoleState:UpdateMarriageBlessState(tTeamRoleList) 
	--角色切换场景，如果触发切换逻辑服，可能导致前面的队员刷新此数据时，
	--检查buff没有触发，后续队员，刷新此数据时，检查触发了buff
	--所以，如果角色在队伍中，并且非暂离状态，并且触发了新婚buff
	--则检查所有未暂离的队员，设置新婚buff

	local bTriggerTeamMarriageBless = false

	if tTeamRoleList and next(tTeamRoleList) then 
		local nRoleID = self.m_oRole:GetID()
		local bLeave = false  --角色是否暂离

		local tRoleMap = {}
		for _, tTeamRole in pairs(tTeamRoleList) do
			if not tTeamRole.bLeave then  --角色未暂离，并且在当前逻辑服
				local oTarRole = goPlayerMgr:GetRoleByID(tTeamRole.nRoleID)
				if oTarRole and not oTarRole:IsReleasedd() then 
					tRoleMap[tTeamRole.nRoleID] = oTarRole
				end 
			else
				if tTeamRole.nRoleID == nRoleID then 
					bLeave = true 
					break
				end
			end
		end

		if not bLeave then 
			for nTarRoleID, oTarRole in pairs(tRoleMap) do 
				if oTarRole.m_oRoleState:GetState(gtRoleStateDef.eMarriageBless) then 
					bTriggerTeamMarriageBless = true
					break
				end
			end
		end
	end

	if bTriggerTeamMarriageBless then 
		for _, tTeamRole in pairs(tTeamRoleList) do
			if not tTeamRole.bLeave then  --角色未暂离，并且在当前逻辑服
				local oTarRole = goPlayerMgr:GetRoleByID(tTeamRole.nRoleID)
				if oTarRole and not oTarRole:IsReleasedd() then 
					--当前在队伍中并且未暂离并且在当前逻辑服，并且当前没有新婚祝福buff的
					if not oTarRole.m_oRoleState:GetState(gtRoleStateDef.eMarriageBless)
						and not oTarRole.m_oRoleState:GetState(gtRoleStateDef.eTeamMarriageBless) then 
						oTarRole.m_oRoleState:AddTeamMarriageBless()
						oTarRole.m_oRoleState:SyncState()
					end
				end 
			end
		end
	else
		if self:GetState(gtRoleStateDef.eTeamMarriageBless) then 
			self:RemoveState(gtRoleStateDef.eTeamMarriageBless)
			self:SyncState()
		end
	end
end

--队伍新婚祝福
---------------------------------------------------
--添加队伍新婚buff
function CRoleState:AddTeamMarriageBless() 
	local nStateID = gtRoleStateDef.eTeamMarriageBless
	assert(ctRoleStateConf[nStateID])
	local tData = {}
	tData.nStateID = nStateID
	self.m_tStateMap[nStateID] = tData
	self:MarkDirty(true)
end

function CRoleState:GetTeamMarriageBlessInfo() 
	local tMarriageBless = self:GetState(gtRoleStateDef.eMarriageBless)
	if tMarriageBless then --自己当前已存在新婚buff, 则不显示队伍的
		return 
	end
	local tState = self:GetState(gtRoleStateDef.eTeamMarriageBless)
	if not tState then 
		return 
	end
	local tInfo = {}
	tInfo.nStateID = gtRoleStateDef.eTeamMarriageBless
	return tInfo
end

--是否有新婚祝福buff加成生效, 
--第1个返回值 true生效, false不生效
--第2个返回值 加成系数(百分比数值，比如 20, 即加成20%)
function CRoleState:IsMarriageBlessEffectActive(nGameType) 
	local bActive = false
	local nRoleStateID = 0
	if self:GetState(gtRoleStateDef.eMarriageBless) then 
		bActive = true 
		nRoleStateID = gtRoleStateDef.eMarriageBless
	elseif self:GetState(gtRoleStateDef.eTeamMarriageBless) then 
		bActive = true 
		nRoleStateID = gtRoleStateDef.eTeamMarriageBless
	end
	if not bActive then 
		return false, 0
	end
	local tConf = ctRoleStateConf[nRoleStateID]
	assert(tConf)
	for _, v in ipairs(tConf.tGameType) do 
		if v[1] == nGameType then 
			return true, tConf.nParam
		end
	end
	return false, 0
end


--队长加成buff
---------------------------------------------------
function CRoleState:AddTeamLeaderBuff() 
	local nStateID = gtRoleStateDef.eTeamLeader
	assert(ctRoleStateConf[nStateID])
	local tData = {}
	tData.nStateID = nStateID
	self.m_tStateMap[nStateID] = tData
	self:MarkDirty(true)
end

function CRoleState:GetTeamLeaderBuffInfo()
	local tState = self:GetState(gtRoleStateDef.eTeamLeader)
	if not tState then 
		return 
	end
	local tInfo = {}
	tInfo.nStateID = gtRoleStateDef.eTeamLeader
	return tInfo
end

--检查是否存在队长加成, 返回加成关系, 及加成系数(百分比数值，比如 20, 即加成20%)
function CRoleState:IsTeamLeaderBuffActive() 
	if self:GetState(gtRoleStateDef.eTeamLeader) then 
		local tConf = ctRoleStateConf[gtRoleStateDef.eTeamLeader]
		return true, tConf.nParam
	end
	return false, 0
end

--更新队伍buff数据
function CRoleState:UpdateTeamLeaderBuff() 
	local tTeamList = self.m_oRole:GetTeamList()
	local bActive = false
	if self.m_oRole:IsLeader() then 
		local nActiveNum = 0
		for k, tRole in ipairs(tTeamList) do 
			if not tRole.bLeave then 
				nActiveNum = nActiveNum + 1
			end
		end
		if nActiveNum >= 3 then 
			bActive = true 
		end
	end

	if bActive then 
		if not self:GetState(gtRoleStateDef.eTeamLeader) then 
			self:AddTeamLeaderBuff()
			self:SyncState()
		end
	else
		if self:GetState(gtRoleStateDef.eTeamLeader) then 
			self:RemoveState(gtRoleStateDef.eTeamLeader)
			self:SyncState()
		end
	end
end

--玩家亲密关系加成buff
---------------------------------------------------
-- nType 加成关系, 1夫妻, 2结拜, 3情缘, 4师徒
function CRoleState:AddHoneyRelationshipBuff(nType)
	local nStateID = gtRoleStateDef.eHoneyRelationship
	assert(ctRoleStateConf[nStateID])
	assert(nType >= 1 and nType <= 4)

	--判断之前是否已存在此关系buff，如果不存在，则添加，如果存在，则增加关系类型数据
	local bNewAdd = false
	local tState = self:GetState(gtRoleStateDef.eHoneyRelationship)
	if tState then 
		if not tState.tActiveType[nType] then 
			tState.tActiveType[nType] = true 
			self:MarkDirty(true)
			bNewAdd = true
		end
	else
		local tData = {}
		tData.nStateID = nStateID
		local tActiveType = {}
		tActiveType[nType] = true
		tData.tActiveType = tActiveType
		self.m_tStateMap[nStateID] = tData
		self:MarkDirty(true)
		bNewAdd = true
	end

	return bNewAdd
end

--是否存在xx亲密关系
function CRoleState:CheckHoneyRelationshipBuffExist(nType) 
	local nStateID = gtRoleStateDef.eHoneyRelationship
	assert(ctRoleStateConf[nStateID])
	assert(nType >= 1 and nType <= 4)
	local tState = self:GetState(gtRoleStateDef.eHoneyRelationship)
	if not tState then 
		return false
	end
	if tState.tActiveType[nType] then 
		return true 
	end
	return false
end

--删除角色亲密关系buff加成关系
function CRoleState:RemoveHoneyRelationshipBuff(nType)
	local nStateID = gtRoleStateDef.eHoneyRelationship
	assert(ctRoleStateConf[nStateID])
	assert(nType >= 1 and nType <= 4)
	local bFlag = false
	local tState = self:GetState(gtRoleStateDef.eHoneyRelationship)
	if not tState then 
		return bFlag
	end
	if tState.tActiveType[nType] then 
		tState.tActiveType[nType] = nil
		self:MarkDirty(true)
		bFlag = true
	end
	if not next(tState.tActiveType) then --如果没其他加成关系了，则删除buff
		self:RemoveState(gtRoleStateDef.eHoneyRelationship)
	end
	return bFlag
end

function CRoleState:GetHoneyRelationshipInfo()
	local tState = self:GetState(gtRoleStateDef.eHoneyRelationship)
	if not tState then 
		return 
	end
	local tInfo = {}
	tInfo.nStateID = gtRoleStateDef.eHoneyRelationship
	local tActiveList = {}
	for nHoneyType, _ in pairs(tState.tActiveType) do 
		table.insert(tActiveList, nHoneyType)
	end
	tInfo.tActiveRelation = tActiveList
	tInfo.nActiveType = self:GetHoneyRelationshipActiveType()
	return tInfo
end

--获取当前生效的亲密关系类型
--返回0，表示没有生效的关系类型
function CRoleState:GetHoneyRelationshipActiveType()
	local tState = self:GetState(gtRoleStateDef.eHoneyRelationship)
	if tState then 
		local tStateConf = ctRoleStateConf[gtRoleStateDef.eHoneyRelationship]
		local tAddRatio = {}
		for k, tVal in ipairs(tStateConf.tParam) do --亲密关系加成子类型索引直接和配置顺序对应
			table.insert(tAddRatio, tVal[1])
		end
		local nMaxRatio = 0
		local tActiveList = {}
		for nType, bState in pairs(tState.tActiveType) do 
			if bState then 
				local nRatio = tAddRatio[nType] or 0
				if nRatio > nMaxRatio then 
					nMaxRatio = nRatio
					tActiveList = {}  --清空
					tActiveList[nType] = true
				elseif nRatio == nMaxRatio then 
					tActiveList[nType] = true
				end
			end
		end
		if not next(tActiveList) then 
			return 0
		end
		--返回生效的关系类型
		--按照优先级判断下
		if tActiveList[tHoneyRelationBuffDef.eSpouse] then 
			return tHoneyRelationBuffDef.eSpouse
		end
		if tActiveList[tHoneyRelationBuffDef.eBrother] then 
			return tHoneyRelationBuffDef.eBrother
		end
		if tActiveList[tHoneyRelationBuffDef.eLover] then 
			return tHoneyRelationBuffDef.eLover
		end
		return tHoneyRelationBuffDef.eMentorship
	else
		return 0
	end
end

--是否存在亲密关系加成，及其系数(百分比数值，比如 20, 即加成20%)
function CRoleState:IsHoneyRelationshipBuffActive()
	-- local tState = self:GetState(gtRoleStateDef.eHoneyRelationship)
	-- if tState then 
	-- 	local tStateConf = ctRoleStateConf[gtRoleStateDef.eHoneyRelationship]
	-- 	local tAddRatio = {}
	-- 	for k, tVal in ipairs(tStateConf.tParam) do --亲密关系加成子类型索引直接和配置顺序对应
	-- 		table.insert(tAddRatio, tVal[1])
	-- 	end
	-- 	local nMaxRatio = 0
	-- 	for nType, bState in pairs(tState.tActiveType) do 
	-- 		if bState then 
	-- 			local nRatio = tAddRatio[nType] or 0
	-- 			if nRatio > nMaxRatio then 
	-- 				nMaxRatio = nRatio
	-- 			end
	-- 		end
	-- 	end
	-- 	return true, nMaxRatio
	-- end
	-- return false, 0
	local nRelationType = self:GetHoneyRelationshipActiveType()
	if nRelationType > 0 then 
		local tStateConf = ctRoleStateConf[gtRoleStateDef.eHoneyRelationship]
		assert(tStateConf)
		local tParam = tStateConf.tParam[nRelationType]
		if tParam then 
			return true, tParam[1] or 0
		end
	end
	return false, 0
end

function CRoleState:UpdateHoneyRelationshipBuff()
	--因为队伍切换场景导致切换逻辑服，先后同步消息问题
	--如果玩家有触发加成关系，需要检查加成关系对应的玩家，是否已有此buff
	--如果没有, 需要给对应玩家也添加此buff
	--只需要关注和自己存在亲密关系的玩家
	local tTeamList = self.m_oRole:GetTeamList()
	-- 4种关系加成
	local tHoneyActiveMap = {}  --{nHoneyType:tRoleList, ...}

	local nRoleID = self.m_oRole:GetID()
	local tServerRoleMap = {}  --可能对应玩家不在当前逻辑服
	tServerRoleMap[nRoleID] = self.m_oRole 

	--当前玩家在队伍并且未暂离
	if self.m_oRole:GetTeamID() > 0 and not self.m_oRole:IsTeamLeave() then 
		for _, tRole in ipairs(tTeamList) do 
			local nTarID = tRole.nRoleID
			if nRoleID ~= nTarID and not tRole.bLeave then --在队伍并且未暂离
				local oTarRole = goPlayerMgr:GetRoleByID(nTarID)
				if oTarRole then  --必须在同一个逻辑服
					tServerRoleMap[nTarID] = oTarRole

					--可能和对方同时存在多种亲密关系
					if self.m_oRole:IsSpouse(nTarID) then 
						local nHoneyType = tHoneyRelationBuffDef.eSpouse
						local tRoleList = tHoneyActiveMap[nHoneyType] or {}
						table.insert(tRoleList, nTarID)
						tHoneyActiveMap[nHoneyType] = tRoleList 
					end
					if self.m_oRole:IsBrother(nTarID) then 
						local nHoneyType = tHoneyRelationBuffDef.eBrother
						local tRoleList = tHoneyActiveMap[nHoneyType] or {}
						table.insert(tRoleList, nTarID)
						tHoneyActiveMap[nHoneyType] = tRoleList 
					end
					if self.m_oRole:IsLover(nTarID) then 
						local nHoneyType = tHoneyRelationBuffDef.eLover
						local tRoleList = tHoneyActiveMap[nHoneyType] or {}
						table.insert(tRoleList, nTarID)
						tHoneyActiveMap[nHoneyType] = tRoleList 
					end
					if self.m_oRole:IsMentorship(nTarID) then 
						local nHoneyType = tHoneyRelationBuffDef.eMentorship
						local tRoleList = tHoneyActiveMap[nHoneyType] or {}
						table.insert(tRoleList, nTarID)
						tHoneyActiveMap[nHoneyType] = tRoleList 
					end
				end
			end
		end
	end

	local tBuffChangeMap = {} --缓存下出现buff变化的玩家ID, 避免多次同步
	for _, nHoneyType in pairs(tHoneyRelationBuffDef) do
		if tHoneyActiveMap[nHoneyType] then --可以激活此buff
			--检查自己和对应玩家，是否存在此buff, 如果不存在，则添加
			--需要判断对方是否在当前逻辑服
			local tRoleList = tHoneyActiveMap[nHoneyType]
			if self:AddHoneyRelationshipBuff(nHoneyType) then --发生真实添加
				tBuffChangeMap[self.m_oRole:GetID()] = self.m_oRole
			end
			for _, nTarID in ipairs(tRoleList) do 
				local oTarRole = tServerRoleMap[nTarID]
				--在当前逻辑服并且发生真实添加
				if oTarRole and 
					oTarRole.m_oRoleState:AddHoneyRelationshipBuff(nHoneyType) then 
					tBuffChangeMap[nTarID] = oTarRole
				end
			end
		else
			--检查自己原来是否存在buff，如果存在，则移除
			if self:RemoveHoneyRelationshipBuff(nHoneyType) then --发生真实移除
				tBuffChangeMap[self.m_oRole:GetID()] = self.m_oRole
			end
		end
	end

	--同步buff变化
	for nTarID, oTarRole in pairs(tBuffChangeMap) do 
		oTarRole.m_oRoleState:SyncState()
	end
end


--队伍列表数据更新
---------------------------------------------------
function CRoleState:OnTeamUpdate() 
	local tTeamList = self.m_oRole:GetTeamList()
	self:UpdateMarriageBlessState(tTeamList)
	self:UpdateTeamLeaderBuff()
	self:UpdateHoneyRelationshipBuff()
end

