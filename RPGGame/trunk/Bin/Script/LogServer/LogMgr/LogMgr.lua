--日志管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLogMgr:Ctor()
	local nNextClearTime = self:GetNextClearTime()
	self.m_nClearTimer = goTimerMgr:Interval(nNextClearTime, function() self:OnClearTimer() end)

	self.m_tCheatCheck = {}
end

function CLogMgr:GetNextClearTime()
	return os.NextDayTime(os.time(), 5, 0, 0)
end

function CLogMgr:OnRelease()
	goTimerMgr:Clear(self.m_nClearTimer)
	self.m_nClearTimer = nil
end

function CLogMgr:OnClearTimer()
	LuaTrace("---清理15天前日志---")
	local nDelTime = os.time() - 15*24*3600
	local sql = string.format("delete from event_log where time<%d;", nDelTime)
	goMysqlPool:GameQuery(sql)
end

function CLogMgr:CheckCheat(nRoleID, nEvent, nItemType, nItemID, sReason)
	if nEvent ~= 3 then
		return
	end
	self.m_tCheatCheck = self.m_tCheatCheck or {}
	local sKey = string.format("%d-%d-%d-%d-%s", nRoleID, nEvent, nItemType, nItemID, sReason)
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

goLogMgr = goLogMgr or CLogMgr:new()
