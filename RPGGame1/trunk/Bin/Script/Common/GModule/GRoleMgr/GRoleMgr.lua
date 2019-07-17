--GLOBAL角色管理器[GlobalSrever和WGlobalServer共用]
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--因为可能多个GLOBAL服务共用一个SSDB,所以需要用服务ID区分表名
local sMixGlobalRoleDB = gtDBDef.sGlobalRoleDB.."_"..CUtil:GetServiceID()

function CGRoleMgr:Ctor()
	self.m_tRoleIDMap = {}
	self.m_tRoleSSMap = {}
	self.m_tDirtyMap = {}
end

function CGRoleMgr:LoadData()
	LuaTrace("加载全局玩家数据------")
	local oDB = GetGModule("DBMgr"):GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	local tKeys = oDB:HKeys(sMixGlobalRoleDB)

	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(sMixGlobalRoleDB, sRoleID)
		local tData = cjson.decode(sData)
		local oRole = CGRole:new()
		oRole:LoadData(tData)
		self.m_tRoleIDMap[oRole:GetID()] = oRole
	end
	self:OnLoaded()
end

function CGRoleMgr:SaveData()
	local oDB = GetGModule("DBMgr"):GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	for nRoleID, _ in pairs(self.m_tDirtyMap) do
		local oRole = self.m_tRoleIDMap[nRoleID]
		if not oRole:IsRobot() then 
			local tData = oRole:SaveData()
			oDB:HSet(sMixGlobalRoleDB, nRoleID, cjson.encode(tData)) --可能保存失败(数据库断线)
		end
		self.m_tDirtyMap[nRoleID] = nil
	end
end

function CGRoleMgr:OnLoaded()
end

function CGRoleMgr:Release()
end

function CGRoleMgr:MakeSSKey(nServer, nSession)
	local nSSKey = nServer << 32 | nSession
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

function CGRoleMgr:RoleOnlineReq(nRoleID, tData)
	local oRole = self:GetRoleByID(nRoleID)
	if oRole then
		local sInfo = string.format("roleid:%d server:%d orgserver:%d accountid:%d accountname:%s"
			, nRoleID, tData.m_nServer, oRole:GetServer(), oRole:GetAccountID(), oRole:GetAccountName())

		assert(tData.m_nServer == oRole:GetServer(), "角色服务器错误: "..sInfo)

	else
		if not CUtil:IsRobot(nRoleID) then 
			oRole = CGRole:new()
		else
			oRole = CGRobot:new()
		end
		self.m_tRoleIDMap[nRoleID] = oRole

	end
	oRole:Init(tData)

	if not CUtil:IsRobot(nRoleID) then 
		local nSSKey = self:MakeSSKey(oRole:GetServer(), oRole:GetSession())
		self.m_tRoleSSMap[nSSKey] = oRole
		self:MarkDirty(nRoleID, true)
		LuaTrace("CGRoleMgr:RoleOnlineReq***", nRoleID, oRole:GetLevel())
	end
	
	oRole:Online()
end

function CGRoleMgr:RoleOfflineReq(nRoleID, tData)
	local oRole = self:GetRoleByID(nRoleID)
	if oRole then
		oRole:Init(tData)
		if not oRole:IsRobot() then 
			if not tData.m_bRelease then
				local nSSKey = self:MakeSSKey(oRole:GetServer(), oRole:GetSession())
				self.m_tRoleSSMap[nSSKey] = nil
				oRole:Offline()
				self.m_nCount = self.m_nCount - 1
				LuaTrace("CGRoleMgr:RoleOffline***", nRoleID, self.m_nCount)
			else
				if oRole:IsOnline() then 
					oRole:Offline()
				end
				oRole:OnRoleRelease()
			end
			self.m_oOnlineLevelMatchHelper:Remove(nRoleID)
		else
			--战斗中下线，只会触发offline，战斗结束，才会触发release
			if not tData.m_bRelease then 
				oRole:Offline()
			else
				if oRole:IsOnline() then 
					oRole:Offline()
				end
				oRole:OnRoleRelease()
				self:MarkDirty(nRoleID, false)
				self.m_tRoleIDMap[nRoleID] = nil
			end
		end
	end
end

function CGRoleMgr:RoleUpdateReq(nRoleID, tData)
	print("CGRoleMgr:RoleUpdateReq***", nRoleID, tData)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole:UpdateReq(tData)
	
	--更新匹配桶
	if tData.m_nLevel and not oRole:IsRobot() then
		self.m_oLevelMatchHelper:UpdateValue(oRole:GetID(), oRole:GetLevel())
		if oRole:IsOnline() then
			self.m_oOnlineLevelMatchHelper:UpdateValue(oRole:GetID(), oRole:GetLevel())
		end
	end
end

--角色更名
function CGRoleMgr:OnRoleNameChange(sOldName, sNewName)
	local oRole = self.m_tRoleNameMap[sOldName]
	self.m_tRoleNameMap[sOldName] = nil
	self.m_tRoleNameMap[sNewName] = oRole
end

--账号角色删除通知
function CGRoleMgr:AccountRoleDeleteNotify(nAccountID, nRoleID) 
	LuaTrace(string.format("角色删除事件通知: 账号(%d), 角色ID(%d)", nAccountID, nRoleID))
	--TODO 

	return true
end
