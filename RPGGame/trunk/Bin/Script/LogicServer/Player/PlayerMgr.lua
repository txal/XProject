--角色(角色)管理模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPlayerMgr:Ctor()
	self.m_tRoleIDMap = {}		--角色ID影射: {[roleid]=role, ...}
	self.m_tRoleSSMap = {} 		--SS(server<<32|session)映射: {[mixid]=role, ...}
end

function CPlayerMgr:GetRoleIDMap()
	return self.m_tRoleIDMap
end

function CPlayerMgr:GetRoleSSMap()
	return self.m_tRoleSSMap
end

function CPlayerMgr:MakeSSKey(nServer, nSession)
	local nSSKey = nServer << 32 | nSession
	return nSSKey
end

--通过角色ID取在线角色对象
function CPlayerMgr:GetRoleByID(nRoleID)
	return self.m_tRoleIDMap[nRoleID]
end

--通过SSKey取在线角色对象
function CPlayerMgr:GetRoleBySS(nServer, nSession)
	local nSSKey = self:MakeSSKey(nServer, nSession)
	return self.m_tRoleSSMap[nSSKey]
end

--角色登陆成功请求
--@nServer: 角色所属的服务器
--@nSession: 角色的会话ID
function CPlayerMgr:RoleOnlineReq(nServer, nSession, nRoleID, bSwitchLogic)
	print("CPlayerMgr:RoleOnlineReq***", nRoleID, nRoleID, bSwitchLogic)
	assert(nServer < 10000, "角色来源不能是世界服!")
	local oRole = self:GetRoleByID(nRoleID)
	if oRole and oRole:GetSession() > 0 then
		return LuaTrace("角色已在线", oRole:GetName())
	end

	local bReconnect = false
	if not oRole then
		oRole = CRole:new(nServer, nRoleID)
	else
		bReconnect = true
		assert(oRole:GetServer() == nServer, "服务器错误")
		assert(oRole:GetID() == nRoleID, "角色错误")
		assert(oRole:GetSession() == 0, "会话ID错误")
	end
	oRole:BindSession(nSession)

	--切换逻辑服不调用Online
	if not bSwitchLogic then
		oRole:Online()
	end

	self.m_tRoleIDMap[nRoleID] = oRole
	--可能队长带队,队员离线
	if nSession > 0 then
		local nSSKey = self:MakeSSKey(nServer, nSession)
		self.m_tRoleSSMap[nSSKey] = oRole
	end

	--切换逻辑服不调用
	if not bSwitchLogic then
		oRole:AfterOnline(bReconnect)
		goLogger:EventLog(gtEvent.eLogin, oRole, oRole:GetOnlineTime()-oRole:GetOfflineTime())
	end
end

--角色离线请求(清数据)
function CPlayerMgr:RoleOfflineReq(nRoleID, bSwitchLogic)
	print("CPlayerMgr:RoleOfflineReq***", nRoleID, bSwitchLogic)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole then
		LuaTrace("角色未登录:", nRoleID)
		return 0
	end

	--日志
	if not bSwitchLogic and oRole:GetSession() > 0 then
		goLogger:EventLog(gtEvent.eLogout, oRole, oRole:GetOfflineTime()-oRole:GetOnlineTime())
	end

	--下线处理
	if not bSwitchLogic then
		xpcall(function() oRole:Offline() end, function(sErr) LuaTrace(sErr, debug.traceback()) end)
	end
	oRole:OnRelease()

	local nServer = oRole:GetServer()
	local nSession = oRole:GetSession()
	local nSSKey = self:MakeSSKey(nServer, nSession)
	self.m_tRoleIDMap[nRoleID] = nil
	self.m_tRoleSSMap[nSSKey] = nil

	return oRole:GetAccountID()
end

--角色断线请求(保留数据)
function CPlayerMgr:RoleDisconnectReq(nRoleID)
	print("CPlayerMgr:RoleDisconnectReq***", nRoleID)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole or oRole:GetSession() == 0 then
		LuaTrace("角色未登录:", nRoleID)
		return (oRole and oRole:GetAccountID() or 0)
	end

	--日志
	if not bSwitchLogic then
		goLogger:EventLog(gtEvent.eLogout, oRole, oRole:GetOfflineTime()-oRole:GetOnlineTime())
	end

	--断线
	local nServer = oRole:GetServer()
	local nSession = oRole:GetSession()
	local nSSKey = self:MakeSSKey(nServer, nSession)
	self.m_tRoleSSMap[nSSKey] = nil
	oRole:OnDisconnect()
	return oRole:GetAccountID()
end

--切换逻辑服请求
function CPlayerMgr:OnSwitchLogicReq(nRoleSession, nRoleServer, nRoleID, nSrcDupMixID, nTarDupMixID, nPosX, nPosY, nLine)
	local nSrcDupID = GF.GetDupID(nSrcDupMixID)
	local nTarDupID = GF.GetDupID(nTarDupMixID)
    print("切换逻辑服:", nSrcDupID.."->"..nTarDupID, nRoleServer, nRoleSession, nPosX, nPosY, nLine)

    self:RoleOnlineReq(nRoleServer, nRoleSession, nRoleID, true)
    local oRole = self:GetRoleByID(nRoleID)
    goDupMgr:EnterDupCreate(nTarDupMixID, oRole:GetNativeObj(), nPosX, nPosY, nLine)
end


goPlayerMgr = goPlayerMgr or CPlayerMgr:new()
goNativePlayerMgr = GlobalExport.GetPlayerMgr()
