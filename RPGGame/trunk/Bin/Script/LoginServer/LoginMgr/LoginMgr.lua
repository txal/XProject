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

--角色离线
function CLoginMgr:OnClientClose(nServer, nSession)
	local oAccount = self:GetAccountBySS(nServer, nSession)
	if not oAccount then
		return
	end
	
	local nSSKey = self:MakeSSKey(nServer, nSession)
	local nSource, sAccount = oAccount:GetSource(), oAccount:GetName()
	local sAccountKey = self:MakeAccountKey(nSource, sAccount)

	goRemoteCall:CallWait("RoleOfflineReq", function(nAccountID)
		local oAccount = self:GetAccountByID(nAccountID)
		if oAccount then
			oAccount:LoadData()
			oAccount:RoleOffline()

			self.m_tAccountIDMap[nAccountID] = nil
			self.m_tAccountNameMap[sAccountKey] = nil
			self.m_tAccountSSMap[nSSKey] = nil
		end
	end, oAccount:GetServer(), oAccount:GetLogic(), oAccount:GetSession(), oAccount:GetID())

end

--发送异地登陆消息
function CLoginMgr:OtherPlaceLogin(nServer, nSession, sAccount)
	print("CLoginMgr:OtherPlaceLogin***", sAccount)
	CmdNet.PBSrv2Clt(nServer, nSession, "OtherPlaceLoginRet", {})
	goTimerMgr:Interval(2, function(nTimerID) 
		goTimerMgr:Clear(nTimerID)
		CmdNet.Srv2Srv("KickClient", nServer, nSession>>nSERVICE_SHIFT, nSession)
	end)
end

--角色列表请求
function CLoginMgr:RoleListReq(nServer, nSession, nSource, sAccount)
	local sAccountKey = self:MakeAccountKey(nSource, sAccount)
	local oAccount = self:GetAccountByName(sAccountKey)

	--账号在线需要先到逻辑服更新当前在线角色摘要信息
	if oAccount then
		goRemoteCall:CallWait("UpdateRoleSummaryReq", function(nAccountID)
			--要重新取Account对象,因可能已下线
			local oAccount = self:GetAccountByID(nAccountID)
			if oAccount then
				oAccount:LoadData() --重新加载数据,逻辑服可能有修改
				oAccount:RoleListReq()
			end
		end , oAccount:GetServer(), oAccount:GetLogic(), oAccount:GetSession(), oAccount:GetID())

	--账号不在线/或新建账号
	else
		local nAccountID = 0
		local oDB = goDBMgr:GetSSDB(nServer, "global")
		local sData = oDB:HGet(gtDBDef.sAccountNameDB, sAccountKey)
		--账号不存在,创建之
		if sData == "" then
			nAccountID = CLAccount:GenPlayerID()
			oDB:HSet(gtDBDef.sAccountNameDB, sAccountKey, cjson.encode({nAccountID=nAccountID}))
		else
			nAccountID = cjson.decode(sData).nAccountID
		end
		--加载账号数据,但是不做缓存
		oAccount = CLAccount:new(nServer, nServer, nAccountID, nSource, sAccount)
		oAccount:LoadData()
		oAccount:RoleListReq()
	end

end

--创建角色请求
function CLoginMgr:CreateRoleReq(nServer, nSession, nSource, sAccount, sRole, nGender, nSchool)
	local sAccountKey = self:MakeAccountKey(nSource, sAccount)

	--创建角色函数
	local function _CreateRole()
		local sData = goDBMgr:GetSSDB(nServer, "global"):HGet(gtDBDef.sAccountNameDB, sAccountKey)
		if sData == "" then
			return CLAccount:Tips("账号不存在", nServer, nSession)
		end
		--加载账号数据
		local nAccountID = cjson.decode(sData).nAccountID
		oAccount = CLAccount:new(nServer, nSession, nAccountID, nSource, sAccount)
		oAccount:LoadData()

		--创建角色和登录成功则缓存
		if oAccount:CreateRole(sRole, nGender, nSchool) then
			self.m_tAccountIDMap[nAccountID] = oAccount
			self.m_tAccountNameMap[sAccountKey] = oAccount
			local nSSKey = self:MakeSSKey(nServer, nSession)
			self.m_tAccountSSMap[nSSKey] = oAccount

			LuaTrace("创建角色并登陆成功")
		end
	end

	--账号在线则先进行异地登陆
	local oAccount = self:GetAccountByName(sAccountKey)
	if oAccount then
		local nOldServer = oAccount:GetServer()
		local nOldSession = oAccount:GetSession()
		goRemoteCall:CallWait("RoleOfflineReq", function(nAccountID)
			--要重新取Account对象,因可能已下线
			local oAccount = self:GetAccountByID(nAccountID)
			if oAccount then
				oAccount:LoadData() --重新加载数据,逻辑服可能有修改
				oAccount:RoleOffline() --离线操作

				self.m_tAccountIDMap[nAccountID] = nil
				self.m_tAccountNameMap[sAccountKey] = nil
				local nSSKey = self:MakeSSKey(nOldServer, nOldSession)
				self.m_tAccountSSMap[nSSKey] = nil

				--不同客户端操作
				if nOldServer ~= nServer or nOldSession ~= nSession then
					self:OtherPlaceLogin(nOldServer, nOldSession, sAccount)
				end
				_CreateRole()
			end
		end , nOldServer, oAccount:GetLogic(), nOldSession, oAccount:GetID())

	--账号不在线,创建角色并登陆
	else
		_CreateRole()

	end
end

--角色登陆请求
function CLoginMgr:LoginRoleReq(nServer, nSession, nSource, sAccount, nRoleID)
	local sAccountKey = self:MakeAccountKey(nSource, sAccount)

	--登录角色函数
	local function _LoginRole()
		local sData = goDBMgr:GetSSDB(nServer, "global"):HGet(gtDBDef.sAccountNameDB, sAccountKey)
		if sData == "" then
			return CLAccount:Tips("账号不存在", nServer, nSession)
		end
		--加载账号数据
		local nAccountID = cjson.decode(sData).nAccountID
		local oAccount = CLAccount:new(nServer, nSession, nAccountID, nSource, sAccount)
		oAccount:LoadData()

		--登录成功则缓存
		if oAccount:RoleLogin(nRoleID) then
			self.m_tAccountIDMap[nAccountID] = oAccount
			self.m_tAccountNameMap[sAccountKey] = oAccount
			local nSSKey = self:MakeSSKey(nServer, nSession)
			self.m_tAccountSSMap[nSSKey] = oAccount

			LuaTrace("角色登陆成功")
		end
	end

	--在线就异地登录
	local oAccount = self:GetAccountByName(sAccountKey)
	if oAccount then
		local nOldServer = oAccount:GetServer()
		local nOldSession = oAccount:GetSession()
		if nOldServer == nServer and nOldSession == nSession then
			return oAccount:RoleLogin(nRoleID)
		end

		goRemoteCall:CallWait("RoleOfflineReq", function(nAccountID)
			--要重新取Account对象,因可能已下线
			local oAccount = self:GetAccountByID(nAccountID)
			if oAccount then
				oAccount:LoadData() --重新加载数据,逻辑服可能有修改
				oAccount:RoleOffline() --离线操作

				self.m_tAccountIDMap[nAccountID] = nil
				self.m_tAccountNameMap[sAccountKey] = nil
				local nSSKey = self:MakeSSKey(nOldServer, nOldSession)
				self.m_tAccountSSMap[nSSKey] = nil

				_LoginRole()

			end
		end , nOldServer, oAccount:GetLogic(), nOldSession, oAccount:GetID())

	--账号不在线,登陆
	else
		_LoginRole()

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