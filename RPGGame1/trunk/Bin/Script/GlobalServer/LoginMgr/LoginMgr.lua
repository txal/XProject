--账号(玩家)登陆管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLoginMgr:Ctor()
    CGModuleBase.Ctor(self, gtGModuleDef.tLoginMgr)
    
	self.m_tAccountIDMap = {}		--账号ID影射: {[accountid]=account, ...}
	self.m_tAccountNameMap = {}		--账号名字影射: {[accountkey]=account, ...}
	self.m_tAccountSSMap = {} 		--SS(server<<32|session)映射: {[mixid]=account, ...}
	self.m_nOnlineNum = 0           --当前在线的玩家数量(含离线保护中的玩家)

	self.m_oLoginQueue = CLoginQueue:new()
end

function CLoginMgr:OnMinTimer()
end

function CLoginMgr:Release()
	self.m_oLoginQueue:Release()
	for nAccountID, oAccount in pairs(self.m_tAccountIDMap) do
		oAccount:Release()
	end
end

function CLoginMgr:GetAccountDB()
	local nServerID = GetGModule("ServerMgr"):GetServerID()
	return GetGModule("DBMgr"):GetGameDB(nServerID, "user", 1)
end

function CLoginMgr:MakeAccountKey(sAccount, nServerID, nSource, sChannel)
	nSource = nSource or 0
	sChannel = sChannel or ""

	local sAccountKey
	if self:IsDivisionSourceAccount(nServerID) then
		sAccountKey = string.format("%d_%s_%s", nSource, sChannel, sAccount)
	else
		sAccountKey = string.format("%d_%s_%s", 0, sChannel, sAccount)
	end
	return sAccountKey
end

function CLoginMgr:MakeSSKey(nServerID, nSessionID)
	local nSSKey = nServerID << 32 | nSessionID
	return nSSKey
end

function CLoginMgr:GetAccountByID(nAccountID)
	return self.m_tAccountIDMap[nAccountID]
end

function CLoginMgr:GetAccountByName(sAccountKey)
	return self.m_tAccountNameMap[sAccountKey]
end

function CLoginMgr:GetAccountBySS(nSSKey)
	return self.m_tAccountSSMap[nSSKey]
end

function CLoginMgr:GetLoginQueue()
	return self.m_oLoginQueue
end

function CLoginMgr:AddOnlineNum(nCount)
	self.m_nOnlineNum = math.max(0, self.m_nOnlineNum + nCount)
	if nCount < 0 then --统计离线玩家数量
		self:GetLoginQueue():OfflineCount(-nCount, os.time())
	end
end

function CLoginMgr:GetOnlineNum()
	return self.m_nOnlineNum
end

--账号下线(清理数据)
function CLoginMgr:AccountOffline(nAccountID, nAccountSessionID)
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		return
	end

	local nSSkey = self:MakeSSKey(oAccount:GetServerID(), oAccount:GetSessionID())
	local sAccountKey = self:MakeAccountKey(oAccount:GetName(), oAccount:GetServerID(), oAccount:GetSource(), oAccount:GetChannel())
	local nOnlineRoleID = oAccount:GetOnlineRoleID()

	if nOnlineRoleID <= 0 then
		LuaTrace("AccountOffline: 无角色登录账号释放成功***", oAccount:GetName())
		self.m_tAccountSSMap[nSSkey] = nil
		self.m_tAccountIDMap[nAccountID] = nil
		self.m_tAccountNameMap[sAccountKey] = nil
		oAccount:OnRelease()
		return
	end

	Network:RMCall("RoleOfflineReq", function()
		if oAccount:GetSessionID() > 0 and oAccount:GetSessionID() ~= nAccountSessionID then
		--异步过程中重连了
			return LuaTrace("AccountOffline: 账号异步释放失败,重连了***", oAccount:GetName())
		end
		LuaTrace("AccountOffline: 有角色登录账号异步释放成功***", oAccount:GetName())
		self.m_tAccountSSMap[nSSkey] = nil
		self.m_tAccountIDMap[nAccountID] = nil
		self.m_tAccountNameMap[sAccountKey] = nil
		oAccount:RoleOffline()
		oAccount:OnRelease()

	end, oAccount:GetServerID(), oAccount:GetLogicServiceID(), nAccountSessionID, nOnlineRoleID)
end

--角色断开连接
function CLoginMgr:OnClientClose(nServerID, nSessionID)
	local oAccount = self:GetAccountBySS(nServerID, nSessionID)
	if not oAccount then
		return
	end
	if nSessionID ~= oAccount:GetSessionID() then 
		return LuaTrace("会话ID错误:", oAccount:GetName(), nSessionID, oAccount:GetSessionID())
	end
	local nSSKey = self:MakeSSKey(nServerID, nSessionID)
	self.m_tAccountSSMap[nSSKey] = nil

	local nOnlineRoleID = oAccount:GetOnlineRoleID()
	if nOnlineRoleID > 0 then
		Network:RMCall("RoleDisconnectReq", nil, oAccount:GetServerID(), oAccount:GetLogicServiceID(), oAccount:GetSessionID(), nOnlineRoleID)
	end
	oAccount:OnDisconnect()
end

--发送异地登陆消息
function CLoginMgr:OtherPlaceLogin(nServerID, nSessionID)
	if nSessionID <= 0 then
		return
	end
	CLAccount:SendMsg("OtherPlaceLoginRet", {}, nServerID, nSessionID)

	GetGModule("TimerMgr"):Interval(2, function(nTimerID) 
		GetGModule("TimerMgr"):Clear(nTimerID)
		Network.CmdSrv2Srv("KickClientReq", nServerID, nSessionID>>gtGDef.tConst.nServiceShift, nSessionID)
	end)
end

--账号数据是否区分
function CLoginMgr:IsDivisionSourceAccount(nServerID)
	return GetGModule("ServerMgr"):IsDivisionSourceAccount(nServerID)
end

--处理合服账号名问题
--@nClientServerID 客户端发过来的要进入的目标服务器ID
function CLoginMgr:DealMergedServerAccount(sAccount, nClientServerID)
	if nClientServerID > 0 and GetGModule("ServerMgr"):IsMerged(nClientServerID) then
		local sSuffix = string.format("_[%d]", nClientServerID)
		sAccount = string.format("%s%s", sAccount, sSuffix)
	end
	return sAccount
end

--角色列表请求
function CLoginMgr:RoleListReq(sAccount, nServerID, nSessionID, nSource, sChannel, nClientServerID)
	if string.Trim(sAccount) == "" then
		return CLAccount:Tips("账号不能为空", nServerID, nSessionID)
	end

	--合服账号名字处理
	sAccount = self:DealMergedServerAccount(sAccount, nClientServerID)

	local sAccountKey = self:MakeAccountKey(sAccount, nServerID, nSource, sChannel)
	local nNewSSKey = self:MakeSSKey(nServerID, nSessionID)
	local oAccount = self:GetAccountByName(sAccountKey)

	if oAccount then
		local nOldServerID = oAccount:GetServerID()
		local nOldSessionID = oAccount:GetSessionID()
		assert(nOldServerID == nServerID, "服务器ID错误")
		local nOldSSKey = self:MakeSSKey(nOldServerID, nOldSessionID)

		local nOnlineRoleID = oAccount:GetOnlineRoleID()
		if nOnlineRoleID > 0 and nOldSessionID > 0 then
		--已有角色登陆
			print("已有角色登陆:", nOnlineRoleID, nSessionID, nOldSessionID)
			Network:RMCall("RoleDisconnectReq", function(nAccountID)
				oAccount:OnDisconnect()
				oAccount:BindSession(nSessionID)

				self.m_tAccountSSMap[nOldSSKey] = nil
				self.m_tAccountSSMap[nNewSSKey] = oAccount
				oAccount:RoleListReq()

				if nSessionID ~= nOldSessionID then
					self:OtherPlaceLogin(nOldServerID, nOldSessionID)
				end

			end, nOldServerID, oAccount:GetLogicServiceID(), nOldSessionID, nOnlineRoleID)

		else
		--没有角色登陆
			print("没有角色登陆:", nSessionID)
			oAccount:BindSession(nSessionID)
			self.m_tAccountSSMap[nOldSSKey] = nil
			self.m_tAccountSSMap[nNewSSKey] = oAccount
			oAccount:RoleListReq()

			if nSessionID ~= nOldSessionID then
				self:OtherPlaceLogin(nOldServerID, nOldSessionID)
			end

		end

	--账号不在线/或新建账号
	else
		local nAccountID = 0
		local oDB = self:GetAccountDB()
		local sData = oDB:HGet(gtDBDef.sAccountNameDB, sAccountKey)
		if sData == "" then
		--账号不存在,创建之
			nAccountID = CUtil:GenUUID()
			local tAccountData = {nSource=nSource, sChannel=sChannel, sAccount=sAccount, nAccountID=nAccountID, sAccountKey=sAccountKey, nTime=os.time()}
			local sAccountData = cseri.encode(tAccountData)
			oDB:HSet(gtDBDef.sAccountNameDB, sAccountKey, sAccountData)
			oDB:HSet(gtDBDef.sAccountNameDB, nAccountID, sAccountData)
			goLogger:CreateAccountLog(nSource, sChannel, nAccountID, sAccount, 0)

		else
			local tData = cseri.decode(sData)
			nAccountID = tData.nAccountID
			if not nAccountID then
				oDB:HDel(gtDBDef.sAccountNameDB, sAccountKey)
				return LuaTrace("账号数据错误", sAccount)
			end
		end
		--加载账号数据
		oAccount = CLAccount:new(nServerID, nSessionID, nAccountID, sAccount, nSource, sChannel)
		self.m_tAccountSSMap[nNewSSKey] = oAccount
		self.m_tAccountIDMap[nAccountID] = oAccount
		self.m_tAccountNameMap[sAccountKey] = oAccount
		oAccount:RoleListReq()

	end

end

--创建角色请求
function CLoginMgr:RoleCreateReq(nServerID, nSessionID, tData)
	local nAccountID = tData.nAccountID 
	local nConfID = tData.nConfID
	local sRoleName = tData.sRoleName
	
	local nNameLen = string.len(sRoleName)
	if nNameLen <= 0 or nNameLen > 8*3 then
		return CLAccount:Tips("角色名字太长啦", nServerID, nSessionID)
	end
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		return CLAccount:Tips("账号已离线，请刷新页面", nServerID, nSessionID)
	end

	local function _fnBadWordCallback(bBadWord)
		if bBadWord then
			return oAccount:Tips("角色名存在非法字符")
		end

		local nOldServerID = oAccount:GetServerID()
		local nOldSessionID = oAccount:GetSessionID()
		assert(nOldServerID == nServerID, "服务器错误")
		assert(nOldSessionID == nSessionID, "会话ID错误") --1定相等

		if oAccount:GetRoleCount() >= 1 then
			return oAccount:Tips("每个帐号只能创建1个角色")
		end

		local nOnlineRoleID = oAccount:GetOnlineRoleID()
		if nOnlineRoleID > 0 then
			Network:RMCall("RoleOfflineReq", function(nAccountID)
				if (nAccountID or 0) <= 0 then
					return LuaTrace("账号离线失败", nAccountID)
				end

				oAccount:RoleOffline()
				oAccount:BindSession(nSessionID)

				if oAccount:CreateRole(nConfID, sRoleName) then
					self.m_tAccountSSMap[nNewSSKey] = oAccount
					LuaTrace("角色登陆成功", nAccountID, oAccount:GetName(), nOnlineRoleID)
				end

			end , nOldServerID, oAccount:GetLogicServiceID(), nOldSessionID, nOnlineRoleID)

		else
			--创建角色并登录
			oAccount:BindSession(nSessionID)
			if oAccount:CreateRole(nConfID, sRoleName) then
				LuaTrace("创建角色并登陆成功")
			end

		end
	end
	CUtil:HasBadWord(sRoleName, _fnBadWordCallback)
end

--角色登陆请求
function CLoginMgr:RoleLoginReq(nServerID, nSessionID, nAccountID, nRoleID)
	local nNewSSKey = self:MakeSSKey(nServerID, nSessionID)
	local function _fnRoleLogin(oAccount, nServerID, nSessionID, nOldSessionID)
		oAccount:BindSession(nSessionID)
		if oAccount:RoleLogin(nRoleID) then
			self.m_tAccountSSMap[nNewSSKey] = oAccount
			LuaTrace("角色登陆成功", oAccount:GetName(), nAccountID, nRoleID)
		end

		if nOldServerID and nOldSessionID and nOldSessionID ~= nSessionID then
			local nOldSSKey = self:MakeSSKey(nOldServerID, nOldSessionID)
			self.m_tAccountSSMap[nOldSSKey] = nil
			self:OtherPlaceLogin(nOldServerID, nOldSessionID)
		end
	end

	--账号已加载
	local oAccount = self:GetAccountByID(nAccountID)
	if oAccount then
		if oAccount:GetAccountState() == gtAccountState.eLockAccount then
			return oAccount:Tips("账号已被封停，请联系客服")
		end
		local nOldServerID = oAccount:GetServerID()
		local nOldSessionID = oAccount:GetSessionID()
		assert(nOldServerID == nServerID, "服务器ID错误")

		--当前有角色
		local nOnlineRoleID = oAccount:GetOnlineRoleID()
		if nOnlineRoleID > 0 then
			if nOnlineRoleID == nRoleID then
			--同一角色并在线则断线处理,否则直接登录
				if nOldSessionID > 0 and nOldSessionID ~= nSessionID then
					Network:RMCall("RoleDisconnectReq", function(nAccountID)
						_fnRoleLogin(oAccount, nServerID, nSessionID, nOldSessionID)

					end , nServerID, oAccount:GetLogicServiceID(), nOldSessionID, nOnlineRoleID)

				else
					_fnRoleLogin(oAccount, nServerID, nSessionID, nOldSessionID)

				end

			else
			--不同角色就先清理当前角色数据再登陆新角色
				Network:RMCall("RoleOfflineReq", function(nAccountID)
					if nAccountID <= 0 then
						return LuaTrace("账号离线失败", oAccount:GetName(), nAccountID, nOnlineRoleID)
					end
					oAccount:RoleOffline() --离线操作
					_fnRoleLogin(oAccount, nServerID, nSessionID, nOldSessionID)

				end , nServerID, oAccount:GetLogicServiceID(), nOldSessionID, nOnlineRoleID)

			end

		--当前没有角色直接登录
		else
			_fnRoleLogin(oAccount, nServerID, nSessionID, nOldSessionID)

		end

	else
	--账号未加载
		local oDB = self:GetAccountDB()
		local sData = oDB:HGet(gtDBDef.sAccountNameDB, nAccountID)
		if sData == "" then
			return CLAccount:Tips("账号不存在", nServerID, nSessionID)
		end

		--加载账号数据
		local oAccount = CLAccount:new(nServerID, nSessionID, nAccountID, "", 0, "")
		if oAccount:GetAccountState() == gtAccountState.eLockAccount then
			oAccount:Release()
			return oAccount:Tips("账号已被封停，请联系客服")
		end
		
		self.m_tAccountSSMap[nNewSSKey] = oAccount
		self.m_tAccountIDMap[nAccountID] = oAccount
		local sAccountKey = self:MakeAccountKey(oAccount:GetName(), oAccount:GetServerID(), oAccount:GetSource(), oAccount:GetChannel())
		self.m_tAccountNameMap[sAccountKey] = oAccount

		if not oAccount:RoleLogin(nRoleID) then
			oAccount:Release()
			self.m_tAccountSSMap[nNewSSKey] = nil
			self.m_tAccountIDMap[nAccountID] = nil
			self.m_tAccountNameMap[sAccountKey] = nil
			return
		end
		LuaTrace("角色登陆成功", oAccount:GetName(), nAccountID, nRoleID)
	end
end

function CLoginMgr:GetMaxOnlineNum() --最大允许登录玩家数量
	return gtGDef.tConst.nMaxOnlineNum
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
function CLoginMgr:OnServiceClose(nServerID, nServiceID)
	local tGateServiceList = GetGModule("ServerMgr"):GetGateServiceList()
	for _, tService in ipairs(tGateServiceList) do
		if tService .nServerID == nServerID and tService.nServiceID == nServiceID then
			for nAccountID, oAccount in pairs(self.m_tAccountIDMap) do
				local nSessionID = oAccount:GetSessionID()
				if nSessionID > 0 then
					local nGateServiceID = CUtil:GetGateBySession(nSessionID)
					if oAccount:GetServerID() == nServerID and nGateServiceID == nServiceID then
						self:OnClientClose(nServerID, nSessionID)
					end
				end
			end
			break
		end
	end
end

--服务器关闭,对应服的角色断线处理
function CLoginMgr:OnServerClose(nServerID)
	for nID, oAccount in pairs(self.m_tAccountIDMap) do
		if oAccount:GetServerID() == nServerID then
			local nSessionID = oAccount:GetSessionID()
			if nSessionID > 0 then
				self:OnClientClose(nServerID, nSessionID)
			end
		end
	end
end

--更新角色摘要
function CLoginMgr:UpdateSimpleRoleReq(nAccountID, nRoleID, tData)
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		return LuaTrace("账号未登陆", nAccountID)
	end
	oAccount:UpdateSimpleRoleData(nRoleID, tData)
end

--更新账号数据
function CLoginMgr:UpdateAccountDataReq(nAccountID, tData)
	local bTmpAccount = false
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		local oDB = self:GetAccountDB()
		local sData = oDB:HGet(gtDBDef.sAccountNameDB, nAccountID)
		if sData == "" then
			return false
		end
		oAccount = CLAccount:new(GetGModule("ServerMgr"):GetServerID(), 0, nAccountID, "", 0, "")
		bTmpAccount = true
	end
	oAccount:UpdateAccountData(tData)
	oAccount:SaveData()
	if bTmpAccount then
		oAccount:Release()
	end
	return true
end

--删除角色
function CLoginMgr:DeleteRoleReq(nAccountID, nRoleID) 
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then --当前，必须登录账号，才可以删除 
		return LuaTrace("账号未登陆", nAccountID)
	end
	LuaTrace(string.format("开始删除 账号(%d), 角色(%d)", nAccountID, nRoleID))
	oAccount:DeleteRoleReq(nRoleID)
end

