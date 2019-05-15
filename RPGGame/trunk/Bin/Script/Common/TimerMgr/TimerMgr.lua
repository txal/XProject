--计时器管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CTimerMgr:Ctor()
	self.m_nCount = 0
	self.m_tTimerMap = {}
end

--注册计时器
function CTimerMgr:Interval(nSecondTime, _fnCallback)
	assert(nSecondTime > 0 and _fnCallback, "参数非法")
	local nTimerID = GlobalExport.RegisterTimer(math.floor(nSecondTime*1000), _fnCallback)
	assert(not self.m_tTimerMap[nTimerID], "计时器ID冲突")
	self.m_tTimerMap[nTimerID] = debug.traceback(nil, nil, 2)
	self.m_nCount = self.m_nCount + 1
	if self.m_nCount >= 100000 then
		LuaTrace("计时器太多了，要注意了!!", self.m_nCount)
	end
	return nTimerID
end

--清理计时器
function CTimerMgr:Clear(nTimerID)
	if not nTimerID or nTimerID == 0 then
		return
	end
	if not self.m_tTimerMap[nTimerID] then
		return
	end
	GlobalExport.CancelTimer(nTimerID)
	self.m_tTimerMap[nTimerID] = nil
	self.m_nCount = self.m_nCount - 1
	return true
end

--取计时器个数
function CTimerMgr:TimerCount()
	return self.m_nCount
end

function CTimerMgr:DebugLog()
	for nTimerID, tTraceback in pairs(self.m_tTimerMap) do 
		LuaTrace(string.format("定时器ID(%d)", nTimerID))
		LuaTrace(tTraceback)
	end
end

goTimerMgr = goTimerMgr or CTimerMgr:new()
