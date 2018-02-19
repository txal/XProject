local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--账号模块
local nAutoSaveTime = 5*60 --自动保存时间
function CAccount:Ctor(nServer, nSession, nID)
	self.m_nID = nID
	self.m_sName = ""
	self.m_nSource = 0
	self.m_nServer = nServer

	self.m_tRoleSummaryMap = {} 	--角色摘要信息:{[roleid]={nID=0,sName="",nLevel=0,nGender=0,nSchool=0,tEquipment={},tLastDup={0,0,0},tCurrDup={0,0,0}},...}
	self.m_nLastRoleID = 0 			--最后登录的角色ID
	self.m_nVIP = 0 				

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
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nID = tData.m_nID
		self.m_sName = tData.m_sName
		self.m_nSource = tData.m_nSource
		self.m_nServer = tData.m_nServer

		self.m_tRoleSummaryMap = tData.m_tRoleSummaryMap
		self.m_nLastRoleID = tData.m_nLastRoleID
		self.m_nVIP = tData.m_nVIP or 0

		return true
	end
end

function CAccount:SaveData()
	self.m_oOnlineRole:SaveData()

	if self:IsDirty() then
		self:MarkDirty(false)

		local tData = {}
		tData.m_nID = self.m_nID
		tData.m_sName = self.m_sName
		tData.m_nSource = self.m_nSource
		tData.m_nServer = self.m_nServer

		tData.m_tRoleSummaryMap = self.m_tRoleSummaryMap
		tData.m_nLastRoleID = self.m_nLastRoleID
		tData.m_nVIP = self.m_nVIP

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
function CAccount:GetVIP() return self.m_nVIP end

function CAccount:Online(nRoleID)
	local tSummary = self.m_tRoleSummaryMap[nRoleID]
	if not tSummary then
		return CRole:Tips("角色不存在", self:GetServer(), self:GetSession())
	end
	self.m_oOnlineRole = CRole:new(self, tSummary.nID)
	self.m_oOnlineRole:Online()
	self:RegAutoSave()
	return true
end

function CAccount:Offline()
	self.m_oOnlineRole:Offline()
	self:UpdateRoleSummary()
end

--更新角色摘要信息
function CAccount:UpdateRoleSummary()
	local nID = self.m_oOnlineRole:GetID() 
	local tSummary = self.m_tRoleSummaryMap[nID]
	if not tSummary then
		tSummary = {}
		self.m_tRoleSummaryMap[nID] = tSummary
	end

	tSummary.nID = nID
	tSummary.sName = self.m_oOnlineRole:GetName()
	tSummary.nLevel = self.m_oOnlineRole:GetLevel()
	tSummary.nGender = self.m_oOnlineRole:GetGender()
	tSummary.nSchool = self.m_oOnlineRole:GetSchool()
	tSummary.tEquipment = self.m_oOnlineRole:GetEquipment()
	tSummary.tLastDup = self.m_oOnlineRole:GetLastDup()
	tSummary.tCurrDup = self.m_oOnlineRole:GetCurrDup()

	self:MarkDirty(true)
	self:SaveData() --需要马上保存,登录服需要这些数据
end
