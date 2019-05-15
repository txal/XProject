--账号(玩家)登陆管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nMaxOnlineNum = 5000         --最大同时在线人数

function CLoginMgr:Ctor()
	self.m_tAccountIDMap = {}		--账号ID影射: {[accountid]=account, ...}
	self.m_tAccountNameMap = {}		--账号名字影射: {[accountkey]=account, ...}
	self.m_tAccountSSMap = {} 		--SS(server<<32|session)映射: {[mixid]=account, ...}
	self.m_nOnlineNum = 0           --当前在线的玩家数量(含离线保护中的玩家)

	self.m_tLoginQueue = CLoginQueue:new()

	self.m_tGMAccountMap = {}
	self.m_nGMTimer = goTimerMgr:Interval(60, function() self:UpdateGMAccount() end)
end

function CLoginMgr:UpdateGMAccount()
	self.m_tGMAccountMap = {}

	local sql = "select accountname,source from gmaccount limit 32;"
	local oMgrSql = goDBMgr:GetMgrMysql()
	oMgrSql:Query(sql)
	while oMgrSql:FetchRow() do
		local sAccount = oMgrSql:ToString("accountname")
		local nSource = oMgrSql:ToInt32("source")
		self.m_tGMAccountMap[sAccount] = nSource
	end
end

function CLoginMgr:OnRelease()
	goTimerMgr:Clear(self.m_nGMTimer)
	self.m_nGMTimer = nil

	self.m_tLoginQueue:OnRelease()
	for nAccountID, oAccount in pairs(self.m_tAccountIDMap) do
		oAccount:OnRelease()
		-- LuaTrace("CLoginMgr:OnRelease***1"
		-- 	, oAccount:GetServer(), oAccount:GetID(), oAccount:GetName(), oAccount:GetSource(), oAccount:GetSession(), oAccount.m_nKeepTimer, oAccount.m_nSaveTimer)
	end

	-- for sAccountKey, oAccount in pairs(self.m_tAccountNameMap) do
	-- 	LuaTrace("CLoginMgr:OnRelease***2", sAccountKey, oAccount:GetServer(), oAccount:GetID(), oAccount:GetName(), oAccount:GetSource(), oAccount:GetSession(), oAccount.m_nKeepTimer, oAccount.m_nSaveTimer)
	-- end
	-- for sSSKey, oAccount in pairs(self.m_tAccountSSMap) do
	-- 	LuaTrace("CLoginMgr:OnRelease***3", sSSKey, oAccount:GetServer(), oAccount:GetID(), oAccount:GetName(), oAccount:GetSource(), oAccount:GetSession(), oAccount.m_nKeepTimer, oAccount.m_nSaveTimer)
	-- end
end

function CLoginMgr:GetAccountDB()
	return goDBMgr:GetSSDB(gnServerID, "user", 1)
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
	local nService = nSession >> gnServiceShift
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

function CLoginMgr:GetLoginQueue() return self.m_tLoginQueue end
function CLoginMgr:AddOnlineNum(nCount)
	self.m_nOnlineNum = self.m_nOnlineNum + nCount
	if nCount < 0 then --统计离线玩家数量
		self:GetLoginQueue():OfflineCount(-nCount, os.time())
	end
end
function CLoginMgr:GetOnlineNum() return self.m_nOnlineNum end

--账号下线(清理数据)
function CLoginMgr:AccountOffline(nAccountID)
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
		oAccount:OnRelease()
		self.m_tAccountIDMap[nAccountID] = nil
		self.m_tAccountNameMap[sAccountKey] = nil
		self.m_tAccountSSMap[nSSKey] = nil
		return
	end

	goRemoteCall:CallWait("RoleOfflineReq", function()
		oAccount:RoleOffline()
		oAccount:OnRelease()
		self.m_tAccountIDMap[nAccountID] = nil
		self.m_tAccountNameMap[sAccountKey] = nil
		self.m_tAccountSSMap[nSSKey] = nil

	end, nServer, oAccount:GetLogic(), nSession, nOnlineRoleID)
end

--角色断开连接
function CLoginMgr:OnClientClose(nServer, nSession)
	local oAccount = self:GetAccountBySS(nServer, nSession)
	print("CLoginMgr:OnClientClose***", nServer, nSession, oAccount and oAccount:GetName() or nil)
	if not oAccount then
		return
	end
	if nSession ~= oAccount:GetSession() then 
		LuaTrace("会话ID错误", nSession, oAccount:GetSession())
		return
	end
	local nSSKey = self:MakeSSKey(nServer, nSession)
	self.m_tAccountSSMap[nSSKey] = nil

	local nOnlineRoleID = oAccount:GetOnlineRoleID()
	if nOnlineRoleID > 0 then
		goRemoteCall:Call("RoleDisconnectReq", oAccount:GetServer(), oAccount:GetLogic(), oAccount:GetSession(), nOnlineRoleID)
		if not gbServerClosing then
			goRemoteCall:CallWait("TeamBattleInfoReq", function(nTeamID, tTeam)
				if not nTeamID then
					return
				end
				if oAccount:GetCurrDupType()==1 and (nTeamID==0 or (nTeamID>0 and #tTeam==1)) then
					self:AccountOffline(oAccount:GetID())
				end
			end, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nOnlineRoleID)
		end
	end
	oAccount:OnDisconnect()
end

--发送异地登陆消息
function CLoginMgr:OtherPlaceLogin(nServer, nSession, sAccount, nNewSession)
	if nSession <= 0 then
		return
	end
	CmdNet.PBSrv2Clt("OtherPlaceLoginRet", nServer, nSession, {})
	goTimerMgr:Interval(2, function(nTimerID) 
		goTimerMgr:Clear(nTimerID)
		CmdNet.Srv2Srv("KickClientReq", nServer, nSession>>gnServiceShift, nSession)
	end)
end

--判断数据区分
function CLoginMgr:CheckDivisionPlatform(nServer, nSource, sAccount)
	nSource = nSource or 0
	if goServerMgr:IsDivisionPlatform(nServer) then
		return nSource
	end
	return 0
end

--处理合服账号名问题
function CLoginMgr:DealMergeServerAccount(nSource, sAccount, nServerID)
	if nServerID > 0 and goServerMgr:IsMerged(nServerID) then
		local sSuffix = ""
		if nServerID > 0 then
			sSuffix = string.format("_[%d]", nServerID)
		end
		local sTmpAccount = string.format("%s%s", sAccount, sSuffix)
		return sTmpAccount
	else
		return sAccount
	end
end

--角色列表请求
function CLoginMgr:RoleListReq(nServer, nSession, nSource, sAccount, nServerID)
	print("CLoginMgr:RoleListReq***", nServer, nSession, nSource, sAccount, nServerID)
	if sAccount == "" then
		return CLAccount:Tips("账号不能为空", nServer, nSession)
	end
	-- if not string.find(sAccount, "abc") and not string.find(sAccount, "test") then
	--  	return CLAccount:Tips("系统改造中，goodgoodstudy,daydayup!!", nServer, nSession)
	-- end
	nSource = self:CheckDivisionPlatform(nServer, nSource, sAccount)

	--3733渠道特殊处理
	if string.find(sAccount, "3733_") then
		local oDB = self:GetAccountDB()
		local sRawAccount = string.sub(sAccount, 6)
		local sRawAccountKey = self:MakeAccountKey(nSource, sRawAccount)
		local sData = oDB:HGet(gtDBDef.sAccountNameDB, sRawAccountKey)
		if sData ~= "" then
			sAccount = sRawAccount
		end
	end

	--GM账号处理
	local nGMSource = self.m_tGMAccountMap[sAccount]
	if nGMSource then
		nSource = nGMSource
	end

	--合服账号名字处理
	sAccount = self:DealMergeServerAccount(nSource, sAccount, nServerID)
	print("DealMergeServerAccount***", sAccount)

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
			print("已有角色登陆:", nOnlineRoleID, nSession, nOldSession)
		--已有角色登陆
			goRemoteCall:CallWait("RoleDisconnectReq", function(nAccountID)
				oAccount:OnDisconnect()
				oAccount:BindSession(nSession)

				self.m_tAccountSSMap[nOldSSKey] = nil
				self.m_tAccountSSMap[nNewSSKey] = oAccount
				oAccount:RoleListReq()

				if nSession ~= nOldSession then
					self:OtherPlaceLogin(nOldServer, nOldSession, sAccount, nSession)
				end

			end, nOldServer, oAccount:GetLogic(), nOldSession, nOnlineRoleID)

		else
			print("没有角色登陆:", nSession)
		--没有角色登陆
			oAccount:BindSession(nSession)
			self.m_tAccountSSMap[nOldSSKey] = nil
			self.m_tAccountSSMap[nNewSSKey] = oAccount
			oAccount:RoleListReq()

			if nSession ~= nOldSession then
				self:OtherPlaceLogin(nOldServer, nOldSession, sAccount, nSession)
			end

		end

	--账号不在线/或新建账号
	else
		local nAccountID = 0
		local oDB = self:GetAccountDB()
		local sData = oDB:HGet(gtDBDef.sAccountNameDB, sAccountKey)
		if sData == "" then
		--账号不存在,创建之
			nAccountID = CLAccount:GenPlayerID()
			oDB:HSet(gtDBDef.sAccountNameDB, sAccountKey, cjson.encode({nAccountID=nAccountID, nTime=os.time()}))
			oDB:HSet(gtDBDef.sAccountNameDB, nAccountID, cjson.encode({nSource=nSource, sAccount=sAccount, nTime=os.time()}))
			goLogger:CreateAccountLog(nSource, nAccountID, sAccount, 0)

		else
			local tData = cjson.decode(sData)
			nAccountID = tData.nAccountID
			if not nAccountID then
				oDB:HDel(gtDBDef.sAccountNameDB, sAccountKey)
				return LuaTrace("账号数据错误", sAccount)
			end
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
function CLoginMgr:RoleCreateReq(nServer, nSession, tData)
	print("CLoginMgr:RoleCreateReq***", tData)
	local nAccountID = tData.nAccountID 
	local nConfID = tData.nConfID
	local sRole = tData.sName
	
	local nLen = string.len(sRole)
	if nLen <= 0 or nLen > 8*3 then
		return CLAccount:Tips("名字长度非法", nServer, nSession)
	end

	local nInviteRoleID = tData.nInviteRoleID
	local oAccount = self:GetAccountByID(nAccountID)
	assert(oAccount, "账号未加载")

	local function _fnBadWordCallback(bBadWord)
		if bBadWord then
			return oAccount:Tips("角色名存在非法字符")
		end

		local nOldServer = oAccount:GetServer()
		local nOldSession = oAccount:GetSession()
		assert(nOldServer == nServer, "服务器错误")
		assert(nOldSession == nSession, "会话ID错误") --1定相等

		if oAccount:GetRoleCount() >= 1 then
			return oAccount:Tips(string.format("每个帐号只能创建%d个角色", 1))
		end

		local nOnlineRoleID = oAccount:GetOnlineRoleID()
		if nOnlineRoleID > 0 then
			goRemoteCall:CallWait("RoleOfflineReq", function(nAccountID)
				if (nAccountID or 0) <= 0 then
					return LuaTrace("账号离线失败", nAccountID)
				end

				oAccount:RoleOffline() --离线操作
				oAccount:BindSession(nSession)

				if oAccount:CreateRole(nConfID, sRole, nInviteRoleID) then
					self.m_tAccountSSMap[nNewSSKey] = oAccount
					LuaTrace("角色登陆成功", oAccount:GetName(), nAccountID, nOnlineRoleID)
				end

			end , nOldServer, oAccount:GetLogic(), nOldSession, nOnlineRoleID)

		else
			--创建角色并登录
			oAccount:BindSession(nSession)
			if oAccount:CreateRole(nConfID, sRole, nInviteRoleID) then
				LuaTrace("创建角色并登陆成功")
			end

		end
	end
	GF.HasBadWord(sRole, _fnBadWordCallback)
end

--角色登陆请求
function CLoginMgr:RoleLoginReq(nServer, nSession, nAccountID, nRoleID)
	print("CLoginMgr:RoleLoginReq***", nServer, nSession)
	local nNewSSKey = self:MakeSSKey(nServer, nSession)
	local function _RoleLogin(oAccount, nSession, nOldServer, nOldSession)
		oAccount:BindSession(nSession)
		if oAccount:RoleLogin(nRoleID) then
			self.m_tAccountSSMap[nNewSSKey] = oAccount
			LuaTrace("角色登陆成功", oAccount:GetName(), nAccountID, nRoleID)
		end

		if nOldServer and nOldSession then
			if nOldSession ~= nSession then
				local nOldSSKey = self:MakeSSKey(nOldServer, nOldSession)
				self.m_tAccountSSMap[nOldSSKey] = nil
				self:OtherPlaceLogin(nOldServer, nOldSession, oAccount:GetName(), nSession)
			end
		end
	end

	--账号已加载
	local oAccount = self:GetAccountByID(nAccountID)
	if oAccount then
		if oAccount:GetAccountState() == gtAccountState.eLockAccount then
			return oAccount:Tips("账号已被封停，请联系客服")
		end
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
		local oDB = self:GetAccountDB()
		local sData = oDB:HGet(gtDBDef.sAccountNameDB, nAccountID)
		if sData == "" then
			return CLAccount:Tips("账号不存在", nServer, nSession)
		end

		--加载账号数据
		local oAccount = CLAccount:new(nServer, nSession, nAccountID, 0, "")
		if oAccount:GetAccountState() == gtAccountState.eLockAccount then
			oAccount:OnRelease()
			return oAccount:Tips("账号已被封停，请联系客服")
		end
		
		self.m_tAccountIDMap[nAccountID] = oAccount
		local sAccountKey = self:MakeAccountKey(oAccount:GetSource(), oAccount:GetName())
		self.m_tAccountNameMap[sAccountKey] = oAccount
		self.m_tAccountSSMap[nNewSSKey] = oAccount
		if not oAccount:RoleLogin(nRoleID) then
			oAccount:OnRelease()
			self.m_tAccountIDMap[nAccountID] = nil
			self.m_tAccountNameMap[sAccountKey] = nil
			self.m_tAccountSSMap[nNewSSKey] = nil
			return
		end
		LuaTrace("角色登陆成功", oAccount:GetName(), nAccountID, nRoleID)
	end
end

function CLoginMgr:GetMaxOnlineNum() --最大允许登录玩家数量
	return nMaxOnlineNum
end

function CLoginMgr:GetLoginAllowNum()
    local nOnlineNum = self:GetOnlineNum()
	local nAllowNum = math.max(self:GetMaxOnlineNum() - nOnlineNum, 0)
	return nAllowNum
end

function CLoginMgr:IsServerMax()
    if self:GetLoginAllowNum() < 1 then 
        return true 
    end
    return false
end

--有服务断开,如果是网关则相关帐号做离线处理
function CLoginMgr:OnServiceClose(nServer, nService)
	--如果是网关断开则对应的玩家断线处理
	local bGateService = false
	for _, tConf in ipairs(goServerMgr:GetGateServiceList()) do
		if tConf.nServer == nServer and nService == tConf.nID then
			bGateService = true
			break
		end
	end
	if not bGateService then
		return
	end

	--离线处理
	LuaTrace("网关关闭------", nServer, nService)
	for nID, oAccount in pairs(self.m_tAccountIDMap) do
		local nSession = oAccount:GetSession()
		local nTmpService = self:GetServiceBySession(nSession)
		if oAccount:GetServer() == nServer and nTmpService == nService then
			self:OnClientClose(nServer, nSession)
		end
	end
end

--服务器关闭
function CLoginMgr:OnServerClose(nServer)
	--角色离线,保存数据
	for nID, oAccount in pairs(self.m_tAccountIDMap) do
		local nSession = oAccount:GetSession()
		local nService = self:GetServiceBySession(nSession)
		self:OnClientClose(nServer, nSession)
		oAccount:SaveData()
	end
end

--更新角色摘要
function CLoginMgr:RoleUpdateSummaryReq(nAccountID, nRoleID, tSummary)
	print("CLoginMgr:RoleUpdateSummaryReq***", nAccountID, nRoleID, tSummary)
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		return LuaTrace("账号未登陆", nAccountID)
	end
	oAccount:UpdateRoleSummary(nRoleID, tSummary)
end

--更新账号数据
function CLoginMgr:UpdateAccountValueReq(nAccountID, tData)
	local bTempAccount = false
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		local oDB = self:GetAccountDB()
		local sData = oDB:HGet(gtDBDef.sAccountNameDB, nAccountID)
		if sData == "" then
			return false
		end
		bTempAccount = true
		oAccount = CLAccount:new(gnServerID, 0, nAccountID, 0, "")
	end
	oAccount:UpdateValueReq(tData)
	oAccount:SaveData()
	if bTempAccount then
		oAccount:OnRelease()
	end
	return true
end

--删除角色
function CLoginMgr:DeleteRoleReq(nAccountID, nRoleID) 
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then --当前，必须登录账号，才可以删除 
		return LuaTrace("账号未登陆", nAccountID)
	end
	print(string.format("开始删除 账号(%d), 角色(%d)", nAccountID, nRoleID))
	oAccount:DeleteRoleReq(nRoleID)
end


goLoginMgr = goLoginMgr or CLoginMgr:new()