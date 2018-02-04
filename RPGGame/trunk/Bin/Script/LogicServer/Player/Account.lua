local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--账号模块
gnBasePlayerID = 1000000 --玩家ID起始
local nMaxPlayerID = 9999999-gnBasePlayerID --玩家ID上限

local nAutoSaveTime = 5*60 --自动保存时间
local nMaxRolePerAccount = 3 --每个帐号创建角色上限
function CAccount:Ctor(nID, nServer, nSession, nSource, sName)
	self.m_nID = nID
	self.m_sName = sName
	self.m_nSource = nSource
	self.m_nServer = nServer

	self.m_tRoleSummaryMap = {} 	--角色摘要信息:{[roleid]={sName="",nLevel=0,nGender=0,nSchool=0,tEquipment={},},...}
	self.m_nLastRoleID = 0 			--最后登录的角色ID
	self.m_oOnlineRole = nil 		--在线角色对象(同时只允许一个角色在线)

	--不保存
	self.m_bDirty = false
	self.m_nSaveTick = nil
	self.m_nSession = nSession

end

function CAccount:IsDirty()
	return self.m_bDirty
end

function CAccount:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

function CAccount:LoadData()
	local oDB = goDBMgr:GetSSDB(self.m_nServer, "user", self.m_nID)
	local sData = oDB:HGet(gtDBDef.sAccountDB, self.m_nID) 
	if sData then
		local tData = cjson.decode(sData)
		self.m_tRoleSummaryMap = tData.m_tRoleSummaryMap
		self.m_nLastRoleID = tData.m_nLastRoleID
	end
end

function CAccount:SaveData()
	self.m_oOnlineRole:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tRoleSummaryMap = self.m_tRoleSummaryMap
	tData.m_nLastRoleID = self.m_nLastRoleID
	local oDB = goDBMgr:GetSSDB(self.m_nServer, "user", self.m_nID)
	oDB:HGet(gtDBDef.sAccountDB, self.m_nID, cjson.encode(tData)) 
end

function CAccount:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil

	if self.m_oOnlineRole then
		self.m_oOnlineRole:OnRelease()
		self.m_oOnlineRole = nil
	end
end

function CAccount:RegAutoSave()
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

function CAccount:GetID()
	return self.m_nID
end

function CAccount:GetName()
	return self.m_sName
end

function CAccount:GetSource()
	return self.m_nScoure
end

function CAccount:GetServer()
	return self.m_nServer
end

function CAccount:GetSession()
	return self.m_nSession
end

--取当前在线的角色对象
function CAccount:GetOnlineRole()
	return self.m_oOnlineRole
end

function CAccount:Online()
	if not self.m_oOnlineRole then
		return
	end
	self:RegAutoSave()
	self.m_oOnlineRole:Online()
	self.m_nLastRoleID = self.m_oOnlineRole:GetID()
	self:MarkDirty(true)
end

function CAccount:Offline()
	if not self.m_oOnlineRole then
		return
	end
	self.m_oOnlineRole:Offline()
	self:UpdateSummary()
	self.m_oOnlineRole = nil
end

--更新角色摘要信息
function CAccount:UpdateSummary()
	if not self.m_oOnlineRole then
		return
	end
	--fix pd
end


--生成唯一账号/角色ID
function CAccount:GenPlayerID()
	local oDB = goDBMgr:GetSSDB(0, "center")
	local nIncr = oDB:HIncr(gtDBDef.sPlayerIDDB, "data")
	local nPlayerID = gnBasePlayerID + nIncr % nMaxPlayerID
	return nPlayerID
end

--取角色数量
function CAccount:GetRoleCount()
	local nCount = 0
	for nRoleID, v in pairs(self.m_tRoleSummaryMap) do
		nCount = nCount +1
	end
	return nCount
end

--角色登录
function CAccount:RoleLogin(nID)
end

--创建角色
function CAccount:CreateRole(sName, nGender, nSchool)
	if self:GetRoleCount() >= nMaxRolePerAccount then
		return CRole:Tips("每个帐号只能创建三个角色", self.m_nServer, self.m_nSession)
	end
	local oDB = goDBMgr:GetSSDB(0, "center")
	local sData = oDB:HGet(gtDBDef.sRoleNameDB, sName)
	if sData ~= "" then
		return CRole:Tips("角色名已被使用", self.m_nServer, self.m_nSession)
	end

	local nID = goPlayerMgr:GenPlayerID()
	local oRole = CRole:new(self, nID, sName, nGender, nSchool)
	self.m_oOnlineRole = oRole
	return oRole
end

--删除角色
function CAccount:DeleteRole(nID)
end