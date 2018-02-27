--帐号(角色)管理模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPlayerMgr:Ctor()
	self.m_tAccountIDMap = {}		--账号ID影射: {[accountid]=account, ...}
	self.m_tAccountSSMap = {} 		--SS(server<<32|session)映射: {[mixid]=account, ...}
end

function CPlayerMgr:GetAccountIDMap()
	return self.m_tAccountIDMap
end

function CPlayerMgr:GetAccountSSMap()
	return self.m_tAccountSSMap
end

function CPlayerMgr:MakeSSKey(nServer, nSession)
	local nSSKey = nServer << 32 | nSession
	return nSSKey
end

--通过账号ID取在线账号对象
function CPlayerMgr:GetAccountByID(nAccountID)
	return self.m_tAccountIDMap[nAccountID]
end

--通过账号ID取在线角色对象
function CPlayerMgr:GetRoleByAccountID(nAccountID)
	local oAccount = self:GetAccountByID(nAccountID)
	if oAccount then
		return oAccount:GetOnlineRole()
	end
end

--通过SSKey取在线账号对象
function CPlayerMgr:GetAccountBySS(nServer, nSession)
	local nSSKey = self:MakeSSKey(nServer, nSession)
	return self.m_tAccountSSMap[nSSKey]
end

--通过SSKey取在线角色对象
function CPlayerMgr:GetRoleBySS(nServer, nSession)
	local oAccount = self:GetAccountBySS(nServer, nSession)
	if oAccount then
		return oAccount:GetOnlineRole()
	end
end

--更新角色摘要信息请求
function CPlayerMgr:RoleUpdateSummaryReq(nAccountID)
	print("CPlayerMgr:RoleUpdateSummaryReq***", nAccountID)
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		LuaTrace("帐号未登录:", nAccountID)
		return nAccountID
	end
	oAccount:UpdateRoleSummary()
	return nAccountID
end

--角色登陆成功请求
--@nServer: 帐号所属的服务器
--@nSession: 帐号的会话ID
function CPlayerMgr:RoleOnlineReq(nServer, nSession, nAccountID, nRoleID, bSwitchLogic)
	print("CPlayerMgr:RoleOnlineReq***", nAccountID, nRoleID, bSwitchLogic)
	assert(nServer < 10000, "角色来源不能是世界服!")
	local oAccount = self:GetAccountByID(nAccountID)
	if oAccount and oAccount:GetSession() > 0 then
		return LuaTrace("帐号已在线", oAccount:GetName())
	end

	if not oAccount then
		oAccount = CAccount:new(nServer, nSession, nAccountID)
		if not oAccount:LoadData() then
			return CRole:Tips("帐号不存在", nServer, nSession)
		end
	else
		assert(oAccount:GetOnlineRole():GetID() == nRoleID, "角色错误")
		assert(oAccount:GetSession() == 0, "会话ID错误")
		oAccount:SetSessioin(nSession)
	end

	if oAccount:Online(nRoleID, bSwitchLogic) then
		local nSSKey = self:MakeSSKey(nServer, nSession)
		self.m_tAccountSSMap[nSSKey] = oAccount
		self.m_tAccountIDMap[nAccountID] = oAccount

		if not bSwitchLogic then
			oAccount:AfterOnline()

			local oRole = oAccount:GetOnlineRole()
			goLogger:EventLog(gtEvent.eLogin, oRole, oRole:GetOnlineTime()-oRole:GetOfflineTime())
		end
		return nAccountID
	end
end

--角色离线请求(清数据)
function CPlayerMgr:RoleOfflineReq(nAccountID, bSwitchLogic)
	print("CPlayerMgr:RoleOfflineReq***", nAccountID, bSwitchLogic)
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		LuaTrace("帐号未登录:", nAccountID)
		return nAccountID
	end

	--日志
	if not bSwitchLogic and oAccount:GetSession() > 0 then
		local oRole = oAccount:GetOnlineRole()
		goLogger:EventLog(gtEvent.eLogout, oRole, oRole:GetOfflineTime()-oRole:GetOnlineTime())
	end

	--下线处理
	if not bSwitchLogic then
		xpcall(function() oAccount:Offline() end, function(sErr) LuaTrace(sErr, debug.traceback()) end)
	end
	oAccount:OnRelease()

	local nServer = oAccount:GetServer()
	local nSession = oAccount:GetSession()
	local nSSKey = self:MakeSSKey(nServer, nSession)
	self.m_tAccountSSMap[nSSKey] = nil
	self.m_tAccountIDMap[nAccountID] = nil
	return nAccountID
end

--角色断线请求(保留数据)
function CPlayerMgr:RoleDisconnectReq(nAccountID)
	print("CPlayerMgr:RoleDisconnectReq***", nAccountID)
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		LuaTrace("帐号未登录:", nAccountID)
		return nAccountID
	end

	--日志
	if not bSwitchLogic then
		local oRole = oAccount:GetOnlineRole()
		goLogger:EventLog(gtEvent.eLogout, oRole, oRole:GetOfflineTime()-oRole:GetOnlineTime())
	end

	--断线
	local nServer = oAccount:GetServer()
	local nSession = oAccount:GetSession()
	local nSSKey = self:MakeSSKey(nServer, nSession)
	self.m_tAccountSSMap[nSSKey] = nil
	oAccount:Disconnect()
	return nAccountID
end


goPlayerMgr = goPlayerMgr or CPlayerMgr:new()
goNativePlayerMgr = GlobalExport.GetPlayerMgr()
