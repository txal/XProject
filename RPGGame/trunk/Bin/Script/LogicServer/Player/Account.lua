local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--账号模块
local nAutoSaveTime = 5*60 --自动保存时间
local nMaxRolePerAccount = 3 --每个帐号创建角色上限
local nMaxPlayerID = 9999999-nBASE_PLAYERID --玩家ID上限
function CAccount:Ctor(nID, nServer, nSession, nSource, sName)
	self.m_nID = nID
	self.m_sName = sName
	self.m_nSource = nSource
	self.m_nServer = nServer

	self.m_tRoleSummaryMap = {} 	--角色摘要信息:{[roleid]={nID=0,sName="",nLevel=0,nGender=0,nSchool=0,tEquipment={},},...}
	self.m_nLastRoleID = 0 			--最后登录的角色ID
	self.m_oOnlineRole = nil 		--在线角色对象(同时只允许一个角色在线)

	--不保存
	self.m_bDirty = false
	self.m_nSaveTimer = nil
	self.m_nSession = nSession

end

function CAccount:IsDirty() return self.m_bDirty end
function CAccount:MarkDirty(bDirty) self.m_bDirty = bDirty end

function CAccount:LoadData()
	local sData = goDBMgr:GetSSDB(self:GetServer(), "user", self:GetID()):HGet(gtDBDef.sAccountDB, self:GetID())
	if sData then
		local tData = cjson.decode(sData)
		self.m_tRoleSummaryMap = tData.m_tRoleSummaryMap
		self.m_nLastRoleID = tData.m_nLastRoleID
	end
end

function CAccount:SaveData()
	self.m_oOnlineRole:SaveData()

	if self:IsDirty() then
		self:MarkDirty(false)

		local tData = {}
		tData.m_tRoleSummaryMap = self.m_tRoleSummaryMap
		tData.m_nLastRoleID = self.m_nLastRoleID

		goDBMgr:GetSSDB(self:GetServer(), "user", self:GetID()):HSet(gtDBDef.sAccountDB, self:GetID(), cjson.encode(tData)) 
	end
end

function CAccount:OnRelease()
	self:CancelAutoSave()

	if self.m_oOnlineRole then
		self.m_oOnlineRole:OnRelease()
		self.m_oOnlineRole = nil
	end
end

function CAccount:CancelAutoSave()
	goTimerMgr:Clear(self.m_nSaveTimer)
	self.m_nSaveTimer = nil
end

function CAccount:RegAutoSave()
	self:CancelAutoSave()
	self.m_nSaveTimer = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

function CAccount:GetID() return self.m_nID end
function CAccount:GetName() return self.m_sName end
function CAccount:GetSource() return self.m_nScoure end
function CAccount:GetServer() return self.m_nServer end
function CAccount:GetSession() return self.m_nSession end
function CAccount:GetOnlineRole() return self.m_oOnlineRole end

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
	self:UpdateRoleSummary()
	self:SaveData()
end

--更新角色摘要信息
function CAccount:UpdateRoleSummary()
	if not self.m_oOnlineRole then
		return
	end
	local nID = self.m_oOnlineRole:GetID() 
	local tSummary = self.m_tRoleSummaryMap[nID] or {}
	self.m_tRoleSummaryMap[nID] = tSummary

	tSummary.nID = nID
	tSummary.sName = self.m_oOnlineRole:GetName()
	tSummary.nGender = self.m_oOnlineRole:GetGender()
	tSummary.nSchool = self.m_oOnlineRole:GetSchool()
	tSummary.nLevel = self.m_oOnlineRole:GetLevel()
	tSummary.tEquipment = self.m_oOnlineRole:GetEquipment()

	self:MarkDirty(true)
end


--生成唯一账号/角色ID
function CAccount:GenPlayerID()
	local nIncr = goDBMgr:GetSSDB(0, "center"):HIncr(gtDBDef.sPlayerIDDB, "data")
	local nPlayerID = nBASE_PLAYERID + nIncr % nMaxPlayerID
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
	local tSummary = self.m_tRoleSummaryMap[nID]
	if not tSummary then
		return CRole:Tips("角色不存在", self:GetServer(), self:GetSession())
	end
	if self.m_oOnlineRole then
		assert(self.m_oOnlineRole:GetID() == nID, "角色登录冲突了")
		return CmdNet.PBSrv2Clt("LoginRet", self:GetServer(), self:GetSession(), {nServerID=self:GetServer()})
	end
	self.m_oOnlineRole = CRole:new(self, tSummary.nID, tSummary.sName, tSummary.nGender, tSummary.nSchool)
	return true
end

--创建角色
function CAccount:CreateRole(sName, nGender, nSchool)
	if self.m_oOnlineRole then
		return CRole:Tips("需要先退出当前账号", self:GetServer(), self:GetSession())
	end
	if self:GetRoleCount() >= nMaxRolePerAccount then
		return CRole:Tips("每个帐号只能创建三个角色", self:GetServer(), self:GetSession())
	end
	local sData = goDBMgr:GetSSDB(self:GetServer(), "global"):HGet(gtDBDef.sRoleNameDB, sName)
	if sData ~= "" then
		return CRole:Tips("角色名已被占用", self:GetServer(), self:GetSession())
	end

	local nID = self:GenPlayerID()
	self.m_oOnlineRole = CRole:new(self, nID, sName, nGender, nSchool)
	return true
end

--删除角色
function CAccount:DeleteRole(nID)
end

--角色列表请求
function CAccount:RoleListReq()
	if self.m_oOnlineRole then
		self:UpdateRoleSummary()
	end
	local tList = {}
	for nRoleID, tSummary in pairs(self.m_tRoleSummaryMap) do
		local tRole = {nID=nRoleID, sName=tSummary.sName, nGender=tSummary.nGender, nSchool=tSummary.nSchool, nLevel=tSummary.nLevel}
		table.insert(tList, tRole)
	end
	CmdNet.PBSrv2Clt("RoleListRet", self:GetServer(), self:GetSession(), {tList=tList})
end