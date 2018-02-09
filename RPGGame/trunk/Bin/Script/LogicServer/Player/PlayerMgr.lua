--玩家管理模块

function CPlayerMgr:Ctor()
	self.m_tAccountIDMap = {}		--账号ID影射: {[accountid]=account, ...}
	self.m_tAccountNameMap = {}		--账号名字影射: {[accountkey]=account, ...}
	self.m_tAccountSessionMap = {}	--账号SESSION影射: {[combindid]=account, ...}
end

function CPlayerMgr:GetAccountIDMap()
	return self.m_tAccountIDMap
end

function CPlayerMgr:GetAccountSessionMap()
	return self.m_tAccountSessionMap
end

--通过账号ID取在线账号对象
function CPlayerMgr:GetAccountByID(nAccountID)
	return self.m_tAccountIDMap[nAccountID]
end

--通过SERVER,SESSION取在线账号对象
function CPlayerMgr:GetAccountBySession(nServer, nSession)
	local nKey = nSession<<32|nSession
	return self.m_tAccountSessionMap[nKey]
end

--通过账号ID取在线角色对象
function CPlayerMgr:GetRoleByAccountID(nAccountID)
	local oAccount = self:GetAccountByID(nAccountID)
	if oAccount then
		return oAccount:GetOnlineRole()
	end
end

--通过SERVER,SESSION取在线角色对象
function CPlayerMgr:GetRoleBySessionID(nServer, nSession)
	local oAccount = self:GetAccountBySession(nServer, nSession)
	if oAccount then
		return oAccount:GetOnlineRole()
	end
end

--客户端断开
function CPlayerMgr:OnClientClose(nSession, oPlayer)
	oPlayer = oPlayer or self:GetPlayerBySession(nSession)
	if not oPlayer then return end
	LuaTrace("CPlayerMgr:OnClientClose***", oPlayer:GetName())

	oPlayer:Offline()
	oPlayer:OnRelease()

    --通知GLOBAL
	Srv2Srv.OnPlayerOffline(gtNetConf:GlobalService(), nSession)

	local nCharID = oPlayer:GetCharID()
	local nSource = oPlayer:GetSource()
	local sAccount = oPlayer:GetAccount()
	local sKey = self:MakeAccountKey(nSource, sAccount)
	print("OnClientClose***", sKey)
	self.m_tSessionMap[nSession] = nil
	self.m_tCharIDMap[nCharID] = nil
	self.m_tAccountMap[sKey] = nil
	self.m_tAccountDataMap[sKey] = nil
	
	--LOG
	goLogger:EventLog(gtEvent.eLogout, oPlayer, oPlayer:GetOfflineTime()-oPlayer:GetOnlineTime())
end

--打印在线玩家情况
function CPlayerMgr:PrintOnline()
	LuaTrace("------SessionMap------")
	for nSession, v in pairs(self.m_tSessionMap) do
		LuaTrace(nSession, v:GetAccount(), v:GetName())
	end
	LuaTrace("------AccountMap------")
	for sAccount, v in pairs(self.m_tAccountMap) do
		LuaTrace(v:GetSession(), sAccount, v:GetName())
	end
	LuaTrace("------CharIDMap------")
	for nCharID, v in pairs(self.m_tCharIDMap) do
		LuaTrace(v:GetSession(), v:GetAccount(), v:GetName())
	end
end

--异地登录
function CPlayerMgr:OtherPlaceLogin(nOldSession, nNewSession, sAccount, sPassword, nSource)
	LuaTrace(string.format("异地登录 账号: %s 旧SESSION: %d 新SESSION: %d", sAccount, nOldSession, nNewSession))
	local oPlayer = assert(self:GetPlayerByAccount(nSource, sAccount), "异地登录玩家找不到")
	assert(oPlayer:GetSession() == 0 or oPlayer:GetSession() == nOldSession)
	if nOldSession > 0 then
		CmdNet.PBSrv2Clt(nOldSession, "OtherPlaceLoginRet", {})
		goTimerMgr:Interval(3, function(nTimerID) self:CloseSession(nOldSession, nTimerID) end)
	end
	self:OnClientClose(nOldSession, oPlayer)
	self:Login(nNewSession, sAccount, sPassword, nSource)
end

--关闭会话
function CPlayerMgr:CloseSession(nSession, nTimerID)
	print("CPlayerMgr:CloseSession***", nSession, nTimerID)
	goTimerMgr:Clear(nTimerID)
	CmdNet.Srv2Srv("KickClient", nSession>>nSERVICE_SHIFT, nSession)
end

--登出(注销)
function CPlayerMgr:Logout(nSession)
	LuaTrace("CPlayerMgr:Logout***", nSession)
	goPlayerMgr:OnClientClose(nSession)
	CmdNet.PBSrv2Clt(nSession, "LogoutRet", {})
end




--------------cpp call--------------
function OnClientClose(nSession)
	print("OnClientClose***", nSession)
	goPlayerMgr:OnClientClose(nSession)
end

function OnServiceClose(nService)
	LuaTrace("OnServiceClose***", nService)
	if not gtNetConf.tGateService[nService] then
		return
	end
	for nSession, oPlayer in pairs(goPlayerMgr.m_tSessionMap) do
		local nTmpService = nSession >> nSERVICE_SHIFT 
		LuaTrace("OnServiceClose close session***", nSession, nTmpService, oPlayer:GetAccount())
		if nTmpService == nService then
			xpcall(function() goPlayerMgr:OnClientClose(nSession) end, function(sErr) LuaTrace(sErr) end)
		end
	end
	if not next(goPlayerMgr.m_tCharIDMap) then
		OnExitServer()
	else
		local nCharID = next(goPlayerMgr.m_tCharIDMap)
		LuaTrace("OnServiceClose fail***", nCharID)
	end
end


goPlayerMgr = goPlayerMgr or CPlayerMgr:new()
goCppPlayerMgr = GlobalExport.GetPlayerMgr()

