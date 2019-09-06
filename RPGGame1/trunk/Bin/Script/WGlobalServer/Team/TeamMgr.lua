--队伍管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CTeamMgr:Ctor()
	self.m_nAutoID = 0
	self.m_tTeamMap = {}

	--不保存
	self.m_tDirtyMap = {} 		--脏队伍列表
	self.m_tDeleteMap = {} 		--删除队伍列表
	self.m_nSaveTick = nil 		--定时保存计时器
	self.m_tRoleTeamMap = {}	--玩家所在队伍映射

	--匹配
	-- self.m_tMatchMap = {} 		--匹配管理{[nGameType]={},...}
	self.m_tMatchMgr = CTeamMatchMgr:new()
end

function CTeamMgr:Release()
	self:GetMatchMgr():Release()
	GetGModule("TimerMgr"):Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil
	self:SaveData()
end

function CTeamMgr:LoadData()
	print("加载队伍数据")
	local oDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())

	local sData = oDB:HGet(gtDBDef.sTeamEtcDB, "data")
	local tData = sData == "" and {} or cseri.decode(sData)
	self.m_nAutoID = tData.m_nAutoID or self.m_nAutoID

	local tKeys = oDB:HKeys(gtDBDef.sTeamDB)
	for _, sKey in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sTeamDB, sKey)
		local oTeam = CTeam:new(self, tonumber(sKey))
		oTeam:LoadData(cseri.decode(sData))
		if oTeam:GetMembers() > 0 then 
			self.m_tTeamMap[oTeam:GetID()] = oTeam

			for _, tRole in ipairs(oTeam:GetRoleList()) do
				self.m_tRoleTeamMap[tRole.nRoleID] = oTeam
			end
		else
			--目前不影响其他系统，而且其他系统可能未加载，不通知
			self.m_tDeleteMap[oTeam:GetID()] = true 
		end
	end

	self:OnLoaded()
	self:GetMatchMgr():Init()
end

function CTeamMgr:OnLoaded()
	self.m_nSaveTick = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
end

function CTeamMgr:SaveData()
	print("保存队伍数据")
	local oDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	for nTeamID, _ in pairs(self.m_tDirtyMap) do
		local oTeam = self:GetTeamByID(nTeamID)
		if oTeam then
			local tData = oTeam:SaveData()
			oDB:HSet(gtDBDef.sTeamDB, nTeamID, cseri.encode(tData))
			self.m_tDirtyMap[nTeamID] = nil
		end
		if nTeamID == 0 then
			local tEctData = {m_nAutoID=self.m_nAutoID}
			oDB:HSet(gtDBDef.sTeamEtcDB, "data", cseri.encode(tEctData))
			self.m_tDirtyMap[0] = nil
		end
	end

	for nTeamID, _ in pairs(self.m_tDeleteMap)do
		oDB:HDel(gtDBDef.sTeamDB, nTeamID)
		self.m_tDeleteMap[nTeamID] = nil
	end
end

--@nTeamID 0表示杂项
function CTeamMgr:MarkDirty(nTeamID, bDirty)
	assert(nTeamID and bDirty ~= nil)
	if not bDirty then
		self.m_tDirtyMap[nTeamID] = nil
	else
		self.m_tDirtyMap[nTeamID] = true
	end
end

function CTeamMgr:GetMatchMgr() return self.m_tMatchMgr end

--bAll 如果在队伍，是否更新整个队伍成员的队伍数据
function CTeamMgr:SyncTeamCache(nRoleID, bAll)
	assert(nRoleID and nRoleID > 0)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then 
		return 
	end
	local oTeam = self:GetTeamByRoleID(nRoleID)
	if oTeam then
		if bAll then 
			oTeam:SyncLogicCache()
		else 
			oTeam:SyncLogicCache(nRoleID)
		end
	else
		local tData = 
		{
			m_nTeamID=0, 
			m_bLeader=false, 
			m_bTeamLeave = true, 
			m_nTeamIndex = 0, 
			m_nTeamNum = 0,
			m_tTeamList = {}, 
		}
		Network:RMCall("RoleUpdateReq", nil, oRole:GetStayServer(), oRole:GetLogic(), 
			oRole:GetSession(), oRole:GetServer(), nRoleID, tData)
	end
end

--更新队伍跟随
--@bTeamDismiss 是否队伍解散
function CTeamMgr:UpdateTeamFollow(oTeam, bTeamDismiss)
	local tRoleList = oTeam:GetRoleList()
	if #tRoleList <= 0 then
		return
	end
	if bTeamDismiss then
		for nIndex, tRole in ipairs(tRoleList) do
			local oTmpRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
			Network:RMCall("SetFollowReq", nil, oTmpRole:GetStayServer(), oTmpRole:GetLogic(), oTmpRole:GetSession(), oTmpRole:GetMixObjID(), {})
		end
		return
	end

	local tLeader = oTeam:GetLeader()
	local oLeaderRole = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)

	local tFollowList = {}
	for nIndex, tRole in ipairs(tRoleList) do
		if tRole.nRoleID ~= tLeader.nRoleID then
			local oTmpRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
			if oTmpRole then
				Network:RMCall("SetFollowReq", nil, oTmpRole:GetStayServer(), oTmpRole:GetLogic(), oTmpRole:GetSession(), oTmpRole:GetMixObjID(), {})
				if not tRole.bLeave then
					table.insert(tFollowList, oTmpRole:GetMixObjID())
				end
			end
		end
	end
	Network:RMCall("SetFollowReq", nil, oLeaderRole:GetStayServer(), oLeaderRole:GetLogic(), oLeaderRole:GetSession(), oLeaderRole:GetMixObjID(), tFollowList)
end

--解散队伍事件
function CTeamMgr:OnTeamDismiss(oTeam)
	if oTeam:GetMembers() > 0 then 
		LuaTrace("调用错误，队伍非空情况下，触发了队伍解散事件")
		LuaTrace(debug.traceback())
		self:UpdateTeamFollow(oTeam, true) --更新队伍

		local tRoleList = oTeam:GetRoleList()	
		for _, tRole in ipairs(tRoleList) do
			self:OnRoleQuit(tRole.nRoleID, true)
		end
	end

	local nTeamID = oTeam:GetID()
	self:GetMatchMgr():OnTeamDismiss(nTeamID)
	oTeam:Release()

	self.m_tTeamMap[nTeamID] = nil
	self.m_tDeleteMap[nTeamID] = true
	self:MarkDirty(nTeamID, false)
	print(string.format("CTeamMgr:OnTeamDismiss, 队伍(%d)解散", nTeamID))
end

--角色退出队伍事件
function CTeamMgr:OnRoleQuit(nRoleID)
	local oTeam = self.m_tRoleTeamMap[nRoleID] 
	self.m_tRoleTeamMap[nRoleID] = nil
	self:SyncTeamCache(nRoleID)
	oTeam:SyncLogicCache()

	--解除自己跟随
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	Network:RMCall("SetFollowReq", nil, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetMixObjID(), {})
	--更新队伍跟随
	self:UpdateTeamFollow(oTeam)

	self:GetMatchMgr():OnRoleQuitTeam(nRoleID, oTeam:GetID())
end

--角色加入事件
function CTeamMgr:OnRoleJoin(nRoleID, oTeam)
	self.m_tRoleTeamMap[nRoleID] = oTeam
	-- self:SyncTeamCache(nRoleID)
	oTeam:SyncLogicCache()
	self:UpdateTeamFollow(oTeam) --更新队伍跟随
	self:GetMatchMgr():OnRoleJoinTeam(nRoleID, oTeam:GetID())

	local bCreate = false
	local bLeader = oTeam:IsLeader(nRoleID)
	if oTeam:GetMembers() <= 1 and bLeader then 
		bCreate = true
	end

	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if bCreate then 
		goTalk:SendTeamMsg(oRole, "创建队伍成功", true)
		oRole:Tips("创建队伍成功")
	else
		local sTeamContent = string.format("%s加入了队伍", oRole:GetFormattedName())
		goTalk:SendTeamMsg(oRole, sTeamContent, true, {nRoleID})
		local tSessionList = oTeam:GetSessionList({nRoleID})
		if tSessionList and #tSessionList > 0 then 
			Network.PBBroadcastExter("FloatTipsRet", tSessionList, {sCont = sTeamContent})
		end
		local oLeader = goGPlayerMgr:GetRoleByID(oTeam:GetLeader().nRoleID)
		if oLeader then 
			local sContent = string.format("欢迎加入%s的队伍", oLeader:GetFormattedName())
			oRole:Tips(sContent)
			goTalk:SendTeamMsgToRole(oRole, sContent, true, nRoleID)
		end
	end
end

function CTeamMgr:OnNameChange(oRole)
	if not oRole then return end
	local oTeam = self:GetTeamByRoleID(oRole:GetID())
	if not oTeam then 
		return 
	end
	oTeam:OnNameChange(oRole)
end

--生成队伍ID
function CTeamMgr:GenID()
	self.m_nAutoID = self.m_nAutoID or 0	
	self.m_nAutoID = self.m_nAutoID%0x7FFFFFFF+1
	self:MarkDirty(0, true)
	return self.m_nAutoID
end

--创建队伍
function CTeamMgr:CreateTeam(nRoleID)
	if self:GetTeamByRoleID(nRoleID) then
		return LuaTrace("已有队伍", nRoleID)
	end
	local nTeamID = self:GenID()
	if self.m_tTeamMap[nTeamID] then
		return LuaTrace("队伍ID冲突", nRoleID, nTeamID)
	end
	local oTeam = CTeam:new(self, nTeamID)
	self.m_tTeamMap[nTeamID] = oTeam  --先关联，再加入，否则加入回调事件中，如果根据ID查找，会有问题
	if not oTeam:Join(nRoleID, true) then 
		self.m_tTeamMap[nTeamID] = nil
		return
	end
	self:MarkDirty(nTeamID, true)
	return oTeam
end


--创建队伍请求
function CTeamMgr:CreateTeamReq(oRole)
	local nRoleID = oRole:GetID()
	if self:GetTeamByRoleID(nRoleID) then
		return oRole:Tips("已有队伍")
	end
	local bPermit, sReason = CTeam:CheckSceneJoinTeam(oRole)
	if not bPermit then
		if sReason then
			oRole:Tips(sReason)
		end
		return
	end 
	local oTeam = self:CreateTeam(nRoleID)
	if not oTeam then 
		return 
	end
	return oTeam:GetID()
end

--角色ID取队伍
function CTeamMgr:GetTeamByRoleID(nRoleID)
	return self.m_tRoleTeamMap[nRoleID]
end

function CTeamMgr:GetRoleTeamID(nRoleID)
	local oTeam = self:GetTeamByRoleID(nRoleID)
	if not oTeam then
		return 0 
	end
	return oTeam:GetID()
end

--ID取队伍
function CTeamMgr:GetTeamByID(nTeamID)
	return self.m_tTeamMap[nTeamID]
end

function CTeamMgr:IsTeamMatching(nTeamID) 
	return self:GetMatchMgr():IsTeamMatching(nTeamID)
end

function CTeamMgr:GetTeamMemberMaxNum()
	return 5
end

--角色进入场景
function CTeamMgr:OnEnterScene(oRole)
	if not oRole then return end
	self:SyncTeamCache(oRole:GetID()) --防止队伍数据不同步
	self:GetMatchMgr():OnRoleEnterScene(oRole)
	local oTeam = self:GetTeamByRoleID(oRole:GetID())
	if not oTeam then 
		return 
	end
	oTeam:OnEnterScene(oRole)
end

function CTeamMgr:OnTeamLeaderChange(oTeam, nOldLeader)
	self:GetMatchMgr():OnTeamLeaderChange(oTeam, nOldLeader)
end

--角色上线
function CTeamMgr:Online(oRole)
	print("CTeamMgr:Online***", oRole:GetName())
	local oTeam = self:GetTeamByRoleID(oRole:GetID())
	if oTeam then 
		oTeam:Online(oRole)
	else
		CTeam:SyncTeamEmpty(oRole:GetID())
	end
	self:SyncTeamCache(oRole:GetID())
end

--角色离线
function CTeamMgr:Offline(oRole)
	local oTeam = self:GetTeamByRoleID(oRole:GetID())
	if oTeam then 
		oTeam:Offline(oRole)
	end
	self:GetMatchMgr():OnRoleOffline(oRole:GetID())
end

--角色释放
function CTeamMgr:OnRoleRelease(oRole)
	local oTeam = self:GetTeamByRoleID(oRole:GetID())
	if not oTeam then return end
	oTeam:OnRoleRelease(oRole)
end

--等级变化
function CTeamMgr:OnLevelChange(oRole)
	local oTeam = self:GetTeamByRoleID(oRole:GetID())
	if oTeam then
		oTeam:SyncTeam()
	else
		CTeam:SyncTeamEmpty(oRole:GetID())
	end
end

--队长发呆时间同步(发呆>=30秒每后60秒通知一次)
function CTeamMgr:LeaderActivityCheck(nRoleID, nLastPacketTime)
	local oTeam = self:GetTeamByRoleID(nRoleID)
	if not oTeam or not oTeam:IsLeader(nRoleID) then
		return
	end
	--战斗中
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if oRole:IsInBattle() then
		return
	end
	--结婚中
	if oRole:GetActState() ~= gtRoleActState.eNormal then
		return
	end
	local nInactivityTime = os.time()-math.max(nLastPacketTime, oRole:GetLastBattleEndTime())
	print("CTeamMgr:LeaderActivityCheck***", oTeam:GetID(), nRoleID, nInactivityTime)
	print(string.format("LeaderActivityCheck, 队长发呆事件(%d)", nRoleID))
	oTeam:LeaderActivityCheck(nRoleID, nInactivityTime)
	--通知逻辑服
	Network:RMCall("TeamLeaderActivityRet", nil, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), nRoleID, nInactivityTime)
end

--角色战斗开始
function CTeamMgr:OnBattleBegin(oRole)
	local oTeam = self:GetTeamByRoleID(oRole:GetID())
	if not oTeam then
		return
	end
	oTeam:OnBattleBegin(oRole)
end

--角色结束战斗
function CTeamMgr:OnBattleEnd(oRole, tBTRes)
	local oTeam = self:GetTeamByRoleID(oRole:GetID())
	if not oTeam then
		return
	end
	oTeam:OnBattleEnd(oRole, tBTRes)
end

--逻辑服查询角色队伍信息
function CTeamMgr:TeamQueryInfoReq(nRoleID)
	local oTeam = self:GetTeamByRoleID(nRoleID)
	if oTeam then
		return oTeam:GetID(), oTeam:IsLeader(nRoleID), oTeam:IsLeave(nRoleID)
	else
		return 0, false, true
	end
end

--逻辑服取战斗队伍请求
function CTeamMgr:TeamBattleInfoReq(nRoleID)
	local oTeam = self:GetTeamByRoleID(nRoleID)
	if not oTeam then
		return 0, nil
	end

	local tTeam = {}
	local tRoleList = oTeam:GetRoleList()
	for nIndex, tRole in ipairs(tRoleList) do
		local oRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
		tTeam[nIndex] = {nIndex=nIndex, bLeave=tRole.bLeave, bRelease=oRole:IsReleasedd(), nRoleID=tRole.nRoleID}
	end
	return oTeam:GetID(), tTeam
end
