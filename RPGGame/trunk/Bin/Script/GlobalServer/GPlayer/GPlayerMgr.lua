--GLOBAL帐号(玩家)管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nAutoSaveTime = 5*60
local nServerID = gnServerID

function CGPlayerMgr:Ctor()
	self.m_tRoleIDMap = {}
	self.m_tRoleSSMap = {}
	self.m_tDirtyMap = {}
	self.m_nSaveTimer = nil
end

function CGPlayerMgr:LoadData()
	local oDB = goDBMgr:GetSSDB(nServerID, "global")
	local tKeys = oDB:HKeys(gtDBDef.sGlobalRoleDB)
	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sGlobalRoleDB, sRoleID)
		local tData = cjson.decode(sData)
		local oRole = CGRole:new()
		oRole:LoadData(tData)
		self.m_tRoleIDMap[oRole:GetID()] = oRole
	end
	self:OnLoaded()
end

function CGPlayerMgr:SaveData()
	local oDB = goDBMgr:GetSSDB(nServerID, "global")
	for nRoleID, v in pairs(self.m_tDirtyMap) do
		local oRole = self.m_tRoleIDMap[nRoleID]
		local tData = oRole:SaveData()
		oDB:HSet(gtDBDef.sGlobalRoleDB, nRoleID, cjson.encode(tData))
	end
	self.m_tDirtyMap = {}
end

function CGPlayerMgr:OnLoaded()
	self.m_nSaveTimer = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

function CGPlayerMgr:OnRelease()
	self:SaveData()
	goTimerMgr:Clear(self.m_nSaveTimer)
end

function CGPlayerMgr:MakeSSKey(nServer, nSession)
	local nSSKey = nServer << 32 | nSession
	return nSSKey
end

function CGPlayerMgr:GetRoleByID(nRoleID)
	return self.m_tRoleIDMap[nRoleID]
end

function CGPlayerMgr:GetRoleBySS(nServer, nSession)
	local nSSKey = self:MakeSSKey(nServer, nSession)
	return self.m_tRoleSSMap[nSSKey]
end

function CGPlayerMgr:MarkDirty(nRoleID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyMap[nRoleID] = bDirty
end

function CGPlayerMgr:RoleOnlineReq(nRoleID, tData)
	print("CGPlayerMgr:RoleOnlineReq***", nRoleID)
	local oRole = self:GetRoleByID(nRoleID)
	if oRole then
		assert(tData.m_nServer == oRole:GetServer(), "角色服务器错误")

	else
		oRole = CGRole:new()
		self.m_tRoleIDMap[nRoleID] = oRole

	end
	oRole:Init(tData)
	oRole:Online()

	local nSSKey = self:MakeSSKey(oRole:GetServer(), oRole:GetSession())
	self.m_tRoleSSMap[nSSKey] = oRole
	self:MarkDirty(nRoleID, true)
end

function CGPlayerMgr:RoleOfflineReq(nRoleID)
	print("CGPlayerMgr:RoleOffline***", nRoleID)
	local oRole = self:GetRoleByID(nRoleID)
	if oRole then
		local nSSKey = self:MakeSSKey(oRole:GetServer(), oRole:GetSession())
		oRole:Offline()
		self.m_tRoleSSMap[nSSKey] = nil
	end
end

function CGPlayerMgr:RoleUpdateReq(nRoleID, tData)
	local oRole = self:GetRoleByID(nRoleID)
	if oRole then
		oRole:UpdateReq(tData)
		self:MarkDirty(nRoleID, true)
	end
end

function CGPlayerMgr:GetOnlineCount()
	local nCount = 0
	for nSSKey, oRole in pairs(self.m_tRoleSSMap) do
		nCount = nCount + 1
	end
	return nCount
end


goGPlayerMgr = goGPlayerMgr or CGPlayerMgr:new()