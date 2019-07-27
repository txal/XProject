--队伍对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--申请人数上限
local nMaxApplys = 20

gtSceneTeamLimitType = 
{
	eNone = 0,        --没有限制
	eSameScene = 1,   --同场景才可归队
	eTeamForbid = 2,  --禁止组队
}

--@nID 队伍ID
function CTeam:Ctor(oTeamMgr, nID)
	self.m_oTeamMgr = oTeamMgr
	self.m_nID = nID
	self.m_tRoleList = {}  			--队伍信息{{nRoleID=0,bLeave=false,nApplyTime=0,
									-- tPreQuit={bQuit, bKick}, tFollowSwitch = {{nTargetDup, nTimeStamp},...}, 
									-- bPreReturn=,},...} 
									--第1个是队长, tPreQuit预离队信息，true，战斗结束或离线时，将离开队伍
									--tFollowSwitch跟随跳转列表, 之所以用列表，是为了防止出现队长多次(大于等于3次)连续跳转场景
	self.m_tApplyMap = {} 			--申请入队列表{[nRoleID]=time,...}
	self.m_tLeaderPartnerInfo = nil --队长伙伴信息

	--不保存
	self.m_tApplyLeader = {bInvalid = true}  --申请带队信息{nRoleID=0,nAgrees=0,nDenys=0}
	self.m_nLeaderActivityNotify = 0 	--上一次队长不活跃推送申请带队时间
	self.m_nLeaderActivityAsking = 0 	--队长不活跃进行是否中
	self.m_nBattleID = 0
end

function CTeam:LoadData(tData)
	for sKey, xVal in pairs(tData) do
		self[sKey] = xVal
	end
	local tRoleList = {}
	for k, tRole in pairs(self.m_tRoleList) do 
		if goGPlayerMgr:GetRoleByID(tRole.nRoleID) then --兼容未知问题导致的角色移除和未正常清理的机器人
			if not tRole.tPreQuit then 
				tRole.tPreQuit = {bQuit = false, bKick = false}
			end
			tRole.tFollowSwitch = nil  --初始置空
			tRole.bPreReturn = nil     --初始置空
			table.insert(tRoleList, tRole)
		end
	end
	self.m_tRoleList = tRoleList
	if #self.m_tRoleList > 0 then 
		self.m_tRoleList[1].bLeave = false
	end
end

function CTeam:SaveData()
	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_tRoleList = self.m_tRoleList
	tData.m_tApplyMap = self.m_tApplyMap
	tData.m_tLeaderPartnerInfo = self.m_tLeaderPartnerInfo
	return tData
end

function CTeam:Release()
	self.m_tRoleList = {}
	self.m_tApplyMap = {}
	self.m_tPartnerInfo = nil
	self.m_tApplyLeader.bInvalid = true
	GetGModule("TimerMgr"):Clear(self.m_nApplyLeaderTimer)
end

function CTeam:MarkDirty(bDirty)
	self.m_oTeamMgr:MarkDirty(self.m_nID, bDirty)
end

function CTeam:GetID() return self.m_nID end
function CTeam:IsFull() return #self.m_tRoleList >= 5 end
function CTeam:GetLeader() return self.m_tRoleList[1] end
function CTeam:GetLeaderRole() 
	local tLeader = self:GetLeader()
	if not tLeader then 
		return
	end
	return  goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
end
function CTeam:GetLeaderLevel()
	local tLeader = self:GetLeader()
	if not tLeader then 
		return 0
	end
	local oRoleLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
	if not oRoleLeader then 
		return 0
	end
	return oRoleLeader:GetLevel()
end
function CTeam:GetMembers() return #self.m_tRoleList end
function CTeam:GetRoleList() return self.m_tRoleList end
function CTeam:IsInTeam(nRoleID) 
	for _, tRoleData in ipairs(self:GetRoleList()) do 
		if tRoleData.nRoleID == nRoleID then 
			return true 
		end
	end
	return false 
end
function CTeam:IsLeave(nRoleID) return self:GetRole(nRoleID).bLeave end
function CTeam:IsLeader(nRoleID) return self.m_tRoleList[1].nRoleID == nRoleID end
function CTeam:SetLeaveState(tRoleData, bLeave) 
	tRoleData.bLeave = bLeave
end
function CTeam:SetFollowSwitchRecord(nRoleID, tTarget) 
	if not nRoleID or not tTarget then 
		return 
	end
	local tRole = self:GetRole(nRoleID)
	if not tRole then return end
	local tFollowSwitch = tRole.tFollowSwitch or {}
	if #tFollowSwitch >= 3 then --超过3条记录, 正常逻辑出错了，或者服务异常了
		return 
	end
	local tRecord = {}
	tRecord.nDupMixID = tTarget.nTarDupMixID
	tRecord.nTimeStamp = os.time()
	table.insert(tFollowSwitch, tRecord)
	tRole.tFollowSwitch = tFollowSwitch
end

function CTeam:ClearFollowSwitchRecord(nRoleID)
	local tRole = self:GetRole(nRoleID)
	if not tRole then 
		return 
	end
	tRole.tFollowSwitch = nil 
end

function CTeam:PopFollowSwitchRecord(nRoleID, nTimeStamp)
	local tRecord = nil
	local tRole = self:GetRole(nRoleID)
	if not tRole then 
		return tRecord
	end
	local tFollowSwitch = tRole.tFollowSwitch or {}
	if #tFollowSwitch <= 0 then 
		return tRecord
	end

	for nIndex = 1, 10 do --防止死循环
		if #tFollowSwitch <= 0 then 
			break 
		end

		local tTemp = tFollowSwitch[1]
		table.remove(tFollowSwitch, 1)
		--超过15秒的, 都判定为不合法的数据, 可能旧数据未清理
		if math.abs(nTimeStamp - tTemp.nTimeStamp) <= 15 then 
			tRecord = tTemp
			break
		end
	end

	return tRecord
end

function CTeam:CheckFollowSwitch(tRecord, nDupMixID, nTimeStamp) 
	if not tRecord or not tRecord.nDupMixID then 
		return false
	end
	--5秒内才判定为有效
	if nDupMixID == tRecord.nDupMixID and math.abs(nTimeStamp - tRecord.nTimeStamp) <= 5 then 
		return true 
	end
	return false
end

function CTeam:IsPreReturn(nRoleID) 
	local tRole = self:GetRole(nRoleID)
	if not tRole then 
		return false 
	end
	return tRole.bPreReturn and true or false
end

function CTeam:SetPreReturn(nRoleID, bReturn)
	local tRole = self:GetRole(nRoleID)
	if not tRole then 
		return 
	end
	tRole.bPreReturn = bReturn
end

function CTeam:CheckTeamActive() 
	for k, tRoleData in pairs(self.m_tRoleList) do 
		if not CUtil:IsRobot(tRoleData.nRoleID) then 
			local oRole = goGPlayerMgr:GetRoleByID(tRoleData.nRoleID)
			if oRole:IsOnline() and not tRoleData.bLeave then --存在在线且未暂离的玩家
				return true
			end
		end
	end
	return false
end

-- function CTeam:RobotOffline()
-- 	local tTeamList = table.DeepCopy(self.m_tRoleList)
-- 	local tRemoveList = {}
-- 	for k, tRoleData in pairs(tTeamList) do 
-- 		if CUtil:IsRobot(tRoleData.nRoleID) then
-- 			local oRole = goGPlayerMgr:GetRoleByID(tRoleData.nRoleID)
-- 			if oRole then 
-- 				self:QuitReq(oRole) 
-- 				table.insert(tRemoveList, tRoleData.nRoleID)
-- 			end
-- 		end
-- 	end
-- 	for k, nRoleID in ipairs(tRemoveList) do 
-- 		goGRobotMgr:RemoveRobot(nRoleID)
-- 	end
-- end

--检查队伍是否解散
function CTeam:CheckTeamRemoveState()
	if not self:CheckTeamActive() then 
		self:RemoveTeam()
	end
end

--队伍会话列表
--tExceptList，指定不获取的列表{nRoleID, ...}
function CTeam:GetSessionList(tExceptList)
	local tSessionList = {}
	for _, tRole in ipairs(self.m_tRoleList) do
		local bExcept = false
		if tExceptList and #tExceptList > 0 then 
			assert(#tExceptList < 6, "参数错误")
			for _, nExceptID in ipairs(tExceptList) do 
				if nExceptID == tRole.nRoleID then 
					bExcept = true 
					break
				end
			end
		end
		if not bExcept then 
			local oRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
			if oRole:IsOnline() and not oRole:IsRobot() then
				table.insert(tSessionList, oRole:GetServer())
				table.insert(tSessionList, oRole:GetSession())
			end
		end
	end
	return tSessionList
end

--广播队伍
function CTeam:BroadcastTeam(sCmd, tMsg)
	local tSessionList = self:GetSessionList()
	Network.PBBroadcastExter(sCmd, tSessionList, tMsg)
end

--角色数据
function CTeam:GetRole(nRoleID)
	for k, tRole in ipairs(self.m_tRoleList) do
		if tRole.nRoleID == nRoleID then
			return tRole, k
		end
	end
end

--将角色队伍信息同步到逻辑服
--如果指定了nRoleID，则只同步nRoleID,否则同步队伍所有成员数据
function CTeam:SyncLogicCache(nRoleID)
	local tTeamList = {}
	for _, tRole in ipairs(self.m_tRoleList) do 
		local oRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
		local tData = {}
		tData.nRoleID = tRole.nRoleID
		tData.bLeave = tRole.bLeave
		tData.nServer = oRole and oRole:GetServer() or 0
		table.insert(tTeamList, tData)
	end

	if nRoleID then 
		for nIndex, tRole in ipairs(self.m_tRoleList) do
			if tRole.nRoleID == nRoleID then 
				local oRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
				local tData = {
					m_nTeamID=self:GetID(), 
					m_bLeader=self:IsLeader(tRole.nRoleID), 
					m_bTeamLeave = self:IsLeave(tRole.nRoleID),
					m_nTeamIndex = nIndex,
					m_nTeamNum = self:GetMembers(),
					m_tTeamList = tTeamList,
				}
				Network.oRemoteCall:Call("RoleUpdateReq", oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), 
					oRole:GetServer(), oRole:GetID(), tData)
			end
		end
	else
		for nIndex, tRole in ipairs(self.m_tRoleList) do
			local oRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
			local tData = {
				m_nTeamID=self:GetID(), 
				m_bLeader=self:IsLeader(tRole.nRoleID), 
				m_bTeamLeave = self:IsLeave(tRole.nRoleID),
				m_nTeamIndex = nIndex,
				m_nTeamNum = self:GetMembers(),
				m_tTeamList = tTeamList,
			}
			Network.oRemoteCall:Call("RoleUpdateReq", oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), 
				oRole:GetServer(), oRole:GetID(), tData)
		end
	end
end

--队长变更
function CTeam:OnLeaderChange(nOldLeaderRoleID)
	self.m_tLeaderPartnerInfo = nil
	self.m_nLeaderActivityNotify = 0
	self.m_tRoleList[1].bLeave = false
	self.m_tApplyLeader.bInvalid = true
	self:MarkDirty(true)

	self:SyncLogicCache()
	self:BroadcastTeam("TeamLeaderChangeRet", {})
	self.m_oTeamMgr:UpdateTeamFollow(self) --更新队伍跟随
	local tTeamLeader = self:GetLeader()
	if tTeamLeader then 
		self:ClearFollowSwitchRecord(tTeamLeader.nRoleID)
		self:SetPreReturn(tTeamLeader.nRoleID, nil)
		local oRoleLeader = goGPlayerMgr:GetRoleByID(tTeamLeader.nRoleID)
		local sTeamContent = string.format("%s被提升为新队长了！", oRoleLeader:GetFormattedName())
		goTalk:SendTeamMsg(oRoleLeader, sTeamContent, true, {tTeamLeader.nRoleID})
		local tSessionList = self:GetSessionList({tTeamLeader.nRoleID})
		if tSessionList and #tSessionList > 0 then 
			Network.PBBroadcastExter("TipsMsgRet", tSessionList, {sCont = sTeamContent})
		end

		local sContent = "您被提升为队长了！"
		oRoleLeader:Tips(sContent)
		goTalk:SendTeamMsgToRole(oRoleLeader, sContent, true, tTeamLeader.nRoleID)

		self:ApplyListReq(oRoleLeader)
	end
	self.m_oTeamMgr:OnTeamLeaderChange(self, nOldLeaderRoleID)
end

--归队事件
function CTeam:OnReturnTeam(tRole, tLeaderTarget)
	tRole.bLeave = false
	self:SetPreReturn(tRole.nRoleID, nil)
	self:MarkDirty(true)
	self:SyncTeam()
	local oRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
	assert(oRole)
	self:SyncLogicCache()
	local tLeader = self:GetLeader()
	local oLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
	if tLeaderTarget then
		self:SetFollowSwitchRecord(tRole.nRoleID, tLeaderTarget)
		Network.oRemoteCall:Call("WSwitchLogicReq", oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), tLeaderTarget)
		self.m_oTeamMgr:UpdateTeamFollow(self)
	else
		--非队长场景切换引发的，才需要发送tips
		local sContent = string.format("%s回归了队伍", oRole:GetFormattedName())
		goTalk:SendTeamMsg(oRole, sContent, true)
		local tSessionList = self:GetSessionList()
		if tSessionList and #tSessionList > 0 then 
			Network.PBBroadcastExter("TipsMsgRet", tSessionList, {sCont = sContent})
		end

		Network.oRemoteCall:CallWait("QueryRoleDupInfoReq", function(nDupMixID, nLine, nPosX, nPosY)
			if not nDupMixID then
				return LuaTrace("CTeam:ReturnTeamReq 队长已释放?", oLeader:GetName(), oLeader:IsReleasedd(), oLeader:IsOnline())
			end

			local nDupID = CUtil:GetDupID(nDupMixID)
			local tDupConf = ctDupConf[nDupID]
			local tTarget = {nRoleID=oRole:GetID(), nTarDupMixID=nDupMixID, nPosX=nPosX, nPosY=nPosY, nLine=nLine, nFace=tDupConf.nFace}
			Network.oRemoteCall:Call("WSwitchLogicReq", oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), tTarget)
			self.m_oTeamMgr:UpdateTeamFollow(self)

		end, oLeader:GetStayServer(), oLeader:GetLogic(), oLeader:GetSession(), oLeader:GetID())
	end
end

--暂离事件
function CTeam:OnLeaveTeam(tRole)
	self:ClearFollowSwitchRecord(tRole.nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
	if not oRole then 
		-- LuaTrace(string.format("OnLeaveTeam:玩家(%d)不存在", tRole.nRoleID))
		return 
	end
	self:SyncLogicCache()
	-- LuaTrace(string.format("OnLeaveTeam:玩家(%d)(%s)", oRole:GetID(), oRole:GetName()))
	self.m_oTeamMgr:UpdateTeamFollow(self)

	local sContent = string.format("%s暂时离开了队伍", oRole:GetFormattedName())
	goTalk:SendTeamMsg(oRole, sContent, true)
	local tSessionList = self:GetSessionList({oRole:GetID()})
	if tSessionList and #tSessionList > 0 then 
		Network.PBBroadcastExter("TipsMsgRet", tSessionList, {sCont = sContent})
	end

	--组队机器人如果出现暂离就删除
	if oRole:IsRobot() then
		if oRole:IsTeamRobot() then 
			goGRobotMgr:RemoveRobot(tRole.nRoleID)
		else
			self:QuitReq(oRole)
		end
	end
	self:CheckTeamRemoveState()
end

--解散当前队伍
function CTeam:RemoveTeam()
	-- LuaTrace(">>>> RemoveTeam <<<<<")
	-- LuaTrace(debug.traceback())
	print("队伍解散")
	local tTempRoleList = table.DeepCopy(self.m_tRoleList)
	local tSessionList = self:GetSessionList()
	local nMembers = self:GetMembers()
	for k = 1, nMembers do 
		local tRoleData = self.m_tRoleList[1]
		table.remove(self.m_tRoleList, 1)
		local oRole = goGPlayerMgr:GetRoleByID(tRoleData.nRoleID)
		if oRole then 
			self:OnRoleQuit(oRole, true, true)
		end
	end
	self.m_oTeamMgr:OnTeamDismiss(self)

	local sCont = "队伍已解散"
	for k, tRoleData in pairs(tTempRoleList) do 
		local oRole = goGPlayerMgr:GetRoleByID(tRoleData.nRoleID)
		if oRole then 
			goTalk:SendTeamMsgToRole(oRole, sCont, true, oRole:GetID())
		end
	end
	if tSessionList and #tSessionList > 0 then 
		Network.PBBroadcastExter("TipsMsgRet", tSessionList, {sCont = sCont})
	end
end

function CTeam:OnRoleQuit(oRole, bKick, bSilence)
	-- LuaTrace(string.format("OnRoleQuit:玩家(%d)(%s)", oRole:GetID(), oRole:GetName()))
	local nRoleID = oRole:GetID()
	if not bSilence then 
		local sContent = bKick and "你被请离了队伍" or "你已离开了队伍"
		oRole:Tips(sContent)
		goTalk:SendTeamMsgToRole(oRole, sContent, true, nRoleID)

		--队伍频道
		local sCont = bKick and string.format("%s被请离队伍", oRole:GetFormattedName()) or string.format("%s离开了队伍", oRole:GetFormattedName())
		goTalk:SendTeamMsg(oRole, sCont, true)
		local tSessionList = self:GetSessionList()
		if tSessionList and #tSessionList > 0 then 
			Network.PBBroadcastExter("TipsMsgRet", tSessionList, {sCont = sCont})
		end
	end
	self:SyncTeamEmpty(nRoleID) --同步无队伍信息(自己和伙伴)
	self.m_oTeamMgr:OnRoleQuit(nRoleID)

	--外层有检查，是否触发解散队伍
	if oRole:IsRobot() and oRole:IsTeamRobot() then 
		goGRobotMgr:RemoveRobot(nRoleID)
	end
end

--退出队伍
--@bKick 是否被踢出
--成功退出，返回true
function CTeam:QuitReq(oRole, bKick)
	if not oRole then
		return
	end
	local nRoleID = oRole:GetID()
	local tRole, nIndex = self:GetRole(nRoleID)
	if not tRole then
		return
	end

	local nRoleActState = oRole:GetActState()	
	if nRoleActState == gtRoleActState.eWedding then
		oRole:Tips("正在举行婚礼，请专心一点哦")
		return
	elseif nRoleActState == gtRoleActState.ePalanquinParade then
		oRole:Tips("正在花轿游行中，请专心一点哦")
		return
	end

	if oRole:IsInBattle() then 
		tRole.tPreQuit = {bQuit = true, bKick = bKick and true or false}
		self:MarkDirty(true)
		if not bKick then 
			oRole:Tips("战斗结束后离开队伍")
		else 
			oRole:Tips("对方战斗结束后离开队伍")
		end
		return
	end

	table.remove(self.m_tRoleList, nIndex)	
	self:MarkDirty(true)

	self:OnRoleQuit(oRole, bKick)
	--队长退出
	if nIndex == 1 then
		--没有人了就解散队伍
		if #self.m_tRoleList <= 0 then
			self.m_oTeamMgr:OnTeamDismiss(self)
			return true
		end

		local fnChangeLeader = function(nIndex)
			local tTemp = self.m_tRoleList[1]
			self.m_tRoleList[1] = self.m_tRoleList[nIndex]
			self.m_tRoleList[nIndex] = tTemp
			self:OnLeaderChange(tRole.nRoleID)
		end

		--检查是否存在未暂离的真实玩家
		local nNewLeaderIdx = 0
		for nIndex, tTmpRole in ipairs(self.m_tRoleList) do
			if (not tTmpRole.bLeave) and tTmpRole.nRoleID ~= nRoleID 
				and not CUtil:IsRobot(tTmpRole.nRoleID) then
					nNewLeaderIdx = nIndex
				break
			end
		end
		if nNewLeaderIdx > 0 then 
			fnChangeLeader(nNewLeaderIdx)
		else
			self:RemoveTeam()
		end
	else
		self:SyncLogicCache() --队长退出，内部会触发一次同步
	end
	--同步新队伍信息
	self:SyncTeam()
	return true
end

--加入队伍
--@bReturn 是否归队
function CTeam:Join(nRoleID, bReturn)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if self:IsFull() then
		return oRole:Tips("队伍已满")
	end
	if self:GetRole(nRoleID) then
		return oRole:Tips("已经在队伍中")
	end
	if self.m_oTeamMgr:GetTeamByRoleID(nRoleID) then
		return oRole:Tips("数据错误")
	end

	local bLeader = #self.m_tRoleList==0
	if bLeader and oRole:IsReleasedd() then
		LuaTrace("状态错误mmm", oRole:IsReleasedd(), oRole:IsOnline(), oRole:GetName())
	end
	table.insert(self.m_tRoleList, {nRoleID=oRole:GetID(), bLeave=(not bLeader), 
		nApplyTime=0, tPreQuit = {bQuit = false, bKick = false}})
	self:MarkDirty(true)
	--归队前必须调用向逻辑服同步一次队伍缓存数据
	self.m_oTeamMgr:OnRoleJoin(oRole:GetID(), self) 
	self:SyncTeam()

	if (not bLeader) and bReturn then 
		self:ReturnTeamReq(oRole)
	end
	return true
end

--检查玩家所在场景是否可组队或者加入队伍
function CTeam:CheckSceneJoinTeam(oRole,nType)
	assert(oRole, "参数错误")
	local tRoleDupConf = oRole:GetDupConf()
	if tRoleDupConf.nTeamLimitType == gtSceneTeamLimitType.eTeamForbid then
		return false, "当前场景限制组队"
	end
	--帮战地图申请，同帮派才能申请
	if tRoleDupConf.nID == 13 and nType and nType > 0 then
		local nLeader = self:GetLeader().nRoleID
		local oLeader = goGPlayerMgr:GetRoleByID(nLeader)
		if oLeader and oLeader:GetUnionID() ~= oRole:GetUnionID() then
			return false,"只有同联盟的成员才能申请"
		end
	end
	return true
end

function CTeam:IsSameActScene(nDupConfIDL, nDupConfIDR)
	local tDupConfL = ctDupConf[nDupConfIDL]
	local tDupConfR = ctDupConf[nDupConfIDR]
	if not tDupConfL or not tDupConfR then 
		return false 
	end
	if nDupConfIDL == nDupConfIDR then 
		return true  
	end

	--TODO 当前硬编码
	local nPVEPrepareDup = 200  -- PVE场景活动类型判断
	local tPVEActID = {200, 201, 202, 203}

	--针对PVE活动或者其他配置了相关数据的
	if tDupConfL.nBattleType > 0 and tDupConfR.nBattleType > 0 then 
		if tDupConfL.nBattleType == tDupConfR.nBattleType then 
			return true 
		end
		if tDupConfL.nBattleType == nPVEPrepareDup then 
			for _, nBattleDupType in pairs(tPVEActID) do 
				if nBattleDupType == tDupConfR.nBattleType then 
					return true 
				end
			end
		elseif tDupConfR.nBattleType == nPVEPrepareDup then 
			for _, nBattleDupType in pairs(tPVEActID) do 
				if nBattleDupType == tDupConfL.nBattleType then 
					return true 
				end
			end
		end
	end

	return false 
end

--检查玩家和队长的场景关系，是否可归队
function CTeam:CheckSceneReturnTeam(oRole, oLeader)
	assert(oRole and oLeader, "参数错误")
	local nRoleSceneMixID = oRole:GetDupMixID()
	local tRoleDupConf = oRole:GetDupConf()

	local nLeaderSceneMixID = oLeader:GetDupMixID()
	local tLeaderDupConf = oLeader:GetDupConf()

	if tRoleDupConf.nTeamLimitType == gtSceneTeamLimitType.eNone and
		tLeaderDupConf.nTeamLimitType == gtSceneTeamLimitType.eNone then
		return true
	end

	if tLeaderDupConf.nTeamLimitType == gtSceneTeamLimitType.eSameScene then
		if not self:IsSameActScene(tRoleDupConf.nID, tLeaderDupConf.nID) then
			return false, "队长正在参加限时活动，请先参加该活动再归队"
		else
			return true
		end

	elseif tRoleDupConf.nTeamLimitType == gtSceneTeamLimitType.eSameScene then
		if not self:IsSameActScene(tRoleDupConf.nID, tLeaderDupConf.nID) then  
			--防止离开场景自动退出活动
			return false, "当前处于活动场景，无法归队"
		else
			return true
		end
	elseif tLeaderDupConf.nTeamLimitType == gtSceneTeamLimitType.eTeamForbid or 
		tRoleDupConf.nTeamLimitType == gtSceneTeamLimitType.eTeamForbid then
		return false, "不可组队场景，归队失败"

	end
	return true
end

--检测是否可以归队
function CTeam:CanReturnTeam(oLeaderRole, oMemberRole)
	local nLeaderDupMixID = oLeaderRole:GetDupMixID()
	local tLeaderDupConf = oLeaderRole:GetDupConf()	

	local nMemberDupMixID = oMemberRole:GetDupMixID()
	local tMemberDupConf = oMemberRole:GetDupConf()

	local nBattleType = tLeaderDupConf.nBattleType
	local tBattleDupConf = ctBattleDupConf[nBattleType] or {}
	-- local nLevelLimit = tBattleDupConf.nLevelLimit or 0

	if tBattleDupConf and tBattleDupConf.bSingle then
		return false, "队长处于单人副本中，无法归队"
	end

	-- if nLevelLimit > 0 and oMemberRole:GetLevel() < nLevelLimit then
	-- 	return false, "等级不满足副本要求无法归队"
	-- end

	-- if oMemberRole:IsInBattle() then
	-- 	return false, "正在战斗中，无法归队"
	-- end

	if oMemberRole:IsReleasedd() then
		return false, "已离线，无法归队"
	end

	if oLeaderRole:IsReleasedd() then
		return false, "队长已离线，无法归队"
	end

	if not oLeaderRole:IsInWorldServer() then
		return false, "队长处于非跨服场景，无法归队"
	end

	local bSceneLimit, sReason = self:CheckSceneReturnTeam(oMemberRole, oLeaderRole)
	if not bSceneLimit then
		return false, sReason
	end
	return true
end

--玩家进入场景
function CTeam:OnEnterScene(oRole)
	local bPermit = self:CheckSceneJoinTeam(oRole)
	if not bPermit then
		self:QuitReq(oRole, false)
		return oRole:Tips("你已进入限制组队场景，自动离开队伍")
	end	

	--更新跟随(因可能切换进程)
	self.m_oTeamMgr:UpdateTeamFollow(self)

	print(oRole:GetName(), "进入场景", oRole:GetDupMixID())

	local nRoleID = oRole:GetID()
	--不论是否是队长，是否其他情况，都尝试pop下, 避免旧数据未清理
	local tFollowSwitchRecord = self:PopFollowSwitchRecord(nRoleID, os.time())

	local tLeader = self:GetLeader()
	local oLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
	if not self:IsLeader(oRole:GetID()) then
		--队员离开场景,队长还在场景的情况
		local nDupMixID = oRole:GetDupMixID()
		if not self:IsLeave(nRoleID) and nDupMixID ~= oLeader:GetDupMixID() then
			--只有场景不一致时，才触发检查
			if not self:CheckFollowSwitch(tFollowSwitchRecord, nDupMixID, os.time()) then 
				print("队员和队长场景不一致，触发暂离队伍", oLeader:GetName(), oRole:GetName(), oRole:GetDupMixID(), oLeader:GetDupMixID()) 
				self:LeaveTeamReq(oRole)
			end
		end
		return
	else
		-- --队长场景发生变化，需要检查，防止将组队机器人带出场景
		-- local tQuitList = {}
		-- local tLeaderDupConf = oLeader:GetDupConf()
		-- local bLeaderPVEActDup = CUtil:IsPVEActDup(tLeaderDupConf.nID)
		-- for k = 2, self:GetMembers() do 
		-- 	local tRole = self.m_tRoleList[k]
		-- 	if CUtil:IsRobot(tRole.nRoleID) then 
		-- 		local oRobot = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
		-- 		if oRobot and oRobot:IsTeamRobot() then 
		-- 			local tRobotLeaderDupConf = oLeader:GetDupConf()
		-- 			local bRobotPVEActDup = CUtil:IsPVEActDup(tRobotLeaderDupConf.nID)
		-- 			--队长在主城或者队长玩法类型和机器人玩法类型不一致
		-- 			if bLeaderPVEActDup then 
		-- 				if not bRobotPVEActDup then 
		-- 					table.insert(tQuitList, oRobot)
		-- 				end
		-- 			elseif tLeaderDupConf.nType == 1 
		-- 				or tLeaderDupConf.nBattleType ~= tRobotLeaderDupConf.nBattleType then 
		-- 				table.insert(tQuitList, oRobot)
		-- 			end
		-- 		end
		-- 	end
		-- end
		-- for _, oRobot in ipairs(tQuitList) do 
		-- 	if self:IsInTeam(oRobot:GetID()) then --防止回调事件各种问题导致不在队伍了
		-- 		self:QuitReq(oRobot)
		-- 	end
		-- end
	end

	local function _fnCallback(nDupMixID, nLine, nPosX, nPosY)
		if not nDupMixID then
			return LuaTrace("取队长所在场景失败?", oRole:GetName(), "online:", oRole:IsOnline(), "release:", oRole:IsReleasedd())
		end
		if nDupMixID <= 0 then
			return LuaTrace("队长场景数据错误?", tLeader, nDupMixID, nLine, nPosX, nPosY)
		end

		local nDupID = CUtil:GetDupID(nDupMixID)
		local tTarget = {nRoleID=0, nTarDupMixID=nDupMixID, nPosX=nPosX, nPosY=nPosY, nLine=nLine, nFace=ctDupConf[nDupID].nFace}

		--ReturnTeamReq中，可能触发暂离事件，暂离事件中，角色离开队伍 --史诗级灾难片，回调地狱
		local tTeamRoleList = {}
		for k = 2, #self.m_tRoleList do  --回调事件中，可能修改self.m_tRoleList
			local tTmpRole = self.m_tRoleList[k]
			table.insert(tTeamRoleList, tTmpRole)
		end
		for k = 1, #tTeamRoleList do 
			local tTmpRole = tTeamRoleList[k]
			if tTmpRole and self:IsInTeam(tTmpRole.nRoleID) then
				if not tTmpRole.bLeave then 
					local oTmpRole = goGPlayerMgr:GetRoleByID(tTmpRole.nRoleID)
					tTarget.nRoleID = tTmpRole.nRoleID
					self:ReturnTeamReq(oTmpRole, tTarget)
					print("队伍发出切换场景指令", oTmpRole:GetName(), tTarget)
				end
			end
		end
	end
	Network.oRemoteCall:CallWait("QueryRoleDupInfoReq", _fnCallback, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID())
end

--归队
function CTeam:ReturnTeamReq(oRole, tLeaderTarget)
	local tRole = self:GetRole(oRole:GetID())
	if not tRole then
		return
	end
	if tLeaderTarget then 
		tLeaderTarget = table.DeepCopy(tLeaderTarget)
	end

	if self:IsLeader(oRole:GetID()) then
		return
	end

	--非暂离状态，并且不是队长切换场景触发，则直接退出
	if not tRole.bLeave and not tLeaderTarget then 
		return 
	end

	local tLeader = self:GetLeader()
	local oLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)

	local bReturn, sReason = self:CanReturnTeam(oLeader, oRole)
	if not bReturn then
		if not tLeaderTarget then
			oRole:Tips(sReason)
		end
		self:LeaveTeamReq(oRole)
		return
	end
	if oRole:IsInBattle() then 
		self:SetPreReturn(oRole:GetID(), true)
		oRole:Tips("战斗结束后将自动归队")
		return
	end
	if oLeader:IsInBattle() then --直接归队,只是加个TIPS提示
		oRole:Tips("队伍正在战斗，少侠请等待队伍战斗结束自动归队")
	end

	local fnReturnTeamCallback = function(bRet, sReason)
		if not bRet then
			-- print(string.format("玩家ID(%d),姓名(%s)归队检查失败", oRole:GetID(), oRole:GetName()))
			if sReason and type(sReason) == "string" then 
				oRole:Tips(sReason) 
			end
			if tLeaderTarget then  
				--原来在队伍非暂离状态，队长切换场景，归队跟随失败，导致暂离，需要将玩家设置成暂离状态
				if oRole:IsRobot() then --如果是机器人，则不论是否暂离状态，都退出队伍
					self:QuitReq(oRole)
				else 
					if not tRole.bLeave and not self:IsLeader(oRole:GetID()) then 
						self:LeaveTeamReq(oRole)
					end
				end
			end
			return 
		end
		tRole.bLeave = false
		self:MarkDirty(true)
		self:OnReturnTeam(tRole, tLeaderTarget)
	end

	local tLeaderDupConf = oLeader:GetDupConf()	
	assert(tLeaderDupConf)
	--PVE活动
	if (tLeaderDupConf.nBattleType == 200) or (tLeaderDupConf.nBattleType == 201) 
		or (tLeaderDupConf.nBattleType == 202) or (tLeaderDupConf.nBattleType == 203) then 
		Network.oRemoteCall:CallWait("ReturnTeamJoinPVEActCheckReq",fnReturnTeamCallback, 
			oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID())
		return 
	end

	--如果队长在日常 非 限时活动中，判断队员是否可参加
	local bLeaderNormalAct = false
	local nLeaderDailyActID = 0
	local tBattleDupConf = ctBattleDupConf[tLeaderDupConf.nBattleType]
	if tBattleDupConf then 
		nLeaderDailyActID = tBattleDupConf.nDailyActID
		if nLeaderDailyActID > 0 then 
			local tDailyConf = ctDailyActivity[nLeaderDailyActID]
			if tDailyConf and tDailyConf.nActivityType == 1 then 
				bLeaderNormalAct = true 
			end
		end
	end
	if bLeaderNormalAct and nLeaderDailyActID > 0 then 
		Network.oRemoteCall:CallWait("CheckJoinDailyActReq",fnReturnTeamCallback, oRole:GetStayServer(), 
			oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), nLeaderDailyActID)
		return 
	else
		fnReturnTeamCallback(true)
	end

end

--暂离请求
function CTeam:LeaveTeamReq(oRole)
	local tRole = self:GetRole(oRole:GetID())
	if not tRole then
		return
	end
	local nRoleID = oRole:GetID()

	if tRole.bLeave then
		return
	end

	local nRoleActState = oRole:GetActState()	
	if nRoleActState == gtRoleActState.eWedding then
		oRole:Tips("正在举行婚礼，请专心一点哦")
		return
	elseif nRoleActState == gtRoleActState.ePalanquinParade then
		oRole:Tips("正在花轿游行中，请专心一点哦")
		return
	end

	local fnLeave = function() 
		self:SyncTeam()
		oRole:Tips("在主界面队伍区域，点击【归队】按钮即可回到队伍")
		self:OnLeaveTeam(tRole)
	end

	if self:IsLeader(oRole:GetID()) then
		local nReturnRoleIdx = 0
		for nIndex, tTmpRole in ipairs(self.m_tRoleList) do
			if (not tTmpRole.bLeave) and tTmpRole.nRoleID ~= nRoleID 
				and not CUtil:IsRobot(tTmpRole.nRoleID) then
				nReturnRoleIdx = nIndex
				break
			end
		end
		if nReturnRoleIdx > 0 then
			self.m_tRoleList[1] = self.m_tRoleList[nReturnRoleIdx]
			self.m_tRoleList[nReturnRoleIdx] = tRole

			tRole.bLeave = true
			self:MarkDirty(true)
			self:OnLeaderChange(tRole.nRoleID)
			fnLeave()
		else 
			self:RemoveTeam()
		end
	else
		tRole.bLeave = true
		self:MarkDirty(true)
		fnLeave()
	end

	-- if tRole.bLeave then
	-- 	self:SyncTeam()
	-- 	oRole:Tips("在主界面队伍区域，点击【归队】按钮即可回到队伍")
	-- 	self:OnLeaveTeam(tRole)
	-- end
end

--邀请在线好友列表请求
function CTeam:FriendListReq(oRole)
	local nRoleID = oRole:GetID()
	local tFriendMap = goFriendMgr:GetFriendMap(nRoleID)
	if not next(tFriendMap) then
		return oRole:Tips("当前没有好友可以助战")
	end
	local tList = {}
	for nTmpRoleID, oFriend in pairs(tFriendMap) do
		local oTmpRole = goGPlayerMgr:GetRoleByID(nTmpRoleID)
		local tInfo = {
			nID=nTmpRoleID,
			sName=oTmpRole:GetName(),
			sHeader=oTmpRole:GetHeader(),
			nLevel=oTmpRole:GetLevel(),
			nSchool=oTmpRole:GetSchool(),
			nGender=oTmpRole:GetGender(),
			nTeamID=0,
		}
		local oTeam = goTeamMgr:GetTeamByRoleID(nTmpRoleID)
		tInfo.nTeamID = oTeam and oTeam:GetID() or 0
		table.insert(tList, tInfo)
	end
	oRole:SendMsg("TeamFriendRet", {tList=tList})
end

--邀请在线帮派成员列表请求
function CTeam:UnionMemberListReq(oRole)
	local nGlobalService = goServerMgr:GetGlobalService(oRole:GetServer(), 20)
	Network.oRemoteCall:CallWait("UnionMemberListReq", function(tMemberList)
		if #tMemberList <= 0 then		
			return oRole:Tips("当前没有帮派成员可以助战")
		end

		local tList = {}
		for _, nTmpRoleID in pairs(tMemberList) do
			if nTmpRoleID ~= oRole:GetID() then
				local oTmpRole = goGPlayerMgr:GetRoleByID(nTmpRoleID)
				local tInfo = {
					nID=nTmpRoleID,
					sName=oTmpRole:GetName(),
					sHeader=oTmpRole:GetHeader(),
					nLevel=oTmpRole:GetLevel(),
					nSchool=oTmpRole:GetSchool(),
					nGender=oTmpRole:GetGender(),
					nTeamID=0,
				}
				local oTeam = goTeamMgr:GetTeamByRoleID(nTmpRoleID)
				tInfo.nTeamID = oTeam and oTeam:GetID() or 0
				table.insert(tList, tInfo)
			end
		end
		oRole:SendMsg("TeamUnionMemberRet", {tList=tList})

	end, oRole:GetServer(), nGlobalService, oRole:GetSession(), oRole:GetID())
end

--发出邀请
function CTeam:InviteReq(oRole, nTarRoleID)
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	if not oTarRole then
		return
	end
	if not oTarRole:IsOnline() then
		return oRole:Tips("对方不在线")
	end
	if goTeamMgr:GetTeamByRoleID(nTarRoleID) then
		return oRole:Tips("对方已有队伍，无法邀请其加入队伍")
	end

	local bPermit, sReason = self:CheckSceneJoinTeam(oTarRole,3)
	if not bPermit then
		oRole:Tips("对方正在活动场景，无法邀请")
		return
	end
	local nActState = oRole:GetActState()
	if nActState == gtRoleActState.eWedding then
		oRole:Tips("正在举行婚礼，请专心一点哦")
		return
	elseif nActState == gtRoleActState.ePalanquinParade then
		oRole:Tips("正在花轿游行中，请专心一点哦")
		return
	end

	local nTarActState = oTarRole:GetActState()	
	if nTarActState == gtRoleActState.eWedding then
		oRole:Tips("对方正在举行婚礼，无法邀请")
		return
	elseif nTarActState == gtRoleActState.ePalanquinParade then
		oRole:Tips("对方正在花轿游行中，无法邀请")
		return
	end
	oRole:Tips(string.format("已邀请%s加入队伍，请耐心等待回复", oTarRole:GetName()))
	--队长
	if self:GetLeader().nRoleID == oRole:GetID() then
		local sCont = string.format("%s 邀请你加入队伍", oRole:GetName())
		local tMsg = {sCont=sCont, tOption={"拒绝邀请", "接受邀请"}, nTimeOut=60}

		goClientCall:CallWait("ConfirmRet", function(tData)
			if tData.nSelIdx == 1 then
				return oRole:Tips(string.format("%s 拒绝了你的入队邀请", oTarRole:GetName()))
			end
			if tData.nSelIdx == 2 then
				if self.m_oTeamMgr:GetTeamByRoleID(nTarRoleID) then
					return oTarRole:Tips("你已经有队伍了")
				end
				local oTeam = self.m_oTeamMgr:GetTeamByID(self.m_nID)
				if not oTeam then
					return oTarRole:Tips("队伍已解散")
				end
				oTeam:Join(nTarRoleID, true)
			end
		end, oTarRole, tMsg)

	--队员
	else
		local sCont = string.format("%s 邀请你加入队伍", oRole:GetName())
		local tMsg = {sCont=sCont, tOption={"拒绝邀请", "申请入队"}, nTimeOut=60}
		goClientCall:CallWait("ConfirmRet", function(tData)
			if tData.nSelIdx == 1 then
				return oRole:Tips(string.format("%s 拒绝了你的入队邀请", oTarRole:GetName()))
			end
			if tData.nSelIdx == 2 then
				if self.m_oTeamMgr:GetTeamByRoleID(nTarRoleID) then
					return oTarRole:Tips("你已经在队伍中")
				end
				local oTeam = self.m_oTeamMgr:GetTeamByID(self.m_nID)
				if not oTeam then
					return oTarRole:Tips("队伍已解散")
				end
				oTeam:JoinApplyReq(oTarRole)
			end
		end, oTarRole, tMsg)

	end

end

--检测申请失效
function CTeam:CheckApplyExpire()
	local nCount = 0
	local nNowTime = os.time()
	for k, nTime in pairs(self.m_tApplyMap) do
		if nNowTime - nTime >= 5*60 then
			self.m_tApplyMap[k] = nil
			self:MarkDirty(true)
		else
			nCount = nCount + 1
		end
	end
	return nCount
end

--申请入队
function CTeam:JoinApplyReq(oRole, bNoTips)
	local bPermit, sReason = self:CheckSceneJoinTeam(oRole,1)
	if not bPermit then
		if sReason then
			oRole:Tips(sReason)
		end
		return
	end
	local nRoleActState = oRole:GetActState()
	if nLeaderActState == gtRoleActState.eWedding then
		oRole:Tips("正在举行婚礼，请专心一点哦")
		return
	elseif nLeaderActState == gtRoleActState.ePalanquinParade then
		oRole:Tips("正在花轿游行中，请专心一点哦")
		return
	end

	local tTeamLeader = self.m_tRoleList[1]
	local oLeader = goGPlayerMgr:GetRoleByID(tTeamLeader.nRoleID)
	if not oLeader then
		return
	end
	local nLeaderActState = oLeader:GetActState()	
	if nLeaderActState == gtRoleActState.eWedding then
		oRole:Tips("对方正在举行婚礼，无法邀请")
		return
	elseif nLeaderActState == gtRoleActState.ePalanquinParade then
		oRole:Tips("对方正在花轿游行中，无法邀请")
		return
	end

	local nCount = self:CheckApplyExpire()
	if nCount >= nMaxApplys then
		if not bNoTips then
			oRole:Tips("对方队伍申请人数已达上限")
		end
		return 
	end
	if self.m_oTeamMgr:GetTeamByRoleID(oRole:GetID()) then
		if not bNoTips then
			oRole:Tips("已在队伍中，请先退出再加入他人队伍")
		end
		return 
	end
	if self.m_tApplyMap[oRole:GetID()] then
		if not bNoTips then
			oRole:Tips("您已经申请过该队伍")
		end
		return
	end
	if self.m_oTeamMgr:IsTeamMatching(self:GetID()) then 
		self:Join(oRole:GetID(), true) 
	else
		self.m_tApplyMap[oRole:GetID()] = os.time()
		self:MarkDirty(true)
		oRole:Tips("已申请加入对方队伍，正在等待队长确认")
		local tLeader = self:GetLeader()
		assert(tLeader)
		local oRoleLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
		assert(oRoleLeader, tLeader.nRoleID)
		self:ApplyListReq(oRoleLeader)
	end
end

--接受入队申请
function CTeam:AgreeJoinReq(oRole, nTarRoleID)
	self:CheckApplyExpire()
	if not self:IsLeader(oRole:GetID()) then
		return oRole:Tips("队长才能操作")
	end
	if not self.m_tApplyMap[nTarRoleID] then
		return oRole:Tips("申请已超时")
	end
	local nRoleActState = oRole:GetActState()
	if nRoleActState == gtRoleActState.eWedding then
		self.m_tApplyMap[nTarRoleID] = nil
		oRole:Tips("正在举行婚礼，对方无法入队")
		self:MarkDirty(true)
		return
	elseif nRoleActState == gtRoleActState.ePalanquinParade then
		self.m_tApplyMap[nTarRoleID] = nil
		oRole:Tips("正在花轿游行中，对方无法入队")
		self:MarkDirty(true)
		return
	end

	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	local nTarActState = oTarRole:GetActState()	
	if nTarActState == gtRoleActState.eWedding then
		self.m_tApplyMap[nTarRoleID] = nil
		oRole:Tips("对方正在举行婚礼，无法入队")
		self:MarkDirty(true)
		return
	elseif nTarActState == gtRoleActState.ePalanquinParade then
		self.m_tApplyMap[nTarRoleID] = nil
		oRole:Tips("对方正在花轿游行中，无法入队")
		self:MarkDirty(true)
		return
	end


	local bPermit, sReason = self:CheckSceneJoinTeam(oTarRole,2)
	if not bPermit then
		self.m_tApplyMap[nTarRoleID] = nil
		oRole:Tips("对方正在活动场景，无法加入队伍")
		self:MarkDirty(true)
		return
	end
	if self.m_oTeamMgr:GetTeamByRoleID(nTarRoleID) then
		self.m_tApplyMap[nTarRoleID] = nil
		self:MarkDirty(true)
		return oRole:Tips("对方已有队伍")
	end
	if self:Join(nTarRoleID, true) then
		self.m_tApplyMap[nTarRoleID] = nil
		self:MarkDirty(true)
	end
	self:ApplyListReq(oRole)
end

function CTeam:TeamClearApplyListReq(oRole)
	print("CTeam:TeamClearApplyListReq***")
	if not self:IsLeader(oRole:GetID()) then
		return oRole:Tips("队长才能操作")
	end
	self.m_tApplyMap = {}
	self:MarkDirty(true)
	self:ApplyListReq(oRole)
end

--申请列表请求
function CTeam:ApplyListReq(oRole)
	if not oRole or not oRole:IsOnline() then 
		return 
	end
	self:CheckApplyExpire()
	local tList = {}
	for nRoleID, nTime in pairs(self.m_tApplyMap) do
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		local tInfo = {}
		tInfo.nID = oRole:GetID()
		tInfo.sName = oRole:GetName()
		tInfo.sHeader = oRole:GetHeader()
		tInfo.nGender = oRole:GetGender()
		tInfo.nSchool = oRole:GetSchool()
		tInfo.nLevel = oRole:GetLevel()
		tInfo.nTime = nTime
		table.insert(tList, tInfo)
	end
	oRole:SendMsg("TeamApplyListRet", {tList=tList})
	print("ApplyListReq***", tList)
end	

--交换位置请求
function CTeam:ExchangeReq(oRole, nIndex1, nIndex2)
	if (nIndex1 < 2 or nIndex1 > #self.m_tRoleList) or (nIndex2 < 2 or nIndex2 > #self.m_tRoleList) then
		return oRole:Tips("位置非法")
	end
	if nIndex1 == nIndex2 then
		return
	end

	if not self:IsLeader(oRole:GetID()) then
		return oRole:Tips("队长才能操作")
	end
	local tTmpRole = self.m_tRoleList[nIndex1]
	self.m_tRoleList[nIndex1] = self.m_tRoleList[nIndex2]
	self.m_tRoleList[nIndex2] = tTmpRole
	self:MarkDirty(true)
	self:SyncTeam()
	self:SyncLogicCache()
end

--召回
function CTeam:CallReturnReq(oRole)
	if not self:IsLeader(oRole:GetID()) then
		return oRole:Tips("队长才能操作")
	end

	local nCallNum = 0
	for k = 2, #self.m_tRoleList do
		local tRole = self.m_tRoleList[k]
		if tRole.bLeave then
			local oTmpRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
			if oTmpRole:IsOnline() then
				nCallNum = nCallNum + 1
			end
		end
	end

	if #self.m_tRoleList <= 1 or nCallNum <= 0 then
		return oRole:Tips("没有暂离状态的队员可召回")
	end

	local bCall = true
	local sReason = nil
	if not oRole:IsInWorldServer() then
		bCall, sReason = false, "只有在跨服场景或幻境副本里才可以召唤队员哦~"
	end
	if not bCall then 
		if sReason and type(sReason) == "string" then 
			oRole:Tips(sReason)
		end
		return 
	end

	for k = 2, #self.m_tRoleList do
		local tRole = self.m_tRoleList[k]
		if tRole.bLeave then
			local oTmpRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
			if oTmpRole:IsOnline() then
				local tMsg = {sCont="队长召回你立即归队", tOption={"取消", "归队"}, nTimeOut=60}
				goClientCall:CallWait("ConfirmRet", function(tData)
					if tData.nSelIdx == 1 then
						return
					end
					if tData.nSelIdx == 2 then
						self:ReturnTeamReq(oTmpRole)
					end
				end, oTmpRole, tMsg)
			end
		end
	end
	oRole:Tips("召回指令已发出，请等待队员确认。。。")
end

function CTeam:CheckPreQuit(nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then 
		return 
	end
	local tRole, nIndex = self:GetRole(nRoleID)
	if not tRole then
		return
	end
	local tPreQuit = tRole.tPreQuit
	if not tPreQuit or not tPreQuit.bQuit then 
		return 
	end
	self:QuitReq(oRole, tPreQuit.bKick)
end

--广播战斗状态
function CTeam:BroadcastBattleInfo(oRole, nBattleID)
	local tMsg = {
		nTeamID = self:GetID(),
		nMemType = 1,
		nID = oRole:GetID(),
		nBattleID = nBattleID,
	}
	self:BroadcastTeam("TeamMemberInfoChangeRet", tMsg)
end

function CTeam:OnBattleBegin(oRole)
	local nRoleID = oRole:GetID()
	if not self:IsInTeam(nRoleID) then 
		return 
	end
	--广播战斗开始
	self.m_nBattleID = oRole:GetBattleID()
	self:BroadcastBattleInfo(oRole, self.m_nBattleID)
end

function CTeam:OnBattleEnd(oRole, tBTRes)
	--广播战斗结束
	if (self.m_nBattleID or tBTRes.nBattleID) == tBTRes.nBattleID then
		self.m_nBattleID = 0
		for _, tRole in ipairs(self.m_tRoleList) do
			local oTmpRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
			if oTmpRole then self:BroadcastBattleInfo(oTmpRole, 0) end
		end
	end

	local nRoleID = oRole:GetID()
	self:CheckPreQuit(nRoleID)

	if not self:IsInTeam(nRoleID) then 
		return 
	end
	if tBTRes.nEndType == gtBTRes.eEscape then 
		self:LeaveTeamReq(oRole)
	end

	if self:GetMembers() <= 0 then --LeaveTeam中触发了解散队伍
		return 
	end

	if not oRole:IsOnline() then --战斗结束时，角色不在线，说明，战斗过程中，角色离线
		--检查队伍是否需要解散
		self:CheckTeamRemoveState()
	end
	if not self:IsInTeam(nRoleID) then 
		return 
	end
	
	local oLeader = self:GetLeaderRole()
	assert(oLeader)
	local nLeaderDupMixID = oLeader:GetDupMixID()

	--需要判断队伍中暂离的机器人，如果在同一个场景，则尝试归队，否则退出队伍
	--某些情况下(比如战斗中)，匹配到机器人之后，不满足归队条件，导致加入队伍时，即是暂离队伍状态
	local tReturnList = {} --缓存列表，防止回调事件影响，在外层处理
	local tQuitList = {}
	for k = 2, #self.m_tRoleList do 
		local tRole = self.m_tRoleList[k]
		if CUtil:IsRobot(tRole.nRoleID) and tRole.bLeave then 
			local oRobot = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
			assert(oRobot)
			local nRobotDupMixID = oRobot:GetDupMixID()
			if nLeaderDupMixID == nRobotDupMixID then 
				tReturnList[tRole.nRoleID] = oRobot
			else
				tQuitList[tRole.nRoleID] = oRobot
			end
		end
	end
	for nRobotID, oRobot in pairs(tReturnList) do 
		self:ReturnTeamReq(oRobot)
	end
	for nRobotID, oRobot in pairs(tQuitList) do 
		if self:IsInTeam(nRobotID) then 
			self:QuitReq(oRobot)
		end
	end

	--可能此时已在回调事件中离开队伍
	if not self:IsInTeam(nRoleID) then 
		return 
	end
	if self:IsLeave(nRoleID) and self:IsPreReturn(nRoleID) then 
		self:ReturnTeamReq(oRole)
	end
end

--玩家上线
function CTeam:Online(oRole)
	print("CTeam:Online***", oRole:GetID())
	local tRole, tRoleIndex = self:GetRole(oRole:GetID())
	if not tRole then
		return
	end

	local bLeader = self:IsLeader(oRole:GetID())
	if not bLeader then 
		--如果队长离线，则将该玩家提升为新队长
		--队长离线时，都会尝试将队长转交给在线的玩家，如果当前队长离线，说明整个队伍都没成员在线
		local tLeader = self:GetLeader()
		local oLeaderRole = self:GetLeaderRole()
		if oLeaderRole and not oLeaderRole:IsOnline() then 
			self.m_tRoleList[1] = tRole
			self.m_tRoleList[tRoleIndex] = tLeader
			self:OnLeaderChange(tLeader.nRoleID)
		end
	end
	if not self:IsLeader(oRole:GetID()) and not tRole.bLeave then
		self:ReturnTeamReq(oRole)
	end
	self:SyncTeam()
end

--玩家下线
function CTeam:Offline(oRole)
	local nRoleID = oRole:GetID()
	self:CheckPreQuit(nRoleID)
	if not self:IsInTeam(nRoleID) then 
		return 
	end

	local tRole = self:GetRole(oRole:GetID())
	if not tRole then
		return
	end

	local nRoleID = oRole:GetID()
	--如果是队长则自动移交队长
	if self:IsLeader(nRoleID) then 
		for nIndex, tRoleData in ipairs(self:GetRoleList()) do 
			if tRoleData.nRoleID ~= nRoleID and not tRoleData.bLeave then 
				local oTempRole = goGPlayerMgr:GetRoleByID(tRoleData.nRoleID)
				if oTempRole and oTempRole:IsOnline() and not oTempRole:IsRobot() then  --必须满足在线且未暂离
					local tTmpRole = self.m_tRoleList[1]
					self.m_tRoleList[1] = self.m_tRoleList[nIndex]
					self.m_tRoleList[nIndex] = tTmpRole
					-- self:SetLeaveState(tTmpRole, true)
					self:OnLeaderChange(nRoleID)
					break
				end
			end
		end
		--如果当前还是队长，如果有在线的队员，则在线的队员都是暂离状态
		--尝试移交给某个在线的玩家
		if self:IsLeader(nRoleID) then 
			for nIndex, tRoleData in ipairs(self:GetRoleList()) do 
				if tRoleData.nRoleID ~= nRoleID then 
					local oTempRole = goGPlayerMgr:GetRoleByID(tRoleData.nRoleID)
					if oTempRole and oTempRole:IsOnline() and not oTempRole:IsRobot() then  --必须满足在线且未暂离
						local tTmpRole = self.m_tRoleList[1]
						self.m_tRoleList[1] = self.m_tRoleList[nIndex]
						self.m_tRoleList[nIndex] = tTmpRole
						-- self:SetLeaveState(tTmpRole, true)
						self:OnLeaderChange(nRoleID)
						break
					end
				end
			end
		end
	end
	-- if not oRole:IsInBattle() then --否则这里会导致玩家战斗中离开队伍
	-- 	self:CheckTeamRemoveState()
	-- end 
	self:SyncTeam()
	self:SyncLogicCache() --防止缓存数据不一致
end

--当角色在逻辑服释放
function CTeam:OnRoleRelease(oRole) 
	if not oRole:IsRobot() then 
		self:LeaveTeamReq(oRole)
	else
		self:QuitReq(oRole)
	end
	if not self:IsInTeam(oRole:GetID()) then --可能已经触发离开队伍了
		return 
	end
	self:CheckTeamRemoveState()
end

--踢队员
function CTeam:KickReq(oRole, nTarRoleID)
	if not self:IsLeader(oRole:GetID()) then
		return oRole:Tips("队长才能操作")
	end
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	if not oTarRole then
		return
	end
	self:QuitReq(oTarRole, true)
end

--移交队长
function CTeam:TransferLeaderReq(oRole, nTarRoleID)
	if not self:IsLeader(oRole:GetID()) then
		return oRole:Tips("队长才能操作")
	end
	if oRole:GetID() == nTarRoleID then
		return
	end
	local tTarRole, nIndex = self:GetRole(nTarRoleID)
	if not tTarRole then
		return
	end
	if nIndex == 1 then
		return
	end
	if tTarRole.bLeave then
		return oRole:Tips("需要对方为归队状态才能移交队长")
	end
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	if not oTarRole then return end
	if oTarRole:IsRobot() then 
		oRole:Tips(string.format("%s拒绝了担任队长", oTarRole:GetFormattedName()))
		return 
	end
	local tTmpRole = self.m_tRoleList[1]
	self.m_tRoleList[1] = self.m_tRoleList[nIndex]
	self.m_tRoleList[nIndex] = tTmpRole
	self:MarkDirty(true)
	self:OnLeaderChange(tTmpRole.nRoleID)
	self:SyncTeam()

	-- oTarRole:Tips("已被任命为队长")
	-- local sCont = string.format("%s 成为队长", oRole:GetName())
	-- --队伍频道
	-- goTalk:SendTeamMsg(oRole, sCont, true)
end

--委任指挥
function CTeam:CommandReq(oRole)
end

--申请带队
function CTeam:ApplyLeaderReq(oRole)
	if self:IsLeader(oRole:GetID()) then
		return oRole:Tips("你已经是队长")
	end
	local tApplyRole = self:GetRole(oRole:GetID())
	if tApplyRole.bLeave then
		return oRole:Tips("请先归队")
	end

	local nLastApplyTime = tApplyRole.nApplyTime or os.time()
	local nInterval = 120-(os.time()-nLastApplyTime)
	if nInterval > 0 then
		return oRole:Tips(string.format("请%d秒后再申请", nInterval))
	end
	if self.m_nLeaderActivityAsking > 0 then
		return oRole:Tips("系统投票进行中")
	end

	--同时只能有一个申请
	local function _fnCheckApply()
		if not self.m_tApplyLeader.bInvalid then
			local oTmpRole = goGPlayerMgr:GetRoleByID(self.m_tApplyLeader.nRoleID)
			return oRole:Tips(string.format("%s已发起申请带队，请稍后...", oTmpRole:GetName()))
		end
		return true
	end
	if not _fnCheckApply() then
		return
	end

	local tMsg = {sCont="是否发起申请带队？", tOption={"取消", "确定"}, nTimeOut=60}
	goClientCall:CallWait("ConfirmRet", function(tData)
		if tData.nSelIdx == 1 then return end
		if tData.nSelIdx == 2 then
			if not _fnCheckApply() then return end

			tApplyRole.nApplyTime = os.time()
			self.m_tApplyLeader = {nRoleID=oRole:GetID(), nAgrees=0, nDenys=0, bInvalid=false}
			self:MarkDirty(true)

			GetGModule("TimerMgr"):Clear(self.m_nApplyLeaderTimer)
			self.m_nApplyLeaderTimer = GetGModule("TimerMgr"):Interval(30, function() self:OnApplyLeaderTimer(oRole:GetID()) end)

			local sNames = ""
			for nIndex, tTmpRole in ipairs(self.m_tRoleList) do
				if tTmpRole.nRoleID ~= tApplyRole.nRoleID then
					local sTmpName  = goGPlayerMgr:GetRoleByID(tTmpRole.nRoleID):GetName()
					sNames = sNames..sTmpName.." "
				end
			end
			oRole:Tips(string.format("请等待队员 %s 确认", sNames))

			--队伍聊天
			goTalk:SendTeamMsg(oRole, string.format("%s发起了申请带队投票", oRole:GetName()), true)

			--向队员发出投票框
			for nIndex, tTmpRole in ipairs(self.m_tRoleList) do
				if tTmpRole.nRoleID ~= tApplyRole.nRoleID then
					local oTmpRole = goGPlayerMgr:GetRoleByID(tTmpRole.nRoleID)
					local tMsg = {nType=1,sCont=string.format("%s申请带队，是否同意？", oRole:GetName()), tOption={"拒绝", "同意"}, nTimeOut=30, nTimeOutSelIdx=2}

					goClientCall:CallWait("ConfirmRet", function(tData)
						if self.m_tApplyLeader.bInvalid then
							return oTmpRole:Tips("该投票已失效")
						end

						--拒绝
						if tData.nSelIdx == 1 then
							self.m_tApplyLeader.nDenys = self.m_tApplyLeader.nDenys + 1
							if not self:IsLeader(oTmpRole:GetID()) then
								goTalk:SendTeamMsg(oRole, string.format("%s拒绝%s的申请带队", oTmpRole:GetName(), oRole:GetName()), true)

							--队长30秒内拒绝
							elseif os.time() - tApplyRole.nApplyTime < 30 then
								self.m_tApplyLeader.bInvalid = true
								GetGModule("TimerMgr"):Clear(self.m_nApplyLeaderTimer)
								self.m_nApplyLeaderTimer =nil
								self:BroadcastTeam("TipsMsgRet", {sCont=string.format("队长拒绝%s的申请带队", oRole:GetName())})
								return

							end
							--所有人完成了投票
							if self.m_tApplyLeader.nDenys+self.m_tApplyLeader.nAgrees >= self:GetMembers()-1 then
								self:OnApplyLeaderTimer(oRole:GetID()) 
							end

						--同意
						elseif tData.nSelIdx == 2 then
							self.m_tApplyLeader.nAgrees = self.m_tApplyLeader.nAgrees + 1
							if not self:IsLeader(oTmpRole:GetID()) then
								goTalk:SendTeamMsg(oRole, string.format("%s同意%s的申请带队", oTmpRole:GetName(), oRole:GetName()), true)

							elseif os.time() - tApplyRole.nApplyTime < 30 then
							--队长30秒内同意
								self.m_tApplyLeader.bInvalid = true
								GetGModule("TimerMgr"):Clear(self.m_nApplyLeaderTimer)
								self.m_nApplyLeaderTimer =nil
								-- self:BroadcastTeam("TipsMsgRet", {sCont=string.format("%s成为新队长", oRole:GetName())})

								local tTarRole, nIndex  = self:GetRole(oRole:GetID())
								if not tTarRole then
									return
								end

								local tLeaderRole = self.m_tRoleList[1]
								self.m_tRoleList[1] = tTarRole
								self.m_tRoleList[nIndex] = tLeaderRole
								self:MarkDirty(true)

								self:OnLeaderChange(tLeaderRole.nRoleID)
								self:SyncTeam()
								return

							end
							--所有人完成了投票
							if self.m_tApplyLeader.nDenys+self.m_tApplyLeader.nAgrees >= self:GetMembers()-1 then
								self:OnApplyLeaderTimer(oRole:GetID()) 
							end

						end
					end, oTmpRole, tMsg)
				end
			end

		end
	end, oRole, tMsg)
end

--申请带队到时
function CTeam:OnApplyLeaderTimer(nRoleID)
	GetGModule("TimerMgr"):Clear(self.m_nApplyLeaderTimer)
	self.m_nApplyLeaderTimer = nil

	if self.m_tApplyLeader.bInvalid then
		return
	end

	self.m_tApplyLeader.bInvalid = true
	self.m_tApplyLeader.nAgrees = self.m_tApplyLeader.nAgrees + 1

	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if self.m_tApplyLeader.nAgrees > self.m_tApplyLeader.nDenys or self.m_tApplyLeader.nAgrees >= 3 then
		local tTarRole, nIndex = self:GetRole(nRoleID)
		if not tTarRole then return end

		local tTmpRole = self.m_tRoleList[1]
		self.m_tRoleList[1] = tTarRole
		self.m_tRoleList[nIndex] = tTmpRole
		self:MarkDirty(true)

		self:OnLeaderChange(tTmpRole.nRoleID)
		self:SyncTeam()

		-- self:BroadcastTeam("TipsMsgRet", {sCont=string.format("%s成为新队长", oRole:GetName())})
		-- goTalk:SendTeamMsg(oRole, sCont, true)
		return 
	end
	if self.m_tApplyLeader.nAgrees <= self.m_tApplyLeader.nDenys then
		return oRole:Tips("申请带队失败")
	end
end

--队长发呆主动推送申请队长条件
function CTeam:LeaderActivityCond()
	--需要人数>=2
	if #self.m_tRoleList < 2 then
		return
	end
	--需要都在线且归队
	for _, tRole in ipairs(self.m_tRoleList) do
		if tRole.bLeave then
			return
		end
		local oTmpRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
		if not oTmpRole:IsOnline() then
			return
		end
	end
	return true
end

--发起队长发呆换队长投票
function CTeam:LaunchLeaderActivityVote()
	if #self.m_tRoleList < 2 then
		return print("没有队员，发起投票失败")
	end
	if self.m_nLeaderActivityAsking > 0 then
		return print("队长发呆投票进行中，发起投票失败")
	end
	if not self.m_tApplyLeader.bInvalid then
		return print("有人申请队长中")
	end

	local tLeader = self.m_tRoleList[1]
	local oLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
	local sCont = string.format("队长%s发呆有点久，大家可以申请队长带队了", oLeader:GetName())
	goTalk:SendTeamMsg(oLeader, sCont, true)

	self.m_nLeaderActivityAsking = #self.m_tRoleList - 1 
	for k = 2, #self.m_tRoleList do
		local tRole = self.m_tRoleList[k]
		local oTmpRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
		local tMsg = {nType=2, sCont="你现在可以申请为队长，是否同意申请？", tOption={"取消", "同意"}, nTimeOut=30, nTimeOutSelIdx=1}
		goClientCall:CallWait("ConfirmRet", function(tData)
			if tData.nSelIdx == 2 then
				local nCurrLeader = self.m_tRoleList[1]
				if nCurrLeader == tLeader.nRoleID then --还没有人同意
					self.m_tRoleList[1] = self.m_tRoleList[2]
					self.m_tRoleList[2] = tTmpRole
					self:MarkDirty(true)
					self:OnLeaderChange(tTmpRole.nRoleID)
					-- goTalk:SendTeamMsg(oTeamMgr, string.format("%s已成功申请为队长", oTmpRole:GetName()), true)
					self.m_nLeaderActivityAsking = 0
				end
			end
			self.m_nLeaderActivityAsking = self.m_nLeaderActivityAsking -1 

		end, oTmpRole, tMsg)
	end
end

--队长发呆检测
function CTeam:LeaderActivityCheck(nRoleID, nInactivityTime)
	--是否队长
	if not self:IsLeader(nRoleID) then
		return
	end
	--需发呆10分钟
	if nInactivityTime < 10*60 then
		return
	end
	--条件判断
	if not self:LeaderActivityCond() then
		return
	end
	--10分钟推送一次
	if os.time()-self.m_nLeaderActivityNotify < 10*60 then
		return
	end
	self.m_nLeaderActivityNotify = os.time()
	self:LaunchLeaderActivityVote()
end

--角色信息
function CTeam:MakeRoleInfo(nIndex, oRole, bLeave)
	local tInfo = {}
	tInfo.nMemType = 1
	tInfo.nID = oRole:GetID()
	tInfo.sName = oRole:GetName()
	tInfo.nSchool = oRole:GetSchool()
	tInfo.sHeader = oRole:GetHeader()
	tInfo.nGender = oRole:GetGender()
	tInfo.nLevel = oRole:GetLevel()
	tInfo.bOnline = oRole:IsOnline()
	tInfo.bLeave = bLeave
	tInfo.nPartnerType = 0	
	tInfo.nPos = nIndex
	tInfo.nBattleID = oRole:GetBattleID()
	return tInfo
end

--伙伴信息
function CTeam:MakePartnerInfo(nIndex, tPartnerInfo)
	local tPartnerInfo = tPartnerInfo or self.m_tLeaderPartnerInfo
	if not tPartnerInfo then
		return
	end
	local tPartner = tPartnerInfo.tPartner[nIndex]
	if not tPartner then
		return
	end

	local tInfo = {}
	tInfo.nMemType = 2
	tInfo.nID = tPartner.nID
	tInfo.sName = tPartner.sName
	tInfo.nSchool = tPartner.nSchool or 0
	tInfo.sHeader = tPartner.sHeader
	tInfo.nGender = tPartner.nGender
	tInfo.nLevel = tPartner.nLevel
	tInfo.bOnline = true
	tInfo.bLeave = false
	tInfo.nPartnerType = tPartner.nType
	tInfo.nPos = 0
	return tInfo
end

function CTeam:OnNameChange(oRole)
	if not oRole then return end
	self:SyncTeam()
end


--广播队伍信息
function CTeam:SyncTeam(oRole)

	local function _MakeTeamMsg()
		local tMsg = {nTeamID=self:GetID(), nFmtID=0,nFmtLv=0,tTeam={}}
		if self.m_tLeaderPartnerInfo then
			tMsg.nFmtID = self.m_tLeaderPartnerInfo.nFmtID
			tMsg.nFmtLv = self.m_tLeaderPartnerInfo.nFmtLv
		end

		for k, tRole in ipairs(self.m_tRoleList) do
			local oRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
			table.insert(tMsg.tTeam, self:MakeRoleInfo(k, oRole, tRole.bLeave))
		end
		for k = 1, 5-#self.m_tRoleList do
			local tInfo = self:MakePartnerInfo(k)
			if tInfo then 
				table.insert(tMsg.tTeam, tInfo)
				tInfo.nPos = #tMsg.tTeam
			else
				table.insert(tMsg.tTeam, {})
			end
		end
		return tMsg
	end

	local tLeader = self:GetLeader()
	if not tLeader then 
		return 
	end
	local oLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
	if not oLeader:IsReleasedd() then
		Network.oRemoteCall:CallWait("WGlobalTeamPartnerReq", function(tPartnerInfo)
			if tPartnerInfo then
				self.m_tLeaderPartnerInfo = tPartnerInfo
				self:MarkDirty(true)
			else
				LuaTrace("CTeam:SyncTeam 获取队长伙伴信息失败", oLeader:GetName(), oLeader:IsOnline(), oLeader:IsReleasedd())
			end

			local tMsg = _MakeTeamMsg()
			if not tMsg then
				return
			end
			if oRole then
				oRole:SendMsg("TeamRet", tMsg)
			else
				self:BroadcastTeam("TeamRet", tMsg)
			end

		end, oLeader:GetStayServer(), oLeader:GetLogic(), oLeader:GetSession(), oLeader:GetID())

	else
		local tMsg = _MakeTeamMsg()
		if not tMsg then return end

		if oRole then
			oRole:SendMsg("TeamRet", tMsg)
		else
			self:BroadcastTeam("TeamRet", tMsg)
		end

	end
end

--发送无队伍信息
function CTeam:SyncTeamEmpty(nRoleID)
	print("CTeam:SyncTeamEmpty***", nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole:IsOnline() or oRole:IsRobot() then
		return
	end

	local tMsg = {nTeamID=0, nFmtID=0,nFmtLv=0,tTeam={}}
	Network.oRemoteCall:CallWait("WGlobalTeamPartnerReq", function(tPartnerInfo)
		if not tPartnerInfo then
			return LuaTrace("CTeam:SyncTeamEmpty 获取队长伙伴信息失败", oRole:GetName(), oRole:IsOnline(), oRole:IsReleasedd())
		end
		tMsg.nFmtID = tPartnerInfo.nFmtID
		tMsg.nFmtLv = tPartnerInfo.nFmtLv

		--自己
		local tInfo = self:MakeRoleInfo(1, oRole, false)
		table.insert(tMsg.tTeam, tInfo)

		--伙伴
		for k = 1, 4 do
			local tInfo = self:MakePartnerInfo(k, tPartnerInfo)
			if tInfo then 
				tInfo.nPos = #tMsg.tTeam + 1
				table.insert(tMsg.tTeam, tInfo)
			else
				table.insert(tMsg.tTeam, {})
			end
		end
		oRole:SendMsg("TeamRet", tMsg)

	end, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID())
end

--取队伍平均等级
function CTeam:GetAvgLevel()
	local nTotalLevel = 0
	for _, tRole in ipairs(self.m_tRoleList) do
		local oRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
		nTotalLevel = nTotalLevel + oRole:GetLevel()
	end
	return math.floor(nTotalLevel/#self.m_tRoleList)
end

function CTeam:GetRoleListInfo()
	local tList = {}
	for nIndex, tRole in ipairs(self.m_tRoleList) do 
		local tInfo = {nRoleID = tRole.nRoleID, bLeave = tRole.bLeave, 
			bLeader = self:IsLeader(tRole.nRoleID), }
		table.insert(tList, tInfo)
	end
	return tList
end

