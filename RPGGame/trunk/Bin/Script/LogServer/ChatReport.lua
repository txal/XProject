--运维聊天汇报
CChatReport = CChatReport or class()

function CChatReport:Ctor()
	self.m_sToken = nil
	self.m_nGameID = 100442
	self.m_sSignURL = "http://chat-api.hoodinn.com/signChat"
	self.m_sReportURL = "http://chat-api.hoodinn.com/chats"
	self.m_tTalkList = {}
	self.m_nTimer = nil
end

function CChatReport:Init()
	--屏蔽
	-- self:Sign()
	-- self.m_nTimer = goTimerMgr:Interval(60, function() self:Report() end)
end

function CChatReport:OnRelease()
	goTimerMgr:Clear(self.m_nTimer)
	self.m_nTimer = nil
end

function CChatReport:AddTalk(tTalk)
	--屏蔽	
	-- table.insert(self.m_tTalkList, tTalk)
	-- if #self.m_tTalkList >= 64 then
	-- 	self:Report()
	-- end
end

function CChatReport:Sign()
	LuaTrace("chat sign:", self.m_sSignURL)
	http.Request("POST", self.m_sSignURL, string.format("gameId=%d&name=%s", self.m_nGameID, "新梦诛"), function(sRet)
		local tRet = sRet=="" and {} or cjson_raw.decode(sRet)
		LuaTrace("sign ret:", tRet)
		if tRet["status"] == 1 then
			self.m_sToken = tRet["token"]
		end
	end)
end

function CChatReport:Report()
	if not self.m_sToken then
		self:Sign()
		return LuaTrace("chat report token is nil")
	end
	local sServerName = goServerMgr:GetServerName(gnServerID)
	local nDisplayID = goServerMgr:GetDisplayID(gnServerID)
	local tTalkList = {}
	for _, tTalk in ipairs(self.m_tTalkList) do
		local tData = {
			gameId = self.m_nGameID,
			areaId = "wx",
			serverName = sServerName..nDisplayID.."服",
			serverId = gnServerID,
			userId = tostring(tTalk.nRoleID),
			nickName = tTalk.sRoleName,
			vip = tTalk.nVIP,
			message = tTalk.sCont,
		}
		table.insert(tTalkList, tData)
	end
	if #tTalkList <= 0 then
		return
	end
	self.m_tTalkList = {}

	LuaTrace("chat report:", self.m_sReportURL)
	local sData = string.format("gameId=%d&token=%s&messages=%s", self.m_nGameID, self.m_sToken, cjson_raw.encode(tTalkList))
	http.Request("POST", self.m_sReportURL, sData, function(sRet)
		local tRet = sRet=="" and {} or cjson_raw.decode(sRet)
		LuaTrace("chat report ret:", tRet)
		if tRet["message"] == "token错误" then --token超时
			self:Sign()
		end
	end)
end


goChatReport = goChatReport or CChatReport:new()