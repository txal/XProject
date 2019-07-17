--运维服务监控
CWatcher = CWatcher or class()

function CWatcher:Ctor()
	self.m_sToken = nil
	self.m_sSignURL = "http://watcher.hoodinn.com/api/sign?project=新梦诛&system=%s&service=%s" 
	self.m_sReportURL = "http://watcher.hoodinn.com/api/report?token=%s&status=%d&event=%s"
	self.m_sSignOutURL = "http://watcher.hoodinn.com/api/sign-out?token=%s"
	self.m_bSignOutOK = false

	self.m_nTimer = nil
	self.m_tServiceList = {
		{30, gnServerID, "LOG30超时"},
		{50, gnServerID, "LOGIC50超时"},
		{20, gnServerID, "GLOBAL20超时"},
		{110, gnWorldServerID, "WGLOBAL110超时"},
		{111, gnWorldServerID, "WGLOBAL111超时"},
		{100, gnWorldServerID, "WLOGIC100超时"},
		{101, gnWorldServerID, "WLOGIC101超时"},
		{102, gnWorldServerID, "WLOGIC102超时"},
	}
end

function CWatcher:Init()
	--测试服屏蔽上报
	if gbOpenGM then
		return
	end
	--屏蔽
	-- self:Sign()
	-- self.m_nTimer = GetGModule("TimerMgr"):Interval(180, function() self:OnTimer() end)
end

function CWatcher:IsSignOuted()
	return self.m_bSignOutOK
end

--注册
function CWatcher:Sign(bReport)
	local sServerGroup = goServerMgr:GetServerGroup(gnServerID)
	local sServerName = goServerMgr:GetServerName(gnServerID)
	local nDisplayID = goServerMgr:GetDisplayID(gnServerID)
	local sSign = string.format(self.m_sSignURL, sServerGroup, sServerName.."-创角登陆")
	LuaTrace("sign:", sSign)

	http.Request("GET", sSign, nil, function(sRet)
		LuaTrace("sign ret:", sRet)
		local tRet = sRet=="" and {} or cjson_raw.decode(sRet)
		if tRet["code"] == 1 then
			self.m_sToken = tRet["data"]["token"]
			if bReport then
				self:TestLogin()
			end
		end
	end)
end

--退出
function CWatcher:SignOut()
	GetGModule("TimerMgr"):Clear(self.m_nTimer)
	self.m_nTimer = nil

	if not self.m_sToken then
		self.m_bSignOutOK = true
		return
	end

	local sSignOut = string.format(self.m_sSignOutURL, self.m_sToken)
	LuaTrace("sign out:", sSignOut)
	
	http.Request("GET", sSignOut, nil, function(sRet)
		LuaTrace("sign out ret:", sRet)
		self.m_bSignOutOK = true
	end)
end

--报告
--@nStatus 1正常;2异常
--@sEvent 
function CWatcher:Report(nStatus, sEvent)
	assert(nStatus, "参数错误")
	if not self.m_sToken then
		self:Sign()
		return LuaTrace("report token is nil")
	end

	sEvent = sEvent or ""
	local sReport = string.format(self.m_sReportURL, self.m_sToken, nStatus, sEvent)
	LuaTrace("report:", sReport)

	http.Request("GET", sReport, nil, function(sRet)
		LuaTrace("report ret:", sRet)
		local tRet
		if sRet ~= "" then
			pcall(function() tRet = cjson_raw.decode(sRet) end)
		end
		if type(tRet) ~= "table" then
			return
		end
		if tRet["message"] == "token错误" then --token过期
			self:Sign(true)
		end
	end)
end

--检测登录创角
function CWatcher:TestLogin()
	local tServiceList = self.m_tServiceList

	local oCenterDB = goDBMgr:GetSSDB(0, "center")
	local oUserDB = goDBMgr:GetSSDB(gnServerID, "user", 1)
	local bRes, sErr = pcall(function() oCenterDB:HGet("watcher", "data") end)
	if not bRes then
		LuaTrace("CENTER SSDB失败", sErr)
		return self:Report(2, "CENTER SSDB失败")
	end
	local bRes, sErr = pcall(function() oUserDB:HGet("watcher", "data") end)
	if not bRes then
		LuaTrace("USER SSDB失败", sErr)
		return self:Report(2, "USER SSDB失败")
	end

	local function _TryCall(i)
		local tService = tServiceList[i]
		if not tService then
			return self:Report(1, "正常")
		end
		Network.oRemoteCall:CallWait("RemoteCallTestReq", function(nValue)
			if not nValue then
				return self:Report(2, tService[3])
			end
			LuaTrace("try call time:", tService[1], CUtil:GetUnixMSTime()-nValue)
			_TryCall(i+1)
		end, tService[2], tService[1], 0, CUtil:GetUnixMSTime())
	end
	_TryCall(1)
end

--计时器
function CWatcher:OnTimer()
	self:TestLogin()
end
