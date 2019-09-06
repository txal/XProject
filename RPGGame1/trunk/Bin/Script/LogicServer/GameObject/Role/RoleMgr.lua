--角色管理模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRoleMgr:Ctor()
	CGModuleBase.Ctor(self)

	self.m_tRoleIDMap = {}		--角色ID影射: {[roleid]=role, ...}
	self.m_tRoleSSMap = {} 		--SS(ServerID<<32|SessionID)映射: {[ssid]=role, ...}
	self.m_nCount = 0
end

function CRoleMgr:Release()
end

function CRoleMgr:OnMinTimer()
	for nRoleID, oRole in pairs(self.m_tRoleIDMap) do
		oRole:OnMinTimer()
	end
end

function CRoleMgr:OnHourTimer()
	for nRoleID, oRole in pairs(self.m_tRoleIDMap) do
		oRole:OnHourTimer()
	end
end

function CRoleMgr:GetCount()
	return self.m_nCount
end

function CRoleMgr:GetRoleIDMap()
	return self.m_tRoleIDMap
end

function CRoleMgr:GetRoleSSMap()
	return self.m_tRoleSSMap
end

function CRoleMgr:MakeSSKey(nServerID, nSessionID)
	local nSSKey = nServerID << 32 | nSessionID
	return nSSKey
end

--通过角色ID取在线角色对象
function CRoleMgr:GetRoleByID(nRoleID)
	return self.m_tRoleIDMap[nRoleID]
end

--通过SSKey取在线角色对象
function CRoleMgr:GetRoleBySS(nServerID, nSessionID)
	local nSSKey = self:MakeSSKey(nServerID, nSessionID)
	return self.m_tRoleSSMap[nSSKey]
end

--角色登陆成功请求
--@nServerID: 角色所属的服务器
--@nSessionID: 角色的会话ID
function CRoleMgr:RoleOnlineReq(nServerID, nSessionID, nRoleID, bSwitchLogic)
	assert(nServerID < GetGModule("ServerIDMgr"):GetWorldServerIDID(), "角色所属服务器不能是世界服")
	local oRole = self:GetRoleByID(nRoleID)
	if oRole and oRole:GetSessionID() > 0 then
		return LuaTrace("角色已经在线", oRole:GetID(), oRole:GetName())
	end

	local bReconnect
	if not oRole then
		bReconnect = false
		oRole = CRole:new()
	else
		bReconnect = true
		assert(oRole:GetObjID() == nRoleID, "角色ID错误")
		assert(oRole:GetServerID() == nServerID, "服务器错误")
		assert(oRole:GetSessionID() == 0, "会话ID错误")
	end
	oRole:BindServerID(nServerID)
	oRole:BindSessionID(nSessionID)
	self.m_tRoleIDMap[nRoleID] = oRole

	--队长带队可能队员不在线,所以nSessionID>0时才放到表里面
	if nSessionID > 0 then
		self.m_tRoleSSMap[self:MakeSSKey(nServerID,nSessionID)] = oRole
	end
	--切换逻辑服不调用Online
	if not bSwitchLogic then
		oRole:Online(bReconnect)
		GetGModule("Logger"):UpdateRoleLog(oRole, {logintime=os.time(),online=1})
		GetGModule("Logger"):EventLog(gtEvent.eOnline, oRole, oRole:GetOnlineTime()-oRole:GetDisconnectTime())
	end
	self.m_nCount = self.m_nCount + 1
end

--角色下线(释放)请求
function CRoleMgr:RoleOfflineReq(nRoleID, bSwitchLogic)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole then
		LuaTrace("CRoleMgr:RoleOfflineReq角色未登录:", nRoleID)
		return 0
	end

	local function _fnReleaseRole()
		oRole:Release()
		local nServerID = oRole:GetServerID()
		local nSessionID = oRole:GetSessionID()
		local nSSKey = self:MakeSSKey(nServerID, nSessionID)
		self.m_tRoleSSMap[nSSKey] = nil
		self.m_tRoleIDMap[nRoleID] = nil
		self.m_nCount = self.m_nCount - 1
	end

	--普通释放
	if not bSwitchLogic then
		if oRole:IsOnline() then --在线先下线
			self:RoleDisconnectReq(nRoleID)
		end
		if oRole:Offline() then
			_fnReleaseRole()
			GetGModule("Logger"):EventLog(gtEvent.eRoleRelease, oRole)		
		end
	--切换场景
	else
		_fnReleaseRole()
	end
	return oRole:GetAccountID()
end

--角色断线请求
function CRoleMgr:RoleDisconnectReq(nRoleID)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole or not oRole:IsOnline() then
		LuaTrace("CRoleMgr:RoleDisconnectReq角色未登录:", nRoleID)
		return (oRole and oRole:GetAccountID() or 0)
	end

	--断线
	local nServerID = oRole:GetServerID()
	local nSessionID = oRole:GetSessionID()
	local nSSKey = self:MakeSSKey(nServerID, nSessionID)
	self.m_tRoleSSMap[nSSKey] = nil
	oRole:OnDisconnect()

	GetGModule("Logger"):UpdateRoleLog(oRole, {online=0})
	GetGModule("Logger"):EventLog(gtEvent.eDisconnect, oRole, oRole:GetDisconnectTime()-oRole:GetOnlineTime())
	return oRole:GetAccountID()
end

--切换逻辑服请求
function CRoleMgr:OnSwitchLogicReq(tSwitchData)
    print("切换逻辑服:", tSwitchData)
    self:RoleOnlineReq(tSwitchData.nServerID, tSwitchData.nSessionID, tSwitchData.nObjID, true)
    local oRole = self:GetRoleByID(tSwitchData.nObjID)
    oRole:EnterScene(tSwitchData.nDupID, tSwitchData.nSceneID, tSwitchData.nPosX, tSwitchData.nPosY, tSwitchData.nLine, tSwitchData.nFace)
end

--将玩家踢离线
function CRoleMgr:KickRole(nRoleID)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole or not oRole:IsOnline() then
		return
	end
	local nSessionID = oRole:GetSessionID()
	Network.CmdSrv2Srv("KickClientReq", oRole:GetServerID(), nSessionID>>gtGDef.tConst.nServiceShift, nSessionID)
end

--服务器关闭
function CRoleMgr:OnServerClose(nServerID)
	--强制对应服玩家释放
	for nRoleID, oRole in pairs(self.m_tRoleIDMap) do
		if nServerID == oRole:GetServerID() then
			oRole:ForceFinishBattle()
			self:RoleOfflineReq(nRoleID)
		end
	end
end

--服务关闭
function CRoleMgr:OnServiceClose(nServerID, nServiceID)
	--如果是登录服,对应服玩家下线
	local tGlobalServiceList = GetGModule("ServerMgr"):GetGlobalServiceList()
	for _, tService in ipairs(tGlobalServiceList) do
		if tService.nServerID == nServerID and tService.nServiceID == nServiceID then
			for nRoleID, oRole in pairs(self.m_tRoleIDMap) do
				if nServerID == oRole:GetServerID() then
					self:RoleDisconnectReq(nRoleID)
				end
			end
			break
		end
	end
end
