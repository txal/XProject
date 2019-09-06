--日志管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--本地化一下,加快访问速度
local gtGameSql = gtGameSql

function LogMgr:Ctor()
	CGModuleBase.Ctor(self, gtGModuleDef.tLogMgr)

	self.m_tCheatCheck = {}
	self.m_oMysqlPool = CMysqlPool:new()
	self.m_nClearLogTimer = GetGModule("TimerMgr"):Interval(self:GetNextClearTime(), function() self:OnClearLogTimer() end)
end

function LogMgr:Release()
	GetGModule("TimerMgr"):Clear(self.m_nClearLogTimer)
	self.m_nClearLogTimer = nil
end

function LogMgr:RegClearLogTimer()
	GetGModule("TimerMgr"):Clear(self.m_nClearLogTimer)
	local nNextClearTime = os.NextDayTime(os.time(), 5, 0, 0)
	self.m_nClearLogTimer = GetGModule("TimerMgr"):Interval(nNextClearTime, function() self:OnClearLogTimer() end)
end

function LogMgr:OnClearLogTimer()
	self:RegClearLogTimer()
	LuaTrace("---清理15天前日志---")
	local sSql = string.format("delete from event_log where time<%d;", os.time()-15*24*3600)
	self.m_oMysqlPool:GameAsyncQuery(sSql)
	self.m_tCheatCheck = {}
end

function LogMgr:CheckCheat(nRoleID, nEvent, nItemID, sReason)
	if nEvent ~= gtEvent.eAddItem then
		return
	end
	if not self.m_tCheatCheck then
		self.m_tCheatCheck or {}
	end

	local sKey = string.format("roleid:%d event:%d itemid:%d reason:%s", nRoleID, nEvent, nItemID, sReason)
	local tRecord = self.m_tCheatCheck[sKey]
	if not tRecord then
		tRecord = {0, os.time()}
		self.m_tCheatCheck[sKey] = tRecord
	end
	tRecord[1] = tRecord[1] + 1

	if tRecord[1] >= 100 then
		LuaTrace("可能有玩家刷奖励:", sKey, tRecord[1], debug.traceback())
	end
	if os.time() - tRecord[2] >= 60 then
		self.m_tCheatCheck[sKey] = nil
	end
end

function LogMgr:_StrField(xField)
	if not xField then
		return ""
	end
	if type(xField) == "number" then
		return tostring(xField)
	elseif type(xField) == "string" then
		return xField
	elseif type(xField) == "table" then
		return tostring(xField)
	end
	return xField
end

function LogMgr:EvenLog(nEventID, sReason, tRoleInfo, ...)
	tRoleInfo.sRoleName = self:_StrField(tRoleInfo.sRoleName)
	local tField = {...}
	local sField1 = _StrField(tField[1])
	local sField2 = _StrField(tField[2])
	local sField3 = _StrField(tField[3])
	local sField4 = _StrField(tField[4])
	local sField5 = _StrField(tField[5])
	local sField6 = _StrField(tField[6])
	local nTime = assert(tField[7])

	local sSql = string.format(gtGameSql.sInsertEventLogSql
		, nEventID, sReason, tRoleInfo.nAccountID, tRoleInfo.nRoleID, tRoleInfo.sRoleName, tRoleInfo.nLevel, tRoleInfo.nVIP
		, sField1, sField2, sField3, sField4, sField5, sField6, nTime)
	self.m_oMysqlPool:GameAsyncQuery(sSql)
	--检测作弊
	self:CheckCheat(tInfo.nRoleID, nEventID, sField1, sReason)
end

function LogMgr:CreateAccountLog(tAccountInfo)
	tAccountInfo.sAccountName = self:_StrField(tAccoutInfo.sAccountName)
	local sSql = string.format(gtGameSql.sInsertAccountSql
		, tAccountInfo.nSource
		, tAccountInfo.sChannel
		, tAccountInfo.nAccountID
		, tAccountInfo.sAccountName
		, tAccountInfo.nVIP
		, tAccountInfo.nTime)
	self.m_oMysqlPool:GameAsyncQuery(sSql)
end

function LogMgr:UpdateAccountLog(nAccountID, tParams)
	local sSetSql = ""
	for k, v in pairs(tParams) do
		sSetSql = sSetSql .. string.format("%s='%s',", k, self:_StrField(v))
	end
	sSetSql = string.sub(sSetSql, 1, -2)

	local sSql = string.format(gtGameSql.sUpdateAccountSql, sSetSql, nAccountID)
	self.m_oMysqlPool:GameAsyncQuery(sSql)
end

function CLogMgr:CreateRoleLog(tRoleInfo)
	tRoleInfo.sRoleName = self:_StrField(tRoleInfo.sRoleName)
	local sSql = string.format(gtGameSql.sInsertRoleSql
		, tRoleInfo.nAccountID
		, tRoleInfo.nRoleID
		, tRoleInfo.sRoleName
		, tRoleInfo.nLevel
		, tRoleInfo.sHeader
		, tRoleInfo.nGender
		, tRoleInfo.nSchool
		, tRoleInfo.nTime)
	self.m_oMysqlPool:GameAsyncQuery(sSql)
end

function CLogMgr:UpdateRoleLog(nRoleID, tParams)
	local sSetSql = ""
	for k, v in pairs(tParams) do
		sSetSql = sSetSql .. string.format("%s='%s',", k, self:_StrField(v))
	end
	sSetSql = string.sub(sSetSql, 1, -2)
	
	local sSql = string.format(gtGameSql.sUpdateRoleSql, sSetSql, nRoleID)
	self.m_oMysqlPool:GameAsyncQuery(sSql)
end

--上下线日志
function CLogMgr:OnlineLog(tRoleInfo, nOnlineType, nKeepTime, nTime)
	local sSql = string.format(gtGameSql.sOnlineLogSql, tRoleInfo.nAccountID, tRoleInfo.nRoleID, tRoleInfo.nLevel, tRoleInfo.nVIP, nOnlineType, nKeepTime, nTime)
	self.m_oMysqlPool:GameAsyncQuery(sSql)
end

--任务日志
function CLogMgr:TaskLog(tRoleInfo, nTaskType, nTaskID, nTaskState, nTime)
	local sSql = string.format(gtGameSql.sInsertTaskSql
		, tRoleInfo.nAccountID, tRoleInfo.nRoleID, tRoleInfo.nSchool, tRoleInfo.nLevel, tRoleInfo.nVIP, nTaskType, nTaskID, nTaskState, nTime)
	self.m_oMysqlPool:GameAsyncQuery(sSql)
end

--元宝日志
function CLogMgr:YuanBaoLog(tRoleInfo, sReason, nYuanBao, nCurrYuanBao, nBindFlag, nTime)
	local sSql = string.format(gtGameSql.sInsertYuanBaoSql
		, tRoleInfo.nAccountID, tRoleInfo.nRoleID, tRoleInfo.nLevel, tRoleInfo.nVIP, sReason, nYuanBao, nCurrYuanBao, nBindFlag, nTime)
	self.m_oMysqlPool:GameAsyncQuery(sSql)
end
