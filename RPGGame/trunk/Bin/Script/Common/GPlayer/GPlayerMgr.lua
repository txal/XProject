--GLOBAL角色管理器[GlobalSrever和WGlobalServer共用]
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local sMixGlobalRoleDB = gtDBDef.sGlobalRoleDB.."_"..GF.GetServiceID() --因为2世界GLOBAL服务共用一个SSDB，所以需要用服务ID区分哈希表名!!!

function CGPlayerMgr:Ctor()
	self.m_tRoleIDMap = {}
	self.m_tRoleSSMap = {}
	self.m_nCount = 0

	self.m_tDirtyMap = {}
	self.m_nSaveTimer = nil

	--不保存
	self.m_tRoleNameMap = {}
	self.m_oLevelMatchHelper = CMatchHelper:new(5) 	--所有玩家
	self.m_oOnlineLevelMatchHelper = CMatchHelper:new(5) --在线玩家
end

--在线人数
function CGPlayerMgr:GetCount()
	return self.m_nCount
end

--世界服的角色数据迁移
function CGPlayerMgr:MoveOldData(oDB)
	LuaTrace("CGPlayerMgr:MoveOldData***")
	local tKeys = oDB:HKeys(gtDBDef.sGlobalRoleDB)
	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sGlobalRoleDB, sRoleID)
		oDB:HSet(sMixGlobalRoleDB, sRoleID, sData)
	end
	return tKeys
end

function CGPlayerMgr:LoadData()
	LuaTrace("加载全局玩家数据")
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local tKeys = oDB:HKeys(sMixGlobalRoleDB)
	if #tKeys <= 0 then
		tKeys = self:MoveOldData(oDB)
	end
	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(sMixGlobalRoleDB, sRoleID)
		local tData = cjson.decode(sData)
		local oRole = CGRole:new()
		oRole:LoadData(tData)
		self.m_tRoleIDMap[oRole:GetID()] = oRole
		self.m_tRoleNameMap[oRole:GetName()]= oRole
		self.m_oLevelMatchHelper:UpdateValue(oRole:GetID(), oRole:GetLevel())
	end
	self:OnLoaded()
end

function CGPlayerMgr:SaveData()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	for nRoleID, v in pairs(self.m_tDirtyMap) do
		local oRole = self.m_tRoleIDMap[nRoleID]
		if not oRole:IsRobot() then 
			local tData = oRole:SaveData()
			oDB:HSet(sMixGlobalRoleDB, nRoleID, cjson.encode(tData)) --可能保存失败(断线)
		end
		self.m_tDirtyMap[nRoleID] = nil
	end
end

function CGPlayerMgr:OnLoaded()
	self.m_nSaveTimer = goTimerMgr:Interval(gnAutoSaveTime, function() self:SaveData() end)
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

function CGPlayerMgr:GetRoleByName(sName)
	return self.m_tRoleNameMap[sName]
end

function CGPlayerMgr:GetRoleSSMap()
	return self.m_tRoleSSMap
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
	local oRole = self:GetRoleByID(nRoleID)
	if oRole then
		local sInfo = string.format("roleid:%d server:%d orgserver:%d accountid:%d accountname:%s"
			, nRoleID, tData.m_nServer, oRole:GetServer(), oRole:GetAccountID(), oRole:GetAccountName())
		assert(tData.m_nServer == oRole:GetServer(), "角色服务器错误: "..sInfo)

	else
		if not GF.IsRobot(nRoleID) then 
			oRole = CGRole:new()
		else
			oRole = CGRobot:new()
		end
		self.m_tRoleIDMap[nRoleID] = oRole

	end
	oRole:Init(tData)
	oRole:Online()

	if not GF.IsRobot(nRoleID) then 
		local nSSKey = self:MakeSSKey(oRole:GetServer(), oRole:GetSession())
		self.m_tRoleSSMap[nSSKey] = oRole
		self.m_tRoleNameMap[oRole:GetName()] = oRole --名字健值
		self:MarkDirty(nRoleID, true)

		if tData.m_nLevel then
			self.m_oLevelMatchHelper:UpdateValue(oRole:GetID(), oRole:GetLevel())
			self.m_oOnlineLevelMatchHelper:UpdateValue(oRole:GetID(), oRole:GetLevel())
		end --更新匹配桶

		self.m_nCount = self.m_nCount + 1	
		LuaTrace("CGPlayerMgr:RoleOnlineReq***", nRoleID, oRole:GetLevel(), self.m_nCount+1)
	end
end

function CGPlayerMgr:RoleOfflineReq(nRoleID, tData)
	local oRole = self:GetRoleByID(nRoleID)
	if oRole then
		oRole:Init(tData)
		if not oRole:IsRobot() then 
			if not tData.m_bRelease then
				local nSSKey = self:MakeSSKey(oRole:GetServer(), oRole:GetSession())
				self.m_tRoleSSMap[nSSKey] = nil
				oRole:Offline()
				self.m_nCount = self.m_nCount - 1
				LuaTrace("CGPlayerMgr:RoleOffline***", nRoleID, self.m_nCount)
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

function CGPlayerMgr:RoleUpdateReq(nRoleID, tData)
	print("CGPlayerMgr:RoleUpdateReq***", nRoleID, tData)
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
function CGPlayerMgr:OnRoleNameChange(sOldName, sNewName)
	local oRole = self.m_tRoleNameMap[sOldName]
	self.m_tRoleNameMap[sOldName] = nil
	self.m_tRoleNameMap[sNewName] = oRole
end

--账号角色删除通知
function CGPlayerMgr:AccountRoleDeleteNotify(nAccountID, nRoleID) 
	LuaTrace(string.format("角色删除事件通知: 账号(%d), 角色ID(%d)", nAccountID, nRoleID))
	--TODO 

	return true
end


goGPlayerMgr = goGPlayerMgr or CGPlayerMgr:new()