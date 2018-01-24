local sPlayerDB = "PlayerDB"
local sAccountDB = "AccountDB"
local sUniqueNameDB = "UniqueNameDB"

function CPlayerMgr:Ctor()
	self.m_tSessionMap = {}
	self.m_tAccountMap= {}
	self.m_tCharIDMap = {}
	self.m_tCharNameMap = {}
end

function CPlayerMgr:GetPlayerBySession(nSessionID)
	return self.m_tSessionMap[nSessionID]
end

function CPlayerMgr:GetPlayerByAccount(sAccount)
	return self.m_tAccountMap[sAccount]
end

function CPlayerMgr:GetPlayerByCharID(sCharID)
	return self.m_tCharIDMap[sCharID]
end

function CPlayerMgr:GetPlayerByName(sCharName)
	return self.m_tCharNameMap[sCharName]
end

--登录
function CPlayerMgr:Login(nSessionID, sAccount, sPassword, sPlatform, sChannel)
	assert(sAccount and sPassword and sPlatform and sChannel)
	if self.m_tAccountMap[sAccount] then
		local nOldSession = self.m_tAccountMap[sAccount]:GetSession()
		if nOldSession == nSessionID then
			return
		end
		self:OtherPlaceLogin(nOldSession, nSessionID, sAccount, sPassword, sPlatform, sChannel)
		return
	end
	local sAccountInfo = goSSDB:HGet(sAccountDB, sAccount)
	if sAccountInfo == "" then
		--创建角色
		CmdNet.PBSrv2Clt(nSessionID, "LoginRet", {nCode=-1})
		return
	end
	local tAccountInfo = GlobalExport.Str2Tb(sAccountInfo)
	local sCharID = tAccountInfo.sCharID
	local nRoleID = tAccountInfo.nRoleID
	local sCharName = tAccountInfo.sCharName
	local sPassword = tAccountInfo.sPassword
	local oPlayer = CPlayer:new(nSessionID, sAccount, sCharID, sCharName, nRoleID, sPlatform, sChannel)

	self.m_tSessionMap[nSessionID] = oPlayer
	self.m_tAccountMap[sAccount] = oPlayer
	self.m_tCharIDMap[sCharID] = oPlayer
	self.m_tCharNameMap[sCharName] = oPlayer
	self:OnLoginSucc(oPlayer)
	return oPlayer
end

--登录成功
function CPlayerMgr:OnLoginSucc(oPlayer)
	LuaTrace("CPlayerMgr:OnLoginSucc***", oPlayer:GetCharID(), oPlayer:GetName())

	--通知gateway
	local nSession = oPlayer:GetSession()
	CmdNet.Srv2Srv("SyncPlayerLogicService", nSession>>nSERVICE_SHIFT, nSession, GlobalExport:GetServiceID()) 

    --通知global
	Srv2Srv.OnPlayerOnline(gtNetConf:GetGlobalService(), nSession, oPlayer:GetCharID(), oPlayer:GetName()
		, GlobalExport:GetServiceID(), oPlayer:GetPlatform(), oPlayer:GetChannel()) 

	--通知客户端
	CmdNet.PBSrv2Clt(nSession, "LoginRet", {nCode=0}) 
    oPlayer:Online()
    --log
	goLogger:EventLog(gtEvent.ePlayerLogin, oPlayer, sPlatform, sChannel)
end

function CPlayerMgr:CreateRole(nSessionID, sAccount, sPassword, sCharName, nRoleID)
	assert(sAccount and sPassword and sCharName and nRoleID)
	local sExist = goSSDB:HGet(sUniqueNameDB, sCharName)
	if sExist ~= "" then --角色名重复
		CmdNet.PBSrv2Clt(nSessionID, "CreateRoleRet", {nCode=-1})
		return
	end
	local sAccountInfo = goSSDB:HGet(sAccountDB, sAccount)
	if sAccountInfo ~= "" then --角色已经存在
		CmdNet.PBSrv2Clt(nSessionID, "CreateRoleRet", {nCode=-2})
		return
	end
	local sCharID = GlobalExport.MakeGameObjID()
	local tAccountInfo = {sCharID=sCharID, sCharName=sCharName, nRoleID=nRoleID, sPassword=sPassword}
	sAccountInfo = GlobalExport.Tb2Str(tAccountInfo)
	goSSDB:HSet(sAccountDB, sAccount, sAccountInfo)
	goSSDB:HSet(sUniqueNameDB, sCharName, sCharID)
	CmdNet.PBSrv2Clt(nSessionID, "CreateRoleRet", {nCode=0})
	goLogger:CreateAccountLog(sAccount, sCharID, sCharName, nRoleID)
end

function CPlayerMgr:OnClientClose(nSessionID)
	local oPlayer = self:GetPlayerBySession(nSessionID)
	if not oPlayer then
		return
	end
    --通知global
	Srv2Srv.OnPlayerOffline(gtNetConf:GetGlobalService(), nSessionID)

	local sAccount = oPlayer:GetAccount()
	local sCharID = oPlayer:GetCharID()
	local sCharName = oPlayer:GetName()

	oPlayer:Offline()
	oPlayer:OnRelease()

	self.m_tSessionMap[nSessionID] = nil
	self.m_tAccountMap[sAccount] = nil
	self.m_tCharIDMap[sCharID] = nil
	self.m_tCharNameMap[sCharName] = nil
	
	--log
	goLogger:EventLog(gtEvent.ePlayerLogout, oPlayer)
end

--异地登录
function CPlayerMgr:OtherPlaceLogin(nOldSession, nNewSession, sAccount, sPassword, sPlatform, sChannel)
	LuaTrace(sAccount, "异地登录")
	local oPlayer = self:GetPlayerBySession(nOldSession)
	assert(oPlayer, "异地登录玩家找不到")
	CmdNet.PBSrv2Clt(nOldSession, "OtherPlaceLoginRet", {})
	self:OnClientClose(nOldSession)
	self:Login(nNewSession, sAccount, sPassword, sPlatform, sChannel)
	CmdNet.Srv2Srv("KickClient", nOldSession>>nSERVICE_SHIFT, nOldSession)
end

--通过玩家名字取玩家ID
function CPlayerMgr:GetCharIDFromDB(sCharName)
	local sCharID = goSSDB:HGet(sUniqueNameDB, sCharName)
	if sCharID ~= "" then
		return sCharID
	end
end




--------------cpp call--------------
function OnClientClose(nSessionID)
	LuaTrace("OnClientDisconnect***", nSessionID)
	goLuaPlayerMgr:OnClientClose(nSessionID)
end

function OnServiceClose(nService)
	LuaTrace("OnServiceClose***", nService)
	if not gtNetConf.tGateService[nService] then
		return
	end
	for nSessionID, oPlayer in pairs(goLuaPlayerMgr.m_tSessionMap) do
		if (nSessionID >> nSERVICE_SHIFT) == nService then
			goLuaPlayerMgr:OnClientClose(nSessionID)
		end
	end
	if not next(goLuaPlayerMgr.m_tCharIDMap) then
		OnExitServer()
	end
end


goCppPlayerMgr = GlobalExport.GetPlayerMgr()
goLuaPlayerMgr = goLuaPlayerMgr or CPlayerMgr:new()