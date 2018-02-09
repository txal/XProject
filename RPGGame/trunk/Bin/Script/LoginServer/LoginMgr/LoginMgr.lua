--玩家登陆管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLoginMgr:Ctor()
	self.m_tAccountIDMap = {}		--账号ID影射: {[accountid]=account, ...}
	self.m_tAccountNameMap = {}		--账号名字影射: {[accountkey]=account, ...}
	self.m_tAccountSessionMap = {}	--账号SESSION影射: {[combindid]=account, ...}
end

function CLoginMgr:MakeAccountKey(nSource, sAccount)
	nSource = nSource or 0
	if nSource == 0 then
		return sAccount
	end
	return (nSource.."_"..sAccount)
end

--角色列表请求
function CLoginMgr:RoleListReq(nServer, nSession, nSource, sAccount)
	local sAccountKey = self:MakeAccountKey(nSource, sAccount)
	local oAccount = self.m_tAccountNameMap[sAccountKey]
	if oAccount then
		oAccount:RoleListReq()
	else
		local oDB = goDBMgr:GetSSDB(nServer, "global")
		local sData = oDB:HGet(gtDBDef.sAccountNameDB, sAccountKey)
		if sData == "" then
			local nAccountID = CLAccount:GenPlayerID()
			oDB:HSet(gtDBDef.sAccountNameDB, sAccountKey, cjson.encode({nAccountID=nAccountID})
		else
		end
	end
end

--登录请求
function CLoginMgr:LoginReq(nServer, nSession, nSource, sAccount)
	print("CLoginMgr:Login***", nServer, nSession, nSource, sAccount)
	assert(nServer and nSource and sAccount, "参数错误")
	local sAccountKey = self:MakeAccountKey(nSource, sAccount)
	local oAccount = self.m_tAccountNameMap[sAccountKey]

	if oAccount then
		local nOldServer, nOldSession = oAccount:GetSession()
		if nServer == nOldServer and nSession == nOldSession then
			CPlayer:Tips("重复登录了", nServer, nSession)
			return LuaTrace("重复登录", nSource, sAccount)
		end
		return self:OtherPlaceLogin(nOldServer, nOldSession, nServer, nSession, nSource, sAccount)
	end

	local nSessionKey = nServer << 32 | nSession
	local oAccount = self.m_tAccountSessionMap[nSessionKey]
	if oAccount then
		--出现这种状况一般是:点了登陆没反应，再换账号再点登陆
		return LuaTrace("会话ID冲突(注销没关连接?) new:", nServer, nSession, nSource, sAccount
			, "--old:", oAccount:GetServer(), oAccount:GetSession(), oAccount:GetSource(), oAccount:GetAccount())
	end

	local nAccountID = self:GenPlayerID()
	local sAccountData = goDBMgr:GetSSDB(nServer, "user", nAccountID):HGet(gtDBDef.sAccountDB, sAccountKey)
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
function CLoginMgr:OnLoginSucc(oPlayer)
	local nSession = oPlayer:GetSession()
	LuaTrace("CLoginMgr:OnLoginSucc***", oPlayer:GetAccount(), oPlayer:GetCharID(), oPlayer:GetName())

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

--创建角色
function CLoginMgr:CreateRole(nSession, sAccount, sPassword, sCharName, nSource)
	LuaTrace("CLoginMgr:CreateRole***", sAccount, sPassword, sCharName, nSource)
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
