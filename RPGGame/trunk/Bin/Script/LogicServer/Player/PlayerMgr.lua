--玩家管理模块
gnBaseCharID = 100000	--玩家ID起始
local nMaxCharID = 999999-gnBaseCharID --玩家ID上限

function CPlayerMgr:Ctor()
	self.m_tSessionMap = {}
	self.m_tAccountMap= {}
	self.m_tCharIDMap = {}

	--账号数据
	self.m_tAccountDataMap = {}
end

--是否被禁言
function CPlayerMgr:IsJinYan(oPlayer)
	local nSource, sAccount = oPlayer:GetSource(), oPlayer:GetAccount()
	local sKey = self:MakeAccountKey(nSource, sAccount)
	local tAccount = self.m_tAccountDataMap[sKey]
	if tAccount then
		return (tAccount.nState == gtUserState.eJinYan)
	end
end

function CPlayerMgr:GetPlayerMap()
	return self.m_tCharIDMap
end

function CPlayerMgr:GetSessionMap()
	return self.m_tSessionMap
end

function CPlayerMgr:GetPlayerBySession(nSession)
	return self.m_tSessionMap[nSession]
end

function CPlayerMgr:MakeAccountKey(nSource, sAccount)
	nSource = nSource or 0
	if nSource == 0 then
		return sAccount
	end
	return (nSource.."_"..sAccount)
end

function CPlayerMgr:GetPlayerByAccount(nSource, sAccount)
	local sKey = self:MakeAccountKey(nSource, sAccount)
	return self.m_tAccountMap[sKey]
end

function CPlayerMgr:GetPlayerByCharID(nCharID)
	return self.m_tCharIDMap[nCharID]
end

--登录
function CPlayerMgr:Login(nSession, sAccount, sPassword, nSource)
	print("CPlayerMgr:Login***", sAccount, sPassword, nSource)
	assert(sAccount and sPassword and nSource)
	local sKey = self:MakeAccountKey(nSource, sAccount)
	if self.m_tAccountMap[sKey] then
		local nOldSession = self.m_tAccountMap[sKey]:GetSession()
		if nOldSession == nSession then
			CPlayer:Tips("重复登录了", nSession)
			return LuaTrace("重复登录", sAccount)
		end
		return self:OtherPlaceLogin(nOldSession, nSession, sAccount, sPassword, nSource)
	end
	if self.m_tSessionMap[nSession] then
		--出现这种状况一般是:点了登陆没反应，再换账号再点登陆
		local oPlayer = self.m_tSessionMap[nSession]
		return LuaTrace("会话ID冲突(注销没关连接?)", nSession, sAccount, "--", oPlayer:GetSession(), oPlayer:GetAccount())
	end
	local sAccountData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sAccountDB, sKey)
	if sAccountData == "" then
		return CmdNet.PBSrv2Clt(nSession, "LoginRet", {nCode=-1}) --创建角色
	end
	local tAccountData = cjson.decode(sAccountData)
	if tAccountData.nState == gtUserState.eFengHao then
		return CPlayer:Tips("你已经被禁止登陆，请联系客服", nSession)
	end
	local nCharID = tAccountData.nCharID
	local sCharName = tAccountData.sCharName
	local sPassword = tAccountData.sPassword
	local oPlayer = CPlayer:new(nSession, sAccount, nCharID, sCharName, nSource)

	self.m_tSessionMap[nSession] = oPlayer
	self.m_tCharIDMap[nCharID] = oPlayer
	self.m_tAccountMap[sKey] = oPlayer
	self.m_tAccountDataMap[sKey] = tAccountData

	self:OnLoginSucc(oPlayer)
	return oPlayer
end

--登录成功
function CPlayerMgr:OnLoginSucc(oPlayer)
	local nSession = oPlayer:GetSession()
	LuaTrace("CPlayerMgr:OnLoginSucc***", oPlayer:GetAccount(), oPlayer:GetCharID(), oPlayer:GetName())

	--通知GATEWAY
	CmdNet.Srv2Srv("SyncPlayerLogicService", nSession>>nSERVICE_SHIFT, nSession, GlobalExport:GetServiceID()) 

    --通知GLOBAL
    local nSource = oPlayer:GetSource()
    local nLogicService = GlobalExport:GetServiceID()
    local tPlayer = {nSession=nSession, nCharID=oPlayer:GetCharID(), sName=oPlayer:GetName(), sAccount=oPlayer:GetAccount()
	    , nSource=nSource, nLogicService=nLogicService}
	Srv2Srv.OnPlayerOnline(gtNetConf:GlobalService(), nSession, tPlayer)

	--通知客户端
	local nOnlineTime = oPlayer:GetOnlineTime()
	local bNewAccount = nOnlineTime == 0 and true or false
	local bFirstOnline = not os.IsSameDay(os.time(), nOnlineTime, 0)
	CmdNet.PBSrv2Clt(nSession, "LoginRet", {nCode=0, bFirstOnline=bFirstOnline, bNewAccount=bNewAccount}) 
    oPlayer:Online()

    --LOG
	goLogger:EventLog(gtEvent.eLogin, oPlayer, oPlayer:GetOnlineTime()-oPlayer:GetOfflineTime())
end

--生成唯一角色ID
function CPlayerMgr:GenCharID()
	local nIncr = goDBMgr:GetSSDB("Center"):HIncr(gtDBDef.sCharIDDB, "IDIncr")
	local nCharID = gnBaseCharID + nIncr % nMaxCharID
	return nCharID
end

--创建角色
function CPlayerMgr:CreateRole(nSession, sAccount, sPassword, sCharName, nSource)
	LuaTrace("CPlayerMgr:CreateRole***", sAccount, sPassword, sCharName, nSource)
	assert(sAccount and sPassword and sCharName and nSource)
	if GF.HasBadWord(sCharName) then
		LuaTrace("角色名含有非法字符")
		return CPlayer:Tips("角色名含有非法字符", nSession)
	end
	local sExist = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sUniqueNameDB, sCharName)
	if sExist ~= "" then --角色名重复
		return CmdNet.PBSrv2Clt(nSession, "CreateRoleRet", {nCode=-1})
	end
	local sAccountData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sAccountDB, self:MakeAccountKey(nSource, sAccount))
	if sAccountData ~= "" then --角色已经存在
		return CmdNet.PBSrv2Clt(nSession, "CreateRoleRet", {nCode=-2})
	end
	local nCharID = self:GenCharID()
	local tAccountData = {nCharID=nCharID, sCharName=sCharName, nSource=nSource, sPassword=sPassword}
	sAccountData = cjson.encode(tAccountData)
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sAccountDB, self:MakeAccountKey(nSource, sAccount), sAccountData)
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sUniqueNameDB, sCharName, nCharID)
	CmdNet.PBSrv2Clt(nSession, "CreateRoleRet", {nCode=0})
	goLogger:CreateAccountLog(sAccount, nCharID, sCharName, nSource)
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

