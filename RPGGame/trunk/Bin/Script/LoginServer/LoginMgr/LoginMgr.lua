--账号(玩家)登陆管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLoginMgr:Ctor()
	self.m_tAccountIDMap = {}		--账号ID影射: {[accountid]=account, ...}
	self.m_tAccountNameMap = {}		--账号名字影射: {[accountkey]=account, ...}
end

function CLoginMgr:MakeAccountKey(nSource, sAccount)
	nSource = nSource or 0
	if nSource == 0 then
		return sAccount
	end
	return (nSource.."_"..sAccount)
end

function CLoginMgr:GetAccountByID(nAccountID)
	return self.m_tAccountIDMap[nAccountID]
end

function CLoginMgr:GetAccountByName(sAccountKey)
	return self.m_tAccountNameMap[sAccountKey]
end

--角色列表请求
function CLoginMgr:RoleListReq(nServer, nSession, nSource, sAccount)
	local sAccountKey = self:MakeAccountKey(nSource, sAccount)
	local oAccount = self.m_tAccountNameMap[sAccountKey]

	--账号在线需要先到逻辑服更新当前在线角色摘要信息
	if oAccount then
		goRemoteCall:CallWait("UpdateRoleSummaryReq", function(nAccountID)
			--要重新取Account对象并重新加载数据
			local oAccount = self:GetAccountByID(nAccountID)
			if oAccount then
				oAccount:LoadData()
				oAccount:RoleListReq()
			end
		end , oAccount:GetServer(), oAccount:GetLogicID(), 0, oAccount:GetID())

	--账号不在线/或新建账号
	else
		local nAccountID = 0
		local oDB = goDBMgr:GetSSDB(nServer, "global")
		local sData = oDB:HGet(gtDBDef.sAccountNameDB, sAccountKey)
		--账号不存在,创建之
		if sData == "" then
			nAccountID = CLAccount:GenPlayerID()
			oDB:HSet(gtDBDef.sAccountNameDB, sAccountKey, cjson.encode({nAccountID=nAccountID})
		else
			local tData = cjson.decode(sData)
			nAccountID = tData.nAccountID
		end
		--加载账号数据,但是不做缓存
		oAccount = CLAccount:new(nAccountID, nServer, nServer, nSource, sName)
		oAccount:LoadData()
		oAccount:RoleListReq()
	end

end

function CLoginMgr:KickAccount()
	if nOldSession > 0 then
		CmdNet.PBSrv2Clt(nOldSession, "OtherPlaceLoginRet", {})
		goTimerMgr:Interval(3, function(nTimerID) self:CloseSession(nOldSession, nTimerID) end)
	end
	self:OnClientClose(nOldSession, oPlayer)
	self:Login(nNewSession, sAccount, sPassword, nSource)

	print("CPlayerMgr:CloseSession***", nSession, nTimerID)
	goTimerMgr:Clear(nTimerID)
	CmdNet.Srv2Srv("KickClient", nSession>>nSERVICE_SHIFT, nSession)
end

--发送异地登陆消息
function CLoginMgr:OtherPlaceLogin(nServer, nSession, sAccount)
	print("CLoginMgr:OtherPlaceLogin***", sAccount)
	CmdNet.PBSrv2Clt(nServer, nSession, "OtherPlaceLoginRet", {})
end

--创建角色请求
function CLoginMgr:CreateRoleReq(nServer, nSession, nSource, sAccount, sRole, nGender, nSchool)
	local sAccountKey = self:MakeAccountKey(nSource, sAccount)
	local oAccount = self.m_tAccountNameMap[sAccountKey]

	local function _CreateRole()
		local sData = goDBMgr:GetSSDB(nServer, "global"):HGet(gtDBDef.sAccountNameDB, sAccountKey)
		if sData == "" then
			return CLAccount:Tips("账号不存在", nServer, nSession)
		end
		--加载账号数据
		local tData = cjson.decode(sData)
		local nAccountID = tData.nAccountID
		oAccount = CLAccount:new(nAccountID, nServer, nSession, nSource, sName)
		oAccount:LoadData()

		--创建角色和登录成功则缓存
		if oAccount:CreateRole(sRole, nGender, nSchool) then
			self.m_tAccountIDMap[nAccountID] = oAccount
			self.m_tAccountNameMap[sAccountKey] = oAccount
			LuaTrace("创建角色并登陆成功")
		end
	end

	--账号不在线,创建角色并登陆
	if not oAccount then
		_CreateRole()

	--账号在线则先进行异地登陆
	else
		goRemoteCall:CallWait("RoleOfflineReq", function(nAccountID)
			--要重新取Account对象并重新加载数据
			local oAccount = self:GetAccountByID(nAccountID)
			if oAccount then
				local nOldServer = oAccount:GetServer()
				local nOldSession = oAccount:GetSession()
				oAccount:LoadData() --重新加载数据,逻辑服可能有修改
				oAccount:RoleOffline() --离线操作
				self.m_tAccountIDMap[nAccountID] = nil
				self.m_tAccountNameMap[sAccountKey] = nil

				--同一客户端操作
				if nOldServer == nServer and nOldSession == nSession then
					_CreateRole()

				--不同客户端操作
				else
					self:OtherPlaceLogin(nOldServer, nOldSession, sAccount)
					_CreateRole()

				end
			end
		end , oAccount:GetServer(), oAccount:GetLogicID(), 0, oAccount:GetID())

	end
end

--角色登陆请求
function CLoginMgr:LoginRoleReq(nServer, nSession, nSource, sAccount)
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
