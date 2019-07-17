--日志管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function LogMgr:Ctor()
	self.m_tCheatCheck = {}
	self.m_nClearTimer = GetGModule("TimerMgr"):Interval(self:GetNextClearTime(), function() self:OnClearTimer() end)
	self.m_oMysqlPool = CMysqlPool:new()
end

function LogMgr:Release()
	GetGModule("TimerMgr"):Clear(self.m_nClearTimer)
	self.m_nClearTimer = nil
end

function LogMgr:GetNextClearTime()
	return os.NextDayTime(os.time(), 5, 0, 0)
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

function LogMgr:OnClearTimer()
	LuaTrace("---清理15天前日志---")
	local nDelTime = os.time() - 15*24*3600
	local sSql = string.format("delete from event_log where time<%d;", nDelTime)
	goMysqlPool:GameQuery(sSql)
end

function LogMgr:CheckCheat(nRoleID, nEvent, nItemType, nItemID, sReason)
	if nEvent ~= 3 then
		return
	end
	self.m_tCheatCheck = self.m_tCheatCheck or {}
	local sKey = string.format("roleid:%d event:%d itemtype:%d itemid:%d reason:%s", nRoleID, nEvent, nItemType, nItemID, sReason)
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
		self.m_tCheatCheck[sKey] = {0, os.time()}
	end
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
	goMysqlPool:GameQuery(sSql)

	--检测作弊
	goLogMgr:CheckCheat(tInfo.nRoleID, nEventID, sField1, sField2, sReason)
end
