--GLOBAL角色管理器[GlobalSrever和WGlobalServer共用]
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--因为可能多个GLOBAL服务共用一个SSDB,所以需要用服务ID区分表名
local sMixGlobalRoleDB = gtDBDef.sGlobalRoleDB.."_"..CUtil:GetServiceID()

function CGRoleMgr:Ctor()
	CGModuleBase.Ctor(self, gtGModuleDef.tGRoleMgr)
	self.m_tRoleIDMap = {}
	self.m_tRoleSSMap = {}
	self.m_tDirtyMap = {}
end

function CGRoleMgr:LoadData()
	LuaTrace("加载全局玩家数据------")
	local nServerID = GetGModule("ServerMgr"):GetServerID()
	local oDB = GetGModule("DBMgr"):GetGameDB(nServerID, "global", CUtil:GetServiceID())
	local tKeys = oDB:HKeys(sMixGlobalRoleDB)
	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(sMixGlobalRoleDB, sRoleID)
		local tData = cseri.decode(sData)
		local oRole = CGRole:new()
		oRole:LoadData(tData)
		self.m_tRoleIDMap[oRole:GetID()] = oRole
	end
	self:OnLoaded()
end

function CGRoleMgr:SaveData()
	local oDB = GetGModule("DBMgr"):GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	for nRoleID, _ in pairs(self.m_tDirtyMap) do
		local oRole = self.m_tRoleIDMap[nRoleID]
		if not oRole:IsRobot() then 
			local tData = oRole:SaveData()
			oDB:HSet(sMixGlobalRoleDB, nRoleID, cseri.encode(tData)) --可能保存失败(数据库断线)
		end
		self.m_tDirtyMap[nRoleID] = nil
	end
end

function CGRoleMgr:OnLoaded()
end

function CGRoleMgr:Release()
end

function CGRoleMgr:MakeSSKey(nServerID, nSessionID)
	local nSSKey = nServerID << 32 | nSessionID
	return nSSKey
end

function CGRoleMgr:GetRoleByID(nRoleID)
	return self.m_tRoleIDMap[nRoleID]
end

function CGRoleMgr:GetRoleBySS(nServer, nSession)
	local nSSKey = self:MakeSSKey(nServer, nSession)
	return self.m_tRoleSSMap[nSSKey]
end

function CGRoleMgr:GetRoleSSMap()
	return self.m_tRoleSSMap
end

function CGRoleMgr:MarkDirty(nRoleID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyMap[nRoleID] = bDirty
end

--角色上线,全量同步
function CGRoleMgr:RoleOnlineReq(nRoleID, tData)
	local oRole = self:GetRoleByID(nRoleID)
	if oRole then
		assert(tData.m_nServerID == oRole:GetServerID(), "角色服务器错误:"..tostring(tData))
	else
		if not CUtil:IsRobot(nRoleID) then 
			oRole = CGRole:new()
		else
			oRole = CGRobot:new()
		end
		self.m_tRoleIDMap[nRoleID] = oRole
		self:MarkDirty(nRoleID, true)
	end
	oRole:LoadData(tData)

	if not CUtil:IsRobot(nRoleID) then 
		local nSSKey = self:MakeSSKey(oRole:GetServerID(), oRole:GetSessionID())
		self.m_tRoleSSMap[nSSKey] = oRole
		LuaTrace("CGRoleMgr:RoleOnlineReq***", nRoleID, oRole:GetRoleName(), oRole:GetLevel())
	end
	oRole:OnRoleOnline()
end

--角色断连
function CGRoleMgr:RoleDisconnectReq(nRoleID, tData)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole then
		return
	end
	local nServerID = oRole:GetServerID()
	local nSessionID = oRole:GetSessionID()
	oRole:UpdateData(tData)

	if not CUtil:IsRobot(nRoleID) then
		local nSSKey = self:MakeSSKey(nServerID, nSessionID)
		self.m_tRoleSSMap[nSSKey] = nil
		LuaTrace("CGRoleMgr:RoleDisconnectReq***", nRoleID, oRole:GetRoleName(), oRole:GetLevel())
	end
end

--角色释放
function CGRoleMgr:RoleReleasedReq(nRoleID, tData)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole then
		return
	end
	oRole:UpdateData(tData)
end

--更新数据
function CGRoleMgr:RoleUpdateDataReq(nRoleID, tData)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole then
		return
	end
	oRole:UpdateData(tData)
end

--账号角色删除通知
function CGRoleMgr:AccountRoleDeleteNotify(nAccountID, nRoleID) 
	LuaTrace(string.format("角色删除事件通知: 账号(%d), 角色ID(%d)", nAccountID, nRoleID))
	return true
end
