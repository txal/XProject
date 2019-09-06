--PVP活动基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CPVPActivityBaseRoleData:Ctor(oModul, oRole, nScoreStamp)
	assert(oRole, "数据错误")
	self.m_oModul = oModul
	self.m_nRoleID = oRole:GetID()
	self.m_sName = oRole:GetName()
	self.m_nLevel = oRole:GetLevel()
	self.m_nRoleConfID = oRole:GetConfID()
	self.m_nSchoolID = oRole:GetSchool()
	self.m_nServer = oRole:GetServer()
	self.m_nScore = self.m_oModul:GetConf().nDefaultScore
	self.m_nScoreStamp = nScoreStamp
	self.m_nState =  gtPVPActivityRoleState.ePrepare   --准备、正常、战斗、进战保护、结束
	self.m_nBattleProtectTime = 0  --进战保护时长
	self.m_nStateChangeStamp = os.time()
	self.m_nLastQuickTeam = 0    --上一次快捷组队时间，有冷却时间
	self.m_bDelegate = false  --是否处于离线委托状态
	self.m_bLeave = false     --是否已离开
	self.m_nBattleCount = 0   --战斗次数
	self.m_nWinCount = 0      --胜利次数
	self.m_tBattleRecord = {} --{index:{nRoleID, ...}, ...}  --只保留最近5次匹配记录
	self.m_nUnionID = oRole:GetUnionID()
end

function CPVPActivityBaseRoleData:GetRoleID() return self.m_nRoleID end
function CPVPActivityBaseRoleData:GetSchool() return self.m_nSchoolID end
function CPVPActivityBaseRoleData:GetUnionID() return self.m_nUnionID end
function CPVPActivityBaseRoleData:GetLevel() return self.m_nLevel end
function CPVPActivityBaseRoleData:IsLeave() return self.m_bLeave end
function CPVPActivityBaseRoleData:GetScore() return self.m_nScore end
function CPVPActivityBaseRoleData:AddScore(nScore, nTimeStamp) 
	self.m_nScore = math.max(self.m_nScore + nScore, 0) 
	self.m_nScoreStamp = nTimeStamp or os.time()
end
function CPVPActivityBaseRoleData:SetScoreZere(nTimeStamp)
	--大于0才设置，防止，玩家正常战斗结束已设置，这里重复设置，导致刷新时间戳
	if self.m_nScore > 0 then 
		self.m_nScore = 0
		self.m_nScoreStamp = nTimeStamp or os.time()
	end
end
function CPVPActivityBaseRoleData:CheckJoinBattle()
	if self.m_nState == gtPVPActivityRoleState.eNormal then
		return true
	end
	return false
end

--是否进战保护状态
function CPVPActivityBaseRoleData:IsBattleProtected()
	if self.m_nState == gtPVPActivityRoleState.eBattleProtected then
		return true
	end
	return false
end

--进战保护状态是否结束
function CPVPActivityBaseRoleData:CheckProtectedEnd(nTimeStamp)
	if self.m_nState ~= gtPVPActivityRoleState.eBattleProtected then
		return true
	end
	if self.m_nStateChangeStamp + self.m_nBattleProtectTime <= nTimeStamp then
		return true
	end
	return false
end

--进战保护倒计时
function CPVPActivityBaseRoleData:GetBattleProtectedCountdown(nTimeStamp)
	local nCountdown = 0
	if not nTimeStamp then
		nTimeStamp = os.time()
	end
	if self.m_nState == gtPVPActivityRoleState.eBattleProtected then
		local nEndTime = self.m_nStateChangeStamp + self.m_nBattleProtectTime
		if nEndTime > nTimeStamp then
			nCountdown = nEndTime - nTimeStamp
		end
	end
	return nCountdown
end

--快捷组队冷却时间
function CPVPActivityBaseRoleData:GetQuickTeamCircleTime() return 60 end

--获取快捷组队倒计时
function CPVPActivityBaseRoleData:GetQuickTeamCountdown(nTimeStamp)
	local nCountdown = 0
	if not nTimeStamp then
		nTimeStamp = os.time()
	end
	local nNextTime = self.m_nLastQuickTeam + self:GetQuickTeamCircleTime()
	if nNextTime > nTimeStamp then
		nCountdown = nNextTime - nTimeStamp
	end
	return nCountdown
end

--是否活跃状态(没退场或状态没结束)
function CPVPActivityBaseRoleData:IsActive()
	if self.m_nState == gtPVPActivityRoleState.eEnd or self.m_bLeave then
		return false
	end
	return true
end

--获取进战保护结束时间
function CPVPActivityBaseRoleData:GetNextBattleTime()
	if self.m_nState == gtPVPActivityRoleState.eBattleProtected then
		return self.m_nStateChangeStamp + self.m_nBattleProtectTime
	end
	return
end

function CPVPActivityBaseRoleData:GetState() return self.m_nState end
function CPVPActivityBaseRoleData:SetState(nState, nBattleProtectTime) 
	if self.m_nState == nState then
		return
	end
	if not nBattleProtectTime then
		nBattleProtectTime = 0
	end
	if nState ~= gtPVPActivityRoleState.eBattleProtected then
		nBattleProtectTime = 0
	end
	self.m_nStateChangeStamp = os.time()
	self.m_nState = nState 
	self.m_nBattleProtectTime = nBattleProtectTime

	if not self.m_bLeave then
		self.m_oModul:BroadcastRoleState(self)
	end
end

function CPVPActivityBaseRoleData:AddBattleCount(bWin)
	self.m_nBattleCount = self.m_nBattleCount + 1
	if bWin then
		self.m_nWinCount = self.m_nWinCount + 1
	end
end

function CPVPActivityBaseRoleData:GetRankData()
	local tRankData = {}
	tRankData.nRoleID = self.m_nRoleID
	tRankData.sName = self.m_sName
	tRankData.nSchoolID = self.m_nSchoolID
	tRankData.nLevel = self.m_nLevel
	tRankData.nScore = self.m_nScore
	tRankData.nTimeStamp = self.m_nScoreStamp
	tRankData.nWinCount = self.m_nWinCount
	tRankData.nUnionID = self.m_nUnionID
	return tRankData
end

--============================================================
function CPVPActivityBase:Ctor(oModul, nActivityID, nSceneID, nOpenTime, nEndTime, nPrepareLastTime)
	assert(oModul and nActivityID > 0 and nSceneID > 0 and nOpenTime and nEndTime, "参数错误")
	assert(os.time() <= nEndTime, "活动时间不正确, 当前时间:"..os.time()..", 结束时间:"..nEndTime)
	self.m_oModul = oModul
	self.m_nActivityID = nActivityID     --活动ID
	local tConf = ctPVPActivityConf[nActivityID]
	assert(tConf, "配置不存在")
	self.m_nType = tConf.nActivityType   --活动类型
	--self.m_nSubType = 0           --活动子类型
	local oScene = goPVPActivityMgr:CreatePVPActivityScene(nSceneID, self)
	assert(oScene, "创建场景失败")
	self.m_nSceneMixID = oScene:GetMixID() --改为保存ID，具体对象引用，场景管理模块统一管理，比较安全
	self.m_tRoleMap = {}    --{nRoleID : RoleData, ...}
	self.m_nJoinNum = 0 --参与人数
	self.m_nRoleNum = 0 --真实玩家人数
	self.m_nState = gtPVPActivityState.ePrepare
	self.m_nStateChangeStamp = os.time()
	--------------------------------------
	--开启和关闭时间，读取实例自己的，以方便GM通过命令开启和控制
	self.m_nOpenTime = nOpenTime -- or CDailyActivity:GetStartStamp(self:GetConf().nScheduleID)
	self.m_nEndTime = nEndTime -- or CDailyActivity:GetEndStamp(self:GetConf().nScheduleID)
	self.m_nPrepareLastTime = nPrepareLastTime or (10 * 60)
	--------------------------------------
	-- self.m_tKickList = {}     --{nRoleID:nKickStamp, ...}, 强制踢出场景列表
	self.m_nKickAllTimer = nil

	self.m_tKickRoleTimerMap = {}    --踢出玩家定时器列表, 销毁时需要主动清理下，否则某些情况下容易提示错误
	--------------------------------
	self.m_nMatchTimer = nil
	self.m_nMatchUnit = 100
	self.m_tMatchList = {}
	self.m_tMatchTeamMap = {}
	self.m_oMatcher = {}
	self.m_tPriorityMatch = {}   --优先匹配列表，存储上一轮未被匹配到的玩家
	--------------------------------
	--机器人管理数据
	self.m_tRobotMap = {}        --{nRobotID:oRobot, ...}
	setmetatable(self.m_tRobotMap, {__mode = "kv"}) --设置为虚表
	self.m_nRobotNum = 0 
	self.m_nLastAddStamp = os.time()
	-- self.m_tRobotMoveMap = {}
	-- self.m_nLastRobotMoveStamp = os.time()

	self.m_nLastRobotRandBattleStamp = os.time()
	--------------------------------
	self.m_oRank = self:CreateRankInst()

	self:GetScene():RegObjEnterCallback(function (oRole, bReconnect)
		self:OnRoleEnter(oRole, bReconnect)
	end)  --利用闭包注册回调
	self:GetScene():RegObjLeaveCallback(function (oRole, nBattleID)
		self:OnRoleLeave(oRole)
	end) 
	self:GetScene():RegObjDisconnectCallback(function (oRole)
		self:OnRoleDisconnect(oRole)
	end)
	self:GetScene():RegObjAfterEnterCallback(function (oRole)
		self:AfterRoleEnter(oRole)
	end)
	self:GetScene():RegObjBattleBeginCallback(function (oRole)
		self:OnRoleEnterBattle(oRole)
	end)
	self:GetScene():RegBattleEndCallback(function (oRole, tBTRes, tExtData) 
		self:OnRoleBattleEnd(oRole, tBTRes, tExtData)
	end)
	-- self:GetScene():RegObjReachTargetPosCallback(function (oRole) 
	-- 	self:OnReachTargetPos(oRole)
	-- end)

	--测试要求准备时间写死，创建时就检查下
	if self:CheckStart() then
		self:OnStart()
	end
end

function CPVPActivityBase:CreateRankInst()
	local fnRankCmp = function (tDataL, tDataR)  -- -1排前面, 1排后面
		if tDataL.nScore ~= tDataR.nScore then
			return tDataL.nScore > tDataR.nScore and -1 or 1
		end

		if tDataL.nScore > 0 then 
			if tDataL.nTimeStamp ~= tDataR.nTimeStamp then
				return tDataL.nTimeStamp < tDataR.nTimeStamp and -1 or 1
			end
		else
			--积分为小于等于0的，即输掉，退出比赛的，时间越早，排名越低
			if tDataL.nTimeStamp ~= tDataR.nTimeStamp then
				return tDataL.nTimeStamp > tDataR.nTimeStamp and -1 or 1
			end
		end

		if tDataL.nWinCount ~= tDataR.nWinCount then 
			return tDataL.nWinCount > tDataR.nWinCount and -1 or 1
		end

		if tDataL.nLevel ~= tDataR.nLevel then
			return tDataL.nLevel > tDataR.nLevel and -1 or 1
		end

		if tDataL.nRoleID ~= tDataR.nRoleID then 
			return tDataL.nRoleID < tDataR.nRoleID and -1 or 1
		end

		return 0
	end
	local oRank = CRBRank:new(fnRankCmp, nil, nil, nil, true) --CSkipList:new(fnRankCmp)
	return oRank
end

function CPVPActivityBase:UpdateRankData(oRoleData)
	--先删除再插入
	assert(oRoleData, "参数错误")
	local nRoleID = oRoleData:GetRoleID()
	assert(nRoleID > 0, "数据错误")
	-- if CUtil:IsRobot(nRoleID) then --机器人不参与排名
	-- 	return 
	-- end
	self.m_oRank:Remove(nRoleID)

	local tRankData = oRoleData:GetRankData()
	self.m_oRank:Insert(nRoleID, tRankData)
end

function CPVPActivityBase:GetRoleData(nRoleID)
	if nRoleID <= 0 then return end
	return self.m_tRoleMap[nRoleID]
end
function CPVPActivityBase:GetActivityID() return self.m_nActivityID end
function CPVPActivityBase:GetType() return self.m_nType end
--function CPVPActivityBase:GetSubType() return self.m_nSubType end
function CPVPActivityBase:GetSchoolID() return self.m_nSchoolID end
function CPVPActivityBase:GetState() return self.m_nState end
function CPVPActivityBase:SetState(nState) 
	if self.m_nState == nState then
		return
	end
	self.m_nState = nState 
	self.m_nStateChangeStamp = os.time()

	--更改玩家状态并同步
	local bSyncRole =  false
	local nRoleState = nil
	if self.m_nState == gtPVPActivityState.eStarted then
		bSyncRole = true
		nRoleState = gtPVPActivityRoleState.eNormal
	elseif self.m_nState == gtPVPActivityState.eEnd then
		bSyncRole = true
		nRoleState = gtPVPActivityRoleState.eEnd
	end
	if bSyncRole then
		for k, oRoleData in pairs(self.m_tRoleMap) do
			oRoleData:SetState(nRoleState)
			if not oRoleData.m_bDelegate and not oRoleData.m_bLeave then
				local oRole = goPlayerMgr:GetRoleByID(oRoleData:GetRoleID())
				if oRole then
					self:SyncRoleData(oRole)
				end
			end
		end
	end
end

function CPVPActivityBase:GetPrepareLastTime() return self.m_nPrepareLastTime end --获取准备时长

--测试要求把准备时间写死，那就写死吧
function CPVPActivityBase:GetPrepareCountdown() --获取准备状态倒计时
	local nCountdown = 0
	if self:GetState() == gtPVPActivityState.ePrepare then
		local nCurTime = os.time()
		--local nStartTime = self.m_nStateChangeStamp + self:GetPrepareLastTime()
		nStartTime = self:GetOpenTime() + self:GetPrepareLastTime()
		if nStartTime > nCurTime then
			nCountdown = nStartTime - nCurTime
		end
	end
	return nCountdown
end

function CPVPActivityBase:GetOpenTime()
	--return CDailyActivity:GetStartStamp(self:GetConf().nScheduleID)
	return self.m_nOpenTime
end

function CPVPActivityBase:GetEndTime()
	--return CDailyActivity:GetEndStamp(self:GetConf().nScheduleID)
	return self.m_nEndTime
end

function CPVPActivityBase:GetEndCountdown() --获取活动结束倒计时
	local nCountdown = 0
	if self:GetState() == gtPVPActivityState.eStarted then
		local nCurTime = os.time()
		local nEndTime = self:GetEndTime()
		if nEndTime > nCurTime then
			nCountdown = nEndTime - nCurTime
		end
	end
	return nCountdown
end

function CPVPActivityBase:GetStateCountdown()
	local nState = self:GetState()
	if nState == gtPVPActivityState.ePrepare then
		return self:GetPrepareCountdown()
	elseif nState == gtPVPActivityState.eStarted then
		return self:GetEndCountdown()
	else
		return 0
	end
end

function CPVPActivityBase:GetConf() return ctPVPActivityConf[self.m_nActivityID] end
function CPVPActivityBase:GetScene() return goDupMgr:GetDup(self.m_nSceneMixID) end --默认只有一个场景
function CPVPActivityBase:GetSceneMixID() return self.m_nSceneMixID end
function CPVPActivityBase:GetMixDupType(oRole) assert(false, "子类未实现") end  --玩法类型ID，用于快速组队
function CPVPActivityBase:GetDupTypeName(oRole) return self:GetConf().sActivityName end 
function CPVPActivityBase:GetBattleDupType() assert(false, "子类未实现") end
function CPVPActivityBase:IsAutoMatch()
	local tConf = self:GetConf()
	assert(tConf, "配置表不存在")
	return tConf.bAutoMatch
end
function CPVPActivityBase:GetMaxJoinNum()
	local tConf = self:GetConf()
	assert(tConf, "配置表不存在")
	return tConf.nMaxJoinNum
end

function CPVPActivityBase:GetRoleNum()
	return self.m_nRoleNum
end

function CPVPActivityBase:GetJoinNum()
	return self.m_nJoinNum
end

function CPVPActivityBase:GetNextOpenTime()
	return self.m_oModul:GetNextOpenTime()
end

function CPVPActivityBase:CheckPartnerPermit()
	local tConf = self:GetConf()
	assert(tConf, "配置表不存在")
	return tConf.bPartnerPermit
end

--检查是否可组队，true可组队，false不可组队
function CPVPActivityBase:CheckTeamPermit()
	local tConf = self:GetConf()
	assert(tConf, "配置表不存在")
	return tConf.bTeamPermit
end

function CPVPActivityBase:GetWinScore() 
	local tConf = self:GetConf()
	assert(tConf, "配置表不存在")
	return tConf.nWinScore
end
function CPVPActivityBase:GetFailScore()
	local tConf = self:GetConf()
	assert(tConf, "配置表不存在")
	return tConf.nFailScore
end

function CPVPActivityBase:IsPrepare()
	if self:GetState() == gtPVPActivityState.ePrepare then
		return true
	end
	return false
end

function CPVPActivityBase:IsStart()
	if self:GetState() == gtPVPActivityState.eStarted then
		return true
	end
	return false
end

function CPVPActivityBase:IsEnd()
	if self:GetState() == gtPVPActivityState.eEnd then
		return true
	end
	return false
end

function CPVPActivityBase:EnterReq(oRole) assert(false, "子类未实现") end

--直接结算单个玩家的匹配积分，队伍匹配积分直接计算队员匹配积分之和
function CPVPActivityBase:CalcMatchScore(nRoleID)
	assert(nRoleID and nRoleID > 0, "参数错误")
	local oRoleActivityData = self:GetRoleData(nRoleID)
	local nLevel = oRoleActivityData:GetLevel()
	local nScore = oRoleActivityData:GetScore()
	local nMatchScore = nLevel * 10 + nScore
	return nMatchScore
end

--玩家相互之间的匹配度
function CPVPActivityBase:CalcMatchVal(nRoleID, nTargetID)
	assert(nRoleID and nTargetID, "参数错误")
	local tMatchList = self.m_tMatchList
	assert(tMatchList, "匹配列表已被释放")
	local nRoleMatchScore = tMatchList[nRoleID].nMatchScore
	local nTargetMatchScore = tMatchList[nTargetID].nMatchScore

	local oRoleData = self:GetRoleData(nRoleID)
	--local oTargetData = self:GetRoleData(nTargetID)

	--匹配分数完全相等，则默认匹配度1000
	local nMatchVal = math.ceil(100000 / (math.abs(nRoleMatchScore - nTargetMatchScore)*0.2 + 100))
	--最近没有互相战斗过的，匹配度+500，最近战斗过的，匹配
	local nInterval = 1
	local bBattle = false
	for k = 1, #oRoleData.m_tBattleRecord do --简单判断最近是否战斗过，不考虑新加入队员并向新队员移交队长的情况
		local tBattleRecord = oRoleData.m_tBattleRecord[k]
		for _, nBattleRoleID in pairs(tBattleRecord) do
			if nBattleRoleID == nTargetID then
				bBattle = true
				break
			end
		end
		if bBattle then
			break
		end
		nInterval = nInterval + 1
	end
	nMatchVal = nMatchVal + 100 * (nInterval - 1)
	return nMatchVal
end

function CPVPActivityBase:BuildMatchPool()
	local tMatchList = {} --{nRoleID : {nMatchScore, {tRoleTeamData, ...}}}
	local tMatchTeamMap = {}   --{nTeamID : {nLeaderID = nLeaderID, tRoleList = {nRoleID, ...}}, ...}
	local nMatchUnit = self.m_nMatchUnit
	local oMatcher = CMatchHelper:new(nMatchUnit)

	--检查当前所有可匹配玩家
	--建立队伍tMatchTeamMap  {nTeamID : {nLeaderID = nRoleID, tRoleList = {RoldID, ...}}, ...}
	--是否在队伍中，不在队伍中，加入匹配桶
	--如果在队伍中，根据TeamID加入到tMatchTeamMap
	--迭代所有玩家列表	
	--根据tMatchTeamMap，计算队伍分数，以队长ID为key加入匹配桶
	--如果队员没处于离队状态，说明队长肯定是在当前场景内
	for nRoleID, oRoleData in pairs(self.m_tRoleMap) do
		local oRole = goPlayerMgr:GetRoleByID(nRoleID)
		if oRole then
			local nTeamID = oRole:GetTeamID()
			if nTeamID > 0 and not oRole:IsTeamLeave() then  --构建team map
				local tTeamData = tMatchTeamMap[nTeamID]
				if not tTeamData then
					tTeamData = {}
					tTeamData.nLeaderID = 0
					tTeamData.tRoleList = {}
					tMatchTeamMap[nTeamID] = tTeamData
				end
				if oRole:IsLeader() then
					tTeamData.nLeaderID = nRoleID
				end
				table.insert(tTeamData.tRoleList, nRoleID)
			else 
				--非组队玩家，直接加入匹配池
				if oRoleData:CheckJoinBattle() then
					local nMatchVal = self:CalcMatchScore(nRoleID)
					local tRoleTeamData = {
						nIndex = oRole:GetTeamIndex(), 
						bLeave = oRole:IsTeamLeave(),
						bRelease = false,
						nRoleID = nRoleID,
					}
					local tMatchData = {}
					tMatchData.nMatchScore = nMatchVal
					tMatchData.tTeamList = {}
					table.insert(tMatchData.tTeamList, tRoleTeamData)

					tMatchList[nRoleID] = tMatchData  --缓存到匹配列表
					oMatcher:UpdateValue(nRoleID, nMatchVal) --加入匹配池
				end
			end
		end
	end

	--统计Team Map，缓存到匹配列表并加入匹配池
	for nTeamID, tTeamData in pairs(tMatchTeamMap) do
		local bCanBattle = true
		for k, nRoleID in pairs(tTeamData.tRoleList) do
			local oTemp = self.m_tRoleMap[nRoleID]
			if not oTemp or not oTemp:CheckJoinBattle() then
				bCanBattle = false
				break
			end
		end

		if bCanBattle then
			local nTotalMatchVal = 0
			local tMatchData = {}
			tMatchData.tTeamList = {}
			for k, nRoleID in pairs(tTeamData.tRoleList) do
				local oRole = goPlayerMgr:GetRoleByID(nRoleID)
				if oRole then
					local nTeamIndex = oRole:GetTeamIndex() 
					if nTeamIndex < 1 or not oRole:IsLeader() then
						nTeamIndex = nTeamIndex > 1 and nTeamIndex or 2 --防止出现错误数据
					end
					if oRole:IsLeader() then 
						nTeamIndex = 1
					end

					local tRoleTeamData = {
						nIndex = nTeamIndex, 
						bLeave = oRole:IsTeamLeave(),
						bRelease = false,
						nRoleID = nRoleID,
					}

					--处理下队伍中的nIndex顺序
					if #(tMatchData.tTeamList) >= nTeamIndex - 1 then 
						table.insert(tMatchData.tTeamList, nTeamIndex, tRoleTeamData)
					else
						table.insert(tMatchData.tTeamList, tRoleTeamData)
					end
					nTotalMatchVal = nTotalMatchVal + self:CalcMatchScore(nRoleID)
				end
			end
			tMatchData.nMatchScore = nTotalMatchVal

			if tTeamData.nLeaderID > 0 and #(tMatchData.tTeamList) > 0 then 
				tMatchList[tTeamData.nLeaderID] = tMatchData  --以队长ID缓存到匹配列表
				oMatcher:UpdateValue(tTeamData.nLeaderID, nTotalMatchVal) --以队长ID加入匹配池
			end
		end
	end

	self.m_tMatchList = tMatchList
	self.m_tMatchTeamMap = tMatchTeamMap --结果缓存下，匹配的时候快速获取队友
	self.m_oMatcher = oMatcher	
end

--将nEnemyID玩家队伍中所有队员ID记录到 nRoleID玩家队伍中的所有玩家 的活动信息中
function CPVPActivityBase:RecordBattleInfo(nRoleID, nEnemyID)
	assert(nRoleID and nEnemyID, "参数错误")
	local tMatchTeamMap = self.m_tMatchTeamMap
	assert(tMatchTeamMap, "队伍匹配记录已释放！")	
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	local oEnemy = goPlayerMgr:GetRoleByID(nEnemyID)
	local nTeamID = oRole:GetTeamID()
	local nEnemyTeamID = oEnemy:GetTeamID()
	if nTeamID > 0 and tMatchTeamMap[nTeamID] and not oRole:IsTeamLeave() then --自己存在有效队伍
		local tMatchTeam = tMatchTeamMap[nTeamID]
		for k, nTempID in pairs(tMatchTeam.tRoleList) do
			local oRoleActivityData = self:GetRoleData(nTempID)
			if #oRoleActivityData.m_tBattleRecord >= 5 then
				table.remove(oRoleActivityData.m_tBattleRecord) --移除最后一个元素
			end
			local tRecord = {}
			if nEnemyTeamID > 0 and tMatchTeamMap[nEnemyTeamID] and not oEnemy:IsTeamLeave() then --敌方存在有效队伍
				local tEnemyMatchTeam = tMatchTeamMap[nEnemyTeamID]
				for _, nTempEnemy in pairs(tEnemyMatchTeam.tRoleList) do
					table.insert(tRecord, nTempEnemy)
				end
			else --敌方没有队伍
				table.insert(tRecord, nEnemyID)
			end
			table.insert(oRoleActivityData.m_tBattleRecord, 1, tRecord)
		end
	else  --自己没有队伍
		local oRoleActivityData = self:GetRoleData(nRoleID)
		if #oRoleActivityData.m_tBattleRecord >= 5 then
			table.remove(oRoleActivityData.m_tBattleRecord) --移除最后一个元素
		end
		local tRecord = {}
		if nEnemyTeamID > 0 and  tMatchTeamMap[nEnemyTeamID] and not oEnemy:IsTeamLeave() then --敌方存在有效队伍
			local tEnemyMatchTeam = tMatchTeamMap[nEnemyTeamID]
			for _, nTempEnemy in pairs(tEnemyMatchTeam.tRoleList) do
				table.insert(tRecord, nTempEnemy)
			end
		else  --敌方没有队伍
			table.insert(tRecord, nEnemyID)
		end
		table.insert(oRoleActivityData.m_tBattleRecord, 1, tRecord)
	end
end

function CPVPActivityBase:AutoMatch()
	if not self:IsStart() then
		return
	end
	--如果固定时间做匹配，不监听匹配相关数据，影响因子太多，数据不好维护
	--直接在匹配的时候，建匹配池进行匹配，不严格保证队伍数据的一致性，以当前逻辑服的数据为准
	self:BuildMatchPool()

	local tMatchList = self.m_tMatchList
	local tMatchTeamMap = self.m_tMatchTeamMap
	local oMatcher = self.m_oMatcher
	assert(tMatchList and tMatchTeamMap and oMatcher, "数据错误")

	local tBattleMatch = {} --{nRoleID : nRoleID, ...}
	--迭代整个匹配列表进行匹配
	local tMatchRecord = {}  --{nRoleID, ...}  匹配记录	
	local nMatchInterval = self.m_nMatchUnit * 5  --匹配浮动区间，默认可以匹配旁边各5个桶的玩家

	--对上一轮未被匹配到的玩家进行优先匹配
	for nRoleID, v in pairs(self.m_tPriorityMatch) do
		--需要满足当前是处于可匹配状态 --只检查当前未组队或者是队长的玩家
		--如果该玩家ID在tMatchList中，说明当前是队长，或者是单人或队伍中但暂离
		if tMatchList[nRoleID] and not tMatchRecord[nRoleID] then
			--强制至少匹配一个
			local nMatchScore = tMatchList[nRoleID].nMatchScore
			local tResult = oMatcher:MatchTarget({nRoleID}, 
												nMatchScore - nMatchInterval, 
												nMatchScore + nMatchInterval, 
												nMatchScore, 
												1,
												10)
			if tResult and #tResult > 0 then
				--local nTargetRoleID = tResult[math.random(1, #tResult)]
				local tMatchValList = {}
				for k, nTargetID in pairs(tResult) do
					local nMatchVal = self:CalcMatchVal(nRoleID, nTargetID) --计算玩家相互之间的匹配度
					tMatchValList[nTargetID] = nMatchVal
				end
				--找出匹配度最高的
				local nTargetRoleID = nil
				local nTempVal = nil
				for k, v in pairs(tMatchValList) do
					if not nTargetRoleID then
						nTargetRoleID = k
						nTempVal = v
					elseif nTempVal < v then
						nTargetRoleID = k
						nTempVal = v
					end
				end
				assert(nTargetRoleID and nTargetRoleID > 0, "匹配结果不正确")
				--互相记录战斗匹配信息
				self:RecordBattleInfo(nRoleID, nTargetRoleID)
				self:RecordBattleInfo(nTargetRoleID, nRoleID)

				tMatchRecord[nRoleID] = nRoleID  --加入到匹配记录中
				tMatchRecord[nTargetRoleID] = nTargetRoleID
				tBattleMatch[nRoleID] = nTargetRoleID

				oMatcher:Remove(nRoleID) --已匹配的从匹配池移除
				oMatcher:Remove(nTargetRoleID)
			end
		end
	end
	self.m_tPriorityMatch = {}  --清空旧的

	for nRoleID, tRoleMatchData in pairs(tMatchList) do
		local nMatchScore = tRoleMatchData.nMatchScore 
		--检查是否已匹配
		if not tMatchRecord[nRoleID] then
			local tResult = oMatcher:MatchTarget({nRoleID}, 
												nMatchScore - nMatchInterval, 
												nMatchScore + nMatchInterval, 
												nMatchScore, 
												0,
												10)
			if tResult and #tResult > 0 then
				--local nTargetRoleID = tResult[math.random(1, #tResult)]
				local tMatchValList = {}
				for k, nTargetID in pairs(tResult) do
					local nMatchVal = self:CalcMatchVal(nRoleID, nTargetID) --计算玩家相互之间的匹配度
					tMatchValList[nTargetID] = nMatchVal
				end
				--找出匹配度最高的
				local nTargetRoleID = nil
				local nTempVal = nil
				for k, v in pairs(tMatchValList) do
					if not nTargetRoleID then
						nTargetRoleID = k
						nTempVal = v
					elseif nTempVal < v then
						nTargetRoleID = k
						nTempVal = v
					end
				end
				assert(nTargetRoleID and nTargetRoleID > 0, "匹配结果不正确")
				--互相记录战斗匹配信息
				self:RecordBattleInfo(nRoleID, nTargetRoleID)
				self:RecordBattleInfo(nTargetRoleID, nRoleID)

				tMatchRecord[nRoleID] = nRoleID  --加入到匹配记录中
				tMatchRecord[nTargetRoleID] = nTargetRoleID
				tBattleMatch[nRoleID] = nTargetRoleID

				oMatcher:Remove(nRoleID) --已匹配的从匹配池移除
				oMatcher:Remove(nTargetRoleID)
			else
				--将未匹配到的玩家加入到优先匹配队列
				--在当前轮次匹配间隔中，可能发生队长转移或者队伍变更的问题
				--或者队伍战斗匹配有效性变化，比如队伍中存在进战保护的玩家
				--目前暂不考虑此类问题的处理
				local oRole = goPlayerMgr:GetRoleByID(nRoleID)
				local nTeamID = oRole:GetTeamID()
				if nTeamID > 0 and tMatchTeamMap[nTeamID] and not oRole:IsTeamLeave() then --自己存在有效队伍
					for k, nTempID in pairs(tMatchTeamMap[nTeamID].tRoleList) do
						self.m_tPriorityMatch[nTempID] = nTempID
					end
				else
					self.m_tPriorityMatch[nRoleID] = nRoleID
				end
			end
		end
	end

	for k, v in pairs(tBattleMatch) do
		local tTeamBattleList = self.m_tMatchList[k].tTeamList
		local tTarTeamBattleList = self.m_tMatchList[v].tTeamList
		assert(tTeamBattleList and #tTeamBattleList > 0)
		assert(tTarTeamBattleList and #tTarTeamBattleList > 0)
		local tAsyncData = {}
		tAsyncData.nActivityID = self:GetActivityID()
		tAsyncData.tTeamBattleList = tTeamBattleList
		tAsyncData.tTarTeamBattleList = tTarTeamBattleList
		local tExtData = {}
		tExtData.bPVPActivityBattle = true
		tExtData.tPVPActivityData = tAsyncData
		-- oRole:PVP(oEnemy, tExtData, not self:CheckPartnerPermit(), 30)
		--直接指定参战玩家，避免内部再次rpc查询队伍信息，特别是rpc期间，队伍数据可能发生变化，导致潜在异常
		goBattleMgr:PVPBySpecify(tTeamBattleList, tTarTeamBattleList, 
			tExtData, not self:CheckPartnerPermit(), 30)
	end

	--[[
	for k, v in pairs(self.m_tPriorityMatch) do
		local oRole = goPlayerMgr:GetRoleByID(k)
		if oRole then
			oRole:Tips("当前轮次未匹配到对手")
		end
	end
	]]

	--匹配完成，将资源释放
	self.m_tMatchList = nil
	self.m_tMatchTeamMap = nil
	self.m_oMatcher = nil
end

--广播场景状态
function CPVPActivityBase:BroadcastRoleState(oRoleData)
	assert(oRoleData, "参数错误")
	local nRoleID = oRoleData:GetRoleID()
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then
		return
	end
	local tBroadcastMsg = {}
	tBroadcastMsg.nAOIID = oRole:GetAOIID()
	tBroadcastMsg.nState = oRoleData:GetState()
    self:GetScene():BroadcastObserver(oRole:GetAOIID(), "PVPActivityRoleStateChangeViewRet", tBroadcastMsg)
end

--对参与活动玩家广播消息
function CPVPActivityBase:BroadcastActivityInfo()
	for k, oRoleData in pairs(self.m_tRoleMap) do
		if not oRoleData.m_bDelegate and not oRoleData.m_bLeave then
			local oRole = goPlayerMgr:GetRoleByID(oRoleData.m_nRoleID)
			if oRole then
				self:SyncPVPActivityInfo(oRole)
			end
		end
	end
end

--当活动开始
function CPVPActivityBase:OnStart()
	print("活动状态切换 准备 -> 开始, 活动ID:"..self:GetActivityID())
	--如果是系统匹配模式，注册匹配定时器
	if self:IsAutoMatch() then
		self.m_nMatchTimer = GetGModule("TimerMgr"):Interval(gnPVPActivityAutoMatchInterval, function () self:AutoMatch() end)
	end
	self:SetState(gtPVPActivityState.eStarted)
	--通知活动内玩家，活动正式开始
	self:BroadcastActivityInfo()
end

function CPVPActivityBase:CheckStart(nTimeStamp)
	if not nTimeStamp then
		nTimeStamp = os.time()
	end
	if self.m_nState == gtPVPActivityState.eStarted then
		return true
	end
	if self.m_nState == gtPVPActivityState.ePrepare then
		--[[
		if (self.m_nStateChangeStamp + self:GetPrepareLastTime()) <= nTimeStamp then
			return true
		end
		]]
		--准备时间，测试要求写死
		if (self:GetOpenTime() + self:GetPrepareLastTime()) <= nTimeStamp then
			return true
		end
	end
	return false
end

function CPVPActivityBase:CheckTimeEnd(nTimeStamp)
	if not nTimeStamp then
		nTimeStamp = os.time()
	end
	if self.m_nState == gtPVPActivityState.eEnd then
		return true
	end
	if self.m_nState == gtPVPActivityState.eStarted then
		if self:GetEndTime() <= nTimeStamp then
			return true
		end
	end
	return false
end

--检查活动是否结束
function CPVPActivityBase:CheckEnd()
	if not self:IsStart() then --只有当前活动处于已开始状态，才有检查结束的必要性
		return false
	end
	local bEnd = self:CheckTimeEnd()
	if bEnd then
		return true
	end
	local nActiveNum = 0
	local nTotalNum = 0
	for k, oRoleData in pairs(self.m_tRoleMap) do
		if oRoleData:IsActive() then
			nActiveNum = nActiveNum + 1
		end
		nTotalNum = nTotalNum + 1
	end
	if nActiveNum <= math.ceil(nTotalNum / 10) then
		bEnd = true
	end
	return bEnd
end

--踢出玩家
function CPVPActivityBase:KickRole(nRoleID)
	local oRoleData = self:GetRoleData(nRoleID)
	if oRoleData then 
		oRoleData:SetState(gtPVPActivityRoleState.eEnd)
	end
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then
		return
	end

	if oRole:IsRobot() then 
		--机器人被移除，会自动退出队伍
		goLRobotMgr:RemoveRobot(oRole:GetID())
		return 
	end
	--不论是否在队伍，都通知移除队伍
	local fnCallBack = function ()
		if oRoleData and not oRoleData.m_bLeave then --玩家在此期间，可能已经主动离开了场景
			oRole:EnterLastCity()
		end
	end
	Network:RMCall("KickFromTeamReq", fnCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nRoleID)
end

function CPVPActivityBase:GetRankRewardList(nRank) --注意，奖励可能不存在，即返回nil或者 <= 0的情况
	assert(nRank > 0, "参数错误")
	local tRewardPoolList = goRankRewardCfg:GetRankReward(self:GetConf().nRankAward, nRank)
	return tRewardPoolList
end

function CPVPActivityBase:GetRankAppellation(nRank)
	if not nRank or nRank < 1 then 
		return 0
	end
	local tTarCfg = goRankRewardCfg:GetRankRewardConf(self:GetConf().nRankAward, nRank)
	if not tTarCfg then 
		return 0
	end
	return tTarCfg.nAppellation
end

function CPVPActivityBase:AddRankReward()
	--通过邮件，给所有玩家发送奖励，因为很多玩家已不在当前逻辑服了，甚至下线了
	local sMailContentTemplate = "此次%s活动，您的排名第%d，这是此次活动的奖励"
	local sPVPActName= self:GetConf().sActivityName
	local sMailTitle = sPVPActName
	local nNextOpenTime = self:GetNextOpenTime()
	local fnTraverseCallback = function(nDataIndex, nRank, nRoleID, tData) 
		local oRoleData = self:GetRoleData(nRoleID)
		if oRoleData and oRoleData.m_nBattleCount >= 3 and not CUtil:IsRobot(nRoleID) then --大于等于3次才发送奖励
			if nRank and nRank > 0 then
				local tRewardPoolList = self:GetRankRewardList(nRank) --可能不存在奖励
				if tRewardPoolList and #tRewardPoolList > 0 then
					local sMailContent = string.format(sMailContentTemplate, sPVPActName, nRank)
					goRewardLaunch:MailLaunch(nRoleID, oRoleData.m_nServer, tRewardPoolList, 
						oRoleData.m_nLevel, oRoleData.m_nRoleConfID, "PVP活动排行榜奖励",
						sMailTitle, sMailContent)
				end
				
				--发放称号
				local nAppellation = self:GetRankAppellation(nRank)
				if nAppellation and nAppellation > 0 then 
					local tAppeParam = {}
					tAppeParam.nExpiryTime = math.max(nNextOpenTime - 5, 0)
					if self:GetActivityID() == 1001 then 
						local sSchoolName = gtSchoolName[oRoleData:GetSchool()]
						assert(sSchoolName)
						tAppeParam.tNameParam = {sSchoolName}
					end
					local tAppeData = 
					{
						nOpType = gtAppellationOpType.eAdd, 
						nConfID = nAppellation, 
						tParam = tAppeParam, 
						nSubKey = 0,
					}

					local oRole = goPlayerMgr:GetRoleByID(nRoleID)
					if oRole then 
						oRole:AppellationUpdate(tAppeData)
					else
						Network:RMCall("AppellationUpdateReq", nil, gnWorldServerID, 
							goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nRoleID, tAppeData)
					end
				end
			else
				LuaTrace("玩家排行榜数据异常，无法获取到排名，nRoleID:"..nRoleID)
			end
		end
	end

	self.m_oRank:TraverseByDataIndex(1, self.m_oRank:GetCount(), fnTraverseCallback)
end

function CPVPActivityBase:CleanAllBattle()
	local tRemoveRecord = {}
	for k, tRoleData in pairs(self.m_tRoleMap) do 
		if not tRoleData.m_bLeave then 
			local nRoleID = tRoleData:GetRoleID()
			local oRole = goPlayerMgr:GetRoleByID(nRoleID)
			if oRole and oRole:IsInBattle() then 
				local nBattleID = oRole:GetBattleID()
				local oBattle = goBattleMgr:GetBattle(nBattleID)
				if oBattle and oBattle:IsPVP() and not tRemoveRecord[nBattleID] then 
					tRemoveRecord[nBattleID] = true
					oBattle:ForceFinish()
				end
			end
		end
	end
end

--当活动结束
function CPVPActivityBase:OnEnd()
	print("活动结束, 活动ID:"..self:GetActivityID())
	if self.m_nMatchTimer then --这里可以直接停止匹配计时器了
		GetGModule("TimerMgr"):Clear(self.m_nMatchTimer)
		self.m_nMatchTimer = nil
	end
	self:SetState(gtPVPActivityState.eEnd)
	self:CleanAllBattle()
	self:BroadcastActivityInfo()
	--将战斗中的人员都强制结束战斗，并且通知所有参与人员，活动已结束
	self:AddRankReward()
	self.m_nKickAllTimer = GetGModule("TimerMgr"):Interval(60, function () self:KickAllRole() end)
end

function CPVPActivityBase:KickAllRole()
	if self.m_nKickAllTimer then
		GetGModule("TimerMgr"):Clear(self.m_nKickAllTimer)
		self.m_nKickAllTimer = nil
	end
	--踢出所有未离开场景玩家
	local tKickList = {}  --防止回调修改self.m_tRoleMap
	for nRoleID, oRoleData in pairs(self.m_tRoleMap) do
		if not oRoleData.m_bLeave then
			table.insert(tKickList, nRoleID)
		end
	end
	for k, nRoleID in ipairs(tKickList) do 
		self:KickRole(nRoleID)
	end
end

--实例被销毁，清理资源
function CPVPActivityBase:Release()
	--已经开始，但是状态未置为结束，可能是时间到，被外部管理器强制释放
	if self.m_nMatchTimer then
		GetGModule("TimerMgr"):Clear(self.m_nMatchTimer)
		self.m_nMatchTimer = nil
	end
	for nTimerID, _ in pairs(self.m_tKickRoleTimerMap) do 
		GetGModule("TimerMgr"):Clear(nTimerID)
	end
	self.m_tKickRoleTimerMap = {}
	self:CleanAllBattle()
	self:KickAllRole()
	goPVPActivityMgr:RemovePVPActivityScene(self:GetSceneMixID())
	self.m_nSceneMixID = nil
end

--玩家断开连接
function CPVPActivityBase:OnRoleDisconnect(oRole)
	assert(oRole, "参数错误")
	local nRoleID = oRole:GetID()
	local oRoleData = self:GetRoleData(nRoleID)
	if oRoleData then
		oRoleData.m_bDelegate = true
	else
		print("数据错误，玩家离线，无法找到玩家活动数据, nRoleID:"..nRoleID)
	end
end

--玩家入场  --断线重连(非重新登录，离线保护状态)，也会调用到
function CPVPActivityBase:OnRoleEnter(oRole, bReconnect)
	assert(oRole, "数据错误")
	local nRoleID = oRole:GetID()
	local bPrepare = self:IsPrepare()
	local oRoleData = self:GetRoleData(nRoleID)
	if not bPrepare and not bReconnect then 
		if not oRoleData then --如果存在oRoleData，可能是战斗结束返回来的
			print("活动非准备状态:<"..self:GetState()..">, 玩家<"..nRoleID..">进入活动场景")
		end
		return
	end
	if bPrepare then
		if oRoleData then --已经存在，不处理
			return
		end
		--所有的活动数据对象，都在这里插入管理
		local nScoreStamp = os.time()
		if self:GetType() == gtPVPActivityType.eQimaiArena then 
			nScoreStamp = self.m_nOpenTime
		end
		oRoleData = CPVPActivityBaseRoleData:new(self, oRole, nScoreStamp)
		self.m_tRoleMap[nRoleID] = oRoleData
		self.m_nJoinNum = self.m_nJoinNum + 1

		if not oRole:IsRobot() then 
			self.m_nRoleNum = self.m_nRoleNum + 1
		end
		self:UpdateRankData(oRoleData)
	else
		if not oRoleData then
			print("数据错误，非重连非准备期间，玩家进入场景，无法找到玩家活动数据, nRoleID:"..nRoleID)
		else
			oRoleData.m_bDelegate = false
		end
	end
end

function CPVPActivityBase:AfterRoleEnter(oRole)
	assert(oRole, "数据错误")	
	local nRoleID = oRole:GetID()
	local oRoleData = self:GetRoleData(nRoleID) --场景进入时，会插入RoleData
	if not oRoleData or oRoleData.m_bLeave then --不存在或者本次活动已结束参与，移除出场景
		oRole:Tips("当前无法进入活动场景")
		if oRole:IsRobot() then 
			LuaTrace("机器人进入场景数据错误")
			LuaTrace(debug.traceback())
		end
		self:KickRole(nRoleID)
		print("已将玩家踢出当前场景, nRoleID:"..nRoleID)
		return
	end
	self:SyncPVPActivityInfo(oRole)
	self:SyncRoleData(oRole)
	if oRole:IsRobot() then 
		self.m_tRobotMap[nRoleID] = oRole
		self.m_nRobotNum = self.m_nRobotNum + 1 

		goLRobotMgr:RegMove(oRole:GetID())
		Network:RMCall("RobotJoinTeamMatchReq", nil, gnWorldServerID, 
			goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nRoleID, self:GetMixDupType())
	end

	--如果当前参与人数超过总数量限制，踢出机器人
	local nMaxJoinNum = self:GetMaxJoinNum()
	local nJoinNum = self:GetJoinNum()
	local nRobotNum = self:GetRobotNum()
	if nMaxJoinNum < nJoinNum and nRobotNum > 0 then 
		print(">>>>>>> 人数过多 触发踢出机器人 <<<<<<<<")
		local nKickNum = math.min(nJoinNum - nMaxJoinNum, nRobotNum)
		--只有几百个数据，直接迭代，暂时不考虑优化
		local tKickList, tKickIndex = CUtil:RandDiffNum(1, nRobotNum, nKickNum)
		local nCount = 1
		tKickList = {}
		for nRobotID, oTempRobot in pairs(self.m_tRobotMap) do 
			if tKickIndex[nCount] then 
				table.insert(tKickList, nRobotID)
			end
			nCount = nCount + 1
		end
		for _, nRobotID in ipairs(tKickList) do 
			self:KickRole(nRobotID)
		end
	end
end

--进入战斗回调
function CPVPActivityBase:OnRoleEnterBattle(oRole)
	assert(oRole, "参数错误")
	local nRoleID = oRole:GetID()
	local oRoleData = self:GetRoleData(nRoleID)
	assert(oRoleData, "数据错误")
	oRoleData:SetState(gtPVPActivityRoleState.eBattle)
end

--玩家离场
function CPVPActivityBase:OnRoleLeave(oRole)
	--可能场景销毁引发的回调，如果场景销毁时，玩家正好在战斗中
	--可能是进入战斗回调，暂时离开
	local nRoleID = oRole:GetID()
	-- local bBattle = oRole:IsInBattle()
	-- if bBattle then
	-- 	--[[ --角色进入战斗后，会发起一次离开场景请求
	-- 	--状态切换放在此处，防止出现队伍数据一致性问题，及玩家状态切换问题
	-- 	self:OnRoleEnterBattle(oRole) ]]
	-- 	return
	-- end
	local oRoleData = self:GetRoleData(nRoleID)
	if oRoleData then
		--玩家真正离开
		local nMixDupType = self:GetMixDupType(oRole)
		local sDupTypeName = self:GetDupTypeName(oRole)
		oRole:CancelMatchTeam(nMixDupType, sDupTypeName)
		
		oRoleData.m_bLeave = true --标记已离开
		oRoleData:SetState(gtPVPActivityRoleState.eEnd)
		oRoleData:SetScoreZere() --积分清零
		self:UpdateRankData(oRoleData)
		if self:IsPrepare() then --如果当前未开始，则将角色数据清除掉
			self.m_oRank:Remove(nRoleID)
			self.m_tRoleMap[nRoleID] = nil
			self.m_nJoinNum = math.max(self.m_nJoinNum - 1, 0)
			if not oRole:IsRobot() then 
				self.m_nRoleNum = math.max(self.m_nRoleNum - 1, 0)
			end
		end
		if oRole:IsRobot() then 
			self.m_nRobotNum = math.max(self.m_nRobotNum - 1, 0)
			self.m_tRobotMap[nRoleID] = nil
			if oRole:IsOnline() then 
				if gbInnerServer then 
					assert(false, "代码错误")
				else
					LuaTrace("请检查代码, 机器人离开PVP场景时，处于在线状态，异常离开或者离线流程逻辑错误")
					LuaTrace(debug.traceback())
				end
			end
			Network:RMCall("RobotCancelTeamMatchReq", nil, gnWorldServerID, 
				goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nRoleID, self:GetMixDupType())
		end
	else		
		print("不在活动列表中的玩家发起<离开场景>请求，nRoleID:"..nRoleID)
	end
    --将角色的当前场景记录数据更改为最后进入的主场景，防止登录时再次进入，导致数据错误
    local tCurrDup = oRole:GetCurrDup()
    local tLastDup = oRole:GetLastDup()
    tCurrDup[1], tCurrDup[2], tCurrDup[3], tCurrDup[4] = tLastDup[1], tLastDup[2], tLastDup[3], tLastDup[4]
    print("离开PVP活动场景，修改玩家当前场景为最后主城")
    oRole:MarkDirty(true)
end

--根据战斗结果发放奖励
function CPVPActivityBase:AddRewardByBattleResult(oRole, bWin, nEnemyNum)
	assert(oRole and nEnemyNum > 0, "参数错误")
	local nRoleID = oRole:GetID()
	local tRoleData = self:GetRoleData(nRoleID)
	assert(tRoleData, "玩家数据错误")
	if tRoleData.m_nWinCount > 10 then --胜利10次，不再获得奖励
		return
	end

	local nRoleLevel = oRole:GetLevel()
	local oBattlePet = oRole.m_oPet:GetCombatPet()
	local nPetLevel = 0
	if oBattlePet then
		nPetLevel = oBattlePet.nPetLv
	end

	local tRewardConf = nil
	local nRoleExp = 0
	local nPetExp = 0
	local nSilverCoinNum = 0
	local nArenaCoin = 0
	local sReason = nil
	if bWin then
		local tConf = self:GetConf()
		tRewardConf = tConf.tWinAward
		nRoleExp = tConf.fnWinRoleExp(nRoleLevel)
		if oBattlePet then
			nPetExp = tConf.fnWinPetExp(nPetLevel)
		end
		nSilverCoinNum = tConf.nWinSilverCoin
		nArenaCoin = math.floor(tConf.nWinPvpPoints(nEnemyNum))
		sReason = "PVP活动战斗胜利"
	else
		local tConf = self:GetConf()
		tRewardConf = tConf.tFailAward
		nRoleExp = tConf.fnFailRoleExp(nRoleLevel)
		if oBattlePet then
			nPetExp = tConf.fnFailPetExp(nPetLevel)
		end
		nSilverCoinNum = tConf.nFailSilverCoin
		nArenaCoin = math.floor(tConf.nFailPvpPoints(nEnemyNum))
		sReason = "PVP活动战斗失败"
	end

	--添加奖励	
	if nRoleExp ~= 0 then
		oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, sReason)
	end
	if nPetExp ~= 0 and oBattlePet then
		oRole.m_oPet:AddExp(nPetExp)
	end
	if nSilverCoinNum > 0 then
		oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nSilverCoinNum, sReason)
	end
	if nArenaCoin > 0 then 
		oRole:AddItem(gtItemType.eCurr, gtCurrType.eArenaCoin, nArenaCoin, sReason)
	end

	local tRewardPoolList = {}
	for k, v in pairs(tRewardConf) do
		for i, nPoolID in pairs(v) do
			if nPoolID > 0 then
				table.insert(tRewardPoolList, nPoolID)
			end
		end
	end
	if #tRewardPoolList > 0 then
		goRewardLaunch:LaunchList(oRole, tRewardPoolList, sReason)
	end
end

function CPVPActivityBase:GetPVPActivityProtectTime(bWin)
	local tConf = self:GetConf()
	return bWin and tConf.nWinWaitTime or tConf.nFailedWaitTime
end

function CPVPActivityBase:GetEnemyNumByBattleExtData(nRoleID, tExtData)
	local nEnemyNum = 0
	local tTeamBattleList = tExtData.tPVPActivityData.tTeamBattleList
	local tTarTeamBattleList = tExtData.tPVPActivityData.tTarTeamBattleList
	for k, tRoleTeamData in pairs(tTeamBattleList) do
		if tRoleTeamData.nRoleID == nRoleID then 
			nEnemyNum = #tTarTeamBattleList
			break
		end
	end
	if nEnemyNum < 1 then 
		for k, tRoleTeamData in pairs(tTarTeamBattleList) do
			if tRoleTeamData.nRoleID == nRoleID then 
				nEnemyNum = #tTeamBattleList
				break
			end
		end
	end

	return nEnemyNum > 0 and nEnemyNum or 1
end

--玩家战斗回调
function CPVPActivityBase:OnRoleBattleEnd(oRole, tBTRes, tExtData)
	--活动已结束，不处理，可能是活动结束，强制战斗结束回调过来的
	if self.m_nState == gtPVPActivityState.eEnd or gbServerClosing then 
		return 
	end
	assert(oRole, "参数错误")
	local nRoleID = oRole:GetID()
	local oRoleData = self:GetRoleData(nRoleID)
	if not oRoleData then 
		return 
	end
	if not self:IsStart() then --活动已结束，本次结果无效，无需处理
		return
	end
	local nEnemyNum = self:GetEnemyNumByBattleExtData(nRoleID, tExtData)

	--当前逃跑是当错战斗失败处理
	local bWin = tBTRes.bWin
	local nEndTime = tBTRes.nEndTime or os.time()
	if bWin then
		oRoleData:AddScore(self:GetWinScore(), nEndTime)
		local nProtectTime = self:GetPVPActivityProtectTime(bWin)
		oRoleData:SetState(gtPVPActivityRoleState.eBattleProtected, nProtectTime)
	else
		oRoleData:AddScore(self:GetFailScore(), nEndTime)
		local nProtectTime = self:GetPVPActivityProtectTime(bWin)
		oRoleData:SetState(gtPVPActivityRoleState.eBattleProtected, nProtectTime)
	end

	if oRoleData:GetScore() <= 0 then
		oRoleData:SetState(gtPVPActivityRoleState.eEnd)
		oRole:Tips("您的积分不足，失去参战资格。请下次努力") --可能正在过图
		local nKickTimerID = GetGModule("TimerMgr"):Interval(3, function (nTimerID) 
			GetGModule("TimerMgr"):Clear(nTimerID)
			self.m_tKickRoleTimerMap[nTimerID] = nil
			self:KickRole(nRoleID)
		end)
		self.m_tKickRoleTimerMap[nKickTimerID] = nRoleID
	end	

	oRoleData:AddBattleCount(bWin)
	self:UpdateRankData(oRoleData)
	self:AddRewardByBattleResult(oRole, bWin, nEnemyNum)

	if not oRoleData.m_bDelegate then
		self:SyncRoleData(oRole)
	end	
	self:SyncPVPActivityInfo(oRole)
end

-- function CPVPActivityBase:TickKickList(nTimeStamp)
-- 	nTimeStamp = nTimeStamp or os.time()
-- 	local tTempList = {}
-- 	for nRoleID, nKickStamp in pairs(self.m_tKickList) do 
-- 		if math.abs(nTimeStamp - nKickStamp) >= 3 then 
-- 			local oRoleData = self:GetRoleData(nRoleID)
-- 			if not oRoleData or not oRoleData.m_bLeave then --可能玩家主动提前离场了
-- 				self:KickRole(nRoleID)
-- 				table.insert(tTempList, nRoleID)
-- 			end
-- 		end
-- 	end
-- 	for k, nRoleID in pairs(tTempList) do 
-- 		self.m_tKickList[nRoleID] = nil
-- 	end
-- end

--外层调用，除了活动开启实例创建、活动结束调用销毁，其他事件，由实例自己管理控制进度
function CPVPActivityBase:Tick(nTimeStamp)
	nTimeStamp = nTimeStamp or os.time()

	if not self:IsEnd() then --未结束的情况，检查结束，这个优先级最高
		local bEnd = self:CheckEnd()
		if bEnd then
			self:OnEnd()
			return
		end
		-- self:RobotMove()
	end

	if self:IsPrepare() then
		if self:CheckStart() then
			self:OnStart()
		end
		self:TickAddRobot(nTimeStamp)
	elseif self:IsStart() then
		--检查更新玩家状态
		-- self:TickKickList(nTimeStamp)
		for k, oRoleData in pairs(self.m_tRoleMap) do
			--如果是准备状态，则切换回正常状态，并通知场景其他玩家
			if oRoleData:IsBattleProtected() then
				if oRoleData:GetBattleProtectedCountdown(nTimeStamp) <= 0 then
					oRoleData:SetState(gtPVPActivityRoleState.eNormal)
				end
			end
		end
		self:RobotBattle()
	elseif self:IsEnd() then
		-- do something
		return
	else
		--不正确的状态
		return
	end

end

--快捷组队请求
function CPVPActivityBase:QuickMatchTeamReq(oRole)
	assert(oRole, "参数错误")
	if not self:CheckTeamPermit() then
		oRole:Tips("当前活动不允许组队")
		return
	end
	local nRoleID = oRole:GetID()
	local oRoleData = self:GetRoleData(nRoleID)
	if not oRoleData then 
		oRole:Tips("请先参与该活动")
		return
	end
	local nCountDown = oRoleData:GetQuickTeamCountdown()
	if nCountDown > 0 then 
		local nMinu = math.floor(nCountDown / 60)
		local nSec = nCountDown % 60
		if nMinu > 0 then 
			oRole:Tips(string.format("便捷组队冷却中，请%d分%d秒后再申请", nMinu, nSec))
		elseif nSec > 0 then 
			oRole:Tips(string.format("便捷组队冷却中，请%d秒后再申请", nSec))
		end
		return
	end
	oRoleData.m_nLastQuickTeam = os.time()
	local nMixDupType = self:GetMixDupType(oRole)
	local sDupTypeName = self:GetDupTypeName(oRole)
	oRole:MatchTeam(nMixDupType, sDupTypeName, true)
	self:SyncRoleData(oRole)
end

function CPVPActivityBase:CancelMatchTeamReq(oRole)
	assert(oRole, "参数错误")
	if not oRole:CheckTeamOp() then
		oRole:Tips("请让队长来修改匹配状态")
		return
	end
	local nMixDupType = self:GetMixDupType(oRole)
	local sDupTypeName = self:GetDupTypeName(oRole)
	oRole:CancelMatchTeam(nMixDupType, sDupTypeName)
	self:SyncRoleData(oRole)
end

function CPVPActivityBase:ValidBattle(oRole,nEnemyID)
	return true
end

function CPVPActivityBase:BattleReq(oRole, nEnemyID)
	assert(oRole and nEnemyID > 0, "参数错误")
	local nRoleID = oRole:GetID()
	if not self:ValidBattle(oRole,nEnemyID) then
		return
	end
	if nRoleID == nEnemyID then
		oRole:Tips("不能对自己发起战斗！")
		return
	end
	local oRoleData = self:GetRoleData(nRoleID)
	if not oRoleData then --玩家数据不存在，将玩家移除出场景
		print("不在活动列表中的玩家发起活动战斗请求，nRoleID:"..nRoleID)
		oRole:EnterLastCity()
		return
	end
	local oEnemy = goPlayerMgr:GetRoleByID(nEnemyID)
	if not oEnemy then
		print("请求对不在活动列表中的玩家发起战斗，nRoleID:"..nRoleID..", nEnemyID:"..nEnemyID)
		oRole:Tips("目标数据不正确")
		return
	end
	local oEnemyData = self:GetRoleData(nEnemyID)
	if not oEnemyData then
		oRole:Tips("非法请求")
		return
	end

	if not self:IsStart() then --活动未开始或已结束，不响应
		oRole:Tips("活动未开始")
		return
	end
	if self:IsAutoMatch() then
		oRole:Tips("当前活动只能通过系统匹配进行战斗")
		return
	end
	local nTeamID = oRole:GetTeamID()
	if not oRole:CheckTeamOp() then 
		oRole:Tips("只有队长才能发起战斗")
		return 
	end

	local nEnemyTeamID = oEnemy:GetTeamID()
	if nTeamID > 0 and nTeamID == nEnemyTeamID then
		--任意一个暂离状态，可以发起战斗
		if not oRole:IsTeamLeave() and not oEnemy:IsTeamLeave() then 
			oRole:Tips("不能对自己队伍发起战斗")
			return
		end
	end
	-----------------------------------
	local oRoleActivityData = self:GetRoleData(oRole:GetID())
	assert(oRoleActivityData, "数据错误")
	if not oRoleActivityData:CheckJoinBattle() then
		if oRoleActivityData:IsBattleProtected() then 
			local nWaitTime = oRoleActivityData:GetBattleProtectedCountdown()
			if nWaitTime > 0 then 
				local sTipsContent = string.format("当前处于战斗保护状态，还需等待%s秒", nWaitTime)
				oRole:Tips(sTipsContent)
				return
			end
		end
		oRole:Tips("当前处于战斗保护状态，无法发起挑战")
		return
	end
	-----------------------------------
	tRoleList = {oRole:GetID(), nEnemyID}

	--前置检查以逻辑服数据为准
	local fnTeamQueryCallback = function (tTeamDataList)
		-- assert(tTeamDataList and (#tTeamDataList) == 2, "参数错误")
		if not tTeamDataList or #tTeamDataList ~= 2 then 
			return 
		end
		local tRoleTeamData = tTeamDataList[1]
		local tEnemyTeamData = tTeamDataList[2]
		assert(tRoleTeamData[1] and tEnemyTeamData[1])
		--检查是否未离队，如果未离队，则该玩家肯定未队长或者队长也在场景中,rpc期间，发生了队长转换
		--检查未暂离的玩家，是否都可以参战
		--检查目标玩家是否在队伍
		--如果目标玩家在队伍，检查是否暂离状态
		--如果非暂离状态，则检查目标玩家非暂离状态队友是否都可以参战
		--以上检查都通过，则开始进入战斗


		--检查发起方状态是否正确
		local bRoleSingle = false
		local tTeamBattleList = {}
		if tRoleTeamData[2] > 0 then
			local bLeave = false
			local tTempData = nil
			for k, tTeamData in ipairs(tRoleTeamData[3]) do 
				if tTeamData.nRoleID == nRoleID then 
					bLeave = tTeamData.bLeave
					if not bLeave and k ~= 1 then --rpc期间，队长发生变化
						oRole:Tips("不是队长，无法发起挑战，请先离队")
						return 
					end
					tTempData = table.DeepCopy(tTeamData)
				end
				if not tTeamData.bLeave then 
					table.insert(tTeamBattleList, tTeamData)
				end
			end
			if bLeave then 
				bRoleSingle = true
				tTempData.bLeave = false  --会影响进战战斗数据生成
				tTeamBattleList = {tTempData}
			end
		else
			local tTeamData = {
				nIndex = oRole:GetTeamIndex(), 
				bLeave = false,
				bRelease = false,
				nRoleID = nRoleID,
			}
			tTeamBattleList = {tTeamData}
			bRoleSingle = true 
		end

		if not bRoleSingle then 
			local bValid = true
			local nMaxWaitTime = 0
			if not bLeave then 
				for k, tTeamData in ipairs(tTeamBattleList) do 
					local oRoleActivityData = self:GetRoleData(tTeamData.nRoleID)
					assert(oRoleActivityData, "数据错误")
					if not oRoleActivityData:CheckJoinBattle() then
						bValid = false
						if oRoleActivityData:IsBattleProtected() then --其他异常情况或状态，不关心
							local nTemp = oRoleActivityData:GetBattleProtectedCountdown()
							if nTemp > nMaxWaitTime then 
								nMaxWaitTime = nTemp
							end
						end
					end
				end
			end
			if not bValid then 
				--取队伍成员时间最长的那个
				if nMaxWaitTime > 0 then 
					local sTipsContent = string.format("队伍状态未恢复，还需等待%s秒", nMaxWaitTime)
					oRole:Tips(sTipsContent) --只提示队长即可
				end
				return 
			end
		else --单人
			local oRoleActivityData = self:GetRoleData(nRoleID)
			assert(oRoleActivityData, "数据错误")
			if not oRoleActivityData:CheckJoinBattle() then
				if oRoleActivityData:IsBattleProtected() then 
					local nWaitTime = oRoleActivityData:GetBattleProtectedCountdown()
					if nWaitTime > 0 then 
						local sTipsContent = string.format("当前处于战斗保护状态，还需等待%s秒", nWaitTime)
						oRole:Tips(sTipsContent)
					end
				end
				return
			end
		end

		--检查对手状态是否正确
		local bTarSingle = false
		local tTarTeamData = nil
		local tTarTeamBattleList = {}
		local nTarTeamLeaderID = 0
		if tEnemyTeamData[2] > 0 then 
			local bLeave = false
			local tTempData = nil
			nTarTeamLeaderID = tEnemyTeamData[3][1].nRoleID
			for k, tTeamData in ipairs(tEnemyTeamData[3]) do 
				if tTeamData.nRoleID == nEnemyID then 
					tTarTeamData = tTeamData
					bLeave = tTeamData.bLeave
					tTempData = table.DeepCopy(tTeamData)
				end
				if not tTeamData.bLeave then 
					table.insert(tTarTeamBattleList, tTeamData)
				end
			end
			if bLeave then 
				bTarSingle = true
				tTempData.bLeave = false --会影响进战战斗数据生成
				tTarTeamBattleList = {tTempData}
			end
		else
			local tTeamData = {
				nIndex = oEnemy:GetTeamIndex(), 
				bLeave = false,
				bRelease = false,
				nRoleID = nEnemyID,
			}
			tTarTeamBattleList = {tTeamData}
			bTarSingle = true 
		end

		if not bTarSingle then --敌人处于队伍并且未暂离
			local bValid = true
			local nMaxWaitTime = 0
			assert(nTarTeamLeaderID > 0)
			--将对手转换为目标队伍队长，否则，如果是对目标队伍队员发起战斗，战斗处理中，会报错
			oEnemy = goPlayerMgr:GetRoleByID(nTarTeamLeaderID) 
			if not bLeave then 
				for k, tTeamData in ipairs(tTarTeamBattleList) do 
					local oRoleActivityData = self:GetRoleData(tTeamData.nRoleID)
					assert(oRoleActivityData, "数据错误")
					if not oRoleActivityData:CheckJoinBattle() then
						bValid = false
						if oRoleActivityData:IsBattleProtected() then --其他异常情况或状态，不关心
							local nTemp = oRoleActivityData:GetBattleProtectedCountdown()
							if nTemp > nMaxWaitTime then 
								nMaxWaitTime = nTemp
							end
						elseif oRoleActivityData:GetState() == gtPVPActivityRoleState.eBattle then 
							oRole:Tips("对方处于战斗状态，请挑战其他玩家")
							return 
						end
					end
				end
			end
			if not bValid then 
				--取队伍成员时间最长的那个
				if nMaxWaitTime > 0 then 
					local sTipsContent = string.format("对方队伍状态未恢复，请等待%s秒后再发起挑战", nMaxWaitTime)
					oRole:Tips(sTipsContent) --只提示队长即可
				end
				return 
			end
		else --敌人处于单人或者队伍暂离状态
			local oRoleActivityData = self:GetRoleData(nEnemyID)
			assert(oRoleActivityData, "数据错误")
			if not oRoleActivityData:CheckJoinBattle() then
				if oRoleActivityData:IsBattleProtected() then 
					local nWaitTime = oRoleActivityData:GetBattleProtectedCountdown()
					if nWaitTime > 0 then 
						local sTipsContent = string.format("对方处于战斗保护状态，请等待%s秒后再发起挑战", nWaitTime)
						oRole:Tips(sTipsContent)
					end
				elseif oRoleActivityData:GetState() == gtPVPActivityRoleState.eBattle then 
					oRole:Tips("对方处于战斗状态，请挑战其他玩家")
					return 
				end
				return
			end 
		end
		if oRole:GetID() == oEnemy:GetID() then  --再次检查下，防止逻辑错误问题
			oRole:Tips("不能对自己队伍发起战斗")
			return 
		end

		assert(#tTeamBattleList > 0 and #tTarTeamBattleList > 0, "逻辑错误") 

		--所有检查通过
		local tAsyncData = {}
		tAsyncData.nActivityID = self:GetActivityID()
		tAsyncData.tTeamBattleList = tTeamBattleList
		tAsyncData.tTarTeamBattleList = tTarTeamBattleList
		local tExtData = {}
		tExtData.bPVPActivityBattle = true
		tExtData.tPVPActivityData = tAsyncData
		-- oRole:PVP(oEnemy, tExtData, not self:CheckPartnerPermit(), 30)
		--直接指定参战玩家，避免内部再次rpc查询队伍信息，特别是rpc期间，队伍数据可能发生变化，导致潜在异常
		goBattleMgr:PVPBySpecify(tTeamBattleList, tTarTeamBattleList, 
			tExtData, not self:CheckPartnerPermit(), 30)
	end	

	CPVPActivityBase:TeamListBattleInfoReq(tRoleList, fnTeamQueryCallback)
end

function CPVPActivityBase:TeamListBattleInfoReq(tRoleList, fnCallBack)
	assert(tRoleList and fnCallBack and #tRoleList > 0, "参数错误")
	Network:RMCall("TeamListBattleInfoReq", fnCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, tRoleList)
end

--同步活动数据
function CPVPActivityBase:SyncPVPActivityInfo(oRole)
	assert(oRole, "参数错误")
	local tRetData = {}
	tRetData.nActivityID = self:GetActivityID()
	tRetData.nState = self:GetState()
	tRetData.nStateCountdown = self:GetStateCountdown()
	tRetData.bQuickMatchTeam = self:CheckTeamPermit()
	tRetData.bAutoMatchBattle = self:IsAutoMatch()
	oRole:SendMsg("PVPActivityInfoRet", tRetData)
end

--同步玩家活动数据
function CPVPActivityBase:SyncRoleData(oRole)
	assert(oRole, "参数错误")
	local nRoleID = oRole:GetID()
	local oRoleData = self:GetRoleData(nRoleID)
	assert(oRoleData, "当前玩家不在活动场景")

	local tRetData = {}
	tRetData.nActivityID = self:GetActivityID()
	tRetData.nScore = oRoleData:GetScore()
	tRetData.nState = oRoleData:GetState()
	tRetData.nStateCountdown = oRoleData:GetBattleProtectedCountdown()
	tRetData.nQuickTeamCountdown = oRoleData:GetQuickTeamCountdown()
	tRetData.nBattleCount = oRoleData.m_nBattleCount
	tRetData.nWinCount = oRoleData.m_nWinCount
	tRetData.nRank = self.m_oRank:GetRankByKey(nRoleID)
	oRole:SendMsg("PVPActivityRoleDataRet", tRetData)
end

function CPVPActivityBase:GetPBRankDataByRank(nRoleID, nRank)
	assert(nRoleID > 0 and nRank > 0, "参数错误")
	local oRoleData = self:GetRoleData(nRoleID)
	assert(oRoleData, "数据错误")

	local tRetData = {}
	tRetData.nRoleID = nRoleID
	tRetData.sRoleName = oRoleData.m_sName
	tRetData.nLevel = oRoleData:GetLevel()
	tRetData.nSchool = oRoleData.m_nSchoolID
	tRetData.nScore = oRoleData:GetScore()
	tRetData.nRank = nRank
	return tRetData
end

--同步排行榜数据
function CPVPActivityBase:SyncRankData(oRole, nPageNum) --排行榜数据分页，前端根据需要，按照分页获取，每次携带玩家自己的数据及当前排行榜总数据
	--没有参与活动，不响应
	assert(oRole and nPageNum > 0, "参数错误")
	local oRoleActivityData = self:GetRoleData(oRole:GetID())
	if not oRoleActivityData then
		print("玩家未参与活动,请求排行榜, nRoleID:"..nRoleID..", nActivityID:"..self:GetActivityID())
		return
	end

	local nRoleID = oRole:GetID()
	local nPageDataNum = 30 --每页数量
	local nRankTotalNum = self.m_oRank:GetCount()
	local nMaxPageNum = math.ceil(nRankTotalNum / nPageDataNum)
	local tRetData = {}
	tRetData.nActivityID = self:GetActivityID()
	tRetData.nMaxPageNum = nMaxPageNum
	tRetData.nPageNum = nPageNum
	tRetData.tRankPageData = {}

	local fnTraverseCallback = function(nDataIndex, nRank, nRoleID, tData) 
		local tPBRankData = self:GetPBRankDataByRank(nRoleID, nRank)
		table.insert(tRetData.tRankPageData, tPBRankData)
	end

	if nMaxPageNum > 0 then
		local nStartDataIndex = nPageDataNum * (nPageNum - 1) + 1
		if nStartDataIndex > nRankTotalNum then 
			oRole:Tips("没有更多数据") 
			return 
		end
		local nEndDataIndex = math.min(nPageDataNum * nPageNum, nRankTotalNum)
		self.m_oRank:TraverseByDataIndex(nStartDataIndex, nEndDataIndex, fnTraverseCallback)
	end	
	local nSelfRank = self.m_oRank:GetRankByKey(nRoleID)
	local tSelfRankData = self:GetPBRankDataByRank(nRoleID, nSelfRank)
	tRetData.tRoleRank = tSelfRankData

	oRole:SendMsg("PVPActivityRankDataRet", tRetData)
end

function CPVPActivityBase:EnterCheckReq(nRoleID,...)
	return true
end

function CPVPActivityBase:GetRobotNum() 
	return self.m_nRobotNum
end

function CPVPActivityBase:TickAddRobot(nTimeStamp) 
	if not self:IsPrepare() then 
		return 
	end
	if self:GetMaxJoinNum() <= self:GetJoinNum() then 
		return 
	end
	local tActConf = self:GetConf()
	local nTarRobotNum = tActConf.nRobotNum or 0
	if nTarRobotNum <= 0 or self:GetRobotNum() >= nTarRobotNum then 
		return 
	end
	local nPrepareTime = self:GetPrepareLastTime()
	if nPrepareTime <= 10 then 
		return 
	end

	if self:GetPrepareCountdown() <= 10 then 
		return 
	end

	local nInterval = 3
	if math.abs(nTimeStamp - self.m_nLastAddStamp) < nInterval then 
		return 
	end 
	print(string.format("活动(%s), 当前机器人数量(%d)", self:GetDupTypeName(), self:GetRobotNum()))
	local nTimes = math.max(math.floor((nPrepareTime - 10) / nInterval), 1)
	local nAddCount = math.min(math.ceil(nTarRobotNum / nTimes), nTarRobotNum - self:GetRobotNum())
	self:AddRobot(nAddCount)

	self.m_nLastAddStamp = nTimeStamp
end

function CPVPActivityBase:AddRobot(nNum) 
	if nNum <= 0 then 
		return 
	end
	local nLimitNum = 30
	if nNum > nLimitNum then 
		LuaTrace(string.format("活动(%d)单次创建机器人数量(%d)过多, 限定值(%d)", 
			self:GetActivityID(), nNum, nLimitNum))
		nNum = nLimitNum
	end
	local tActConf = self:GetConf()
	local nMinLevel = tActConf.nLimitLevel

	local tServerList = {}

	if gnServerID == gnWorldServerID then 
		local tServerMap = goServerMgr:GetServerMap()
		for nServerID, v in pairs(tServerMap) do 
			if CUtil:GetMaxRoleLevelByServer(nServerID) >= nMinLevel then 
				table.insert(tServerList, nServerID)
			end
		end
	else
		local nServerLevel = goServerMgr:GetServerLevel(gnServerID)
		if CUtil:GetMaxRoleLevelByServer(nServerID) >= nMinLevel then 
			table.insert(tServerList, gnServerID)
		end
	end
	if #tServerList <= 0 then 
		return 
	end

	local tRoleConfID = {}
	if self:GetBattleDupType() == gtBattleDupType.eSchoolArena then 
		local nSchoolID = self:GetSchoolID()
		for nRoleConfID, tConf in pairs(ctRoleInitConf) do 
			if tConf.nSchool == nSchoolID then
				table.insert(tRoleConfID, nRoleConfID)
			end
		end
	end
	local tRobotCreateList = {}
	for k = 1, nNum do 
		local nTarServer = tServerList[math.random(#tServerList)]
		local nServerLevel = goServerMgr:GetServerLevel(nTarServer)
		local nMaxLevel = math.min(math.max(nMinLevel, CUtil:GetMaxRoleLevelByServer(nTarServer)),
			#ctRoleLevelConf)

		local tParam = {}
		tParam.nMinLevel = nMinLevel
		tParam.nMaxLevel = nMaxLevel
		tParam.nServer = nTarServer
		tParam.nDupMixID = self:GetSceneMixID()
		tParam.tRoleConfID= table.DeepCopy(tRoleConfID)
		assert(tParam.nDupMixID)

		table.insert(tRobotCreateList, tParam)
	end

	Network:RMCall("PVPActCreateRobotReq", nil, gnWorldServerID, 
		goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, tRobotCreateList)
	print("添加机器人AddRobot", nNum)
end

-- function CPVPActivityBase:RobotMove()
-- 	local nCurStamp = os.time()
-- 	if math.abs(nCurStamp - self.m_nLastRobotMoveStamp) < 3 then 
-- 		return 
-- 	end
-- 	self.m_nLastRobotMoveStamp = nCurStamp

-- 	local tRunSet = {}
--     for nRobotID, oRobot in pairs(self.m_tRobotMap) do 
-- 		if oRobot and not oRobot:IsInBattle() then 
-- 			if oRobot:CheckTeamOp() and not self.m_tRobotMoveMap[oRobot:GetID()] then 
-- 				table.insert(tRunSet, oRobot:GetID())
-- 			end
-- 		end
-- 	end
-- 	local nSetNum = #tRunSet
--     if nSetNum < 1 then 
--         return 
-- 	end

-- 	local nDupMixID = self:GetSceneMixID()
-- 	local nDupID = CUtil:GetDupID(nDupMixID)
-- 	local tDupConf = ctDupConf[nDupID]
-- 	assert(tDupConf)

-- 	local nMoveSpeed = gtGDef.tConst.nRobotMoveSpeed
-- 	assert(nMoveSpeed > 0)

-- 	local nMoveCount = math.random(1, math.ceil(nSetNum/3))
-- 	local tRandList = CUtil:RandDiffNum(1, nSetNum, nMoveCount)
-- 	for _, nRandIndex in ipairs(tRandList) do 
-- 		local nRobotID = tRunSet[nRandIndex]
-- 		local oRobot = goPlayerMgr:GetRoleByID(nRobotID)
--         if oRobot and oRobot:GetNativeObj() and oRobot:GetAOIID() > 0 then 
--             local nXPosMin = math.min(tDupConf.nWidth, 100)  --避免地图长宽不足100的异常情况
--             local nXPosMax = math.max(nXPosMin, tDupConf.nWidth - 100)
--             local nYPosMin = math.min(tDupConf.nHeight, 100)
--             local nYPosMax = math.max(nYPosMin, tDupConf.nHeight - 100)
--             if not (nXPosMin == nXPosMax and nYPosMin == nYPosMax) then 
--                 local nXPos = math.random(nXPosMin, nXPosMax)
--                 local nYPos = math.random(nYPosMin, nYPosMax)
--                 oRobot:RunTo(nXPos, nYPos, nMoveSpeed)
--                 self.m_tRobotMoveMap[oRobot:GetID()] = nCurStamp
--             end
--         end
-- 	end

-- 	--清理旧的异常数据
-- 	local tRemoveList = {}
-- 	for nRobotID, nTempTimeStamp in pairs(self.m_tRobotMoveMap) do 
-- 		if math.abs(nCurStamp - nTempTimeStamp) > 30 then 
-- 			table.insert(tRemoveList, nRobotID) 
-- 		end
-- 	end
-- 	for k, nRobotID in ipairs(tRemoveList) do 
--         self.m_tRobotMoveMap[nRobotID] = nil
-- 		local oRobot = goPlayerMgr:GetRoleByID(nRobotID)
-- 		--可能直接离线被踢出去了当前不存在此对象了，或者已离开场景了
--         if oRobot and oRobot:GetNativeObj() and oRobot:GetAOIID() > 0 then 
--             oRobot:StopRun()
--         end
--     end
-- end

-- function CPVPActivityBase:OnReachTargetPos(oRole)
-- 	if not oRole or not oRole:IsRobot() then 
-- 		return 
-- 	end
-- 	self.m_tRobotMoveMap[oRole:GetID()] = nil
-- end

function CPVPActivityBase:RobotBattle()
	if self:IsAutoMatch() or not self:IsStart() or self:GetRobotNum() <= 0 then 
		return 
	end
	if self:GetStateCountdown() < 30 then --最后半分钟不匹配了，没啥意义
		return 
	end

	local nTimeStamp = os.time()
	local nInterval = 20
	if math.abs(nTimeStamp - self.m_nLastRobotRandBattleStamp) < nInterval then 
		return 
	end
	self.m_nLastRobotRandBattleStamp = nTimeStamp
	print(">>>>>>>> PVP活动机器人战斗匹配 <<<<<<<")

	local tRobotAttackMap = {}
	for nRobotID, oRobot in pairs(self.m_tRobotMap) do 
		--筛选当前为队长或者暂离或者非队伍状态的机器人
		if oRobot:IsOnline() and oRobot:CheckTeamOp() and not oRobot:IsInBattle() then 
			local tRobotData = self:GetRoleData(nRobotID)
			if tRobotData and tRobotData:CheckJoinBattle() then 
				tRobotAttackMap[nRobotID] = oRobot
			end
		end
	end

	local oDup = self:GetScene()
	local tRecordList = {}  --已经匹配进战的
	for nRobotID, oRobot in pairs(tRobotAttackMap) do 
		if not tRecordList[nRobotID] then 
			local tObserved = oDup:GetAreaObserveds(oRobot:GetAOIID(), gtGDef.tObjType.eRole)
			local tMatchSet = {}
			for _, oNativeRole in ipairs(tObserved) do 
				local oTempRole = GetLuaObjByNativeObj(oNativeRole)
				--只针对队长或者暂离的队员或者非队伍玩家发起攻击, 简化逻辑, 坑太多
				if oTempRole and oTempRole:CheckTeamOp() and not oTempRole:IsInBattle() and oTempRole:GetID() ~= nRobotID then 
					local tRoleData = self:GetRoleData(nRobotID)
					if tRoleData and tRoleData:CheckJoinBattle() then 
						table.insert(tMatchSet, oTempRole)
					end
				end
			end

			local oTarRole = nil
			if #tMatchSet > 0 then 
				oTarRole = tMatchSet[math.random(#tMatchSet)]
			end

			if oTarRole then
				if oTarRole:IsRobot() then 
					tRecordList[oTarRole:GetID()] = true
				end
				tRecordList[nRobotID] = true
				--进入战斗可能会失败 oTarRole的非暂离队伍成员可能不满足战斗条件
				print(string.format("机器人(%d)(%s) 匹配玩家 (%d)(%s) 发起战斗请求", 
					nRobotID, oRobot:GetName(), oTarRole:GetID(), oTarRole:GetName()))
				self:BattleReq(oRobot, oTarRole:GetID())
			end
		end
	end
end

