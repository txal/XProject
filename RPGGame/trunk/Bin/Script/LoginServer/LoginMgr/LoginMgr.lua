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

--角色下线
function CLoginMgr:RoleOffline(nAccountID)
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		return
	end

	local nServer = oAccount:GetServer()
	local nSession = oAccount:GetSession()
	local nSource = oAccount:GetSource()
	local sAccount = oAccount:GetName()

	local nSSKey = self:MakeSSKey(nServer, nSession)
	local sAccountKey = self:MakeAccountKey(nSource, sAccount)

	oAccount:LoadData() --需要重新加载数据,逻辑服可能修改了
	goRemoteCall:CallWait("RoleOfflineReq", function(nAccountID)
		local oAccount = self:GetAccountByID(nAccountID)
		if oAccount then
			oAccount:LoadData()
			oAccount:RoleOffline()

			self.m_tAccountIDMap[nAccountID] = nil
			self.m_tAccountNameMap[sAccountKey] = nil
			self.m_tAccountSSMap[nSSKey] = nil
		end
	end, nServer, oAccount:GetLogic(), nSession, nAccountID)
end

--角色断开连接
function CLoginMgr:OnClientClose(nServer, nSession)
	local oAccount = self:GetAccountBySS(nServer, nSession)
	if not oAccount and oAccount:GetSession() > 0 then
		return
	end
	local nSSKey = self:MakeSSKey(nServer, nSession)
	self.m_tAccountSSMap[nSSKey] = nil

	oAccount:LoadData() --需要重新加载数据,逻辑服可能修改了
	goRemoteCall:Call("RoleDisconnectReq", oAccount:GetServer(), oAccount:GetLogic(), oAccount:GetSession(), oAccount:GetID())
	oAccount:BindSession(0)
end

--发送异地登陆消息
function CLoginMgr:OtherPlaceLogin(nServer, nSession, sAccount)
	print("CLoginMgr:OtherPlaceLogin***", sAccount)
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

		if oAccount:GetOnlineRoleID() > 0 then
		--已有角色登陆
			goRemoteCall:CallWait("RoleDisconnectReq", function(nAccountID)
				oAccount:LoadData() --重新加载数据,逻辑服可能有修改

				oAccount:BindSession(nSession)
				self.m_tAccountSSMap[nNewSSKey] = oAccount
				oAccount:RoleListReq()

				if nSession ~= nOldSession then
					self:OtherPlaceLogin(nOldServer, nOldSession, sAccount)
				end

			end , nOldServer, oAccount:GetLogic(), nOldSession, oAccount:GetID())

		else
		--没有角色登陆
			oAccount:BindSession(nSession)
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
		else
			nAccountID = cjson.decode(sData).nAccountID
		end
		--加载账号数据
		oAccount = CLAccount:new(nServer, nSession, nAccountID, nSource, sAccount)
		oAccount:LoadData()
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
	assert(nOldSession == nSession, "SESSION错误")

	if oAccount:GetOnlineRoleID() > 0 then
		goRemoteCall:CallWait("RoleOfflineReq", function(nAccountID)
			oAccount:LoadData() --重新加载数据,逻辑服可能有修改
			oAccount:RoleOffline() --离线操作

			oAccount:BindSession(nSession)
			if oAccount:RoleLogin(nRoleID) then
				self.m_tAccountSSMap[nNewSSKey] = oAccount
				LuaTrace("角色登陆成功", oAccount:GetName(), nRoleID)
			end

		end , nOldServer, oAccount:GetLogic(), 0, oAccount:GetID())

	else
		--创建角色和登录成功则缓存
		if oAccount:CreateRole(nConfID, sRole) then
			LuaTrace("创建角色并登陆成功")
		end

	end

end

--角色登陆请求
function CLoginMgr:RoleLoginReq(nServer, nSession, nAccountID, nRoleID)
	local nNewSSKey = self:MakeSSKey(nServer, nSession)

	--在线异地登录
	local oAccount = self:GetAccountByID(nAccountID)
	if oAccount then
		local nOldServer = oAccount:GetServer()
		assert(nOldServer == nServer, "服务器ID错误")
		local nOldSession = oAccount:GetSession()

		if oAccount:GetOnlineRoleID() > 0 then
			goRemoteCall:CallWait("RoleOfflineReq", function(nAccountID)
				oAccount:LoadData() --重新加载数据,逻辑服可能有修改
				oAccount:RoleOffline() --离线操作

				oAccount:BindSession(nSession)
				if oAccount:RoleLogin(nRoleID) then
					self.m_tAccountSSMap[nNewSSKey] = oAccount
					LuaTrace("角色登陆成功", oAccount:GetName(), nRoleID)
				end

				if nSession ~= nOldSession then
					self:OtherPlaceLogin(nOldServer, nOldSession, oAccount:GetName())
				end

			end , nOldServer, oAccount:GetLogic(), nOldSession, oAccount:GetID())

		else
			oAccount:BindSession(nSession)
			if oAccount:RoleLogin(nRoleID) then
				self.m_tAccountSSMap[nNewSSKey] = oAccount
				LuaTrace("角色登陆成功", oAccount:GetName(), nRoleID)
			end

			if nSession ~= nOldSession then
				self:OtherPlaceLogin(nOldServer, nOldSession, oAccount:GetName())
			end

		end

	else
	--账号未加载
		local sData = goDBMgr:GetSSDB(nServer, "global"):HGet(gtDBDef.sAccountNameDB, nAccountID)
		if sData == "" then
			return CLAccount:Tips("账号不存在", nServer, nSession)
		end

		--加载账号数据
		local oAccount = CLAccount:new(nServer, nSession, nAccountID, 0, "")
		oAccount:LoadData()
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

goLoginMgr = goLoginMgr or CLoginMgr:new()