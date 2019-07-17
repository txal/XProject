--日志模块(支持世界服)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLogger:Ctor()
	CGModuleBase.Ctor(self, gtGModuleDef.tLogger)
	self.m_tRoleInfo = {}

	--任务类日志
	self.m_tTaskEventMap = {}
	self.m_tTaskEventMap[gtEvent.eAccepTask] = 10
	self.m_tTaskEventMap[gtEvent.eCompleteTask] = 11
    self.m_tTaskEventMap[gtEvent.eCompTargetTask] = 51
end

function CLogger:_GetRoleInfo(oRole)
	local tInfo = self.m_tRoleInfo
	tInfo.nServer = 0
	tInfo.nService = 0
	tInfo.nAccountID = 0
	tInfo.nRoleID = 0
	tInfo.sRoleName = ""
	tInfo.nSchool = 0
	tInfo.nLevel = 0
	tInfo.nVIP = 0

	if not oRole then
		return tInfo
	end

	tInfo.nServer = oRole:GetServer()
	tInfo.nService = GetGModule("ServerMgr"):GetLogService(tInfo.nServer)
	tInfo.nAccountID = oRole:GetAccountID()
	tInfo.nRoleID = oRole:GetID()
	tInfo.sRoleName = oRole:GetName()
	tInfo.nSchool = oRole:GetSchool()
	tInfo.nLevel = oRole:GetLevel()
	tInfo.nVIP = oRole:GetVIP()
	return tInfo
end

function CLogger:_normal_log(nEventID, sReason, oRole, Field1, Field2, Field3, Field4, Field5, Field6)
	assert(nEventID and sReason)

	Field1 = Field1 or ""
	Field2 = Field2 or ""
	Field3 = Field3 or ""
	Field4 = Field4 or ""
	Field5 = Field5 or ""
	Field6 = Field6 or ""

	local tInfo = self:_GetRoleInfo(oRole)
	if oRole then
		Network.oRemoteCall:Call("EventLogReq", tInfo.nServer, tInfo.nService, 0, nEventID, sReason, tInfo, Field1, Field2, Field3, Field4, Field5, Field6, os.time())

	else
		local oServerMgr = GetGModule("ServerMgr")
		local tLogList = oServerMgr:GetLogServiceList()
		for _, tConf in pairs(tLogList) do
			Network.oRemoteCall:Call("EventLogReq", tConf.nServer, tConf.nID, 0, nEventID, sReason, tInfo, Field1, Field2, Field3, Field4, Field5, Field6, os.time())
		end
	end
end

--事件日志
function CLogger:EventLog(nEventID, oRole, Field1, Field2, Field3, Field4, Field5, Field6)
	if nEventID == gtEvent.eOnline or nEventID == gtEvent.eOffline then --上线离线事件
		assert(oRole, "参数错误")
		local tInfo = self:_GetRoleInfo(oRole)
		local nType = nEventID == gtEvent.eOnline and 1 or 0
		Network.oRemoteCall:Call("OnlineLogReq", tInfo.nServer, tInfo.nService, 0, tInfo, nType, Field1, os.time())
		return

	elseif self.m_tTaskEventMap[nEventID] then --任务类
		assert(oRole, "参数错误")
		local tInfo = self:_GetRoleInfo(oRole)
		local nType = self.m_tTaskEventMap[nEventID]
		Network.oRemoteCall:Call("TaskLogReq", tInfo.nServer, tInfo.nService, 0, tInfo, nType, Field1, os.time())
		return

	end
	self:_normal_log(nEventID, 0, oRole, Field1, Field2, Field3, Field4, Field5, Field6)
end

--奖励日志
function CLogger:AwardLog(nEventID, sReason, oRole, nItemType, nItemID, nItemNum, Field1, Field2, Field3)
	assert(sReason and nItemType and nItemID and nItemNum, "参数错误")
	if nItemType == gtItemType.eCurr and (nItemID == gtCurrType.eYuanBao or nItemID == gtCurrType.eBYuanBao) then
	--元宝有单独日志
		assert(oRole, "参数错误")
		local tInfo = self:_GetRoleInfo(oRole)

		local nYuanBao = math.abs(nItemNum)
		if nEventID == gtEvent.eSubItem then
			nYuanBao = -nYuanBao
		end

		tInfo.sReason = sReason
		tInfo.nYuanBao = nYuanBao
		tInfo.nCurrYuanBao = tonumber(Field1)
		tInfo.nBind = nItemID==gtCurrType.eBYuanBao and 1 or 0

		Network.oRemoteCall:Call("YuanBaoLogReq", tInfo.nServer, tInfo.nService, 0, tInfo, os.time())
		return
	end
	self:_normal_log(nEventID, sReason, oRole, nItemType, nItemID, nItemNum, Field1, Field2, Field3)

end

--创建账号日志
function CLogger:CreateAccountLog(nSource, nAccountID, sAccountName, nVIP)
	assert(nSource and nAccountID and sAccountName and nVIP)
	--只会在本服创建账号
	assert(gnServerID < gnWorldServerID, "世界服不能创建账号!")
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(gnServerID)
	Network.oRemoteCall:Call("CreateAccountLogReq", gnServerID, nLogService, 0, nSource, nAccountID, sAccountName, nVIP, os.time())
end

--创建角色日志
function CLogger:CreateRoleLog(nAccountID, nRoleID, sRoleName, nLevel, sImgHeader, nGender, nSchool)
	assert(nAccountID and nRoleID and sRoleName and nLevel and nGender and nSchool)
	--只会在本服创建角色
	assert(gnServerID < gnWorldServerID, "世界服不能创建角色!")
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(gnServerID)
	Network.oRemoteCall:Call("CreateRoleLogReq", gnServerID, nLogService, 0, nAccountID, nRoleID, sRoleName, nLevel, sImgHeader, nGender, nSchool, os.time())
end

--更新账号数据
function CLogger:UpdateAccountLog(oRole, tParam) 
	local nAccountID = oRole:GetAccountID()
	local nServerID = oRole:GetServer()
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(nServerID)
	Network.oRemoteCall:Call("UpdateAccountLogReq", nServerID, nLogService, 0, nAccountID, tParam)
end

--更新角色数据
function CLogger:UpdateRoleLog(oRole, tParam) 
	assert(oRole and next(tParam))
	local nRoleID = oRole:GetID()
	local nServerID = oRole:GetServer()
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(nServerID)
	Network.oRemoteCall:Call("UpdateRoleLogReq", nServerID, nLogService, 0, nRoleID, tParam)
end

--@oSrcRole 邀请者
--@oTarRole 被邀请者 
function CLogger:InviteLog(oSrcRole, oTarRole)
	local nSrcServer = oSrcRole:GetServer()
	local nSrcRoleID = oSrcRole:GetID()

	local nTarServer = oTarRole:GetServer()
	local nTarRoleID = oTarRole:GetID()
	
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(nSrcServer)
	Network.oRemoteCall:Call("ShareLogReq", nSrcServer, nLogService, 0, nSrcServer, nSrcRoleID, nTarServer, nTarRoleID, os.time())
end

--聊天日志
function CLogger:TalkLog(oRole, tData)
	local nServer = oRole:GetServer()
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(nServer)
	Network.oRemoteCall:Call("TalkLogReq", nServer, nLogService, 0, tData)
end

--活动日志
--@nActID 活动ID
--@sActName 活动名字
--@tCost 活动消耗物品
--@tAward 活动获得物品
--@nCharge 充值类活动达到的充值数量
--@sExt1 保留字段1
--@sExt2 保留字段2
function CLogger:ActivityLog(oRole, nActID, sActName, tCost, tAward, nCharge, sExt1, sExt2, nSubActID, sSubActName)
	assert(nActID > 0, "活动ID错误")
	local tLog = {}
	tLog.actid = nActID
	tLog.acttype = ctHuoDongConf[nActID].nActType or 0
	tLog.actname = sActName or ""
	tLog.subactid = nSubActID or 0
	tLog.subactname = sSubActName or ""
	tLog.cost = tCost or {}
	tLog.award = tAward or {}
	tLog.charge = nCharge or ""
	tLog.ext1 = sExt1 or ""
	tLog.ext2 = sExt2 or ""

	tLog.roleid = oRole:GetID()
	tLog.level = oRole:GetLevel()
	tLog.vip = oRole:GetVIP()
	tLog.time = os.time()

	local nServer = oRole:GetServer()
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(nServer)
	Network.oRemoteCall:Call("ActivityLogReq", nServer, nLogService, 0, tLog)
end

--创建帮派日志
function CLogger:CreateUnionLog(oRole, nUnionID, nDisplayID, sUnionName, nUnionLevel, nLeaderID, sLeaderName, nCreateTime)
	local tLog = {
		nUnionID = nUnionID,	
		nDisplayID = nDisplayID,
		sUnionName = sUnionName,
		nUnionLevel = nUnionLevel,
		nLeaderID = nLeaderID,
		sLeaderName = sLeaderName,
		nCreateTime = nCreateTime,
	}
	local nServer = oRole:GetServer()
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(nServer)
	Network.oRemoteCall:Call("CreateUnionLogReq", nServer, nLogService, 0, tLog)
end
--删除帮派
function CLogger:DelUnionLog(nServer, nUnionID)
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(nServer)
	Network.oRemoteCall:Call("DelUnionLogReq", nServer, nLogService, 0, nUnionID)
end
--更新帮派日志
function CLogger:UpdateUnionLog(nServer, nUnionID, tParam)
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(nServer)
	Network.oRemoteCall:Call("UpdateUnionLogReq", nServer, nLogService, 0, nUnionID, tParam)
end
--创建帮派成员日志
function CLogger:CreateUnionMemberLog(oRole, nUnionID, nPosition, nJoinTime, nLeaveTime, nCurrContri, nTotalContri, nDayContri)
	local tLog = {
		nRoleID = oRole:GetID(),
		sRoleName = oRole:GetName(),
		nUnionID = nUnionID or 0,	
		nPosition = nPosition or 0,
		nJoinTime = nJoinTime or 0,
		nLeaveTime = nLeaveTime or 0,
		nCurrContri = nCurrContri or 0,
		nTotalContri = nTotalContri or 0,
		nDayContri = nDayContri or 0,
	}
	local nServer = oRole:GetServer()
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(nServer)
	Network.oRemoteCall:Call("CreateUnionMemberLogReq", nServer, nLogService, 0, tLog)
end
--更新帮派成员日志
function CLogger:UpdateUnionMemberLog(nServer, nRoleID, tParam)
	local oServerMgr = GetGModule("ServerMgr")
	local nLogService = oServerMgr:GetLogService(nServer)
	Network.oRemoteCall:Call("UpdateUnionMemberLogReq", nServer, nLogService, 0, nRoleID, tParam)
end
