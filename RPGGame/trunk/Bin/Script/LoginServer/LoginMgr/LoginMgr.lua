--账号(玩家)登陆管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLoginMgr:Ctor()
	self.m_tAccountIDMap = {}		--账号ID影射: {[accountid]=account, ...}
	self.m_tAccountNameMap = {}		--账号名字影射: {[accountkey]=account, ...}
	self.m_tAccountSSMap = {} 		--SS(server<<32|session)映射: {[mixid]=account, ...}
end

function CLoginMgr:MakeAccountKey(nSource, sAccount)
	nSource = nSource or 0
	if nSource == 0 then
		return sAccount
	end
	return (nSource.."_"..sAccount)
end

function CLoginMgr:MakeSSKey(nServer, nSession)
	local nSSKey = nServer << 32 | nSession
	return nSSKey
end

function CLoginMgr:GetServiceBySession(nSession)
	local nService = nSession >> nSERVICE_SHIFT
	return nService
end

function CLoginMgr:GetAccountByID(nAccountID)
	return self.m_tAccountIDMap[nAccountID]
end

function CLoginMgr:GetAccountByName(sAccountKey)
	return self.m_tAccountNameMap[sAccountKey]
end

function CLoginMgr:GetAccountBySS(nServer, nSession)
	local nSSKey = self:MakeSSKey(nServer, nSession)
	return self.m_tAccountSSMap[nSSKey]
end

--账号下线(清理数据)
function CLoginMgr:AccountOffline(nAccountID)
	print("CLoginMgr:AccountOffline***", nAccountID)
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		return
	end

	local nServer = oAccount:GetServer()
	local nSession = oAccount:GetSession()
	local nSSKey = self:MakeSSKey(nServer, nSession)

	local nSource = oAccount:GetSource()
	local sAccount = oAccount:GetName()
	local sAccountKey = self:MakeAccountKey(nSource, sAccount)

	local nOnlineRoleID = oAccount:GetOnlineRoleID()
	if nOnlineRoleID <= 0 then
		self.m_tAccountIDMap[nAccountID] = nil
		self.m_tAccountNameMap[sAccountKey] = nil
		self.m_tAccountSSMap[nSSKey] = nil
		return
	end

	goRemoteCall:CallWait("RoleOfflineReq", function(nAccountID)
		if nAccountID <= 0 then
			return LuaTrace("账号离线失败", nAccountID)
		end
		oAccount:RoleOffline()
		oAccount:OnRelease()
		self.m_tAccountIDMap[nAccountID] = nil
		self.m_tAccountNameMap[sAccountKey] = nil
		self.m_tAccountSSMap[nSSKey] = nil

	end, nServer, oAccount:GetLogic(), nSession, nOnlineRoleID)
end

--角色断开连接
function CLoginMgr:OnClientClose(nServer, nSession)
	print("CLoginMgr:OnClientClose***", nServer, nSession)
	local oAccount = self:GetAccountBySS(nServer, nSession)
	if not oAccount then
		return
	end
	assert(nSession == oAccount:GetSession(), "会话ID错误")
	local nSSKey = self:MakeSSKey(nServer, nSession)
	self.m_tAccountSSMap[nSSKey] = nil
	local nOnlineRoleID = oAccount:GetOnlineRoleID()
	if nOnlineRoleID > 0 then
		goRemoteCall:Call("RoleDisconnectReq", oAccount:GetServer(), oAccount:GetLogic(), oAccount:GetSession(), nOnlineRoleID)
	end
	oAccount:OnDisconnect()
end

--发送异地登陆消息
function CLoginMgr:OtherPlaceLogin(nServer, nSession, sAccount)
	print("CLoginMgr:OtherPlaceLogin***", sAccount)
	if nSession <= 0 then
		return
	end

	CmdNet.PBSrv2Clt("OtherPlaceLoginRet", nServer, nSession, {})
	goTimerMgr:Interval(2, function(nTimerID) 
		goTimerMgr:Clear(nTimerID)
		CmdNet.Srv2Srv("KickClientReq", nServer, nSession>>nSERVICE_SHIFT, nSession)
	end)
end

--角色列表请求
function CLoginMgr:RoleListReq(nServer, nSession, nSource, sAccount)
	print("CLoginMgr:RoleListReq***", nServer, nSession, nSource, sAccount)
	local nNewSSKey = self:MakeSSKey(nServer, nSession)
	local sAccountKey = self:MakeAccountKey(nSource, sAccount)
	local oAccount = self:GetAccountByName(sAccountKey)

	if oAccount then
		local nOldServer = oAccount:GetServer()
		assert(nOldServer == nServer, "服务器ID错误")
		local nOldSession = oAccount:GetSession()
		local nOldSSKey = self:MakeSSKey(nOldServer, nOldSession)

		local nOnlineRoleID = oAccount:GetOnlineRoleID()
		if nOnlineRoleID > 0 and nOldSession > 0 then
		--已有角色登陆
			goRemoteCall:CallWait("RoleDisconnectReq", function(nAccountID)
				oAccount:OnDisconnect()
				oAccount:BindSession(nSession)
				self.m_tAccountSSMap[nOldSSKey] = nil
				self.m_tAccountSSMap[nNewSSKey] = oAccount
				oAccount:RoleListReq()

				if nSession ~= nOldSession then
					self:OtherPlaceLogin(nOldServer, nOldSession, sAccount)
				end

			end , nOldServer, oAccount:GetLogic(), nOldSession, nOnlineRoleID)

		else
		--没有角色登陆
			oAccount:BindSession(nSession)
			self.m_tAccountSSMap[nOldSSKey] = nil
			self.m_tAccountSSMap[nNewSSKey] = oAccount
			oAccount:RoleListReq()

			if nSession ~= nOldSession then
				self:OtherPlaceLogin(nOldServer, nOldSession, sAccount)
			end

		end

	--账号不在线/或新建账号
	else
		local nAccountID = 0
		local oDB = goDBMgr:GetSSDB(nServer, "global")
		local sData = oDB:HGet(gtDBDef.sAccountNameDB, sAccountKey)
		if sData == "" then
		--账号不存在,创建之
			nAccountID = CLAccount:GenPlayerID()
			oDB:HSet(gtDBDef.sAccountNameDB, sAccountKey, cjson.encode({nAccountID=nAccountID}))
			oDB:HSet(gtDBDef.sAccountNameDB, nAccountID, cjson.encode({nSource=nSource, sAccount=sAccount}))
			goLogger:CreateAccountLog(nSource, nAccountID, sAccount, 0)

		else
			nAccountID = cjson.decode(sData).nAccountID
		end
		--加载账号数据
		oAccount = CLAccount:new(nServer, nSession, nAccountID, nSource, sAccount)
		self.m_tAccountIDMap[nAccountID] = oAccount
		self.m_tAccountNameMap[sAccountKey] = oAccount
		self.m_tAccountSSMap[nNewSSKey] = oAccount

		oAccount:RoleListReq()

	end

end

--创建角色请求
function CLoginMgr:RoleCreateReq(nServer, nSession, nAccountID, nConfID, sRole)
	local oAccount = self:GetAccountByID(nAccountID)
	assert(oAccount, "账号未加载")

	local nOldServer = oAccount:GetServer()
	local nOldSession = oAccount:GetSession()
	assert(nOldServer == nServer, "服务器错误")
	assert(nOldSession == nSession, "会话ID错误") --1定相等

	local nOnlineRoleID = oAccount:GetOnlineRoleID()
	if nOnlineRoleID > 0 then
		goRemoteCall:CallWait("RoleOfflineReq", function(nAccountID)
			if nAccountID <= 0 then
				return LuaTrace("账号离线失败", nAccountID)
			end

			oAccount:RoleOffline() --离线操作
			oAccount:BindSession(nSession)

			if oAccount:CreateRole(nConfID, sRole) then
				self.m_tAccountSSMap[nNewSSKey] = oAccount
				LuaTrace("角色登陆成功", oAccount:GetName(), nOnlineRoleID)
			end

		end , nOldServer, oAccount:GetLogic(), nOldSession, nOnlineRoleID)

	else
		--创建角色并登录
		oAccount:BindSession(nSession)
		if oAccount:CreateRole(nConfID, sRole) then
			LuaTrace("创建角色并登陆成功")
		end

	end

end

--角色登陆请求
function CLoginMgr:RoleLoginReq(nServer, nSession, nAccountID, nRoleID)
	print("CLoginMgr:RoleLoginReq***", nServer, nSession)
	local nNewSSKey = self:MakeSSKey(nServer, nSession)

	local function _RoleLogin(oAccount, nSession, nOldServer, nOldSession)
		oAccount:BindSession(nSession)
		if oAccount:RoleLogin(nRoleID) then
			self.m_tAccountSSMap[nNewSSKey] = oAccount
			LuaTrace("角色登陆成功", oAccount:GetName(), nRoleID)
		end

		if nOldServer and nOldSession then
			if nOldSession ~= nSession then
				local nOldSSKey = self:MakeSSKey(nOldServer, nOldSession)
				self.m_tAccountSSMap[nOldSSKey] = nil
				self:OtherPlaceLogin(nOldServer, nOldSession, oAccount:GetName())
			end
		end
	end

	--账号已加载
	local oAccount = self:GetAccountByID(nAccountID)
	if oAccount then
		local nOldServer = oAccount:GetServer()
		assert(nOldServer == nServer, "服务器ID错误")
		local nOldSession = oAccount:GetSession()

		--当前有角色
		local nOnlineRoleID = oAccount:GetOnlineRoleID()
		if nOnlineRoleID > 0 then
			if nOnlineRoleID == nRoleID then
			--同一角色并在线则断线处理,否则直接登录
				if nOldSession > 0 and nOldSession ~= nSession then
					goRemoteCall:CallWait("RoleDisconnectReq", function(nAccountID)
						_RoleLogin(oAccount, nSession, nOldServer, nOldSession)

					end , nOldServer, oAccount:GetLogic(), nOldSession, nOnlineRoleID)

				else
					_RoleLogin(oAccount, nSession, nOldServer, nOldSession)

				end

			else
			--不同角色就先清理当前角色数据再登陆新角色
				goRemoteCall:CallWait("RoleOfflineReq", function(nAccountID)
					if nAccountID <= 0 then
						return LuaTrace("账号离线失败", nAccountID)
					end
					oAccount:RoleOffline() --离线操作
					_RoleLogin(oAccount, nSession, nOldServer, nOldSession)

				end , nOldServer, oAccount:GetLogic(), nOldSession, nOnlineRoleID)

			end

		--当前没有角色直接登录
		else
			_RoleLogin(oAccount, nSession, nOldServer, nOldSession)

		end

	else
	--账号未加载
		local sData = goDBMgr:GetSSDB(nServer, "global"):HGet(gtDBDef.sAccountNameDB, nAccountID)
		if sData == "" then
			return CLAccount:Tips("账号不存在", nServer, nSession)
		end

		--加载账号数据
		local oAccount = CLAccount:new(nServer, nSession, nAccountID, 0, "")
		if oAccount:RoleLogin(nRoleID) then
			self.m_tAccountIDMap[nAccountID] = oAccount
			local sAccountKey = self:MakeAccountKey(oAccount:GetSource(), oAccount:GetName())
			self.m_tAccountNameMap[sAccountKey] = oAccount
			self.m_tAccountSSMap[nNewSSKey] = oAccount
			LuaTrace("角色登陆成功", oAccount:GetName(), nRoleID)
		end

	end
end

--有服务断开,如果是网关则相关帐号做离线处理
function CLoginMgr:OnServiceClose(nServer, nService)
	local bGateService = false
	for _, tConf in ipairs(gtServerConf.tGateService) do
		if tConf.nServer == nServer and nService == tConf.nID then
			bGateService = true
			break
		end
	end
	if not bGateService then
		return
	end

	--离线处理
	for nID, oAccount in pairs(self.m_tAccountIDMap) do
		local nSession = oAccount:GetSession()
		local nTmpService = self:GetServiceBySession(nSession)
		if oAccount:GetServer() == nServer and nTmpService == nService then
			self:OnClientClose(nServer, nSession)
		end
	end
end

--更新角色摘要
function CLoginMgr:RoleUpdateSummaryReq(nAccountID, nRoleID, tSummary)
	print("CLoginMgr:RoleUpdateSummaryReq***", nAccountID, nRoleID)
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		return LuaTrace("账号未登陆", nAccountID)
	end
	oAccount:UpdateRoleSummary(nRoleID, tSummary)
end

goLoginMgr = goLoginMgr or CLoginMgr:new()